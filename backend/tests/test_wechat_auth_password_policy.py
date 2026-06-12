from __future__ import annotations

from unittest.mock import AsyncMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app

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

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/wechat/register",
            json={
                "temp_token": "temp-token",
                "username": "wechatuser",
                "email": "wechat@example.com",
                "password": "weakpass12",
            },
        )

    assert response.status_code == 422
    assert "10 位" in str(response.json()["detail"])
    register_spy.assert_not_awaited()
