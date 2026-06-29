from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock
from urllib.parse import parse_qs, urlparse

import pytest
from httpx import ASGITransport, AsyncClient

from app.database import get_db
from app.domains.auth import wechat_router
from app.main import app
from app.schemas.auth import UserResponse


class MockJsonResponse:
    def __init__(self, payload):
        self._payload = payload

    def json(self):
        return self._payload


class MockWeChatClient:
    def __init__(self, payload):
        self._payload = payload

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb):
        return False

    async def get(self, *args, **kwargs):
        return MockJsonResponse(self._payload)


@pytest.fixture(autouse=True)
def cleanup_overrides_and_state():
    yield
    app.dependency_overrides.clear()
    wechat_router._state_cache.clear()


@pytest.fixture
def mock_db_session():
    session = AsyncMock()
    session.execute = AsyncMock()
    session.commit = AsyncMock()
    session.flush = AsyncMock()
    session.refresh = AsyncMock()
    session.add = MagicMock()
    return session


@pytest.fixture
def mock_get_db(mock_db_session):
    async def _override():
        yield mock_db_session

    app.dependency_overrides[get_db] = _override
    return mock_db_session


def _enable_wechat(monkeypatch):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.settings.wechat_frontend_callback_url",
        "http://localhost:3000/auth/wechat/callback",
    )


def _extract_exchange_code(location: str) -> str:
    parsed = urlparse(location)
    values = parse_qs(parsed.query).get("exchange_code")
    assert values and values[0]
    return values[0]


def _wechat_user() -> MagicMock:
    user = MagicMock()
    user.id = 1
    user.username = "wechat-user"
    user.email = "wechat@example.com"
    user.role = "user"
    user.is_active = True
    user.deleted_at = None
    user.created_at = datetime.now(UTC)
    return user


@pytest.mark.asyncio
async def test_wechat_qr_preserves_safe_next(monkeypatch):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/auth/wechat/qr", params={"next": "/jobs"})

    assert response.status_code == 200
    data = response.json()
    assert data["state"]
    assert wechat_router._state_cache[data["state"]].next_path == "/jobs"


@pytest.mark.asyncio
async def test_wechat_qr_rejects_external_next(monkeypatch):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/auth/wechat/qr",
            params={"next": "https://evil.example/callback"},
        )

    assert response.status_code == 200
    data = response.json()
    assert data["state"]
    assert wechat_router._state_cache[data["state"]].next_path == "/today"


@pytest.mark.asyncio
async def test_wechat_bind_accepts_json_body(monkeypatch, mock_get_db):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")
    monkeypatch.setattr(
        "app.core.security.decode_access_token",
        lambda token: {"temp": True, "wechat_openid": "openid-1"},
    )
    monkeypatch.setattr(
        "app.core.security.verify_password",
        lambda password, hashed_password: True,
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_login",
        AsyncMock(return_value=None),
    )

    user = MagicMock()
    user.id = 1
    user.username = "bound-user"
    user.email = "bound@example.com"
    user.role = "user"
    user.is_active = True
    user.created_at = datetime.now(UTC)
    user.hashed_password = "hashed-password"

    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_bind",
        AsyncMock(return_value=user),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.bind_wechat_openid",
        AsyncMock(return_value=user),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router._create_wechat_auth_session",
        AsyncMock(
            return_value=UserResponse(
                id=1,
                username="bound-user",
                email="bound@example.com",
                role="user",
                permissions=["job:read"],
                is_active=True,
                created_at=datetime.now(UTC),
            )
        ),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.log_audit_from_request",
        AsyncMock(),
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/wechat/bind",
            json={
                "temp_token": "temp-token",
                "username": "bound-user",
                "password": "SecurePass1!",
            },
        )

    assert response.status_code == 200
    assert response.json()["username"] == "bound-user"


@pytest.mark.asyncio
async def test_wechat_callback_redirects_bound_user_to_frontend(
    monkeypatch,
    mock_get_db,
):
    _enable_wechat(monkeypatch)
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.httpx.AsyncClient",
        lambda: MockWeChatClient({"openid": "openid-1"}),
    )
    replace_session_spy = AsyncMock(return_value=MagicMock(id=99))
    monkeypatch.setattr(
        wechat_router,
        "replace_user_session",
        replace_session_spy,
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.get_role_permissions",
        AsyncMock(return_value=["job:read"]),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.log_audit_from_request",
        AsyncMock(),
    )

    user = _wechat_user()

    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_login",
        AsyncMock(return_value=user),
    )
    wechat_router._state_cache["state-1"] = wechat_router.WeChatStateEntry(
        issued_at=datetime.now(UTC),
        next_path="/jobs",
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/auth/wechat/callback?code=valid-code&state=state-1",
            follow_redirects=False,
        )

    assert response.status_code == 302
    location = response.headers["location"]
    assert location.startswith(
        "http://localhost:3000/auth/wechat/callback?status=success"
    )
    assert "exchange_code=" in location
    assert "access_token=" not in location
    assert "refresh_token=" not in location
    assert "temp_token=" not in location
    assert "set-cookie" not in response.headers
    replace_session_spy.assert_not_awaited()


