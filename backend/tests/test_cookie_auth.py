"""Tests for cookie-based authentication.

These tests verify that cookie-based auth (get_current_user_cookie)
works correctly alongside the existing header-based auth (get_current_user).

Run with:
    python -m pytest tests/test_cookie_auth.py -v
"""
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import Depends, FastAPI
from httpx import ASGITransport, AsyncClient

from app.core.security import (
    create_access_token_sid,
    csrf_protect,
    get_current_user_cookie,
)
from app.database import get_db


@pytest.fixture
def mock_db_session():
    """Mock database session for auth tests."""
    session = AsyncMock()
    session.execute = AsyncMock()
    session.commit = AsyncMock()
    session.add = MagicMock()
    session.refresh = AsyncMock()
    return session


@pytest.fixture
def test_app(mock_db_session):
    """Create a test app with cookie auth endpoints."""
    app = FastAPI()

    # Override get_db
    async def _override():
        yield mock_db_session
    app.dependency_overrides[get_db] = _override

    @app.get("/test/me")
    async def test_me(current_user=Depends(get_current_user_cookie)):
        return {
            "id": current_user.id,
            "username": current_user.username,
            "email": current_user.email,
        }

    @app.post("/test/protected")
    async def test_protected(
        current_user=Depends(get_current_user_cookie),
        _=Depends(csrf_protect),
    ):
        return {"message": "ok", "user_id": current_user.id}

    @app.get("/test/public")
    async def test_public(
        current_user=Depends(get_current_user_cookie),
        _=Depends(csrf_protect),
    ):
        return {
            "id": current_user.id,
            "username": current_user.username,
        }

    yield app
    app.dependency_overrides.pop(get_db, None)


# ── Cookie Auth Tests ──────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_me_with_valid_cookie_succeeds(test_user, mock_db_session, test_app):
    """GET /test/me succeeds with valid pm_access_token cookie."""
    from datetime import UTC, datetime

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.role = "user"
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)

    mock_session = MagicMock()
    mock_session.id = 42
    mock_session.user_id = 1

    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = mock_user

    mock_result_session = MagicMock()
    mock_result_session.scalar_one_or_none.return_value = mock_session

    mock_db_session.execute.side_effect = [mock_result_user, mock_result_session]

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 200
    data = response.json()
    assert data["username"] == test_user["username"]
    assert data["email"] == test_user["email"]


@pytest.mark.asyncio
async def test_me_without_cookie_returns_401(test_app):
    """GET /test/me without pm_access_token cookie returns 401."""
    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/test/me")

    assert response.status_code == 401
    assert "认证" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_me_with_invalid_token_returns_401(test_app):
    """GET /test/me with invalid pm_access_token cookie returns 401."""
    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": "invalid_token"},
        )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_with_expired_token_returns_401(test_app):
    """GET /test/me with expired pm_access_token cookie returns 401."""
    from datetime import UTC, datetime, timedelta

    from jose import jwt

    from app.config import settings

    payload = {
        "sub": "1",
        "username": "testuser",
        "sid": 42,
        "typ": "access",
        "exp": datetime.now(UTC) - timedelta(hours=1),
    }
    expired_token = jwt.encode(payload, settings.jwt_secret_key, algorithm="HS256")

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": expired_token},
        )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_query_filters_expired_sessions(test_user, mock_db_session, test_app):
    """Cookie auth should reject sessions whose refresh lifetime has ended."""
    token = create_access_token_sid(1, test_user["username"], 42)

    missing_session = MagicMock()
    missing_session.scalar_one_or_none.return_value = None
    mock_db_session.execute.return_value = missing_session

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 401
    statement = mock_db_session.execute.await_args.args[0]
    assert "refresh_expires_at" in str(statement)


