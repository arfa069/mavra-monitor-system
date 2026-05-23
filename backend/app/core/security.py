"""Security utilities: auth dependencies and compatibility re-exports.

Modules have been split into:
  - passwords.py: bcrypt-sha256 hashing
  - tokens.py: JWT create/decode
  - login_lockout.py: Redis-backed login attempts
  - sessions.py: DB session management + transaction-aware variants
  - security.py: FastAPI auth dependencies + compatibility re-exports
"""
from __future__ import annotations

import hashlib
import logging
from typing import TYPE_CHECKING

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.login_lockout import (  # noqa: F401  # re-exported for compatibility
    LOCKOUT_DURATION_SECONDS,
    MAX_LOGIN_ATTEMPTS,
    clear_login_attempts,
    is_account_locked,
    record_failed_login,
)

# ── Re-exported from split modules ────────────────────────
from app.core.passwords import (  # noqa: F401  # re-exported for compatibility
    PASSWORD_HASH_PREFIX,
    get_password_hash,
    verify_password,
)
from app.core.sessions import (  # noqa: F401  # re-exported for compatibility
    create_session,
    create_session_with_token,
    delete_other_sessions,
    delete_session,
    get_session_by_id,
    get_session_by_refresh_token,
    get_session_by_token,
    get_user_sessions,
    rotate_session_refresh_token,
    stage_delete_other_sessions,
    stage_delete_user_sessions,
)
from app.core.tokens import (  # noqa: F401  # re-exported for compatibility
    ACCESS_TOKEN_EXPIRE_MINUTES,
    ALGORITHM,
    SECRET_KEY,
    create_access_token,
    create_access_token_sid,
    create_csrf_token,
    create_refresh_token,
    decode_access_token,
    decode_access_token_strict,
    hash_token,
)
from app.database import get_db

if TYPE_CHECKING:
    from app.models.user import User

logger = logging.getLogger(__name__)

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Dependency to get current authenticated user from JWT token.

    Validates the token AND checks that:
      - The user exists and is not soft-deleted (deleted_at IS NULL)
      - A corresponding session exists in users_sessions
    Does NOT check is_active (API compatibility field only).
    """
    from app.models.user import User

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="认证失败：Token 无效或已过期",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception

    user_id = payload.get("sub")
    if user_id is None:
        raise credentials_exception

    # Convert sub to int; malformed subjects get 401, not 500
    try:
        user_id_int = int(user_id)
    except (ValueError, TypeError):
        raise credentials_exception

    result = await db.execute(
        select(User).where(
            User.id == user_id_int,
            User.deleted_at.is_(None),
        )
    )
    user = result.scalar_one_or_none()

    if user is None:
        raise credentials_exception

    # ── Session validation ──────────────────────────────────
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    from app.models.session import Session

    session_result = await db.execute(
        select(Session).where(
            Session.user_id == user.id,
            Session.token_hash == token_hash,
        )
    )
    active_session = session_result.scalar_one_or_none()
    if active_session is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：会话已失效或已在其他地方退出",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user


async def get_current_user_cookie(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> User:
    """Dependency: authenticate via ``pm_access_token`` cookie.

    Reads the access token from the ``pm_access_token`` cookie, validates
    it with :func:`decode_access_token_strict` (which enforces ``typ``,
    ``sub``, and ``sid`` claims), then verifies that:

    - The ``users`` record exists and is not soft-deleted.
    - A ``users_sessions`` row matching ``sid`` and ``user_id`` exists.

    Returns 401 for:
    - Missing cookie.
    - Invalid / expired token.
    - Wrong token type (missing ``typ="access"``).
    - Malformed ``sub`` (user_id) claim.
    - Malformed ``sid`` (session_id) claim.
    - Deleted or non-existent user.
    - Missing / deleted session.
    """
    from app.models.user import User

    cookie_name = settings.auth_access_cookie_name
    token = request.cookies.get(cookie_name)

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：未提供登录凭证",
        )

    payload = decode_access_token_strict(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：Token 无效或已过期",
        )

    # ── Validate sub (user_id) ──────────────────────────────────────
    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：Token 无效或已过期",
        )
    try:
        user_id_int = int(user_id)
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：Token 无效或已过期",
        )

    # ── Validate sid (session_id) ───────────────────────────────────
    sid = payload.get("sid")
    if sid is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：Token 无效或已过期",
        )
    try:
        sid_int = int(sid)
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：Token 无效或已过期",
        )

    # ── Look up user (exclude soft-deleted) ─────────────────────────
    result = await db.execute(
        select(User).where(
            User.id == user_id_int,
            User.deleted_at.is_(None),
        )
    )
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：用户不存在或已被删除",
        )

    # ── Look up session by sid ──────────────────────────────────────
    session = await get_session_by_id(sid_int, user_id_int, db)
    if session is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：会话已失效或已在其他地方退出",
        )

    return user


SAFE_METHODS = frozenset({"GET", "HEAD", "OPTIONS"})


async def csrf_protect(request: Request) -> None:
    """CSRF protection dependency.

    Compares the ``pm_csrf_token`` cookie with the ``X-CSRF-Token``
    request header.  Validation is **skipped** for safe HTTP methods
    (GET, HEAD, OPTIONS).

    Returns 403 when:
    - The CSRF cookie is missing.
    - The CSRF header is missing.
    - The cookie and header values do not match.
    """
    if request.method in SAFE_METHODS:
        return

    csrf_cookie = request.cookies.get(settings.auth_csrf_cookie_name)
    csrf_header = request.headers.get(settings.auth_csrf_header_name)

    if not csrf_cookie or not csrf_header or csrf_cookie != csrf_header:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="CSRF 验证失败：请求被拒绝",
        )


def parse_device(user_agent: str) -> str:
    """Parse browser and OS from User-Agent string."""
    if not user_agent:
        return "Unknown"
    return user_agent[:200]


def require_role(*allowed_roles: str):
    """Require specific roles for an endpoint.

    Usage:
        @router.get("/admin", dependencies=[Depends(require_role("admin", "super_admin"))])
    """
    async def role_checker(current_user: User = Depends(get_current_user)):
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="需要管理员权限",
            )
        return current_user
    return role_checker
