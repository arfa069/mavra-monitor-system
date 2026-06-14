"""Schemas shared by durable task APIs."""

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel


class MessageResponse(BaseModel):
    message: str


class TaskQueuedResponse(BaseModel):
    status: Literal["pending", "skipped", "error"]
    task_id: str | None = None
    message: str | None = None
    reason: str | None = None


class TaskProgressResponse(BaseModel):
    task_id: str
    status: Literal["pending", "running", "completed", "failed", "error"]
    total: int = 0
    success: int = 0
    errors: int = 0
    reason: str | None = None
    worker_id: str | None = None
    heartbeat_at: datetime | None = None
    lease_until: datetime | None = None
    started_at: datetime | None = None
    finished_at: datetime | None = None
    details: list[Any] | None = None


class TaskErrorResponse(BaseModel):
    status: Literal["error"]
    reason: str


class MatchTaskQueuedResponse(BaseModel):
    status: Literal["pending", "completed"]
    task_id: str | None
    total: int
    reason: str | None = None


class CrawlerWorkerResponse(BaseModel):
    worker_id: str
    kind: str
    platform: str | None
    hostname: str
    pid: int
    status: str
    started_at: datetime | None
    last_heartbeat_at: datetime | None
    stopped_at: datetime | None


class CleanupResultResponse(BaseModel):
    status: Literal["completed"]
    deleted_crawl_logs: int
    deleted_price_history: int
    cutoff_date: datetime
    retention_days: int


class ServiceInfoResponse(BaseModel):
    name: str
    status: Literal["ok"]
    docs: str
    prefixes: list[str]


class HealthResponse(BaseModel):
    status: Literal["starting", "healthy", "unhealthy"]