@pytest.mark.asyncio
async def test_me_query_filters_idle_expired_sessions(
    test_user,
    mock_db_session,
    test_app,
):
    """Cookie auth should reject sessions idle beyond the configured window."""
    token = create_access_token_sid(1, test_user["username"], 42)

    missing_session = MagicMock()
    missing_session.scalar_one_or_none.return_value = None
    mock_db_session.execute.return_value = missing_session

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 401
    statement = mock_db_session.execute.await_args.args[0]
    assert "last_active_at" in str(statement)


@pytest.mark.asyncio
async def test_me_with_valid_cookie_touches_session_activity(
    test_user,
    mock_db_session,
    test_app,
):
    """Successful cookie auth should slide the idle timeout forward."""
    from datetime import UTC, datetime

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.role = "user"
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)

    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = mock_user
    touch_result = MagicMock()
    mock_db_session.execute.side_effect = [mock_result_user, touch_result]

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 200
    touch_statement = mock_db_session.execute.await_args_list[1].args[0]
    assert "UPDATE users_sessions" in str(touch_statement)
    assert "last_active_at" in str(touch_statement)
    mock_db_session.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_me_with_valid_cookie_extends_refresh_cookie_max_age(
    test_user,
    mock_db_session,
    test_app,
):
    """Successful cookie auth should slide the Web refresh cookie forward."""
    from datetime import UTC, datetime, timedelta

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.role = "user"
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)

    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = mock_user
    touch_result = MagicMock()
    touch_result.scalar_one_or_none.return_value = datetime.now(UTC) + timedelta(
        days=3,
    )
    mock_db_session.execute.side_effect = [mock_result_user, touch_result]

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={
                "pm_access_token": token,
                "pm_refresh_token": "browser-refresh-token",
            },
        )

    assert response.status_code == 200
    refresh_cookie = next(
        value
        for value in response.headers.get_list("set-cookie")
        if value.startswith("pm_refresh_token=browser-refresh-token")
    )
    max_age_part = next(
        part.strip()
        for part in refresh_cookie.split(";")
        if part.strip().startswith("Max-Age=")
    )
    max_age = int(max_age_part.removeprefix("Max-Age="))
    assert 0 < max_age <= 60 * 60


@pytest.mark.asyncio
async def test_me_with_wrong_token_type_returns_401(test_app):
    """GET /test/me with token missing 'typ=access' claim returns 401."""
    from app.core.tokens import create_access_token

    # Legacy create_access_token does not include typ="access"
    token = create_access_token({"sub": "1", "username": "testuser"})

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_with_malformed_sid_returns_401(test_app):
    """GET /test/me with non-integer sid in token returns 401."""
    from datetime import UTC, datetime, timedelta

    from jose import jwt

    from app.config import settings

    payload = {
        "sub": "1",
        "username": "testuser",
        "sid": "not-an-integer",
        "typ": "access",
        "exp": datetime.now(UTC) + timedelta(hours=1),
    }
    token = jwt.encode(payload, settings.jwt_secret_key, algorithm="HS256")

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_with_nonexistent_user_returns_401(test_user, mock_db_session, test_app):
    """GET /test/me when user is not found (deleted data) returns 401."""
    token = create_access_token_sid(1, test_user["username"], 42)

    # User not found in DB
    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = None

    mock_db_session.execute.return_value = mock_result_user

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 401
    # JOIN query returns None for both "user not found" and "session not found"
    assert "会话" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_me_with_deleted_user_returns_401(test_user, mock_db_session, test_app):
    """GET /test/me with soft-deleted user returns 401.

    The SQL query uses ``WHERE deleted_at IS NULL``, so a soft-deleted
    user is never returned by the database — the mock returns None.
    """
    token = create_access_token_sid(1, test_user["username"], 42)

    # SQL with ``deleted_at IS NULL`` filters out the deleted user
    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = None

    mock_db_session.execute.return_value = mock_result_user

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_with_missing_session_returns_401(test_user, mock_db_session, test_app):
    """GET /test/me with valid token but missing session returns 401."""

    token = create_access_token_sid(1, test_user["username"], 42)

    # JOIN query returns None (session not found for sid=42)
    mock_result_session = MagicMock()
    mock_result_session.scalar_one_or_none.return_value = None

    mock_db_session.execute.return_value = mock_result_session

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 401
    assert "会话" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_me_with_authorization_header_only_fails(test_user, mock_db_session, test_app):
    """GET /test/me with only Authorization header returns 401 for cookie auth.

    The cookie-based auth should NOT fall back to Authorization header.
    """
    token = create_access_token_sid(1, test_user["username"], 42)

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/me",
            headers={"Authorization": f"Bearer {token}"},
        )

    assert response.status_code == 401


