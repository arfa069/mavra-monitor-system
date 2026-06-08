"""Time utilities."""
from __future__ import annotations

from datetime import UTC, datetime


def now_utc() -> datetime:
    """Return current UTC datetime."""
    return datetime.now(UTC)


def today_start_utc() -> datetime:
    """Return today's start (00:00:00) in UTC."""
    return datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
