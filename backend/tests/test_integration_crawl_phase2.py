"""Phase 2 Crawler Integration Tests.

Tests persist crawl task state in PostgreSQL via async SQLAlchemy.
Uses ASGITransport for API calls and real DB sessions for verifications.
"""
from unittest.mock import AsyncMock, MagicMock

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


@pytest.mark.asyncio
async def test_job_single_crawl_persists_task(phase2_client, monkeypatch, cleanup_phase2_overrides):
    """POST /api/v1/jobs/crawl-now/1 creates a crawl_tasks row."""
    await _clean_crawl_tables()

    async def fake_runner(task, *, config_id):
        task.status = "completed"
        task.total = 1
        task.success = 1
        task.errors = 0
        return {"status": "success", "new_count": 1, "updated_count": 0, "deactivated_count": 0}

    monkeypatch.setattr(
        "app.domains.crawling.task_runner.CrawlTaskRunner.run_job_config",
        fake_runner,
    )

    # Mock the config existence check
    mock_config = MagicMock()
    mock_config.id = 1
    monkeypatch.setattr(
        "app.domains.jobs.service.get_job_config",
        AsyncMock(return_value=mock_config),
    )

    async with AsyncSessionLocal() as db:
        install_auth_and_db_overrides(db)
        response = await phase2_client.post("/api/v1/jobs/crawl-now/1")

        assert response.status_code == 200, f"Got {response.status_code}: {response.text}"
        task_id = response.json()["task_id"]

    # The task record was created in the real DB via AsyncSessionLocal() inside crawl_service
    async with AsyncSessionLocal() as verify_db:
        from app.domains.crawling.task_store import get_crawl_task_record

        record = await get_crawl_task_record(verify_db, task_id)
        assert record is not None
        assert record.task_type == "job_config"
        assert record.entity_id == "1"


@pytest.mark.asyncio
async def test_job_crawl_status_reads_persistent_task(phase2_client):
    """GET /api/v1/jobs/crawl/status/{task_id} reads from crawl_tasks."""
    await _clean_crawl_tables()

    async with AsyncSessionLocal() as db:
        from app.domains.crawling.task_store import create_crawl_task_record

        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_config",
            platform="boss",
            user_id=1,
            entity_type="job_config",
            entity_id="1",
        )
        record.status = "failed"
        record.reason = "profile_already_leased"
        await db.commit()

        response = await phase2_client.get(f"/api/v1/jobs/crawl/status/{record.task_id}")

        assert response.status_code == 200
        assert response.json()["status"] == "failed"


@pytest.mark.asyncio
async def test_startup_recovery_marks_stale_tasks_and_releases_profiles(tmp_path):
    """Startup recovery marks stale running tasks and releases expired profile leases."""
    await _clean_crawl_tables()

    from datetime import UTC, datetime, timedelta

    from sqlalchemy import select

    from app.domains.crawling.profile_pool import (
        DatabaseProfilePool,
        recover_stale_profile_leases,
    )
    from app.domains.crawling.task_store import (
        create_crawl_task_record,
        mark_task_running,
        recover_stale_running_tasks,
    )

    stale_time = datetime.now(UTC) - timedelta(hours=2)

    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_config",
            user_id=1,
            entity_type="job_config",
            entity_id="1",
        )
        await mark_task_running(
            db, record, owner="old-api", lease_seconds=1, now=stale_time,
        )

        pool = DatabaseProfilePool(root=tmp_path)
        await pool.acquire(
            db,
            platform="boss",
            profile_key="default",
            owner="old-api",
            task_id=record.task_id,
            lease_seconds=1,
        )
        # Manually expire the profile lease for recovery testing
        from app.domains.crawling.profile_pool import LEASED
        from app.models.crawl_profile import CrawlProfile

        result = await db.execute(
            select(CrawlProfile).where(CrawlProfile.profile_key == "default")
        )
        profile_row = result.scalar_one()
        profile_row.lease_until = stale_time
        await db.commit()

    async with AsyncSessionLocal() as db:
        recovered_tasks = await recover_stale_running_tasks(
            db, owner_reason="worker_restarted",
        )
        recovered_profiles = await recover_stale_profile_leases(db)

    assert recovered_tasks == 1
    assert recovered_profiles == 1
