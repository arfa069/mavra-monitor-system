"""Shared auth cookie helpers for consistent cookie setting across routers.

Used by ``auth/router.py`` and ``auth/wechat_router.py`` to ensure
``pm_access_token``, ``pm_refresh_token``, and ``pm_csrf_token`` cookies
are set with identical parameters.
"""
from __future__ import annotations

from fastapi import Response

from app.config import settings


def set_web_refresh_cookie(response: Response, refresh_token: str) -> None:
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
        max_age=settings.refresh_token_expire_days * 86400,
    )


def set_auth_cookies(
    response: Response,
    access_token: str,
    refresh_token: str,
    csrf_token: str,
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
        max_age=settings.refresh_token_expire_days * 86400,
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
