"""Phase 3 integration coverage for multi-platform job crawling."""

from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest


@pytest.mark.asyncio
async def test_new_job_notification_uses_51job_label(monkeypatch):
    """51job crawls should produce a platform-specific notification title."""
    from app.domains.jobs import notification_service as notification

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
    from app.domains.jobs.scheduler import JobConfigScheduler

    scheduler = SimpleNamespace(
        add_job=lambda *args, **kwargs: calls.append((args, kwargs)),
        get_job=lambda _job_id: None,
        remove_job=lambda _job_id: None,
    )
    calls: list[tuple[tuple, dict]] = []

    manager = JobConfigScheduler(scheduler)
    manager.add_job(42, "*/5 * * * *", "Asia/Shanghai")

    assert len(calls) == 1
    args, kwargs = calls[0]
    assert args[0].__name__ == "crawl_scheduled_config"
    assert kwargs["id"] == "job_config_cron_42"
    assert kwargs["kwargs"] == {"config_id": 42, "cron_expression": "*/5 * * * *"}
    assert kwargs["max_instances"] == 1


def test_51job_search_page_targets_we_domain():
    """51job crawl should create its own we.51job.com CloakBrowser page URL."""
    from app.platforms.job51 import Job51Adapter

    assert Job51Adapter._build_search_page("python", "020000") == (
        "https://we.51job.com/pc/search?keyword=python&searchType=2&jobArea=020000"
    )


def test_51job_crawl_uses_cloakbrowser_without_cdp(monkeypatch):
    """51job crawl should fetch through the CloakBrowser page, not a CDP endpoint."""
    import sys
    from types import SimpleNamespace

    from app.platforms.job51 import SEARCH_API_PATH, Job51Adapter

    calls: dict[str, list] = {"launch": [], "goto": [], "evaluate": [], "close": []}

    class FakePage:
        url = "about:blank"

        def goto(self, url: str, **_kwargs):
            calls["goto"].append(url)
            self.url = url

        def reload(self, **_kwargs):
            calls["goto"].append("reload")

        def wait_for_load_state(self, *_args, **_kwargs):
            return None

        def wait_for_timeout(self, *_args, **_kwargs):
            return None

        def evaluate(self, expression, arg=None):
            calls["evaluate"].append((expression, arg))
            if expression == "() => navigator.userAgent":
                return "Fake Chrome"
            if expression == "() => navigator.language":
                return "zh-CN"
            assert SEARCH_API_PATH in arg["apiUrl"]
            return {
                "ok": True,
                "status": 200,
                "contentType": "application/json",
                "body": (
                    '{"resultbody":{"job":{"items":['
                    '{"jobId":"j1","jobName":"Python","fullCompanyName":"Acme"}'
                    '],"total_page":1}}}'
                ),
            }

    class FakeContext:
        def __init__(self):
            self.page = FakePage()

        def new_page(self):
            return self.page

        def cookies(self, _urls):
            return [{"name": "guid", "value": "cookie", "domain": ".51job.com", "path": "/"}]

        def close(self):
            calls["close"].append(True)

    def launch_persistent_context(*args, **kwargs):
        calls["launch"].append((args, kwargs))
        return FakeContext()

    monkeypatch.setitem(
        sys.modules,
        "cloakbrowser",
        SimpleNamespace(launch_persistent_context=launch_persistent_context),
    )

    result = Job51Adapter(profile_dir="profile", max_pages=1)._crawl_sync(
        "https://we.51job.com/pc/search?keyword=python&jobArea=020000"
    )

    assert result["success"] is True
    assert result["count"] == 1
    assert calls["launch"][0][0] == ("profile",)
    assert calls["goto"] == ["https://we.51job.com/pc/search?keyword=python&searchType=2&jobArea=020000"]
    assert calls["close"] == [True]


def test_51job_adapter_accepts_explicit_profile_dir(monkeypatch):
    from pathlib import Path

    from app.platforms.job51 import Job51Adapter

    custom_dir = "/custom/profiles/51job/test"
    adapter = Job51Adapter(profile_dir=custom_dir)

    assert adapter.profile_dir == Path(custom_dir)


def test_51job_waf_fuse_stops_after_limit(monkeypatch):
    from app.platforms.job51 import Job51Adapter

    adapter = Job51Adapter(profile_dir="profile", max_pages=5)
    adapter._waf_hits = 2

    assert adapter._should_stop_for_waf() is True


def test_51job_first_waf_preserves_failure_category(monkeypatch):
    from app.platforms.job51 import Job51Adapter

    adapter = Job51Adapter(profile_dir="profile", max_pages=1)
    monkeypatch.setattr(adapter, "_start_browser", lambda: None)
    monkeypatch.setattr(adapter, "_refresh_cookies_sync", lambda _reason: True)

    def raise_waf(_keyword, _job_area, _page_num):
        adapter._waf_hits += 1
        raise RuntimeError("51job WAF")

    monkeypatch.setattr(adapter, "_fetch_search_page_sync", raise_waf)

    result = adapter._crawl_sync(
        "https://we.51job.com/pc/search?keyword=python&jobArea=020000"
    )

    assert result == {
        "success": False,
        "error": "51job WAF response detected",
        "failure_category": "waf",
    }


def test_51job_classifies_html_waf_response():
    from app.platforms.job51 import classify_51job_response

    category = classify_51job_response(
        {"ok": True, "status": 200, "contentType": "text/html", "body": "<html>安全验证</html>"}
    )

    assert category == "waf"


def test_51job_http_experiment_returns_metrics(monkeypatch):
    from app.platforms.job51 import Job51Adapter

    adapter = Job51Adapter(profile_dir="profile", max_pages=1)
    monkeypatch.setattr(
        adapter,
        "_http_experiment_fetch",
        lambda url: {"success": False, "failure_category": "waf", "elapsed_ms": 25},
    )

    result = adapter.run_http_experiment(["https://we.51job.com/pc/search?keyword=python"])

    assert result["total"] == 1
    assert result["success_rate"] == 0.0
    assert result["waf_hit_rate"] == 1.0
