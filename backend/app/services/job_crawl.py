"""Job crawling service: process results, deduplicate, send notifications."""
from __future__ import annotations

import asyncio
import logging
import random
import re
from datetime import UTC, datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.platforms.base import BasePlatformAdapter
    from app.services.scheduler_service import CrawlTask

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.system_log import emit_system_log_detached
from app.database import AsyncSessionLocal
from app.domains.jobs.match_service import analyze_resume_vs_jobs
from app.domains.jobs.notification_service import send_new_job_notification
from app.models.job import Job, JobSearchConfig
from app.models.job_crawl_log import JobCrawlLog
from app.models.job_match import UserResume

logger = logging.getLogger(__name__)

VALID_JOB_PLATFORMS = {"boss", "51job", "liepin"}
_JOB_CRAWL_LOCK = asyncio.Lock()
DETAIL_COOKIE_FAILURE_COOLDOWN_LIMIT = 2
DETAIL_RETRY_DELAY_SECONDS = (20.0, 40.0)


def _normalize_platform(platform: object) -> str:
    """Return a supported platform key, defaulting legacy rows/mocks to boss."""
    if not isinstance(platform, str) or not platform:
        return "boss"
    normalized = platform.strip().lower()
    if normalized not in VALID_JOB_PLATFORMS:
        raise ValueError(f"Unknown job platform: {platform}")
    return normalized


def _create_adapter(platform: str) -> BasePlatformAdapter:
    """Create the appropriate adapter for the given job platform."""
    from app.platforms import BossZhipinAdapter, Job51Adapter, LiepinAdapter

    platform = _normalize_platform(platform)
    adapters: dict[str, type] = {
        "boss": BossZhipinAdapter,
        "51job": Job51Adapter,
        "liepin": LiepinAdapter,
    }
    return adapters[platform]()


def parse_salary(salary_str: str | None) -> tuple[int | None, int | None]:
    """Parse salary string like '20-40K·14薪' to (min, max) in K.

    Returns:
        (salary_min, salary_max) in units of K, or (None, None) if unparseable.
    """
    if not salary_str:
        return None, None

    # Remove bonus part like "·14薪"
    salary_str = re.sub(r'·\d+薪', '', salary_str)

    # Match patterns like "20-40K", "20K", "20-40k", "面议"
    if salary_str in ('面议', '薪资面议', '薪资面议 '):
        return None, None

    # Remove spaces and clean up
    salary_str = re.sub(r'\s+', '', salary_str)

    match = re.match(r'(\d+)[kK]?-(\d+)[kK]?', salary_str)
    if match:
        return int(match.group(1)), int(match.group(2))

    # Single value like "20K"
    match = re.match(r'^(\d+)[kK]?$', salary_str.strip())
    if match:
        val = int(match.group(1))
        return val, val

    return None, None


