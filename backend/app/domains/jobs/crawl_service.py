"""Job crawling service: process results, deduplicate, send notifications."""
from __future__ import annotations

import asyncio
import logging
import random
import re
from contextlib import suppress
from datetime import UTC, datetime
from typing import TYPE_CHECKING
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

from sqlalchemy import select

from app.core.task_registry import CrawlTask, TaskStatus
from app.domains.crawling.task_store import CrawlTaskRecord, runtime_task_from_record

if TYPE_CHECKING:
    from app.platforms.base import BasePlatformAdapter
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.system_log import emit_system_log_detached
from app.database import AsyncSessionLocal
from app.domains.jobs.match_service import analyze_resume_vs_jobs
from app.domains.jobs.notification_service import send_new_job_notification
from app.domains.jobs.runtime import JobCrawlRuntimeContext
from app.models.job import Job, JobSearchConfig
from app.models.job_crawl_log import JobCrawlLog
from app.models.job_match import UserResume

logger = logging.getLogger(__name__)

VALID_JOB_PLATFORMS = {"boss", "51job", "liepin"}
_JOB_CRAWL_LOCK = asyncio.Lock()
DETAIL_COOKIE_FAILURE_COOLDOWN_LIMIT = 2
DETAIL_RETRY_DELAY_SECONDS = (20.0, 40.0)
DETAIL_FETCH_TIMEOUT_SECONDS = 15.0
DETAIL_WAF_BLOCK_LIMIT = 1
DETAIL_TIMEOUT_LIMIT = 3


def _config_profile_key(config: JobSearchConfig | None) -> str:
    raw = getattr(config, "profile_key", None) if config is not None else None
    return raw or "default"


def _group_job_configs_for_profile_leases(
    configs: list[JobSearchConfig],
) -> dict[tuple[str, str], list[JobSearchConfig]]:
    grouped: dict[tuple[str, str], list[JobSearchConfig]] = {}
    for config in configs:
        platform = _normalize_platform(getattr(config, "platform", "boss"))
        profile_key = _config_profile_key(config)
        grouped.setdefault((platform, profile_key), []).append(config)
    return grouped


def _job_group_task_metadata(platform: str, profile_key: str, parent_task_id: str) -> dict:
    return {
        "task_type": "job_platform_profile",
        "platform": platform,
        "profile_key": profile_key,
        "entity_type": "job_platform_profile",
        "entity_id": f"{platform}:{profile_key}",
        "payload": {
            "parent_task_id": parent_task_id,
            "platform": platform,
            "profile_key": profile_key,
        },
    }


def _group_profile_lanes_for_parallelism(
    groups: dict[tuple[str, str], list[JobSearchConfig]],
) -> dict[str, list[tuple[str, str, list[JobSearchConfig]]]]:
    lanes: dict[str, list[tuple[str, str, list[JobSearchConfig]]]] = {}
    for (platform, profile_key), platform_configs in groups.items():
        lanes.setdefault(profile_key, []).append(
            (platform, profile_key, platform_configs)
        )
    return lanes


def _normalize_platform(platform: object) -> str:
    """Return a supported platform key, defaulting legacy rows/mocks to boss."""
    if not isinstance(platform, str) or not platform:
        return "boss"
    normalized = platform.strip().lower()
    if normalized not in VALID_JOB_PLATFORMS:
        raise ValueError(f"Unknown job platform: {platform}")
    return normalized


def _create_adapter(
    platform: str,
    *,
    runtime_context=None,
) -> BasePlatformAdapter:
    """Create the appropriate adapter for the given job platform."""
    from app.platforms import (
        BossCloakExperimentalAdapter,
        Job51Adapter,
        LiepinAdapter,
    )

    platform = _normalize_platform(platform)
    adapters: dict[str, type] = {
        "boss": BossCloakExperimentalAdapter,
        "51job": Job51Adapter,
        "liepin": LiepinAdapter,
    }
    kwargs = {}
    if runtime_context is not None:
        kwargs["profile_dir"] = runtime_context.profile_dir
        kwargs["runtime_context"] = runtime_context
    return adapters[platform](**kwargs)


