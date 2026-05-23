"""Tests for user-scoped product crawl scheduling."""
from unittest.mock import AsyncMock, patch

import pytest


@pytest.mark.asyncio
async def test_manual_crawl_task_fetches_only_requesting_users_products():
    """A user-scoped crawl task must not fetch all active products."""
    from app.core.task_registry import CrawlTask
    from app.domains.crawling.scheduler_service import _run_crawl_task

    task = CrawlTask(task_id="task-user-42", source="manual", user_id=42)

    with (
        patch("app.domains.crawling.scheduler_service.emit_system_log_detached", new_callable=AsyncMock),
        patch("app.domains.crawling.service.get_active_products", new_callable=AsyncMock) as get_products,
    ):
        get_products.return_value = []

        await _run_crawl_task(task)

    get_products.assert_awaited_once_with(user_id=42)