async def process_job_results(
    config_id: int,
    jobs: list[dict],
    total_scraped: int,
    adapter: BasePlatformAdapter | None = None,
    *,
    platform: str = "boss",
) -> dict:
    """Process crawl results: deduplicate, insert/update jobs, send notifications.

    Args:
        config_id: The JobSearchConfig ID that was crawled
        jobs: List of job data dicts from BossZhipinAdapter
        total_scraped: Total number of jobs seen in this crawl (for logging)

    Returns:
        {"new_count": N, "updated_count": N, "deactivated_count": N}
    """
    new_count = 0
    updated_count = 0
    deactivated_count = 0
    new_job_ids: list[int] = []
    detail_jobs: list[Job] = []

    async with AsyncSessionLocal() as db:
        config = await db.get(JobSearchConfig, config_id)
        if not config:
            logger.warning(f"JobSearchConfig {config_id} not found")
            return {"new_count": 0, "updated_count": 0, "deactivated_count": 0}

        # Get job_ids seen in this crawl
        seen_job_ids = {job["job_id"] for job in jobs if job.get("job_id")}

        # Deactivate jobs that were seen last time but not this time (grace period)
        if seen_job_ids:
            result = await db.execute(
                select(Job).where(
                    Job.search_config_id == config_id,
                    Job.is_active,
                )
            )
            all_active_jobs = list(result.scalars().all())

            threshold = config.deactivation_threshold or 3

            for job in all_active_jobs:
                if job.job_id in seen_job_ids:
                    # Job is still present — reset counter
                    job.consecutive_miss_count = 0
                    job.last_active_at = datetime.now(UTC)
                else:
                    # Job not seen this crawl — increment miss counter
                    job.consecutive_miss_count = (job.consecutive_miss_count or 0) + 1
                    if job.consecutive_miss_count >= threshold:
                        job.is_active = False
                        job.last_updated_at = datetime.now(UTC)
                        deactivated_count += 1

        # Batch query: find all jobs by job_id in ONE query
        job_ids = [job["job_id"] for job in jobs if job.get("job_id")]
        job_id_to_data: dict[str, dict] = {job["job_id"]: job for job in jobs if job.get("job_id")}

        jobs_by_job_id: dict[str, Job] = {}
        if job_ids:
            result = await db.execute(
                select(Job).where(
                    Job.search_config_id == config_id,
                    Job.job_id.in_(job_ids),
                )
            )
            for job in result.scalars().all():
                jobs_by_job_id[job.job_id] = job

        # Separate into found by job_id vs need dedup check
        jobs_need_dedup: list[dict] = []  # jobs not found by job_id, need dedup by (title, company, salary)

        for job_id, job_obj in jobs_by_job_id.items():
            if job_id not in job_id_to_data:
                continue  # Skip jobs not in our input data (mock may return unexpected results)
            job_data = job_id_to_data[job_id]
            salary = job_data.get("salary")
            salary_min, salary_max = parse_salary(salary)
            # Update existing job
            job_obj.last_updated_at = datetime.now(UTC)
            job_obj.is_active = True
            if job_data.get("title"):
                job_obj.title = job_data["title"]
            if job_data.get("company"):
                job_obj.company = job_data["company"]
            if salary:
                job_obj.salary = salary
                job_obj.salary_min = salary_min
                job_obj.salary_max = salary_max
            if job_data.get("location"):
                job_obj.location = job_data["location"]
            if job_data.get("experience"):
                job_obj.experience = job_data["experience"]
            if job_data.get("education"):
                job_obj.education = job_data["education"]
            if job_data.get("url"):
                job_obj.url = job_data["url"]
            if job_data.get("description"):
                job_obj.description = job_data["description"]
            if job_data.get("address"):
                job_obj.address = job_data["address"]
            if not job_obj.description or not job_obj.address:
                detail_jobs.append(job_obj)
            updated_count += 1

        for job_data in jobs:
            job_id = job_data.get("job_id")
            if not job_id or job_id in jobs_by_job_id:
                continue
            # Not found by job_id — collect for dedup check
            salary = job_data.get("salary")
            salary_min, salary_max = parse_salary(salary)
            jobs_need_dedup.append({
                "job_id": job_id,
                "data": job_data,
                "salary": salary,
                "salary_min": salary_min,
                "salary_max": salary_max,
                "title": job_data.get("title") or "",
                "company": job_data.get("company") or "",
                "company_id": job_data.get("company_id") or "",
                "location": job_data.get("location") or "",
                "experience": job_data.get("experience") or "",
                "education": job_data.get("education") or "",
                "url": job_data.get("url") or "",
                "description": job_data.get("description") or "",
                "address": job_data.get("address") or "",
            })

        # Batch dedup query: find all matching by (title, company, salary) in ONE query
        newly_inserted_job_ids: list[str] = []  # track string job_ids of new inserts
        newly_inserted_job_ids_needing_detail: set[str] = set()
        if jobs_need_dedup:
            dedup_tuples = [(j["title"], j["company"], j["salary"] or "") for j in jobs_need_dedup]
            result = await db.execute(
                select(Job).where(
                    Job.search_config_id == config_id,
                    Job.title.in_([t[0] for t in dedup_tuples]),
                    Job.company.in_([t[1] for t in dedup_tuples]),
                    Job.salary.in_([t[2] for t in dedup_tuples]),
                )
            )
            # Build dedup lookup: (title, company, salary) -> Job
            dedup_map: dict[tuple[str, str, str], Job] = {}
            for job in result.scalars().all():
                dedup_map[(job.title, job.company, job.salary or "")] = job

            now = datetime.now(UTC)
            for item in jobs_need_dedup:
                key = (item["title"], item["company"], item["salary"])
                existing_dup = dedup_map.get(key)
                if existing_dup:
                    # Update existing record with new job_id
                    existing_dup.job_id = item["job_id"]
                    existing_dup.last_updated_at = now
                    existing_dup.is_active = True
                    if item["location"]:
                        existing_dup.location = item["location"]
                    if item["experience"]:
                        existing_dup.experience = item["experience"]
                    if item["education"]:
                        existing_dup.education = item["education"]
                    if item["url"]:
                        existing_dup.url = item["url"]
                    if item.get("description"):
                        existing_dup.description = item["description"]
                    if item.get("address"):
                        existing_dup.address = item["address"]
                    updated_count += 1
                else:
                    # Insert new job
                    newly_inserted_job_ids.append(item["job_id"])
                    if not item.get("description"):
                        newly_inserted_job_ids_needing_detail.add(item["job_id"])
                    new_job = Job(
                        job_id=item["job_id"],
                        search_config_id=config_id,
                        title=item["title"],
                        company=item["company"],
                        company_id=item["company_id"],
                        salary=item["salary"],
                        salary_min=item["salary_min"],
                        salary_max=item["salary_max"],
                        location=item["location"],
                        experience=item["experience"],
                        education=item["education"],
                        url=item["url"],
                        description=item.get("description") or "",
                        address=item.get("address") or "",
                        first_seen_at=now,
                        last_updated_at=now,
                        is_active=True,
                    )
                    db.add(new_job)
                    new_count += 1

        # Flush all new jobs and fetch full Job objects
        if newly_inserted_job_ids:
            await db.flush()
            result = await db.execute(
                select(Job).where(
                    Job.search_config_id == config_id,
                    Job.job_id.in_(newly_inserted_job_ids),
                )
            )
            new_jobs: list[Job] = list(result.scalars().all())
            new_job_ids = [j.id for j in new_jobs]
            for job_obj in new_jobs:
                if job_obj.job_id in newly_inserted_job_ids_needing_detail:
                    detail_jobs.append(job_obj)

        # Send notification for new jobs (after commit so config.notify_on_new is available)
        if new_count > 0 and config.notify_on_new:
            try:
                await send_new_job_notification(config, new_count, total_scraped)
            except Exception:
                logger.exception("Failed to send job notification for config %s", config_id)

        # Log crawl result — in same transaction as job inserts/updates
        crawl_log = JobCrawlLog(
            search_config_id=config.id,
            status="SUCCESS",
            new_jobs_count=new_count,
            total_jobs_count=total_scraped,
            scraped_at=datetime.now(UTC),
            error_message=None,
        )
        db.add(crawl_log)

        # Single commit for both job data and crawl log
        await db.commit()

        # Fetch job details sequentially with rate limiting (no concurrency)
        if detail_jobs:
            detail_errors = 0
            detail_updates = 0
            consecutive_cookie_failures = 0
            cookie_failure_cooldowns = 0
            retry_detail_jobs: list[Job] = []
            for job_obj in detail_jobs:
                try:
                    result = await update_job_detail(
                        job_obj,
                        adapter=adapter,
                        platform=platform,
                        db=db,
                    )
                    if isinstance(result, Exception):
                        detail_errors += 1
                        retry_detail_jobs.append(job_obj)
                    elif isinstance(result, dict) and not result.get("success"):
                        detail_errors += 1
                        retry_detail_jobs.append(job_obj)
                        err = result.get("error", "")
                        if "code=37" in err or "code=36" in err or "Cookie expired" in err:
                            consecutive_cookie_failures += 1
                        else:
                            consecutive_cookie_failures = 0
                    else:
                        detail_updates += 1
                        consecutive_cookie_failures = 0
                except Exception:
                    detail_errors += 1
                    retry_detail_jobs.append(job_obj)
                    consecutive_cookie_failures += 1

                # 连续 cookie 失败时先冷却，再继续串行补详情；多次冷却仍失败才停止。
                if consecutive_cookie_failures >= 3:
                    remaining = len(detail_jobs) - detail_jobs.index(job_obj) - 1
                    if cookie_failure_cooldowns < DETAIL_COOKIE_FAILURE_COOLDOWN_LIMIT:
                        cookie_failure_cooldowns += 1
                        cooldown = random.uniform(20.0, 40.0)
                        logger.warning(
                            "Cooling down detail fetch after %d consecutive cookie failures; "
                            "%d jobs remaining, cooldown %.1fs (%d/%d)",
                            consecutive_cookie_failures,
                            remaining,
                            cooldown,
                            cookie_failure_cooldowns,
                            DETAIL_COOKIE_FAILURE_COOLDOWN_LIMIT,
                        )
                        consecutive_cookie_failures = 0
                        await asyncio.sleep(cooldown)
                        continue
                    logger.warning(
                        "Bailing out of detail fetch: %d consecutive cookie failures, "
                        "%d jobs remaining",
                        consecutive_cookie_failures, remaining,
                    )
                    break

                # 2-5秒间隔，避免触发反爬
                await asyncio.sleep(random.uniform(2.0, 5.0))
            if retry_detail_jobs:
                retry_delay = random.uniform(*DETAIL_RETRY_DELAY_SECONDS)
                logger.info(
                    "Retrying %d failed detail fetches after %.1fs",
                    len(retry_detail_jobs),
                    retry_delay,
                )
                await asyncio.sleep(retry_delay)
                for job_obj in retry_detail_jobs:
                    try:
                        result = await update_job_detail(
                            job_obj,
                            adapter=adapter,
                            platform=platform,
                            db=db,
                        )
                        if isinstance(result, dict) and result.get("success"):
                            detail_updates += 1
                    except Exception:
                        logger.exception("Retry detail fetch failed for job %s", job_obj.id)

                    await asyncio.sleep(random.uniform(2.0, 5.0))
            if detail_errors:
                logger.info("Detail fetch completed: %d errors out of %d jobs", detail_errors, len(detail_jobs))

        if new_job_ids and config.enable_match_analysis:
            resume_result = await db.execute(
                select(UserResume).where(UserResume.user_id == config.user_id)
            )
            resumes = list(resume_result.scalars().all())
            for resume in resumes:
                try:
                    await analyze_resume_vs_jobs(resume.id, new_job_ids)
                except Exception:
                    logger.exception("Failed to run match analysis for resume %s", resume.id)

    return {
        "new_count": new_count,
        "updated_count": updated_count,
        "deactivated_count": deactivated_count,
    }


