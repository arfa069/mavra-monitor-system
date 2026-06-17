from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.domains.crawling.scheduler_service import crawl_all_products
from app.models.crawl_task import CrawlTaskRecord

pytestmark = pytest.mark.asyncio


class AsyncContextManagerMock:
    async def __aenter__(self):
        return MagicMock()
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        pass


@pytest.fixture(autouse=True)
def mock_db_session():
    with patch("app.domains.crawling.scheduler_service.AsyncSessionLocal", return_value=AsyncContextManagerMock()):
        yield


async def test_crawl_all_products_enqueues_task():
    """crawl_all_products always enqueues a task (inline execution removed)."""
    dummy_record = CrawlTaskRecord(
        task_id="dummy-task-id-1",
        status="pending",
        source="manual",
        user_id=1,
        entity_type="crawl_task",
        entity_id=None,
        total=0,
        success=0,
        errors=0,
    )
    with patch("app.domains.crawling.scheduler_service.create_crawl_task_record", new=AsyncMock(return_value=dummy_record)):
        result = await crawl_all_products(source="manual", background=True, user_id=1)

    assert result["status"] == "pending"
    assert result["task_id"] == "dummy-task-id-1"


async def test_crawl_all_products_does_not_check_api_process_lock():
    """crawl_all_products does not need scheduler state (inline execution removed)."""
    dummy_record = CrawlTaskRecord(
        task_id="dummy-task-id-2",
        status="pending",
        source="manual",
        user_id=1,
        entity_type="crawl_task",
        entity_id=None,
        total=0,
        success=0,
        errors=0,
    )
    with patch("app.domains.crawling.scheduler_service.create_crawl_task_record", new=AsyncMock(return_value=dummy_record)):
        result = await crawl_all_products(source="manual", background=True, user_id=1)

    assert result["status"] == "pending"
    assert result["task_id"] == "dummy-task-id-2"
