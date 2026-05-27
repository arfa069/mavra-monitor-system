from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from app.core.task_registry import TaskStatus
from app.database import AsyncSessionLocal
from app.domains.crawling.task_store import (
    create_crawl_task_record,
    recover_stale_running_tasks,
)
from app.domains.jobs.crawl_service import aggregate_waiting_job_parent_tasks

pytestmark = pytest.mark.asyncio


async def test_recover_stale_running_tasks_marks_failed():
    async with AsyncSessionLocal() as db:
        # Clean up any leftover stale tasks from previous runs first
        await recover_stale_running_tasks(
            db,
            owner_reason="pre_test_cleanup",
            now=datetime.now(UTC) + timedelta(days=1),
        )

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
        record.locked_by = "dead-worker"
        record.lease_until = datetime.now(UTC) - timedelta(seconds=1)
        await db.commit()

        count = await recover_stale_running_tasks(
            db,
            owner_reason="worker_stale_lease",
            now=datetime.now(UTC),
        )

    assert count >= 1
    refreshed = await db.get(type(record), record.id)
    assert refreshed.status == TaskStatus.FAILED.value
    assert refreshed.reason == "worker_stale_lease"
    assert refreshed.locked_by is None


async def test_aggregate_waiting_parent_after_child_recovery():
    async with AsyncSessionLocal() as db:
        parent = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_all",
            platform=None,
            profile_key=None,
            user_id=1,
            entity_type="job_crawl",
            entity_id=None,
            payload={"user_id": 1},
        )
        parent.status = TaskStatus.RUNNING.value
        parent.reason = "waiting_for_children"
        parent.locked_by = None
        parent.lease_until = None

        child = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_platform_profile",
            platform="boss",
            profile_key="default",
            parent_task_id=parent.task_id,
            user_id=1,
            entity_type="job_platform_profile",
            entity_id="boss:default",
            payload={"platform": "boss", "profile_key": "default", "config_ids": [3]},
        )
        child.status = TaskStatus.FAILED.value
        child.total = 1
        child.errors = 1
        child.reason = "worker_stale_lease"
        await db.commit()

    aggregated = await aggregate_waiting_job_parent_tasks()

    async with AsyncSessionLocal() as db:
        refreshed = await db.get(type(parent), parent.id)

    assert aggregated >= 1
    assert refreshed.status == TaskStatus.FAILED.value
    assert refreshed.reason == "child_task_failed"
    assert refreshed.errors >= 1
