"""Crawler task execution facade.

This module keeps Phase 1 in-process while separating task creation from
business crawler execution.
"""

from __future__ import annotations

import logging
from collections.abc import Awaitable, Callable

from app.core.task_registry import CrawlTask, TaskStatus

ProgressCallback = Callable[[CrawlTask], Awaitable[None]]

logger = logging.getLogger(__name__)


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
        task.details = [result]
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
        """Run product crawl for a single platform via OpenCLI (no profile needed)."""
        from app.domains.crawling import service as crawling_service

        task.status = TaskStatus.RUNNING
        await self._notify_progress(task)

        products = await crawling_service.get_active_products(
            user_id=task.user_id or 1, platform=platform
        )
        if not products:
            task.status = TaskStatus.COMPLETED
            task.reason = "no_active_products"
            await self._notify_progress(task)
            return {"status": "completed", "total": 0, "success": 0, "errors": 0, "details": []}

        task.total = len(products)
        await self._notify_progress(task)
        logger.info("Task %s: crawling %d products for platform %s", task.task_id, task.total, platform)

        details: list[dict] = []
        for product in products:
            try:
                result = await crawling_service.crawl_one_opencli(
                    product_id=product.id, platform=product.platform
                )
                details.append(result)
            except Exception as exc:
                details.append({
                    "product_id": product.id,
                    "status": "error",
                    "reason": str(exc),
                    "platform": product.platform,
                })

        task.success = sum(1 for d in details if d.get("status") == "success")
        task.errors = sum(1 for d in details if d.get("status") == "error")
        logger.info(
            "Task %s: platform products crawl done (%d/%d success, %d errors)",
            task.task_id, task.success, task.total, task.errors,
        )
        task.details = details
        task.status = (
            TaskStatus.FAILED
            if task.total > 0 and task.success == 0 and task.errors > 0
            else TaskStatus.COMPLETED
        )
        if task.status == TaskStatus.FAILED:
            task.reason = next(
                (d.get("reason", "crawl_failed") for d in details if d.get("status") == "error"),
                "crawl_failed",
            )
        await self._notify_progress(task)
        return {
            "status": "error" if task.status == TaskStatus.FAILED else "completed",
            "reason": task.reason,
            "total": task.total,
            "success": task.success,
            "errors": task.errors,
            "details": details,
        }

    async def run_all_products(self, task: CrawlTask) -> dict:
        """Run product crawl for all platforms via OpenCLI (no profile needed)."""
        from app.domains.crawling import service as crawling_service

        task.status = TaskStatus.RUNNING
        await self._notify_progress(task)

        user_id = task.user_id or 1
        products = await crawling_service.get_active_products(user_id=user_id)

        if not products:
            task.status = TaskStatus.COMPLETED
            task.reason = "no_active_products"
            logger.info("Task %s: no active products, skipping", task.task_id)
            await self._notify_progress(task)
            return {"status": "completed", "total": 0, "success": 0, "errors": 0, "details": []}

        task.total = len(products)
        await self._notify_progress(task)
        logger.info("Task %s: crawling %d products (all platforms)", task.task_id, task.total)

        details: list[dict] = []
        for product in products:
            try:
                result = await crawling_service.crawl_one_opencli(
                    product_id=product.id, platform=product.platform
                )
                details.append(result)
            except Exception as exc:
                details.append({
                    "product_id": product.id,
                    "status": "error",
                    "reason": str(exc),
                    "platform": product.platform,
                })

        task.success = sum(1 for d in details if d.get("status") == "success")
        task.errors = sum(1 for d in details if d.get("status") == "error")
        logger.info(
            "Task %s: all products crawl done (%d/%d success, %d errors)",
            task.task_id, task.success, task.total, task.errors,
        )
        task.details = details
        task.status = (
            TaskStatus.FAILED
            if task.total > 0 and task.success == 0 and task.errors > 0
            else TaskStatus.COMPLETED
        )
        if task.status == TaskStatus.FAILED:
            task.reason = next(
                (d.get("reason", "crawl_failed") for d in details if d.get("status") == "error"),
                "crawl_failed",
            )
        await self._notify_progress(task)
        return {
            "status": "error" if task.status == TaskStatus.FAILED else "completed",
            "reason": task.reason,
            "total": task.total,
            "success": task.success,
            "errors": task.errors,
            "details": details,
        }
