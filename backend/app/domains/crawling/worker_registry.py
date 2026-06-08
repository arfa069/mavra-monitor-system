"""Crawler worker registry operations."""

from __future__ import annotations

from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.crawler_worker import CrawlerWorkerRecord
from app.utils.time import now_utc


async def register_worker(
    db: AsyncSession,
    *,
    worker_id: str,
    kind: str,
    platform: str | None,
    hostname: str,
    pid: int,
    now: datetime | None = None,
) -> CrawlerWorkerRecord:
    current = now or now_utc()
    result = await db.execute(
        select(CrawlerWorkerRecord).where(CrawlerWorkerRecord.worker_id == worker_id)
    )
    record = result.scalar_one_or_none()
    if record is None:
        record = CrawlerWorkerRecord(
            worker_id=worker_id,
            kind=kind,
            platform=platform,
            hostname=hostname,
            pid=pid,
            status="online",
            started_at=current,
            last_heartbeat_at=current,
            created_at=current,
            updated_at=current,
        )
        db.add(record)
    else:
        record.kind = kind
        record.platform = platform
        record.hostname = hostname
        record.pid = pid
        record.status = "online"
        record.started_at = current
        record.last_heartbeat_at = current
        record.stopped_at = None
        record.updated_at = current
    await db.commit()
    await db.refresh(record)
    return record


async def heartbeat_worker(
    db: AsyncSession,
    worker_id: str,
    *,
    now: datetime | None = None,
) -> CrawlerWorkerRecord | None:
    current = now or now_utc()
    result = await db.execute(
        select(CrawlerWorkerRecord).where(CrawlerWorkerRecord.worker_id == worker_id)
    )
    record = result.scalar_one_or_none()
    if record is None:
        return None
    record.status = "online"
    record.last_heartbeat_at = current
    record.updated_at = current
    await db.commit()
    await db.refresh(record)
    return record


async def mark_worker_stopping(
    db: AsyncSession,
    worker_id: str,
    *,
    now: datetime | None = None,
) -> CrawlerWorkerRecord | None:
    current = now or now_utc()
    result = await db.execute(
        select(CrawlerWorkerRecord).where(CrawlerWorkerRecord.worker_id == worker_id)
    )
    record = result.scalar_one_or_none()
    if record is None:
        return None
    record.status = "stopped"
    record.stopped_at = current
    record.updated_at = current
    await db.commit()
    await db.refresh(record)
    return record


async def mark_stale_workers_offline(
    db: AsyncSession,
    *,
    stale_after_seconds: int,
    now: datetime | None = None,
) -> int:
    current = now or now_utc()
    threshold = current - timedelta(seconds=stale_after_seconds)
    result = await db.execute(
        select(CrawlerWorkerRecord).where(
            CrawlerWorkerRecord.status == "online",
            CrawlerWorkerRecord.last_heartbeat_at < threshold,
        )
    )
    records = result.scalars().all()
    for record in records:
        record.status = "offline"
        record.updated_at = current
    await db.commit()
    return len(records)
