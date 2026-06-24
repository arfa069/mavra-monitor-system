"""API error envelope tests for Flutter clients."""

from datetime import UTC, datetime
from importlib import import_module
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_current_user
from app.database import get_db
from app.main import app


def _user(role: str = "user") -> MagicMock:
    user = MagicMock()
    user.id = 1
    user.username = "error-user"
    user.email = "error@example.com"
    user.role = role
    user.is_active = True
    user.deleted_at = None
    user.created_at = datetime.now(UTC)
    return user


def _assert_error_envelope(payload: dict, *, code: str) -> None:
    assert payload["code"] == code
    assert isinstance(payload["message"], str)
    assert payload["message"]
    assert isinstance(payload["details"], dict)
    assert isinstance(payload["trace_id"], str)
    assert payload["trace_id"]
    assert payload["help_url"] == f"/docs/errors/{code}"


@pytest.fixture(autouse=True)
def cleanup_overrides():
    yield
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_401_error_contract_guides_reauthentication():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/auth/me")

    assert response.status_code == 401
    payload = response.json()
    _assert_error_envelope(payload, code="session_expired")
    assert "刷新" in payload["message"]
    assert "重新登录" in payload["message"]


@pytest.mark.asyncio
async def test_validation_error_contract_includes_field_paths():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/api/v1/auth/login", json={})

    assert response.status_code == 422
    payload = response.json()
    _assert_error_envelope(payload, code="validation_error")
    fields = payload["details"]["fields"]
    assert {"path": "body.username", "message": "Field required", "type": "missing"} in fields
    assert {"path": "body.password", "message": "Field required", "type": "missing"} in fields


@pytest.mark.asyncio
async def test_403_error_contract_preserves_permission_message():
    async def _override_user():
        return _user(role="user")

    async def _override_db():
        yield AsyncMock()

    app.dependency_overrides[get_current_user] = _override_user
    app.dependency_overrides[get_db] = _override_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/dashboard/alerts/recent")

    assert response.status_code == 403
    payload = response.json()
    _assert_error_envelope(payload, code="forbidden")
    assert "权限" in payload["message"]


@pytest.mark.asyncio
async def test_404_error_contract_has_help_url():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/not-a-real-route")

    assert response.status_code == 404
    payload = response.json()
    _assert_error_envelope(payload, code="not_found")


@pytest.mark.asyncio
async def test_500_error_contract_is_safe_and_traceable(monkeypatch):
    dashboard_router = import_module("app.domains.dashboard.router")

    class ExplodingDashboardService:
        def __init__(self, db, redis_client=None):
            pass

        async def calculate_user_kpi(self, user_id):
            raise RuntimeError("database password is super-secret")

    async def _override_user():
        return _user(role="user")

    async def _override_db():
        yield AsyncMock()

    monkeypatch.setattr(
        dashboard_router,
        "DashboardService",
        ExplodingDashboardService,
    )
    app.dependency_overrides[get_current_user] = _override_user
    app.dependency_overrides[get_db] = _override_db

    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/dashboard/kpi")

    assert response.status_code == 500
    payload = response.json()
    _assert_error_envelope(payload, code="internal_error")
    assert "稍后" in payload["message"]
    assert "super-secret" not in response.text