async def update_job_detail(
    job: int | Job,
    adapter: BasePlatformAdapter | None = None,
    *,
    platform: str = "boss",
    db: AsyncSession | None = None,
    commit: bool = True,
) -> dict:
    """Fetch and update job detail (description, address) from platform API.

    Accepts a Job ID (int) or an already-loaded Job object to avoid an
    extra ``db.get()`` when the caller already has the object loaded.
    """
    async def _update(db_session: AsyncSession) -> dict:
        if isinstance(job, Job):
            job_obj = job
        else:
            job_obj = await db_session.get(Job, job)
            if not job_obj:
                return {"success": False, "error": "Job not found"}

        # Reuse adapter if provided (shares session & cookies), else create new
        detail_adapter = adapter
        if detail_adapter is None:
            detail_adapter = _create_adapter(platform)

        # Skip detail fetching only when both fields already exist
        if job_obj.description and job_obj.address:
            return {
                "success": True,
                "detail": {
                    "description": job_obj.description,
                    "address": job_obj.address,
                }
            }

        # crawl_detail is available on both BossZhipinAdapter and Job51Adapter
        if not hasattr(detail_adapter, "crawl_detail"):
            return {"success": False, "error": f"Adapter for {platform} has no crawl_detail"}
        result = await detail_adapter.crawl_detail(job_obj.job_id)

        if not result.get("success"):
            return result

        detail = result["detail"]

        # Update job record with detail data
        job_obj.description = detail.get("description", "")
        job_obj.address = detail.get("address", "")
        job_obj.last_updated_at = datetime.now(UTC)
        if commit:
            await db_session.commit()

        return {"success": True, "detail": detail}

    if db is not None:
        return await _update(db)

    async with AsyncSessionLocal() as db_session:
        return await _update(db_session)


