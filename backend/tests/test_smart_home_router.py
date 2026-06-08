from datetime import UTC, datetime
from types import SimpleNamespace

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_current_user
from app.database import get_db
from app.main import app
from app.models.user import User
from app.schemas.smart_home import (
    SmartHomeEntity,
    SmartHomeEntityListResponse,
)


def _user(role: str) -> User:
    return User(
        id=1, username="tester", email="tester@example.com", role=role, is_active=True
    )


def _config() -> SimpleNamespace:
    now = datetime.now(UTC)
    return SimpleNamespace(
        id=1,
        base_url="http://homeassistant.local:8123",
        encrypted_token="encrypted",
        enabled=True,
        last_status="ok",
        last_error=None,
        created_at=now,
        updated_at=now,
    )


async def _db_override():
    yield SimpleNamespace()


def _override_user(role: str) -> None:
    async def _current_user():
        return _user(role)

    app.dependency_overrides[get_current_user] = _current_user


def _clear_overrides() -> None:
    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_get_config_requires_configure_permission(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    async def deny_permission(db, role_name, permission):
        return False

    async def permission_exists(db, permission):
        return True

    monkeypatch.setattr("app.core.permissions.role_has_permission", deny_permission)
    monkeypatch.setattr("app.core.permissions.permission_exists", permission_exists)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.get("/v1/smart-home/config")
    finally:
        _clear_overrides()

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_update_config_redacts_token_in_response(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("admin")

    async def allow_permission(db, role_name, permission):
        return True

    async def save_config(db, data):
        assert data.token == "long-lived-token"
        return _config()

    async def log_audit(**kwargs):
        assert kwargs["details"]["token"] == "long-lived-token"
        return None

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    monkeypatch.setattr("app.domains.smart_home.service.save_config", save_config)
    monkeypatch.setattr("app.core.audit.log_audit", log_audit)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.put(
                "/v1/smart-home/config",
                json={
                    "base_url": "http://homeassistant.local:8123",
                    "token": "long-lived-token",
                    "enabled": True,
                },
            )
    finally:
        _clear_overrides()

    assert response.status_code == 200
    payload = response.json()
    assert payload["token_configured"] is True
    assert "token" not in payload
    assert "encrypted_token" not in payload


@pytest.mark.asyncio
async def test_entities_filters_to_supported_domains(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    async def allow_permission(db, role_name, permission):
        return True

    async def list_entities(db):
        return SmartHomeEntityListResponse(
            items=[
                SmartHomeEntity(
                    entity_id="switch.kitchen",
                    domain="switch",
                    name="Kitchen Switch",
                    state="on",
                    attributes={},
                    available=True,
                )
            ],
            total=1,
            connected=True,
        )

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    monkeypatch.setattr("app.domains.smart_home.service.list_entities", list_entities)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.get("/v1/smart-home/entities")
    finally:
        _clear_overrides()

    assert response.status_code == 200
    assert response.json()["items"][0]["entity_id"] == "switch.kitchen"


@pytest.mark.asyncio
async def test_entities_reports_missing_secret_key(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    async def allow_permission(db, role_name, permission):
        return True

    from app.domains.smart_home.crypto import SmartHomeSecretKeyMissingError

    async def list_entities(db):
        raise SmartHomeSecretKeyMissingError("SMART_HOME_SECRET_KEY is not configured")

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    monkeypatch.setattr("app.domains.smart_home.service.list_entities", list_entities)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.get("/v1/smart-home/entities")
    finally:
        _clear_overrides()

    assert response.status_code == 500
    assert response.json()["detail"] == "SMART_HOME_SECRET_KEY is not configured on the server"


@pytest.mark.asyncio
async def test_entities_reports_token_decrypt_failure(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    async def allow_permission(db, role_name, permission):
        return True

    from app.domains.smart_home.crypto import SmartHomeTokenDecryptError

    async def list_entities(db):
        raise SmartHomeTokenDecryptError(
            "Stored Home Assistant token cannot be decrypted with the current SMART_HOME_SECRET_KEY"
        )

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    monkeypatch.setattr("app.domains.smart_home.service.list_entities", list_entities)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.get("/v1/smart-home/entities")
    finally:
        _clear_overrides()

    assert response.status_code == 500
    assert (
        response.json()["detail"]
        == "Stored Home Assistant token cannot be decrypted with the current SMART_HOME_SECRET_KEY"
    )


@pytest.mark.asyncio
async def test_service_call_rejects_unsupported_service(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    async def allow_permission(db, role_name, permission):
        return True

    async def call_entity_service(db, entity_id, service, service_data):
        raise SmartHomeUnsupportedServiceError

    from app.domains.smart_home.service import SmartHomeUnsupportedServiceError

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    monkeypatch.setattr(
        "app.domains.smart_home.service.call_entity_service", call_entity_service
    )

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/v1/smart-home/entities/switch.kitchen/service",
                json={"service": "delete_everything", "service_data": {}},
            )
    finally:
        _clear_overrides()

    assert response.status_code == 400
    assert response.json()["detail"] == "Unsupported smart home service"
