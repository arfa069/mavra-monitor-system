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

    raw = {
        "job_id": "123",
        "title": "Python Engineer",
        "company": "Example Co",
        "salary": "20-40k",
        "location": "上海",
        "experience": "3-5年",
        "education": "本科",
        "url": "https://www.liepin.com/job/123.shtml",
    }

    job = LiepinAdapter._normalize_job(raw)

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

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())
    monkeypatch.setattr(adapter, "_crawl_via_cdp", AsyncMock())

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is True
    assert result["count"] == 1
    assert result["jobs"][0]["job_id"] == "123"
    adapter._crawl_via_cdp.assert_not_called()


@pytest.mark.asyncio
async def test_liepin_crawl_falls_back_to_cdp_api_when_http_request_fails(monkeypatch):
    from app.platforms import liepin
    from app.platforms.liepin import LiepinAdapter

    class FakeSession:
        def get(self, *_args, **_kwargs):
            raise TimeoutError("network blocked")

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())
    monkeypatch.setattr(
        liepin,
        "open_temporary_tab",
        AsyncMock(return_value=("ws://target", "target-liepin")),
    )
    close_target_mock = AsyncMock()
    monkeypatch.setattr(liepin, "close_target", close_target_mock)
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
                                "job": {
                                    "jobId": "198123",
                                    "title": "Python Dev",
                                    "salary": "25k",
                                    "dq": "上海",
                                    "requireWorkYears": "3年",
                                    "requireEduLevel": "本科",
                                    "link": "https://www.liepin.com/job/198123.shtml",
                                },
                                "comp": {"compName": "Test Co"},
                            }
                        ]
                    }
                }
            },
        }),
    )

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is True
    assert result["count"] == 1
    assert result["jobs"][0]["job_id"] == "198123"
    close_target_mock.assert_awaited_once_with("target-liepin")


@pytest.mark.asyncio
async def test_liepin_crawl_falls_back_to_cdp_when_http_returns_html(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "text/html"}
        text = "<html>安全验证</html>"

        def json(self):
            raise ValueError("not json")

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())
    monkeypatch.setattr(
        adapter,
        "_crawl_via_cdp",
        AsyncMock(return_value={"success": True, "jobs": [{"job_id": "cdp"}], "count": 1}),
    )

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is True
    assert result["jobs"][0]["job_id"] == "cdp"
    adapter._crawl_via_cdp.assert_awaited_once_with("python", "020")


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
async def test_liepin_crawl_fails_when_browser_unavailable(monkeypatch):
    from app.platforms import liepin
    from app.platforms.liepin import LiepinAdapter

    monkeypatch.setattr(
        liepin,
        "open_temporary_tab",
        AsyncMock(return_value=(None, None)),
    )

    result = await LiepinAdapter().crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is False
    assert "浏览器" in result["error"]


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
    monkeypatch.setattr(adapter, "_crawl_detail_via_cdp", AsyncMock())

    result = await adapter.crawl_detail("123")

    assert result["success"] is True
    assert result["detail"]["description"] == "负责开发"
    assert result["detail"]["address"] == "上海市"
    adapter._crawl_detail_via_cdp.assert_not_called()


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
    monkeypatch.setattr(adapter, "_crawl_detail_via_cdp", AsyncMock())

    result = await adapter.crawl_detail("123")

    assert result["success"] is True
    assert result["detail"]["description"] == "负责开发"
    assert result["detail"]["address"] == "无地址"
    adapter._crawl_detail_via_cdp.assert_not_called()


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
    monkeypatch.setattr(adapter, "_crawl_detail_via_cdp", AsyncMock())

    result = await adapter.crawl_detail("123")

    assert result["success"] is False
    assert "HTTP response contained no detail" in result["error"]
    adapter._crawl_detail_via_cdp.assert_not_called()


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
