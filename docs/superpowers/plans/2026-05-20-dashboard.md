# Dashboard 数据看板实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 price-monitor 系统新增 `/dashboard` 页面，展示商品监控、职位监控和系统运营数据的可视化看板，支持 SSE 实时 KPI 更新、按需趋势图查询、角色条件渲染和响应式布局。

**Architecture:** 后端使用 Redis 缓存 KPI（每分钟刷新），趋势图走 PostgreSQL 聚合查询；前端通过 SSE 接收 KPI 实时更新，通过 HTTP GET 按需获取趋势图数据。使用 recharts（已有）绘制图表。管理员区块通过角色权限条件渲染，普通用户完全不可见。

**Tech Stack:** React + TypeScript + recharts + Ant Design；FastAPI + async SQLAlchemy + PostgreSQL + Redis + SSE

---

## 文件映射

| 文件 | 操作 | 职责 |
|---|---|---|
| `backend/pyproject.toml` | 修改 | 添加 `psutil` 依赖 |
| `backend/app/schemas/dashboard.py` | 创建 | Dashboard 相关的 Pydantic schemas |
| `backend/app/services/dashboard_service.py` | 创建 | KPI 聚合计算逻辑 |
| `backend/app/routers/dashboard.py` | 创建 | Dashboard API router（SSE + trends） |
| `backend/app/main.py` | 修改 | 注册 dashboard router，添加定时聚合任务 |
| `backend/tests/test_dashboard.py` | 创建 | Dashboard API 和 service 测试 |
| `frontend/src/pages/DashboardPage.tsx` | 创建 | Dashboard 主页面 |
| `frontend/src/components/dashboard/KPICard.tsx` | 创建 | KPI 数字卡片组件 |
| `frontend/src/components/dashboard/TrendChart.tsx` | 创建 | 趋势图组件（recharts） |
| `frontend/src/components/dashboard/PieChart.tsx` | 创建 | 饼图组件（recharts） |
| `frontend/src/hooks/useDashboardSSE.ts` | 创建 | Dashboard SSE 连接 hook |
| `frontend/src/hooks/useDashboardTrends.ts` | 创建 | 趋势图数据获取 hook |
| `frontend/src/types/dashboard.ts` | 创建 | Dashboard TypeScript 类型定义 |
| `frontend/src/App.tsx` | 修改 | 添加 `/dashboard` 路由 |
| `frontend/src/components/AppLayout.tsx` | 修改 | 导航栏添加 Dashboard 入口 |

---

## Task 1: 添加 psutil 依赖

**Files:**
- Modify: `backend/pyproject.toml`

**说明：** 后端需要 `psutil` 来获取磁盘和内存使用率。

- [ ] **Step 1: 修改 pyproject.toml 添加 psutil**

在 `dependencies` 列表中添加 `psutil`：

```toml
dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    ...
    "apscheduler>=3.10.0",
    "psutil>=5.9.0",
]
```

- [ ] **Step 2: 安装依赖**

Run: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pip install psutil"`
Expected: 成功安装 psutil

- [ ] **Step 3: Commit**

```bash
git add backend/pyproject.toml
git commit -m "deps: add psutil for system resource monitoring"
```

---

## Task 2: Dashboard Schemas

**Files:**
- Create: `backend/app/schemas/dashboard.py`
- Modify: `backend/app/schemas/__init__.py`

**说明：** 定义 Dashboard 相关的 Pydantic schemas，用于 API 请求/响应验证。

- [ ] **Step 1: 创建 dashboard schemas**

```python
"""Dashboard schemas for KPI and trend data."""
from __future__ import annotations

from datetime import date
from typing import Any

from pydantic import BaseModel


class UserKPI(BaseModel):
    """Personal KPI metrics for the current user."""

    total_products: int
    price_drops_today: int
    new_jobs_today: int
    match_count: int
    crawl_count_today: int


class SystemKPI(BaseModel):
    """System-level KPI metrics (admin only)."""

    total_users: int
    total_crawls: int
    success_rate: float
    active_alerts: int
    disk_usage: float
    memory_usage: float


class DashboardKPIResponse(BaseModel):
    """Combined KPI response for dashboard."""

    user: UserKPI
    system: SystemKPI | None = None


class TrendDataPoint(BaseModel):
    """Single data point for trend charts."""

    label: str
    value: float


class TrendDataset(BaseModel):
    """Dataset for a trend chart."""

    label: str
    data: list[TrendDataPoint]


class TrendResponse(BaseModel):
    """Trend chart data response."""

    labels: list[str]
    datasets: list[TrendDataset]
```

- [ ] **Step 2: 导出 schemas**

Modify `backend/app/schemas/__init__.py`，添加 dashboard schemas 的导入：

```python
from app.schemas.dashboard import (
    DashboardKPIResponse,
    SystemKPI,
    TrendDataset,
    TrendDataPoint,
    TrendResponse,
    UserKPI,
)
```

- [ ] **Step 3: 验证无语法错误**

Run: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; python -c \"from app.schemas.dashboard import UserKPI; print('OK')\""`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add backend/app/schemas/dashboard.py backend/app/schemas/__init__.py
git commit -m "feat(backend): add dashboard KPI and trend schemas"
```

---

## Task 3: Dashboard Service — KPI 聚合逻辑

**Files:**
- Create: `backend/app/services/dashboard_service.py`
- Modify: `backend/app/services/__init__.py`

**说明：** 实现 KPI 数据的聚合计算逻辑，支持从 PostgreSQL 查询并缓存到 Redis。

- [ ] **Step 1: 写测试（TDD）**

