"""Crawler task execution facade.

This module keeps Phase 1 in-process while separating task creation from
business crawler execution.
"""

from __future__ import annotations

import asyncio
import random
from collections.abc import Awaitable, Callable

from app.core.task_registry import CrawlTask, TaskStatus
from app.database import AsyncSessionLocal

PRODUCT_CONCURRENCY_LIMIT = 3
PRODUCT_CRAWL_INTERVAL_MIN = 2.0
PRODUCT_CRAWL_INTERVAL_MAX = 3.0

ProgressCallback = Callable[[CrawlTask], Awaitable[None]]


async def _crawl_product_with_semaphore(
    product_id: int,
    semaphore: asyncio.Semaphore,
) -> dict:
    async with semaphore:
        from app.domains.crawling.router import _crawl_one

        result = await _crawl_one(product_id)
        await asyncio.sleep(
            random.uniform(PRODUCT_CRAWL_INTERVAL_MIN, PRODUCT_CRAWL_INTERVAL_MAX)
        )
        return result


async def crawl_products_with_profile(
    *,
    product_ids: list[int],
    platform: str,
    profile_key: str,
    task_id: str,
) -> list[dict]:
    """Crawl products for a single platform profile lane."""
    from app.domains.crawling import service as crawling_service
    from app.domains.crawling.browser_manager import BrowserManager

    results: list[dict] = []
    manager = BrowserManager()
    async with manager.acquire(
        platform=platform,
        profile_key=profile_key,
        owner="product-crawler",
        task_id=task_id,
    ) as session:
        for product_id in product_ids:
            try:
                result = await crawling_service.crawl_one_with_session(
                    product_id=product_id,
                    session=session,
                )
                results.append(result)
            except Exception as exc:
                results.append(
                    {
                        "product_id": product_id,
                        "status": "error",
                        "reason": str(exc),
                    }
                )
            await asyncio.sleep(
                random.uniform(PRODUCT_CRAWL_INTERVAL_MIN, PRODUCT_CRAWL_INTERVAL_MAX)
            )
    return results


async def _product_profile_groups(
    *,
    user_id: int,
    platform: str | None = None,
) -> dict[tuple[str, str], list]:
    """Group active products by (platform, profile_key)."""
    from app.domains.crawling.service import get_active_products
    from app.domains.products import repository as product_repository
    from app.domains.products.profile_binding import default_product_profile_key

    async with AsyncSessionLocal() as db:
        kwargs: dict = {"user_id": user_id}
        if platform is not None:
            kwargs["platform"] = platform
        products = await get_active_products(**kwargs)
        groups: dict[tuple[str, str], list] = {}
        for product in products:
            config = await product_repository.get_product_cron_config(
                db,
                user_id=user_id,
                platform=product.platform,
            )
            profile_key = (
                config.profile_key
                if config is not None
                else default_product_profile_key(product.platform)
            )
            groups.setdefault((product.platform, profile_key), []).append(product)
    return groups


