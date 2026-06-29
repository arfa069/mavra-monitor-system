"""Token-first authentication contract tests."""
import importlib
from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from unittest.mock import ANY, AsyncMock, MagicMock

import pytest
from fastapi import HTTPException, Response
from httpx import ASGITransport, AsyncClient
from starlette.requests import Request

from app.core.security import get_current_user
from app.core.tokens import create_access_token_sid
from app.database import get_db
from app.main import app

auth_router = importlib.import_module("app.domains.auth.router")


def _user() -> SimpleNamespace:
    return SimpleNamespace(
        id=1,
        username="testuser",
        email="test@example.com",
        hashed_password="unused-in-token-first-tests",
        role="user",
        is_active=True,
        deleted_at=None,
        created_at=datetime.now(UTC),
    )


def _mock_db() -> AsyncMock:
    db = AsyncMock()
    db.add = MagicMock()
    db.delete = AsyncMock()
    db.flush = AsyncMock()
    db.commit = AsyncMock()
    db.rollback = AsyncMock()
    return db


@pytest.fixture
def token_first_dependencies(monkeypatch):
    user = _user()
    db = _mock_db()
    session = SimpleNamespace(
        id=42,
        user_id=user.id,
        refresh_expires_at=datetime.now(UTC) + timedelta(days=14),
        last_active_at=datetime.now(UTC),
    )

    async def override_db():
        yield db

    app.dependency_overrides[get_db] = override_db
    monkeypatch.setattr(
        auth_router.auth_service,
        "get_user_for_login",
        AsyncMock(return_value=user),
    )
    monkeypatch.setattr(
        auth_router.auth_service,
        "add_login_log",
        AsyncMock(),
    )
    monkeypatch.setattr(auth_router, "verify_password", lambda *_: True)
    monkeypatch.setattr(
        auth_router,
        "is_account_locked",
        AsyncMock(return_value=(False, 0)),
    )
    monkeypatch.setattr(auth_router, "clear_login_attempts", AsyncMock())
    monkeypatch.setattr(auth_router, "record_failed_login", AsyncMock())
    replace_session = AsyncMock(return_value=session)
    monkeypatch.setattr(
        auth_router,
        "replace_user_session",
        replace_session,
        raising=False,
    )
    monkeypatch.setattr(auth_router, "get_role_permissions", AsyncMock(return_value=[]))
    monkeypatch.setattr(auth_router, "log_audit_from_request", AsyncMock())

    yield SimpleNamespace(
        user=user,
        db=db,
        session=session,
        replace_session=replace_session,
    )
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_web_login_returns_access_token_and_refresh_cookie(
    token_first_dependencies,
):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": "testuser",
                "password": "password123",
                "client_kind": "web",
            },
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["token_type"] == "bearer"
    assert payload["expires_in"] > 0
    assert payload["access_token"]
    assert payload["refresh_token"] is None
    assert payload["user"]["username"] == "testuser"

    set_cookie = response.headers.get_list("set-cookie")
    refresh_cookie = next(
        value for value in set_cookie if value.startswith("pm_refresh_token=")
    )
    assert "HttpOnly" in refresh_cookie
    assert "Secure" in refresh_cookie
    assert "SameSite=lax" in refresh_cookie
    assert "Path=/" in refresh_cookie
    max_age_part = next(
        part.strip()
        for part in refresh_cookie.split(";")
        if part.strip().startswith("Max-Age=")
    )
    max_age = int(max_age_part.removeprefix("Max-Age="))
    assert 0 < max_age <= 60 * 60
    access_clear = next(
        value for value in set_cookie if value.startswith("pm_access_token=")
    )
    csrf_clear = next(
        value for value in set_cookie if value.startswith("pm_csrf_token=")
    )
    assert "Max-Age=0" in access_clear
    assert "Max-Age=0" in csrf_clear


