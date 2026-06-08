"""Resume-job match analysis service."""

from __future__ import annotations

import asyncio
import logging
from collections.abc import Awaitable, Callable, Iterable

from sqlalchemy import case, desc, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.task_registry import CrawlTask
from app.core.user_config_cache import get_cached_user_config
from app.database import AsyncSessionLocal
from app.domains.jobs.llm.provider import MatchAnalysis, get_llm_provider
from app.integrations.feishu import send_feishu_notification
from app.models.job import Job, JobSearchConfig
from app.models.job_match import MatchResult, UserResume

MATCH_ANALYSIS_BATCH_SIZE = 3
NOTIFIABLE_RECOMMENDATIONS = {"强烈推荐", "可以考虑"}
RECOMMENDATION_RANK = {"强烈推荐": 3, "可以考虑": 2, "不太匹配": 1}
logger = logging.getLogger(__name__)


async def _get_jobs_needing_analysis(
    db,
    resume_id: int,
    job_ids: list[int],
    *,
    user_id: int | None = None,
) -> list:
    """Return jobs that need match analysis for the given resume.

    A job needs analysis if:
    1. No existing MatchResult for (resume_id, job_id)
    2. Job was updated after the last MatchResult analysis
    """

    # 1. Get existing match results for this resume
    existing_result = await db.execute(
        select(MatchResult).where(MatchResult.resume_id == resume_id)
    )
    match_map = {m.job_id: m for m in existing_result.scalars().all()}

    # 2. Get target jobs, scoped to the task user when available.
    jobs_query = select(Job).join(
        JobSearchConfig, Job.search_config_id == JobSearchConfig.id
    ).where(Job.id.in_(job_ids))
    if user_id is not None:
        jobs_query = jobs_query.where(JobSearchConfig.user_id == user_id)
    jobs_result = await db.execute(jobs_query)
    jobs = list(jobs_result.scalars().all())

    need_analysis = []
    for job in jobs:
        match = match_map.get(job.id)
        if not match:
            need_analysis.append(job)
        elif job.last_updated_at > match.updated_at:
            need_analysis.append(job)
        # else: already analyzed and job hasn't changed, skip

    return need_analysis


async def run_match_analysis_task(
    task: CrawlTask,
    resume_id: int,
    job_ids: list[int],
    db: AsyncSession | None = None,
) -> None:
    """Run match analysis in background, updating task progress.

    Args:
        task: The CrawlTask to update with progress
        resume_id: The resume to analyze against
        job_ids: Candidate job IDs to consider
        db: Optional database session (for testing injection)
    """
    from app.core.task_registry import TaskStatus

    task.status = TaskStatus.RUNNING

    try:
        if db is not None:
            await _execute_match_analysis(task, resume_id, job_ids, db)
        else:
            async with AsyncSessionLocal() as db:
                await _execute_match_analysis(task, resume_id, job_ids, db)
    except (ValueError, ConnectionError, TimeoutError) as exc:
        logger.warning("Match analysis failed for resume %s: %s", resume_id, exc)
        task.status = TaskStatus.FAILED
        task.reason = str(exc)
    except Exception:
        logger.exception("Unexpected error in match analysis for resume %s", resume_id)
        task.status = TaskStatus.FAILED
        task.reason = "match_analysis_failed"


