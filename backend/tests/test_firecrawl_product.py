from types import SimpleNamespace
from unittest.mock import AsyncMock

import httpx
import pytest

from app.config import settings


class FakeAsyncClient:
    def __init__(self, *, response=None, exc=None):
        self.response = response
        self.exc = exc
        self.requests = []

    async def __aenter__(self):
        return self

    async def __aexit__(self, *_args):
        return None

    async def post(self, url, *, headers=None, json=None):
        self.requests.append({"url": url, "headers": headers, "json": json})
        if self.exc:
            raise self.exc
        return self.response


def response(status_code, payload):
    return httpx.Response(status_code, json=payload, request=httpx.Request("POST", "https://api.test/v2/scrape"))


@pytest.fixture(autouse=True)
def firecrawl_settings(monkeypatch):
    monkeypatch.setattr(settings, "firecrawl_api_url", "https://api.test")
    monkeypatch.setattr(settings, "firecrawl_api_key", "secret-key")
    monkeypatch.setattr(settings, "firecrawl_timeout_seconds", 12.0)
    monkeypatch.setattr(settings, "firecrawl_wait_for_ms", 1500)
    monkeypatch.setattr(settings, "firecrawl_profile_name", "")


@pytest.mark.asyncio
async def test_firecrawl_parses_product_format(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(
        response=response(
            200,
            {
                "data": {
                    "product": {
                        "title": "Phone",
                        "variants": [{"price": {"amount": "1999.50", "currency": "CNY"}}],
                    }
                }
            },
        )
    )
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://item.jd.com/1.html", "jd")

    assert result.success is True
    assert result.price == "1999.50"
    assert result.currency == "CNY"
    assert result.title == "Phone"
    assert client.requests[0]["url"] == "https://api.test/v2/scrape"
    assert client.requests[0]["headers"]["Authorization"] == "Bearer secret-key"
    assert client.requests[0]["json"]["mobile"] is True
    assert client.requests[0]["json"]["timeout"] == 12000


@pytest.mark.asyncio
async def test_firecrawl_sends_configured_profile_read_only(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(
        response=response(
            200,
            {
                "data": {
                    "product": {
                        "title": "Phone",
                        "variants": [{"price": {"amount": "1999.50", "currency": "CNY"}}],
                    }
                }
            },
        )
    )
    monkeypatch.setattr(settings, "firecrawl_profile_name", "jd-login-profile")
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://item.jd.com/1.html", "jd")

    assert result.success is True
    assert client.requests[0]["json"]["profile"] == {
        "name": "jd-login-profile",
        "saveChanges": False,
    }


@pytest.mark.asyncio
async def test_firecrawl_parses_json_fallback(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(
        response=response(
            200,
            {"data": {"json": {"title": "Book", "price": 88, "currency": "USD"}}},
        )
    )
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://example.com/item", "amazon")

    assert result.success is True
    assert result.price == "88"
    assert result.currency == "USD"
    assert result.title == "Book"
    assert client.requests[0]["json"]["mobile"] is False


@pytest.mark.asyncio
async def test_firecrawl_price_missing(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(response=response(200, {"data": {"product": {"title": "No price"}}}))
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://example.com/item", "amazon")

    assert result.success is False
    assert result.error == "firecrawl_price_not_found"


@pytest.mark.asyncio
async def test_firecrawl_invalid_json_response(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(
        response=httpx.Response(
            200,
            content=b"not json",
            request=httpx.Request("POST", "https://api.test/v2/scrape"),
        )
    )
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://example.com/item", "amazon")

    assert result.success is False
    assert result.error == "firecrawl_invalid_response"


@pytest.mark.asyncio
async def test_firecrawl_rejects_zero_price(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(
        response=response(
            200,
            {
                "data": {
                    "product": {
                        "title": "Login wall product",
                        "variants": [{"price": {"amount": "0", "currency": "CNY"}}],
                    }
                }
            },
        )
    )
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://item.jd.com/1.html", "jd")

    assert result.success is False
    assert result.error == "firecrawl_invalid_price"


@pytest.mark.asyncio
async def test_firecrawl_rejects_login_wall_title(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(
        response=response(
            200,
            {
                "data": {
                    "product": {
                        "title": "京东APP扫码登录",
                        "variants": [{"price": {"amount": "1999", "currency": "CNY"}}],
                    }
                }
            },
        )
    )
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://item.jd.com/1.html", "jd")

    assert result.success is False
    assert result.error == "firecrawl_login_wall"


@pytest.mark.asyncio
async def test_firecrawl_rejects_login_wall_markdown(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(
        response=response(
            200,
            {
                "data": {
                    "markdown": "请登录后查看商品价格",
                    "product": {
                        "title": "Phone",
                        "variants": [{"price": {"amount": "1999", "currency": "CNY"}}],
                    },
                }
            },
        )
    )
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://item.jd.com/1.html", "jd")

    assert result.success is False
    assert result.error == "firecrawl_login_wall"


@pytest.mark.asyncio
async def test_firecrawl_rejects_login_wall_json_title(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(
        response=response(
            200,
            {"data": {"json": {"title": "京东APP扫码登录", "price": 1999, "currency": "CNY"}}},
        )
    )
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://item.jd.com/1.html", "jd")

    assert result.success is False
    assert result.error == "firecrawl_login_wall"


@pytest.mark.asyncio
async def test_firecrawl_failure_logs_without_price_history(monkeypatch):
    from app.domains.crawling import service

    class FakeSession:
        async def __aenter__(self):
            return self

        async def __aexit__(self, *_args):
            return None

    product = SimpleNamespace(id=1, active=True, platform="jd", url="https://item.jd.com/1.html", title=None)
    monkeypatch.setattr(service, "AsyncSessionLocal", lambda: FakeSession())
    monkeypatch.setattr(service.repository, "get_product", AsyncMock(return_value=product))
    monkeypatch.setattr(
        "app.platforms.firecrawl_product.crawl_product_via_firecrawl",
        AsyncMock(return_value=SimpleNamespace(success=False, price=None, error="firecrawl_login_wall")),
    )
    save_price_history = AsyncMock()
    save_crawl_log = AsyncMock()
    monkeypatch.setattr(service, "save_price_history", save_price_history)
    monkeypatch.setattr(service, "save_crawl_log", save_crawl_log)

    result = await service.crawl_one_firecrawl(product_id=1, platform="jd")

    assert result == {"status": "error", "product_id": 1, "reason": "firecrawl_login_wall"}
    save_price_history.assert_not_awaited()
    save_crawl_log.assert_awaited_once()


@pytest.mark.asyncio
async def test_opencli_crawl_releases_db_session_before_external_call(monkeypatch):
    from app.domains.crawling import service

    active_sessions = 0

    class FakeSession:
        async def __aenter__(self):
            nonlocal active_sessions
            active_sessions += 1
            return self

        async def __aexit__(self, *_args):
            nonlocal active_sessions
            active_sessions -= 1
            return None

    async def fake_crawl_jd(url):
        assert url == "https://item.jd.com/1.html"
        assert active_sessions == 0
        return SimpleNamespace(success=True, price="1999", currency="CNY", title="JD item")

    product = SimpleNamespace(id=1, active=True, platform="jd", url="https://item.jd.com/1.html", title=None)
    persist_result = {"status": "success", "product_id": 1, "price": 1999.0}
    persist = AsyncMock(return_value=persist_result)

    monkeypatch.setattr(service, "AsyncSessionLocal", lambda: FakeSession())
    monkeypatch.setattr(service.repository, "get_product", AsyncMock(return_value=product))
    monkeypatch.setattr("app.platforms.jd_opencli.crawl_jd_via_opencli", fake_crawl_jd)
    monkeypatch.setattr(service, "_persist_product_crawl_result_by_id", persist)

    result = await service.crawl_one_opencli(product_id=1, platform="jd")

    assert result == persist_result
    persist.assert_awaited_once_with(
        product_id=1,
        result_data={
            "success": True,
            "price": "1999",
            "currency": "CNY",
            "title": "JD item",
        },
    )


@pytest.mark.parametrize(
    ("status_code", "expected"),
    [
        (401, "firecrawl_unauthorized"),
        (402, "firecrawl_payment_required"),
        (429, "firecrawl_rate_limited"),
        (500, "firecrawl_server_error"),
    ],
)
@pytest.mark.asyncio
async def test_firecrawl_http_error_mapping(monkeypatch, status_code, expected):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(response=response(status_code, {"error": "failed"}))
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://example.com/item", "amazon")

    assert result.success is False
    assert result.error == expected


@pytest.mark.asyncio
async def test_firecrawl_timeout_mapping(monkeypatch):
    from app.platforms import firecrawl_product

    client = FakeAsyncClient(exc=httpx.TimeoutException("slow"))
    monkeypatch.setattr(firecrawl_product.httpx, "AsyncClient", lambda **_kwargs: client)

    result = await firecrawl_product.crawl_product_via_firecrawl("https://example.com/item", "amazon")

    assert result.success is False
    assert result.error == "firecrawl_timeout"


@pytest.mark.asyncio
async def test_firecrawl_requires_api_key(monkeypatch):
    from app.platforms import firecrawl_product

    monkeypatch.setattr(settings, "firecrawl_api_key", "")

    result = await firecrawl_product.crawl_product_via_firecrawl("https://example.com/item", "amazon")

    assert result.success is False
    assert result.error == "firecrawl_api_key_missing"


@pytest.mark.asyncio
async def test_product_engine_defaults_to_opencli(monkeypatch):
    from app.domains.crawling import service

    opencli = AsyncMock(return_value={"status": "success", "product_id": 1})
    firecrawl = AsyncMock(return_value={"status": "error", "product_id": 1})
    monkeypatch.setattr(settings, "product_crawl_engine", "opencli")
    monkeypatch.setattr(service, "crawl_one_opencli", opencli)
    monkeypatch.setattr(service, "crawl_one_firecrawl", firecrawl)

    result = await service.crawl_one_product(product_id=1, platform="jd")

    assert result == {"status": "success", "product_id": 1}
    opencli.assert_awaited_once_with(product_id=1, platform="jd")
    firecrawl.assert_not_awaited()


@pytest.mark.asyncio
async def test_product_engine_firecrawl_does_not_call_opencli(monkeypatch):
    from app.domains.crawling import service

    opencli = AsyncMock(return_value={"status": "success", "product_id": 1})
    firecrawl = AsyncMock(return_value={"status": "success", "product_id": 1})
    monkeypatch.setattr(settings, "product_crawl_engine", "firecrawl")
    monkeypatch.setattr(service, "crawl_one_opencli", opencli)
    monkeypatch.setattr(service, "crawl_one_firecrawl", firecrawl)

    result = await service.crawl_one_product(product_id=1, platform="jd")

    assert result == {"status": "success", "product_id": 1}
    firecrawl.assert_awaited_once_with(product_id=1, platform="jd")
    opencli.assert_not_awaited()


def test_product_kind_only_includes_product_task_types():
    from app.domains.crawling.task_store import task_types_for_kinds

    assert task_types_for_kinds({"product"}) == {"product_all", "product_platform"}