@pytest.mark.asyncio
async def test_login_replaces_existing_user_session(token_first_dependencies):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": "testuser",
                "password": "password123",
                "client_kind": "web",
            },
        )

    assert response.status_code == 200
    token_first_dependencies.replace_session.assert_awaited_once_with(
        user_id=token_first_dependencies.user.id,
        refresh_token=ANY,
        device=ANY,
        ip_address=ANY,
        db=token_first_dependencies.db,
    )


@pytest.mark.asyncio
async def test_failed_login_does_not_replace_existing_session(
    monkeypatch,
    token_first_dependencies,
):
    monkeypatch.setattr(auth_router, "verify_password", lambda *_: False)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": "testuser",
                "password": "wrong-password",
                "client_kind": "web",
            },
        )

    assert response.status_code == 401
    token_first_dependencies.replace_session.assert_not_awaited()


@pytest.mark.asyncio
async def test_locked_account_login_does_not_replace_existing_session(
    monkeypatch,
    token_first_dependencies,
):
    monkeypatch.setattr(
        auth_router,
        "is_account_locked",
        AsyncMock(return_value=(True, 15)),
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": "testuser",
                "password": "password123",
                "client_kind": "web",
            },
        )

    assert response.status_code == 429
    token_first_dependencies.replace_session.assert_not_awaited()


@pytest.mark.asyncio
async def test_soft_deleted_user_login_does_not_replace_existing_session(
    token_first_dependencies,
):
    token_first_dependencies.user.deleted_at = datetime.now(UTC)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": "testuser",
                "password": "password123",
                "client_kind": "web",
            },
        )

    assert response.status_code == 401
    token_first_dependencies.replace_session.assert_not_awaited()


@pytest.mark.asyncio
async def test_native_login_returns_both_tokens_without_auth_cookies(
    token_first_dependencies,
):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": "testuser",
                "password": "password123",
                "client_kind": "native",
            },
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["access_token"]
    assert payload["refresh_token"]
    assert response.headers.get_list("set-cookie") == []


@pytest.mark.asyncio
async def test_bearer_me_accepts_strict_sid_access_token(monkeypatch):
    user = _user()
    db = _mock_db()
    user_result = MagicMock()
    user_result.scalar_one_or_none.return_value = user
    touch_result = MagicMock()
    permissions_result = MagicMock()
    permissions_result.scalars.return_value.all.return_value = []
    db.execute = AsyncMock(side_effect=[user_result, touch_result, permissions_result])

    async def override_db():
        yield db

    app.dependency_overrides[get_db] = override_db
    try:
        token = create_access_token_sid(user.id, user.username, 42)
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="https://test") as client:
            response = await client.get(
                "/api/v1/auth/me",
                headers={"Authorization": f"Bearer {token}"},
            )
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json()["username"] == user.username


@pytest.mark.asyncio
async def test_bearer_auth_wins_over_legacy_access_cookie():
    user = _user()
    db = _mock_db()
    result = MagicMock()
    result.scalar_one_or_none.return_value = user
    db.execute = AsyncMock(return_value=result)
    bearer_token = create_access_token_sid(user.id, user.username, 42)
    legacy_cookie = create_access_token_sid(user.id, user.username, 7)
    request = Request(
        {
            "type": "http",
            "method": "GET",
            "path": "/api/v1/auth/me",
            "headers": [
                (b"authorization", f"Bearer {bearer_token}".encode()),
                (b"cookie", f"pm_access_token={legacy_cookie}".encode()),
            ],
        }
    )

    authenticated_user = await get_current_user(request, db)

    statement = db.execute.await_args.args[0]
    statement_values = set(statement.compile().params.values())
    assert authenticated_user is user
    assert 42 in statement_values
    assert 7 not in statement_values


