"""Security regression tests for crawl task read endpoints."""

from datetime import UTC, datetime
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_current_user
from app.database import get_db
from app.main import app


def _task_record(task_id: str = "task-1") -> SimpleNamespace:
    now = datetime.now(UTC)
    return SimpleNamespace(
        task_id=task_id,
        status="completed",
        total=1,
        success=1,
        errors=0,
        reason=None,
        locked_by="worker-1",
        heartbeat_at=now,
        lease_until=now,
        started_at=now,
        finished_at=now,
        details_json=[{"ok": True}],
    )


def _override_user(user_id: int = 42) -> None:
    user = MagicMock()
    user.id = user_id
    user.role = "user"

    async def _current_user():
        return user

    app.dependency_overrides[get_current_user] = _current_user


def _override_db() -> AsyncMock:
    db = AsyncMock()

    async def _db():
        yield db

    app.dependency_overrides[get_db] = _db
    return db


def _clear_overrides() -> None:
    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_db, None)


@pytest.mark.anyio
@pytest.mark.parametrize(
    "path",
    [
        "/api/v1/crawl/status/task-1",
        "/api/v1/crawl/result/task-1",
        "/api/v1/jobs/crawl/status/task-1",
        "/api/v1/jobs/crawl/result/task-1",
    ],
)
async def test_crawl_task_read_endpoints_scope_records_to_current_user(
    monkeypatch,
    path: str,
):
    """Task read endpoints must not perform global task-id lookups."""
    db = _override_db()
    _override_user(user_id=42)
    get_record = AsyncMock(return_value=_task_record())
    monkeypatch.setattr(
        "app.domains.crawling.task_store.get_crawl_task_record",
        get_record,
    )

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(path, headers={"Authorization": "Bearer fake"})

        assert response.status_code == 200
        get_record.assert_awaited_once_with(db, "task-1", user_id=42)
    finally:
        _clear_overrides()