def _build_crawl_url(config: JobSearchConfig) -> str:
    """Add config keyword/city to crawl URL when the stored URL is generic."""
    parsed = urlparse(config.url)
    params = dict(parse_qsl(parsed.query, keep_blank_values=True))
    if getattr(config, "keyword", None) and not params.get("query"):
        params["query"] = config.keyword
    if getattr(config, "city_code", None) and not params.get("city"):
        params["city"] = config.city_code
    return urlunparse(parsed._replace(query=urlencode(params)))


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
    unique_jobs: dict[str, dict] = {}
    for job in jobs:
        job_id = job.get("job_id")
        if job_id and job_id not in unique_jobs:
            unique_jobs[job_id] = job
    jobs = list(unique_jobs.values())
    total_scraped = len(jobs)

    def needs_initial_detail_fetch(job_data: dict) -> bool:
        return not job_data.get("description")

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
            if not job_obj.description:
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
                    if not existing_dup.description:
                        detail_jobs.append(existing_dup)
                    updated_count += 1
                else:
                    # Insert new job
                    newly_inserted_job_ids.append(item["job_id"])
                    if needs_initial_detail_fetch(item):
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
            consecutive_waf_blocks = 0
            consecutive_detail_timeouts = 0
            cookie_failure_cooldowns = 0
            retry_detail_jobs: list[Job] = []
            for job_obj in detail_jobs:
                try:
                    logger.info("Fetching job detail: platform=%s job_id=%s db_id=%s", platform, job_obj.job_id, job_obj.id)
                    result = await asyncio.wait_for(
                        update_job_detail(
                            job_obj,
                            adapter=adapter,
                            platform=platform,
                            profile_key=_config_profile_key(config),
                            db=db,
                        ),
                        timeout=DETAIL_FETCH_TIMEOUT_SECONDS,
                    )
                    if isinstance(result, Exception):
                        detail_errors += 1
                        retry_detail_jobs.append(job_obj)
                    elif isinstance(result, dict) and not result.get("success"):
                        detail_errors += 1
                        err = str(result.get("error", ""))
                        if "Blocked by Aliyun WAF" in err:
                            consecutive_waf_blocks += 1
                            logger.warning(
                                "Detail fetch blocked by WAF: platform=%s job_id=%s db_id=%s consecutive=%d/%d",
                                platform,
                                job_obj.job_id,
                                job_obj.id,
                                consecutive_waf_blocks,
                                DETAIL_WAF_BLOCK_LIMIT,
                            )
                            if platform == "51job" and consecutive_waf_blocks >= DETAIL_WAF_BLOCK_LIMIT:
                                logger.warning("Bailing out of 51job detail fetch after repeated WAF blocks")
                                break
                            continue
                        retry_detail_jobs.append(job_obj)
                        consecutive_waf_blocks = 0
                        if "code=37" in err or "code=36" in err or "Cookie expired" in err:
                            consecutive_cookie_failures += 1
                        else:
                            consecutive_cookie_failures = 0
                    else:
                        detail_updates += 1
                        consecutive_cookie_failures = 0
                        consecutive_waf_blocks = 0
                        consecutive_detail_timeouts = 0
                except TimeoutError:
                    logger.warning(
                        "Detail fetch timed out after %.0fs: platform=%s job_id=%s db_id=%s",
                        DETAIL_FETCH_TIMEOUT_SECONDS,
                        platform,
                        job_obj.job_id,
                        job_obj.id,
                    )
                    detail_errors += 1
                    consecutive_cookie_failures += 1
                    consecutive_detail_timeouts += 1
                    if consecutive_detail_timeouts >= DETAIL_TIMEOUT_LIMIT:
                        logger.warning("Bailing out of detail fetch after %d consecutive timeouts", consecutive_detail_timeouts)
                        break
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
                        logger.info("Retrying job detail: platform=%s job_id=%s db_id=%s", platform, job_obj.job_id, job_obj.id)
                        result = await asyncio.wait_for(
                            update_job_detail(
                                job_obj,
                                adapter=adapter,
                                platform=platform,
                                profile_key=_config_profile_key(config),
                                db=db,
                            ),
                            timeout=DETAIL_FETCH_TIMEOUT_SECONDS,
                        )
                        if isinstance(result, dict) and result.get("success"):
                            detail_updates += 1
                    except TimeoutError:
                        logger.warning(
                            "Retry detail fetch timed out after %.0fs: platform=%s job_id=%s db_id=%s",
                            DETAIL_FETCH_TIMEOUT_SECONDS,
                            platform,
                            job_obj.job_id,
                            job_obj.id,
                        )
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
    profile_key: str | None = None,
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
            from app.core.crawler_paths import build_profile_dir
            from app.domains.jobs.runtime import JobCrawlRuntimeContext
            pk = profile_key or "default"
            runtime_context = JobCrawlRuntimeContext(
                platform=platform,
                profile_key=pk,
                profile_dir=build_profile_dir(pk),
                task_id=None,
                config_id=job_obj.search_config_id,
                run_id=f"detail-{job_obj.job_id}",
            )
            detail_adapter = _create_adapter(platform, runtime_context=runtime_context)

        # 51job search results usually include description but not precise address;
        # do not hit the WAF-prone detail page only to backfill address.
        if job_obj.description and (platform == "51job" or job_obj.address):
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
        if platform == "51job":
            result = await detail_adapter.crawl_detail(job_obj.job_id, job_obj.url or "")
        else:
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
    runtime_context=None,
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
                runtime_context=runtime_context,
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
        url = _build_crawl_url(config)

    try:
        if adapter is None:
            adapter = _create_adapter(platform, runtime_context=runtime_context)
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
        logging.getLogger("app.domains.jobs.crawl_service").exception(
            "Unexpected error crawling config_id %d", config_id
        )
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


