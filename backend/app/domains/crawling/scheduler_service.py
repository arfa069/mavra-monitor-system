"""Shared scheduler service for crawl-all logic.

Used by both APScheduler cron job and manual crawl-now endpoint.
Provides a single entry point with concurrency protection.
"""
import asyncio
import logging
import random
from typing import Literal

from app.core.system_log import emit_system_log_detached
from app.core.task_registry import CrawlTask, TaskStatus, create_task

logger = logging.getLogger(__name__)

# Deferred import to avoid circular dependency
_scheduler_state: dict | None = None

# Concurrency configuration
CONCURRENCY_LIMIT = 3  # Max simultaneous crawls (balance between speed and anti-bot)
CRAWL_INTERVAL_MIN = 2.0  # Seconds between crawls (was 7-12s)
CRAWL_INTERVAL_MAX = 3.0


def _set_scheduler_state(state: dict) -> None:
    """Called once by main.py lifespan startup."""
    global _scheduler_state
    _scheduler_state = state


async def _crawl_one_with_semaphore(
    product_id: int, semaphore: asyncio.Semaphore, from_app: bool
) -> dict:
    """Crawl a single product with semaphore-controlled concurrency."""
    async with semaphore:
        from app.domains.crawling.router import _crawl_one

        result = await _crawl_one(product_id)
        await asyncio.sleep(random.uniform(CRAWL_INTERVAL_MIN, CRAWL_INTERVAL_MAX))
        return result


async def _run_crawl_task(task: CrawlTask) -> None:
    """Execute the actual crawl and update task status."""
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

        result = await CrawlTaskRunner().run_all_products(task)

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

    # Create task and start background execution
    task = create_task(
        source,
        user_id=user_id,
        entity_type="crawl_task",
        entity_id=None,
    )

    if background:
        # Create background task - it will acquire the lock when it runs
        asyncio.create_task(_run_crawl_in_lock(task, crawl_lock))
        return {
            "status": "pending",
            "task_id": task.task_id,
            "source": source,
        }

    # Synchronous execution (for cron jobs)
    async with crawl_lock:
        logger.info("Crawl started (source=%s, concurrency=%d)", source, CONCURRENCY_LIMIT)
        try:
            from app.domains.crawling.service import get_active_products

            products = await get_active_products(user_id=user_id)
            if not products:
                logger.info("No active products to crawl")
                return {"status": "completed", "total": 0, "success": 0, "errors": 0}

            product_ids = [p.id for p in products]
            semaphore = asyncio.Semaphore(CONCURRENCY_LIMIT)

            tasks = [
                _crawl_one_with_semaphore(pid, semaphore, True) for pid in product_ids
            ]
            results = await asyncio.gather(*tasks, return_exceptions=True)

            processed_results = []
            for i, result in enumerate(results):
                if isinstance(result, Exception):
                    logger.exception("Crawl failed for product %d", product_ids[i])
                    processed_results.append(
                        {"status": "error", "product_id": product_ids[i], "error": str(result)}
                    )
                else:
                    processed_results.append(result)

            success_count = sum(
                1 for r in processed_results if r.get("status") == "success"
            )
            error_count = sum(1 for r in processed_results if r.get("status") == "error")
            return {
                "status": "completed",
                "total": len(products),
                "success": success_count,
                "errors": error_count,
                "details": processed_results,
                "source": source,
            }
        except Exception:
            logger.exception("Crawl failed (source=%s)", source)
            return {"status": "error", "reason": "internal_error", "source": source}


async def _run_crawl_in_lock(task: CrawlTask, crawl_lock: asyncio.Semaphore) -> None:
    """Run crawl task with lock protection."""
    try:
        async with crawl_lock:
            await _run_crawl_task(task)
    finally:
        # Clean up shared browsers after task completes
        await _cleanup_all_shared_browsers()


async def crawl_products_by_platform(user_id: int, platform: str, **kwargs) -> None:
    """Crawl all active products for a specific user + platform.

    Called by ProductCronScheduler cron jobs. Respects concurrency
    limits and logs results.
    """
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
            from app.domains.crawling.service import get_active_products

            semaphore = asyncio.Semaphore(CONCURRENCY_LIMIT)
            products = await get_active_products(user_id=user_id, platform=platform)

            if not products:
                logger.info("No active %s products to crawl for user %s", platform, user_id)
                return

            tasks = [
                _crawl_one_with_semaphore(p.id, semaphore, False)
                for p in products
            ]
            results = await asyncio.gather(*tasks, return_exceptions=True)

            success = sum(1 for r in results if isinstance(r, dict) and r.get("status") == "success")
            errors = sum(1 for r in results if isinstance(r, Exception) or (isinstance(r, dict) and r.get("status") == "error"))
            logger.info("Crawl user=%s %s: %d products, %d success, %d errors", user_id, platform, len(products), success, errors)
    finally:
        await _cleanup_all_shared_browsers()


async def _cleanup_all_shared_browsers() -> None:
    """Close all shared browser instances after crawl task."""
    from app.platforms import AmazonAdapter, JDAdapter, TaobaoAdapter

    for adapter_class in [TaobaoAdapter, JDAdapter, AmazonAdapter]:
        try:
            await adapter_class._close_shared_browser()
        except Exception as exc:
            logger.warning("Failed to close shared browser for class %s: %s", adapter_class.__name__, exc)
