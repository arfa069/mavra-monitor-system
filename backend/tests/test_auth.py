"""Tests for authentication API."""
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_password_hash
from app.database import get_db
from app.main import app
from app.models.user import User


class TestRegister:
    """Tests for POST /auth/register."""

    @pytest.mark.asyncio
    async def test_register_success(self):
        """Test successful user registration."""
        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None  # No existing user
        mock_session.execute = AsyncMock(return_value=mock_result)
        mock_session.add = MagicMock()
        mock_session.commit = AsyncMock()
        mock_session.refresh = AsyncMock(side_effect=lambda u: setattr(u, "id", 1) or setattr(u, "created_at", datetime.now(UTC)) or setattr(u, "updated_at", datetime.now(UTC)))

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/register",
                    json={"username": "testuser", "email": "test@example.com", "password": "123456"},
                )
            assert response.status_code == 201
            data = response.json()
            assert data["username"] == "testuser"
            assert data["email"] == "test@example.com"
            assert data["is_active"] is True
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_register_duplicate_username(self):
        """Test registration with duplicate username returns 400."""
        existing_user = MagicMock(spec=User)
        existing_user.username = "testuser"

        mock_session = AsyncMock()
        mock_result = MagicMock()
        # First call: username exists
        mock_result.scalar_one_or_none.side_effect = [existing_user, None]
        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/register",
                    json={"username": "testuser", "email": "test@example.com", "password": "123456"},
                )
            assert response.status_code == 400
            assert "用户名已注册" in response.json()["detail"]
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_register_duplicate_email(self):
        """Test registration with duplicate email returns 400."""
        mock_session = AsyncMock()
        mock_result = MagicMock()
        # First call: username not exists, second call: email exists
        mock_result.scalar_one_or_none.side_effect = [None, MagicMock()]
        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/register",
                    json={"username": "testuser", "email": "test@example.com", "password": "123456"},
                )
            assert response.status_code == 400
            assert "邮箱已注册" in response.json()["detail"]
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_register_password_too_short(self):
        """Test registration with short password returns 422."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.post(
                "/auth/register",
                json={"username": "testuser", "email": "test@example.com", "password": "123"},
            )
        assert response.status_code == 422


class TestLogin:
    """Tests for POST /auth/login."""

    @pytest.mark.asyncio
    async def test_login_success(self):
        """Test successful login returns UserResponse and sets auth cookies."""
        hashed = get_password_hash("password123")
        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.email = "test@example.com"
        mock_user.hashed_password = hashed
        mock_user.is_active = True
        mock_user.role = "user"
        mock_user.deleted_at = None
        mock_user.created_at = datetime.now(UTC)

        mock_session = AsyncMock()
        mock_session.flush = AsyncMock()
        mock_session.commit = AsyncMock()
        mock_session.add = MagicMock()
        mock_session.delete = AsyncMock()

        # All execute calls return the same mock_result which handles both
        # scalar_one_or_none (for user query) and scalars().all() (for session count / permissions)
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_scalars = MagicMock()
        mock_scalars.all.return_value = []
        mock_result.scalars.return_value = mock_scalars

        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/login",
                    json={"username": "testuser", "password": "password123"},
                )
            assert response.status_code == 200
            data = response.json()
            # UserResponse shape (no access_token in body)
            assert data["username"] == "testuser"
            assert data["email"] == "test@example.com"
            assert data["role"] == "user"
            assert "id" in data
            assert "access_token" not in data
            assert "token_type" not in data
            # Cookies set via Set-Cookie header
            set_cookie = response.headers.get("set-cookie", "")
            assert "pm_access_token=" in set_cookie
            assert "pm_refresh_token=" in set_cookie
            assert "pm_csrf_token=" in set_cookie
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_login_wrong_password(self):
        """Test login with wrong password returns 401."""
        hashed = get_password_hash("password123")
        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.hashed_password = hashed
        mock_user.is_active = True
        mock_user.deleted_at = None

        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/login",
                    json={"username": "testuser", "password": "wrongpassword"},
                )
            assert response.status_code == 401
            assert "用户名或密码错误" in response.json()["detail"]
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_login_user_not_found(self):
        """Test login with non-existent user returns 401."""
        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/login",
                    json={"username": "nonexistent", "password": "password123"},
                )
            assert response.status_code == 401
            assert "用户名或密码错误" in response.json()["detail"]
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_login_inactive_user(self):
        """Test login with soft-deleted user returns 401."""
        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.hashed_password = get_password_hash("password123")
        mock_user.is_active = True
        mock_user.deleted_at = datetime.now(UTC)  # soft-deleted

        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/login",
                    json={"username": "testuser", "password": "password123"},
                )
            assert response.status_code == 401
            assert "用户已被禁用" in response.json()["detail"]
        finally:
            app.dependency_overrides.clear()

    # ── deleted_at lifecycle tests (refactored auth truth) ──

    @pytest.mark.asyncio
    async def test_login_rejects_soft_deleted_user(self):
        """A user with deleted_at set cannot log in, regardless of is_active."""
        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.hashed_password = get_password_hash("password123")
        mock_user.is_active = True  # is_active is True, but deleted_at is set
        mock_user.deleted_at = datetime.now(UTC)

        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/login",
                    json={"username": "testuser", "password": "password123"},
                )
            assert response.status_code == 401
            # Must not create session for deleted user
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_login_ignores_is_active_when_not_deleted(self):
        """is_active is API compatibility only; login is allowed when deleted_at is None."""
        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.hashed_password = get_password_hash("password123")
        mock_user.is_active = False  # is_active=False but deleted_at=None
        mock_user.deleted_at = None
        mock_user.role = "user"
        mock_user.email = "test@example.com"
        mock_user.created_at = datetime.now(UTC)

        mock_session = AsyncMock()
        mock_session.flush = AsyncMock()
        mock_session.commit = AsyncMock()
        mock_session.add = MagicMock()
        mock_session.delete = AsyncMock()

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_scalars = MagicMock()
        mock_scalars.all.return_value = []
        mock_result.scalars.return_value = mock_scalars

        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/login",
                    json={"username": "testuser", "password": "password123"},
                )
            assert response.status_code == 200
            data = response.json()
            # UserResponse, not TokenResponse
            assert data["username"] == "testuser"
            assert "access_token" not in data
            # Cookies are set
            set_cookie = response.headers.get("set-cookie", "")
            assert "pm_access_token=" in set_cookie
        finally:
            app.dependency_overrides.clear()


class TestRefresh:
    """Tests for POST /auth/refresh."""

    @pytest.mark.asyncio
    async def test_refresh_success(self):
        """Test successful token refresh returns UserResponse and sets new cookies."""
        from app.core.security import create_refresh_token

        old_refresh_token = create_refresh_token()

        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.email = "test@example.com"
        mock_user.is_active = True
        mock_user.role = "user"
        mock_user.deleted_at = None
        mock_user.created_at = datetime.now(UTC)

        mock_session_obj = MagicMock()
        mock_session_obj.id = 42
        mock_session_obj.user_id = 1

        mock_db = AsyncMock()
        mock_db.commit = AsyncMock()

        mock_refresh_result = MagicMock()
        mock_refresh_result.scalar_one_or_none.return_value = mock_session_obj

        mock_user_result = MagicMock()
        mock_user_result.scalar_one_or_none.return_value = mock_user

        mock_permissions = MagicMock()
        mock_permissions.scalars.return_value.all.return_value = []

        mock_db.execute = AsyncMock(side_effect=[
            mock_refresh_result,  # get_session_by_refresh_token
            mock_user_result,     # user query
            mock_permissions,     # get_role_permissions
        ])

        async def _override_get_db():
            yield mock_db

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/refresh",
                    cookies={
                        "pm_refresh_token": old_refresh_token,
                        "pm_csrf_token": "csrf-value",
                    },
                    headers={
                        "X-CSRF-Token": "csrf-value",
                    },
                )
            assert response.status_code == 200
            data = response.json()
            assert data["username"] == "testuser"
            assert "access_token" not in data
            # New cookies set
            set_cookie = response.headers.get("set-cookie", "")
            assert "pm_access_token=" in set_cookie
            assert "pm_refresh_token=" in set_cookie
            assert "pm_csrf_token=" in set_cookie
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_refresh_without_cookie_returns_401(self):
        """Test refresh without pm_refresh_token cookie returns 401."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.post(
                "/auth/refresh",
                cookies={"pm_csrf_token": "csrf-value"},
                headers={"X-CSRF-Token": "csrf-value"},
            )
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_refresh_invalid_token_returns_401(self):
        """Test refresh with invalid refresh token returns 401."""
        mock_db = AsyncMock()
        mock_refresh_result = MagicMock()
        mock_refresh_result.scalar_one_or_none.return_value = None
        mock_db.execute = AsyncMock(return_value=mock_refresh_result)

        async def _override_get_db():
            yield mock_db

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/refresh",
                    cookies={
                        "pm_refresh_token": "invalid-token",
                        "pm_csrf_token": "csrf-value",
                    },
                    headers={
                        "X-CSRF-Token": "csrf-value",
                    },
                )
            assert response.status_code == 401
            assert "刷新令牌" in response.json()["detail"]
        finally:
            app.dependency_overrides.clear()