async def _execute_match_analysis(
    task: CrawlTask,
    resume_id: int,
    job_ids: list[int],
    db: AsyncSession,
    *,
    progress_callback: Callable[[CrawlTask], Awaitable[None]] | None = None,
    user_id: int | None = None,
) -> None:
    """Internal: execute match analysis with an open db session.

    Supports both in-memory task_registry path and durable crawl_tasks
    worker path via progress_callback.
    """
    from app.core.task_registry import TaskStatus

    # 1. Get the resume
    resume = await db.get(UserResume, resume_id)
    if not resume or (user_id is not None and resume.user_id != user_id):
        task.status = TaskStatus.FAILED
        task.reason = "resume_not_found"
        if progress_callback is not None:
            await progress_callback(task)
        return

    # 2. Filter to jobs needing analysis
    jobs_to_analyze = await _get_jobs_needing_analysis(
        db,
        resume_id,
        job_ids,
        user_id=resume.user_id if user_id is None else user_id,
    )
    task.total = len(jobs_to_analyze)
    logger.info(
        "Job match analysis started: task_id=%s resume_id=%s requested_jobs=%d jobs_to_analyze=%d",
        getattr(task, "task_id", ""),
        resume_id,
        len(job_ids),
        len(jobs_to_analyze),
    )

    if not jobs_to_analyze:
        task.status = TaskStatus.COMPLETED
        task.reason = "all_up_to_date"
        logger.info(
            "Job match analysis completed: task_id=%s resume_id=%s reason=all_up_to_date",
            getattr(task, "task_id", ""),
            resume_id,
        )
        if progress_callback is not None:
            await progress_callback(task)
        return

    if progress_callback is not None:
        await progress_callback(task)

    # 3. Get user for notifications (cached)
    user = await get_cached_user_config(db)

    provider = get_llm_provider()
    notify_jobs = []  # 高分职位，汇总后发一条飞书

    # 过滤无内容的 job
    valid_jobs = [j for j in jobs_to_analyze if job_has_required_match_fields(j)]
    invalid_count = len(jobs_to_analyze) - len(valid_jobs)
    if invalid_count:
        task.errors += invalid_count
        logger.info(
            "Job match analysis skipped %d jobs without required fields: task_id=%s resume_id=%s errors=%d",
            invalid_count,
            getattr(task, "task_id", ""),
            resume_id,
            task.errors,
        )

    if not valid_jobs:
        if progress_callback is not None:
            await progress_callback(task)
    else:
        sem = asyncio.Semaphore(MATCH_ANALYSIS_BATCH_SIZE)

        async def _analyze_one(job: Job) -> MatchAnalysis:
            async with sem:
                return await provider.analyze_match(
                    resume_text=resume.resume_text,
                    job_title=job.title or "",
                    job_company=job.company or "",
                    job_salary=job.salary or "",
                    job_location=job.location or "",
                    job_experience=job.experience or "",
                    job_education=job.education or "",
                    job_description=job.description or "",
                )

        results = await asyncio.gather(
            *(_analyze_one(j) for j in valid_jobs),
            return_exceptions=True,
        )

        # 逐个 upsert + commit
        for job, result in zip(valid_jobs, results):
            if isinstance(result, Exception):
                task.errors += 1
                logger.warning(
                    "Job match analysis item failed: task_id=%s resume_id=%s job_id=%s error=%s",
                    getattr(task, "task_id", ""),
                    resume_id,
                    getattr(job, "id", ""),
                    result,
                )
                continue

            await upsert_match_result(
                db=db,
                user_id=resume.user_id,
                resume_id=resume.id,
                job_id=job.id,
                analysis=result,
            )
            task.success += 1
            await db.commit()

            if should_notify_match(result.apply_recommendation):
                notify_jobs.append((job, result))

        if progress_callback is not None:
            await progress_callback(task)
        logger.info(
            "Job match analysis completed: task_id=%s resume_id=%s total=%d success=%d errors=%d",
            getattr(task, "task_id", ""),
            resume_id,
            len(valid_jobs),
            task.success,
            task.errors,
        )

    # 汇总飞书通知（只发一条）
    webhook_url = user.get("feishu_webhook_url") if user else None
    if notify_jobs and webhook_url:
        try:
            lines = [
                f"职位匹配提醒（共 {len(notify_jobs)} 个高分职位）",
                f"简历：{resume.name}",
            ]
            sorted_notify_jobs = sorted(
                notify_jobs,
                key=lambda x: recommendation_rank(x[1].apply_recommendation),
                reverse=True,
            )
            for job, analysis in sorted_notify_jobs:
                lines.append(
                    f"• {job.title or '-'} / {job.company or '-'}（{analysis.apply_recommendation}）"
                )
            top_analysis = sorted_notify_jobs[0][1]
            lines.append(f"结论：{top_analysis.apply_recommendation}")
            await send_feishu_notification(webhook_url, "\n".join(lines))
        except (ValueError, ConnectionError, TimeoutError) as exc:
            logger.warning("Failed to send Feishu notification: %s", exc)
        except Exception:
            logger.exception("Failed to send Feishu notification (unexpected error)")

    # Determine final status
    attempted = task.success + task.errors
    if task.success == 0 and attempted > 0:
        task.status = TaskStatus.FAILED
        task.reason = "all_items_failed"
    else:
        task.status = TaskStatus.COMPLETED
    logger.info(
        "Job match analysis finished: task_id=%s resume_id=%s status=%s success=%d errors=%d reason=%s",
        getattr(task, "task_id", ""),
        resume_id,
        task.status.value if hasattr(task.status, "value") else task.status,
        task.success,
        task.errors,
        getattr(task, "reason", None),
    )
    if progress_callback is not None:
        await progress_callback(task)


