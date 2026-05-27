from __future__ import annotations

import pytest

from app.config import settings
from app.core.task_registry import TaskStatus
from app.database import AsyncSessionLocal
from app.domains.crawling.task_store import (
    claim_next_pending_task,
    create_crawl_task_record,
    requeue_claimed_task,
)

pytestmark = pytest.mark.asyncio


async def test_requeue_claimed_task_increments_attempt_count(monkeypatch):
    monkeypatch.setattr(settings, "crawler_task_max_requeue_attempts", 3)
    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_config",
            platform="boss",
            profile_key="default",
            user_id=1,
            entity_type="job_config",
            entity_id="3",
            payload={"config_id": 3},
        )
        record.status = TaskStatus.RUNNING.value
        record.locked_by = "worker-test"
        await db.commit()
        await db.refresh(record)

        ok = await requeue_claimed_task(
            db,
            record.task_id,
            worker_id="worker-test",
            reason="profile_busy",
        )

    assert ok is True
    assert record.attempt_count == 1
    assert record.status == TaskStatus.PENDING.value


async def test_requeue_claimed_task_fails_after_max_attempts(monkeypatch):
    monkeypatch.setattr(settings, "crawler_task_max_requeue_attempts", 2)
    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_config",
            platform="boss",
            profile_key="default",
            user_id=1,
            entity_type="job_config",
            entity_id="3",
            payload={"config_id": 3},
        )
        record.status = TaskStatus.RUNNING.value
        record.locked_by = "worker-test"
        record.attempt_count = 1
        await db.commit()
        await db.refresh(record)

        ok = await requeue_claimed_task(
            db,
            record.task_id,
            worker_id="worker-test",
            reason="profile_busy",
        )

    assert ok is True
    assert record.attempt_count == 2
    assert record.status == TaskStatus.FAILED.value
    assert "max_requeue_exceeded" in record.reason


async def test_claim_next_pending_task_skips_max_attempts_tasks(monkeypatch):
    monkeypatch.setattr(settings, "crawler_task_max_requeue_attempts", 2)
    async with AsyncSessionLocal() as db:
        from sqlalchemy import delete

        from app.models.crawl_task import CrawlTaskRecord

        # Clean up stale pending tasks first
        await db.execute(
            delete(CrawlTaskRecord).where(
                CrawlTaskRecord.status == TaskStatus.PENDING.value,
                CrawlTaskRecord.task_type == "job_config",
            )
        )
        await db.commit()

        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_config",
            platform="boss",
            profile_key="default",
            user_id=1,
            entity_type="job_config",
            entity_id="3",
            payload={"config_id": 3},
        )
        record.attempt_count = 2
        await db.commit()
        await db.refresh(record)

        claimed = await claim_next_pending_task(
            db,
            worker_id="worker-test",
            kinds={"job"},
            platforms={"boss"},
        )

    assert claimed is None