async def _get_job_config_user_id(config_id: int) -> int | None:
    async with AsyncSessionLocal() as db:
        config = await db.get(JobSearchConfig, config_id)
        return config.user_id if config else None


async def _persist_crawl_task_progress(
    record_id: int,
    progress_task: CrawlTask,
) -> None:
    from app.domains.crawling.task_store import (
        CrawlTaskRecord,
        sync_record_from_runtime_task,
    )

    async with AsyncSessionLocal() as db:
        record = await db.get(CrawlTaskRecord, record_id)
        if record is not None:
            await sync_record_from_runtime_task(db, record, progress_task)


async def _profile_lease_heartbeat(
    record_id: int,
    pool,
    lease,
    *,
    interval_seconds: float = 30.0,
) -> None:
    from app.domains.crawling.task_store import CrawlTaskRecord, renew_task_lease

    while True:
        await asyncio.sleep(interval_seconds)
        try:
            async with AsyncSessionLocal() as db:
                record = await db.get(CrawlTaskRecord, record_id)
                if record is not None and record.status == "running":
                    await renew_task_lease(db, record)
            async with AsyncSessionLocal() as db:
                await pool.renew(db, lease)
        except Exception:
            logger.warning(
                "Failed to renew profile lease heartbeat for crawl task record %s",
                record_id,
                exc_info=True,
            )


async def _stop_heartbeat(task: asyncio.Task | None) -> None:
    if task is None:
        return
    task.cancel()
    with suppress(asyncio.CancelledError):
        await task


