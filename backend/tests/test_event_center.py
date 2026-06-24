"""Event center tests for system logs, permissions, and API shape."""

import asyncio
from contextlib import suppress
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import create_access_token_sid, get_current_user
from app.database import get_db
from app.main import app


def create_mock_user(user_id: int = 1, role: str = "user"):
    """Create a mock authenticated user."""
    user = MagicMock()
    user.id = user_id
    user.username = f"user-{user_id}"
    user.email = f"user-{user_id}@example.com"
    user.role = role
    user.is_active = True
    user.deleted_at = None
    user.created_at = datetime.now(UTC)
    user.updated_at = datetime.now(UTC)
    user.is_admin = role in ("admin", "super_admin")
    return user


def _mock_bearer_db(user):
    result = MagicMock()
    result.scalar_one_or_none.return_value = user
    db = AsyncMock()
    db.execute = AsyncMock(return_value=result)
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


@pytest.fixture(autouse=True)
def cleanup_overrides():
    """Reset FastAPI dependency overrides after each test."""
    yield
    app.dependency_overrides.clear()


def setup_overrides(user, db_session):
    """Install auth and db dependency overrides."""

    async def _mock_get_current_user(token=None, db=None):
        return user

    async def _mock_get_db():
        yield db_session

    app.dependency_overrides[get_current_user] = _mock_get_current_user
    app.dependency_overrides[get_db] = _mock_get_db


@pytest.mark.asyncio
async def test_emit_system_log_commit_success_returns_entry():
    """emit_system_log should return the created log and commit when requested."""
    from app.core.system_log import emit_system_log

    mock_db = AsyncMock()
    mock_db.add = MagicMock()
    mock_db.commit = AsyncMock()

    entry = await emit_system_log(
        db=mock_db,
        category="runtime",
        event_type="job_crawl.started",
        source="jobs",
        message="Job crawl started",
        user_id=7,
        commit=True,
    )

    assert entry is not None
    assert entry.category == "runtime"
    assert entry.event_type == "job_crawl.started"
    assert entry.user_id == 7
    mock_db.add.assert_called_once()
    mock_db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_emit_system_log_redacts_sensitive_payload_before_storage():
    """Sensitive payload fields should never be stored in system logs."""
    from app.core.system_log import emit_system_log

    mock_db = AsyncMock()
    mock_db.add = MagicMock()

    entry = await emit_system_log(
        db=mock_db,
        category="runtime",
        event_type="job_crawl.started",
        source="jobs",
        message="Job crawl started",
        payload={
            "cookie": "session=secret",
            "headers": {"Authorization": "Bearer secret", "User-Agent": "Chrome"},
            "securityId": "abcdef1234567890",
            "safe": "value",
        },
    )

    assert entry is not None
    assert entry.payload_json == {
        "cookie": "***REDACTED***",
        "headers": {"Authorization": "***REDACTED***", "User-Agent": "Chrome"},
        "securityId": "abcdef12***",
        "safe": "value",
    }


@pytest.mark.asyncio
async def test_emit_system_log_failure_is_best_effort():
    """emit_system_log should swallow write failures and return None."""
    from app.core.system_log import emit_system_log

    mock_db = AsyncMock()
    mock_db.add = MagicMock(side_effect=RuntimeError("db write failed"))
    mock_db.commit = AsyncMock()

    entry = await emit_system_log(
        db=mock_db,
        category="platform",
        event_type="http.500",
        source="/health",
        message="Health check failed",
        commit=True,
    )

    assert entry is None
    mock_db.commit.assert_not_awaited()


def test_normalize_system_log_redacts_existing_payloads():
    """Event Center output should redact rows written before storage redaction."""
    from app.core.system_log import normalize_system_log

    log = MagicMock()
    log.id = 1
    log.category = "runtime"
    log.event_type = "job_crawl.started"
    log.severity = "info"
    log.message = "Job crawl started"
    log.occurred_at = datetime.now(UTC)
    log.source = "jobs"
    log.status = "running"
    log.user_id = 7
    log.entity_type = "job_config"
    log.entity_id = "3"
    log.trace_id = None
    log.payload_json = {"webhook_url": "https://open.feishu.cn/hook/secret"}

    result = normalize_system_log(log)

    assert result["payload"] == {"webhook_url": "***REDACTED***"}


