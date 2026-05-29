"""Pytest configuration and fixtures for price monitor tests."""
from collections.abc import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient

from app.config import settings
from app.main import app


@pytest.fixture(scope="session", autouse=True)
def enable_crawler_inline_execution():
    """Tests default to inline execution so existing behaviour remains verifiable."""
    settings.crawler_inline_execution_enabled = True


@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"


@pytest.fixture
async def async_client() -> AsyncGenerator[AsyncClient, None]:
    """HTTP client for integration tests."""
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


import shutil
from pathlib import Path


@pytest.fixture(scope="session", autouse=True)
def _clean_test_profiles():
    """Clean up test-created profile directories after each test."""
    yield
    profiles_root = Path(__file__).resolve().parent.parent / "profiles"
    if profiles_root.exists():
        for d in profiles_root.iterdir():
            if d.is_dir() and ("test" in d.name or d.name.startswith("job-")):
                shutil.rmtree(d, ignore_errors=True)

import tempfile
from pathlib import Path


@pytest.fixture(scope="session", autouse=True)
def _temp_profile_root(tmp_path_factory):
    """Redirect test profile directories to a temp location."""
    import app.core.crawler_paths as cp
    temp_root = tmp_path_factory.mktemp("test_profiles")
    cp._project_root = lambda: temp_root
    yield