"""Persistent crawl task store."""

from __future__ import annotations

import socket
import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.task_registry import CrawlTask, TaskStatus
from app.models.crawl_task import CrawlTaskRecord

DEFAULT_TASK_LEASE_SECONDS = 60 * 60


def _now() -> datetime:
    return datetime.now(UTC)


def _owner() -> str:
    return f"api:{socket.gethostname()}"


async def create_crawl_task_record(
    db: AsyncSession,
    *,
    source: str,
    task_type: str,
    user_id: int | None,
    entity_type: str | None,
    entity_id: str | None,
    platform: str | None = None,
    profile_key: str | None = None,
    parent_task_id: str | None = None,
    payload: dict | None = None,
) -> CrawlTaskRecord:
    now = _now()
    record = CrawlTaskRecord(
        task_id=uuid.uuid4().hex,
        parent_task_id=parent_task_id,
        task_type=task_type,
        platform=platform,
        profile_key=profile_key,
        source=source,
        status=TaskStatus.PENDING.value,
        user_id=user_id,
        entity_type=entity_type,
        entity_id=entity_id,
        total=0,
        success=0,
        errors=0,
        payload_json=payload,
        created_at=now,
        updated_at=now,
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return record


async def renew_task_lease(
    db: AsyncSession,
    record: CrawlTaskRecord,
    *,
    lease_seconds: int = DEFAULT_TASK_LEASE_SECONDS,
    now: datetime | None = None,
) -> CrawlTaskRecord:
    current = now or _now()
    record.heartbeat_at = current
    record.lease_until = current + timedelta(seconds=lease_seconds)
    record.updated_at = current
    await db.commit()
    await db.refresh(record)
    return record


async def get_crawl_task_record(
    db: AsyncSession,
    task_id: str,
    *,
    user_id: int | None = None,
) -> CrawlTaskRecord | None:
    stmt = select(CrawlTaskRecord).where(CrawlTaskRecord.task_id == task_id)
    if user_id is not None:
        stmt = stmt.where(CrawlTaskRecord.user_id == user_id)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


def runtime_task_from_record(record: CrawlTaskRecord) -> CrawlTask:
    task = CrawlTask(
        task_id=record.task_id,
        status=TaskStatus(record.status),
        source=record.source,
        user_id=record.user_id,
        entity_type=record.entity_type,
        entity_id=record.entity_id,
    )
    task.total = record.total or 0
    task.success = record.success or 0
    task.errors = record.errors or 0
    task.reason = record.reason
    task.details = record.details_json or []
    return task


async def sync_record_from_runtime_task(
    db: AsyncSession,
    record: CrawlTaskRecord,
    task: CrawlTask,
) -> CrawlTaskRecord:
    now = _now()
    status = task.status.value if isinstance(task.status, TaskStatus) else str(task.status)
    record.status = status
    record.total = task.total
    record.success = task.success
    record.errors = task.errors
    record.reason = task.reason
    record.details_json = task.details
    record.heartbeat_at = now if status == TaskStatus.RUNNING.value else record.heartbeat_at
    record.updated_at = now
    if status == TaskStatus.RUNNING.value and record.started_at is None:
        record.started_at = now
    if status in {TaskStatus.COMPLETED.value, TaskStatus.FAILED.value}:
        record.finished_at = now
        record.locked_by = None
        record.lease_until = None
    await db.commit()
    await db.refresh(record)
    return record


async def mark_task_running(
    db: AsyncSession,
    record: CrawlTaskRecord,
    *,
    owner: str | None = None,
    lease_seconds: int = DEFAULT_TASK_LEASE_SECONDS,
    now: datetime | None = None,
) -> CrawlTaskRecord:
    current = now or _now()
    record.status = TaskStatus.RUNNING.value
    record.locked_by = owner or _owner()
    record.lease_until = current + timedelta(seconds=lease_seconds)
    record.heartbeat_at = current
    record.started_at = record.started_at or current
    record.updated_at = current
    await db.commit()
    await db.refresh(record)
    return record


async def recover_stale_running_tasks(
    db: AsyncSession,
    *,
    owner_reason: str = "worker_restarted",
    now: datetime | None = None,
) -> int:
    current = now or _now()
    result = await db.execute(
        select(CrawlTaskRecord).where(
            CrawlTaskRecord.status == TaskStatus.RUNNING.value,
            CrawlTaskRecord.lease_until.is_not(None),
            CrawlTaskRecord.lease_until < current,
        )
    )
    records = result.scalars().all()
    for record in records:
        record.status = TaskStatus.FAILED.value
        record.reason = owner_reason
        record.locked_by = None
        record.lease_until = None
        record.finished_at = current
        record.updated_at = current
    await db.commit()
    return len(records)