@pytest.mark.asyncio
async def test_bearer_auth_query_filters_expired_sessions():
    user = _user()
    db = _mock_db()
    missing_session = MagicMock()
    missing_session.scalar_one_or_none.return_value = None
    db.execute = AsyncMock(return_value=missing_session)
    token = create_access_token_sid(user.id, user.username, 42)
    request = Request(
        {
            "type": "http",
            "method": "GET",
            "path": "/api/v1/auth/me",
            "headers": [(b"authorization", f"Bearer {token}".encode())],
        }
    )

    with pytest.raises(HTTPException):
        await get_current_user(request, db)

    statement = db.execute.await_args.args[0]
    assert "refresh_expires_at" in str(statement)


@pytest.mark.asyncio
async def test_bearer_auth_query_filters_idle_expired_sessions():
    user = _user()
    db = _mock_db()
    missing_session = MagicMock()
    missing_session.scalar_one_or_none.return_value = None
    db.execute = AsyncMock(return_value=missing_session)
    token = create_access_token_sid(user.id, user.username, 42)
    request = Request(
        {
            "type": "http",
            "method": "GET",
            "path": "/api/v1/auth/me",
            "headers": [(b"authorization", f"Bearer {token}".encode())],
        }
    )

    with pytest.raises(HTTPException):
        await get_current_user(request, db)

    statement = db.execute.await_args.args[0]
    assert "last_active_at" in str(statement)


@pytest.mark.asyncio
async def test_bearer_auth_success_touches_session_activity():
    user = _user()
    db = _mock_db()
    user_result = MagicMock()
    user_result.scalar_one_or_none.return_value = user
    touch_result = MagicMock()
    db.execute = AsyncMock(side_effect=[user_result, touch_result])
    token = create_access_token_sid(user.id, user.username, 42)
    request = Request(
        {
            "type": "http",
            "method": "GET",
            "path": "/api/v1/auth/me",
            "headers": [(b"authorization", f"Bearer {token}".encode())],
        }
    )

    authenticated_user = await get_current_user(request, db)

    assert authenticated_user is user
    touch_statement = db.execute.await_args_list[1].args[0]
    assert "UPDATE users_sessions" in str(touch_statement)
    assert "last_active_at" in str(touch_statement)
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_bearer_auth_success_extends_web_refresh_cookie():
    user = _user()
    db = _mock_db()
    user_result = MagicMock()
    user_result.scalar_one_or_none.return_value = user
    touch_result = MagicMock()
    touch_result.scalar_one_or_none.return_value = datetime.now(UTC) + timedelta(
        days=3,
    )
    db.execute = AsyncMock(side_effect=[user_result, touch_result])
    token = create_access_token_sid(user.id, user.username, 42)
    request = Request(
        {
            "type": "http",
            "method": "GET",
            "path": "/api/v1/auth/me",
            "headers": [
                (b"authorization", f"Bearer {token}".encode()),
                (b"cookie", b"pm_refresh_token=browser-refresh-token"),
            ],
        }
    )
    response = Response()

    authenticated_user = await get_current_user(request, db, response=response)

    assert authenticated_user is user
    refresh_cookie = response.headers["set-cookie"]
    assert refresh_cookie.startswith("pm_refresh_token=browser-refresh-token")
    max_age_part = next(
        part.strip()
        for part in refresh_cookie.split(";")
        if part.strip().startswith("Max-Age=")
    )
    max_age = int(max_age_part.removeprefix("Max-Age="))
    assert 0 < max_age <= 60 * 60


@pytest.mark.asyncio
async def test_native_refresh_rotates_body_token_and_rejects_replay(
    monkeypatch,
    token_first_dependencies,
):
    old_refresh = "old-native-refresh-token-value"
    new_refresh = "new-native-refresh-token-value"
    user_result = MagicMock()
    user_result.scalar_one_or_none.return_value = token_first_dependencies.user
    token_first_dependencies.db.execute = AsyncMock(return_value=user_result)

    lookup = AsyncMock(side_effect=[token_first_dependencies.session, None])
    monkeypatch.setattr(auth_router, "get_session_by_refresh_token", lookup)
    monkeypatch.setattr(auth_router, "rotate_session_refresh_token", AsyncMock())
    monkeypatch.setattr(auth_router, "create_refresh_token", lambda: new_refresh)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        first = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": old_refresh},
        )
        replay = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": old_refresh},
        )

    assert first.status_code == 200
    assert first.json()["refresh_token"] == new_refresh
    assert first.json()["access_token"]
    assert replay.status_code == 401


