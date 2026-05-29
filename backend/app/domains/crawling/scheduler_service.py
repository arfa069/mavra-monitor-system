"""Shared scheduler service for crawl-all logic.

Used by both APScheduler cron job and manual crawl-now endpoint.
Provides a single entry point with concurrency protection.
"""
import asyncio
import logging
from typing import Literal

from app.config import settings
from app.core.system_log import emit_system_log_detached
from app.core.task_registry import CrawlTask, TaskStatus
from app.database import AsyncSessionLocal
from app.domains.crawling.task_store import (
    CrawlTaskRecord,
    create_crawl_task_record,
    runtime_task_from_record,
    sync_record_from_runtime_task,
)

logger = logging.getLogger(__name__)

# Deferred import to avoid circular dependency
_scheduler_state: dict | None = None


def _set_scheduler_state(state: dict) -> None:
    """Called once by main.py lifespan startup."""
    global _scheduler_state
    _scheduler_state = state


async def _run_crawl_task(task: CrawlTask, *, record_id: int | None = None) -> None:
    """Execute the actual crawl and update task status.

    When *record_id* is provided, persist task progress to the database.
    """

    async def _persist_progress(progress_task: CrawlTask) -> None:
        if record_id is None:
            return
        async with AsyncSessionLocal() as db:
            record = await db.get(CrawlTaskRecord, record_id)
            if record is not None:
                await sync_record_from_runtime_task(db, record, progress_task)

    task.status = TaskStatus.RUNNING
    logger.info(f"Task {task.task_id}: started (source={task.source})")
    await emit_system_log_detached(
        category="runtime",
        event_type="product_crawl.started",
        source="products",
        severity="info",
        status="running",
        message=f"Product crawl task {task.task_id} started",
        user_id=task.user_id,
        entity_type=task.entity_type or "crawl_task",
        entity_id=task.entity_id or task.task_id,
        payload={"task_id": task.task_id, "source": task.source},
    )

    try:
        from app.domains.crawling.task_runner import CrawlTaskRunner

        result = await CrawlTaskRunner(progress_callback=_persist_progress).run_all_products(task)

        if result.get("reason") == "no_active_products":
            logger.info(f"Task {task.task_id}: no active products")
            await emit_system_log_detached(
                category="runtime",
                event_type="product_crawl.completed",
                source="products",
                severity="info",
                status="completed",
                message=f"Product crawl task {task.task_id} completed with no active products",
                user_id=task.user_id,
                entity_type=task.entity_type or "crawl_task",
                entity_id=task.entity_id or task.task_id,
                payload={"task_id": task.task_id, "reason": task.reason},
            )
            return

        if result.get("details") and task.details is None:
            task.details = result["details"]

        logger.info(f"Task {task.task_id}: completed ({task.success} success, {task.errors} errors)")
        await emit_system_log_detached(
            category="runtime",
            event_type="product_crawl.completed",
            source="products",
            severity="info" if task.errors == 0 else "warning",
            status="completed",
            message=f"Product crawl task {task.task_id} completed",
            user_id=task.user_id,
            entity_type=task.entity_type or "crawl_task",
            entity_id=task.entity_id or task.task_id,
            payload={
                "task_id": task.task_id,
                "total": task.total,
                "success": task.success,
                "errors": task.errors,
            },
        )

    except Exception as e:
        logger.exception(f"Task {task.task_id}: failed")
        task.status = TaskStatus.FAILED
        task.reason = str(e)
        await emit_system_log_detached(
            category="runtime",
            event_type="product_crawl.failed",
            source="products",
            severity="error",
            status="failed",
            message=f"Product crawl task {task.task_id} failed",
            user_id=task.user_id,
            entity_type=task.entity_type or "crawl_task",
            entity_id=task.entity_id or task.task_id,
            payload={"task_id": task.task_id, "reason": task.reason},
        )


