"""Sensitive-value redaction helpers for logs and event payloads."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

FULL_REDACT_KEYS = {
    "authorization",
    "cookie",
    "cookies",
    "set-cookie",
    "token",
    "access_token",
    "refresh_token",
    "stoken",
    "__zp_stoken__",
    "webhook_url",
    "feishu_webhook_url",
}
PARTIAL_REDACT_KEYS = {"securityid", "security_id"}


def redact_payload(value: Any) -> Any:
    if isinstance(value, Mapping):
        redacted = {}
        for key, item in value.items():
            normalized = str(key).lower()
            if normalized in FULL_REDACT_KEYS:
                redacted[key] = "***REDACTED***"
            elif normalized in PARTIAL_REDACT_KEYS:
                s = str(item)
                redacted[key] = f"{s[:8]}***" if len(s) > 8 else "***"
            else:
                redacted[key] = redact_payload(item)
        return redacted
    if isinstance(value, list):
        return [redact_payload(item) for item in value]
    if isinstance(value, tuple):
        return tuple(redact_payload(item) for item in value)
    if isinstance(value, set):
        return {redact_payload(item) for item in value}
    return value
