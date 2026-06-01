"""Dashboard schemas for KPI and trend data."""
from __future__ import annotations

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


class RecentAlert(BaseModel):
    """Recent alert item for the dashboard."""

    id: int
    product_id: int | None
    alert_type: str
    message: str
    active: bool
    created_at: str | None
    product_title: str | None = None
    platform: str | None = None
