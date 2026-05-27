"""Safety helpers for tests that mutate the configured database."""

from __future__ import annotations

import os
from urllib.parse import urlparse

import pytest

from app.config import settings


def require_test_database() -> None:
    """Skip destructive DB tests unless the configured database is clearly a test DB."""
    if os.environ.get("PRICE_MONITOR_ALLOW_DESTRUCTIVE_TEST_DB") == "1":
        return

    database_name = (urlparse(settings.database_url).path or "").strip("/").lower()
    if "test" in database_name or "pytest" in database_name:
        return

    pytest.skip(
        "destructive database test skipped: DATABASE_URL does not point to a test database"
    )