async def crawl_single_config(
    config_id: int,
    adapter: BasePlatformAdapter | None = None,
    *,
    _lock_already_held: bool = False,
    **kwargs,
) -> dict:
    """Crawl a single JobSearchConfig and process results.

    Routes to the correct platform adapter based on config.platform.

    Args:
        config_id: The JobSearchConfig ID to crawl.
        adapter: Optional shared adapter. When provided, reuses
            the adapter's session and cookies across multiple configs to
            avoid redundant cookie acquisition and browser tab churn.
    """
    if not _lock_already_held:
        if _JOB_CRAWL_LOCK.locked():
            logger.warning("Job crawl skipped: another job crawl is in progress")
            return {"status": "skipped", "reason": "another_job_crawl_in_progress"}
        async with _JOB_CRAWL_LOCK:
            return await crawl_single_config(
                config_id,
                adapter=adapter,
                _lock_already_held=True,
                **kwargs,
            )

    async with AsyncSessionLocal() as db:
        config = await db.get(JobSearchConfig, config_id)
        if not config:
            return {"status": "error", "error": "Config not found"}
        # Eagerly load platform before session closes
        try:
            platform = _normalize_platform(getattr(config, "platform", "boss"))
        except ValueError as exc:
            return {"status": "error", "error": str(exc)}
        url = config.url

    try:
        if adapter is None:
            adapter = _create_adapter(platform)
        result = await adapter.crawl(url)

        if result.get("success"):
            stats = await process_job_results(
                config_id=config_id,
                jobs=result["jobs"],
                total_scraped=result["count"],
                adapter=adapter,
                platform=platform,
            )
            return {"status": "success", **stats}
        else:
            # Log error
            async with AsyncSessionLocal() as db:
                log = JobCrawlLog(
                    search_config_id=config_id,
                    status="ERROR",
                    error_message=result.get("error", "Unknown error"),
                    scraped_at=datetime.now(UTC),
                )
                db.add(log)
                await db.commit()
            return {"status": "error", "error": result.get("error")}
    except Exception as exc:
        import logging
        logging.getLogger("app.services.job_crawl").exception("Unexpected error crawling config_id %d", config_id)
        async with AsyncSessionLocal() as db:
            log = JobCrawlLog(
                search_config_id=config_id,
                status="ERROR",
                error_message=f"Unhandled error: {str(exc)}",
                scraped_at=datetime.now(UTC),
            )
            db.add(log)
            await db.commit()
        return {"status": "error", "error": str(exc)}


