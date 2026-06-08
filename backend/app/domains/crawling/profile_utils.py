"""Shared profile utilities."""
from __future__ import annotations

from datetime import UTC, datetime

from app.models.crawl_profile import CrawlProfile


class CrawlProfileLeaseActiveError(RuntimeError):
    """Raised when a non-expired lease is still active."""


def assert_profile_not_leased(profile: CrawlProfile) -> None:
    """Raise if the profile has an active (non-expired) lease."""
    if profile.lease_until is not None and profile.lease_until > datetime.now(UTC):
        raise CrawlProfileLeaseActiveError(profile.profile_key)
