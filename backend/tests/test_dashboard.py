"""Tests for dashboard service and API."""
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.schemas.dashboard import SystemKPI, UserKPI


# --- Service Tests ---


class TestDashboardService:
    """Test dashboard KPI aggregation."""

    @pytest.fixture
    def mock_db(self):
        """Create a mock async database session."""
        db = AsyncMock()

        # Helper to create mock result with scalar_one/scalar_one_or_none
        def make_result(value):
            result = MagicMock()
            result.scalar_one.return_value = value
            result.scalar_one_or_none.return_value = value
            result.all.return_value = []
            return result

        db.execute = AsyncMock(side_effect=lambda q: make_result(0))
        return db

    @pytest.fixture
    def service(self, mock_db):
        """Create dashboard service with mock redis."""
        from app.services.dashboard_service import DashboardService

        return DashboardService(mock_db, redis_client=None)

    @pytest.mark.asyncio
    async def test_calculate_user_kpi_empty(self, service, mock_db):
        """User KPI with no data returns zeros."""
        kpi = await service.calculate_user_kpi(user_id=1)
        assert isinstance(kpi, UserKPI)
        assert kpi.total_products == 0
        assert kpi.price_drops_today == 0
        assert kpi.new_jobs_today == 0
        assert kpi.match_count == 0
        assert kpi.crawl_count_today == 0

    @pytest.mark.asyncio
    async def test_calculate_system_kpi(self, service, mock_db):
        """System KPI returns valid metrics."""
        kpi = await service.calculate_system_kpi()
        assert isinstance(kpi, SystemKPI)
        assert kpi.total_users >= 0
        assert kpi.total_crawls >= 0
        assert 0.0 <= kpi.success_rate <= 1.0
        assert kpi.active_alerts >= 0
        assert 0.0 <= kpi.disk_usage <= 1.0
        assert 0.0 <= kpi.memory_usage <= 1.0

    @pytest.mark.asyncio
    async def test_calculate_user_kpi_with_data(self, service, mock_db):
        """User KPI returns correct counts when data exists."""
        call_count = 0

        def make_result(value):
            nonlocal call_count
            result = MagicMock()
            # Return the provided value for each call
            result.scalar_one.return_value = value
            result.scalar_one_or_none.return_value = value
            result.all.return_value = []
            call_count += 1
            return result

        # Simulate: 5 products, 2 price drops, 3 new jobs, 1 match, 10 crawls
        mock_db.execute = AsyncMock(
            side_effect=[
                make_result(5),   # total_products
                make_result(2),   # price_drops
                make_result(3),   # new_jobs
                make_result(1),   # match_count
                make_result(7),   # product_crawls
                make_result(3),   # job_crawls
            ]
        )

        kpi = await service.calculate_user_kpi(user_id=1)
        assert kpi.total_products == 5
        assert kpi.price_drops_today == 2
        assert kpi.new_jobs_today == 3
        assert kpi.match_count == 1
        assert kpi.crawl_count_today == 10


# --- API Tests ---


class TestDashboardAPI:
    """Test dashboard API endpoints."""

    @pytest.mark.asyncio
    async def test_get_dashboard_kpi_unauthorized(self, async_client):
        """Unauthenticated request returns 401."""
        resp = await async_client.get("/dashboard/kpi")
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_trends_unauthorized(self, async_client):
        """Unauthenticated trend request returns 401."""
        resp = await async_client.get("/dashboard/trends?type=price&days=7")
        assert resp.status_code == 401