async def crawl_all_job_searches(
    source: str = "manual",
    *,
    user_id: int | None = None,
    _lock_already_held: bool = False,
) -> dict:
    """Crawl all active job search configs.

    Groups configs by platform and shares one adapter per platform so that
    cookie acquisition happens at most once per platform instead of once
    per config.
    """
    if not _lock_already_held:
        if _JOB_CRAWL_LOCK.locked():
            logger.warning(
                "Job crawl skipped: another job crawl is in progress (source=%s)",
                source,
            )
            return {
                "status": "skipped",
                "reason": "another_job_crawl_in_progress",
                "total": 0,
                "success": 0,
                "errors": 0,
            }
        async with _JOB_CRAWL_LOCK:
            return await crawl_all_job_searches(
                source=source,
                user_id=user_id,
                _lock_already_held=True,
            )

    async with AsyncSessionLocal() as db:
        filters = [JobSearchConfig.active]
        if user_id is not None:
            filters.append(JobSearchConfig.user_id == user_id)
        result = await db.execute(
            select(JobSearchConfig).where(*filters)
        )
        configs = list(result.scalars().all())

    if not configs:
        return {"status": "completed", "total": 0, "success": 0, "errors": 0}

    total = len(configs)
    success_count = 0
    error_count = 0
    details = []

    # Group configs by platform, share one adapter per platform
    by_platform: dict[str, list] = {}
    for config in configs:
        try:
            platform = _normalize_platform(getattr(config, "platform", "boss"))
        except ValueError as exc:
            logger.warning("Skipping config %s with invalid platform %r", config.id, config.platform)
            details.append({"config_id": config.id, "status": "error", "error": str(exc)})
            error_count += 1
            continue
        by_platform.setdefault(platform, []).append(config)

    idx = 0
    for platform, platform_configs in by_platform.items():
        adapter = _create_adapter(platform)
        for config in platform_configs:
            result = await crawl_single_config(
                config.id,
                adapter=adapter,
                _lock_already_held=True,
            )
            details.append({"config_id": config.id, **result})
            if result.get("status") == "success":
                success_count += 1
            else:
                error_count += 1

            idx += 1
            if idx < total:
                delay = random.uniform(3, 6)
                logger.debug("Waiting %.1fs before next config", delay)
                await asyncio.sleep(delay)

    return {
        "status": "completed",
        "total": total,
        "success": success_count,
        "errors": error_count,
        "details": details,
    }