# ── CSRF Protection Tests ──────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_csrf_skipped_for_get(test_user, mock_db_session, test_app):
    """CSRF check is skipped for GET requests."""
    from datetime import UTC, datetime

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.role = "user"
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)

    mock_session = MagicMock()
    mock_session.id = 42
    mock_session.user_id = 1

    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = mock_user

    mock_result_session = MagicMock()
    mock_result_session.scalar_one_or_none.return_value = mock_session

    mock_db_session.execute.side_effect = [mock_result_user, mock_result_session]

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/test/public",
            cookies={"pm_access_token": token},
        )

    # GET should succeed even without CSRF cookie/header
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_csrf_missing_cookie_returns_403(test_user, mock_db_session, test_app):
    """POST without pm_csrf_token cookie returns 403 when CSRF is required."""
    from datetime import UTC, datetime

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)

    mock_session = MagicMock()
    mock_session.id = 42
    mock_session.user_id = 1

    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = mock_user

    mock_result_session = MagicMock()
    mock_result_session.scalar_one_or_none.return_value = mock_session

    mock_db_session.execute.side_effect = [mock_result_user, mock_result_session]

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/test/protected",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 403
    assert "CSRF" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_csrf_missing_header_returns_403(test_user, mock_db_session, test_app):
    """POST with CSRF cookie but without X-CSRF-Token header returns 403."""
    from datetime import UTC, datetime

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)

    mock_session = MagicMock()
    mock_session.id = 42
    mock_session.user_id = 1

    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = mock_user

    mock_result_session = MagicMock()
    mock_result_session.scalar_one_or_none.return_value = mock_session

    mock_db_session.execute.side_effect = [mock_result_user, mock_result_session]

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/test/protected",
            cookies={
                "pm_access_token": token,
                "pm_csrf_token": "csrf-value",
            },
        )

    assert response.status_code == 403
    assert "CSRF" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_csrf_mismatch_returns_403(test_user, mock_db_session, test_app):
    """POST with mismatched CSRF cookie and header returns 403."""
    from datetime import UTC, datetime

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)

    mock_session = MagicMock()
    mock_session.id = 42
    mock_session.user_id = 1

    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = mock_user

    mock_result_session = MagicMock()
    mock_result_session.scalar_one_or_none.return_value = mock_session

    mock_db_session.execute.side_effect = [mock_result_user, mock_result_session]

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/test/protected",
            cookies={
                "pm_access_token": token,
                "pm_csrf_token": "csrf-cookie-value",
            },
            headers={
                "X-CSRF-Token": "different-csrf-value",
            },
        )

    assert response.status_code == 403
    assert "CSRF" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_csrf_valid_returns_200(test_user, mock_db_session, test_app):
    """POST with valid CSRF cookie and matching header returns 200."""
    from datetime import UTC, datetime

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.role = "user"
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)

    mock_session = MagicMock()
    mock_session.id = 42
    mock_session.user_id = 1

    mock_result_user = MagicMock()
    mock_result_user.scalar_one_or_none.return_value = mock_user

    mock_result_session = MagicMock()
    mock_result_session.scalar_one_or_none.return_value = mock_session

    mock_db_session.execute.side_effect = [mock_result_user, mock_result_session]

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/test/protected",
            cookies={
                "pm_access_token": token,
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
        )

    assert response.status_code == 200
    assert response.json()["user_id"] == 1
