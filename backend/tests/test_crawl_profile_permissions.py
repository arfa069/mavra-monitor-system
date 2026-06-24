"""Security regression tests for crawl profile management permissions."""

from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_current_user
from app.database import get_db
from app.domains.crawling import profile_service
from app.main import app


def _make_user(role: str) -> MagicMock:
    user = MagicMock()
    user.id = 1
    user.username = f"{role}-user"
    user.email = f"{role}@example.test"
    user.role = role
    user.is_active = True
    user.deleted_at = None
    user.created_at = datetime.now(UTC)
    user.updated_at = datetime.now(UTC)
    return user


def _override_user(role: str) -> None:
    async def _current_user():
        return _make_user(role)

    app.dependency_overrides[get_current_user] = _current_user


def _override_db() -> None:
    async def _db():
        yield AsyncMock()

    app.dependency_overrides[get_db] = _db


def _clear_overrides() -> None:
    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_db, None)


@pytest.mark.anyio
async def test_crawl_profiles_require_profile_manage_permission(monkeypatch):
    """A normal authenticated user must not list shared browser profiles."""
    _override_user("user")
    _override_db()
    monkeypatch.setattr(
        "app.core.permissions.role_has_permission",
        AsyncMock(return_value=False),
    )
    monkeypatch.setattr(
        "app.core.permissions.permission_exists",
        AsyncMock(return_value=True),
    )
    list_profiles = AsyncMock(return_value=[])
    monkeypatch.setattr(profile_service, "list_profiles", list_profiles)

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(
                "/api/v1/crawl-profiles",
                headers={"Authorization": "Bearer fake"},
            )

        assert response.status_code == 403
        list_profiles.assert_not_awaited()
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_crawl_profiles_allow_profile_manager(monkeypatch):
    """Admins with crawl_profile:manage can still list profiles."""
    _override_user("admin")
    _override_db()
    monkeypatch.setattr(
        "app.core.permissions.role_has_permission",
        AsyncMock(return_value=True),
    )
    monkeypatch.setattr(
        "app.core.permissions.permission_exists",
        AsyncMock(return_value=True),
    )
    list_profiles = AsyncMock(return_value=[])
    monkeypatch.setattr(profile_service, "list_profiles", list_profiles)

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(
                "/api/v1/crawl-profiles",
                headers={"Authorization": "Bearer fake"},
            )

        assert response.status_code == 200
        assert response.json() == []
        list_profiles.assert_awaited_once()
    finally:
        _clear_overrides()
