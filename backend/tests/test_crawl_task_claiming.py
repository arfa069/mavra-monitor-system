from __future__ import annotations

import uuid

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


async def test_crawl_task_model_has_ready_claim_index():
    index_names = {index.name for index in CrawlTaskRecord.__table__.indexes}

    assert "ix_crawl_tasks_claim_ready" in index_names


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


async def _clear_pending_job_tasks() -> None:
    for task_type in ("job_config", "job_all", "job_platform_profile"):
        await _clear_pending_tasks(task_type)


async def test_claim_next_pending_task_sets_running_and_owner():
    platform = f"claim-boss-{uuid.uuid4().hex[:8]}"
    await _clear_pending_tasks("job_config")
    async with AsyncSessionLocal() as db:
        task = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_config",
            platform=platform,
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
            platforms={platform},
        )

    assert claimed is not None
    assert claimed.task_type == task.task_type
    assert claimed.platform == platform
    assert claimed.status == "running"
    assert claimed.locked_by == "worker-job-boss"
    assert claimed.heartbeat_at is not None
    assert claimed.lease_until is not None


async def test_claim_next_pending_task_respects_kind_and_platform():
    product_platform = f"claim-jd-{uuid.uuid4().hex[:8]}"
    job_platform = f"claim-boss-{uuid.uuid4().hex[:8]}"
    await _clear_pending_tasks("product_platform")
    async with AsyncSessionLocal() as db:
        await create_crawl_task_record(
            db,
            source="manual",
            task_type="product_platform",
            platform=product_platform,
            profile_key="product-jd-default",
            user_id=1,
            entity_type="product_platform",
            entity_id="jd",
        )

        claimed = await claim_next_pending_task(
            db,
            worker_id="worker-job-only",
            kinds={"job"},
            platforms={job_platform},
        )

    assert claimed is None


async def test_platform_worker_does_not_claim_full_parent_task():
    platform = f"claim-boss-{uuid.uuid4().hex[:8]}"
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
            platforms={platform},
        )

    assert claimed is None


async def test_unfiltered_job_worker_claims_full_parent_task():
    await _clear_pending_job_tasks()
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
    assert claimed.task_type == task.task_type
    assert claimed.platform is None


async def test_analysis_worker_claims_job_match_analysis_task():
    await _clear_pending_tasks("job_match_analysis")
    async with AsyncSessionLocal() as db:
        await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_match_analysis",
            platform=None,
            profile_key=None,
            user_id=1,
            entity_type="resume",
            entity_id="1",
            payload={"resume_id": 1, "job_ids": [10, 20]},
        )

        claimed = await claim_next_pending_task(
            db,
            worker_id="worker-analysis-1",
            kinds={"analysis"},
            platforms=None,
        )

    assert claimed is not None
    assert claimed.task_type == "job_match_analysis"
    assert claimed.status == "running"
    assert claimed.locked_by == "worker-analysis-1"


async def test_job_worker_does_not_claim_analysis_task():
    await _clear_pending_tasks("job_match_analysis")
    async with AsyncSessionLocal() as db:
        await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_match_analysis",
            platform=None,
            profile_key=None,
            user_id=1,
            entity_type="resume",
            entity_id="1",
            payload={"resume_id": 1, "job_ids": [10]},
        )

        claimed = await claim_next_pending_task(
            db,
            worker_id="worker-job-only",
            kinds={"job"},
            platforms=None,
        )

    assert claimed is None


async def test_all_worker_claims_analysis_task():
    for tt in ("job_config", "job_all", "job_platform_profile", "product_all", "product_platform", "job_match_analysis"):
        await _clear_pending_tasks(tt)
    async with AsyncSessionLocal() as db:
        task = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_match_analysis",
            platform=None,
            profile_key=None,
            user_id=1,
            entity_type="resume",
            entity_id="1",
            payload={"resume_id": 1, "job_ids": [10]},
        )

        claimed = await claim_next_pending_task(
            db,
            worker_id="worker-all",
            kinds={"all"},
            platforms=None,
        )

    assert claimed is not None
    assert claimed.task_type == task.task_type