class CrawlTaskRunner:
    def __init__(self, *, progress_callback: ProgressCallback | None = None):
        self._progress_callback = progress_callback

    async def _notify_progress(self, task: CrawlTask) -> None:
        if self._progress_callback is not None:
            await self._progress_callback(task)

    async def run_job_config(
        self,
        task: CrawlTask,
        *,
        config_id: int,
        runtime_context=None,
    ) -> dict:
        from app.domains.jobs.crawl_service import crawl_single_config

        task.status = TaskStatus.RUNNING
        await self._notify_progress(task)
        result = await crawl_single_config(config_id, runtime_context=runtime_context)
        ok = result.get("status") != "error"
        task.status = TaskStatus.COMPLETED if ok else TaskStatus.FAILED
        task.total = sum(
            result.get(key, 0)
            for key in ("new_count", "updated_count", "deactivated_count")
        )
        task.success = result.get("new_count", 0)
        task.errors = 0 if ok else 1
        if not ok:
            task.reason = result.get("error") or result.get("reason") or "crawl_failed"
        await self._notify_progress(task)
        return result

    async def run_all_jobs(self, task: CrawlTask) -> dict:
        from app.domains.jobs.crawl_service import crawl_all_job_searches

        task.status = TaskStatus.RUNNING
        await self._notify_progress(task)
        result = await crawl_all_job_searches(source=task.source, user_id=task.user_id)
        ok = result.get("status") != "error"
        task.status = TaskStatus.COMPLETED if ok else TaskStatus.FAILED
        task.total = result.get("total", 0)
        task.success = result.get("success", 0)
        task.errors = result.get("errors", 0)
        if not ok:
            task.reason = result.get("error") or result.get("reason") or "crawl_failed"
        await self._notify_progress(task)
        return result

    async def run_products_by_platform(self, task: CrawlTask, *, platform: str) -> dict:
        """Run product crawl for a single platform using its configured profile."""
        task.status = TaskStatus.RUNNING
        await self._notify_progress(task)
        groups = await _product_profile_groups(user_id=task.user_id or 1, platform=platform)
        if not groups:
            task.status = TaskStatus.COMPLETED
            task.reason = "no_active_products"
            await self._notify_progress(task)
            return {"status": "completed", "total": 0, "success": 0, "errors": 0, "details": []}

        if len(groups) != 1:
            task.status = TaskStatus.FAILED
            task.reason = "ambiguous_product_profile_group"
            await self._notify_progress(task)
            return {"status": "error", "reason": task.reason}

        (group_platform, profile_key), products = next(iter(groups.items()))
        product_ids = [product.id for product in products]
        task.profile_key = profile_key
        task.total = len(product_ids)
        await self._notify_progress(task)

        details = await crawl_products_with_profile(
            product_ids=product_ids,
            platform=group_platform,
            profile_key=profile_key,
            task_id=task.task_id,
        )
        task.success = sum(1 for item in details if item.get("status") == "success")
        task.errors = sum(1 for item in details if item.get("status") == "error")
        task.details = details
        task.status = TaskStatus.COMPLETED
        await self._notify_progress(task)
        return {
            "status": "completed",
            "profile_key": profile_key,
            "total": task.total,
            "success": task.success,
            "errors": task.errors,
            "details": details,
        }

    async def run_all_products(self, task: CrawlTask) -> dict:
        task.status = TaskStatus.RUNNING
        await self._notify_progress(task)
        groups = await _product_profile_groups(user_id=task.user_id or 1)
        if not groups:
            task.status = TaskStatus.COMPLETED
            task.reason = "no_active_products"
            await self._notify_progress(task)
            return {"status": "completed", "total": 0, "success": 0, "errors": 0, "details": []}

        all_details: list[dict] = []
        total_success = 0
        total_errors = 0

        # Run each profile lane serially to avoid sharing AsyncSession across lanes
        for (platform, profile_key), products in groups.items():
            product_ids = [product.id for product in products]
            task.profile_key = profile_key
            task.total = len(product_ids)
            await self._notify_progress(task)

            try:
                details = await crawl_products_with_profile(
                    product_ids=product_ids,
                    platform=platform,
                    profile_key=profile_key,
                    task_id=task.task_id,
                )
            except Exception as exc:
                details = [
                    {
                        "product_id": pid,
                        "status": "error",
                        "reason": str(exc),
                    }
                    for pid in product_ids
                ]
            all_details.extend(details)
            total_success += sum(1 for item in details if item.get("status") == "success")
            total_errors += sum(1 for item in details if item.get("status") == "error")

        task.profile_key = None
        task.total = len(all_details)
        task.success = total_success
        task.errors = total_errors
        task.details = all_details
        task.status = TaskStatus.COMPLETED
        await self._notify_progress(task)
        return {
            "status": "completed",
            "total": task.total,
            "success": task.success,
            "errors": task.errors,
            "details": all_details,
        }