async def enqueue_job_match_analysis(
    db,
    *,
    resume_id: int,
    job_ids: list[int],
    user_id: int,
    source: str = "manual",
) -> dict:
    """Create a durable crawl_task for job match analysis.

    Returns {"task_id": str|None, "total": int, "status": str, "reason": str|None}.
    If no jobs need analysis, returns completed without creating a task.
    """
    from app.domains.crawling.task_store import create_crawl_task_record

    jobs_to_analyze = await _get_jobs_needing_analysis(
        db,
        resume_id,
        job_ids,
        user_id=user_id,
    )
    if not jobs_to_analyze:
        return {
            "task_id": None,
            "total": 0,
            "status": "completed",
            "reason": "all_up_to_date",
        }

    record = await create_crawl_task_record(
        db,
        source=source,
        task_type="job_match_analysis",
        user_id=user_id,
        entity_type="resume",
        entity_id=str(resume_id),
        payload={
            "resume_id": resume_id,
            "job_ids": [j.id for j in jobs_to_analyze],
        },
    )
    record.total = len(jobs_to_analyze)
    await db.commit()
    await db.refresh(record)
    return {
        "task_id": record.task_id,
        "total": len(jobs_to_analyze),
        "status": "pending",
        "reason": None,
    }


def should_notify_match(recommendation: str | None) -> bool:
    """Whether a match recommendation should trigger notification."""

    return recommendation in NOTIFIABLE_RECOMMENDATIONS


def recommendation_rank(recommendation: str | None) -> int:
    """Sort rank for match recommendations."""

    return RECOMMENDATION_RANK.get(recommendation or "", 0)


def job_has_required_match_fields(job) -> bool:
    """Whether a job has enough text fields for match analysis."""

    return all([job.title, job.company, job.description])


