"""Tests for Liepin adapter and shared CDP helpers."""

from __future__ import annotations

import json
from unittest.mock import AsyncMock

import pytest


@pytest.mark.asyncio
async def test_open_temporary_tab_uses_cdp_new_endpoint(monkeypatch):
    import http.client

    from app.platforms.cdp_utils import open_temporary_tab

    requests: list[tuple[str, str]] = []

    class FakeResponse:
        def read(self) -> bytes:
            return json.dumps({
                "id": "target-liepin",
                "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/page/target-liepin",
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

    ws_url, target_id = await open_temporary_tab("https://www.liepin.com/zhaopin/?key=python")

    assert ws_url == "ws://127.0.0.1:9222/devtools/page/target-liepin"
    assert target_id == "target-liepin"
    assert requests[0][0] == "PUT"
    assert requests[0][1].startswith("/json/new?https%3A%2F%2Fwww.liepin.com")


@pytest.mark.asyncio
async def test_close_target_closes_requested_cdp_target(monkeypatch):
    import http.client

    from app.platforms.cdp_utils import close_target

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

    await close_target("target-liepin")

    assert requests[0] == ("GET", "/json/close/target-liepin")
    assert ("GET", "/json") in requests


def test_liepin_normalize_job():
    from app.platforms.liepin import LiepinAdapter

    payload = {
        "jobCardList": [
            {
                "job": {
                    "jobId": "123",
                    "title": "Python Engineer",
                    "salary": "20-40k",
                    "dq": "上海",
                    "requireWorkYears": "3-5年",
                    "requireEduLevel": "本科",
                    "link": "https://www.liepin.com/job/123.shtml",
                },
                "comp": {"compName": "Example Co"},
            }
        ]
    }

    job = LiepinAdapter._transform_jobs(payload)[0]

    assert job["job_id"] == "123"
    assert job["title"] == "Python Engineer"
    assert job["company"] == "Example Co"
    assert job["salary"] == "20-40k"
    assert job["location"] == "上海"
    assert job["experience"] == "3-5年"
    assert job["education"] == "本科"
    assert job["url"] == "https://www.liepin.com/job/123.shtml"
    assert job["description"] == ""
    assert job["address"] == ""


def test_liepin_transform_jobs_normalizes_search_items():
    from app.platforms.liepin import LiepinAdapter

    payload = {
        "data": {
            "data": {
                "jobCardList": [
                    {
                        "job": {
                            "jobId": "123",
                            "title": "Python Engineer",
                            "salary": "20-40k",
                            "dq": "上海",
                            "requireWorkYears": "3-5年",
                            "requireEduLevel": "本科",
                            "link": "https://www.liepin.com/job/123.shtml",
                        },
                        "comp": {"compId": "c1", "compName": "Example Co"},
                    }
                ]
            }
        }
    }

    jobs = LiepinAdapter._transform_jobs(payload)

    assert jobs == [
        {
            "job_id": "123",
            "title": "Python Engineer",
            "company": "Example Co",
            "company_id": "c1",
            "salary": "20-40k",
            "location": "上海",
            "experience": "3-5年",
            "education": "本科",
            "url": "https://www.liepin.com/job/123.shtml",
            "description": "",
            "address": "",
        }
    ]


def test_liepin_transform_jobs_prefers_detail_id_from_link():
    from app.platforms.liepin import LiepinAdapter

    payload = {
        "data": {
            "data": {
                "jobCardList": [
                    {
                        "job": {
                            "jobId": "82380963",
                            "title": "Python Engineer",
                            "link": "https://www.liepin.com/job/1982380963.shtml",
                        },
                        "comp": {"compName": "Example Co"},
                    }
                ]
            }
        }
    }

    jobs = LiepinAdapter._transform_jobs(payload)

    assert jobs[0]["job_id"] == "1982380963"
    assert jobs[0]["url"] == "https://www.liepin.com/job/1982380963.shtml"


@pytest.mark.asyncio
async def test_liepin_crawl_uses_http_json_success(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "application/json"}
        text = '{"data":{"data":{"jobCardList":[]}}}'

        def json(self):
            return {
                "data": {
                    "data": {
                        "jobCardList": [
                            {
                                "job": {
                                    "jobId": "123",
                                    "title": "Python Engineer",
                                    "salary": "20-40k",
                                    "dq": "上海",
                                    "requireWorkYears": "3-5年",
                                    "requireEduLevel": "本科",
                                    "link": "https://www.liepin.com/job/123.shtml",
                                },
                                "comp": {"compId": "c1", "compName": "Example Co"},
                            }
                        ]
                    }
                }
            }

    class FakeCookies:
        def get(self, key):
            return "token-123" if key == "XSRF-TOKEN" else None

    class FakeSession:
        cookies = FakeCookies()

        def get(self, *_args, **_kwargs):
            return object()

        def post(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is True
    assert result["count"] == 1
    assert result["jobs"][0]["job_id"] == "123"


@pytest.mark.asyncio
async def test_liepin_crawl_posts_pc_search_api_without_opening_browser(monkeypatch):
    from app.platforms.liepin import API_BASE_URL, SEARCH_API_PATH, LiepinAdapter

    calls: dict[str, object] = {}

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "application/json"}
        text = "{}"

        def json(self):
            return {
                "data": {
                    "data": {
                        "jobCardList": [
                            {
                                "job": {"jobId": "123", "title": "Python Engineer"},
                                "comp": {"compName": "Example Co"},
                            }
                        ]
                    }
                }
            }

    class FakeCookies:
        def get(self, key):
            return "token-123" if key == "XSRF-TOKEN" else None

    class FakeSession:
        cookies = FakeCookies()

        def get(self, url, **kwargs):
            calls["get_url"] = url
            calls["get_kwargs"] = kwargs
            return object()

        def post(self, url, **kwargs):
            calls["post_url"] = url
            calls["post_kwargs"] = kwargs
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    post_kwargs = calls["post_kwargs"]
    assert result["success"] is True
    assert calls["post_url"] == f"{API_BASE_URL}{SEARCH_API_PATH}"
    assert post_kwargs["headers"]["X-XSRF-TOKEN"] == "token-123"
    assert post_kwargs["json"]["data"]["mainSearchPcConditionForm"]["key"] == "python"
    assert post_kwargs["json"]["data"]["mainSearchPcConditionForm"]["dq"] == "020"


@pytest.mark.asyncio
async def test_liepin_crawl_returns_http_failure_when_request_fails(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeSession:
        def get(self, *_args, **_kwargs):
            raise TimeoutError("network blocked")

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is False
    assert result["failure_category"] == "parse_error"


@pytest.mark.asyncio
async def test_liepin_crawl_returns_failure_when_http_returns_html(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "text/html"}
        text = "<html>安全验证</html>"

        def json(self):
            raise ValueError("not json")

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return object()

        def post(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is False
    assert result["failure_category"] == "parse_error"


@pytest.mark.skip(reason="Liepin CDP fallback was removed in Phase 3")
@pytest.mark.asyncio
async def test_liepin_cdp_fallback_closes_temporary_tab(monkeypatch):
    from app.platforms import liepin
    from app.platforms.liepin import LiepinAdapter

    monkeypatch.setattr(
        liepin,
        "open_temporary_tab",
        AsyncMock(return_value=("ws://target", "target-liepin")),
    )
    monkeypatch.setattr(
        liepin,
        "evaluate_json_fetch",
        AsyncMock(return_value={
            "status": 200,
            "contentType": "application/json",
            "json": {
                "data": {
                    "data": {
                        "jobCardList": [
                            {
                                "job": {"jobId": "123", "title": "Python"},
                                "comp": {"compName": "Example"},
                            }
                        ]
                    }
                }
            },
        }),
    )
    close_target = AsyncMock()
    monkeypatch.setattr(liepin, "close_target", close_target)

    result = await LiepinAdapter()._crawl_via_cdp("python", "020")

    assert result["success"] is True
    assert result["count"] == 1
    close_target.assert_awaited_once_with("target-liepin")


@pytest.mark.skip(reason="Liepin CDP fallback was removed in Phase 3")
@pytest.mark.asyncio
async def test_liepin_cdp_fallback_uses_dom_when_api_fetch_fails(monkeypatch):
    import websockets

    from app.platforms import liepin
    from app.platforms.liepin import LiepinAdapter

    monkeypatch.setattr(
        liepin,
        "open_temporary_tab",
        AsyncMock(return_value=("ws://target", "target-liepin")),
    )
    monkeypatch.setattr(
        liepin,
        "evaluate_json_fetch",
        AsyncMock(return_value={"error": "TypeError: Failed to fetch"}),
    )
    close_target = AsyncMock()
    monkeypatch.setattr(liepin, "close_target", close_target)

    fake_ws = AsyncMock()
    fake_ws.__aenter__ = AsyncMock(return_value=fake_ws)
    fake_ws.__aexit__ = AsyncMock(return_value=None)
    fake_ws.send = AsyncMock()
    fake_ws.recv = AsyncMock(return_value=json.dumps({
        "result": {"result": {"value": json.dumps({
            "jobs": [{
                "job_id": "198123",
                "title": "Python Dev",
                "company": "Test Co",
                "salary": "25k",
                "location": "上海",
                "experience": "3年",
                "education": "本科",
                "url": "https://www.liepin.com/job/198123.shtml",
            }],
        })}},
    }))
    monkeypatch.setattr(websockets, "connect", lambda *a, **k: fake_ws)

    result = await LiepinAdapter()._crawl_via_cdp("python", "020")

    assert result["success"] is True
    assert result["jobs"][0]["job_id"] == "198123"
    close_target.assert_awaited_once_with("target-liepin")


@pytest.mark.asyncio
async def test_liepin_crawl_fails_when_http_unavailable(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeSession:
        def get(self, *_args, **_kwargs):
            raise TimeoutError("network blocked")

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is False
    assert result["failure_category"] == "parse_error"


@pytest.mark.asyncio
async def test_liepin_crawl_detail_uses_http_first(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "text/html"}
        text = "<html><div class='job-intro-container'>负责开发</div><div class='label-box'>职位地址：上海市</div></html>"

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl_detail("123")

    assert result["success"] is True
    assert result["detail"]["description"] == "负责开发"
    assert result["detail"]["address"] == "上海市"


@pytest.mark.asyncio
async def test_liepin_crawl_detail_tries_anonymous_detail_url(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    requested_urls = []

    class FakeResponse:
        def __init__(self, text):
            self.status_code = 200
            self.headers = {"content-type": "text/html"}
            self.text = text

    class FakeSession:
        def get(self, url, *_args, **_kwargs):
            requested_urls.append(url)
            if "/a/" in url:
                return FakeResponse("<html><div class='job-intro-container'>匿名职位详情</div></html>")
            return FakeResponse("<html></html>")

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl_detail("75066461")

    assert result["success"] is True
    assert result["detail"]["description"] == "匿名职位详情"
    assert requested_urls == [
        "https://www.liepin.com/job/75066461.shtml",
        "https://www.liepin.com/a/75066461.shtml",
    ]


@pytest.mark.asyncio
async def test_liepin_crawl_detail_does_not_treat_login_header_as_challenge(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "text/html"}
        text = (
            "<html><header>登录/注册</header>"
            "<div class='job-intro-container'>负责开发</div></html>"
        )

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl_detail("123")

    assert result["success"] is True
    assert result["detail"]["description"] == "负责开发"
    assert result["detail"]["address"] == "无地址"


@pytest.mark.asyncio
async def test_liepin_crawl_detail_does_not_open_cdp_on_challenge(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "text/html"}
        text = "<html>安全验证</html>"

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl_detail("123")

    assert result["success"] is False
    assert "HTTP response contained no detail" in result["error"]


@pytest.mark.skip(reason="Liepin CDP detail fallback was removed in Phase 3")
@pytest.mark.asyncio
async def test_liepin_cdp_detail_closes_temporary_tab(monkeypatch):
    import websockets

    from app.platforms import liepin
    from app.platforms.liepin import LiepinAdapter

    monkeypatch.setattr(
        liepin,
        "open_temporary_tab",
        AsyncMock(return_value=("ws://target", "target-liepin")),
    )
    close_target_mock = AsyncMock()
    monkeypatch.setattr(liepin, "close_target", close_target_mock)

    fake_ws = AsyncMock()
    fake_ws.__aenter__ = AsyncMock(return_value=fake_ws)
    fake_ws.__aexit__ = AsyncMock(return_value=None)
    fake_ws.send = AsyncMock()
    fake_ws.recv = AsyncMock(return_value=json.dumps({
        "result": {"result": {"value": json.dumps({"description": "D", "address": "A"})}},
    }))
    monkeypatch.setattr(websockets, "connect", lambda *a, **k: fake_ws)

    async def fake_wait_for(coro, timeout):
        return await coro
    monkeypatch.setattr(liepin, "asyncio", type("obj", (object,), {"sleep": AsyncMock(), "wait_for": fake_wait_for}))

    result = await LiepinAdapter()._crawl_detail_via_cdp("123")

    assert result["success"] is True
    assert result["detail"]["description"] == "D"
    close_target_mock.assert_awaited_once_with("target-liepin")


def test_liepin_parse_detail_html():
    from app.platforms.liepin import LiepinAdapter

    html = """
    <html>
      <body>
        <div class="job-intro-container">负责 Python 服务开发</div>
        <div class="label-box">职位地址：上海市浦东新区</div>
      </body>
    </html>
    """

    detail = LiepinAdapter._parse_detail_html(html)

    assert detail["description"] == "负责 Python 服务开发"
    assert detail["address"] == "上海市浦东新区"
