"""Tests for dashboard service and API."""
import asyncio
import json
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from importlib import import_module
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.security import get_current_user
from app.database import get_db
from app.domains.dashboard.service import list_recent_alerts
from app.main import app
from app.schemas.dashboard import RecentAlert, SystemKPI, TrendResponse, UserKPI


def _make_user(user_id: int = 1, role: str = "user"):
    user = MagicMock()
    user.id = user_id
    user.username = f"user{user_id}"
    user.email = f"user{user_id}@example.com"
    user.role = role
    user.is_active = True
    user.deleted_at = None
    user.created_at = datetime.now(UTC)
    user.updated_at = datetime.now(UTC)
    return user


def _make_alert(
    *,
    alert_id: int = 1,
    product_id: int | None = 10,
    alert_type: str = "price_drop",
    active: bool = True,
    created_at: datetime | None = None,
    product_title: str | None = "Test Product",
    platform: str | None = "jd",
):
    alert = MagicMock()
    alert.id = alert_id
    alert.product_id = product_id
    alert.alert_type = alert_type
    alert.threshold_percent = None
    alert.last_notified_at = None
    alert.last_notified_price = None
    alert.active = active
    alert.created_at = created_at or datetime.now(UTC)
    alert.updated_at = datetime.now(UTC)
    if product_id is not None:
        product = MagicMock()
        product.title = product_title
        product.platform = platform
        alert.product = product
    else:
        alert.product = None
    return alert


# --- Service Tests ---


