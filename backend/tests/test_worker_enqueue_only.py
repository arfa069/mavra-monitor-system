from __future__ import annotations

import pytest

from app.config import settings
from app.domains.crawling.scheduler_service import crawl_all_products

pytestmark = pytest.mark.asyncio


async def test_crawl_all_products_enqueues_without_inline_execution(monkeypatch):
    monkeypatch.setattr(settings, "crawler_inline_execution_enabled", False)

    result = await crawl_all_products(source="manual", background=True, user_id=1)

    assert result["status"] == "pending"
    assert result["task_id"]


async def test_crawl_all_products_does_not_require_api_process_lock(monkeypatch):
    monkeypatch.setattr(settings, "crawler_inline_execution_enabled", False)
    from app.domains.crawling import scheduler_service

    monkeypatch.setattr(scheduler_service, "_scheduler_state", None)

    result = await crawl_all_products(source="manual", background=True, user_id=1)

    assert result["status"] == "pending"
    assert result["task_id"]