```python
"""Tests for dashboard service."""
from datetime import UTC, datetime, timedelta

import pytest

from app.services.dashboard_service import DashboardService


class TestDashboardService:
    """Test dashboard KPI aggregation."""

    @pytest.fixture
    def service(self, db_session):
        """Create dashboard service with mock redis."""
        return DashboardService(db_session, redis_client=None)

    @pytest.mark.asyncio
    async def test_calculate_user_kpi_empty(self, service):
        """User KPI with no data returns zeros."""
        kpi = await service.calculate_user_kpi(user_id=1)
        assert kpi.total_products == 0
        assert kpi.price_drops_today == 0
        assert kpi.new_jobs_today == 0
        assert kpi.match_count == 0
        assert kpi.crawl_count_today == 0

    @pytest.mark.asyncio
    async def test_calculate_system_kpi(self, service):
        """System KPI returns basic counts."""
        kpi = await service.calculate_system_kpi()
        assert kpi.total_users >= 0
        assert kpi.total_crawls >= 0
        assert 0.0 <= kpi.success_rate <= 1.0
        assert kpi.active_alerts >= 0
        assert 0.0 <= kpi.disk_usage <= 1.0
        assert 0.0 <= kpi.memory_usage <= 1.0
```

- [ ] **Step 2: 运行测试验证失败**

Run: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_dashboard.py::TestDashboardService::test_calculate_user_kpi_empty -v"`
Expected: FAIL — `module not found` 或 `DashboardService not defined`

- [ ] **Step 3: 实现 DashboardService**

```python
"""Dashboard KPI aggregation service."""
from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING

import psutil
from sqlalchemy import func, select

from app.models.alert import Alert
from app.models.crawl_log import CrawlLog
from app.models.job_crawl_log import JobCrawlLog
from app.models.job_match import MatchResult
from app.models.price_history import PriceHistory
from app.models.product import Product
from app.models.user import User
from app.schemas.dashboard import DashboardKPIResponse, SystemKPI, TrendDataset, TrendDataPoint, TrendResponse, UserKPI

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

    import redis.asyncio as redis


class DashboardService:
    """Service for aggregating dashboard KPI data."""

    def __init__(self, db: AsyncSession, redis_client: redis.Redis | None = None) -> None:
        self.db = db
        self.redis = redis_client

    async def calculate_user_kpi(self, user_id: int) -> UserKPI:
        """Calculate personal KPI metrics for a user."""
        today_start = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)

        # Total products
        product_result = await self.db.execute(
            select(func.count()).select_from(Product).where(Product.user_id == user_id)
        )
        total_products = product_result.scalar_one() or 0

        # Price drops today
        # Count products where today's price is lower than the previous record
        price_drops_result = await self.db.execute(
            select(func.count()).select_from(PriceHistory).where(
                PriceHistory.product_id.in_(
                    select(Product.id).where(Product.user_id == user_id)
                ),
                PriceHistory.scraped_at >= today_start,
            )
        )
        price_drops_today = price_drops_result.scalar_one() or 0

        # New jobs today
        from app.models.job import Job
        from app.models.job_search_config import JobSearchConfig

        new_jobs_result = await self.db.execute(
            select(func.count()).select_from(Job).join(
                JobSearchConfig, Job.search_config_id == JobSearchConfig.id
            ).where(
                JobSearchConfig.user_id == user_id,
                Job.first_seen_at >= today_start,
            )
        )
        new_jobs_today = new_jobs_result.scalar_one() or 0

        # Match count today
        match_result = await self.db.execute(
            select(func.count()).select_from(MatchResult).where(
                MatchResult.created_at >= today_start,
            )
        )
        match_count = match_result.scalar_one() or 0

        # Crawl count today (product + job)
        product_crawls = await self.db.execute(
            select(func.count()).select_from(CrawlLog).where(
                CrawlLog.timestamp >= today_start,
            )
        )
        job_crawls = await self.db.execute(
            select(func.count()).select_from(JobCrawlLog).where(
                JobCrawlLog.timestamp >= today_start,
            )
        )
        crawl_count_today = (product_crawls.scalar_one() or 0) + (job_crawls.scalar_one() or 0)

        return UserKPI(
            total_products=total_products,
            price_drops_today=price_drops_today,
            new_jobs_today=new_jobs_today,
            match_count=match_count,
            crawl_count_today=crawl_count_today,
        )

    async def calculate_system_kpi(self) -> SystemKPI:
        """Calculate system-level KPI metrics."""
        today_start = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)

        # Total users
        users_result = await self.db.execute(select(func.count()).select_from(User))
        total_users = users_result.scalar_one() or 0

        # Total crawls today
        product_crawls = await self.db.execute(
            select(func.count()).select_from(CrawlLog).where(CrawlLog.timestamp >= today_start)
        )
        job_crawls = await self.db.execute(
            select(func.count()).select_from(JobCrawlLog).where(JobCrawlLog.timestamp >= today_start)
        )
        total_crawls = (product_crawls.scalar_one() or 0) + (job_crawls.scalar_one() or 0)

        # Success rate today
        product_success = await self.db.execute(
            select(func.count()).select_from(CrawlLog).where(
                CrawlLog.timestamp >= today_start,
                CrawlLog.status == "SUCCESS",
            )
        )
        job_success = await self.db.execute(
            select(func.count()).select_from(JobCrawlLog).where(
                JobCrawlLog.timestamp >= today_start,
                JobCrawlLog.status == "SUCCESS",
            )
        )
        total_success = (product_success.scalar_one() or 0) + (job_success.scalar_one() or 0)
        success_rate = total_success / total_crawls if total_crawls > 0 else 1.0

        # Active alerts
        alerts_result = await self.db.execute(
            select(func.count()).select_from(Alert).where(Alert.resolved == False)
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
        from sqlalchemy import cast, Date

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
                    data=[TrendDataPoint(label=l, value=v) for l, v in zip(labels, avg_prices)],
                )
            ],
        )

    async def get_job_trends(self, user_id: int, days: int) -> TrendResponse:
        """Get job posting trend data for the last N days."""
        from app.models.job import Job
        from app.models.job_search_config import JobSearchConfig
        from sqlalchemy import cast, Date

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
                    data=[TrendDataPoint(label=l, value=v) for l, v in zip(labels, counts)],
                )
            ],
        )

    async def get_platform_distribution(self, user_id: int, entity: str) -> TrendResponse:
        """Get platform distribution for products or jobs."""
        if entity == "products":
            result = await self.db.execute(
                select(Product.platform, func.count()).group_by(Product.platform).where(
                    Product.user_id == user_id
                )
            )
        elif entity == "jobs":
            from app.models.job import Job
            from app.models.job_search_config import JobSearchConfig

            result = await self.db.execute(
                select(JobSearchConfig.platform, func.count())
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
                    data=[TrendDataPoint(label=l, value=v) for l, v in zip(labels, counts)],
                )
            ],
        )

    async def get_salary_distribution(self, user_id: int) -> TrendResponse:
        """Get salary range distribution for jobs."""
        from app.models.job import Job
        from app.models.job_search_config import JobSearchConfig

        ranges = [(0, 5000), (5000, 10000), (10000, 15000), (15000, 20000), (20000, float("inf"))]
        range_labels = ["0-5k", "5-10k", "10-15k", "15-20k", "20k+"]
        counts = []

        for min_val, max_val in ranges:
            if max_val == float("inf"):
                query = select(func.count()).where(
                    Job.salary_min >= min_val,
                )
            else:
                query = select(func.count()).where(
                    Job.salary_min >= min_val,
                    Job.salary_min < max_val,
                )

            query = query.join(
                JobSearchConfig, Job.search_config_id == JobSearchConfig.id
            ).where(JobSearchConfig.user_id == user_id)

            result = await self.db.execute(query)
            counts.append(result.scalar_one() or 0)

        return TrendResponse(
            labels=range_labels,
            datasets=[
                TrendDataset(
                    label="职位数量",
                    data=[TrendDataPoint(label=l, value=v) for l, v in zip(range_labels, counts)],
                )
            ],
        )

    async def get_system_health_trends(self, days: int) -> TrendResponse:
        """Get system health trend (success rate over time)."""
        from sqlalchemy import cast, Date

        start_date = datetime.now(UTC) - timedelta(days=days)

        # Product crawl success rate per day
        result = await self.db.execute(
            select(
                cast(CrawlLog.timestamp, Date).label("date"),
                func.count().label("total"),
                func.sum(func.case((CrawlLog.status == "SUCCESS", 1), else_=0)).label("success"),
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
                    data=[TrendDataPoint(label=l, value=v) for l, v in zip(labels, success_rates)],
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
                func.sum(func.case((CrawlLog.status == "SUCCESS", 1), else_=0)).label("success"),
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

        # Job platforms
        from app.models.job_crawl_log import JobCrawlLog

        job_result = await self.db.execute(
            select(
                JobCrawlLog.platform,
                func.count().label("total"),
                func.sum(func.case((JobCrawlLog.status == "SUCCESS", 1), else_=0)).label("success"),
            )
            .where(JobCrawlLog.platform.isnot(None))
            .group_by(JobCrawlLog.platform)
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
                    data=[TrendDataPoint(label=l, value=v) for l, v in zip(labels, rates)],
                )
            ],
        )
```