@pytest.mark.asyncio
async def test_cookie_refresh_cookie_max_age_matches_session_remaining_lifetime(
    monkeypatch,
    token_first_dependencies,
):
    old_refresh = "old-browser-refresh-token-value"
    new_refresh = "new-browser-refresh-token-value"
    session = SimpleNamespace(
        id=42,
        user_id=token_first_dependencies.user.id,
        refresh_expires_at=datetime.now(UTC) + timedelta(seconds=120),
    )
    user_result = MagicMock()
    user_result.scalar_one_or_none.return_value = token_first_dependencies.user
    token_first_dependencies.db.execute = AsyncMock(return_value=user_result)

    monkeypatch.setattr(
        auth_router,
        "get_session_by_refresh_token",
        AsyncMock(return_value=session),
    )
    monkeypatch.setattr(auth_router, "rotate_session_refresh_token", AsyncMock())
    monkeypatch.setattr(auth_router, "create_refresh_token", lambda: new_refresh)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        response = await client.post(
            "/api/v1/auth/refresh",
            cookies={"pm_refresh_token": old_refresh},
            headers={"Origin": "http://localhost:3000"},
        )

    assert response.status_code == 200
    refresh_cookie = next(
        value
        for value in response.headers.get_list("set-cookie")
        if value.startswith("pm_refresh_token=")
    )
    max_age_part = next(
        part.strip()
        for part in refresh_cookie.split(";")
        if part.strip().startswith("Max-Age=")
    )
    max_age = int(max_age_part.removeprefix("Max-Age="))
    assert 0 < max_age <= 120


@pytest.mark.asyncio
async def test_cookie_refresh_invalid_token_clears_auth_cookies(
    monkeypatch,
    token_first_dependencies,
):
    monkeypatch.setattr(
        auth_router,
        "get_session_by_refresh_token",
        AsyncMock(return_value=None),
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        response = await client.post(
            "/api/v1/auth/refresh",
            cookies={"pm_refresh_token": "invalid-browser-refresh-token"},
            headers={"Origin": "http://localhost:3000"},
        )

    assert response.status_code == 401
    set_cookie = response.headers.get_list("set-cookie")
    refresh_clear = next(
        value for value in set_cookie if value.startswith("pm_refresh_token=")
    )
    assert "Max-Age=0" in refresh_clear


@pytest.mark.asyncio
async def test_native_password_change_returns_rotated_tokens_without_cookies(
    monkeypatch,
    token_first_dependencies,
):
    old_refresh = "old-password-refresh-token-value"
    new_refresh = "new-password-refresh-token-value"
    app.dependency_overrides[get_current_user] = lambda: token_first_dependencies.user
    monkeypatch.setattr(
        auth_router,
        "get_session_by_refresh_token",
        AsyncMock(return_value=token_first_dependencies.session),
    )
    monkeypatch.setattr(auth_router, "stage_delete_other_sessions", AsyncMock())
    rotate = AsyncMock()
    monkeypatch.setattr(auth_router, "rotate_session_refresh_token", rotate)
    monkeypatch.setattr(auth_router, "create_refresh_token", lambda: new_refresh)
    try:
        token = create_access_token_sid(
            token_first_dependencies.user.id,
            token_first_dependencies.user.username,
            token_first_dependencies.session.id,
        )
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="https://test") as client:
            response = await client.post(
                "/api/v1/auth/me/password",
                headers={"Authorization": f"Bearer {token}"},
                json={
                    "old_password": "password123",
                    "new_password": "NewSecurePass1!",
                    "refresh_token": old_refresh,
                },
            )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert response.status_code == 200
    assert response.json()["access_token"]
    assert response.json()["refresh_token"] == new_refresh
    assert response.headers.get_list("set-cookie") == []
    rotate.assert_awaited_once_with(
        token_first_dependencies.session,
        new_refresh,
        token_first_dependencies.db,
    )


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("refresh_session_user_id", "refresh_session_id"),
    [
        (2, 42),
        (1, 99),
    ],
)
async def test_native_password_change_rejects_refresh_session_identity_mismatch(
    monkeypatch,
    token_first_dependencies,
    refresh_session_user_id,
    refresh_session_id,
):
    original_password_hash = token_first_dependencies.user.hashed_password
    refresh_session = SimpleNamespace(
        id=refresh_session_id,
        user_id=refresh_session_user_id,
    )
    app.dependency_overrides[get_current_user] = lambda: token_first_dependencies.user
    monkeypatch.setattr(
        auth_router,
        "get_session_by_refresh_token",
        AsyncMock(return_value=refresh_session),
    )
    rotate = AsyncMock()
    monkeypatch.setattr(auth_router, "rotate_session_refresh_token", rotate)
    monkeypatch.setattr(auth_router, "stage_delete_other_sessions", AsyncMock())
    try:
        token = create_access_token_sid(
            token_first_dependencies.user.id,
            token_first_dependencies.user.username,
            token_first_dependencies.session.id,
        )
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="https://test") as client:
            response = await client.post(
                "/api/v1/auth/me/password",
                headers={"Authorization": f"Bearer {token}"},
                json={
                    "old_password": "password123",
                    "new_password": "NewSecurePass1!",
                    "refresh_token": "different-session-refresh-token",
                },
            )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert response.status_code == 401
    assert (
        token_first_dependencies.user.hashed_password
        == original_password_hash
    )
    rotate.assert_not_awaited()
    token_first_dependencies.db.commit.assert_not_awaited()


