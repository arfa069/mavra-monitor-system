from datetime import UTC, datetime

import pytest
from sqlalchemy import delete

from app.database import AsyncSessionLocal
from app.models.crawl_task import CrawlTaskRecord


def test_crawl_task_model_table_name_and_required_columns():
    from app.models.crawl_task import CrawlTaskRecord

    columns = CrawlTaskRecord.__table__.columns

    assert CrawlTaskRecord.__tablename__ == "crawl_tasks"
    assert columns["task_id"].nullable is False
    assert "parent_task_id" in columns
    assert "profile_key" in columns
    assert columns["task_type"].nullable is False
    assert columns["status"].nullable is False
    assert columns["created_at"].nullable is False


def test_crawl_task_defaults_are_explicit():
    from app.models.crawl_task import CrawlTaskRecord

    now = datetime.now(UTC)
    task = CrawlTaskRecord(
        task_id="task-1",
        task_type="product_all",
        source="manual",
        status="pending",
        created_at=now,
        updated_at=now,
    )

    assert CrawlTaskRecord.total.default.arg == 0
    assert CrawlTaskRecord.success.default.arg == 0
    assert CrawlTaskRecord.errors.default.arg == 0


@pytest.mark.asyncio
async def test_create_persistent_crawl_task():
    from app.domains.crawling.task_store import create_crawl_task_record

    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="product_all",
            user_id=1,
            entity_type="crawl_task",
            entity_id=None,
        )

        assert len(record.task_id) == 32
        assert record.status == "pending"
        assert record.source == "manual"
        assert record.task_type == "product_all"


@pytest.mark.asyncio
async def test_runtime_task_round_trip():
    from app.core.task_registry import TaskStatus
    from app.domains.crawling.task_store import (
        create_crawl_task_record,
        runtime_task_from_record,
        sync_record_from_runtime_task,
    )

    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="manual",
            task_type="job_config",
            user_id=1,
            entity_type="job_config",
            entity_id="8",
        )
        runtime_task = runtime_task_from_record(record)
        runtime_task.status = TaskStatus.COMPLETED
        runtime_task.total = 3
        runtime_task.success = 2
        runtime_task.errors = 1
        runtime_task.details = [{"status": "success"}]

        await sync_record_from_runtime_task(db, record, runtime_task)

        assert record.status == "completed"
        assert record.total == 3
        assert record.details_json == [{"status": "success"}]


@pytest.mark.asyncio
async def test_recover_stale_running_tasks_marks_failed():
    from datetime import UTC, datetime, timedelta

    from app.domains.crawling.task_store import (
        create_crawl_task_record,
        mark_task_running,
        recover_stale_running_tasks,
    )

    async with AsyncSessionLocal() as db:
        record = await create_crawl_task_record(
            db,
            source="cron",
            task_type="product_all",
            user_id=1,
            entity_type="crawl_task",
            entity_id=None,
        )
        await mark_task_running(
            db,
            record,
            owner="test-worker",
            lease_seconds=1,
            now=datetime.now(UTC) - timedelta(seconds=10),
        )

        recovered = await recover_stale_running_tasks(db, owner_reason="test_restart")

        assert recovered == 1
        assert record.status == "failed"
        assert record.reason == "test_restart"