async def crawl_scheduled_config(
    config_id: int,
    cron_expression: str | None = None,
) -> dict:
    """Run a scheduled job crawl and mirror manual crawls in Event Center."""
    from app.config import settings
    from app.core.task_registry import TaskStatus
    from app.domains.crawling.task_store import (
        create_crawl_task_record,
        runtime_task_from_record,
    )

    user_id = await _get_job_config_user_id(config_id)

    async with AsyncSessionLocal() as db:
        config = await db.get(JobSearchConfig, config_id)
        config_platform = (
            _normalize_platform(getattr(config, "platform", "boss"))
            if config
            else "boss"
        )
        profile_key = _config_profile_key(config)

    payload = {
        "config_id": config_id,
        "source": "scheduled",
        "platform": config_platform,
        "profile_key": profile_key,
    }
    if cron_expression:
        payload["cron_expression"] = cron_expression

    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="cron",
            task_type="job_config",
            platform=config_platform,
            profile_key=profile_key,
            user_id=user_id,
            entity_type="job_config",
            entity_id=str(config_id),
            payload=payload,
        )
        task = runtime_task_from_record(record)
        record_id = record.id

    if not settings.crawler_inline_execution_enabled:
        return {"status": "pending", "task_id": task.task_id}

    async def _persist_cron_progress(progress_task: CrawlTask) -> None:
        await _persist_crawl_task_progress(record_id, progress_task)

    try:
        from app.domains.crawling.profile_pool import (
            DatabaseProfilePool,
            ProfileAlreadyLeasedError,
            ProfileUnavailableError,
        )
        from app.domains.crawling.task_runner import CrawlTaskRunner

        pool = DatabaseProfilePool()
        try:
            async with AsyncSessionLocal() as lease_db:
                async with pool.lease(
                    lease_db,
                    platform=config_platform,
                    profile_key=profile_key,
                    owner=task.task_id,
                    task_id=task.task_id,
                ) as lease:
                    heartbeat_task = asyncio.create_task(
                        _profile_lease_heartbeat(record_id, pool, lease)
                    )
                    try:
                        await emit_system_log_detached(
                            category="runtime",
                            event_type="job_crawl.started",
                            source="jobs",
                            severity="info",
                            status="running",
                            message=f"Scheduled job crawl for config {config_id} started",
                            user_id=user_id,
                            entity_type="job_config",
                            entity_id=str(config_id),
                            payload=payload,
                        )
                        runtime_context = JobCrawlRuntimeContext(
                            platform=config_platform,
                            profile_key=lease.profile_key,
                            profile_dir=lease.profile_dir,
                            task_id=task.task_id,
                            config_id=config_id,
                            run_id=task.task_id,
                            log_context={"source": task.source, "profile_key": lease.profile_key},
                        )
                        result = await CrawlTaskRunner(
                            progress_callback=_persist_cron_progress
                        ).run_job_config(task, config_id=config_id, runtime_context=runtime_context)
                    finally:
                        await _stop_heartbeat(heartbeat_task)
        except (ProfileAlreadyLeasedError, ProfileUnavailableError) as exc:
            task.status = TaskStatus.FAILED
            task.reason = str(exc)
            await _persist_cron_progress(task)
            result = {"status": "error", "error": str(exc)}

        ok = result.get("status") != "error"
        await _persist_cron_progress(task)
        await emit_system_log_detached(
            category="runtime",
            event_type="job_crawl.completed" if ok else "job_crawl.failed",
            source="jobs",
            severity="info" if ok else "error",
            status="completed" if ok else "failed",
            message=f"Scheduled job crawl for config {config_id} {'completed' if ok else 'failed'}",
            user_id=user_id,
            entity_type="job_config",
            entity_id=str(config_id),
            payload={**payload, **result},
        )
        return result
    except Exception as exc:
        task.status = TaskStatus.FAILED
        task.reason = str(exc)
        await _persist_cron_progress(task)
        await emit_system_log_detached(
            category="runtime",
            event_type="job_crawl.failed",
            source="jobs",
            severity="error",
            status="failed",
            message=f"Scheduled job crawl for config {config_id} failed",
            user_id=user_id,
            entity_type="job_config",
            entity_id=str(config_id),
            payload={**payload, "reason": str(exc)},
        )
        raise


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

    # Group configs by (platform, profile_key), share one adapter per group
    groups = _group_job_configs_for_profile_leases(configs)

    idx = 0
    for (platform, profile_key), platform_configs in groups.items():
        from app.domains.crawling.profile_pool import DatabaseProfilePool

        pool = DatabaseProfilePool()
        try:
            async with AsyncSessionLocal() as lease_db:
                async with pool.lease(
                    lease_db,
                    platform=platform,
                    profile_key=profile_key,
                    owner=f"sync-all-{platform}-{profile_key}",
                    task_id=f"sync-all-{platform}-{profile_key}",
                ) as lease:
                    runtime_context = JobCrawlRuntimeContext(
                        platform=platform,
                        profile_key=lease.profile_key,
                        profile_dir=lease.profile_dir,
                        task_id=None,
                        config_id=None,
                        run_id=f"sync-all-{platform}-{profile_key}",
                        log_context={"source": "manual", "profile_key": lease.profile_key},
                    )
                    adapter = _create_adapter(platform, runtime_context=runtime_context)
                    for config in platform_configs:
                        result = await crawl_single_config(
                            config.id,
                            adapter=adapter,
                            _lock_already_held=True,
                            runtime_context=runtime_context,
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
        except Exception as exc:
            for config in platform_configs:
                details.append({"config_id": config.id, "status": "error", "error": str(exc)})
                error_count += 1

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
    from app.config import settings
    from app.core.task_registry import TaskStatus
    from app.domains.crawling.task_store import (
        create_crawl_task_record,
        runtime_task_from_record,
    )

    async with AsyncSessionLocal() as db:
        config = await db.get(JobSearchConfig, config_id)
        config_platform = _normalize_platform(getattr(config, "platform", "boss")) if config else "boss"
        profile_key = _config_profile_key(config)

    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_config",
            platform=config_platform,
            profile_key=profile_key,
            user_id=user_id,
            entity_type="job_config",
            entity_id=str(config_id),
            payload={"config_id": config_id, "platform": config_platform, "profile_key": profile_key},
        )
        task = runtime_task_from_record(record)
        record_id = record.id

    if not settings.crawler_inline_execution_enabled:
        return task

    async def _persist_cron_progress(progress_task: CrawlTask) -> None:
        await _persist_crawl_task_progress(record_id, progress_task)

    async def _run():
        try:
            # Acquire profile before running the crawl
            from app.domains.crawling.profile_pool import (
                DatabaseProfilePool,
                ProfileAlreadyLeasedError,
                ProfileUnavailableError,
            )

            pool = DatabaseProfilePool()
            try:
                async with AsyncSessionLocal() as lease_db:
                    async with pool.lease(
                        lease_db,
                        platform=config_platform,
                        profile_key=profile_key,
                        owner=task.task_id,
                        task_id=task.task_id,
                    ) as lease:
                        heartbeat_task = asyncio.create_task(
                            _profile_lease_heartbeat(record_id, pool, lease)
                        )
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
                            from app.domains.crawling.task_runner import CrawlTaskRunner

                            runtime_context = JobCrawlRuntimeContext(
                                platform=config_platform,
                                profile_key=lease.profile_key,
                                profile_dir=lease.profile_dir,
                                task_id=task.task_id,
                                config_id=config_id,
                                run_id=task.task_id,
                                log_context={"source": task.source, "profile_key": lease.profile_key},
                            )
                            result = await CrawlTaskRunner(
                                progress_callback=_persist_cron_progress
                            ).run_job_config(task, config_id=config_id, runtime_context=runtime_context)
                        finally:
                            await _stop_heartbeat(heartbeat_task)
                    ok = result.get("status") != "error"
                    await _persist_cron_progress(task)
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
            except (ProfileAlreadyLeasedError, ProfileUnavailableError) as exc:
                task.status = TaskStatus.FAILED
                task.reason = str(exc)
                await _persist_cron_progress(task)
        except Exception as e:
            task.status = TaskStatus.FAILED
            task.reason = str(e)
            await _persist_cron_progress(task)
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
    from app.config import settings
    from app.core.task_registry import TaskStatus
    from app.domains.crawling.task_store import (
        CrawlTaskRecord,
        create_crawl_task_record,
        runtime_task_from_record,
        sync_record_from_runtime_task,
    )

    async with AsyncSessionLocal() as db:
        parent_record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_all",
            platform=None,
            profile_key=None,
            user_id=user_id,
            entity_type="job_crawl",
            entity_id=None,
            payload={"user_id": user_id, "source": "manual"},
        )
        parent_task = runtime_task_from_record(parent_record)
        parent_record_id = parent_record.id

    if not settings.crawler_inline_execution_enabled:
        return parent_task

    async def _persist_parent(progress_task: CrawlTask) -> None:
        async with AsyncSessionLocal() as db:
            record = await db.get(CrawlTaskRecord, parent_record_id)
            if record is not None:
                await sync_record_from_runtime_task(db, record, progress_task)

    parent_task.status = TaskStatus.RUNNING
    await _persist_parent(parent_task)

    async def _run():
        try:
            await emit_system_log_detached(
                category="runtime",
                event_type="job_crawl.started",
                source="jobs",
                severity="info",
                status="running",
                message="Job crawl for all active configs started",
                user_id=parent_task.user_id,
                entity_type="job_crawl",
                entity_id=parent_task.task_id,
                payload={"task_id": parent_task.task_id},
            )

            # Load configs grouped by platform
            async with AsyncSessionLocal() as db:
                from sqlalchemy import select

                from app.models.job import JobSearchConfig

                filters = [JobSearchConfig.active]
                if user_id is not None:
                    filters.append(JobSearchConfig.user_id == user_id)
                result = await db.execute(
                    select(JobSearchConfig).where(*filters)
                )
                configs = list(result.scalars().all())

            if not configs:
                parent_task.status = TaskStatus.COMPLETED
                parent_task.total = 0
                parent_task.success = 0
                parent_task.errors = 0
                await _persist_parent(parent_task)
                return

            # Group by (platform, profile_key), create child tasks
            groups = _group_job_configs_for_profile_leases(configs)

            total_configs = len(configs)
            parent_task.total = total_configs
            parent_task.success = 0
            parent_task.errors = 0
            await _persist_parent(parent_task)

            async def _run_group(
                platform: str,
                profile_key: str,
                platform_configs: list[JobSearchConfig],
            ) -> dict:
                metadata = _job_group_task_metadata(
                    platform, profile_key, parent_task.task_id
                )
                async with AsyncSessionLocal() as db:
                    child_record = await create_crawl_task_record(
                        db,
                        source="manual",
                        task_type=metadata["task_type"],
                        platform=metadata["platform"],
                        profile_key=metadata["profile_key"],
                        parent_task_id=metadata["payload"]["parent_task_id"],
                        user_id=user_id,
                        entity_type=metadata["entity_type"],
                        entity_id=metadata["entity_id"],
                        payload=metadata["payload"],
                    )
                    child_record_id = child_record.id

                async def _persist_child(progress_task: CrawlTask) -> None:
                    async with AsyncSessionLocal() as db:
                        record = await db.get(CrawlTaskRecord, child_record_id)
                        if record is not None:
                            await sync_record_from_runtime_task(db, record, progress_task)

                from app.domains.crawling.profile_pool import DatabaseProfilePool

                child_task = runtime_task_from_record(child_record)
                child_task.status = TaskStatus.RUNNING
                child_task.total = len(platform_configs)
                await _persist_child(child_task)
                pool = DatabaseProfilePool()
                child_details = []
                child_success = 0
                child_errors = 0
                try:
                    async with AsyncSessionLocal() as lease_db:
                        async with pool.lease(
                            lease_db,
                            platform=platform,
                            profile_key=profile_key,
                            owner=child_task.task_id,
                            task_id=child_task.task_id,
                        ) as lease:
                            from app.domains.crawling.task_runner import CrawlTaskRunner

                            heartbeat_task = asyncio.create_task(
                                _profile_lease_heartbeat(
                                    child_record_id,
                                    pool,
                                    lease,
                                )
                            )
                            try:
                                for idx, config in enumerate(platform_configs):
                                    runtime_context = JobCrawlRuntimeContext(
                                        platform=platform,
                                        profile_key=lease.profile_key,
                                        profile_dir=lease.profile_dir,
                                        task_id=child_task.task_id,
                                        config_id=config.id,
                                        run_id=child_task.task_id,
                                        log_context={"parent_task_id": parent_task.task_id},
                                    )
                                    result = await CrawlTaskRunner(
                                        progress_callback=_persist_child
                                    ).run_job_config(
                                        child_task,
                                        config_id=config.id,
                                        runtime_context=runtime_context,
                                    )
                                    detail = {"config_id": config.id, **result}
                                    child_details.append(detail)
                                    if result.get("status") == "success":
                                        child_success += 1
                                    else:
                                        child_errors += 1

                                    if idx < len(platform_configs) - 1:
                                        await asyncio.sleep(random.uniform(3, 6))
                            finally:
                                await _stop_heartbeat(heartbeat_task)
                except Exception as exc:
                    remaining_configs = platform_configs[child_success + child_errors:]
                    child_errors += len(remaining_configs)
                    failed_details = [
                        {
                            "config_id": config.id,
                            "status": "error",
                            "error": str(exc),
                        }
                        for config in remaining_configs
                    ]
                    child_details.extend(failed_details)

                child_task.total = len(platform_configs)
                child_task.success = child_success
                child_task.errors = child_errors
                child_task.details = child_details
                child_task.status = (
                    TaskStatus.COMPLETED
                    if child_errors == 0
                    else TaskStatus.FAILED
                )
                if child_errors:
                    child_task.reason = "platform_crawl_failed"

                async with AsyncSessionLocal() as db:
                    record = await db.get(CrawlTaskRecord, child_record_id)
                    if record is not None:
                        await sync_record_from_runtime_task(db, record, child_task)

                return {
                    "success": child_success,
                    "errors": child_errors,
                    "details": child_details,
                }

            async def _run_profile_lane(
                lane_groups: list[tuple[str, str, list[JobSearchConfig]]],
            ) -> list[dict]:
                lane_results = []
                for platform, profile_key, platform_configs in lane_groups:
                    lane_results.append(
                        await _run_group(platform, profile_key, platform_configs)
                    )
                return lane_results

            lanes = _group_profile_lanes_for_parallelism(groups)

            lane_results = await asyncio.gather(
                *(_run_profile_lane(lane_groups) for lane_groups in lanes.values()),
                return_exceptions=True,
            )

            all_details = []
            for lane_result in lane_results:
                if isinstance(lane_result, Exception):
                    parent_task.errors += 1
                    all_details.append(
                        {
                            "status": "error",
                            "error": str(lane_result),
                        }
                    )
                    continue
                for group_result in lane_result:
                    parent_task.success += group_result["success"]
                    parent_task.errors += group_result["errors"]
                    all_details.extend(group_result["details"])

            parent_task.status = (
                TaskStatus.COMPLETED
                if parent_task.errors == 0
                else TaskStatus.FAILED
            )
            parent_task.details = all_details
            await _persist_parent(parent_task)

            ok = parent_task.errors == 0
            await emit_system_log_detached(
                category="runtime",
                event_type="job_crawl.completed" if ok else "job_crawl.failed",
                source="jobs",
                severity="info" if ok else "error",
                status="completed" if ok else "failed",
                message=f"Job crawl for all active configs {'completed' if ok else 'failed'}",
                user_id=parent_task.user_id,
                entity_type="job_crawl",
                entity_id=parent_task.task_id,
                payload={"task_id": parent_task.task_id, "total": parent_task.total, "success": parent_task.success, "errors": parent_task.errors},
            )
        except Exception as e:
            parent_task.status = TaskStatus.FAILED
            parent_task.reason = str(e)
            await _persist_parent(parent_task)
            await emit_system_log_detached(
                category="runtime",
                event_type="job_crawl.failed",
                source="jobs",
                severity="error",
                status="failed",
                message="Job crawl for all active configs failed",
                user_id=parent_task.user_id,
                entity_type="job_crawl",
                entity_id=parent_task.task_id,
                payload={"task_id": parent_task.task_id, "reason": parent_task.reason},
            )

    asyncio.create_task(_run())
    return parent_task