@pytest.mark.asyncio
async def test_cookie_refresh_rejects_untrusted_origin(token_first_dependencies):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://test") as client:
        response = await client.post(
            "/api/v1/auth/refresh",
            cookies={"pm_refresh_token": "browser-refresh-token-value"},
            headers={"Origin": "https://evil.example"},
        )

    assert response.status_code == 403
    assert "Origin" in response.json()["detail"]
    token_first_dependencies.db.execute.assert_not_called()


@pytest.mark.asyncio
async def test_cookie_logout_rejects_untrusted_origin(
    token_first_dependencies,
):
    app.dependency_overrides[get_current_user] = lambda: token_first_dependencies.user
    try:
        access_token = create_access_token_sid(
            token_first_dependencies.user.id,
            token_first_dependencies.user.username,
            token_first_dependencies.session.id,
        )
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="https://test") as client:
            response = await client.post(
                "/api/v1/auth/logout",
                cookies={
                    "pm_access_token": access_token,
                    "pm_refresh_token": "browser-refresh-token-value",
                    "pm_csrf_token": "csrf-value",
                },
                headers={
                    "Origin": "https://evil.example",
                    "X-CSRF-Token": "csrf-value",
                },
            )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert response.status_code == 403
    token_first_dependencies.db.delete.assert_not_awaited()


@pytest.mark.asyncio
async def test_bearer_logout_deletes_sid_session_and_clears_cookie_attributes(
    monkeypatch,
    token_first_dependencies,
):
    app.dependency_overrides[get_current_user] = lambda: token_first_dependencies.user
    monkeypatch.setattr(
        auth_router,
        "get_session_by_id",
        AsyncMock(return_value=token_first_dependencies.session),
        raising=False,
    )
    try:
        token = create_access_token_sid(
            token_first_dependencies.user.id,
            token_first_dependencies.user.username,
            token_first_dependencies.session.id,
        )
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="https://test") as client:
            response = await client.post(
                "/api/v1/auth/logout",
                headers={"Authorization": f"Bearer {token}"},
            )
            app.dependency_overrides.pop(get_current_user, None)
            missing_session = MagicMock()
            missing_session.scalar_one_or_none.return_value = None
            token_first_dependencies.db.execute = AsyncMock(
                return_value=missing_session
            )
            me_after_logout = await client.get(
                "/api/v1/auth/me",
                headers={"Authorization": f"Bearer {token}"},
            )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert response.status_code == 200
    assert me_after_logout.status_code == 401
    token_first_dependencies.db.delete.assert_awaited_once_with(
        token_first_dependencies.session
    )
    set_cookie = response.headers.get_list("set-cookie")
    refresh_clear = next(
        value for value in set_cookie if value.startswith("pm_refresh_token=")
    )
    assert "Max-Age=0" in refresh_clear
    assert "Secure" in refresh_clear
    assert "SameSite=lax" in refresh_clear
    assert "Path=/" in refresh_clear


