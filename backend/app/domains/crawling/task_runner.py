"""Crawler task execution facade.

This module keeps Phase 1 in-process while separating task creation from
business crawler execution.
"""

from __future__ import annotations

import asyncio
import random
from collections.abc import Awaitable, Callable

from app.core.task_registry import CrawlTask, TaskStatus

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

    async def run_all_products(self, task: CrawlTask) -> dict:
        from app.domains.crawling.service import get_active_products

        task.status = TaskStatus.RUNNING
        await self._notify_progress(task)
        products = await get_active_products(user_id=task.user_id)
        task.total = len(products)
        await self._notify_progress(task)
        if not products:
            task.status = TaskStatus.COMPLETED
            task.reason = "no_active_products"
            await self._notify_progress(task)
            return {"status": "completed", "total": 0, "success": 0, "errors": 0, "details": []}

        product_ids = [product.id for product in products]
        semaphore = asyncio.Semaphore(PRODUCT_CONCURRENCY_LIMIT)
        crawl_tasks = [
            _crawl_product_with_semaphore(product_id, semaphore)
            for product_id in product_ids
        ]
        results = await asyncio.gather(*crawl_tasks, return_exceptions=True)

        details = []
        for product_id, result in zip(product_ids, results, strict=True):
            if isinstance(result, Exception):
                details.append(
                    {"status": "error", "product_id": product_id, "error": str(result)}
                )
            else:
                details.append(result)

        task.success = sum(1 for item in details if item.get("status") == "success")
        task.errors = sum(1 for item in details if item.get("status") == "error")
        task.details = details
        task.status = TaskStatus.COMPLETED
        await self._notify_progress(task)
        return {
            "status": "completed",
            "total": task.total,
            "success": task.success,
            "errors": task.errors,
            "details": details,
        }