async def enqueue_job_all_children(
    record: CrawlTaskRecord,
    parent_task: CrawlTask,
    *,
    progress_callback,
) -> dict:
    """Create pending job_platform_profile child tasks for a claimed job_all task."""
    from app.core.task_registry import TaskStatus
    from app.domains.crawling.task_store import (
        create_crawl_task_record,
    )

    user_id = record.user_id

    async with AsyncSessionLocal() as db:
        filters = [JobSearchConfig.active]
        if user_id is not None:
            filters.append(JobSearchConfig.user_id == user_id)
        result = await db.execute(
            select(JobSearchConfig).where(*filters)
        )
        configs = list(result.scalars().all())

    if not configs:
        parent_task.status = TaskStatus.COMPLETED
        parent_task.total = 0
        parent_task.success = 0
        parent_task.errors = 0
        await progress_callback(parent_task)
        return {"status": "completed", "total": 0, "success": 0, "errors": 0}

    groups = _group_job_configs_for_profile_leases(configs)
    child_task_ids: list[str] = []
    child_summaries: list[dict] = []

    for (platform, profile_key), platform_configs in groups.items():
        config_ids = [c.id for c in platform_configs]
        metadata = _job_group_task_metadata(platform, profile_key, parent_task.task_id)
        async with AsyncSessionLocal() as db:
            child_record = await create_crawl_task_record(
                db,
                source="manual",
                task_type=metadata["task_type"],
                platform=metadata["platform"],
                profile_key=metadata["profile_key"],
                parent_task_id=metadata["payload"]["parent_task_id"],
                user_id=user_id,
                entity_type=metadata["entity_type"],
                entity_id=metadata["entity_id"],
                payload={
                    **metadata["payload"],
                    "config_ids": config_ids,
                },
            )
            child_task_ids.append(child_record.task_id)
            child_summaries.append({
                "task_id": child_record.task_id,
                "platform": platform,
                "profile_key": profile_key,
                "config_ids": config_ids,
            })

    parent_task.status = TaskStatus.RUNNING
    parent_task.reason = "waiting_for_children"
    parent_task.total = len(configs)
    parent_task.details = child_summaries
    await progress_callback(parent_task)

    return {"status": "waiting_for_children", "child_task_ids": child_task_ids}


