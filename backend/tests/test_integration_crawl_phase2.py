"""Phase 2 Crawler Integration Tests.

Tests persist crawl task state in PostgreSQL via async SQLAlchemy.
Uses ASGITransport for API calls and real DB sessions for verifications.
"""
from unittest.mock import MagicMock

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import delete

from app.core.security import get_current_user
from app.database import AsyncSessionLocal, get_db
from app.main import app
from app.models.crawl_profile import CrawlProfile
from app.models.crawl_task import CrawlTaskRecord


def create_mock_user(user_id=1, username="testuser", role="user"):
    user = MagicMock()
    user.id = user_id
    user.username = username
    user.email = f"{username}@example.com"
    user.role = role
    user.deleted_at = None
    return user


@pytest.fixture
def cleanup_phase2_overrides():
    yield
    app.dependency_overrides.clear()


@pytest.fixture
async def phase2_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


async def _clean_crawl_tables():
    async with AsyncSessionLocal() as s:
        await s.execute(delete(CrawlProfile))
        await s.execute(delete(CrawlTaskRecord))
        await s.commit()


@pytest.fixture
async def crawl_db_session():
    """Provide a clean DB session for direct queries."""
    await _clean_crawl_tables()
    async with AsyncSessionLocal() as session:
        yield session
    await _clean_crawl_tables()


def install_auth_and_db_overrides(db_session):
    async def _mock_get_current_user(token=None, db=None):
        return create_mock_user()

    async def _mock_get_db():
        yield db_session

    app.dependency_overrides[get_current_user] = _mock_get_current_user
    app.dependency_overrides[get_db] = _mock_get_db


@pytest.mark.asyncio
async def test_product_crawl_now_persists_task(phase2_client, monkeypatch, cleanup_phase2_overrides):
    """POST /api/v1/crawl/crawl-now creates a crawl_tasks row."""
    await _clean_crawl_tables()
    import asyncio

    async def fake_run_crawl_in_lock(task, crawl_lock, *, record_id=None):
        task.status = "completed"

    monkeypatch.setattr(
        "app.domains.crawling.scheduler_service._run_crawl_in_lock",
        fake_run_crawl_in_lock,
    )
    monkeypatch.setattr(
        "app.domains.crawling.scheduler_service._scheduler_state",
        {"crawl_lock": asyncio.Semaphore(1)},
    )

    async with AsyncSessionLocal() as db:
        install_auth_and_db_overrides(db)

        response = await phase2_client.post("/api/v1/crawl/crawl-now")

        assert response.status_code == 200
        task_id = response.json()["task_id"]

        from app.domains.crawling.task_store import get_crawl_task_record

        record = await get_crawl_task_record(db, task_id)
        assert record is not None
        assert record.task_type == "product_all"
        assert record.source == "manual"


@pytest.mark.asyncio
async def test_product_status_reads_persistent_task(phase2_client):
    """GET /api/v1/crawl/status/{task_id} reads from crawl_tasks."""
    await _clean_crawl_tables()

    async with AsyncSessionLocal() as db:
        from app.domains.crawling.task_store import create_crawl_task_record

        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="product_all",
            user_id=1,
            entity_type="crawl_task",
            entity_id=None,
        )
        record.status = "completed"
        record.total = 2
        record.success = 1
        record.errors = 1
        await db.commit()

        response = await phase2_client.get(f"/api/v1/crawl/status/{record.task_id}")

        assert response.status_code == 200
        assert response.json()["status"] == "completed"
        assert response.json()["total"] == 2
