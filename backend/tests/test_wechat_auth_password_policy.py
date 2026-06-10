from __future__ import annotations

from unittest.mock import AsyncMock

import pytest
from fastapi import HTTPException
from starlette.requests import Request
from starlette.responses import Response

from app.domains.auth import wechat_router

pytestmark = pytest.mark.asyncio


async def test_register_with_wechat_rejects_weak_password(monkeypatch):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")
    monkeypatch.setattr(
        "app.core.security.decode_access_token",
        lambda token: {"temp": True, "wechat_openid": "openid-1"},
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_login",
        AsyncMock(return_value=None),
    )
    register_spy = AsyncMock()
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.register_wechat_user",
        register_spy,
    )

    scope = {
        "type": "http",
        "method": "POST",
        "path": "/auth/wechat/register",
        "headers": [],
        "query_string": b"",
    }
    request = Request(scope)
    response = Response()
    db = AsyncMock()

    with pytest.raises(HTTPException) as exc_info:
        await wechat_router.register_with_wechat(
            temp_token="temp-token",
            username="wechatuser",
            email="wechat@example.com",
            password="weakpass12",
            request=request,
            response=response,
            db=db,
        )

    assert exc_info.value.status_code == 422
    assert "10 位" in str(exc_info.value.detail)
    register_spy.assert_not_awaited()