class TestDashboardService:
    """Test dashboard KPI aggregation."""

    class FakeRedis:
        def __init__(self, initial=None, *, fail_get=False, fail_set=False):
            self.store = dict(initial or {})
            self.fail_get = fail_get
            self.fail_set = fail_set
            self.get_calls: list[str] = []
            self.setex_calls: list[tuple[str, int, str]] = []

        async def get(self, key):
            self.get_calls.append(key)
            if self.fail_get:
                raise RuntimeError("redis get failed")
            return self.store.get(key)

        async def setex(self, key, ttl, value):
            self.setex_calls.append((key, ttl, value))
            if self.fail_set:
                raise RuntimeError("redis set failed")
            self.store[key] = value

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
        from app.domains.dashboard.dashboard_service import DashboardService

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

    @pytest.mark.asyncio
    async def test_calculate_user_kpi_cache_hit_skips_database(self, mock_db):
        """Cached user KPI is returned without hitting the database."""
        from app.domains.dashboard.dashboard_service import DashboardService

        cached = {
            "total_products": 9,
            "price_drops_today": 2,
            "new_jobs_today": 3,
            "match_count": 4,
            "crawl_count_today": 5,
        }
        redis = self.FakeRedis({"dashboard:kpi:user:7": json.dumps(cached)})
        mock_db.execute = AsyncMock(side_effect=AssertionError("database should not be queried"))

        kpi = await DashboardService(mock_db, redis).calculate_user_kpi(user_id=7)

        assert kpi == UserKPI(**cached)
        assert redis.get_calls == ["dashboard:kpi:user:7"]
        mock_db.execute.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_calculate_user_kpi_cache_miss_computes_and_stores(self, mock_db):
        """User KPI cache miss computes from DB and stores JSON with a short TTL."""
        from app.domains.dashboard.dashboard_service import DashboardService

        def make_result(value):
            result = MagicMock()
            result.scalar_one.return_value = value
            return result

        mock_db.execute = AsyncMock(
            side_effect=[
                make_result(5),
                make_result(1),
                make_result(2),
                make_result(3),
                make_result(4),
                make_result(6),
            ]
        )
        redis = self.FakeRedis()

        kpi = await DashboardService(mock_db, redis).calculate_user_kpi(user_id=3)

        assert kpi.total_products == 5
        assert kpi.price_drops_today == 1
        assert kpi.new_jobs_today == 2
        assert kpi.match_count == 3
        assert kpi.crawl_count_today == 10
        assert redis.setex_calls == [
            (
                "dashboard:kpi:user:3",
                DashboardService.USER_KPI_CACHE_TTL,
                json.dumps(kpi.model_dump(), ensure_ascii=False),
            )
        ]

    @pytest.mark.asyncio
    async def test_calculate_user_kpi_redis_failure_falls_back_to_database(self, mock_db):
        """Redis errors are swallowed so KPI can still be calculated from DB."""
        from app.domains.dashboard.dashboard_service import DashboardService

        def make_result(value):
            result = MagicMock()
            result.scalar_one.return_value = value
            return result

        mock_db.execute = AsyncMock(side_effect=[make_result(0) for _ in range(6)])
        redis = self.FakeRedis(fail_get=True, fail_set=True)

        kpi = await DashboardService(mock_db, redis).calculate_user_kpi(user_id=4)

        assert kpi == UserKPI(
            total_products=0,
            price_drops_today=0,
            new_jobs_today=0,
            match_count=0,
            crawl_count_today=0,
        )
        assert mock_db.execute.await_count == 6

    @pytest.mark.asyncio
    async def test_calculate_user_kpi_cache_keys_are_scoped_by_user(self, mock_db):
        """Different users read different KPI cache keys."""
        from app.domains.dashboard.dashboard_service import DashboardService

        redis = self.FakeRedis(
            {
                "dashboard:kpi:user:1": json.dumps(
                    {
                        "total_products": 1,
                        "price_drops_today": 0,
                        "new_jobs_today": 0,
                        "match_count": 0,
                        "crawl_count_today": 0,
                    }
                ),
                "dashboard:kpi:user:2": json.dumps(
                    {
                        "total_products": 2,
                        "price_drops_today": 0,
                        "new_jobs_today": 0,
                        "match_count": 0,
                        "crawl_count_today": 0,
                    }
                ),
            }
        )
        mock_db.execute = AsyncMock(side_effect=AssertionError("database should not be queried"))
        service = DashboardService(mock_db, redis)

        first = await service.calculate_user_kpi(user_id=1)
        second = await service.calculate_user_kpi(user_id=2)

        assert first.total_products == 1
        assert second.total_products == 2
        assert redis.get_calls == ["dashboard:kpi:user:1", "dashboard:kpi:user:2"]
        mock_db.execute.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_calculate_user_kpi_counts_only_actual_price_drops_today(self):
        """price_drops_today counts products whose latest price fell today."""
        from app.domains.dashboard.dashboard_service import DashboardService
        from app.models import (
            Base,
            CrawlLog,
            Job,
            JobCrawlLog,
            JobSearchConfig,
            MatchResult,
            PriceHistory,
            Product,
            User,
        )

        class AsyncSessionAdapter:
            def __init__(self, sync_session):
                self.sync_session = sync_session

            async def execute(self, statement):
                return self.sync_session.execute(statement)

        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(
            engine,
            tables=[
                User.__table__,
                Product.__table__,
                PriceHistory.__table__,
                JobSearchConfig.__table__,
                Job.__table__,
                MatchResult.__table__,
                CrawlLog.__table__,
                JobCrawlLog.__table__,
            ],
        )

        session_maker = sessionmaker(engine, expire_on_commit=False)
        now = datetime.now(UTC)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        yesterday = today_start - timedelta(hours=1)
        today_early = today_start + timedelta(hours=1)
        today_late = today_start + timedelta(hours=2)

        with session_maker() as db:
            db.add(
                User(
                    id=1,
                    username="dashboard-user",
                    email="dashboard@example.com",
                    hashed_password="hashed",
                )
            )
            products = [
                Product(id=i, user_id=1, platform="jd", url=f"https://example.com/{i}")
                for i in range(1, 6)
            ]
            db.add_all(products)
            db.add_all(
                [
                    # Actual drop: latest today 80 < latest before today 100.
                    PriceHistory(product_id=1, price=Decimal("100.00"), scraped_at=yesterday),
                    PriceHistory(product_id=1, price=Decimal("90.00"), scraped_at=today_early),
                    PriceHistory(product_id=1, price=Decimal("80.00"), scraped_at=today_late),
                    # Went up today, should not count.
                    PriceHistory(product_id=2, price=Decimal("100.00"), scraped_at=yesterday),
                    PriceHistory(product_id=2, price=Decimal("110.00"), scraped_at=today_late),
                    # Same price today, should not count.
                    PriceHistory(product_id=3, price=Decimal("100.00"), scraped_at=yesterday),
                    PriceHistory(product_id=3, price=Decimal("100.00"), scraped_at=today_late),
                    # First observation today, should not count.
                    PriceHistory(product_id=4, price=Decimal("50.00"), scraped_at=today_late),
                    # No observation today, should not count.
                    PriceHistory(product_id=5, price=Decimal("100.00"), scraped_at=yesterday),
                ]
            )
            db.commit()

            kpi = await DashboardService(AsyncSessionAdapter(db)).calculate_user_kpi(
                user_id=1
            )

        engine.dispose()

        assert kpi.total_products == 5
        assert kpi.price_drops_today == 1

    @pytest.mark.asyncio
    async def test_price_change_trends_are_user_scoped_and_ignore_zero_previous_price(self):
        """Price-change trends average only current user's comparable product prices."""
        from app.domains.dashboard.dashboard_service import DashboardService
        from app.models import Base, PriceHistory, Product, User

        class AsyncSessionAdapter:
            def __init__(self, sync_session):
                self.sync_session = sync_session

            async def execute(self, statement):
                return self.sync_session.execute(statement)

        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(
            engine,
            tables=[User.__table__, Product.__table__, PriceHistory.__table__],
        )

        session_maker = sessionmaker(engine, expire_on_commit=False)
        now = datetime.now(UTC)
        day_one = (now - timedelta(days=2)).replace(hour=9, minute=0, second=0, microsecond=0)
        day_two = day_one + timedelta(days=1)
        day_three = day_two + timedelta(days=1)

        with session_maker() as db:
            db.add_all(
                [
                    User(id=1, username="user-one", email="one@example.com", hashed_password="hash"),
                    User(id=2, username="user-two", email="two@example.com", hashed_password="hash"),
                ]
            )
            db.add_all(
                [
                    Product(id=1, user_id=1, platform="jd", url="https://example.com/1"),
                    Product(id=2, user_id=1, platform="jd", url="https://example.com/2"),
                    Product(id=3, user_id=2, platform="jd", url="https://example.com/3"),
                ]
            )
            db.add_all(
                [
                    PriceHistory(product_id=1, price=Decimal("100.00"), scraped_at=day_one),
                    PriceHistory(product_id=1, price=Decimal("90.00"), scraped_at=day_two),
                    PriceHistory(product_id=1, price=Decimal("99.00"), scraped_at=day_three),
                    # Previous zero would divide by zero, so product 2 is ignored for day_two.
                    PriceHistory(product_id=2, price=Decimal("0.00"), scraped_at=day_one),
                    PriceHistory(product_id=2, price=Decimal("20.00"), scraped_at=day_two),
                    # Other user's price movement must not affect user 1's average.
                    PriceHistory(product_id=3, price=Decimal("100.00"), scraped_at=day_one),
                    PriceHistory(product_id=3, price=Decimal("200.00"), scraped_at=day_two),
                ]
            )
            db.commit()

            trend = await DashboardService(AsyncSessionAdapter(db)).get_price_change_trends(
                user_id=1,
                days=7,
            )

        engine.dispose()

        assert isinstance(trend, TrendResponse)
        assert trend.labels == [str(day_two.date()), str(day_three.date())]
        assert trend.datasets[0].label == "平均价格变化率(%)"
        assert [point.value for point in trend.datasets[0].data] == [-10.0, 10.0]

    @pytest.mark.asyncio
    async def test_job_match_trends_count_and_average_score_are_user_scoped(self):
        """Job-match trends return count and average score datasets for the user."""
        from app.domains.dashboard.dashboard_service import DashboardService
        from app.models import Base, Job, JobSearchConfig, MatchResult, User, UserResume

        class AsyncSessionAdapter:
            def __init__(self, sync_session):
                self.sync_session = sync_session

            async def execute(self, statement):
                return self.sync_session.execute(statement)

        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(
            engine,
            tables=[
                User.__table__,
                JobSearchConfig.__table__,
                Job.__table__,
                UserResume.__table__,
                MatchResult.__table__,
            ],
        )

        session_maker = sessionmaker(engine, expire_on_commit=False)
        now = datetime.now(UTC)
        match_day = (now - timedelta(days=1)).replace(hour=10, minute=0, second=0, microsecond=0)

        with session_maker() as db:
            db.add_all(
                [
                    User(id=1, username="user-one", email="one@example.com", hashed_password="hash"),
                    User(id=2, username="user-two", email="two@example.com", hashed_password="hash"),
                ]
            )
            db.add_all(
                [
                    JobSearchConfig(id=1, user_id=1, platform="boss", name="u1", url="https://jobs/1"),
                    JobSearchConfig(id=2, user_id=2, platform="boss", name="u2", url="https://jobs/2"),
                ]
            )
            db.add_all(
                [
                    Job(id=1, job_id="u1-a", search_config_id=1),
                    Job(id=2, job_id="u1-b", search_config_id=1),
                    Job(id=3, job_id="u2-a", search_config_id=2),
                ]
            )
            db.add_all(
                [
                    UserResume(id=1, user_id=1, name="resume1", resume_text="python"),
                    UserResume(id=2, user_id=2, name="resume2", resume_text="java"),
                ]
            )
            db.add_all(
                [
                    MatchResult(user_id=1, resume_id=1, job_id=1, match_score=80, created_at=match_day),
                    MatchResult(user_id=1, resume_id=1, job_id=2, match_score=90, created_at=match_day),
                    MatchResult(user_id=2, resume_id=2, job_id=3, match_score=10, created_at=match_day),
                ]
            )
            db.commit()

            trend = await DashboardService(AsyncSessionAdapter(db)).get_job_match_trends(
                user_id=1,
                days=7,
            )

        engine.dispose()

        assert isinstance(trend, TrendResponse)
        assert trend.labels == [str(match_day.date())]
        assert [dataset.label for dataset in trend.datasets] == ["匹配次数", "平均匹配分"]
        assert trend.datasets[0].data[0].value == 2
        assert trend.datasets[1].data[0].value == 85.0

    @pytest.mark.asyncio
    async def test_crawl_failure_trends_count_product_and_job_failures(self):
        """Crawl-failure trends return product and job failure counts by day."""
        from app.domains.dashboard.dashboard_service import DashboardService
        from app.models import Base, CrawlLog, JobCrawlLog, JobSearchConfig, User

        class AsyncSessionAdapter:
            def __init__(self, sync_session):
                self.sync_session = sync_session

            async def execute(self, statement):
                return self.sync_session.execute(statement)

        engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(
            engine,
            tables=[User.__table__, JobSearchConfig.__table__, CrawlLog.__table__, JobCrawlLog.__table__],
        )

        session_maker = sessionmaker(engine, expire_on_commit=False)
        now = datetime.now(UTC)
        failure_day = (now - timedelta(days=1)).replace(hour=11, minute=0, second=0, microsecond=0)

        with session_maker() as db:
            db.add(User(id=1, username="admin", email="admin@example.com", hashed_password="hash"))
            db.add(JobSearchConfig(id=1, user_id=1, platform="boss", name="jobs", url="https://jobs"))
            db.add_all(
                [
                    CrawlLog(platform="jd", status="ERROR", timestamp=failure_day),
                    CrawlLog(platform="jd", status="SUCCESS", timestamp=failure_day),
                    JobCrawlLog(search_config_id=1, status="ERROR", scraped_at=failure_day),
                    JobCrawlLog(search_config_id=1, status="SUCCESS", scraped_at=failure_day),
                ]
            )
            db.commit()

            trend = await DashboardService(AsyncSessionAdapter(db)).get_crawl_failure_trends(days=7)

        engine.dispose()

        assert isinstance(trend, TrendResponse)
        assert trend.labels == [str(failure_day.date())]
        assert [dataset.label for dataset in trend.datasets] == ["商品爬取失败", "职位爬取失败"]
        assert trend.datasets[0].data[0].value == 1
        assert trend.datasets[1].data[0].value == 1

    @pytest.mark.asyncio
    async def test_new_trend_methods_return_stable_empty_arrays(self, service):
        """New trend methods keep the existing empty TrendResponse shape."""
        for trend in [
            await service.get_price_change_trends(user_id=1, days=7),
            await service.get_job_match_trends(user_id=1, days=7),
            await service.get_crawl_failure_trends(days=7),
        ]:
            assert isinstance(trend, TrendResponse)
            assert trend.labels == []
            assert all(dataset.data == [] for dataset in trend.datasets)

    @pytest.mark.asyncio
    async def test_list_recent_alerts_includes_product_context(self):
        """Recent alerts include product title and platform when available."""
        alert = _make_alert()

        class _Repo:
            @staticmethod
            async def list_recent_alerts(db, *, limit, include_product_context=False):
                return [alert]

        from app.domains.dashboard import service as dashboard_service

        original_repository = dashboard_service.repository
        dashboard_service.repository = _Repo()
        try:
            rows = await list_recent_alerts(AsyncMock(), limit=10)
        finally:
            dashboard_service.repository = original_repository

        assert len(rows) == 1
        row = rows[0]
        assert isinstance(RecentAlert.model_validate(row), RecentAlert)
        assert row["id"] == 1
        assert row["product_title"] == "Test Product"
        assert row["platform"] == "jd"
        assert row["created_at"] == alert.created_at.isoformat()

    @pytest.mark.asyncio
    async def test_list_recent_alerts_omits_product_context_when_no_product(self):
        """Alerts without product still validate and keep nullable fields empty."""
        alert = _make_alert(product_id=None, product_title=None, platform=None)

        class _Repo:
            @staticmethod
            async def list_recent_alerts(db, *, limit, include_product_context=False):
                return [alert]

        from app.domains.dashboard import service as dashboard_service

        original_repository = dashboard_service.repository
        dashboard_service.repository = _Repo()
        try:
            rows = await list_recent_alerts(AsyncMock(), limit=10)
        finally:
            dashboard_service.repository = original_repository

        assert rows[0]["product_id"] is None
        assert rows[0]["product_title"] is None
        assert rows[0]["platform"] is None