@pytest.mark.asyncio
async def test_wechat_callback_redirects_unbound_user_with_fragment(
    monkeypatch,
    mock_get_db,
):
    _enable_wechat(monkeypatch)
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.httpx.AsyncClient",
        lambda: MockWeChatClient({"openid": "openid-2"}),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_login",
        AsyncMock(return_value=None),
    )
    wechat_router._state_cache["state-2"] = wechat_router.WeChatStateEntry(
        issued_at=datetime.now(UTC),
        next_path="/today",
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/auth/wechat/callback?code=valid-code&state=state-2",
            follow_redirects=False,
        )

    assert response.status_code == 302
    location = response.headers["location"]
    assert "status=unbound" in location
    assert "exchange_code=" in location
    assert "#temp_token=" not in location


@pytest.mark.asyncio
async def test_wechat_exchange_bound_code_returns_native_session(
    monkeypatch,
    mock_get_db,
):
    _enable_wechat(monkeypatch)
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.httpx.AsyncClient",
        lambda: MockWeChatClient({"openid": "openid-1"}),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.get_role_permissions",
        AsyncMock(return_value=["job:read"]),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.log_audit_from_request",
        AsyncMock(),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.create_refresh_token",
        lambda: "new-wechat-refresh-token-value",
    )
    replace_session_spy = AsyncMock(return_value=MagicMock(id=99))
    monkeypatch.setattr(
        wechat_router,
        "replace_user_session",
        replace_session_spy,
        raising=False,
    )

    user = _wechat_user()
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_login",
        AsyncMock(return_value=user),
    )
    wechat_router._state_cache["state-bound"] = wechat_router.WeChatStateEntry(
        issued_at=datetime.now(UTC),
        next_path="/jobs",
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        callback = await client.get(
            "/api/v1/auth/wechat/callback?code=valid-code&state=state-bound",
            follow_redirects=False,
        )
        exchange_code = _extract_exchange_code(callback.headers["location"])
        response = await client.post(
            "/api/v1/auth/wechat/exchange",
            json={"exchange_code": exchange_code, "client_kind": "native"},
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "success"
    assert payload["unbound"] is None
    assert payload["session"]["access_token"]
    assert payload["session"]["refresh_token"] == "new-wechat-refresh-token-value"
    assert payload["session"]["user"]["username"] == "wechat-user"
    replace_session_spy.assert_awaited_once()


@pytest.mark.asyncio
async def test_wechat_exchange_unbound_code_returns_temp_token_once(
    monkeypatch,
    mock_get_db,
):
    _enable_wechat(monkeypatch)
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.httpx.AsyncClient",
        lambda: MockWeChatClient({"openid": "openid-2"}),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_login",
        AsyncMock(return_value=None),
    )
    wechat_router._state_cache["state-unbound"] = wechat_router.WeChatStateEntry(
        issued_at=datetime.now(UTC),
        next_path="/today",
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        callback = await client.get(
            "/api/v1/auth/wechat/callback?code=valid-code&state=state-unbound",
            follow_redirects=False,
        )
        exchange_code = _extract_exchange_code(callback.headers["location"])
        first = await client.post(
            "/api/v1/auth/wechat/exchange",
            json={"exchange_code": exchange_code},
        )
        replay = await client.post(
            "/api/v1/auth/wechat/exchange",
            json={"exchange_code": exchange_code},
        )
        missing = await client.post(
            "/api/v1/auth/wechat/exchange",
            json={"exchange_code": "expired-or-missing-exchange-code"},
        )

    assert first.status_code == 200
    payload = first.json()
    assert payload["status"] == "unbound"
    assert payload["session"] is None
    assert payload["unbound"]["temp_token"]
    assert payload["unbound"]["next_path"] == "/today"
    assert replay.status_code == 400
    assert missing.status_code == 400


@pytest.mark.asyncio
async def test_wechat_callback_redirects_state_error(monkeypatch):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.settings.wechat_frontend_callback_url",
        "http://localhost:3000/auth/wechat/callback",
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/auth/wechat/callback?code=bad&state=missing",
            follow_redirects=False,
        )

    assert response.status_code == 302
    assert "status=error" in response.headers["location"]
    assert "reason=state_expired" in response.headers["location"]


@pytest.mark.asyncio
async def test_wechat_qr_uses_canonical_backend_callback_by_default(
    monkeypatch,
):
    from urllib.parse import parse_qs, urlparse

    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "test-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "test-secret")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_redirect_uri", None)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/auth/wechat/qr")

    assert response.status_code == 200
    query = parse_qs(urlparse(response.json()["qr_url"]).query)
    assert query["redirect_uri"] == [
        "http://localhost:8000/api/v1/auth/wechat/callback"
    ]

