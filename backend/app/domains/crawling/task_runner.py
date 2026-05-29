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

PRODUCT_CRAWL_INTERVAL_MIN = 2.0
PRODUCT_CRAWL_INTERVAL_MAX = 3.0

def _opencli_enabled_for(platform: str) -> bool:
    """Check if OpenCLI is enabled for the given product platform."""
    from app.config import settings
    if platform == "jd":
        return settings.jd_opencli_enabled
    if platform == "taobao":
        return settings.taobao_opencli_enabled
    return False

PRODUCT_PROFILE_NOT_CONFIGURED = "platform_profile_not_configured"

ProgressCallback = Callable[[CrawlTask], Awaitable[None]]


async def crawl_products_with_profile (
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
    try:
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
                    result["profile_key"] = profile_key
                    results.append(result)
                except Exception as exc:
                    results.append(
                        {
                            "product_id": product_id,
                            "status": "error",
                            "reason": str(exc),
                            "profile_key": profile_key,
                        }
                    )
                await asyncio.sleep(
                    random.uniform(PRODUCT_CRAWL_INTERVAL_MIN, PRODUCT_CRAWL_INTERVAL_MAX)
                )
    except Exception as exc:
        reason = str(exc)
        await _log_lane_start_failure(
            product_ids=product_ids,
            platform=platform,
            reason=reason,
        )
        return [
            {
                "product_id": product_id,
                "status": "error",
                "reason": reason,
                "profile_key": profile_key,
            }
            for product_id in product_ids
        ]
    return results


async def _log_lane_start_failure(
    *,
    product_ids: list[int],
    platform: str,
    reason: str,
) -> None:
    from app.domains.crawling import service as crawling_service

    for product_id in product_ids:
        await crawling_service.save_crawl_log(
            product_id,
            platform,
            "ERROR",
            error_message=reason,
        )


async def _product_profile_groups(
    *,
    user_id: int,
    platform: str | None = None,
) -> tuple[dict[tuple[str, str], list], dict[str, list]]:
    """Group active products by (platform, profile_key)."""
    from app.domains.crawling.service import get_active_products
    from app.domains.products import repository as product_repository

    async with AsyncSessionLocal() as db:
        kwargs: dict = {"user_id": user_id}
        if platform is not None:
            kwargs["platform"] = platform
        products = await get_active_products(**kwargs)
        bindings = await product_repository.list_product_profile_bindings(
            db,
            user_id=user_id,
        )
        binding_by_platform = {binding.platform: binding for binding in bindings}
        groups: dict[tuple[str, str], list] = {}
        missing: dict[str, list] = {}
        for product in products:
            binding = binding_by_platform.get(product.platform)
            if binding is None:
                missing.setdefault(product.platform, []).append(product)
                continue
            profile_key = binding.profile_key
            groups.setdefault((product.platform, profile_key), []).append(product)
    return groups, missing


async def _missing_profile_details(*, platform: str, products: list) -> list[dict]:
    product_ids = [product.id for product in products]
    await _log_lane_start_failure(
        product_ids=product_ids,
        platform=platform,
        reason=PRODUCT_PROFILE_NOT_CONFIGURED,
    )
    return [
        {
            "product_id": product_id,
            "status": "error",
            "reason": PRODUCT_PROFILE_NOT_CONFIGURED,
            "profile_key": None,
        }
        for product_id in product_ids
    ]


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
        """Run product crawl for a single platform using its configured profile."""
        task.status = TaskStatus.RUNNING
        await self._notify_progress(task)
        groups, missing = await _product_profile_groups(user_id=task.user_id or 1, platform=platform)
        if not groups and not missing:
            task.status = TaskStatus.COMPLETED
            task.reason = "no_active_products"
            await self._notify_progress(task)
            return {"status": "completed", "total": 0, "success": 0, "errors": 0, "details": []}

        if missing:
            products = next(iter(missing.values()))
            details = await _missing_profile_details(platform=platform, products=products)
            task.status = TaskStatus.FAILED
            task.reason = PRODUCT_PROFILE_NOT_CONFIGURED
            task.total = len(details)
            task.errors = len(details)
            task.details = details
            await self._notify_progress(task)
            return {
                "status": "error",
                "reason": PRODUCT_PROFILE_NOT_CONFIGURED,
                "profile_key": None,
                "total": task.total,
                "success": 0,
                "errors": task.errors,
                "details": task.details,
            }

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

        try:
            details = await crawl_products_with_profile(
                product_ids=product_ids,
                platform=group_platform,
                profile_key=profile_key,
                task_id=task.task_id,
            )
        except Exception as exc:
            task.status = TaskStatus.FAILED
            task.reason = str(exc)
            task.errors = len(product_ids)
            task.details = [
                {
                    "product_id": product_id,
                    "status": "error",
                    "reason": str(exc),
                    "profile_key": profile_key,
                }
                for product_id in product_ids
            ]
            await self._notify_progress(task)
            return {
                "status": "error",
                "reason": task.reason,
                "profile_key": profile_key,
                "total": task.total,
                "success": 0,
                "errors": task.errors,
                "details": task.details,
            }
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

        from app.domains.crawling import service as crawling_service

        user_id = task.user_id or 1
        groups, missing = await _product_profile_groups(user_id=user_id)

        # ---- OpenCLI: crawl directly without profiles, one by one ----
        opencli_details: list[dict] = []
        for (platform, profile_key), products in list(groups.items()):
            if _opencli_enabled_for(platform):
                del groups[(platform, profile_key)]
                for product in products:
                    try:
                        result = await crawling_service.crawl_one_opencli(
                            product_id=product.id, platform=platform
                        )
                        opencli_details.append(result)
                    except Exception as exc:
                        opencli_details.append({
                            "product_id": product.id,
                            "status": "error",
                            "reason": str(exc),
                            "profile_key": profile_key,
                        })

        if not groups and not missing and not opencli_details:
            task.status = TaskStatus.COMPLETED
            task.reason = "no_active_products"
            await self._notify_progress(task)
            return {"status": "completed", "total": 0, "success": 0, "errors": 0, "details": []}

        total_products = len(opencli_details)
        total_products += sum(len(products) for products in groups.values())
        total_products += sum(len(products) for products in missing.values())
        task.total = total_products
        await self._notify_progress(task)

        async def _run_lane(platform: str, profile_key: str, product_ids: list[int]) -> list[dict]:
            try:
                return await crawl_products_with_profile(
                    product_ids=product_ids,
                    platform=platform,
                    profile_key=profile_key,
                    task_id=task.task_id,
                )
            except Exception as exc:
                return [
                    {
                        "product_id": pid,
                        "status": "error",
                        "reason": str(exc),
                        "profile_key": profile_key,
                    }
                    for pid in product_ids
                ]

        lane_tasks = []
        for (platform, profile_key), products in groups.items():
            product_ids = [product.id for product in products]
            lane_tasks.append(_run_lane(platform, profile_key, product_ids))

        lane_results = await asyncio.gather(*lane_tasks) if lane_tasks else []
        missing_results = [
            await _missing_profile_details(platform=platform, products=products)
            for platform, products in missing.items()
        ]

        all_details: list[dict] = []
        total_success = 0
        total_errors = 0
        for details in [opencli_details, *lane_results, *missing_results]:
            all_details.extend(details)
            total_success += sum(1 for item in details if item.get("status") == "success")
            total_errors += sum(1 for item in details if item.get("status") == "error")

        task.profile_key = None
        task.total = len(all_details)
        task.success = total_success
        task.errors = total_errors
        task.details = all_details
        task.status = (
            TaskStatus.FAILED
            if task.total > 0 and total_success == 0 and total_errors > 0
            else TaskStatus.COMPLETED
        )
        if task.status == TaskStatus.FAILED:
            task.reason = all_details[0].get("reason") if all_details else "crawl_failed"
        await self._notify_progress(task)
        return {
            "status": "error" if task.status == TaskStatus.FAILED else "completed",
            "reason": task.reason,
            "total": task.total,
            "success": task.success,
            "errors": task.errors,
            "details": all_details,
        }
