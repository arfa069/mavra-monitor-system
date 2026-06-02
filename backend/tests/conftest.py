"""Pytest configuration and fixtures for price monitor tests."""
import os
import shutil
import tempfile
from collections.abc import AsyncGenerator
from pathlib import Path

import pytest
from httpx import ASGITransport, AsyncClient

_TEST_PROFILE_ROOT = Path(tempfile.mkdtemp(prefix="price-monitor-test-profiles-"))
os.environ["PRICE_MONITOR_PROFILE_ROOT"] = str(_TEST_PROFILE_ROOT)


@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"


@pytest.fixture
async def async_client() -> AsyncGenerator[AsyncClient, None]:
    """HTTP client for integration tests."""
    from app.main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.fixture
def test_user() -> dict:
    """Test user data for authentication tests."""
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "securepassword123",
    }


@pytest.fixture
def another_user() -> dict:
    """Another test user for conflict tests."""
    return {
        "username": "anotheruser",
        "email": "another@example.com",
        "password": "anotherpassword456",
    }

@pytest.fixture(scope="session", autouse=True)
def _clean_test_profiles():
    """Clean up test-created profile directories after the test session."""
    yield
    shutil.rmtree(_TEST_PROFILE_ROOT, ignore_errors=True)