def test_normalize_audit_log_redacts_existing_details():
    """Audit details displayed in Event Center should not expose tokens."""
    from app.core.system_log import normalize_audit_log

    log = MagicMock()
    log.id = 1
    log.action = "auth.login"
    log.created_at = datetime.now(UTC)
    log.actor_user_id = 7
    log.target_type = "user"
    log.target_id = 7
    log.details = {"access_token": "secret", "username": "user-7"}

    result = normalize_audit_log(log)

    assert result["payload"] == {
        "access_token": "***REDACTED***",
        "username": "user-7",
    }


def test_can_view_event_applies_platform_and_admin_rules():
    """Platform events stay admin-only while user-scoped events stay per-user."""
    from app.core.system_log import can_view_event

    regular_user = create_mock_user(user_id=11, role="user")
    admin_user = create_mock_user(user_id=99, role="admin")

    assert can_view_event(
        current_user=regular_user,
        kind="audit",
        event_user_id=11,
    ) is True
    assert can_view_event(
        current_user=regular_user,
        kind="audit",
        event_user_id=12,
    ) is False
    assert can_view_event(
        current_user=regular_user,
        kind="system",
        event_user_id=11,
        category="runtime",
    ) is True
    assert can_view_event(
        current_user=regular_user,
        kind="platform",
        event_user_id=None,
        category="platform",
    ) is False
    assert can_view_event(
        current_user=admin_user,
        kind="platform",
        event_user_id=None,
        category="platform",
    ) is True


def test_event_center_paths_are_excluded_from_platform_http_logging():
    from app.main import _is_event_center_path

    assert _is_event_center_path("/api/v1/events")
    assert _is_event_center_path("/api/v1/events/stream")
    assert not _is_event_center_path("/events")
    assert not _is_event_center_path("/v1/events")
    assert not _is_event_center_path("/api/v1/jobs")


@pytest.mark.asyncio
async def test_events_endpoint_returns_paginated_items():
    """GET /events should return unified event-center payload."""
    user = create_mock_user(user_id=21, role="user")

    count_result = MagicMock()
    count_result.scalar_one_or_none.return_value = 2

    rows = [
        {
            "id": "system:2",
            "kind": "system",
            "event_type": "job_crawl.started",
            "category": "runtime",
            "severity": "info",
            "message": "Job crawl started",
            "occurred_at": datetime.now(UTC),
            "source": "jobs",
            "status": "pending",
            "user_id": 21,
            "entity_type": "job_config",
            "entity_id": "9",
            "trace_id": "trace-1",
            "payload": {"task_id": "abc"},
        },
        {
            "id": "audit:1",
            "kind": "audit",
            "event_type": "auth.login",
            "category": "auth",
            "severity": "info",
            "message": "auth.login",
            "occurred_at": datetime.now(UTC),
            "source": "audit",
            "status": "success",
            "user_id": 21,
            "entity_type": "user",
            "entity_id": "21",
            "trace_id": None,
            "payload": {"username": "user-21"},
        },
    ]

    list_result = MagicMock()
    list_result.mappings.return_value.all.return_value = rows

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(side_effect=[count_result, list_result])
    setup_overrides(user, mock_db)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/events?page=1&page_size=20")

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 2
    assert data["page"] == 1
    assert data["page_size"] == 20
    assert [item["kind"] for item in data["items"]] == ["system", "audit"]


@pytest.mark.asyncio
async def test_regular_user_cannot_request_platform_kind():
    """Regular users should get an empty list for platform-only event queries."""
    user = create_mock_user(user_id=22, role="user")

    count_result = MagicMock()
    count_result.scalar_one_or_none.return_value = 0

    list_result = MagicMock()
    list_result.mappings.return_value.all.return_value = []

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(side_effect=[count_result, list_result])
    setup_overrides(user, mock_db)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/events?kind=platform")

    assert response.status_code == 200
    assert response.json()["items"] == []


@pytest.mark.asyncio
async def test_event_stream_accepts_bearer_access_token():
    """Flutter/native clients can open event-center SSE with a bearer token."""
    user = create_mock_user(user_id=23, role="user")
    db = _mock_bearer_db(user)

    async def _override_db():
        yield db

    token = create_access_token_sid(user.id, user.username, 42)
    app.dependency_overrides[get_db] = _override_db

    response_start = await _stream_response_start("/api/v1/events/stream", token)

    assert response_start["status"] == 200
    headers = dict(response_start["headers"])
    assert headers[b"content-type"].startswith(b"text/event-stream")
