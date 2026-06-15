"""Liepin platform contract and pipeline tests."""

from __future__ import annotations

from pathlib import Path
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from pydantic import TypeAdapter


def test_job_platform_accepts_liepin():
    from app.schemas.job import JobPlatform

    adapter = TypeAdapter(JobPlatform)

    assert adapter.validate_python("liepin") == "liepin"


def test_create_adapter_supports_liepin(monkeypatch):
    from app.domains.jobs import crawl_service as job_crawl

    class FakeLiepinAdapter:
        pass

    monkeypatch.setattr(
        "app.platforms.LiepinAdapter",
        FakeLiepinAdapter,
        raising=False,
    )

    adapter = job_crawl._create_adapter("liepin")

    assert isinstance(adapter, FakeLiepinAdapter)


def test_create_liepin_adapter_accepts_runtime_profile_dir():
    from app.domains.jobs import crawl_service as job_crawl
    from app.domains.jobs.runtime import JobCrawlRuntimeContext

    context = JobCrawlRuntimeContext(
        platform="liepin",
        profile_key="boss-default-2",
        profile_dir=Path("profiles/boss-default-2"),
        task_id="task-1",
        config_id=3,
        run_id="run-1",
    )

    adapter = job_crawl._create_adapter("liepin", runtime_context=context)

    assert adapter.runtime_context == context
    assert adapter.profile_dir == Path("profiles/boss-default-2")


@pytest.mark.asyncio
async def test_new_job_notification_uses_liepin_label(monkeypatch):
    from app.domains.jobs import notification_service as notification

    sent_messages: list[str] = []

    async def fake_send(_webhook_url: str, message: str) -> dict:
        sent_messages.append(message)
        return {"ok": True}

    monkeypatch.setattr(
        notification,
        "get_cached_user_config",
        AsyncMock(return_value={"feishu_webhook_url": "https://example.test/hook"}),
    )
    monkeypatch.setattr(notification, "send_feishu_notification", fake_send)

    config = SimpleNamespace(name="Liepin Python", platform="liepin", user_id=1)
    result = await notification.send_new_job_notification(config, 2, 20)

    assert result == {"ok": True}
    assert sent_messages
    assert "猎聘新职位提醒" in sent_messages[0]


@pytest.mark.asyncio
async def test_existing_job_missing_detail_is_enriched(monkeypatch):
    from unittest.mock import MagicMock

    from app.domains.jobs.crawl_service import process_job_results

    mock_config = MagicMock()
    mock_config.id = 1
    mock_config.notify_on_new = False
    mock_config.deactivation_threshold = 3
    mock_config.enable_match_analysis = False

    existing_job = MagicMock()
    existing_job.id = 99
    existing_job.job_id = "liepin-1"
    existing_job.search_config_id = 1
    existing_job.is_active = True
    existing_job.consecutive_miss_count = 0
    existing_job.description = ""
    existing_job.address = ""

    active_result = MagicMock()
    active_result.scalars.return_value.all.return_value = [existing_job]
    existing_result = MagicMock()
    existing_result.scalars.return_value.all.return_value = [existing_job]

    mock_db = MagicMock()
    mock_db.get = AsyncMock(return_value=mock_config)
    mock_db.execute = AsyncMock(side_effect=[active_result, existing_result])
    mock_db.add = MagicMock()
    mock_db.commit = AsyncMock()

    update_detail = AsyncMock(return_value={"success": True, "detail": {"description": "D", "address": "A"}})
    monkeypatch.setattr("app.domains.jobs.crawl_service.update_job_detail", update_detail)
    monkeypatch.setattr("app.domains.jobs.crawl_service.asyncio.sleep", AsyncMock())

    class FakeSession:
        async def __aenter__(self):
            return mock_db

        async def __aexit__(self, *_args):
            return None

    monkeypatch.setattr("app.domains.jobs.crawl_service.AsyncSessionLocal", lambda: FakeSession())

    result = await process_job_results(
        1,
        [{"job_id": "liepin-1", "title": "Python", "description": "", "address": ""}],
        platform="liepin",
    )

    assert result["updated_count"] == 1
    update_detail.assert_awaited_once()
    # Now passes Job objects, not raw ints
    assert update_detail.await_args.args[0] is existing_job
    _, kwargs = update_detail.await_args
    assert kwargs["adapter"] is None
    assert kwargs["platform"] == "liepin"
    assert kwargs["db"] is mock_db
    assert "commit" not in kwargs