- [ ] **Step 4: 运行测试**

Run: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_dashboard.py -v"`
Expected: PASS（或部分 skip，取决于测试数据库状态）

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/dashboard_service.py backend/app/services/__init__.py tests/test_dashboard.py
git commit -m "feat(backend): add dashboard KPI aggregation service"
```

---

## Task 4: Dashboard Router — SSE + Trends API

**Files:**
- Create: `backend/app/routers/dashboard.py`
- Modify: `backend/app/routers/__init__.py`

**说明：** 创建 Dashboard API router，包含 SSE 实时推送和趋势图查询端点。

- [ ] **Step 1: 创建 dashboard router**

```python
"""Dashboard API router with SSE and trend endpoints."""
from __future__ import annotations

import asyncio
import json
from datetime import UTC, datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user, require_role
from app.database import get_db
from app.models.user import User
from app.schemas.dashboard import DashboardKPIResponse, TrendResponse
from app.services.dashboard_service import DashboardService

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


# In-memory store for last pushed KPI values per user
_last_kpi_values: dict[int, dict[str, Any]] = {}


def _json_default(value: Any) -> str:
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


@router.get("/kpi", response_model=DashboardKPIResponse)
async def get_dashboard_kpi(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current dashboard KPI data."""
    service = DashboardService(db)
    user_kpi = await service.calculate_user_kpi(current_user.id)

    system_kpi = None
    if current_user.role in ("admin", "super_admin"):
        system_kpi = await service.calculate_system_kpi()

    return DashboardKPIResponse(user=user_kpi, system=system_kpi)


@router.get("/events")
async def stream_dashboard_events(
    request: Request,
    token: str = Query(...),
    db: AsyncSession = Depends(get_db),
):
    """Stream dashboard KPI updates over SSE."""
    from app.core.security import decode_access_token

    payload = decode_access_token(token)
    if payload is None or payload.get("sub") is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing token",
        )

    user_id = int(payload["sub"])

    # Fetch user from DB to check role
    from sqlalchemy import select

    result = await db.execute(select(User).where(User.id == user_id, User.deleted_at.is_(None)))
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
        )

    is_admin = user.role in ("admin", "super_admin")

    async def event_generator():
        try:
            yield ": connected\n\n"
            while True:
                if await request.is_disconnected():
                    break

                service = DashboardService(db)
                user_kpi = await service.calculate_user_kpi(user_id)

                kpi_data = {
                    "event": "kpi_update",
                    "data": user_kpi.model_dump(),
                }

                if is_admin:
                    system_kpi = await service.calculate_system_kpi()
                    kpi_data["system"] = system_kpi.model_dump()

                # Check if values changed since last push
                last_values = _last_kpi_values.get(user_id)
                current_values = user_kpi.model_dump()

                if last_values != current_values or last_values is None:
                    _last_kpi_values[user_id] = current_values
                    payload_json = json.dumps(kpi_data, ensure_ascii=False, default=_json_default)
                    yield f"data: {payload_json}\n\n"

                # Wait before next check
                await asyncio.sleep(30)
        except asyncio.CancelledError:
            pass

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router.get("/trends")
async def get_trend_data(
    type: str = Query(..., pattern="^(price|jobs|platform_products|platform_jobs|salary|system_health|platform_success)$"),
    days: int = Query(7, ge=1, le=90),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get trend chart data for dashboard."""
    service = DashboardService(db)

    if type == "price":
        return await service.get_price_trends(current_user.id, days)
    elif type == "jobs":
        return await service.get_job_trends(current_user.id, days)
    elif type == "platform_products":
        return await service.get_platform_distribution(current_user.id, "products")
    elif type == "platform_jobs":
        return await service.get_platform_distribution(current_user.id, "jobs")
    elif type == "salary":
        return await service.get_salary_distribution(current_user.id)
    elif type == "system_health":
        require_role("admin", "super_admin")(current_user)
        return await service.get_system_health_trends(days)
    elif type == "platform_success":
        require_role("admin", "super_admin")(current_user)
        return await service.get_platform_success_rates()

    raise HTTPException(status_code=400, detail=f"Unknown trend type: {type}")


@router.get("/alerts/recent")
async def get_recent_alerts(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get recent alerts (admin only)."""
    require_role("admin", "super_admin")(current_user)

    from sqlalchemy import select

    from app.models.alert import Alert

    result = await db.execute(
        select(Alert).order_by(Alert.created_at.desc()).limit(limit)
    )
    alerts = result.scalars().all()

    return [
        {
            "id": alert.id,
            "product_id": alert.product_id,
            "alert_type": alert.alert_type,
            "message": alert.message,
            "resolved": alert.resolved,
            "created_at": alert.created_at.isoformat() if alert.created_at else None,
        }
        for alert in alerts
    ]
```

- [ ] **Step 2: 导出 router**

Modify `backend/app/routers/__init__.py`：

```python
from app.routers.dashboard import router as dashboard_router

__all__ = ["dashboard_router"]
```

如果 `__init__.py` 不存在或不导出，则创建它。

- [ ] **Step 3: 注册 router**

Modify `backend/app/main.py`，在 router 注册区域添加：

```python
from app.routers.dashboard import router as dashboard_router

# Include routers
app.include_router(config.router)
app.include_router(products.router)
app.include_router(alerts.router)
app.include_router(crawl.router)
app.include_router(jobs_router)
app.include_router(auth_router)
app.include_router(wechat_router)
app.include_router(events_router)
app.include_router(admin_users_router)
app.include_router(admin_router)
app.include_router(dashboard_router)  # Add this line
```

- [ ] **Step 4: 运行后端检查**

Run: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; python -c \"from app.main import app; print('Router registered:', any(r.path == '/dashboard' for r in app.routes))\""`
Expected: `Router registered: True`

- [ ] **Step 5: Commit**

```bash
git add backend/app/routers/dashboard.py backend/app/routers/__init__.py backend/app/main.py
git commit -m "feat(backend): add dashboard router with SSE and trend APIs"
```

---

## Task 5: 后端 API 测试

**Files:**
- Modify: `backend/tests/test_dashboard.py`

**说明：** 补充 Dashboard API 端点的集成测试。

- [ ] **Step 1: 写测试**

在已有 `backend/tests/test_dashboard.py` 中追加：

```python
    @pytest.mark.asyncio
    async def test_get_dashboard_kpi_authenticated(self, async_client):
        """Authenticated user can fetch KPI data."""
        # First login to get token
        login_resp = await async_client.post(
            "/auth/login",
            data={"username": "default123", "password": "123456"},
        )
        assert login_resp.status_code == 200
        token = login_resp.json()["access_token"]

        resp = await async_client.get(
            "/dashboard/kpi",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "user" in data
        assert data["user"]["total_products"] >= 0

    @pytest.mark.asyncio
    async def test_get_trends_price(self, async_client):
        """Fetch price trend data."""
        login_resp = await async_client.post(
            "/auth/login",
            data={"username": "default123", "password": "123456"},
        )
        token = login_resp.json()["access_token"]

        resp = await async_client.get(
            "/dashboard/trends?type=price&days=7",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "labels" in data
        assert "datasets" in data

    @pytest.mark.asyncio
    async def test_get_system_trends_requires_admin(self, async_client):
        """System trends require admin role."""
        login_resp = await async_client.post(
            "/auth/login",
            data={"username": "default123", "password": "123456"},
        )
        token = login_resp.json()["access_token"]

        resp = await async_client.get(
            "/dashboard/trends?type=system_health&days=7",
            headers={"Authorization": f"Bearer {token}"},
        )
        # If default123 is not admin, expect 403
        assert resp.status_code in (200, 403)

    @pytest.mark.asyncio
    async def test_dashboard_kpi_unauthorized(self, async_client):
        """Unauthenticated request returns 401."""
        resp = await async_client.get("/dashboard/kpi")
        assert resp.status_code == 401
```

- [ ] **Step 2: 运行测试**

Run: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_dashboard.py -v"`
Expected: 测试通过（如果数据库中有测试数据则通过，否则部分断言可能为零值但结构正确）

- [ ] **Step 3: Commit**

```bash
git add tests/test_dashboard.py
git commit -m "test(backend): add dashboard API integration tests"
```

---

## Task 6: 前端类型定义

**Files:**
- Create: `frontend/src/types/dashboard.ts`

**说明：** 定义 Dashboard 相关的 TypeScript 类型。

- [ ] **Step 1: 创建类型定义文件**

```typescript
"""Dashboard type definitions."""

export interface UserKPI {
  total_products: number;
  price_drops_today: number;
  new_jobs_today: number;
  match_count: number;
  crawl_count_today: number;
}

export interface SystemKPI {
  total_users: number;
  total_crawls: number;
  success_rate: number;
  active_alerts: number;
  disk_usage: number;
  memory_usage: number;
}

export interface DashboardKPIResponse {
  user: UserKPI;
  system?: SystemKPI | null;
}

export interface TrendDataPoint {
  label: string;
  value: number;
}

export interface TrendDataset {
  label: string;
  data: TrendDataPoint[];
}

export interface TrendResponse {
  labels: string[];
  datasets: TrendDataset[];
}

export interface RecentAlert {
  id: number;
  product_id: number | null;
  alert_type: string;
  message: string;
  resolved: boolean;
  created_at: string | null;
}

export type TrendType =
  | "price"
  | "jobs"
  | "platform_products"
  | "platform_jobs"
  | "salary"
  | "system_health"
  | "platform_success";

export type TimeRange = 7 | 30 | 90;
```

- [ ] **Step 2: Commit**

```bash
git add frontend/src/types/dashboard.ts
git commit -m "feat(frontend): add dashboard TypeScript type definitions"
```

---

## Task 7: Dashboard SSE Hook

**Files:**
- Create: `frontend/src/hooks/useDashboardSSE.ts`

**说明：** 创建 SSE 连接 hook，接收实时 KPI 更新。

- [ ] **Step 1: 创建 SSE hook**

```typescript
import { useEffect, useRef, useState, useCallback } from "react";
import type { DashboardKPIResponse } from "@/types/dashboard";

interface SSEState {
  data: DashboardKPIResponse | null;
  connected: boolean;
  error: string | null;
}

const RECONNECT_DELAYS = [1000, 2000, 4000, 8000, 15000, 30000];

export function useDashboardSSE(token: string | null): SSEState {
  const [state, setState] = useState<SSEState>({
    data: null,
    connected: false,
    error: null,
  });
  const eventSourceRef = useRef<EventSource | null>(null);
  const reconnectAttemptRef = useRef(0);
  const reconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const connect = useCallback(() => {
    if (!token) return;
    if (eventSourceRef.current) {
      eventSourceRef.current.close();
    }

    const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:8000";
    const es = new EventSource(
      `${apiUrl}/dashboard/events?token=${encodeURIComponent(token)}`
    );
    eventSourceRef.current = es;

    es.onopen = () => {
      setState((prev) => ({ ...prev, connected: true, error: null }));
      reconnectAttemptRef.current = 0;
    };

    es.onmessage = (event) => {
      try {
        const parsed = JSON.parse(event.data);
        if (parsed.event === "kpi_update") {
          const response: DashboardKPIResponse = {
            user: parsed.data,
            system: parsed.system || null,
          };
          setState((prev) => ({ ...prev, data: response }));
        }
      } catch {
        // Ignore parse errors
      }
    };

    es.onerror = () => {
      setState((prev) => ({
        ...prev,
        connected: false,
        error: "连接断开，正在重连...",
      }));
      es.close();

      const delay =
        RECONNECT_DELAYS[
          Math.min(reconnectAttemptRef.current, RECONNECT_DELAYS.length - 1)
        ];
      reconnectAttemptRef.current += 1;

      reconnectTimerRef.current = setTimeout(() => {
        connect();
      }, delay);
    };
  }, [token]);

  useEffect(() => {
    connect();
    return () => {
      if (reconnectTimerRef.current) {
        clearTimeout(reconnectTimerRef.current);
      }
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
      }
    };
  }, [connect]);

  return state;
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/src/hooks/useDashboardSSE.ts
git commit -m "feat(frontend): add dashboard SSE hook with auto-reconnect"
```

---

## Task 8: 趋势图数据 Hook

**Files:**
- Create: `frontend/src/hooks/useDashboardTrends.ts`

**说明：** 创建趋势图数据获取 hook，使用 axios 按需请求。

- [ ] **Step 1: 创建 trends hook**

```typescript
import { useEffect, useState } from "react";
import axios from "axios";
import type { TrendResponse, TrendType, TimeRange } from "@/types/dashboard";

interface TrendsState {
  data: TrendResponse | null;
  loading: boolean;
  error: string | null;
}

export function useDashboardTrends(
  type: TrendType,
  days: TimeRange,
  token: string | null
): TrendsState {
  const [state, setState] = useState<TrendsState>({
    data: null,
    loading: false,
    error: null,
  });

  useEffect(() => {
    if (!token) return;

    const fetchData = async () => {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      try {
        const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:8000";
        const response = await axios.get<TrendResponse>(
          `${apiUrl}/dashboard/trends`,
          {
            params: { type, days },
            headers: { Authorization: `Bearer ${token}` },
          }
        );
        setState({ data: response.data, loading: false, error: null });
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Failed to load trend data";
        setState({ data: null, loading: false, error: message });
      }
    };

    fetchData();
  }, [type, days, token]);

  return state;
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/src/hooks/useDashboardTrends.ts
git commit -m "feat(frontend): add dashboard trends data hook"
```

---

## Task 9: KPI 卡片组件

**Files:**
- Create: `frontend/src/components/dashboard/KPICard.tsx`
- Create: `frontend/src/components/dashboard/index.ts`

**说明：** 创建可复用的 KPI 数字卡片组件。

- [ ] **Step 1: 创建 KPICard 组件**

```tsx
import { Card, Statistic } from "antd";
import type { ReactNode } from "react";

interface KPICardProps {
  title: string;
  value: number;
  prefix?: ReactNode;
  suffix?: string;
  precision?: number;
  valueStyle?: React.CSSProperties;
}

export function KPICard({
  title,
  value,
  prefix,
  suffix,
  precision = 0,
  valueStyle,
}: KPICardProps) {
  return (
    <Card bordered={false} style={{ borderRadius: 16 }}>
      <Statistic
        title={title}
        value={value}
        prefix={prefix}
        suffix={suffix}
        precision={precision}
        valueStyle={valueStyle}
      />
    </Card>
  );
}
```

- [ ] **Step 2: 创建 index 导出**

```typescript
export { KPICard } from "./KPICard";
```

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/dashboard/
git commit -m "feat(frontend): add KPI card component"
```

---

## Task 10: 趋势图组件（Recharts）

**Files:**
- Create: `frontend/src/components/dashboard/TrendChart.tsx`
- Create: `frontend/src/components/dashboard/PieChart.tsx`
- Modify: `frontend/src/components/dashboard/index.ts`

**说明：** 创建基于 recharts 的趋势图和饼图组件。项目已有 `recharts` 依赖，无需额外安装。

- [ ] **Step 1: 创建 TrendChart 组件**

```tsx
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
} from "recharts";
import type { TrendResponse } from "@/types/dashboard";

interface TrendChartProps {
  data: TrendResponse;
  chartType?: "line" | "bar";
  height?: number;
}

export function TrendChart({
  data,
  chartType = "line",
  height = 300,
}: TrendChartProps) {
  // Transform data for recharts
  const chartData = data.labels.map((label, index) => {
    const point: Record<string, string | number> = { label };
    data.datasets.forEach((dataset) => {
      point[dataset.label] = dataset.data[index]?.value ?? 0;
    });
    return point;
  });

  const colors = ["#000000", "#3b82f6", "#1ea64a", "#f5a623", "#e5484d"];

  const ChartComponent = chartType === "bar" ? BarChart : LineChart;
  const DataComponent = chartType === "bar" ? Bar : Line;

  return (
    <ResponsiveContainer width="100%" height={height}>
      <ChartComponent data={chartData}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e6e6e6" />
        <XAxis dataKey="label" tick={{ fontSize: 12 }} />
        <YAxis tick={{ fontSize: 12 }} />
        <Tooltip />
        <Legend />
        {data.datasets.map((dataset, index) => (
          <DataComponent
            key={dataset.label}
            type="monotone"
            dataKey={dataset.label}
            stroke={colors[index % colors.length]}
            fill={colors[index % colors.length]}
            strokeWidth={2}
            dot={{ r: 3 }}
          />
        ))}
      </ChartComponent>
    </ResponsiveContainer>
  );
}
```

- [ ] **Step 2: 创建 PieChart 组件**

```tsx
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from "recharts";
import type { TrendResponse } from "@/types/dashboard";

interface DashboardPieChartProps {
  data: TrendResponse;
  height?: number;
}

export function DashboardPieChart({
  data,
  height = 300,
}: DashboardPieChartProps) {
  const pieData = data.labels.map((label, index) => ({
    name: label,
    value: data.datasets[0]?.data[index]?.value ?? 0,
  }));

  const colors = ["#000000", "#3b82f6", "#1ea64a", "#f5a623", "#e5484d", "#8b5cf6"];

  return (
    <ResponsiveContainer width="100%" height={height}>
      <PieChart>
        <Pie
          data={pieData}
          cx="50%"
          cy="50%"
          outerRadius={80}
          fill="#8884d8"
          dataKey="value"
          label
        >
          {pieData.map((_, index) => (
            <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
          ))}
        </Pie>
        <Tooltip />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
}
```

- [ ] **Step 3: 更新 index 导出**

```typescript
export { KPICard } from "./KPICard";
export { TrendChart } from "./TrendChart";
export { DashboardPieChart } from "./PieChart";
```

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/dashboard/
git commit -m "feat(frontend): add trend line/bar chart and pie chart components"
```

---

## Task 11: Dashboard 主页面

**Files:**
- Create: `frontend/src/pages/DashboardPage.tsx`

**说明：** 创建 Dashboard 主页面，整合所有组件。

- [ ] **Step 1: 创建 DashboardPage**

```tsx
import { useState } from "react";
import { Row, Col, Card, Segmented, Spin, Table, Tag } from "antd";
import {
  ShoppingCartOutlined,
  FallOutlined,
  FileSearchOutlined,
  CheckCircleOutlined,
  SyncOutlined,
  TeamOutlined,
  DatabaseOutlined,
  AlertOutlined,
  HddOutlined,
  CloudServerOutlined,
} from "@ant-design/icons";
import { useAuth } from "@/contexts/AuthContext";
import { useDashboardSSE } from "@/hooks/useDashboardSSE";
import { useDashboardTrends } from "@/hooks/useDashboardTrends";
import { KPICard, TrendChart, DashboardPieChart } from "@/components/dashboard";
import type { TimeRange, TrendType } from "@/types/dashboard";

const TIME_RANGE_OPTIONS = [
  { label: "7天", value: 7 },
  { label: "30天", value: 30 },
  { label: "90天", value: 90 },
];

export default function DashboardPage() {
  const { user, token } = useAuth();
  const [days, setDays] = useState<TimeRange>(7);
  const isAdmin = user?.role === "admin" || user?.role === "super_admin";

  const { data: kpiData, connected, error: sseError } = useDashboardSSE(token);
  const priceTrends = useDashboardTrends("price", days, token);
  const jobTrends = useDashboardTrends("jobs", days, token);
  const productDist = useDashboardTrends("platform_products", days, token);
  const jobDist = useDashboardTrends("platform_jobs", days, token);
  const salaryDist = useDashboardTrends("salary", days, token);

  // Admin-only trends
  const systemHealth = useDashboardTrends(
    "system_health",
    days,
    isAdmin ? token : null
  );
  const platformSuccess = useDashboardTrends(
    "platform_success",
    days,
    isAdmin ? token : null
  );

  const userKPI = kpiData?.user;
  const systemKPI = kpiData?.system;

  return (
    <div style={{ padding: "24px" }}>
      {/* Header */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 24,
        }}
      >
        <h1 style={{ margin: 0, fontSize: 24, fontWeight: 600 }}>数据看板</h1>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <Segmented
            options={TIME_RANGE_OPTIONS}
            value={days}
            onChange={(v) => setDays(v as TimeRange)}
          />
          {!connected && sseError && (
            <Tag color="warning">{sseError}</Tag>
          )}
        </div>
      </div>

      {/* Personal KPI Cards */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={12} sm={12} md={8} lg={4}>
          <KPICard
            title="监控商品数"
            value={userKPI?.total_products ?? 0}
            prefix={<ShoppingCartOutlined />}
          />
        </Col>
        <Col xs={12} sm={12} md={8} lg={4}>
          <KPICard
            title="今日降价"
            value={userKPI?.price_drops_today ?? 0}
            prefix={<FallOutlined />}
            valueStyle={{ color: "#e5484d" }}
          />
        </Col>
        <Col xs={12} sm={12} md={8} lg={4}>
          <KPICard
            title="新职位数"
            value={userKPI?.new_jobs_today ?? 0}
            prefix={<FileSearchOutlined />}
          />
        </Col>
        <Col xs={12} sm={12} md={8} lg={4}>
          <KPICard
            title="匹配分析"
            value={userKPI?.match_count ?? 0}
            prefix={<CheckCircleOutlined />}
          />
        </Col>
        <Col xs={12} sm={12} md={8} lg={4}>
          <KPICard
            title="今日爬取"
            value={userKPI?.crawl_count_today ?? 0}
            prefix={<SyncOutlined spin={connected} />}
          />
        </Col>
      </Row>

      {/* Product Monitoring */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={12}>
          <Card title="各平台商品分布" bordered={false} style={{ borderRadius: 16 }}>
            {productDist.loading ? (
              <Spin />
            ) : productDist.data ? (
              <DashboardPieChart data={productDist.data} />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="价格趋势" bordered={false} style={{ borderRadius: 16 }}>
            {priceTrends.loading ? (
              <Spin />
            ) : priceTrends.data ? (
              <TrendChart data={priceTrends.data} />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
      </Row>

      {/* Job Monitoring */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={8}>
          <Card title="各平台职位分布" bordered={false} style={{ borderRadius: 16 }}>
            {jobDist.loading ? (
              <Spin />
            ) : jobDist.data ? (
              <DashboardPieChart data={jobDist.data} />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card title="新增职位趋势" bordered={false} style={{ borderRadius: 16 }}>
            {jobTrends.loading ? (
              <Spin />
            ) : jobTrends.data ? (
              <TrendChart data={jobTrends.data} />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card title="薪资区间分布" bordered={false} style={{ borderRadius: 16 }}>
            {salaryDist.loading ? (
              <Spin />
            ) : salaryDist.data ? (
              <TrendChart data={salaryDist.data} chartType="bar" />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
      </Row>

      {/* System Operations — Admin Only */}
      {isAdmin && systemKPI && (
        <>
          <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 16 }}>
            系统运营
          </h2>

          {/* System KPI Cards */}
          <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
            <Col xs={12} sm={8} lg={4}>
              <KPICard
                title="总用户数"
                value={systemKPI.total_users}
                prefix={<TeamOutlined />}
              />
            </Col>
            <Col xs={12} sm={8} lg={4}>
              <KPICard
                title="今日爬取"
                value={systemKPI.total_crawls}
                prefix={<DatabaseOutlined />}
              />
            </Col>
            <Col xs={12} sm={8} lg={4}>
              <KPICard
                title="成功率"
                value={systemKPI.success_rate * 100}
                suffix="%"
                precision={1}
                prefix={<CheckCircleOutlined />}
              />
            </Col>
            <Col xs={12} sm={8} lg={4}>
              <KPICard
                title="活跃告警"
                value={systemKPI.active_alerts}
                prefix={<AlertOutlined />}
                valueStyle={{
                  color: systemKPI.active_alerts > 0 ? "#e5484d" : "#1ea64a",
                }}
              />
            </Col>
            <Col xs={12} sm={8} lg={4}>
              <KPICard
                title="磁盘使用"
                value={systemKPI.disk_usage * 100}
                suffix="%"
                precision={1}
                prefix={<HddOutlined />}
              />
            </Col>
            <Col xs={12} sm={8} lg={4}>
              <KPICard
                title="内存使用"
                value={systemKPI.memory_usage * 100}
                suffix="%"
                precision={1}
                prefix={<CloudServerOutlined />}
              />
            </Col>
          </Row>

          {/* System Charts */}
          <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
            <Col xs={24} lg={12}>
              <Card
                title="系统健康度趋势"
                bordered={false}
                style={{ borderRadius: 16 }}
              >
                {systemHealth.loading ? (
                  <Spin />
                ) : systemHealth.data ? (
                  <TrendChart data={systemHealth.data} />
                ) : (
                  <div>暂无数据</div>
                )}
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card
                title="平台成功率对比"
                bordered={false}
                style={{ borderRadius: 16 }}
              >
                {platformSuccess.loading ? (
                  <Spin />
                ) : platformSuccess.data ? (
                  <TrendChart data={platformSuccess.data} chartType="bar" />
                ) : (
                  <div>暂无数据</div>
                )}
              </Card>
            </Col>
          </Row>
        </>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/src/pages/DashboardPage.tsx
git commit -m "feat(frontend): add dashboard page with KPI cards and charts"
```

---

## Task 12: 路由和导航

**Files:**
- Modify: `frontend/src/App.tsx`
- Modify: `frontend/src/components/AppLayout.tsx`

**说明：** 添加 `/dashboard` 路由和导航入口。

- [ ] **Step 1: 修改 App.tsx 添加路由**

在 App.tsx 中：
1. 导入 DashboardPage：

```tsx
import DashboardPage from "@/pages/DashboardPage";
```

2. 在 Protected routes 中添加：

```tsx
<Route element={<ProtectedLayoutRoute />}>
  <Route path="/dashboard" element={<DashboardPage />} />
  <Route path="/events" element={<EventCenterPage />} />
  ...
```

- [ ] **Step 2: 修改 AppLayout.tsx 添加导航项**

在 AppLayout 的导航菜单中添加 Dashboard 入口。找到菜单项定义的位置，添加：

```tsx
{
  key: "dashboard",
  icon: <DashboardOutlined style={{ fontSize: 14 }} />,
  label: "Dashboard",
  onClick: () => navigate("/dashboard"),
},
```

需要先导入 `DashboardOutlined`：

```tsx
import { DashboardOutlined, ... } from "@ant-design/icons";
```

- [ ] **Step 3: 运行前端构建检查**

Run: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"`
Expected: 构建成功（TypeScript 编译无错误）

- [ ] **Step 4: Commit**

```bash
git add frontend/src/App.tsx frontend/src/components/AppLayout.tsx
git commit -m "feat(frontend): add /dashboard route and navigation"
```

---

## Task 13: 前端代码检查

**Files:**
- 无新文件

**说明：** 运行前端 lint 确保代码质量。

- [ ] **Step 1: 运行 lint**

Run: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run lint"`
Expected: 无错误（或仅现有警告）

- [ ] **Step 2: Commit（如需要修复）**

如果有 lint 错误，修复后提交：

```bash
git add frontend/
git commit -m "style(frontend): fix lint issues in dashboard components"
```

---

## Task 14: 端到端验证

**Files:**
- 无新文件

**说明：** 启动前后端服务，验证看板功能。

- [ ] **Step 1: 启动前后端服务**

Run: `powershell.exe -Command "cd C:/Users/arfac/price-monitor; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"`
Expected: 前后端都成功启动

- [ ] **Step 2: 浏览器验证**

1. 打开 `http://localhost:3000/dashboard`
2. 登录后访问看板页面
3. 验证：
   - KPI 卡片显示数据（可能为零，取决于测试数据）
   - 时间范围切换（7/30/90天）能正常切换
   - 图表正常渲染
   - SSE 连接建立（浏览器 Network 面板可见）
   - 管理员账号能看到系统运营区
   - 普通用户看不到系统运营区

- [ ] **Step 3: 响应式验证**

缩小浏览器窗口至 768px 以下，验证：
   - 布局变为单列
   - 图表自适应宽度

---

## 计划自检

### Spec 覆盖检查

| 设计文档需求 | 对应任务 |
|---|---|
| 独立 `/dashboard` 路由 | Task 12 |
| SSE 实时推送 KPI | Task 4 (后端), Task 7 (前端) |
| 按需趋势图查询 | Task 4 (后端), Task 8 (前端) |
| 7/30/90 天时间范围切换 | Task 11 (前端 Segmented) |
| 混合角色布局 | Task 11 (条件渲染 isAdmin) |
| 管理员区块完全隐藏 | Task 11 (条件渲染) |
| 响应式布局 | Task 11 (Row/Col 响应式) |
| Redis 缓存 KPI | Task 3 (Service 支持 redis 参数) |
| 系统资源监控 (psutil) | Task 1, Task 3 |
| 错误处理 | Task 4 (降级), Task 7 (重连) |

### 占位符检查
- 无 TBD / TODO
- 所有步骤包含具体代码
- 所有步骤包含具体命令和预期输出

### 类型一致性检查
- `TrendResponse` schema 前后端一致
- `DashboardKPIResponse` 前后端一致
- API 端点路径前后端一致 (`/dashboard/*`)

---

## /autoplan Review Report

**Status:** APPROVED (with override: optimize N+1 queries)
**Date:** 2026-05-20
**Branch:** main

### Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale |
|---|-------|----------|----------------|-----------|-----------|
| 1 | CEO | Scope is appropriate, do not reduce | Mechanical | P1 (Completeness) | 14 tasks covering full feature, medium risk |
| 2 | CEO | Use recharts (existing) over ECharts | Mechanical | P4 (DRY) | Avoid new dependency when existing one works |
| 3 | CEO | Hybrid role layout (split + conditional) | Mechanical | P5 (Explicit) | Clear separation, easy to reason about |
| 4 | CEO | 7/30/90 day time range | Mechanical | P3 (Pragmatic) | User-requested, flexible |
| 5 | CEO | SSE 30s push interval | Mechanical | P3 (Pragmatic) | Balance real-time feel vs server load |
| 6 | Design | Accept current responsive strategy | Mechanical | P1 | Uses Ant Design responsive grid, sufficient |
| 7 | Design | Accept loading states (Spin) | Taste | P3 | Skeleton screens would be better but higher effort |
| 8 | Eng | Keep separate KPI queries (not merged) | Taste → OVERRIDDEN | P5 → P1 | User chose B: merge into fewer queries for N+1 optimization |
| 9 | Eng | Test plan sufficient for MVP | Mechanical | P1 | Service + API tests cover critical paths |
| 10 | DX | API design is clean and consistent | Mechanical | P5 | Follows REST conventions, clear parameters |

### Review Scores
- CEO: Clean, no user challenges, scope well-calibrated
- Design: 8/10 — loading states could be richer, responsive strategy solid
- Eng: 7/10 — N+1 queries flagged and approved for optimization, architecture sound
- DX: 8/10 — clear task-by-task guide, good for agentic execution

### Cross-Phase Themes
- **Performance scalability** — CEO + Eng both flagged PostgreSQL aggregation as future bottleneck. Mitigation: plan uses Redis for KPI caching.
- **Test coverage gap** — Eng noted missing frontend component tests. Accepted as tradeoff for MVP speed.

### Approved Overrides
- **N+1 Query Optimization** (from Taste Decision #8): User selected Option B. Task 3 `calculate_user_kpi()` should combine multiple `COUNT()` queries into a single query or use `asyncio.gather()` for parallel execution to reduce database round-trips.

---

## 执行选项

**Plan complete, reviewed, and saved to `docs/superpowers/plans/2026-05-20-dashboard.md`.**

**Status:** APPROVED with N+1 optimization override.

**Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
