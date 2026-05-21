"""Phase 3 integration coverage for multi-platform job crawling."""

from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest


@pytest.mark.asyncio
async def test_new_job_notification_uses_51job_label(monkeypatch):
    """51job crawls should produce a platform-specific notification title."""
    from app.services import notification

    sent_messages: list[str] = []

    async def _fake_send(_webhook_url: str, message: str) -> dict:
        sent_messages.append(message)
        return {"ok": True}

    monkeypatch.setattr(
        notification,
        "get_cached_user_config",
        AsyncMock(return_value={"feishu_webhook_url": "https://example.test/hook"}),
    )
    monkeypatch.setattr(notification, "send_feishu_notification", _fake_send)

    config = SimpleNamespace(name="51job Python", platform="51job")
    result = await notification.send_new_job_notification(config, 3, 50)

    assert result == {"ok": True}
    assert sent_messages
    assert "前程无忧新职位提醒" in sent_messages[0]
    assert "51job Python" in sent_messages[0]


def test_job_config_scheduler_registers_platform_agnostic_config_job():
    """Cron scheduling should dispatch by config id so 51job uses normal routing."""
    from app.services.scheduler_job import JobConfigScheduler

    scheduler = SimpleNamespace(
        add_job=lambda *args, **kwargs: calls.append((args, kwargs)),
        get_job=lambda _job_id: None,
        remove_job=lambda _job_id: None,
    )
    calls: list[tuple[tuple, dict]] = []

    manager = JobConfigScheduler(scheduler)
    manager.add_job(42, "*/5 * * * *", "Asia/Shanghai")

    assert len(calls) == 1
    _, kwargs = calls[0]
    assert kwargs["id"] == "job_config_cron_42"
    assert kwargs["kwargs"] == {"config_id": 42, "cron_expression": "*/5 * * * *"}
    assert kwargs["max_instances"] == 1


@pytest.mark.asyncio
async def test_51job_cdp_page_lookup_does_not_fallback_to_other_domains(monkeypatch):
    """51job search fetch must not run inside unrelated browser tabs."""
    import http.client
    import json

    from app.platforms.job51 import Job51Adapter

    class FakeResponse:
        def read(self) -> bytes:
            return json.dumps([
                {
                    "url": "https://www.taobao.com/",
                    "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/page/taobao",
                },
                {
                    "url": "https://www.51job.com/",
                    "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/page/www-51job",
                },
                {
                    "url": "edge://newtab/",
                    "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/page/newtab",
                },
            ]).encode()

    class FakeConnection:
        def __init__(self, *_args, **_kwargs):
            self.closed = False

        def request(self, _method: str, _path: str) -> None:
            return None

        def getresponse(self) -> FakeResponse:
            return FakeResponse()

        def close(self) -> None:
            self.closed = True

    monkeypatch.setattr(http.client, "HTTPConnection", FakeConnection)

    assert await Job51Adapter._find_page_ws() is None


@pytest.mark.asyncio
async def test_51job_can_open_temporary_search_tab(monkeypatch):
    """51job crawl can create its own we.51job.com page when none is open."""
    import http.client
    import json

    from app.platforms.job51 import Job51Adapter

    requests: list[tuple[str, str]] = []

    class FakeResponse:
        def read(self) -> bytes:
            return json.dumps({
                "id": "target-51job",
                "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/page/target-51job",
            }).encode()

    class FakeConnection:
        def __init__(self, *_args, **_kwargs):
            pass

        def request(self, method: str, path: str) -> None:
            requests.append((method, path))

        def getresponse(self) -> FakeResponse:
            return FakeResponse()

        def close(self) -> None:
            pass

    monkeypatch.setattr(http.client, "HTTPConnection", FakeConnection)

    ws_url, target_id = await Job51Adapter._open_search_page_ws("python", "020000")

    assert ws_url == "ws://127.0.0.1:9222/devtools/page/target-51job"
    assert target_id == "target-51job"
    assert requests[0][0] == "PUT"
    assert requests[0][1].startswith("/json/new?https%3A%2F%2Fwe.51job.com%2Fpc%2Fsearch")


@pytest.mark.asyncio
async def test_51job_closes_temporary_search_tab(monkeypatch):
    """Only the temporary CDP tab created for crawling should be closed."""
    import http.client

    from app.platforms.job51 import Job51Adapter

    requests: list[tuple[str, str]] = []

    class FakeConnection:
        def __init__(self, *_args, **_kwargs):
            pass

        def request(self, method: str, path: str) -> None:
            requests.append((method, path))

        def getresponse(self):
            return object()

        def close(self) -> None:
            pass

    monkeypatch.setattr(http.client, "HTTPConnection", FakeConnection)

    await Job51Adapter._close_page("target-51job")

    assert requests == [("GET", "/json/close/target-51job")]
