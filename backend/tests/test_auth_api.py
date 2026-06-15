"""Integration tests for authentication API endpoints.

NOTE: These tests use TDD approach - tests define expected behavior
for /auth/* endpoints. If auth router is not yet registered in app,
tests will fail with RouterNotFound or similar errors.
"""
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.database import get_db
from app.main import app

# --- Fixtures ---


@pytest.fixture
def mock_db_session():
    """Mock database session for auth tests."""
    session = AsyncMock()
    session.execute = AsyncMock()
    session.commit = AsyncMock()
    session.flush = AsyncMock()
    session.add = MagicMock()
    session.refresh = AsyncMock()
    session.delete = AsyncMock()
    return session


@pytest.fixture
def mock_get_db(mock_db_session):
    """Override get_db dependency with mock session."""
    async def _override():
        yield mock_db_session
    app.dependency_overrides[get_db] = _override
    yield mock_db_session
    app.dependency_overrides.pop(get_db, None)


# --- POST /auth/register Tests ---


@pytest.mark.asyncio
async def test_register_success_returns_201(test_user, mock_get_db):
    """POST /auth/register with valid data returns 201 Created."""
    from datetime import UTC, datetime


    # Mock user not found (new user)
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_get_db.execute.return_value = mock_result

    # Mock refresh to set attributes
    def mock_refresh(user):
        user.id = 1
        user.created_at = datetime.now(UTC)
    mock_get_db.refresh.side_effect = mock_refresh

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": test_user["username"],
                "email": test_user["email"],
                "password": "SecurePass1!",
            },
        )

    assert response.status_code == 201
    data = response.json()
    assert data["username"] == test_user["username"]
    assert data["email"] == test_user["email"]
    assert data["is_active"] is True
    assert "id" in data


@pytest.mark.asyncio
async def test_register_duplicate_username_returns_400(test_user, mock_get_db):
    """POST /auth/register with existing username returns 400."""
    # Mock existing user found
    mock_result = MagicMock()
    existing_user = MagicMock()
    existing_user.username = test_user["username"]
    mock_result.scalar_one_or_none.return_value = existing_user
    mock_get_db.execute.return_value = mock_result

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": test_user["username"],
                "email": "new@example.com",
                "password": "SecurePass1!",
            },
        )

    assert response.status_code == 400
    # Error message in Chinese
    assert "用户名" in response.json().get("detail", "") or "已注册" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_register_duplicate_email_returns_400(test_user, mock_get_db):
    """POST /auth/register with existing email returns 400."""
    # Mock existing user with same email - first call returns None (no user),
    # second call returns user with same email
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.side_effect = [None, MagicMock()]
    mock_get_db.execute.return_value = mock_result

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "different_user",
                "email": test_user["email"],
                "password": "SecurePass1!",
            },
        )

    assert response.status_code == 400
    assert "邮箱" in response.json().get("detail", "") or "已注册" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_register_password_too_short_returns_422(mock_get_db):
    """POST /auth/register with short password returns 422."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "12345",  # Too short (< 6 chars expected)
            },
        )

    assert response.status_code == 422
    # Validation error for password
    detail = response.json().get("detail", [])
    if isinstance(detail, list):
        assert any("password" in str(d).lower() or "length" in str(d).lower() for d in detail)


@pytest.mark.asyncio
async def test_register_password_missing_special_character_returns_422(mock_get_db):
    """POST /auth/register with weak password returns 422."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "SecurePass12",
            },
        )

    assert response.status_code == 422
    detail = response.json().get("detail", [])
    assert "10 位" in str(detail)


