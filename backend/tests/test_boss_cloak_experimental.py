import json
from unittest.mock import MagicMock

import pytest


def test_transform_job_preserves_lid_and_security_id():
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    job = BossCloakExperimentalAdapter._transform_job(
        {
            "securityId": "sid",
            "encryptJobId": "eid",
            "jobName": "Python",
            "brandName": "Acme",
            "salaryDesc": "20-30K",
            "cityName": "广州",
            "jobExperience": "3-5年",
            "jobDegree": "本科",
        },
        "lid-1",
    )

    assert job["job_id"] == "sid"
    assert job["lid"] == "lid-1"
    assert job["url"] == "https://www.zhipin.com/job_detail/eid.html"


def test_refresh_cookies_copies_full_cookie_scope_and_headers():
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    adapter = BossCloakExperimentalAdapter()
    adapter._search_page = "https://www.zhipin.com/web/geek/jobs?query=python&city=101280100"
    adapter._session = MagicMock()
    adapter._cloak_page = MagicMock()
    adapter._cloak_context = MagicMock()
    adapter._cloak_context.cookies.return_value = [
        {"name": "__zp_stoken__", "value": "token", "domain": ".zhipin.com", "path": "/"},
        {"name": "ab_guid", "value": "guid", "domain": "www.zhipin.com", "path": "/"},
    ]
    adapter._cloak_page.evaluate.side_effect = [
        "Mozilla/5.0 Chrome/146",
        "zh-CN",
    ]

    adapter._refresh_cookies("test")

    adapter._session.cookies.set.assert_any_call(
        "__zp_stoken__",
        "token",
        domain=".zhipin.com",
        path="/",
    )
    adapter._session.cookies.set.assert_any_call(
        "ab_guid",
        "guid",
        domain="www.zhipin.com",
        path="/",
    )
    assert adapter._headers["Referer"] == adapter._search_page
    assert adapter._headers["X-Requested-With"] == "XMLHttpRequest"


def test_post_job_page_uses_real_boss_form_shape():
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    response = MagicMock()
    response.status_code = 200
    response.json.return_value = {"code": 0, "zpData": {"jobList": []}}
    adapter = BossCloakExperimentalAdapter()
    adapter._session = MagicMock()
    adapter._session.post.return_value = response
    adapter._headers = {"Referer": "search"}

    result = adapter._post_job_page("python", "101280100", 2)

    assert result["code"] == 0
    _, kwargs = adapter._session.post.call_args
    assert kwargs["data"]["page"] == "2"
    assert kwargs["data"]["pageSize"] == "30"
    assert kwargs["data"]["city"] == "101280100"
    assert kwargs["data"]["query"] == "python"
    assert kwargs["data"]["scene"] == "1"
    assert kwargs["headers"]["Content-Type"] == "application/x-www-form-urlencoded"
    assert kwargs["impersonate"] == "chrome124"


@pytest.mark.asyncio
async def test_crawl_serially_fetches_details(monkeypatch):
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    adapter = BossCloakExperimentalAdapter(max_jobs=2, max_pages=1)
    monkeypatch.setattr(adapter, "_start_browser", MagicMock())
    monkeypatch.setattr(adapter, "_refresh_cookies", MagicMock())
    monkeypatch.setattr(adapter, "_close_browser_sync", MagicMock())
    monkeypatch.setattr(adapter, "_sleep", MagicMock())
    monkeypatch.setattr(
        adapter,
        "_post_job_page",
        MagicMock(return_value={
            "code": 0,
            "zpData": {
                "lid": "lid",
                "hasMore": False,
                "jobList": [
                    {"securityId": "sid-1", "encryptJobId": "eid-1", "jobName": "One"},
                    {"securityId": "sid-2", "encryptJobId": "eid-2", "jobName": "Two"},
                ],
            },
        }),
    )
    detail = MagicMock(side_effect=[
        {"success": True, "detail": {"description": "D1", "address": "A1"}},
        {"success": True, "detail": {"description": "D2", "address": "A2"}},
    ])
    monkeypatch.setattr(adapter, "_crawl_detail_sync", detail)

    result = await adapter.crawl("https://www.zhipin.com/web/geek/jobs?query=python&city=101280100")

    assert result["success"] is True
    assert result["count"] == 2
    assert result["jobs"][0]["description"] == "D1"
    assert result["jobs"][1]["address"] == "A2"
    assert detail.call_count == 2
    adapter._sleep.assert_called_once_with(adapter.detail_delay_seconds)


@pytest.mark.asyncio
async def test_crawl_writes_jsonl_progress_log(monkeypatch, tmp_path):
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    log_path = tmp_path / "boss.jsonl"
    adapter = BossCloakExperimentalAdapter(max_jobs=1, max_pages=1, log_path=log_path)
    monkeypatch.setattr(adapter, "_start_browser", MagicMock())
    monkeypatch.setattr(adapter, "_refresh_cookies", MagicMock())
    monkeypatch.setattr(adapter, "_close_browser_sync", MagicMock())
    monkeypatch.setattr(adapter, "_sleep", MagicMock())
    monkeypatch.setattr(
        adapter,
        "_post_job_page",
        MagicMock(return_value={
            "code": 0,
            "zpData": {
                "lid": "lid",
                "hasMore": False,
                "jobList": [
                    {"securityId": "sid-1", "encryptJobId": "eid-1", "jobName": "One"},
                ],
            },
        }),
    )
    monkeypatch.setattr(
        adapter,
        "_crawl_detail_sync",
        MagicMock(return_value={"success": True, "detail": {"description": "D", "address": "A"}}),
    )

    result = await adapter.crawl("https://www.zhipin.com/web/geek/jobs?query=python&city=101280100")

    assert result["success"] is True
    events = [json.loads(line)["event"] for line in log_path.read_text(encoding="utf-8").splitlines()]
    assert events == ["crawl_start", "list_page", "jobs_added", "detail", "crawl_finish"]


def test_crawl_detail_refreshes_on_anti_bot_code(monkeypatch):
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    adapter = BossCloakExperimentalAdapter()
    adapter._session = MagicMock()
    adapter._search_page = "https://www.zhipin.com/web/geek/jobs?query=python&city=101280100"
    refresh = MagicMock()
    monkeypatch.setattr(adapter, "_refresh_cookies", refresh)
    monkeypatch.setattr(
        adapter,
        "_get_detail_once",
        MagicMock(side_effect=[
            {"success": False, "error": "API code=37"},
            {"success": True, "detail": {"description": "ok"}},
        ]),
    )

    result = adapter._crawl_detail_sync("sid", "lid")

    assert result["success"] is True
    refresh.assert_called_once()


def test_boss_default_profile_uses_configured_profile_root(monkeypatch, tmp_path):
    from types import SimpleNamespace

    from app.platforms import boss_cloak_experimental
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    monkeypatch.setattr(
        boss_cloak_experimental,
        "settings",
        SimpleNamespace(resolved_crawler_profile_root=tmp_path),
    )

    adapter = BossCloakExperimentalAdapter()

    assert adapter.profile_dir == tmp_path / "profiles" / "boss" / "default"
