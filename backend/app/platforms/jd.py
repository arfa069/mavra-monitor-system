"""JD platform adapter."""
from typing import Any

from app.config import settings
from app.platforms.base import BasePlatformAdapter
from app.platforms.jd_opencli import crawl_jd_via_opencli
from app.platforms.middleware.cookie_injection import CookieInjectionMiddleware
from app.platforms.strategies import (
    ChainedPriceStrategy,
    CSSSelectorStrategy,
    JSDeeScanStrategy,
)


class JDAdapter(BasePlatformAdapter, CookieInjectionMiddleware):
    """Adapter for JD.com price crawling.

    Supports two modes:
    1. CDP mode (recommended): Connects to an existing browser with JD login.
       Requires Edge/Chrome started with --remote-debugging-port=9222.
    2. Cookie mode: Launches headless browser and injects JD cookies.
       Set JD_COOKIE env var with the full cookie string.

    Cookie injection is tracked at class level so the same shared context
    only gets cookies once. Re-injection only occurs when the shared
    browser/context is rebuilt.
    """

    # Class-level injection tracking
    _shared_cookies_injected: bool = False
    _shared_cookie_context_id: int | None = None

    async def crawl_with_page(self, url: str, page) -> dict[str, Any]:
        """Crawl JD page via OpenCLI first, fall back to Playwright strategies."""
        import logging
        _log = logging.getLogger(__name__)

        # Try OpenCLI first (if enabled)
        opencli_result = await crawl_jd_via_opencli(url)
        if opencli_result.success and opencli_result.price:
            _log.info("OpenCLI returned price %s for %s", opencli_result.price, url)
            return {
                "success": True,
                "price": opencli_result.price,
                "currency": opencli_result.currency,
                "title": opencli_result.title or "",
            }

        # OpenCLI detected auth / security issues ? surface them
        if opencli_result.is_login_page:
            _log.warning("OpenCLI detected login page for %s", url)
            return {
                "success": False,
                "error": "JD login required (via OpenCLI)",
                "failure_type": "login_required",
            }
        if opencli_result.has_security_challenge or opencli_result.looks_blocked:
            _log.warning("OpenCLI detected anti-bot challenge for %s", url)
            return {
                "success": False,
                "error": "JD anti-bot verification required (via OpenCLI)",
                "failure_type": "anti_bot",
            }

        # OpenCLI succeeded but returned no price — don't waste a Playwright call
        if opencli_result.success:
            _log.warning("OpenCLI returned no price for %s", url)
            return {
                "success": False,
                "error": "JD price not found (via OpenCLI)",
            }

        # OpenCLI failed for technical reasons (not simply disabled) ? fallback
        if opencli_result.error and "jd_opencli_enabled is False" not in opencli_result.error:
            _log.warning(
                "OpenCLI failed (%s), falling back to Playwright for %s",
                opencli_result.error, url,
            )

        # Fallback: use parent Playwright-based crawling
        return await super().crawl_with_page(url, page)

    def __init__(self):
        """Initialize JD adapter with strategies."""
        super().__init__()

        # CSS Selector strategy for direct price elements
        self.css_strategy = CSSSelectorStrategy(
            selectors=[
                ".product-price",       # Desktop product page (most common)
                ".p-price .price",      # Desktop alternative
                ".price .JD-price",     # Desktop alternative
                "[data-price]",         # Data attribute
                "#jdPrice .price",      # Price section
                ".p-price",             # Generic price container
                ".price",               # Generic price class
            ],
            currency="CNY",
        )

        # JavaScript deep scan strategy as fallback
        self.js_strategy = JSDeeScanStrategy(currency="CNY")

        # Chain CSS as primary, JS as fallback
        self._price_strategy = ChainedPriceStrategy([
            self.css_strategy,
            self.js_strategy,
        ])

    def _should_inject_cookie_fallback(self) -> bool:
        return bool(settings.jd_cookie and settings.jd_cookie_fallback_enabled)

    def classify_failure(self, url: str, content: str) -> str | None:
        lowered = content.lower()
        if (
            "pc-frequent-pro.pf.jd.com" in url
            or "reason=403" in url
            or "访问频繁" in content
            or "安全验证" in content
        ):
            return "anti_bot"
        if "passport.jd.com" in url or "请登录" in content or "login" in lowered:
            return "login_required"
        return None

    async def _init_browser(self):
        """Initialize browser with JD cookies if using launch mode."""
        await super()._init_browser()

        # In launch mode (not CDP), inject cookies only once per shared context
        if not self._cdp_mode and self._should_inject_cookie_fallback() and self._context:
            context_id = id(self._context)
            needs_injection = (
                not self.__class__._shared_cookies_injected
                or self.__class__._shared_cookie_context_id != context_id
            )
            if needs_injection:
                await self.inject_cookies(self._context, settings.jd_cookie, domain=".jd.com")
                self.__class__._shared_cookies_injected = True
                self.__class__._shared_cookie_context_id = context_id
                # Re-create page after adding cookies
                if self._page:
                    await self._page.close()
                self._page = await self._context.new_page()

    @classmethod
    async def _close_shared_browser(cls):
        """Close shared browser and reset injection state."""
        await super()._close_shared_browser()
        cls._shared_cookies_injected = False
        cls._shared_cookie_context_id = None

    async def extract_price(self, page) -> dict[str, Any]:
        """Extract price from JD page using chained strategies.

        Uses CSSSelectorStrategy as primary, JSDeeScanStrategy as fallback.
        """
        return await self._price_strategy.extract(page)

    async def extract_title(self, page) -> str:
        """Extract title from JD page."""
        try:
            title_selectors = [
                ".sku-name",          # Desktop product title
                ".product-name",
                ".itemInfo-bar h1",
                "h1.title",
                "#product-title",
                ".p-sku-title",
                ".detail-title",
            ]

            for selector in title_selectors:
                try:
                    element = page.locator(selector).first
                    if await element.count() > 0:
                        title = await element.text_content()
                        if title and title.strip():
                            return title.strip()
                except Exception:
                    continue

            # Fallback to page title, strip JD suffix
            page_title = await page.title()
            if " - " in page_title:
                return page_title.split(" - ")[0].strip()
            if "【" in page_title:
                return page_title.split("【")[0].strip()
            return page_title.strip()

        except Exception:
            return ""

