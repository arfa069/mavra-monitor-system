"""API tests for resume and job match endpoints."""

from datetime import UTC, datetime
from unittest.mock import ANY, AsyncMock, MagicMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_current_user
from app.main import app


def create_mock_user(user_id=1, username="testuser", role="user"):
    """Create a mock user with minimal attributes."""
    user = MagicMock()
    user.id = user_id
    user.username = username
    user.email = f"{username}@example.com"
    user.role = role
    user.deleted_at = None
    user.created_at = datetime.now(UTC)
    user.updated_at = datetime.now(UTC)
    return user


@pytest.fixture
def mock_get_current_user():
    """Mock get_current_user to return a test user."""
    async def _mock_get_current_user(token=None, db=None):
        return create_mock_user()
    app.dependency_overrides[get_current_user] = _mock_get_current_user
    yield
    app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_list_resumes_returns_items(mock_get_current_user):
    """GET /jobs/resumes returns uploaded resumes."""
    from app.database import get_db
    from app.models.job_match import UserResume

    resume = MagicMock(spec=UserResume)
    resume.id = 1
    resume.user_id = 1
    resume.name = "Resume A"
    resume.resume_text = "Python engineer"
    resume.created_at = datetime.now(UTC)
    resume.updated_at = datetime.now(UTC)

    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = [resume]

    mock_session = AsyncMock()
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def _override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = _override_get_db
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get("/api/v1/jobs/resumes")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "Resume A"
    finally:
        app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_create_resume_returns_created_entity(mock_get_current_user):
    """POST /jobs/resumes creates a resume."""
    from datetime import UTC, datetime

    from app.database import get_db

    mock_session = AsyncMock()
    mock_session.add = MagicMock()
    mock_session.commit = AsyncMock()
    mock_session.refresh = AsyncMock(
        side_effect=lambda resume: (
            setattr(resume, "id", 99),
            setattr(resume, "created_at", datetime.now(UTC)),
            setattr(resume, "updated_at", datetime.now(UTC)),
        )
    )

    async def _override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = _override_get_db
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.post(
                "/api/v1/jobs/resumes",
                json={"name": "Resume B", "resume_text": "Frontend engineer"},
            )
        assert response.status_code == 201
        data = response.json()
        assert data["id"] == 99
        assert data["name"] == "Resume B"
    finally:
        app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_trigger_match_analysis_enqueues_durable_task(mock_get_current_user):
    """POST /jobs/match-results/analyze enqueues a durable crawl_task."""
    from app.database import get_db
    from app.models.job_match import UserResume

    resume = MagicMock(spec=UserResume)
    resume.id = 1
    resume.user_id = 1

    mock_session = AsyncMock()
    mock_session.get = AsyncMock(return_value=resume)

    async def _override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = _override_get_db

    with patch("app.domains.jobs.router.enqueue_job_match_analysis", new_callable=AsyncMock) as mock_enqueue:
        mock_enqueue.return_value = {
            "task_id": "durable-abc",
            "total": 5,
            "status": "pending",
            "reason": None,
        }

        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/jobs/match-results/analyze",
                    json={"resume_id": 1, "job_ids": [10]},
                )
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "pending"
            assert data["task_id"] == "durable-abc"
            assert data["total"] == 5
            mock_enqueue.assert_called_once()
        finally:
            app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_trigger_match_analysis_returns_completed_when_all_up_to_date(mock_get_current_user):
    """POST /jobs/match-results/analyze returns completed when no jobs need analysis."""
    from app.database import get_db
    from app.models.job_match import UserResume

    resume = MagicMock(spec=UserResume)
    resume.id = 1
    resume.user_id = 1

    mock_session = AsyncMock()
    mock_session.get = AsyncMock(return_value=resume)

    async def _override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = _override_get_db

    with patch("app.domains.jobs.router.enqueue_job_match_analysis", new_callable=AsyncMock) as mock_enqueue:
        mock_enqueue.return_value = {
            "task_id": None,
            "total": 0,
            "status": "completed",
            "reason": "all_up_to_date",
        }

        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/jobs/match-results/analyze",
                    json={"resume_id": 1, "job_ids": [10]},
                )
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "completed"
            assert data["task_id"] is None
            assert data["reason"] == "all_up_to_date"
        finally:
            app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_analyze_async_enqueues_durable_task(mock_get_current_user):
    """POST /jobs/match-results/analyze-async enqueues a durable crawl_task."""
    from app.database import get_db
    from app.models.job_match import UserResume

    resume = MagicMock(spec=UserResume)
    resume.id = 1
    resume.user_id = 1

    mock_session = AsyncMock()
    mock_session.get = AsyncMock(return_value=resume)

    async def _override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = _override_get_db

    with patch("app.domains.jobs.router.enqueue_job_match_analysis", new_callable=AsyncMock) as mock_enqueue:
        mock_enqueue.return_value = {
            "task_id": "durable-xyz",
            "total": 3,
            "status": "pending",
            "reason": None,
        }

        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/jobs/match-results/analyze-async",
                    json={"resume_id": 1, "job_ids": [10]},
                )
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "pending"
            assert data["task_id"] == "durable-xyz"
            assert data["total"] == 3
            mock_enqueue.assert_called_once()
        finally:
            app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_analyze_async_returns_completed_when_all_up_to_date(mock_get_current_user):
    """POST /jobs/match-results/analyze-async returns completed if no jobs need analysis."""
    from app.database import get_db
    from app.models.job_match import UserResume

    resume = MagicMock(spec=UserResume)
    resume.id = 1
    resume.user_id = 1

    mock_session = AsyncMock()
    mock_session.get = AsyncMock(return_value=resume)

    async def _override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = _override_get_db

    with patch("app.domains.jobs.router.enqueue_job_match_analysis", new_callable=AsyncMock) as mock_enqueue:
        mock_enqueue.return_value = {
            "task_id": None,
            "total": 0,
            "status": "completed",
            "reason": "all_up_to_date",
        }

        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/jobs/match-results/analyze-async",
                    json={"resume_id": 1, "job_ids": [10]},
                )
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "completed"
            assert data["reason"] == "all_up_to_date"
            assert data["task_id"] is None
        finally:
            app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_get_task_status_returns_task_state_from_crawl_tasks(mock_get_current_user):
    """GET /jobs/tasks/{task_id} should return task status from crawl_tasks."""
    mock_record = MagicMock()
    mock_record.task_id = "xyz789"
    mock_record.status = "running"
    mock_record.total = 5
    mock_record.success = 2
    mock_record.errors = 1
    mock_record.reason = None
    mock_record.locked_by = "worker:test"
    mock_record.heartbeat_at = None
    mock_record.lease_until = None
    mock_record.task_type = "job_match_analysis"

    with patch("app.domains.crawling.task_store.get_crawl_task_record", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = mock_record
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get("/api/v1/jobs/tasks/xyz789")
        assert response.status_code == 200
        data = response.json()
        assert data["task_id"] == "xyz789"
        assert data["status"] == "running"
        assert data["total"] == 5
        assert data["success"] == 2
        assert data["errors"] == 1
        assert data["worker_id"] == "worker:test"
        mock_get.assert_awaited_once_with(ANY, "xyz789", user_id=1)


@pytest.mark.asyncio
async def test_get_task_status_returns_404_for_missing_task(mock_get_current_user):
    """GET /jobs/tasks/{task_id} should 404 for unknown task."""
    with patch("app.domains.crawling.task_store.get_crawl_task_record", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = None
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get("/api/v1/jobs/tasks/nonexistent")
        assert response.status_code == 404
        data = response.json()
        assert data["status"] == "error"
        assert data["reason"] == "task_not_found"


@pytest.mark.asyncio
async def test_get_task_status_returns_404_for_non_match_task(mock_get_current_user):
    """GET /jobs/tasks/{task_id} should only expose job_match_analysis tasks."""
    mock_record = MagicMock()
    mock_record.task_type = "job_config"

    with patch("app.domains.crawling.task_store.get_crawl_task_record", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = mock_record
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get("/api/v1/jobs/tasks/job-task")
        assert response.status_code == 404
        data = response.json()
        assert data["status"] == "error"
        assert data["reason"] == "task_not_found"