async def analyze_resume_vs_jobs(
    resume_id: int, job_ids: Iterable[int] | None = None
) -> dict:
    """Analyze a resume against selected or all jobs for the user."""

    async with AsyncSessionLocal() as db:
        resume = await db.get(UserResume, resume_id)
        if not resume or resume.user_id != 1:
            return {
                "processed": 0,
                "created": 0,
                "updated": 0,
                "skipped": 0,
                "items": [],
            }

        query = (
            select(Job)
            .join(JobSearchConfig, Job.search_config_id == JobSearchConfig.id)
            .where(JobSearchConfig.user_id == 1)
        )
        if job_ids:
            query = query.where(Job.id.in_(list(job_ids)))

        jobs_result = await db.execute(query)
        jobs = list(jobs_result.scalars().all())
        if not jobs:
            return {
                "processed": 0,
                "created": 0,
                "updated": 0,
                "skipped": 0,
                "items": [],
            }

        user = await get_cached_user_config(db)
        webhook_url = user.get("feishu_webhook_url") if user else None

        provider = get_llm_provider()
        created = 0
        updated = 0
        skipped = 0
        notify_jobs = []

        # Batch valid jobs first
        valid_jobs = [j for j in jobs if job_has_required_match_fields(j)]
        skipped = len(jobs) - len(valid_jobs)

        sem = asyncio.Semaphore(MATCH_ANALYSIS_BATCH_SIZE)

        async def _analyze_one(job: Job) -> MatchAnalysis:
            async with sem:
                return await provider.analyze_match(
                    resume_text=resume.resume_text,
                    job_title=job.title or "",
                    job_company=job.company or "",
                    job_salary=job.salary or "",
                    job_location=job.location or "",
                    job_experience=job.experience or "",
                    job_education=job.education or "",
                    job_description=job.description or "",
                )

        results = await asyncio.gather(
            *(_analyze_one(j) for j in valid_jobs),
            return_exceptions=True,
        )

        for job, result in zip(valid_jobs, results):
            if isinstance(result, Exception):
                skipped += 1
                continue

            _, was_created = await upsert_match_result(
                db=db,
                user_id=resume.user_id,
                resume_id=resume.id,
                job_id=job.id,
                analysis=result,
            )
            if was_created:
                created += 1
            else:
                updated += 1
            await db.commit()

            if should_notify_match(result.apply_recommendation):
                notify_jobs.append((job, result))

        # Batch notification (one message with all high-score jobs)
        if notify_jobs and webhook_url:
            try:
                lines = [
                    f"职位匹配提醒（共 {len(notify_jobs)} 个高分职位）",
                    f"简历：{resume.name}",
                ]
                sorted_notify_jobs = sorted(
                    notify_jobs,
                    key=lambda x: recommendation_rank(x[1].apply_recommendation),
                    reverse=True,
                )
                for job, analysis in sorted_notify_jobs:
                    lines.append(
                        f"• {job.title or '-'} / {job.company or '-'}（{analysis.apply_recommendation}）"
                    )
                top_analysis = sorted_notify_jobs[0][1]
                lines.append(f"结论：{top_analysis.apply_recommendation}")
                await send_feishu_notification(webhook_url, "\n".join(lines))
            except (ValueError, ConnectionError, TimeoutError) as exc:
                logger.warning("Failed to send Feishu notification: %s", exc)
            except Exception:
                logger.exception("Failed to send Feishu notification (unexpected error)")

        items_result = await db.execute(
            select(MatchResult)
            .options(selectinload(MatchResult.job))
            .where(MatchResult.resume_id == resume.id)
            .order_by(
                desc(
                    case(
                        (MatchResult.apply_recommendation == "强烈推荐", 3),
                        (MatchResult.apply_recommendation == "可以考虑", 2),
                        (MatchResult.apply_recommendation == "不太匹配", 1),
                        else_=0,
                    )
                ),
                MatchResult.updated_at.desc(),
            )
        )
        items = list(items_result.scalars().all())

        return {
            "processed": len(jobs),
            "created": created,
            "updated": updated,
            "skipped": skipped,
            "items": items,
        }


async def upsert_match_result(
    db,
    user_id: int,
    resume_id: int,
    job_id: int,
    analysis: MatchAnalysis,
) -> tuple[MatchResult, bool]:
    """Insert or update a single match result using PostgreSQL atomic upsert.

    Uses ``INSERT … ON CONFLICT DO UPDATE … RETURNING xmax`` to atomically
    write and determine whether the row was created or updated.
    """
    from sqlalchemy import func, literal_column
    from sqlalchemy.dialects.postgresql import insert as pg_insert

    stmt = pg_insert(MatchResult).values(
        user_id=user_id,
        resume_id=resume_id,
        job_id=job_id,
        match_score=analysis.match_score,
        match_reason=analysis.match_reason,
        apply_recommendation=analysis.apply_recommendation,
        llm_model_used=analysis.model_used,
    )
    stmt = stmt.on_conflict_do_update(
        index_elements=[MatchResult.resume_id, MatchResult.job_id],
        set_={
            "match_score": stmt.excluded.match_score,
            "match_reason": stmt.excluded.match_reason,
            "apply_recommendation": stmt.excluded.apply_recommendation,
            "llm_model_used": stmt.excluded.llm_model_used,
            "updated_at": func.now(),
        },
    ).returning(MatchResult, literal_column("xmax"))

    result = await db.execute(stmt)
    row = result.mappings().one()
    match_result = row[MatchResult]
    was_created = row["xmax"] == 0

    return match_result, was_created