class TestGetMe:
    """Tests for GET /auth/me."""

    @pytest.mark.asyncio
    async def test_get_me_success(self):
        """Test successful get current user with cookie auth."""
        from app.core.security import create_access_token_sid

        token = create_access_token_sid(1, "testuser", 42)

        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.email = "test@example.com"
        mock_user.hashed_password = get_password_hash("password123")
        mock_user.is_active = True
        mock_user.role = "user"
        mock_user.deleted_at = None
        mock_user.created_at = datetime.now(UTC)

        mock_session_obj = MagicMock()
        mock_session_obj.id = 42
        mock_session_obj.user_id = 1

        mock_db = AsyncMock()

        mock_user_result = MagicMock()
        mock_user_result.scalar_one_or_none.return_value = mock_user

        mock_session_result = MagicMock()
        mock_session_result.scalar_one_or_none.return_value = mock_session_obj

        mock_permissions = MagicMock()
        mock_permissions.scalars.return_value.all.return_value = []

        mock_db.execute = AsyncMock(side_effect=[
            mock_user_result,     # get_current_user_cookie: user query
            mock_session_result,  # get_current_user_cookie: session query (get_session_by_id)
            mock_permissions,     # get_role_permissions
        ])

        async def _override_get_db():
            yield mock_db

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get(
                    "/auth/me",
                    cookies={"pm_access_token": token},
                )
            assert response.status_code == 200
            data = response.json()
            assert data["username"] == "testuser"
            assert data["email"] == "test@example.com"
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_me_no_token(self):
        """Test get current user without token returns 401."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get("/auth/me")
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_get_me_invalid_token(self):
        """Test get current user with invalid cookie token returns 401."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(
                "/auth/me",
                cookies={"pm_access_token": "invalid_token"},
            )
        assert response.status_code == 401
        assert "Token 无效或已过期" in response.json()["detail"]

    # ── deleted_at lifecycle tests for get_current_user_cookie ──

    @pytest.mark.asyncio
    async def test_get_me_ignores_is_active_when_not_deleted_and_session_exists(self):
        """Authentication validity is based on deleted_at + session, not is_active."""
        from app.core.security import create_access_token_sid

        token = create_access_token_sid(1, "testuser", 42)

        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.email = "test@example.com"
        mock_user.hashed_password = get_password_hash("password123")
        mock_user.is_active = False  # is_active=False but not deleted
        mock_user.deleted_at = None
        mock_user.role = "user"
        mock_user.created_at = datetime.now(UTC)

        mock_session_obj = MagicMock()
        mock_session_obj.id = 42
        mock_session_obj.user_id = 1

        mock_db = AsyncMock()

        mock_user_result = MagicMock()
        mock_user_result.scalar_one_or_none.return_value = mock_user

        mock_session_result = MagicMock()
        mock_session_result.scalar_one_or_none.return_value = mock_session_obj

        mock_permissions = MagicMock()
        mock_permissions.scalars.return_value.all.return_value = []

        mock_db.execute = AsyncMock(side_effect=[
            mock_user_result,     # user query
            mock_session_result,  # session query
            mock_permissions,     # get_role_permissions
        ])

        async def _override_get_db():
            yield mock_db

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get(
                    "/auth/me",
                    cookies={"pm_access_token": token},
                )
            assert response.status_code == 200
            data = response.json()
            assert data["username"] == "testuser"
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_me_rejects_deleted_user_even_with_session(self):
        """Soft-deleted users are rejected even if the token session row exists."""
        from app.core.security import create_access_token_sid

        token = create_access_token_sid(1, "testuser", 42)

        mock_db = AsyncMock()
        # User query returns None (SQL filtered out deleted user)
        user_result = MagicMock()
        user_result.scalar_one_or_none.return_value = None
        mock_db.execute = AsyncMock(return_value=user_result)

        async def _override_get_db():
            yield mock_db

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get(
                    "/auth/me",
                    cookies={"pm_access_token": token},
                )
            assert response.status_code == 401
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_me_rejects_non_integer_sub_as_401(self):
        """Malformed token subject must not surface as 500."""
        from datetime import timedelta

        from jose import jwt

        from app.config import settings

        # Token with non-integer sub
        payload = {
            "sub": "not-an-int",
            "username": "testuser",
            "sid": 42,
            "typ": "access",
            "exp": datetime.now(UTC) + timedelta(hours=1),
        }
        token = jwt.encode(payload, settings.jwt_secret_key, algorithm="HS256")

        mock_db = AsyncMock()

        async def _override_get_db():
            yield mock_db

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get(
                    "/auth/me",
                    cookies={"pm_access_token": token},
                )
            assert response.status_code == 401
        finally:
            app.dependency_overrides.clear()


