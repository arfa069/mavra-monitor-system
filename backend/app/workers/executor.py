"""Execute claimed crawler tasks."""

from __future__ import annotations

import asyncio
import logging

from app.config import settings
from app.core.system_log import emit_system_log_detached
from app.core.task_registry import TaskStatus
from app.database import AsyncSessionLocal
from app.domains.crawling.profile_pool import ProfileAlreadyLeasedError
from app.domains.crawling.task_store import (
    CrawlTaskRecord,
    renew_task_lease_by_id,
    requeue_claimed_task,
    runtime_task_from_record,
    sync_record_from_runtime_task,
)

logger = logging.getLogger(__name__)


async def _persist(record_id: int, task) -> None:
    async with AsyncSessionLocal() as db:
        record = await db.get(CrawlTaskRecord, record_id)
        if record is not None:
            await sync_record_from_runtime_task(db, record, task)


async def _release_waiting_parent_lease(record_id: int, *, worker_id: str) -> None:
    async with AsyncSessionLocal() as db:
        record = await db.get(CrawlTaskRecord, record_id)
        if (
            record is not None
            and record.status == TaskStatus.RUNNING.value
            and record.reason == "waiting_for_children"
            and record.locked_by == worker_id
        ):
            record.locked_by = None
            record.lease_until = None
            record.heartbeat_at = None
            await db.commit()


async def execute_claimed_task(record: CrawlTaskRecord, *, worker_id: str) -> dict:
    """Run a task that has already been moved to running by task_store."""
    task = runtime_task_from_record(record)
    task.status = TaskStatus.RUNNING

    async def progress_callback(progress_task) -> None:
        await _persist(record.id, progress_task)

    await emit_system_log_detached(
        category="runtime",
        event_type="crawler_worker.task_claimed",
        source="crawler_worker",
        severity="info",
        status="running",
        message=f"Worker {worker_id} claimed task {record.task_id}",
        entity_type="crawl_task",
        entity_id=record.task_id,
        payload={
            "worker_id": worker_id,
            "task_id": record.task_id,
            "task_type": record.task_type,
            "platform": record.platform,
            "profile_key": record.profile_key,
        },
    )
    logger.info(
        "Worker %s claimed task %s (type=%s, platform=%s)",
        worker_id, record.task_id, record.task_type, record.platform or "any",
    )

    heartbeat_task = asyncio.create_task(
        run_task_heartbeat(task_id=record.task_id, worker_id=worker_id)
    )
    try:
        if record.task_type == "product_all":
            from app.domains.crawling.task_runner import CrawlTaskRunner

            result = await CrawlTaskRunner(progress_callback=progress_callback).run_all_products(task)
        elif record.task_type == "product_platform":
            from app.domains.crawling.task_runner import CrawlTaskRunner

            result = await CrawlTaskRunner(progress_callback=progress_callback).run_products_by_platform(
                task,
                platform=record.platform or "",
            )
        elif record.task_type == "job_config":
            result = await _execute_job_config(record, task, progress_callback)
        elif record.task_type == "job_all":
            result = await _execute_job_all(record, task, progress_callback)
        elif record.task_type == "job_platform_profile":
            result = await _execute_job_platform_profile(record, task, progress_callback)
        elif record.task_type == "job_match_analysis":
            result = await _execute_job_match_analysis(record, task, progress_callback)
        else:
            result = {"status": "error", "reason": f"unsupported_task_type:{record.task_type}"}

        if result.get("status") == "waiting_for_children":
            task.status = TaskStatus.RUNNING
            task.reason = "waiting_for_children"
        elif result.get("status") == "error":
            task.status = TaskStatus.FAILED
            task.reason = result.get("reason") or result.get("error") or "task_failed"
        else:
            task.status = TaskStatus.COMPLETED
        await progress_callback(task)
        if result.get("status") == "waiting_for_children":
            await _release_waiting_parent_lease(record.id, worker_id=worker_id)

        # Emit completion event
        if result.get("status") == "waiting_for_children":
            event_type = "crawler_worker.task_waiting_for_children"
            event_status = "running"
            event_severity = "info"
        else:
            event_type = (
                "crawler_worker.task_completed"
                if task.status == TaskStatus.COMPLETED
                else "crawler_worker.task_failed"
            )
            event_status = "completed" if task.status == TaskStatus.COMPLETED else "failed"
            event_severity = "info" if task.status == TaskStatus.COMPLETED else "error"
        await emit_system_log_detached(
            category="runtime",
            event_type=event_type,
            source="crawler_worker",
            severity=event_severity,
            status=event_status,
            message=f"Worker {worker_id} processed task {record.task_id} ({event_status})",
            entity_type="crawl_task",
            entity_id=record.task_id,
            payload={
                "worker_id": worker_id,
                "task_id": record.task_id,
                "task_type": record.task_type,
                "platform": record.platform,
                "profile_key": record.profile_key,
                "reason": task.reason,
            },
        )

        return result
    except ProfileAlreadyLeasedError as exc:
        async with AsyncSessionLocal() as db:
            await requeue_claimed_task(
                db,
                record.task_id,
                worker_id=worker_id,
                reason=f"profile_busy:{exc}",
                retry_delay_seconds=settings.crawler_profile_busy_retry_delay_seconds,
            )
            # Check whether the task was requeued or failed due to max requeue
            refreshed = await db.get(CrawlTaskRecord, record.id)
            if refreshed is not None and refreshed.status == TaskStatus.FAILED.value:
                return {
                    "status": "error",
                    "reason": refreshed.reason or "profile_busy_max_requeue_exceeded",
                }
        return {"status": "deferred", "reason": "profile_busy"}
    except Exception as exc:
        logger.exception("Worker %s failed task %s", worker_id, record.task_id)
        task.status = TaskStatus.FAILED
        task.reason = str(exc)
        await progress_callback(task)
        await emit_system_log_detached(
            category="runtime",
            event_type="crawler_worker.task_failed",
            source="crawler_worker",
            severity="error",
            status="failed",
            message=f"Worker {worker_id} failed task {record.task_id}",
            entity_type="crawl_task",
            entity_id=record.task_id,
            payload={
                "worker_id": worker_id,
                "task_id": record.task_id,
                "task_type": record.task_type,
                "platform": record.platform,
                "profile_key": record.profile_key,
                "reason": str(exc),
            },
        )
        return {"status": "error", "reason": str(exc)}
    finally:
        heartbeat_task.cancel()
        try:
            await heartbeat_task
        except asyncio.CancelledError:
            pass


