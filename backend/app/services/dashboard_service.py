"""Dashboard KPI aggregation service."""
from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING

import psutil
from sqlalchemy import case, func, select

from app.models.alert import Alert
from app.models.crawl_log import CrawlLog
from app.models.job_crawl_log import JobCrawlLog
from app.models.job_match import MatchResult
from app.models.price_history import PriceHistory
from app.models.product import Product
from app.models.user import User
from app.schemas.dashboard import (
    DashboardKPIResponse,
    SystemKPI,
    TrendDataset,
    TrendDataPoint,
    TrendResponse,
    UserKPI,
)

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

    import redis.asyncio as redis


class DashboardService:
    """Service for aggregating dashboard KPI data."""

    def __init__(
        self, db: AsyncSession, redis_client: redis.Redis | None = None
    ) -> None:
        self.db = db
        self.redis = redis_client

    async def calculate_user_kpi(self, user_id: int) -> UserKPI:
        """Calculate personal KPI metrics for a user."""
        today_start = datetime.now(UTC).replace(
            hour=0, minute=0, second=0, microsecond=0
        )

        # Total products — N+1 optimized: parallel COUNT queries
        product_count_q = select(func.count()).select_from(Product).where(
            Product.user_id == user_id
        )

        # Price drops today: products with price_history today
        price_drops_q = (
            select(func.count())
            .select_from(PriceHistory)
            .where(
                PriceHistory.product_id.in_(
                    select(Product.id).where(Product.user_id == user_id)
                ),
                PriceHistory.scraped_at >= today_start,
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
            .where(MatchResult.created_at >= today_start)
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
        today_start = datetime.now(UTC).replace(
            hour=0, minute=0, second=0, microsecond=0
        )

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
                        TrendDataPoint(label=l, value=v)
                        for l, v in zip(labels, avg_prices)
                    ],
                )
            ],
        )

    async def get_job_trends(self, user_id: int, days: int) -> TrendResponse:
        """Get job posting trend data for the last N days."""
        from app.models.job import Job, JobSearchConfig
        from sqlalchemy import Date, cast

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
                        TrendDataPoint(label=l, value=v)
                        for l, v in zip(labels, counts)
                    ],
                )
            ],
        )

    async def get_platform_distribution(
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
                        TrendDataPoint(label=l, value=v)
                        for l, v in zip(labels, counts)
                    ],
                )
            ],
        )

    async def get_salary_distribution(self, user_id: int) -> TrendResponse:
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
        counts = []

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

            result = await self.db.execute(query)
            counts.append(result.scalar_one() or 0)

        return TrendResponse(
            labels=range_labels,
            datasets=[
                TrendDataset(
                    label="职位数量",
                    data=[
                        TrendDataPoint(label=l, value=v)
                        for l, v in zip(range_labels, counts)
                    ],
                )
            ],
        )

    async def get_system_health_trends(self, days: int) -> TrendResponse:
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
                        TrendDataPoint(label=l, value=v)
                        for l, v in zip(labels, success_rates)
                    ],
                )
            ],
        )

    async def get_platform_success_rates(self) -> TrendResponse:
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
                        TrendDataPoint(label=l, value=v)
                        for l, v in zip(labels, rates)
                    ],
                )
            ],
        )