async def crawl_single_config_background(
    config_id: int,
    *,
    user_id: int | None = None,
) -> CrawlTask:
    """后台运行单配置爬取，立即返回 task 对象。"""
    from app.services.scheduler_service import TaskStatus, create_task

    task = create_task(
        "manual",
        user_id=user_id,
        entity_type="job_config",
        entity_id=str(config_id),
    )
    task.status = TaskStatus.RUNNING

    async def _run():
        try:
            await emit_system_log_detached(
                category="runtime",
                event_type="job_crawl.started",
                source="jobs",
                severity="info",
                status="running",
                message=f"Job crawl for config {config_id} started",
                user_id=task.user_id,
                entity_type="job_config",
                entity_id=str(config_id),
                payload={"task_id": task.task_id, "config_id": config_id},
            )
            result = await crawl_single_config(config_id)
            ok = result.get("status") != "error"
            task.status = TaskStatus.COMPLETED if ok else TaskStatus.FAILED
            task.total = sum(v for k, v in result.items() if k in ("new_count", "updated_count", "deactivated_count"))
            task.success = result.get("new_count", 0)
            task.errors = 0 if ok else 1
            await emit_system_log_detached(
                category="runtime",
                event_type="job_crawl.completed" if ok else "job_crawl.failed",
                source="jobs",
                severity="info" if ok else "error",
                status="completed" if ok else "failed",
                message=f"Job crawl for config {config_id} {'completed' if ok else 'failed'}",
                user_id=task.user_id,
                entity_type="job_config",
                entity_id=str(config_id),
                payload={"task_id": task.task_id, **result},
            )
        except Exception as e:
            task.status = TaskStatus.FAILED
            task.reason = str(e)
            await emit_system_log_detached(
                category="runtime",
                event_type="job_crawl.failed",
                source="jobs",
                severity="error",
                status="failed",
                message=f"Job crawl for config {config_id} failed",
                user_id=task.user_id,
                entity_type="job_config",
                entity_id=str(config_id),
                payload={"task_id": task.task_id, "reason": task.reason},
            )

    asyncio.create_task(_run())
    return task


async def crawl_all_job_searches_background(*, user_id: int | None = None) -> CrawlTask:
    """后台运行全量爬取，立即返回 task 对象。"""
    from app.services.scheduler_service import TaskStatus, create_task

    task = create_task(
        "manual",
        user_id=user_id,
        entity_type="job_crawl",
        entity_id=None,
    )
    task.status = TaskStatus.RUNNING

    async def _run():
        try:
            await emit_system_log_detached(
                category="runtime",
                event_type="job_crawl.started",
                source="jobs",
                severity="info",
                status="running",
                message="Job crawl for all active configs started",
                user_id=task.user_id,
                entity_type="job_crawl",
                entity_id=task.task_id,
                payload={"task_id": task.task_id},
            )
            result = await crawl_all_job_searches(source="manual", user_id=task.user_id)
            ok = result.get("status") != "error"
            task.status = TaskStatus.COMPLETED if ok else TaskStatus.FAILED
            task.total = result.get("total", 0)
            task.success = result.get("success", 0)
            task.errors = result.get("errors", 0)
            await emit_system_log_detached(
                category="runtime",
                event_type="job_crawl.completed" if ok else "job_crawl.failed",
                source="jobs",
                severity="info" if ok else "error",
                status="completed" if ok else "failed",
                message=f"Job crawl for all active configs {'completed' if ok else 'failed'}",
                user_id=task.user_id,
                entity_type="job_crawl",
                entity_id=task.task_id,
                payload={"task_id": task.task_id, **result},
            )
        except Exception as e:
            task.status = TaskStatus.FAILED
            task.reason = str(e)
            await emit_system_log_detached(
                category="runtime",
                event_type="job_crawl.failed",
                source="jobs",
                severity="error",
                status="failed",
                message="Job crawl for all active configs failed",
                user_id=task.user_id,
                entity_type="job_crawl",
                entity_id=task.task_id,
                payload={"task_id": task.task_id, "reason": task.reason},
            )

    asyncio.create_task(_run())
    return task