async def run_task_heartbeat(
    *,
    task_id: str,
    worker_id: str,
    once: bool = False,
) -> bool:
    while True:
        async with AsyncSessionLocal() as db:
            renewed = await renew_task_lease_by_id(
                db,
                task_id,
                worker_id=worker_id,
                lease_seconds=settings.crawler_task_lease_seconds,
            )
        if once:
            return renewed
        if not renewed:
            return False
        await asyncio.sleep(settings.crawler_worker_heartbeat_interval_seconds)


async def _execute_job_config(record: CrawlTaskRecord, task, progress_callback) -> dict:
    from app.domains.crawling.profile_pool import DatabaseProfilePool
    from app.domains.crawling.task_runner import CrawlTaskRunner
    from app.domains.jobs.crawl_service import _config_profile_key, _normalize_platform
    from app.domains.jobs.runtime import JobCrawlRuntimeContext
    from app.models.job import JobSearchConfig

    payload = record.payload_json or {}
    config_id = int(payload.get("config_id") or record.entity_id)
    pool = DatabaseProfilePool()
    async with AsyncSessionLocal() as db:
        config = await db.get(JobSearchConfig, config_id)
        platform = _normalize_platform(getattr(config, "platform", record.platform or "boss")) if config else record.platform or "boss"
        profile_key = _config_profile_key(config)
    async with AsyncSessionLocal() as lease_db:
        async with pool.lease(
            lease_db,
            platform=platform,
            profile_key=profile_key,
            owner=task.task_id,
            task_id=task.task_id,
        ) as lease:
            runtime_context = JobCrawlRuntimeContext(
                platform=platform,
                profile_key=lease.profile_key,
                profile_dir=lease.profile_dir,
                task_id=task.task_id,
                config_id=config_id,
                run_id=task.task_id,
                log_context={"source": task.source, "profile_key": lease.profile_key},
            )
            return await CrawlTaskRunner(progress_callback=progress_callback).run_job_config(
                task,
                config_id=config_id,
                runtime_context=runtime_context,
            )


async def _execute_job_all(record: CrawlTaskRecord, task, progress_callback) -> dict:
    from app.domains.jobs.crawl_service import enqueue_job_all_children

    return await enqueue_job_all_children(record, task, progress_callback=progress_callback)


async def _execute_job_platform_profile(record: CrawlTaskRecord, task, progress_callback) -> dict:
    from app.domains.jobs.crawl_service import execute_job_platform_profile_task

    return await execute_job_platform_profile_task(record, task, progress_callback=progress_callback)


async def _execute_job_match_analysis(record: CrawlTaskRecord, task, progress_callback) -> dict:
    from app.domains.jobs.match_service import _execute_match_analysis

    payload = record.payload_json or {}
    resume_id = payload.get("resume_id")
    job_ids = payload.get("job_ids", [])
    user_id = record.user_id

    if not resume_id or not job_ids:
        task.status = TaskStatus.FAILED
        task.reason = "invalid_payload"
        await progress_callback(task)
        return {"status": "error", "reason": "invalid_payload"}

    async with AsyncSessionLocal() as db:
        await _execute_match_analysis(
            task,
            resume_id=resume_id,
            job_ids=job_ids,
            db=db,
            progress_callback=progress_callback,
            user_id=user_id,
        )

    if task.status == TaskStatus.COMPLETED:
        return {"status": "completed"}
    if task.status == TaskStatus.FAILED:
        return {"status": "error", "reason": task.reason or "analysis_failed"}
    return {"status": "error", "reason": "unexpected_task_status"}