# --- API Tests ---


class TestDashboardAPI:
    """Test dashboard API endpoints."""

    @pytest.mark.asyncio
    async def test_get_dashboard_kpi_unauthorized(self, async_client):
        """Unauthenticated request returns 401."""
        resp = await async_client.get("/api/v1/dashboard/kpi")
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_trends_unauthorized(self, async_client):
        """Unauthenticated trend request returns 401."""
        resp = await async_client.get("/api/v1/dashboard/trends?type=price&days=7")
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_get_new_trend_types_return_valid_response(self, monkeypatch):
        """New trend query types are accepted and return TrendResponse payloads."""
        dashboard_router = import_module("app.domains.dashboard.router")

        seen_calls: list[tuple[str, int, int | None]] = []

        class FakeDashboardService:
            def __init__(self, db, redis_client=None):
                pass

            async def get_price_change_trends(self, user_id, days):
                seen_calls.append(("price_change", days, user_id))
                return TrendResponse(labels=[], datasets=[])

            async def get_job_match_trends(self, user_id, days):
                seen_calls.append(("job_matches", days, user_id))
                return TrendResponse(labels=[], datasets=[])

            async def get_crawl_failure_trends(self, days):
                seen_calls.append(("crawl_failures", days, None))
                return TrendResponse(labels=[], datasets=[])

        async def _override_user():
            return _make_user(user_id=7, role="admin")

        async def _override_db():
            yield AsyncMock()

        monkeypatch.setattr(dashboard_router, "DashboardService", FakeDashboardService)
        app.dependency_overrides[get_current_user] = _override_user
        app.dependency_overrides[get_db] = _override_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                responses = [
                    await client.get("/api/v1/dashboard/trends?type=price_change&days=3"),
                    await client.get("/api/v1/dashboard/trends?type=job_matches&days=3"),
                    await client.get("/api/v1/dashboard/trends?type=crawl_failures&days=3"),
                ]
            assert [response.status_code for response in responses] == [200, 200, 200]
            assert [response.json() for response in responses] == [
                {"labels": [], "datasets": []},
                {"labels": [], "datasets": []},
                {"labels": [], "datasets": []},
            ]
            assert seen_calls == [
                ("price_change", 3, 7),
                ("job_matches", 3, 7),
                ("crawl_failures", 3, None),
            ]
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_crawl_failures_trend_rejects_normal_users(self, monkeypatch):
        """System-wide crawl failure trend is admin-only."""
        dashboard_router = import_module("app.domains.dashboard.router")

        service = MagicMock()
        service.get_crawl_failure_trends = AsyncMock(return_value=TrendResponse(labels=[], datasets=[]))

        class FakeDashboardService:
            def __init__(self, db, redis_client=None):
                pass

            async def get_crawl_failure_trends(self, days):
                return await service.get_crawl_failure_trends(days)

        async def _override_user():
            return _make_user(role="user")

        async def _override_db():
            yield AsyncMock()

        monkeypatch.setattr(dashboard_router, "DashboardService", FakeDashboardService)
        app.dependency_overrides[get_current_user] = _override_user
        app.dependency_overrides[get_db] = _override_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/dashboard/trends?type=crawl_failures&days=7")
            assert resp.status_code == 403
            service.get_crawl_failure_trends.assert_not_awaited()
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_recent_alerts_forbidden_for_non_admin(self):
        """Non-admin users cannot access recent alerts."""

        async def _override_user():
            return _make_user(role="user")

        async def _override_db():
            yield AsyncMock()

        app.dependency_overrides[get_current_user] = _override_user
        app.dependency_overrides[get_db] = _override_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/dashboard/alerts/recent")
            assert resp.status_code == 403
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_recent_alerts_returns_product_context_for_admin(self):
        """Admin recent alerts include product context fields in the response."""
        alert = _make_alert()
        result = MagicMock()
        result.scalars.return_value.all.return_value = [alert]
        db = AsyncMock()
        db.execute = AsyncMock(return_value=result)

        async def _override_user():
            return _make_user(role="admin")

        async def _override_db():
            yield db

        app.dependency_overrides[get_current_user] = _override_user
        app.dependency_overrides[get_db] = _override_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/dashboard/alerts/recent?limit=2")
            assert resp.status_code == 200
            data = resp.json()
            assert len(data) == 1
            assert data[0]["id"] == 1
            assert data[0]["product_title"] == "Test Product"
            assert data[0]["platform"] == "jd"
            assert data[0]["created_at"] == alert.created_at.isoformat()
        finally:
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_recent_alerts_limit_parameter_is_forwarded(self):
        """The limit query parameter is passed through to the service layer."""
        seen_limits: list[int] = []

        async def _fake_list_recent_alerts(db, *, limit):
            seen_limits.append(limit)
            return []

        from app.domains.dashboard import service as dashboard_service

        original = dashboard_service.list_recent_alerts
        dashboard_service.list_recent_alerts = _fake_list_recent_alerts

        async def _override_user():
            return _make_user(role="admin")

        async def _override_db():
            yield AsyncMock()

        app.dependency_overrides[get_current_user] = _override_user
        app.dependency_overrides[get_db] = _override_db
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/dashboard/alerts/recent?limit=2")
            assert resp.status_code == 200
            assert seen_limits == [2]
        finally:
            dashboard_service.list_recent_alerts = original
            app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_admin_sse_pushes_when_only_system_kpi_changes(self, monkeypatch):
        """Admin SSE compares user and system KPI payloads for changes."""
        from app.models.user import User

        dashboard_router = import_module("app.domains.dashboard.router")

        class FakeRequest:
            async def is_disconnected(self):
                return False

        class FakeDashboardService:
            system_total_users = 0

            def __init__(self, db, redis_client=None):
                pass

            async def calculate_user_kpi(self, user_id):
                return UserKPI(
                    total_products=1,
                    price_drops_today=0,
                    new_jobs_today=0,
                    match_count=0,
                    crawl_count_today=0,
                )

            async def calculate_system_kpi(self):
                self.__class__.system_total_users += 1
                return SystemKPI(
                    total_users=self.__class__.system_total_users,
                    total_crawls=0,
                    success_rate=1.0,
                    active_alerts=0,
                    disk_usage=0.0,
                    memory_usage=0.0,
                )

        async def cancel_sleep(seconds):
            raise asyncio.CancelledError

        dashboard_router._last_kpi_values.clear()
        monkeypatch.setattr(dashboard_router, "DashboardService", FakeDashboardService)
        monkeypatch.setattr(dashboard_router.asyncio, "sleep", cancel_sleep)

        response = await dashboard_router.stream_dashboard_events(
            request=FakeRequest(),
            current_user=User(
                id=1,
                username="admin",
                email="admin@example.com",
                role="admin",
            ),
            db=object(),
        )
        stream = response.body_iterator

        initial_chunk = await anext(stream)
        changed_chunk = await anext(stream)

        assert '"total_users": 1' in initial_chunk
        assert '"total_users": 2' in changed_chunk
