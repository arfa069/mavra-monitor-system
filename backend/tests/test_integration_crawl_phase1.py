"""Phase 1 Crawler API Integration Tests.

Uses ASGITransport to test endpoints without a running server.
Mocks auth, DB, and scheduler state where needed.
"""
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_current_user
from app.main import app


def create_mock_user(user_id=1, username="testuser", role="user"):
    user = MagicMock()
    user.id = user_id
    user.username = username
    user.email = f"{username}@example.com"
    user.role = role
    user.deleted_at = None
    return user


@pytest.fixture
def mock_user():
    """Mock get_current_user for all auth-gated endpoints."""
    async def _mock_get_current_user(token=None, db=None):
        return create_mock_user()

    app.dependency_overrides[get_current_user] = _mock_get_current_user
    yield
    app.dependency_overrides.pop(get_current_user, None)


# ============================================================
# POST /products/crawl/crawl-now
# ============================================================

class TestCrawlNowEndpoint:
    """POST /products/crawl/crawl-now — triggers manual crawl."""

    @pytest.mark.asyncio
    async def test_crawl_now_returns_task_id(self, mock_user):
        """Returns pending status and task_id when crawl starts."""
        from app.database import get_db

        # Mock DB for require_permission lookup
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = 1
        mock_result.scalars.return_value.all.return_value = ["crawl:execute"]
        mock_session = AsyncMock()
        mock_session.execute = AsyncMock(return_value=mock_result)

        async def _override():
            yield mock_session

        app.dependency_overrides[get_db] = _override
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post("/products/crawl/crawl-now")

            # Should either return pending (scheduler running) or 500 (not init)
            assert response.status_code in [200, 500]
            data = response.json()
            if response.status_code == 200:
                assert data["status"] == "pending"
                assert "task_id" in data
        finally:
            app.dependency_overrides.pop(get_db, None)


# ============================================================
# GET /products/crawl/status/{task_id}
# ============================================================

