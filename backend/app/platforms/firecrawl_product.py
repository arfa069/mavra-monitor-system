"""Firecrawl product adapter."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

LOGIN_WALL_KEYWORDS = (
    "京东APP扫码登录",
    "扫码登录",
    "请登录",
    "登录后查看",
)


@dataclass
class FirecrawlProductResult:
    success: bool
    price: str | None = None
    currency: str = "CNY"
    title: str | None = None
    error: str | None = None


PRODUCT_JSON_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "price": {"type": ["number", "string"]},
        "currency": {"type": "string"},
    },
    "required": ["price"],
}


def _error_for_status(status_code: int) -> str:
    if status_code == 401:
        return "firecrawl_unauthorized"
    if status_code == 402:
        return "firecrawl_payment_required"
    if status_code == 429:
        return "firecrawl_rate_limited"
    if status_code >= 500:
        return "firecrawl_server_error"
    return f"firecrawl_http_{status_code}"


def _contains_login_wall_text(*values: object) -> bool:
    for value in values:
        if isinstance(value, str) and any(keyword in value for keyword in LOGIN_WALL_KEYWORDS):
            return True
    return False


def _valid_positive_price(value: object) -> bool:
    try:
        return Decimal(str(value)) > 0
    except (InvalidOperation, ValueError):
        return False


def _result_from_price(*, price: object, currency: object, title: object) -> FirecrawlProductResult:
    if _contains_login_wall_text(title):
        return FirecrawlProductResult(success=False, error="firecrawl_login_wall")
    if not _valid_positive_price(price):
        return FirecrawlProductResult(success=False, error="firecrawl_invalid_price")
    return FirecrawlProductResult(
        success=True,
        price=str(price),
        currency=str(currency or "CNY"),
        title=title if isinstance(title, str) else None,
    )


def _extract_product(data: dict[str, Any]) -> FirecrawlProductResult:
    if _contains_login_wall_text(data.get("markdown")):
        return FirecrawlProductResult(success=False, error="firecrawl_login_wall")

    product = data.get("product")
    if isinstance(product, dict):
        if _contains_login_wall_text(product.get("title")):
            return FirecrawlProductResult(success=False, error="firecrawl_login_wall")
        variants = product.get("variants")
        if isinstance(variants, list) and variants:
            price = variants[0].get("price") if isinstance(variants[0], dict) else None
            if isinstance(price, dict) and price.get("amount") is not None:
                return _result_from_price(
                    price=str(price["amount"]),
                    currency=price.get("currency") or "CNY",
                    title=product.get("title"),
                )

    extracted_json = data.get("json")
    if isinstance(extracted_json, dict) and _contains_login_wall_text(extracted_json.get("title")):
        return FirecrawlProductResult(success=False, error="firecrawl_login_wall")
    if isinstance(extracted_json, dict) and extracted_json.get("price") is not None:
        return _result_from_price(
            price=extracted_json["price"],
            currency=extracted_json.get("currency") or "CNY",
            title=extracted_json.get("title"),
        )

    return FirecrawlProductResult(success=False, error="firecrawl_price_not_found")


async def crawl_product_via_firecrawl(url: str, platform: str) -> FirecrawlProductResult:
    """Crawl a product URL via Firecrawl Cloud."""
    if not settings.firecrawl_api_key:
        return FirecrawlProductResult(success=False, error="firecrawl_api_key_missing")

    api_url = settings.firecrawl_api_url.rstrip("/") + "/v2/scrape"
    payload: dict[str, Any] = {
        "url": url,
        "formats": [
            "product",
            {"type": "json", "schema": PRODUCT_JSON_SCHEMA},
            "markdown",
        ],
        "timeout": int(settings.firecrawl_timeout_seconds * 1000),
        "waitFor": settings.firecrawl_wait_for_ms,
        "maxAge": 0,
        "proxy": "auto",
        "mobile": platform in {"jd", "taobao"},
    }
    if settings.firecrawl_profile_name:
        payload["profile"] = {
            "name": settings.firecrawl_profile_name,
            "saveChanges": False,
        }

    try:
        async with httpx.AsyncClient(timeout=settings.firecrawl_timeout_seconds) as client:
            response = await client.post(
                api_url,
                headers={"Authorization": f"Bearer {settings.firecrawl_api_key}"},
                json=payload,
            )
    except httpx.TimeoutException:
        return FirecrawlProductResult(success=False, error="firecrawl_timeout")
    except httpx.HTTPError as exc:
        logger.warning("Firecrawl product crawl failed for %s: %s", url, exc)
        return FirecrawlProductResult(success=False, error="firecrawl_request_failed")

    if response.status_code != 200:
        return FirecrawlProductResult(success=False, error=_error_for_status(response.status_code))

    try:
        payload_data = response.json()
    except ValueError:
        return FirecrawlProductResult(success=False, error="firecrawl_invalid_response")
    data = payload_data.get("data") if isinstance(payload_data, dict) else None
    if not isinstance(data, dict):
        return FirecrawlProductResult(success=False, error="firecrawl_price_not_found")
    return _extract_product(data)
