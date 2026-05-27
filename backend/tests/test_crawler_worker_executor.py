from __future__ import annotations

import pytest

from app.core.task_registry import TaskStatus
from app.database import AsyncSessionLocal
from app.domains.crawling.profile_pool import ProfileAlreadyLeasedError
from app.domains.crawling.task_store import create_crawl_task_record
from app.workers import executor
from app.workers.executor import execute_claimed_task, run_task_heartbeat

pytestmark = pytest.mark.asyncio


async def test_execute_unknown_task_type_marks_failed():
    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="unknown",
            user_id=1,
            entity_type="crawl_task",
            entity_id="unknown",
        )
        record.status = TaskStatus.RUNNING.value
        record.locked_by = "worker-test"
        await db.commit()
        await db.refresh(record)

        result = await execute_claimed_task(record, worker_id="worker-test")

    assert result["status"] == "error"
    assert result["reason"] == "unsupported_task_type:unknown"


async def test_run_task_heartbeat_renews_running_task():
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

    renewed = await run_task_heartbeat(
        task_id=record.task_id,
        worker_id="worker-test",
        once=True,
    )

    assert renewed is True


async def test_waiting_for_children_releases_parent_lease(monkeypatch):
    async def fake_execute_job_all(record, task, progress_callback):
        return {"status": "waiting_for_children", "child_task_ids": ["child-1"]}

    monkeypatch.setattr(executor, "_execute_job_all", fake_execute_job_all)

    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_all",
            user_id=1,
            entity_type="job_crawl",
            entity_id=None,
            payload={"user_id": 1},
        )
        record.status = TaskStatus.RUNNING.value
        record.locked_by = "worker-test"
        await db.commit()
        await db.refresh(record)

        result = await execute_claimed_task(record, worker_id="worker-test")
        refreshed = await db.get(type(record), record.id)
        await db.refresh(refreshed)

    assert result["status"] == "waiting_for_children"
    assert refreshed.status == TaskStatus.RUNNING.value
    assert refreshed.reason == "waiting_for_children"
    assert refreshed.locked_by is None
    assert refreshed.lease_until is None
    assert refreshed.heartbeat_at is None


async def test_job_platform_profile_busy_bubbles_to_executor_requeue(monkeypatch):
    class BusyLease:
        async def __aenter__(self):
            raise ProfileAlreadyLeasedError("profile busy")

        async def __aexit__(self, exc_type, exc, tb):
            return False

    class BusyPool:
        def lease(self, *args, **kwargs):
            return BusyLease()

    monkeypatch.setattr("app.domains.crawling.profile_pool.DatabaseProfilePool", BusyPool)

    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_platform_profile",
            platform="boss",
            profile_key="default",
            parent_task_id="parent-1",
            user_id=1,
            entity_type="job_platform_profile",
            entity_id="boss:default",
            payload={"platform": "boss", "profile_key": "default", "config_ids": [3]},
        )
        record.status = TaskStatus.RUNNING.value
        record.locked_by = "worker-test"
        await db.commit()
        await db.refresh(record)

    result = await execute_claimed_task(record, worker_id="worker-test")

    async with AsyncSessionLocal() as db:
        refreshed = await db.get(type(record), record.id)

    assert result["status"] == "deferred"
    assert refreshed.status == TaskStatus.PENDING.value
    assert refreshed.reason.startswith("profile_busy:")
