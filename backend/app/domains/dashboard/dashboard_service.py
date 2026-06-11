"""Dashboard KPI aggregation service."""
from __future__ import annotations

import asyncio
import json
from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING, Any

import psutil
from sqlalchemy import case, func, select

from app.core.json_utils import safe_json_dumps
from app.models.alert import Alert
from app.models.crawl_log import CrawlLog
from app.models.job_crawl_log import JobCrawlLog
from app.models.job_match import MatchResult
from app.models.price_history import PriceHistory
from app.models.product import Product
from app.models.user import User
from app.schemas.dashboard import (
    SystemKPI,
    TrendDataPoint,
    TrendDataset,
    TrendResponse,
    UserKPI,
)
from app.utils.time import today_start_utc

if TYPE_CHECKING:
    import redis.asyncio as redis
    from sqlalchemy.ext.asyncio import AsyncSession


class DashboardService:
    """Service for aggregating dashboard KPI data."""

    # User KPI is cached longer than the SSE poll interval (30 s) so that
    # repeated polls within the same window always hit cache instead of
    # running 6 parallel DB queries every cycle.
    USER_KPI_CACHE_TTL = 60
    # System KPI changes even more slowly; 2-minute cache is fine.
    SYSTEM_KPI_CACHE_TTL = 120
    TREND_CACHE_TTL = 300

    def __init__(
        self, db: AsyncSession, redis_client: redis.Redis | None = None
    ) -> None:
        self.db = db
        self.redis = redis_client

    async def calculate_user_kpi(self, user_id: int) -> UserKPI:
        """Calculate personal KPI metrics for a user."""
        return await self._cached_or_compute(
            f"dashboard:kpi:user:{user_id}",
            lambda: self._calculate_user_kpi_uncached(user_id),
            UserKPI,
            self.USER_KPI_CACHE_TTL,
        )

    async def _cached_or_compute(self, key: str, factory, schema_cls, ttl: int):
        """Generic cache-or-compute: return cached model_validate(hit) or factory() result."""
        cached = await self._get_cached(key)
        if cached is not None:
            return schema_cls.model_validate(cached)
        result = await factory()
        await self._set_cached(key, result.model_dump(), ttl)
        return result

    async def _get_cached(self, key: str) -> Any | None:
        """Read and deserialize a JSON value from Redis."""
        if self.redis is None:
            return None

        try:
            raw_value = await self.redis.get(key)
            if raw_value is None:
                return None
            if isinstance(raw_value, bytes):
                raw_value = raw_value.decode("utf-8")
            return json.loads(raw_value)
        except Exception:
            return None

    async def _set_cached(self, key: str, value: Any, ttl: int) -> None:
        """Serialize a value as JSON and store it in Redis with a TTL."""
        if self.redis is None:
            return

        try:
            await self.redis.setex(
                key, ttl, safe_json_dumps(value)
            )
        except Exception:
            return

    async def _calculate_user_kpi_uncached(self, user_id: int) -> UserKPI:
        """Calculate personal KPI metrics for a user."""
        today_start = today_start_utc()

        # Total products
        product_count_q = select(func.count()).select_from(Product).where(
            Product.user_id == user_id
        )

        user_product_ids_q = select(Product.id).where(Product.user_id == user_id)

        # Price drops today: single CTE scan with conditional aggregation.
        # The previous approach used two separate window-function subqueries joined
        # together, which required two full PriceHistory scans.  This version does
        # one pass: for each product keep the MIN scraped_at per day bucket, then
        # compare today-bucket price vs previous-bucket price in one aggregation.
        ranked_cte = (
            select(
                PriceHistory.product_id.label("product_id"),
                PriceHistory.price.label("price"),
                case(
                    (PriceHistory.scraped_at >= today_start, 1),
                    else_=0,
                ).label("is_today"),
                func.row_number()
                .over(
                    partition_by=[
                        PriceHistory.product_id,
                        case(
                            (PriceHistory.scraped_at >= today_start, 1),
                            else_=0,
                        ),
                    ],
                    order_by=PriceHistory.scraped_at.desc(),
                )
                .label("rn"),
            )
            .where(PriceHistory.product_id.in_(user_product_ids_q))
            .cte("ranked_prices")
        )

        today_price_col = func.max(
            case((ranked_cte.c.is_today == 1, ranked_cte.c.price), else_=None)
        )
        prev_price_col = func.max(
            case((ranked_cte.c.is_today == 0, ranked_cte.c.price), else_=None)
        )

        price_drops_q = (
            select(func.count())
            .select_from(
                select(
                    ranked_cte.c.product_id,
                    today_price_col.label("today_price"),
                    prev_price_col.label("prev_price"),
                )
                .where(ranked_cte.c.rn == 1)
                .group_by(ranked_cte.c.product_id)
                .having(
                    today_price_col.isnot(None),
                    prev_price_col.isnot(None),
                    today_price_col < prev_price_col,
                )
                .subquery()
            )
        )

        # New jobs today
        from app.models.job import Job, JobSearchConfig

        new_jobs_q = (
            select(func.count())
            .select_from(Job)
            .join(JobSearchConfig, Job.search_config_id == JobSearchConfig.id)
            .where(
                JobSearchConfig.user_id == user_id,
                Job.first_seen_at >= today_start,
            )
        )

        # Match count today
        match_q = (
            select(func.count())
            .select_from(MatchResult)
            .where(
                MatchResult.user_id == user_id,
                MatchResult.created_at >= today_start,
            )
        )

        # Crawl counts today (parallel)
        product_crawls_q = (
            select(func.count())
            .select_from(CrawlLog)
            .where(CrawlLog.timestamp >= today_start)
        )
        job_crawls_q = (
            select(func.count())
            .select_from(JobCrawlLog)
            .where(JobCrawlLog.scraped_at >= today_start)
        )

        # Execute all counts in parallel (N+1 optimization)
        results = await asyncio.gather(
            self.db.execute(product_count_q),
            self.db.execute(price_drops_q),
            self.db.execute(new_jobs_q),
            self.db.execute(match_q),
            self.db.execute(product_crawls_q),
            self.db.execute(job_crawls_q),
        )

        total_products = results[0].scalar_one() or 0
        price_drops_today = results[1].scalar_one() or 0
        new_jobs_today = results[2].scalar_one() or 0
        match_count = results[3].scalar_one() or 0
        product_crawls = results[4].scalar_one() or 0
        job_crawls = results[5].scalar_one() or 0
        crawl_count_today = product_crawls + job_crawls

        return UserKPI(
            total_products=total_products,
            price_drops_today=price_drops_today,
            new_jobs_today=new_jobs_today,
            match_count=match_count,
            crawl_count_today=crawl_count_today,
        )

    async def calculate_system_kpi(self) -> SystemKPI:
        """Calculate system-level KPI metrics."""
        return await self._cached_or_compute(
            "dashboard:kpi:system",
            self._calculate_system_kpi_uncached,
            SystemKPI,
            self.SYSTEM_KPI_CACHE_TTL,
        )

    async def _calculate_system_kpi_uncached(self) -> SystemKPI:
        """Calculate system-level KPI metrics."""
        today_start = today_start_utc()

        # Total users
        users_result = await self.db.execute(
            select(func.count()).select_from(User)
        )
        total_users = users_result.scalar_one() or 0

        # Total crawls today — parallel
        product_crawls_q = (
            select(func.count())
            .select_from(CrawlLog)
            .where(CrawlLog.timestamp >= today_start)
        )
        job_crawls_q = (
            select(func.count())
            .select_from(JobCrawlLog)
            .where(JobCrawlLog.scraped_at >= today_start)
        )
        pc_result, jc_result = await asyncio.gather(
            self.db.execute(product_crawls_q),
            self.db.execute(job_crawls_q),
        )
        total_crawls = (pc_result.scalar_one() or 0) + (
            jc_result.scalar_one() or 0
        )

        # Success rate today — parallel
        product_success_q = (
            select(func.count())
            .select_from(CrawlLog)
            .where(
                CrawlLog.timestamp >= today_start,
                CrawlLog.status == "SUCCESS",
            )
        )
        job_success_q = (
            select(func.count())
            .select_from(JobCrawlLog)
            .where(
                JobCrawlLog.scraped_at >= today_start,
                JobCrawlLog.status == "SUCCESS",
            )
        )
        ps_result, js_result = await asyncio.gather(
            self.db.execute(product_success_q),
            self.db.execute(job_success_q),
        )
        total_success = (ps_result.scalar_one() or 0) + (
            js_result.scalar_one() or 0
        )
        success_rate = total_success / total_crawls if total_crawls > 0 else 1.0

        # Active alerts
        alerts_result = await self.db.execute(
            select(func.count()).select_from(Alert).where(Alert.active == True)  # noqa: E712
        )
        active_alerts = alerts_result.scalar_one() or 0

        # System resource usage
        try:
            disk_usage = psutil.disk_usage("/").percent / 100.0
            memory_usage = psutil.virtual_memory().percent / 100.0
        except Exception:
            disk_usage = 0.0
            memory_usage = 0.0

        return SystemKPI(
            total_users=total_users,
            total_crawls=total_crawls,
            success_rate=round(success_rate, 2),
            active_alerts=active_alerts,
            disk_usage=round(disk_usage, 2),
            memory_usage=round(memory_usage, 2),
        )

    async def get_price_trends(self, user_id: int, days: int) -> TrendResponse:
        """Get price trend data for the last N days."""
        return await self._get_cached_trend(
            f"dashboard:{user_id}:price:{days}",
            lambda: self._get_price_trends_uncached(user_id, days),
        )

    async def _get_price_trends_uncached(
        self, user_id: int, days: int
    ) -> TrendResponse:
        """Get price trend data for the last N days."""
        from sqlalchemy import Date, cast

        start_date = datetime.now(UTC) - timedelta(days=days)

        result = await self.db.execute(
            select(
                cast(PriceHistory.scraped_at, Date).label("date"),
                func.avg(PriceHistory.price).label("avg_price"),
                func.count().label("count"),
            )
            .join(Product, PriceHistory.product_id == Product.id)
            .where(
                Product.user_id == user_id,
                PriceHistory.scraped_at >= start_date,
            )
            .group_by(cast(PriceHistory.scraped_at, Date))
            .order_by(cast(PriceHistory.scraped_at, Date))
        )

        labels = []
        avg_prices = []
        for row in result.all():
            labels.append(str(row.date))
            avg_prices.append(float(row.avg_price) if row.avg_price else 0.0)

        return TrendResponse(
            labels=labels,
            datasets=[
                TrendDataset(
                    label="平均价格",
                    data=[
                        TrendDataPoint(label=label, value=value)
                        for label, value in zip(labels, avg_prices)
                    ],
                )
            ],
        )

    async def get_price_change_trends(
        self, user_id: int, days: int
    ) -> TrendResponse:
        """Get average price change percentage trend data."""
        return await self._get_cached_trend(
            f"dashboard:{user_id}:price_change:{days}",
            lambda: self._get_price_change_trends_uncached(user_id, days),
        )

    async def _get_price_change_trends_uncached(
        self, user_id: int, days: int
    ) -> TrendResponse:
        """Get average price change percentage trend data using SQL window functions."""
        start_date = datetime.now(UTC) - timedelta(days=days)

        sub = (
            select(
                PriceHistory.price,
                PriceHistory.scraped_at,
                func.lag(PriceHistory.price).over(
                    partition_by=PriceHistory.product_id,
                    order_by=PriceHistory.scraped_at,
                ).label("prev_price"),
            )
            .join(Product, PriceHistory.product_id == Product.id)
            .where(
                Product.user_id == user_id,
                PriceHistory.scraped_at >= start_date,
            )
            .subquery()
        )

        change_expr = ((sub.c.price - sub.c.prev_price) / sub.c.prev_price) * 100

        stmt = (
            select(
                func.date(sub.c.scraped_at).label("label"),
                func.avg(change_expr).label("avg_change"),
            )
            .where(
                sub.c.prev_price.isnot(None),
                sub.c.prev_price > 0,
            )
            .group_by(func.date(sub.c.scraped_at))
            .order_by(func.date(sub.c.scraped_at))
        )

        result = await self.db.execute(stmt)
        rows = result.all()
        labels = [str(row.label) for row in rows]
        values = [round(float(row.avg_change or 0), 2) for row in rows]

        return TrendResponse(
            labels=labels,
            datasets=[
                TrendDataset(
                    label="平均价格变化率(%)",
                    data=[
                        TrendDataPoint(label=label, value=value)
                        for label, value in zip(labels, values)
                    ],
                )
            ],
        )

    async def get_job_trends(self, user_id: int, days: int) -> TrendResponse:
        """Get job posting trend data for the last N days."""
        return await self._get_cached_trend(
            f"dashboard:{user_id}:jobs:{days}",
            lambda: self._get_job_trends_uncached(user_id, days),
        )

    async def _get_job_trends_uncached(
        self, user_id: int, days: int
    ) -> TrendResponse:
        """Get job posting trend data for the last N days."""
        from sqlalchemy import Date, cast

        from app.models.job import Job, JobSearchConfig

        start_date = datetime.now(UTC) - timedelta(days=days)

        result = await self.db.execute(
            select(
                cast(Job.first_seen_at, Date).label("date"),
                func.count().label("count"),
            )
            .join(JobSearchConfig, Job.search_config_id == JobSearchConfig.id)
            .where(
                JobSearchConfig.user_id == user_id,
                Job.first_seen_at >= start_date,
            )
            .group_by(cast(Job.first_seen_at, Date))
            .order_by(cast(Job.first_seen_at, Date))
        )

        labels = []
        counts = []
        for row in result.all():
            labels.append(str(row.date))
            counts.append(row.count or 0)

        return TrendResponse(
            labels=labels,
            datasets=[
                TrendDataset(
                    label="新增职位",
                    data=[
                        TrendDataPoint(label=label, value=value)
                        for label, value in zip(labels, counts)
                    ],
                )
            ],
        )

    async def get_job_match_trends(
        self, user_id: int, days: int
    ) -> TrendResponse:
        """Get job match count and average score trend data."""
        return await self._get_cached_trend(
            f"dashboard:{user_id}:job_match:{days}",
            lambda: self._get_job_match_trends_uncached(user_id, days),
        )

    async def _get_job_match_trends_uncached(
        self, user_id: int, days: int
    ) -> TrendResponse:
        """Get job match count and average score trend data."""
        start_date = datetime.now(UTC) - timedelta(days=days)
        match_date = func.date(MatchResult.created_at)

        result = await self.db.execute(
            select(
                match_date.label("date"),
                func.count().label("count"),
                func.avg(MatchResult.match_score).label("avg_score"),
            )
            .where(
                MatchResult.user_id == user_id,
                MatchResult.created_at >= start_date,
            )
            .group_by(match_date)
            .order_by(match_date)
        )

        labels = []
        counts = []
        avg_scores = []
        for row in result.all():
            labels.append(str(row.date))
            counts.append(row.count or 0)
            avg_scores.append(round(float(row.avg_score or 0), 2))

        return TrendResponse(
            labels=labels,
            datasets=[
                TrendDataset(
                    label="匹配次数",
                    data=[
                        TrendDataPoint(label=label, value=value)
                        for label, value in zip(labels, counts)
                    ],
                ),
                TrendDataset(
                    label="平均匹配分",
                    data=[
                        TrendDataPoint(label=label, value=value)
                        for label, value in zip(labels, avg_scores)
                    ],
                ),
            ],
        )

    async def get_platform_distribution(
        self, user_id: int, entity: str
    ) -> TrendResponse:
        """Get platform distribution for products or jobs."""
        return await self._get_cached_trend(
            f"dashboard:{user_id}:platform_{entity}:0",
            lambda: self._get_platform_distribution_uncached(user_id, entity),
        )

    async def _get_platform_distribution_uncached(
        self, user_id: int, entity: str
    ) -> TrendResponse:
        """Get platform distribution for products or jobs."""
        if entity == "products":
            result = await self.db.execute(
                select(Product.platform, func.count())
                .where(Product.user_id == user_id)
                .group_by(Product.platform)
            )
        elif entity == "jobs":
            from app.models.job import Job, JobSearchConfig

            result = await self.db.execute(
                select(JobSearchConfig.platform, func.count())
                .select_from(JobSearchConfig)
                .join(Job, Job.search_config_id == JobSearchConfig.id)
                .where(JobSearchConfig.user_id == user_id)
                .group_by(JobSearchConfig.platform)
            )
        else:
            return TrendResponse(labels=[], datasets=[])

        labels = []
        counts = []
        for row in result.all():
            labels.append(row[0])
            counts.append(row[1] or 0)

        return TrendResponse(
            labels=labels,
            datasets=[
                TrendDataset(
                    label="数量",
                    data=[
                        TrendDataPoint(label=label, value=value)
                        for label, value in zip(labels, counts)
                    ],
                )
            ],
        )

    async def get_salary_distribution(self, user_id: int) -> TrendResponse:
        """Get salary range distribution for jobs."""
        return await self._get_cached_trend(
            f"dashboard:{user_id}:salary:0",
            lambda: self._get_salary_distribution_uncached(user_id),
        )

    async def _get_salary_distribution_uncached(
        self, user_id: int
    ) -> TrendResponse:
        """Get salary range distribution for jobs."""
        from app.models.job import Job, JobSearchConfig

        ranges = [
            (0, 5000),
            (5000, 10000),
            (10000, 15000),
            (15000, 20000),
            (20000, float("inf")),
        ]
        range_labels = ["0-5k", "5-10k", "10-15k", "15-20k", "20k+"]
        queries = []
        for min_val, max_val in ranges:
            if max_val == float("inf"):
                query = select(func.count()).where(Job.salary_min >= min_val)
            else:
                query = select(func.count()).where(
                    Job.salary_min >= min_val,
                    Job.salary_min < max_val,
                )
            query = query.select_from(Job).join(
                JobSearchConfig, Job.search_config_id == JobSearchConfig.id
            ).where(JobSearchConfig.user_id == user_id)
            queries.append(query)

        results = await asyncio.gather(*(self.db.execute(q) for q in queries))
        counts = [r.scalar_one() or 0 for r in results]

        return TrendResponse(
            labels=range_labels,
            datasets=[
                TrendDataset(
                    label="职位数量",
                    data=[
                        TrendDataPoint(label=label, value=value)
                        for label, value in zip(range_labels, counts)
                    ],
                )
            ],
        )

    async def get_system_health_trends(
        self, user_id: int, days: int
    ) -> TrendResponse:
        """Get system health trend (success rate over time)."""
        return await self._get_cached_trend(
            f"dashboard:{user_id}:system_health:{days}",
            lambda: self._get_system_health_trends_uncached(days),
        )

    async def _get_system_health_trends_uncached(
        self, days: int
    ) -> TrendResponse:
        """Get system health trend (success rate over time)."""
        from sqlalchemy import Date, case, cast

        start_date = datetime.now(UTC) - timedelta(days=days)

        result = await self.db.execute(
            select(
                cast(CrawlLog.timestamp, Date).label("date"),
                func.count().label("total"),
                func.sum(
                    case((CrawlLog.status == "SUCCESS", 1), else_=0)
                ).label("success"),
            )
            .where(CrawlLog.timestamp >= start_date)
            .group_by(cast(CrawlLog.timestamp, Date))
            .order_by(cast(CrawlLog.timestamp, Date))
        )

        labels = []
        success_rates = []
        for row in result.all():
            labels.append(str(row.date))
            rate = (row.success or 0) / row.total if row.total > 0 else 1.0
            success_rates.append(round(rate, 2))

        return TrendResponse(
            labels=labels,
            datasets=[
                TrendDataset(
                    label="成功率",
                    data=[
                        TrendDataPoint(label=label, value=value)
                        for label, value in zip(labels, success_rates)
                    ],
                )
            ],
        )

    async def get_crawl_failure_trends(self, days: int) -> TrendResponse:
        """Get product and job crawl failure trend data."""
        return await self._get_cached_trend(
            f"dashboard:system:crawl_failure:{days}",
            lambda: self._get_crawl_failure_trends_uncached(days),
        )

    async def _get_crawl_failure_trends_uncached(
        self, days: int
    ) -> TrendResponse:
        """Get product and job crawl failure trend data."""
        start_date = datetime.now(UTC) - timedelta(days=days)
        product_date = func.date(CrawlLog.timestamp)
        job_date = func.date(JobCrawlLog.scraped_at)

        product_stmt = (
            select(
                product_date.label("date"),
                func.count().label("count"),
            )
            .where(
                CrawlLog.timestamp >= start_date,
                CrawlLog.status != "SUCCESS",
            )
            .group_by(product_date)
            .order_by(product_date)
        )
        job_stmt = (
            select(
                job_date.label("date"),
                func.count().label("count"),
            )
            .where(
                JobCrawlLog.scraped_at >= start_date,
                JobCrawlLog.status != "SUCCESS",
            )
            .group_by(job_date)
            .order_by(job_date)
        )
        product_result, job_result = await asyncio.gather(
            self.db.execute(product_stmt),
            self.db.execute(job_stmt),
        )

        product_counts = {
            str(row.date): row.count or 0 for row in product_result.all()
        }
        job_counts = {str(row.date): row.count or 0 for row in job_result.all()}
        labels = sorted(set(product_counts) | set(job_counts))

        return TrendResponse(
            labels=labels,
            datasets=[
                TrendDataset(
                    label="商品爬取失败",
                    data=[
                        TrendDataPoint(
                            label=label, value=product_counts.get(label, 0)
                        )
                        for label in labels
                    ],
                ),
                TrendDataset(
                    label="职位爬取失败",
                    data=[
                        TrendDataPoint(label=label, value=job_counts.get(label, 0))
                        for label in labels
                    ],
                ),
            ],
        )

    async def get_platform_success_rates(self, user_id: int) -> TrendResponse:
        """Get success rate per platform."""
        return await self._get_cached_trend(
            f"dashboard:{user_id}:platform_success:0",
            self._get_platform_success_rates_uncached,
        )

    async def _get_cached_trend(self, key: str, factory) -> TrendResponse:
        return await self._cached_or_compute(key, factory, TrendResponse, self.TREND_CACHE_TTL)

    async def _get_platform_success_rates_uncached(self) -> TrendResponse:
        """Get success rate per platform."""
        # Product platforms
        result = await self.db.execute(
            select(
                CrawlLog.platform,
                func.count().label("total"),
                func.sum(
                    case((CrawlLog.status == "SUCCESS", 1), else_=0)
                ).label("success"),
            )
            .where(CrawlLog.platform.isnot(None))
            .group_by(CrawlLog.platform)
        )

        labels = []
        rates = []
        for row in result.all():
            labels.append(row.platform)
            rate = (row.success or 0) / row.total if row.total > 0 else 1.0
            rates.append(round(rate, 2))

        # Job platforms (join through JobSearchConfig)
        from app.models.job import JobSearchConfig

        job_result = await self.db.execute(
            select(
                JobSearchConfig.platform,
                func.count().label("total"),
                func.sum(
                    case((JobCrawlLog.status == "SUCCESS", 1), else_=0)
                ).label("success"),
            )
            .select_from(JobCrawlLog)
            .join(JobSearchConfig, JobCrawlLog.search_config_id == JobSearchConfig.id)
            .where(JobSearchConfig.platform.isnot(None))
            .group_by(JobSearchConfig.platform)
        )

        for row in job_result.all():
            labels.append(row.platform)
            rate = (row.success or 0) / row.total if row.total > 0 else 1.0
            rates.append(round(rate, 2))

        return TrendResponse(
            labels=labels,
            datasets=[
                TrendDataset(
                    label="成功率",
                    data=[
                        TrendDataPoint(label=label, value=value)
                        for label, value in zip(labels, rates)
                    ],
                )
            ],
        )