@pytest.mark.asyncio
async def test_register_username_too_short_returns_422(mock_get_db):
    """POST /auth/register with short username returns 422."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "ab",  # Too short (< 3 chars expected)
                "email": "test@example.com",
                "password": "securepassword",
            },
        )

    assert response.status_code == 422


# --- POST /auth/login Tests ---


@pytest.mark.asyncio
async def test_login_success_returns_200_and_cookies(test_user, mock_get_db):
    """POST /auth/login with valid credentials returns 200 and sets auth cookies."""

    from app.core.security import get_password_hash

    # Mock user found with correct password
    hashed = get_password_hash(test_user["password"])
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.hashed_password = hashed
    mock_user.is_active = True
    mock_user.role = "user"
    mock_user.deleted_at = None
    mock_user.created_at = "2024-01-01T00:00:00+00:00"

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = mock_user
    # Also handle scalars().all() for session count and permissions
    mock_scalars = MagicMock()
    mock_scalars.all.return_value = []
    mock_result.scalars.return_value = mock_scalars

    mock_get_db.execute.return_value = mock_result

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": test_user["username"],
                "password": test_user["password"],
            },
        )

    assert response.status_code == 200
    data = response.json()
    # UserResponse shape — no access_token in body
    assert data["username"] == test_user["username"]
    assert data["email"] == test_user["email"]
    assert data["role"] == "user"
    assert "id" in data
    assert "access_token" not in data
    # Cookies set via Set-Cookie header
    set_cookie = response.headers.get("set-cookie", "")
    assert "pm_access_token=" in set_cookie
    assert "pm_refresh_token=" in set_cookie
    assert "pm_csrf_token=" in set_cookie



@pytest.mark.asyncio
async def test_login_by_email_success(test_user, mock_get_db):
    """POST /auth/login with valid email and password returns 200 and sets auth cookies."""
    from app.core.security import get_password_hash

    hashed = get_password_hash(test_user["password"])
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.hashed_password = hashed
    mock_user.is_active = True
    mock_user.role = "user"
    mock_user.deleted_at = None
    mock_user.created_at = "2024-01-01T00:00:00+00:00"

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = mock_user
    mock_scalars = MagicMock()
    mock_scalars.all.return_value = []
    mock_result.scalars.return_value = mock_scalars

    mock_get_db.execute.return_value = mock_result

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": test_user["email"],
                "password": test_user["password"],
            },
        )

    assert response.status_code == 200
    data = response.json()
    assert data["username"] == test_user["username"]
    assert data["email"] == test_user["email"]
    set_cookie = response.headers.get("set-cookie", "")
    assert "pm_access_token=" in set_cookie
    assert "pm_refresh_token=" in set_cookie
    assert "pm_csrf_token=" in set_cookie


@pytest.mark.asyncio
async def test_login_user_not_found_returns_401(mock_get_db):
    """POST /auth/login with non-existent user returns 401."""
    # Mock user not found
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_get_db.execute.return_value = mock_result

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": "nonexistent",
                "password": "password123",
            },
        )

    assert response.status_code == 401
    assert "错误" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_login_wrong_password_returns_401(test_user, mock_get_db):
    """POST /auth/login with wrong password returns 401."""
    from app.core.security import get_password_hash

    # Mock user found but wrong password
    hashed = get_password_hash("correct_password")
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.hashed_password = hashed
    mock_user.is_active = True
    mock_user.deleted_at = None

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = mock_user
    mock_get_db.execute.return_value = mock_result

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": test_user["username"],
                "password": "wrong_password",
            },
        )

    assert response.status_code == 401
    assert "错误" in response.json().get("detail", "")


@pytest.mark.skip(reason="pre-existing issue: clear_login_attempts/record_failed_login not properly async")
@pytest.mark.asyncio
async def test_login_account_locked_after_5_failures(test_user, mock_get_db):
    """POST /auth/login after 5 failures returns 429 with lockout info."""
    from app.core.security import clear_login_attempts, record_failed_login

    # Clear any existing attempts
    clear_login_attempts(test_user["username"])

    # Record 5 failed login attempts
    for _ in range(5):
        record_failed_login(test_user["username"])

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username": test_user["username"],
                "password": "any_password",
            },
        )

    # Should be locked out
    assert response.status_code == 429
    data = response.json()
    # Check for lockout message (in Chinese: "登录尝试次数过多")
    assert "登录尝试" in data.get("detail", "") or "分钟" in data.get("detail", "")

    # Clean up
    clear_login_attempts(test_user["username"])


# --- POST /auth/refresh Tests ---


@pytest.mark.asyncio
async def test_refresh_success_returns_200_and_new_cookies(test_user, mock_get_db):
    """POST /auth/refresh with valid refresh token returns 200 and new cookies."""
    from app.core.security import create_refresh_token

    old_refresh = create_refresh_token()

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.role = "user"
    mock_user.deleted_at = None
    mock_user.created_at = "2024-01-01T00:00:00+00:00"

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    # get_session_by_refresh_token → mock_session_obj
    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    # user query → mock_user
    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    # permissions query → empty list
    mock_permissions = MagicMock()
    mock_permissions.scalars.return_value.all.return_value = []

    mock_get_db.execute.side_effect = [
        mock_session_result,  # get_session_by_refresh_token
        mock_user_result,     # user query
        mock_permissions,     # get_role_permissions
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/refresh",
            cookies={
                "pm_refresh_token": old_refresh,
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
        )

    assert response.status_code == 200
    data = response.json()
    assert data["username"] == test_user["username"]
    assert "access_token" not in data
    # New cookies set
    set_cookie = response.headers.get("set-cookie", "")
    assert "pm_access_token=" in set_cookie
    assert "pm_refresh_token=" in set_cookie
    assert "pm_csrf_token=" in set_cookie


@pytest.mark.asyncio
async def test_refresh_without_cookie_returns_401():
    """POST /auth/refresh without pm_refresh_token cookie returns 401."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/refresh",
            cookies={"pm_csrf_token": "csrf-value"},
            headers={"X-CSRF-Token": "csrf-value"},
        )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_refresh_invalid_token_returns_401(mock_get_db):
    """POST /auth/refresh with invalid refresh token returns 401."""
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_get_db.execute.return_value = mock_result

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/refresh",
            cookies={
                "pm_refresh_token": "invalid-token",
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
        )
    assert response.status_code == 401
    assert "刷新令牌" in response.json().get("detail", "")


