"""Crawler task execution facade.

This module keeps Phase 1 in-process while separating task creation from
business crawler execution.
"""

from __future__ import annotations

from app.core.task_registry import CrawlTask, TaskStatus


class CrawlTaskRunner:
    async def run_job_config(self, task: CrawlTask, *, config_id: int) -> dict:
        from app.domains.jobs.crawl_service import crawl_single_config

        task.status = TaskStatus.RUNNING
        result = await crawl_single_config(config_id)
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
        return result

    async def run_all_jobs(self, task: CrawlTask) -> dict:
        from app.domains.jobs.crawl_service import crawl_all_job_searches

        task.status = TaskStatus.RUNNING
        result = await crawl_all_job_searches(source=task.source, user_id=task.user_id)
        ok = result.get("status") != "error"
        task.status = TaskStatus.COMPLETED if ok else TaskStatus.FAILED
        task.total = result.get("total", 0)
        task.success = result.get("success", 0)
        task.errors = result.get("errors", 0)
        if not ok:
            task.reason = result.get("error") or result.get("reason") or "crawl_failed"
        return result

    async def run_all_products(self, task: CrawlTask) -> dict:
        from app.domains.crawling.router import _crawl_one
        from app.domains.crawling.service import get_active_products

        task.status = TaskStatus.RUNNING
        products = await get_active_products(user_id=task.user_id)
        task.total = len(products)
        if not products:
            task.status = TaskStatus.COMPLETED
            task.reason = "no_active_products"
            return {"status": "completed", "total": 0, "success": 0, "errors": 0, "details": []}

        details = []
        for product in products:
            try:
                details.append(await _crawl_one(product.id))
            except Exception as exc:
                details.append({"status": "error", "product_id": product.id, "error": str(exc)})

        task.success = sum(1 for item in details if item.get("status") == "success")
        task.errors = sum(1 for item in details if item.get("status") == "error")
        task.details = details
        task.status = TaskStatus.COMPLETED
        return {
            "status": "completed",
            "total": task.total,
            "success": task.success,
            "errors": task.errors,
            "details": details,
        }