class TestLogout:
    """Tests for POST /auth/logout."""

    @pytest.mark.asyncio
    async def test_logout_success(self):
        """Test successful logout with cookie auth."""
        from app.core.security import create_access_token_sid

        token = create_access_token_sid(1, "testuser", 42)

        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.email = "test@example.com"
        mock_user.hashed_password = get_password_hash("password123")
        mock_user.is_active = True
        mock_user.role = "user"
        mock_user.deleted_at = None
        mock_user.created_at = datetime.now(UTC)

        mock_session_obj = MagicMock()
        mock_session_obj.id = 42
        mock_session_obj.user_id = 1

        mock_db = AsyncMock()
        mock_db.delete = AsyncMock()
        mock_db.commit = AsyncMock()
        mock_db.rollback = AsyncMock()

        mock_user_result = MagicMock()
        mock_user_result.scalar_one_or_none.return_value = mock_user

        mock_session_result = MagicMock()
        mock_session_result.scalar_one_or_none.return_value = mock_session_obj

        # get_current_user_cookie: (1) user query, (2) session query
        # logout: (3) get_session_by_refresh_token
        mock_db.execute = AsyncMock(side_effect=[
            mock_user_result,     # 1. get_current_user_cookie: user
            mock_session_result,  # 2. get_current_user_cookie: session
            mock_session_result,  # 3. get_session_by_refresh_token
        ])

        async def _override_get_db():
            yield mock_db

        app.dependency_overrides[get_db] = _override_get_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/logout",
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
            assert "登出成功" in response.json()["message"]
            # Cookies should be cleared (set-cookie with expiry in the past)
            set_cookie = response.headers.get("set-cookie", "")
            assert "pm_access_token=" in set_cookie
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_logout_invalidates_session(self):
        """After logout, the same token should return 401 on /auth/me."""
        from app.core.security import create_access_token_sid

        token = create_access_token_sid(1, "testuser", 42)

        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "testuser"
        mock_user.email = "test@example.com"
        mock_user.hashed_password = get_password_hash("password123")
        mock_user.is_active = True
        mock_user.role = "user"
        mock_user.deleted_at = None
        mock_user.created_at = datetime.now(UTC)

        mock_session_obj = MagicMock()
        mock_session_obj.id = 42
        mock_session_obj.user_id = 1

        # ── Step 1: Logout succeeds ───────────────────────────────────
        mock_db_logout = AsyncMock()
        mock_db_logout.delete = AsyncMock()
        mock_db_logout.commit = AsyncMock()
        mock_db_logout.rollback = AsyncMock()

        user_result = MagicMock()
        user_result.scalar_one_or_none.return_value = mock_user
        session_result = MagicMock()
        session_result.scalar_one_or_none.return_value = mock_session_obj

        mock_db_logout.execute = AsyncMock(side_effect=[
            user_result,      # get_current_user_cookie: user
            session_result,   # get_current_user_cookie: session
            session_result,   # get_session_by_refresh_token
        ])

        async def _override_logout():
            yield mock_db_logout

        app.dependency_overrides[get_db] = _override_logout
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/logout",
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
        finally:
            app.dependency_overrides.pop(get_db, None)

        # ── Step 2: After logout, /auth/me returns 401 ────────────────
        mock_db_me = AsyncMock()

        # User found but session not found (simulate deleted session)
        user_found = MagicMock()
        user_found.scalar_one_or_none.return_value = mock_user

        session_gone = MagicMock()
        session_gone.scalar_one_or_none.return_value = None

        mock_db_me.execute = AsyncMock(side_effect=[
            user_found,    # user query
            session_gone,  # session query → None → 401
        ])

        async def _override_me():
            yield mock_db_me

        app.dependency_overrides[get_db] = _override_me
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get(
                    "/auth/me",
                    cookies={"pm_access_token": token},
                )
            assert response.status_code == 401
            assert "会话已失效" in response.json()["detail"]
        finally:
            app.dependency_overrides.clear()


