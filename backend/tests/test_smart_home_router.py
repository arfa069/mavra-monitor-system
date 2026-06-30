import asyncio
from contextlib import suppress
from datetime import UTC, datetime
from importlib import import_module
from types import SimpleNamespace

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import create_access_token_sid, get_current_user
from app.database import get_db
from app.main import app
from app.models.user import User
from app.schemas.smart_home import (
    SmartHomeEntity,
    SmartHomeEntityListResponse,
    SmartHomeSummaryResponse,
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


def _mock_bearer_db(user):
    result = SimpleNamespace(scalar_one_or_none=lambda: user)
    db = SimpleNamespace()

    async def execute(_statement):
        return result

    async def commit():
        return None

    db.execute = execute
    db.commit = commit
    return db


async def _stream_response_start(path: str, token: str) -> dict:
    """Run the ASGI app until response headers are sent for an SSE route."""
    start_event = asyncio.Event()
    start_message: dict = {}
    request_sent = False

    async def receive():
        nonlocal request_sent
        if not request_sent:
            request_sent = True
            return {"type": "http.request", "body": b"", "more_body": False}
        return {"type": "http.disconnect"}

    async def send(message):
        nonlocal start_message
        if message["type"] == "http.response.start":
            start_message = message
            start_event.set()

    scope = {
        "type": "http",
        "asgi": {"version": "3.0"},
        "http_version": "1.1",
        "method": "GET",
        "scheme": "http",
        "path": path,
        "raw_path": path.encode(),
        "query_string": b"",
        "headers": [
            (b"host", b"test"),
            (b"authorization", f"Bearer {token}".encode()),
        ],
        "client": ("testclient", 50000),
        "server": ("test", 80),
        "root_path": "",
    }
    task = asyncio.create_task(app(scope, receive, send))
    try:
        await asyncio.wait_for(start_event.wait(), timeout=2)
    finally:
        task.cancel()
        with suppress(asyncio.CancelledError):
            await task
    return start_message


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
            response = await client.get("/api/v1/smart-home/config")
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
                "/api/v1/smart-home/config",
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
            response = await client.get("/api/v1/smart-home/entities")
    finally:
        _clear_overrides()

    assert response.status_code == 200
    assert response.json()["items"][0]["entity_id"] == "switch.kitchen"


@pytest.mark.asyncio
async def test_summary_returns_lightweight_home_signal(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    async def allow_permission(db, role_name, permission):
        return True

    async def get_summary(db):
        return SmartHomeSummaryResponse(
            configured=True,
            connected=True,
            active_count=4,
            unavailable_count=1,
        )

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    monkeypatch.setattr("app.domains.smart_home.service.get_summary", get_summary)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.get("/api/v1/smart-home/summary")
    finally:
        _clear_overrides()

    assert response.status_code == 200
    assert response.json() == {
        "configured": True,
        "connected": True,
        "active_count": 4,
        "unavailable_count": 1,
    }


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
            response = await client.get("/api/v1/smart-home/entities")
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
            response = await client.get("/api/v1/smart-home/entities")
    finally:
        _clear_overrides()

    assert response.status_code == 500
    assert (
        response.json()["detail"]
        == "Stored Home Assistant token cannot be decrypted with the current SMART_HOME_SECRET_KEY"
    )


@pytest.mark.asyncio
async def test_service_call_accepts_entity_id_with_slash_in_request_body(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")
    received: dict[str, object] = {}

    async def allow_permission(db, role_name, permission):
        return True

    async def call_entity_service(db, entity_id, service, service_data):
        received.update(
            entity_id=entity_id,
            service=service,
            service_data=service_data,
        )

    async def log_audit(*args, **kwargs):
        return None

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    monkeypatch.setattr(
        "app.domains.smart_home.service.call_entity_service", call_entity_service
    )
    router_module = import_module("app.domains.smart_home.router")
    monkeypatch.setattr(router_module, "log_audit_from_request", log_audit)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/api/v1/smart-home/services/call",
                json={
                    "entity_id": "light.office/main",
                    "service": "turn_on",
                    "service_data": {"brightness": 50},
                },
            )
    finally:
        _clear_overrides()

    assert response.status_code == 200
    assert response.json()["entity_id"] == "light.office/main"
    assert received == {
        "entity_id": "light.office/main",
        "service": "turn_on",
        "service_data": {"brightness": 50},
    }


@pytest.mark.asyncio
async def test_legacy_entity_service_path_is_not_registered():
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/api/v1/smart-home/entities/light.office/service",
                json={"service": "turn_on", "service_data": {}},
            )
    finally:
        _clear_overrides()

    assert response.status_code == 404


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
                "/api/v1/smart-home/services/call",
                json={
                    "entity_id": "switch.kitchen",
                    "service": "delete_everything",
                    "service_data": {},
                },
            )
    finally:
        _clear_overrides()

    assert response.status_code == 400
    assert response.json()["detail"] == "Unsupported smart home service"


@pytest.mark.asyncio
async def test_smart_home_entity_stream_accepts_bearer_access_token(monkeypatch):
    user = _user("user")

    async def override_db():
        yield _mock_bearer_db(user)

    async def allow_permission(db, role_name, permission):
        return True

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    app.dependency_overrides[get_db] = override_db

    token = create_access_token_sid(user.id, user.username, 42)
    try:
        response_start = await _stream_response_start(
            "/api/v1/smart-home/entities/stream",
            token,
        )
    finally:
        _clear_overrides()

    assert response_start["status"] == 200
    headers = dict(response_start["headers"])
    assert headers[b"content-type"].startswith(b"text/event-stream")