async def crawl_all_products(
    source: Literal["cron", "manual"],
    background: bool = True,
    *,
    user_id: int | None = None,
) -> dict:
    """Start crawl all active products with concurrency protection.

    Uses a shared Semaphore to prevent overlapping executions from
    both cron-triggered and manually-triggered crawl operations.

    Args:
        source: "cron" for APScheduler-triggered, "manual" for HTTP endpoint
        background: If True, run crawl in background and return task ID immediately.
                   If False, wait for completion (for cron jobs).

    Returns:
        dict with task_id (if background=True) or full results
    """
    # Create persistent task record first (worker-only path does not need locks)
    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source=source,
            task_type="product_all",
            platform=None,
            profile_key=None,
            user_id=user_id,
            entity_type="crawl_task",
            entity_id=None,
        )
        task = runtime_task_from_record(record)

    if not settings.crawler_inline_execution_enabled:
        return {"status": "pending", "task_id": task.task_id, "source": source}

    # Inline fallback path (original lock-protected behaviour)
    if _scheduler_state is None:
        logger.error("Scheduler state not initialized")
        return {"status": "error", "reason": "scheduler_not_initialized"}

    crawl_lock: asyncio.Semaphore = _scheduler_state.get("crawl_lock")
    if crawl_lock is None:
        logger.error("crawl_lock not initialized")
        return {"status": "error", "reason": "lock_not_initialized"}

    if crawl_lock.locked():
        logger.warning("Crawl skipped: another crawl is in progress (source=%s)", source)
        return {
            "status": "skipped",
            "reason": "another_crawl_in_progress",
            "source": source,
        }

    if background:
        # Create background task - it will acquire the lock when it runs
        asyncio.create_task(_run_crawl_in_lock(task, crawl_lock, record_id=record.id))
        return {
            "status": "pending",
            "task_id": task.task_id,
            "source": source,
        }

    async with crawl_lock:
        await _run_crawl_task(task, record_id=record.id)
        return {
            "status": "error" if task.status == TaskStatus.FAILED else task.status.value,
            "task_id": task.task_id,
            "total": task.total,
            "success": task.success,
            "errors": task.errors,
            "details": task.details,
            "reason": task.reason,
            "source": source,
        }


async def _run_crawl_in_lock(task: CrawlTask, crawl_lock: asyncio.Semaphore, *, record_id: int | None = None) -> None:
    """Run crawl task with lock protection."""
    try:
        async with crawl_lock:
            await _run_crawl_task(task, record_id=record_id)
    finally:
        # Clean up shared browsers after task completes
        await _cleanup_all_shared_browsers()


async def crawl_products_by_platform(user_id: int, platform: str, **kwargs) -> None:
    """Crawl all active products for a specific user + platform.

    Called by ProductCronScheduler cron jobs. Uses profile-first runner.
    Persists task state to crawl_tasks.
    """
    from app.domains.products import repository as product_repository

    # Resolve profile key from product platform binding. The cron config only owns timing.
    async with AsyncSessionLocal() as db:
        binding = await product_repository.get_product_profile_binding(
            db, user_id=user_id, platform=platform
        )
        profile_key = binding.profile_key if binding else None

    # Create persistent task record with profile_key
    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="cron",
            task_type="product_platform",
            platform=platform,
            profile_key=profile_key,
            user_id=user_id,
            entity_type="product_platform",
            entity_id=platform,
            payload={"platform": platform, "profile_key": profile_key},
        )
        task = runtime_task_from_record(record)

    if not settings.crawler_inline_execution_enabled:
        await emit_system_log_detached(
            category="runtime",
            event_type="product_crawl.enqueued",
            source="products",
            severity="info",
            status="pending",
            message=f"Product crawl enqueued for {platform}",
            user_id=user_id,
            entity_type="product_platform",
            entity_id=platform,
            payload={"task_id": task.task_id, "platform": platform, "profile_key": profile_key},
        )
        return

    # Inline fallback path
    if _scheduler_state is None:
        logger.error("Scheduler state not initialized in crawl_products_by_platform")
        return

    crawl_lock: asyncio.Semaphore = _scheduler_state.get("crawl_lock")
    if crawl_lock is None:
        logger.error("crawl_lock not initialized in crawl_products_by_platform")
        return

    if crawl_lock.locked():
        logger.warning(
            "Crawl skipped for platform %s user %d: another crawl task is in progress",
            platform, user_id
        )
        return

    try:
        async with crawl_lock:
            from app.domains.crawling.task_store import mark_task_running

            async with AsyncSessionLocal() as db:
                await mark_task_running(db, record, owner="cron")

            async def _persist_progress(progress_task: CrawlTask) -> None:
                async with AsyncSessionLocal() as db_inner:
                    rec = await db_inner.get(CrawlTaskRecord, record.id)
                    if rec is not None:
                        await sync_record_from_runtime_task(db_inner, rec, progress_task)

            from app.domains.crawling.task_runner import CrawlTaskRunner

            result = await CrawlTaskRunner(progress_callback=_persist_progress).run_products_by_platform(
                task, platform=platform
            )

            logger.info(
                "Crawl user=%s %s profile=%s: %d products, %d success, %d errors",
                user_id, platform, profile_key,
                result.get("total", 0), result.get("success", 0), result.get("errors", 0)
            )
    finally:
        await _cleanup_all_shared_browsers()


async def _cleanup_all_shared_browsers() -> None:
    """Close all shared browser instances after crawl task.

    No-op: browser-based product adapters have been removed.
    Product crawling now uses OpenCLI without shared browsers.
    """
