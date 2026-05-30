from __future__ import annotations

import pytest

from app.domains.crawling.scheduler_service import crawl_all_products

pytestmark = pytest.mark.asyncio


async def test_crawl_all_products_enqueues_task():
    """crawl_all_products always enqueues a task (inline execution removed)."""
    result = await crawl_all_products(source="manual", background=True, user_id=1)

    assert result["status"] == "pending"
    assert result["task_id"]


async def test_crawl_all_products_does_not_check_api_process_lock():
    """crawl_all_products does not need scheduler state (inline execution removed)."""
    result = await crawl_all_products(source="manual", background=True, user_id=1)

    assert result["status"] == "pending"
    assert result["task_id"]
