"""JSON serialization utilities."""

from __future__ import annotations

import json
from collections.abc import Callable
from datetime import datetime
from typing import Any


def json_default(value: Any) -> str:
    """Serialize datetime to ISO format; fall back to str()."""
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


def safe_json_dumps(value: Any, *, default: Callable[[Any], str] | None = None) -> str:
    """Serialize value to JSON with ``ensure_ascii=False``."""
    return json.dumps(value, ensure_ascii=False, default=default)
