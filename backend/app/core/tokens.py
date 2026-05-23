"""JWT token creation and decoding, refresh token and CSRF helpers."""
from __future__ import annotations

import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from typing import Any

from jose import JWTError, jwt

from app.config import settings

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60  # Backward compat default for legacy callers
SECRET_KEY = settings.jwt_secret_key


# ── Legacy helpers ──────────────────────────────────────────────────────────
# Kept for existing callers (auth router, wechat router) that pass raw dicts.
# New code should use create_access_token_sid() for typed access tokens.


def create_access_token(
    data: dict[str, Any],
    expires_delta: timedelta | None = None,
) -> str:
    """Create a JWT access token from a raw dict payload.

    Legacy helper for existing callers. New code should prefer
    :func:`create_access_token_sid` for typed access tokens.
    """
    to_encode = data.copy()
    expire = datetime.now(UTC) + (
        expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict[str, Any] | None:
    """Decode and validate a JWT access token. Returns ``None`` if invalid/expired."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None


# ── New standard JWT helpers ────────────────────────────────────────────────


def create_access_token_sid(user_id: int, username: str, session_id: int) -> str:
    """Create a standard JWT access token with typed claims.

    Payload includes:
    - ``sub``      — user ID as string
    - ``username`` — username
    - ``sid``      — session ID
    - ``typ``      — ``"access"``
    - ``exp``      — expiration (default: ``access_token_expire_minutes`` from config)

    Use this in new code. Existing callers still use :func:`create_access_token`.
    """
    expire = datetime.now(UTC) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    payload: dict[str, Any] = {
        "sub": str(user_id),
        "username": username,
        "sid": session_id,
        "typ": "access",
        "exp": expire,
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token_strict(token: str) -> dict[str, Any] | None:
    """Strictly decode and validate an access token.

    Rejects tokens that are:
    - Expired or malformed (standard JWT validation)
    - Missing ``typ`` claim or ``typ != "access"``
    - Missing ``sub`` claim
    - Missing ``sid`` claim

    Returns the decoded payload dict on success, ``None`` on failure.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        return None

    if payload.get("typ") != "access":
        return None
    if payload.get("sub") is None:
        return None
    if payload.get("sid") is None:
        return None

    return payload


# ── Opaque refresh token helpers ────────────────────────────────────────────


def create_refresh_token() -> str:
    """Create a cryptographically random opaque refresh token.

    Uses ``secrets.token_urlsafe(48)`` which produces a 64-character string.
    The raw value is hashed before storage (see :func:`hash_token`).
    """
    return secrets.token_urlsafe(48)


def hash_token(token: str) -> str:
    """Hash a token using SHA-256 for secure storage.

    Returns a 64-character hex digest. Deterministic — same input always
    produces the same output (so lookups work).
    """
    return hashlib.sha256(token.encode()).hexdigest()


# ── CSRF helper ─────────────────────────────────────────────────────────────


def create_csrf_token() -> str:
    """Create a cryptographically random CSRF token.

    Uses ``secrets.token_urlsafe(32)`` which produces a 43-character string.
    """
    return secrets.token_urlsafe(32)
