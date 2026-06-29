"""Shared auth cookie helpers for consistent cookie setting across routers.

Used by ``auth/router.py`` and ``auth/wechat_router.py`` to ensure
``pm_access_token``, ``pm_refresh_token``, and ``pm_csrf_token`` cookies
are set with identical parameters.
"""
from __future__ import annotations

from datetime import UTC, datetime, timedelta

from fastapi import Response

from app.config import settings


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def refresh_cookie_max_age(
    refresh_expires_at: datetime | None,
    last_active_at: datetime | None = None,
) -> int:
    """Return remaining refresh-cookie lifetime in seconds.

    The browser cookie should not outlive either the absolute session lifetime
    or the sliding idle timeout.
    """
    now = datetime.now(UTC)
    max_ages = []
    if isinstance(refresh_expires_at, datetime):
        max_ages.append((_as_utc(refresh_expires_at) - now).total_seconds())
    else:
        max_ages.append(settings.refresh_token_expire_days * 86400)

    if isinstance(last_active_at, datetime):
        idle_expires_at = _as_utc(last_active_at)
        idle_expires_at += timedelta(minutes=settings.session_idle_timeout_minutes)
        max_ages.append((idle_expires_at - now).total_seconds())
    else:
        max_ages.append(settings.session_idle_timeout_minutes * 60)

    return max(0, int(min(max_ages)))


def set_web_refresh_cookie(
    response: Response,
    refresh_token: str,
    *,
    max_age: int | None = None,
) -> None:
    """Set the Web refresh cookie and remove legacy access/CSRF cookies."""
    response.delete_cookie(
        key=settings.auth_access_cookie_name,
        path="/",
        secure=settings.auth_cookie_secure,
        httponly=True,
        samesite=settings.auth_cookie_samesite,
    )
    response.delete_cookie(
        key=settings.auth_csrf_cookie_name,
        path="/",
        secure=settings.auth_cookie_secure,
        httponly=False,
        samesite=settings.auth_cookie_samesite,
    )
    response.set_cookie(
        key=settings.auth_refresh_cookie_name,
        value=refresh_token,
        httponly=True,
        samesite=settings.auth_cookie_samesite,
        secure=settings.auth_cookie_secure,
        path="/",
        max_age=(
            settings.refresh_token_expire_days * 86400
            if max_age is None
            else max_age
        ),
    )


def extend_web_refresh_cookie(
    response: Response,
    refresh_token: str,
    *,
    max_age: int,
) -> None:
    """Refresh only the Web refresh cookie lifetime."""
    response.set_cookie(
        key=settings.auth_refresh_cookie_name,
        value=refresh_token,
        httponly=True,
        samesite=settings.auth_cookie_samesite,
        secure=settings.auth_cookie_secure,
        path="/",
        max_age=max_age,
    )


def set_auth_cookies(
    response: Response,
    access_token: str,
    refresh_token: str,
    csrf_token: str,
    *,
    refresh_max_age: int | None = None,
) -> None:
    """Set auth cookies (access, refresh, CSRF) on a response."""
    response.set_cookie(
        key=settings.auth_access_cookie_name,
        value=access_token,
        httponly=True,
        samesite=settings.auth_cookie_samesite,
        secure=settings.auth_cookie_secure,
        path="/",
        max_age=settings.access_token_expire_minutes * 60,
    )
    response.set_cookie(
        key=settings.auth_refresh_cookie_name,
        value=refresh_token,
        httponly=True,
        samesite=settings.auth_cookie_samesite,
        secure=settings.auth_cookie_secure,
        path="/",
        max_age=(
            settings.refresh_token_expire_days * 86400
            if refresh_max_age is None
            else refresh_max_age
        ),
    )
    response.set_cookie(
        key=settings.auth_csrf_cookie_name,
        value=csrf_token,
        httponly=False,
        samesite=settings.auth_cookie_samesite,
        secure=settings.auth_cookie_secure,
        path="/",
    )


def clear_auth_cookies(response: Response) -> None:
    """Clear all auth cookies on a response."""
    response.delete_cookie(
        key=settings.auth_access_cookie_name,
        path="/",
        secure=settings.auth_cookie_secure,
        httponly=True,
        samesite=settings.auth_cookie_samesite,
    )
    response.delete_cookie(
        key=settings.auth_refresh_cookie_name,
        path="/",
        secure=settings.auth_cookie_secure,
        httponly=True,
        samesite=settings.auth_cookie_samesite,
    )
    response.delete_cookie(
        key=settings.auth_csrf_cookie_name,
        path="/",
        secure=settings.auth_cookie_secure,
        httponly=False,
        samesite=settings.auth_cookie_samesite,
    )
