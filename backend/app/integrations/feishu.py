"""Feishu webhook integration."""
from __future__ import annotations

from urllib.parse import urlsplit

import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

_client: httpx.AsyncClient | None = None
_FEISHU_WEBHOOK_HOST = "open.feishu.cn"
_FEISHU_WEBHOOK_PATH_PREFIX = "/open-apis/bot/v2/hook/"


def validate_feishu_webhook_url(webhook_url: str | None, *, allow_empty: bool = True) -> str:
    """Validate and normalize a Feishu bot webhook URL."""
    value = (webhook_url or "").strip()
    if not value:
        if allow_empty:
            return ""
        raise ValueError("Feishu webhook URL is required")

    parsed = urlsplit(value)
    if (
        parsed.scheme != "https"
        or parsed.hostname != _FEISHU_WEBHOOK_HOST
        or parsed.username is not None
        or parsed.password is not None
        or parsed.fragment
        or (parsed.port is not None and parsed.port != 443)
        or not parsed.path.startswith(_FEISHU_WEBHOOK_PATH_PREFIX)
        or len(parsed.path) <= len(_FEISHU_WEBHOOK_PATH_PREFIX)
    ):
        raise ValueError("Feishu webhook URL must be an https://open.feishu.cn bot hook URL")
    return value


def _get_client() -> httpx.AsyncClient:
    """Return a shared AsyncClient instance (created on first call)."""
    global _client
    if _client is None:
        _client = httpx.AsyncClient(timeout=10.0)
    return _client


@retry(
    retry=retry_if_exception_type(httpx.HTTPError),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=5),
)
async def send_feishu_notification(webhook_url: str, message: str) -> dict:
    """Send notification via Feishu webhook.

    Args:
        webhook_url: Feishu webhook URL
        message: Text message to send

    Returns:
        Response from Feishu API

    Raises:
        httpx.HTTPStatusError: If request fails after retries
    """
    webhook_url = validate_feishu_webhook_url(webhook_url, allow_empty=False)

    payload = {
        "msg_type": "text",
        "content": {
            "text": message,
        },
    }

    client = _get_client()
    response = await client.post(webhook_url, json=payload)
    response.raise_for_status()
    return response.json()