async def execute_job_platform_profile_task(
    record: CrawlTaskRecord,
    child_task: CrawlTask,
    *,
    progress_callback,
) -> dict:
    """Execute one claimed job_platform_profile child task under one profile lease."""
    from app.domains.crawling.profile_pool import DatabaseProfilePool
    from app.domains.crawling.task_runner import CrawlTaskRunner

    payload = record.payload_json or {}
    config_ids = payload.get("config_ids", [])
    platform = payload.get("platform") or record.platform or "boss"
    profile_key = payload.get("profile_key") or record.profile_key or "default"

    child_task.status = TaskStatus.RUNNING
    child_task.total = len(config_ids)
    await progress_callback(child_task)

    pool = DatabaseProfilePool()
    child_details = []
    child_success = 0
    child_errors = 0
    try:
        async with AsyncSessionLocal() as lease_db:
            async with pool.lease(
                lease_db,
                platform=platform,
                profile_key=profile_key,
                owner=child_task.task_id,
                task_id=child_task.task_id,
            ) as lease:
                for idx, config_id in enumerate(config_ids):
                    runtime_context = JobCrawlRuntimeContext(
                        platform=platform,
                        profile_key=lease.profile_key,
                        profile_dir=lease.profile_dir,
                        task_id=child_task.task_id,
                        config_id=config_id,
                        run_id=child_task.task_id,
                        log_context={"parent_task_id": record.parent_task_id},
                    )
                    result = await CrawlTaskRunner(
                        progress_callback=progress_callback
                    ).run_job_config(
                        child_task,
                        config_id=config_id,
                        runtime_context=runtime_context,
                    )
                    detail = {"config_id": config_id, **result}
                    child_details.append(detail)
                    if result.get("status") == "success":
                        child_success += 1
                    else:
                        child_errors += 1

                    if idx < len(config_ids) - 1:
                        await asyncio.sleep(random.uniform(3, 6))
    except Exception as exc:
        remaining = len(config_ids) - child_success - child_errors
        child_errors += remaining
        child_details.append({"status": "error", "error": str(exc)})

    child_task.total = len(config_ids)
    child_task.success = child_success
    child_task.errors = child_errors
    child_task.details = child_details
    child_task.status = TaskStatus.COMPLETED if child_errors == 0 else TaskStatus.FAILED
    if child_errors:
        child_task.reason = "platform_crawl_failed"
    await progress_callback(child_task)

    # Aggregate parent after this child finishes
    if record.parent_task_id:
        await aggregate_parent_task_if_children_finished(record.parent_task_id)

    return {
        "status": "completed" if child_errors == 0 else "error",
        "success": child_success,
        "errors": child_errors,
        "details": child_details,
    }


