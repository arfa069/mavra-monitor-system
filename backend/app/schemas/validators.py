"""Shared Pydantic field validators."""

from __future__ import annotations

import zoneinfo

from apscheduler.triggers.cron import CronTrigger


def validate_cron_value(v: str | None) -> str | None:
    """Validate a crontab expression string."""
    if v is None:
        return v
    val = v.strip()
    if not val:
        return None
    try:
        CronTrigger.from_crontab(val)
    except Exception as exc:
        raise ValueError(f"Invalid cron expression: {exc}")
    return val


def validate_timezone_value(v: str | None) -> str | None:
    """Validate a timezone string."""
    if not v:
        return v
    val = v.strip()
    if not val:
        return None
    try:
        zoneinfo.ZoneInfo(val)
    except Exception:
        raise ValueError(f"Invalid timezone: {v}")
    return val