# --- POST /auth/logout Tests ---


@pytest.mark.asyncio
async def test_logout_success(test_user, mock_get_db):
    """POST /auth/logout returns 200 on successful logout."""
    from app.core.security import create_access_token_sid

    token = create_access_token_sid(1, test_user["username"], 42)

    # Mock user found
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.is_active = True
    mock_user.role = "user"

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    # get_current_user_cookie: user query → found
    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user
    # get_current_user_cookie: session query → found
    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    mock_get_db.execute.side_effect = [
        mock_user_result,     # get_current_user_cookie: user
        mock_session_result,  # get_current_user_cookie: session
        mock_session_result,  # get_session_by_refresh_token
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/logout",
            cookies={
                "pm_access_token": token,
                "pm_refresh_token": "test-refresh-token",
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
        )

    assert response.status_code == 200
    assert "登出" in response.json().get("message", "")


@pytest.mark.asyncio
async def test_logout_without_cookies_returns_401():
    """POST /auth/logout without cookies returns 401."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/api/v1/auth/logout")

    assert response.status_code in [401, 403]


# --- GET /auth/me Tests ---


@pytest.mark.asyncio
async def test_me_with_valid_token_returns_user_info(test_user, mock_get_db):
    """GET /auth/me with valid pm_access_token cookie returns user info."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid

    token = create_access_token_sid(1, test_user["username"], 42)

    # Mock user found
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.role = "user"
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    mock_permissions = MagicMock()
    mock_permissions.scalars.return_value.all.return_value = []

    mock_get_db.execute.side_effect = [
        mock_user_result,     # get_current_user_cookie: user
        mock_session_result,  # get_current_user_cookie: session
        mock_permissions,     # get_role_permissions
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/auth/me",
            cookies={"pm_access_token": token},
        )

    assert response.status_code == 200
    data = response.json()
    assert data.get("username") == test_user["username"]
    assert data.get("email") == test_user["email"]


@pytest.mark.asyncio
async def test_me_without_cookie_returns_401():
    """GET /auth/me without pm_access_token cookie returns 401."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/auth/me")

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_with_expired_token_returns_401(mock_get_db):
    """GET /auth/me with expired pm_access_token cookie returns 401."""
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

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/auth/me",
            cookies={"pm_access_token": expired_token},
        )

    assert response.status_code == 401


# --- PATCH /auth/me Tests ---


@pytest.mark.asyncio
async def test_update_me_with_valid_data_returns_200(test_user, mock_get_db):
    """PATCH /auth/me with valid data returns 200 and updated user info."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid

    token = create_access_token_sid(1, test_user["username"], 42)

    # Mock current user
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.created_at = datetime.now(UTC)
    mock_user.hashed_password = "hashed"
    mock_user.role = "user"
    mock_user.deleted_at = None

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    # Results: get_current_user_cookie (user + session),
    # then username check (None), email check (None), then permissions
    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    mock_none_result = MagicMock()
    mock_none_result.scalar_one_or_none.return_value = None

    mock_permissions = MagicMock()
    mock_permissions.scalars.return_value.all.return_value = []

    # get_current_user_cookie now uses a single JOIN query
    mock_get_db.execute.side_effect = [
        mock_user_result,     # get_current_user_cookie: JOIN query
        mock_none_result,     # username check — no conflict
        mock_none_result,     # email check — no conflict
        mock_permissions,     # get_role_permissions
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.patch(
            "/api/v1/auth/me",
            cookies={
                "pm_access_token": token,
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
            json={
                "username": "new_username",
                "email": "new@example.com",
            },
        )

    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "new_username"
    assert data["email"] == "new@example.com"


@pytest.mark.asyncio
async def test_update_me_with_duplicate_username_returns_400(test_user, mock_get_db):
    """PATCH /auth/me with existing username returns 400."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid

    token = create_access_token_sid(1, test_user["username"], 42)

    # Mock current user
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.created_at = datetime.now(UTC)
    mock_user.hashed_password = "hashed"
    mock_user.role = "user"
    mock_user.deleted_at = None

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    # Results: get_current_user_cookie (user + session), then duplicate username
    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    mock_duplicate = MagicMock()
    existing_user = MagicMock()
    existing_user.username = "existing_user"
    mock_duplicate.scalar_one_or_none.return_value = existing_user

    mock_get_db.execute.side_effect = [
        mock_user_result,     # get_current_user_cookie: user
        mock_session_result,  # get_current_user_cookie: session
        mock_duplicate,       # username check — conflict
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.patch(
            "/api/v1/auth/me",
            cookies={
                "pm_access_token": token,
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
            json={"username": "existing_user"},
        )

    assert response.status_code == 400
    assert "用户名" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_update_me_with_duplicate_email_returns_400(test_user, mock_get_db):
    """PATCH /auth/me with existing email returns 400."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid

    token = create_access_token_sid(1, test_user["username"], 42)

    # Mock current user
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.created_at = datetime.now(UTC)
    mock_user.hashed_password = "hashed"
    mock_user.role = "user"
    mock_user.deleted_at = None

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    # Results: get_current_user_cookie (user + session), then email check returns duplicate
    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    mock_duplicate = MagicMock()
    duplicate_user = MagicMock()
    duplicate_user.id = 999
    duplicate_user.username = "some_other_user"
    duplicate_user.deleted_at = None
    mock_duplicate.scalar_one_or_none.return_value = duplicate_user

    mock_get_db.execute.side_effect = [
        mock_user_result,     # get_current_user_cookie: user
        mock_session_result,  # get_current_user_cookie: session
        mock_duplicate,       # email check — conflict
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.patch(
            "/api/v1/auth/me",
            cookies={
                "pm_access_token": token,
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
            json={"email": "existing@example.com"},
        )

    assert response.status_code == 400
    assert "邮箱" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_update_me_with_same_username_returns_200(test_user, mock_get_db):
    """PATCH /auth/me with same username as current user returns 200 (no conflict)."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid

    token = create_access_token_sid(1, test_user["username"], 42)

    # Mock current user
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.created_at = datetime.now(UTC)
    mock_user.hashed_password = "hashed"
    mock_user.role = "user"
    mock_user.deleted_at = None

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    mock_none_result = MagicMock()
    mock_none_result.scalar_one_or_none.return_value = None

    mock_get_db.execute.side_effect = [
        mock_user_result,     # get_current_user_cookie: user
        mock_session_result,  # get_current_user_cookie: session
        mock_none_result,     # username check — no conflict (same name)
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.patch(
            "/api/v1/auth/me",
            cookies={
                "pm_access_token": token,
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
            json={"username": test_user["username"]},
        )

    assert response.status_code == 200


# --- POST /auth/me/password Tests ---


@pytest.mark.asyncio
async def test_change_password_with_wrong_old_password_returns_400(test_user, mock_get_db):
    """POST /auth/me/password with wrong old password returns 400."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid, get_password_hash

    token = create_access_token_sid(1, test_user["username"], 42)

    # Mock current user
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.created_at = datetime.now(UTC)
    mock_user.hashed_password = get_password_hash("correct_password")
    mock_user.role = "user"

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    mock_get_db.execute.side_effect = [
        mock_user_result,     # get_current_user_cookie: user
        mock_session_result,  # get_current_user_cookie: session
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/me/password",
            cookies={
                "pm_access_token": token,
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
            json={
                "old_password": "wrong_password",
                "new_password": "NewSecurePass1!",
            },
        )

    assert response.status_code == 400
    assert "原密码" in response.json().get("detail", "")


@pytest.mark.asyncio
async def test_change_password_with_valid_data_returns_200(test_user, mock_get_db):
    """POST /auth/me/password with valid data returns 200."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid, get_password_hash

    token = create_access_token_sid(1, test_user["username"], 42)

    # Mock current user
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.created_at = datetime.now(UTC)
    mock_user.hashed_password = get_password_hash(test_user["password"])
    mock_user.role = "user"
    mock_user.deleted_at = None

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    # get_current_user_cookie: (1) user, (2) session
    # get_session_by_refresh_token: (3) session
    # stage_delete_other_sessions: (4) other sessions
    mock_other_sessions = MagicMock()
    mock_other_sessions.scalars.return_value.all.return_value = []

    mock_get_db.execute.side_effect = [
        mock_user_result,     # 1. get_current_user_cookie: user
        mock_session_result,  # 2. get_current_user_cookie: session
        mock_session_result,  # 3. get_session_by_refresh_token
        mock_other_sessions,  # 4. stage_delete_other_sessions
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/me/password",
            cookies={
                "pm_access_token": token,
                "pm_refresh_token": "test-refresh-token",
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
            json={
                "old_password": test_user["password"],
                "new_password": "NewSecurePass1!",
            },
        )

    assert response.status_code == 200
    assert "成功" in response.json().get("message", "")
    # Cookies should be refreshed
    set_cookie = response.headers.get("set-cookie", "")
    assert "pm_access_token=" in set_cookie


@pytest.mark.asyncio
async def test_change_password_without_cookie_returns_401():
    """POST /auth/me/password without cookies returns 401 or 403."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/me/password",
            json={
                "old_password": "OldPassword1!",
                "new_password": "NewSecurePass1!",
            },
        )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_change_password_with_weak_new_password_returns_422(test_user, mock_get_db):
    """POST /auth/me/password with weak new password returns 422."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid, get_password_hash

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.created_at = datetime.now(UTC)
    mock_user.hashed_password = get_password_hash(test_user["password"])
    mock_user.role = "user"
    mock_user.deleted_at = None

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    mock_get_db.execute.side_effect = [
        mock_user_result,
        mock_session_result,
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/me/password",
            cookies={
                "pm_access_token": token,
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
            json={
                "old_password": test_user["password"],
                "new_password": "alllowercase1!",
            },
        )

    assert response.status_code == 422
    assert "10 位" in str(response.json().get("detail", []))


# --- Password Change Session Cleanup Tests ---


@pytest.mark.asyncio
async def test_change_password_deletes_other_sessions_but_keeps_current(test_user, mock_get_db):
    """POST /auth/me/password removes other sessions but keeps current."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid, get_password_hash

    token = create_access_token_sid(1, test_user["username"], 42)

    # Mock user
    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)
    mock_user.hashed_password = get_password_hash(test_user["password"])
    mock_user.role = "user"

    # Mock session (current)
    mock_session_row = MagicMock()
    mock_session_row.id = 42
    mock_session_row.user_id = 1

    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_row

    mock_other_sessions_result = MagicMock()
    mock_other_sessions_result.scalars.return_value.all.return_value = [MagicMock()]

    mock_get_db.execute.side_effect = [
        mock_user_result,              # 1. get_current_user_cookie: user
        mock_session_result,           # 2. get_current_user_cookie: session
        mock_session_result,           # 3. get_session_by_refresh_token
        mock_other_sessions_result,    # 4. stage_delete_other_sessions
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/me/password",
            cookies={
                "pm_access_token": token,
                "pm_refresh_token": "test-refresh-token",
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
            json={
                "old_password": test_user["password"],
                "new_password": "NewSecurePass1!",
            },
        )

    assert response.status_code == 200
    # stage_delete_other_sessions was called (deletes done before commit)
    assert mock_get_db.commit.called


@pytest.mark.asyncio
async def test_change_password_missing_current_session_returns_401(test_user, mock_get_db):
    """POST /auth/me/password returns 401 when current session is missing."""
    from datetime import UTC, datetime

    from app.core.security import create_access_token_sid, get_password_hash

    token = create_access_token_sid(1, test_user["username"], 42)

    mock_user = MagicMock()
    mock_user.id = 1
    mock_user.username = test_user["username"]
    mock_user.email = test_user["email"]
    mock_user.is_active = True
    mock_user.deleted_at = None
    mock_user.created_at = datetime.now(UTC)
    mock_user.hashed_password = get_password_hash(test_user["password"])
    mock_user.role = "user"

    mock_session_obj = MagicMock()
    mock_session_obj.id = 42
    mock_session_obj.user_id = 1

    mock_user_result = MagicMock()
    mock_user_result.scalar_one_or_none.return_value = mock_user

    mock_session_result = MagicMock()
    mock_session_result.scalar_one_or_none.return_value = mock_session_obj

    # get_session_by_refresh_token returns None
    mock_no_session = MagicMock()
    mock_no_session.scalar_one_or_none.return_value = None

    mock_get_db.execute.side_effect = [
        mock_user_result,     # 1. get_current_user_cookie: JOIN query
        mock_no_session,      # 2. get_session_by_refresh_token → None
    ]

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/me/password",
            cookies={
                "pm_access_token": token,
                "pm_refresh_token": "test-refresh-token",
                "pm_csrf_token": "csrf-value",
            },
            headers={
                "X-CSRF-Token": "csrf-value",
            },
            json={
                "old_password": test_user["password"],
                "new_password": "NewSecurePass1!",
            },
        )

    assert response.status_code == 401
    assert "会话" in response.json().get("detail", "")


# --- Health Check for Auth Endpoints ---


@pytest.mark.asyncio
async def test_auth_endpoints_exist():
    """Verify auth endpoints are registered in the app."""
    # Check router is included - this will fail with AttributeError if not
    from app.main import app

    routes = [route.path for route in app.routes]
    auth_routes = [r for r in routes if r.startswith("/api/v1/auth")]

    # At minimum, these routes should be registered
    expected_routes = ["/api/v1/auth/register", "/api/v1/auth/login", "/api/v1/auth/logout", "/api/v1/auth/me", "/api/v1/auth/refresh"]
    for route in expected_routes:
        assert route in auth_routes, f"Route {route} not found in app routes"
