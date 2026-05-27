from __future__ import annotations

import pytest

from app.core.task_registry import TaskStatus
from app.database import AsyncSessionLocal
from app.domains.crawling.task_store import create_crawl_task_record
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