async def aggregate_parent_task_if_children_finished(parent_task_id: str) -> bool:
    """Aggregate child results into parent task when all children are done."""
    from app.core.task_registry import TaskStatus
    from app.domains.crawling.task_store import (
        CrawlTaskRecord,
        get_crawl_task_record,
        sync_record_from_runtime_task,
    )

    async with AsyncSessionLocal() as db:
        parent_record = await get_crawl_task_record(db, parent_task_id)
        if parent_record is None:
            return False

        result = await db.execute(
            select(CrawlTaskRecord).where(
                CrawlTaskRecord.parent_task_id == parent_task_id,
            )
        )
        children = list(result.scalars().all())

        if not children:
            return False

        # Return False if any child is still pending or running
        for child in children:
            if child.status in (TaskStatus.PENDING.value, TaskStatus.RUNNING.value):
                return False

        total = sum(c.total or 0 for c in children)
        success = sum(c.success or 0 for c in children)
        errors = sum(c.errors or 0 for c in children)

        parent_task = runtime_task_from_record(parent_record)
        parent_task.total = total
        parent_task.success = success
        parent_task.errors = errors
        parent_task.status = TaskStatus.COMPLETED if errors == 0 else TaskStatus.FAILED
        parent_task.reason = None if errors == 0 else "child_task_failed"
        parent_task.details = [
            {
                "task_id": c.task_id,
                "platform": c.platform,
                "profile_key": c.profile_key,
                "status": c.status,
                "total": c.total,
                "success": c.success,
                "errors": c.errors,
                "reason": c.reason,
            }
            for c in children
        ]

        await sync_record_from_runtime_task(db, parent_record, parent_task)

        ok = errors == 0
        await emit_system_log_detached(
            category="runtime",
            event_type="job_crawl.completed" if ok else "job_crawl.failed",
            source="jobs",
            severity="info" if ok else "error",
            status="completed" if ok else "failed",
            message=f"Job crawl for all active configs {'completed' if ok else 'failed'}",
            user_id=parent_record.user_id,
            entity_type="job_crawl",
            entity_id=parent_task_id,
            payload={
                "task_id": parent_task_id,
                "total": total,
                "success": success,
                "errors": errors,
            },
        )

    return True