@pytest.mark.asyncio
async def test_bearer_logout_ignores_body_refresh_and_deletes_bearer_session(
    monkeypatch,
    token_first_dependencies,
):
    app.dependency_overrides[get_current_user] = lambda: token_first_dependencies.user
    refresh_lookup = AsyncMock(
        return_value=SimpleNamespace(id=99, user_id=token_first_dependencies.user.id)
    )
    bearer_lookup = AsyncMock(return_value=token_first_dependencies.session)
    monkeypatch.setattr(auth_router, "get_session_by_refresh_token", refresh_lookup)
    monkeypatch.setattr(auth_router, "get_session_by_id", bearer_lookup)
    try:
        token = create_access_token_sid(
            token_first_dependencies.user.id,
            token_first_dependencies.user.username,
            token_first_dependencies.session.id,
        )
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="https://test") as client:
            response = await client.post(
                "/api/v1/auth/logout",
                headers={"Authorization": f"Bearer {token}"},
                json={"refresh_token": "different-session-refresh-token"},
            )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert response.status_code == 200
    refresh_lookup.assert_not_awaited()
    bearer_lookup.assert_awaited_once_with(
        token_first_dependencies.session.id,
        token_first_dependencies.user.id,
        token_first_dependencies.db,
    )
    token_first_dependencies.db.delete.assert_awaited_once_with(
        token_first_dependencies.session
    )


@pytest.mark.asyncio
async def test_logout_delete_failure_returns_500_without_clearing_cookies(
    monkeypatch,
    token_first_dependencies,
):
    app.dependency_overrides[get_current_user] = lambda: token_first_dependencies.user
    monkeypatch.setattr(
        auth_router,
        "get_session_by_id",
        AsyncMock(return_value=token_first_dependencies.session),
    )
    token_first_dependencies.db.delete.side_effect = RuntimeError("database unavailable")
    try:
        token = create_access_token_sid(
            token_first_dependencies.user.id,
            token_first_dependencies.user.username,
            token_first_dependencies.session.id,
        )
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="https://test") as client:
            response = await client.post(
                "/api/v1/auth/logout",
                headers={"Authorization": f"Bearer {token}"},
            )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert response.status_code == 500
    assert response.headers.get_list("set-cookie") == []
    token_first_dependencies.db.rollback.assert_awaited_once()
    auth_router.log_audit_from_request.assert_not_awaited()


@pytest.mark.asyncio
async def test_csrf_protection_skips_native_bearer_requests():
    request = Request(
        {
            "type": "http",
            "method": "POST",
            "path": "/api/v1/auth/logout",
            "headers": [(b"authorization", b"Bearer native-access-token")],
        }
    )

    await auth_router.csrf_protect(request)


@pytest.mark.asyncio
async def test_csrf_protection_skips_bearer_with_legacy_access_cookie():
    request = Request(
        {
            "type": "http",
            "method": "POST",
            "path": "/api/v1/auth/logout",
            "headers": [
                (b"authorization", b"Bearer native-access-token"),
                (b"cookie", b"pm_access_token=legacy-cookie"),
            ],
        }
    )

    await auth_router.csrf_protect(request)
