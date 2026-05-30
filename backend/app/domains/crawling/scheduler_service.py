"""Shared scheduler service for crawl-all logic.

Used by both APScheduler cron job and manual crawl-now endpoint.
All tasks are enqueued to the database for Worker processes to pick up.
"""
import logging
from typing import Literal

from app.core.system_log import emit_system_log_detached
from app.database import AsyncSessionLocal
from app.domains.crawling.task_store import (
    create_crawl_task_record,
    runtime_task_from_record,
)

logger = logging.getLogger(__name__)


async def crawl_all_products(
    source: Literal["cron", "manual"],
    background: bool = True,
    *,
    user_id: int | None = None,
) -> dict:
    """Crawl all active products — enqueues a task and returns immediately.

    The worker process picks up the pending crawl_task record.
    """
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

    return {"status": "pending", "task_id": task.task_id, "source": source}


async def crawl_products_by_platform(user_id: int, platform: str, **kwargs) -> None:
    """Crawl all active products for a specific user + platform.

    Called by ProductCronScheduler cron jobs. Enqueues a task for the Worker.
    """
    from app.domains.products import repository as product_repository

    async with AsyncSessionLocal() as db:
        binding = await product_repository.get_product_profile_binding(
            db, user_id=user_id, platform=platform
        )
        profile_key = binding.profile_key if binding else None

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
