"""Taobao platform adapter."""
from typing import Any

from app.config import settings
from app.platforms.base import BasePlatformAdapter
from app.platforms.strategies import (
    CSSSelectorStrategy,
    JSDeeScanStrategy,
)
from app.platforms.taobao_opencli import crawl_taobao_via_opencli


class TaobaoAdapter(BasePlatformAdapter):
    """Adapter for Taobao/Tmall price crawling.

    Uses CSSSelectorStrategy as primary extraction method.
    Uses JSDeeScanStrategy as fallback if taobao_js_deep_scan_enabled is set in config.
    """

    async def crawl_with_page(self, url: str, page) -> dict[str, Any]:
        """Crawl Taobao page via OpenCLI first, fall back to Playwright strategies."""
        import logging
        _log = logging.getLogger(__name__)

        opencli_result = await crawl_taobao_via_opencli(url)
        if opencli_result.success and opencli_result.price:
            _log.info("OpenCLI returned taobao price %s for %s", opencli_result.price, url)
            return {
                "success": True,
                "price": opencli_result.price,
                "currency": opencli_result.currency,
                "title": opencli_result.title or "",
            }

        # OpenCLI succeeded but returned no price — don't waste a Playwright call
        if opencli_result.success:
            _log.warning("OpenCLI returned no price for %s", url)
            return {
                "success": False,
                "error": "Taobao price not found (via OpenCLI)",
            }

        # OpenCLI failed for technical reasons (not simply disabled) ? fallback
        if opencli_result.error and "taobao_opencli_enabled is False" not in opencli_result.error:
            _log.warning(
                "OpenCLI taobao failed (%s), falling back to Playwright for %s",
                opencli_result.error, url,
            )

        return await super().crawl_with_page(url, page)

    def __init__(self):
        """Initialize Taobao adapter with strategies.

        Reads taobao_js_deep_scan_enabled from config to determine if JS deep scan
        fallback should be enabled.
        """
        super().__init__()

        # Check config for JS deep scan setting
        self.js_deep_scan_enabled = settings.taobao_js_deep_scan_enabled

        # Primary strategy: CSS selector-based extraction
        # Updated with Tmall's current price structure
        self.css_strategy = CSSSelectorStrategy(
            selectors=[
                # Tmall new structure (priceWrap/highlightPrice pattern)
                "[class*='priceWrap'] [class*='highlightPrice']",
                "[class*='priceWrap'] [class*='text--']",
                "[class*='priceWrap']",
                # Classic Tmall/Taobao selectors
                ".price-value",
                ".tm-price-panel .tm-price",
                "[data-price]",
                ".originPrice",
                "#J_PromoPrice .price-value",
                ".price",
                # Try price in highlight area first
                ".highlightPrice",
                "[class*='highlightPrice']",
            ],
            currency="CNY",
        )

        # Fallback strategy: JavaScript deep scan (only if enabled in config)
        self.js_strategy = JSDeeScanStrategy() if self.js_deep_scan_enabled else None

    async def extract_price(self, page) -> dict[str, Any]:
        """Extract price from Taobao page.

        Tries CSS selector strategy first, then JS deep scan as fallback.
        """
        # Try CSS selector strategy first
        result = await self.css_strategy.extract(page)
        if result.get("success"):
            return result

        # Fallback to JS deep scan if enabled and CSS failed
        if self.js_strategy:
            js_result = await self.js_strategy.extract(page)
            if js_result.get("success"):
                return js_result

        return {"success": False, "error": "Price not found on Taobao page"}

    def classify_failure(self, url: str, content: str) -> str | None:
        if "login.taobao.com" in url or "登录" in content:
            return "login_required"
        if "验证码" in content or "滑块" in content:
            return "anti_bot"
        return None

    async def extract_title(self, page) -> str:
        """Extract title from Taobao page."""
        try:
            title_selectors = [
                ".product-title",
                ".item-title",
                "h1.title",
                "#J_ItemInfo .title",
            ]

            for selector in title_selectors:
                try:
                    element = page.locator(selector).first
                    if await element.count() > 0:
                        title = await element.text_content()
                        if title:
                            return title.strip()
                except Exception:
                    continue

            # Fallback to page title
            return await page.title()

        except Exception:
            return ""