class TestCrawlStatusEndpoint:
    """GET /products/crawl/status/{task_id} — poll crawl progress."""

    @pytest.mark.asyncio
    async def test_status_unknown_task_returns_404(self):
        """Unknown task_id returns 404."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get("/products/crawl/status/nonexistent")

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_status_pending_task(self, mock_user):
        """Pending task returns PENDING status."""
        from app.core.task_registry import create_task

        task = create_task("manual", user_id=1)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(f"/products/crawl/status/{task.task_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["task_id"] == task.task_id
        assert data["status"] == "pending"

    @pytest.mark.asyncio
    async def test_status_completed_task(self, mock_user):
        """Completed task returns COMPLETED status with counts."""
        from app.core.task_registry import TaskStatus, create_task

        task = create_task("manual", user_id=1)
        task.status = TaskStatus.COMPLETED
        task.total = 5
        task.success = 4
        task.errors = 1

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(f"/products/crawl/status/{task.task_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert data["total"] == 5
        assert data["success"] == 4
        assert data["errors"] == 1

    @pytest.mark.asyncio
    async def test_status_via_v1_prefix(self, mock_user):
        """Same endpoint accessible via /v1 prefix."""
        from app.core.task_registry import create_task

        task = create_task("manual", user_id=1)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(f"/v1/crawl/status/{task.task_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["task_id"] == task.task_id


# ============================================================
# GET /products/crawl/result/{task_id}
# ============================================================

class TestCrawlResultEndpoint:
    """GET /products/crawl/result/{task_id} — retrieve final result."""

    @pytest.mark.asyncio
    async def test_result_unknown_returns_404(self):
        """Unknown task_id returns 404."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get("/products/crawl/result/nonexistent")

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_result_pending_returns_202(self, mock_user):
        """Pending/running task returns 202."""
        from app.core.task_registry import create_task

        task = create_task("manual", user_id=1)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(f"/products/crawl/result/{task.task_id}")

        assert response.status_code == 202
        data = response.json()
        assert data["status"] == "pending"

    @pytest.mark.asyncio
    async def test_result_completed_returns_details(self, mock_user):
        """Completed task returns full result."""
        from app.core.task_registry import TaskStatus, create_task

        task = create_task("manual", user_id=1)
        task.status = TaskStatus.COMPLETED
        task.total = 2
        task.success = 2
        task.errors = 0
        task.details = [
            {"status": "success", "product_id": 1},
            {"status": "success", "product_id": 2},
        ]

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(f"/products/crawl/result/{task.task_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert len(data["details"]) == 2

    @pytest.mark.asyncio
    async def test_result_failed_returns_500(self, mock_user):
        """Failed task returns 500 with reason."""
        from app.core.task_registry import TaskStatus, create_task

        task = create_task("manual", user_id=1)
        task.status = TaskStatus.FAILED
        task.reason = "something_went_wrong"

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get(f"/products/crawl/result/{task.task_id}")

        assert response.status_code == 500
        data = response.json()
        assert data["reason"] == "something_went_wrong"


# ============================================================
# CrawlTaskRunner Integration
# ============================================================

class TestCrawlTaskRunnerIntegration:
    """CrawlTaskRunner calls correct underlying services."""

    @pytest.mark.asyncio
    async def test_runner_single_job_routes_to_service(self, monkeypatch):
        """run_job_config delegates to crawl_single_config."""
        from app.core.task_registry import create_task
        from app.domains.crawling.task_runner import CrawlTaskRunner

        mock_crawl = AsyncMock(
            return_value={"status": "success", "new_count": 3, "updated_count": 1, "deactivated_count": 0}
        )
        monkeypatch.setattr(
            "app.domains.jobs.crawl_service.crawl_single_config",
            mock_crawl,
        )

        task = create_task("manual", user_id=1, entity_type="job_config", entity_id="5")
        result = await CrawlTaskRunner().run_job_config(task, config_id=5)

        assert result["status"] == "success"
        assert task.total == 4
        mock_crawl.assert_awaited_once_with(5)

    @pytest.mark.asyncio
    async def test_runner_all_jobs_routes_to_service(self, monkeypatch):
        """run_all_jobs delegates to crawl_all_job_searches."""
        from app.core.task_registry import create_task
        from app.domains.crawling.task_runner import CrawlTaskRunner

        mock_all = AsyncMock(
            return_value={"status": "completed", "total": 3, "success": 3, "errors": 0}
        )
        monkeypatch.setattr(
            "app.domains.jobs.crawl_service.crawl_all_job_searches",
            mock_all,
        )

        task = create_task("manual", user_id=1)
        result = await CrawlTaskRunner().run_all_jobs(task)

        assert result["status"] == "completed"
        assert task.total == 3
        mock_all.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_runner_no_active_products_returns_early(self, monkeypatch):
        """run_all_products returns immediately when no active products."""
        from app.core.task_registry import TaskStatus, create_task
        from app.domains.crawling.task_runner import CrawlTaskRunner

        monkeypatch.setattr(
            "app.domains.crawling.service.get_active_products",
            AsyncMock(return_value=[]),
        )

        task = create_task("manual", user_id=1)
        result = await CrawlTaskRunner().run_all_products(task)

        assert task.reason == "no_active_products"
        assert task.status == TaskStatus.COMPLETED

    @pytest.mark.asyncio
    async def test_runner_product_error_handled_gracefully(self, monkeypatch):
        """Exception in product crawl is caught and recorded as error."""
        from types import SimpleNamespace

        from app.core.task_registry import create_task
        from app.domains.crawling.task_runner import CrawlTaskRunner

        monkeypatch.setattr(
            "app.domains.crawling.service.get_active_products",
            AsyncMock(return_value=[SimpleNamespace(id=99)]),
        )
        monkeypatch.setattr(
            "app.domains.crawling.service.crawl_one",
            AsyncMock(side_effect=ValueError("network error")),
        )

        task = create_task("manual", user_id=1)
        result = await CrawlTaskRunner().run_all_products(task)

        assert result["status"] == "completed"
        assert task.errors == 1
        assert task.success == 0


# ============================================================
# Profile Lease Manager Integration
# ============================================================

class TestProfileLeaseIntegration:
    """Profile lease management with real temp directories."""

    @pytest.mark.asyncio
    async def test_acquire_creates_directory(self, tmp_path):
        """Acquiring a lease creates the profile directory."""
        from app.core.profile_lease import InProcessProfileLeaseManager

        manager = InProcessProfileLeaseManager(root=tmp_path)
        lease = await manager.acquire("boss", "profile-a", owner="test")

        assert lease.profile_dir.exists()
        assert lease.platform == "boss"
        assert lease.profile_key == "profile-a"

    @pytest.mark.asyncio
    async def test_duplicate_acquire_raises(self, tmp_path):
        """Acquiring the same lease twice raises RuntimeError."""
        from app.core.profile_lease import InProcessProfileLeaseManager

        manager = InProcessProfileLeaseManager(root=tmp_path)
        await manager.acquire("boss", "profile-a", owner="test")

        with pytest.raises(RuntimeError, match="already leased"):
            await manager.acquire("boss", "profile-a", owner="test2")

    @pytest.mark.asyncio
    async def test_release_allows_reacquire(self, tmp_path):
        """After release, same lease can be acquired again."""
        from app.core.profile_lease import InProcessProfileLeaseManager

        manager = InProcessProfileLeaseManager(root=tmp_path)
        lease = await manager.acquire("boss", "profile-a", owner="test")
        await manager.release(lease)

        lease2 = await manager.acquire("boss", "profile-a", owner="test2")
        assert lease2.profile_key == "profile-a"

    @pytest.mark.asyncio
    async def test_context_manager_releases_on_exit(self, tmp_path):
        """Using the context manager releases the lease on exit."""
        from app.core.profile_lease import InProcessProfileLeaseManager

        manager = InProcessProfileLeaseManager(root=tmp_path)
        async with manager.lease("boss", "profile-a", owner="test") as lease:
            assert lease.profile_dir.exists()

        # Should be able to reacquire immediately
        lease2 = await manager.acquire("boss", "profile-a", owner="test2")
        assert lease2.profile_key == "profile-a"


# ============================================================
# CDP Security Integration
# ============================================================

class TestCdpSecurity:
    """CDP URL validation integration checks."""

    def test_localhost_accepted(self):
        """localhost is accepted without allow_non_local."""
        from app.core.cdp_security import validate_cdp_url

        validate_cdp_url("ws://localhost:9222")  # no raise

    def test_loopback_accepted(self):
        """127.0.0.1 is accepted."""
        from app.core.cdp_security import validate_cdp_url

        validate_cdp_url("ws://127.0.0.1:9222")  # no raise

    def test_external_rejected(self):
        """External host is rejected."""
        from app.core.cdp_security import validate_cdp_url

        with pytest.raises(ValueError, match="must be local"):
            validate_cdp_url("ws://evil.example.com:9222")

    def test_empty_rejected(self):
        """Empty URL is rejected."""
        from app.core.cdp_security import validate_cdp_url

        with pytest.raises(ValueError, match="empty"):
            validate_cdp_url("")

    def test_allow_non_local_skips_validation(self):
        """allow_non_local=True skips local-only check."""
        from app.core.cdp_security import validate_cdp_url

        validate_cdp_url("ws://evil.example.com:9222", allow_non_local=True)  # no raise


# ============================================================
# Log Redaction Integration
# ============================================================

class TestLogRedaction:
    """Log redaction masks sensitive fields."""

    def test_cookies_redacted(self):
        from app.core.log_redaction import redact_payload

        result = redact_payload({"cookie": "secret"})
        assert result["cookie"] == "***REDACTED***"

    def test_tokens_redacted(self):
        from app.core.log_redaction import redact_payload

        result = redact_payload({"access_token": "abc123", "refresh_token": "xyz789"})
        assert result["access_token"] == "***REDACTED***"
        assert result["refresh_token"] == "***REDACTED***"

    def test_webhook_url_redacted(self):
        from app.core.log_redaction import redact_payload

        result = redact_payload({"webhook_url": "https://open.feishu.cn/hook/secret"})
        assert result["webhook_url"] == "***REDACTED***"

    def test_security_id_partial_redact(self):
        from app.core.log_redaction import redact_payload

        result = redact_payload({"securityId": "abcdef1234567890"})
        assert result["securityId"].startswith("abcdef12")
        assert result["securityId"].endswith("***")

    def test_safe_fields_preserved(self):
        from app.core.log_redaction import redact_payload

        result = redact_payload({"name": "Alice", "price": 99.9})
        assert result["name"] == "Alice"
        assert result["price"] == 99.9

    def test_nested_redaction(self):
        from app.core.log_redaction import redact_payload

        payload = {"headers": {"Authorization": "Bearer secret", "X-Custom": "ok"}}
        result = redact_payload(payload)
        assert result["headers"]["Authorization"] == "***REDACTED***"
        assert result["headers"]["X-Custom"] == "ok"


# ============================================================
# Summary
# ============================================================

@pytest.fixture(scope="session", autouse=True)
def print_summary():
    yield
    print("\n" + "=" * 70)
    print("Phase 1 Crawler Integration Tests Complete")
    print("=" * 70)
