import pytest

from app.platforms.base import BasePlatformAdapter
from app.platforms.jd import JDAdapter


class FakePage:
    def __init__(self):
        self.goto_calls = []

    async def goto(self, url, wait_until="domcontentloaded", timeout=60000):
        self.goto_calls.append((url, wait_until, timeout))

    async def wait_for_load_state(self, state, timeout=30000):
        return None

    async def wait_for_timeout(self, timeout):
        return None

    async def wait_for_selector(self, selector, timeout=None, state=None):
        return None

    async def evaluate(self, expression):
        return None


class FakeAdapter(BasePlatformAdapter):
    platform_name = "fake"

    async def extract_price(self, page):
        return {"success": True, "price": "12.34", "currency": "CNY"}

    async def extract_title(self, page):
        return "Demo"


@pytest.mark.asyncio
async def test_crawl_with_page_reuses_existing_page():
    page = FakePage()
    adapter = FakeAdapter()

    result = await adapter.crawl_with_page("https://example.test/item", page)

    assert result["price"] == "12.34"
    assert page.goto_calls == [("https://example.test/item", "domcontentloaded", 60000)]


def test_jd_cookie_injection_disabled_by_default(monkeypatch):
    monkeypatch.setattr("app.platforms.jd.settings.jd_cookie", "pt_key=abc;pt_pin=demo;")
    monkeypatch.setattr("app.platforms.jd.settings.jd_cookie_fallback_enabled", False)

    adapter = JDAdapter()

    assert adapter._should_inject_cookie_fallback() is False


def test_jd_login_required_reason_is_profile_specific():
    adapter = JDAdapter()

    assert adapter.classify_failure("https://passport.jd.com/login.aspx", "") == "login_required"
    assert adapter.classify_failure("https://item.jd.com/100.html", "请登录后查看") == "login_required"


def test_jd_frequent_verification_is_anti_bot():
    adapter = JDAdapter()

    assert (
        adapter.classify_failure(
            "https://pc-frequent-pro.pf.jd.com/?from=pc_item&reason=403",
            "",
        )
        == "anti_bot"
    )
    assert adapter.classify_failure("https://item.jd.com/100.html", "安全验证") == "anti_bot"
