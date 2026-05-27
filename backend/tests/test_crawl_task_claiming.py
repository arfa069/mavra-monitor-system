from __future__ import annotations

import pytest
from sqlalchemy import select

from app.core.task_registry import TaskStatus
from app.database import AsyncSessionLocal
from app.domains.crawling.task_store import (
    claim_next_pending_task,
    create_crawl_task_record,
)
from app.models.crawl_task import CrawlTaskRecord

pytestmark = pytest.mark.asyncio


async def _clear_pending_tasks(task_type: str) -> None:
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(CrawlTaskRecord).where(
                CrawlTaskRecord.status == TaskStatus.PENDING.value,
                CrawlTaskRecord.task_type == task_type,
            )
        )
        for record in result.scalars().all():
            await db.delete(record)
        await db.commit()


async def test_claim_next_pending_task_sets_running_and_owner():
    await _clear_pending_tasks("job_config")
    async with AsyncSessionLocal() as db:
        task = await create_crawl_task_record(
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

        claimed = await claim_next_pending_task(
            db,
            worker_id="worker-job-boss",
            kinds={"job"},
            platforms={"boss"},
        )

    assert claimed is not None
    assert claimed.task_id == task.task_id
    assert claimed.status == "running"
    assert claimed.locked_by == "worker-job-boss"
    assert claimed.heartbeat_at is not None
    assert claimed.lease_until is not None


async def test_claim_next_pending_task_respects_kind_and_platform():
    await _clear_pending_tasks("product_platform")
    async with AsyncSessionLocal() as db:
        await create_crawl_task_record(
            db,
            source="manual",
            task_type="product_platform",
            platform="jd",
            profile_key="product-jd-default",
            user_id=1,
            entity_type="product_platform",
            entity_id="jd",
        )

        claimed = await claim_next_pending_task(
            db,
            worker_id="worker-job-only",
            kinds={"job"},
            platforms={"boss"},
        )

    assert claimed is None


async def test_platform_worker_does_not_claim_full_parent_task():
    await _clear_pending_tasks("job_all")
    async with AsyncSessionLocal() as db:
        await create_crawl_task_record(
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

        claimed = await claim_next_pending_task(
            db,
            worker_id="worker-job-boss",
            kinds={"job"},
            platforms={"boss"},
        )

    assert claimed is None


async def test_unfiltered_job_worker_claims_full_parent_task():
    await _clear_pending_tasks("job_all")
    async with AsyncSessionLocal() as db:
        task = await create_crawl_task_record(
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

        claimed = await claim_next_pending_task(
            db,
            worker_id="worker-job-coordinator",
            kinds={"job"},
            platforms=None,
        )

    assert claimed is not None
    assert claimed.task_id == task.task_id