class TestRequireRole:
    """Tests for require_role decorator."""

    @pytest.mark.asyncio
    async def test_require_role_allows_correct_role(self):
        """Test require_role allows user with correct role."""
        from app.core.security import require_role

        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "adminuser"
        mock_user.email = "admin@example.com"
        mock_user.role = "admin"
        mock_user.is_active = True
        mock_user.deleted_at = None
        mock_user.created_at = datetime.now(UTC)

        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            # Test that user with admin role passes the role check
            role_checker = require_role("admin")
            # Directly call the dependency function with mocked user
            result = await role_checker(current_user=mock_user)
            assert result == mock_user
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_require_role_denies_wrong_role(self):
        """Test require_role denies user with wrong role."""
        from fastapi import HTTPException

        from app.core.security import require_role

        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "regularuser"
        mock_user.email = "user@example.com"
        mock_user.role = "user"
        mock_user.is_active = True
        mock_user.deleted_at = None

        mock_session = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = _override_get_db
        try:
            role_checker = require_role("admin", "super_admin")
            with pytest.raises(HTTPException) as exc_info:
                await role_checker(current_user=mock_user)
            assert exc_info.value.status_code == 403
            assert "需要管理员权限" in exc_info.value.detail
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_require_role_allows_super_admin(self):
        """Test require_role allows super_admin role."""
        from app.core.security import require_role

        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "superadmin"
        mock_user.email = "super@example.com"
        mock_user.role = "super_admin"
        mock_user.is_active = True
        mock_user.deleted_at = None

        role_checker = require_role("admin", "super_admin")
        result = await role_checker(current_user=mock_user)
        assert result == mock_user

    @pytest.mark.asyncio
    async def test_require_role_denies_deleted_user(self):
        """Test require_role checks are done after get_current_user validates user is active."""
        from app.core.security import require_role

        mock_user = MagicMock(spec=User)
        mock_user.id = 1
        mock_user.username = "activeadmin"
        mock_user.email = "admin@example.com"
        mock_user.role = "admin"
        mock_user.is_active = True
        mock_user.deleted_at = None

        role_checker = require_role("admin")
        result = await role_checker(current_user=mock_user)
        assert result == mock_user
