from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from app.database import AsyncSessionLocal
from app.domains.crawling.worker_registry import (
    heartbeat_worker,
    mark_stale_workers_offline,
    register_worker,
)
from app.models.crawler_worker import CrawlerWorkerRecord

pytestmark = pytest.mark.asyncio


async def test_register_worker_creates_online_row():
    async with AsyncSessionLocal() as db:
        worker = await register_worker(
            db,
            worker_id="worker-test-1",
            kind="job",
            platform="boss",
            hostname="host-a",
            pid=1234,
        )

    assert worker.worker_id == "worker-test-1"
    assert worker.kind == "job"
    assert worker.platform == "boss"
    assert worker.status == "online"
    assert worker.last_heartbeat_at is not None


async def test_heartbeat_worker_updates_existing_row():
    async with AsyncSessionLocal() as db:
        worker = await register_worker(
            db,
            worker_id="worker-test-2",
            kind="product",
            platform="jd",
            hostname="host-a",
            pid=1235,
        )
        old_heartbeat = worker.last_heartbeat_at

        updated = await heartbeat_worker(db, "worker-test-2")

    assert updated is not None
    assert updated.last_heartbeat_at >= old_heartbeat
    assert updated.status == "online"


async def test_mark_stale_workers_offline():
    import uuid as uuid_mod
    worker_id = f"worker-stale-{uuid_mod.uuid4().hex[:8]}"
    async with AsyncSessionLocal() as db:
        worker = CrawlerWorkerRecord(
            worker_id=worker_id,
            kind="job",
            platform="51job",
            hostname="host-b",
            pid=2222,
            status="online",
            started_at=datetime.now(UTC) - timedelta(minutes=10),
            last_heartbeat_at=datetime.now(UTC) - timedelta(minutes=10),
            created_at=datetime.now(UTC) - timedelta(minutes=10),
            updated_at=datetime.now(UTC) - timedelta(minutes=10),
        )
        db.add(worker)
        await db.commit()

        count = await mark_stale_workers_offline(
            db,
            stale_after_seconds=60,
            now=datetime.now(UTC),
        )

    assert count >= 1
    refreshed = await db.get(CrawlerWorkerRecord, worker.id)
    assert refreshed.status == "offline"
