from unittest.mock import AsyncMock

import pytest


@pytest.mark.asyncio
async def test_runner_executes_single_job_config(monkeypatch):
    from app.core.task_registry import create_task
    from app.domains.crawling.task_runner import CrawlTaskRunner

    task = create_task("manual", user_id=1, entity_type="job_config", entity_id="3")
    runner = CrawlTaskRunner()
    monkeypatch.setattr(
        "app.domains.jobs.crawl_service.crawl_single_config",
        AsyncMock(return_value={"status": "success", "new_count": 2, "updated_count": 1, "deactivated_count": 0}),
    )

    result = await runner.run_job_config(task, config_id=3)

    assert result["status"] == "success"
    assert task.total == 3
    assert task.success == 2
    assert task.errors == 0


@pytest.mark.asyncio
async def test_runner_marks_failed_job_config(monkeypatch):
    from app.core.task_registry import TaskStatus, create_task
    from app.domains.crawling.task_runner import CrawlTaskRunner

    task = create_task("manual", user_id=1, entity_type="job_config", entity_id="3")
    runner = CrawlTaskRunner()
    monkeypatch.setattr(
        "app.domains.jobs.crawl_service.crawl_single_config",
        AsyncMock(return_value={"status": "error", "error": "blocked"}),
    )

    result = await runner.run_job_config(task, config_id=3)

    assert result["status"] == "error"
    assert task.status == TaskStatus.FAILED
    assert task.reason == "blocked"


@pytest.mark.asyncio
async def test_runner_executes_all_jobs(monkeypatch):
    from app.core.task_registry import TaskStatus, create_task
    from app.domains.crawling.task_runner import CrawlTaskRunner

    task = create_task("manual", user_id=1, entity_type="job_config")
    runner = CrawlTaskRunner()
    monkeypatch.setattr(
        "app.domains.jobs.crawl_service.crawl_all_job_searches",
        AsyncMock(return_value={"status": "success", "total": 5, "success": 5, "errors": 0}),
    )

    result = await runner.run_all_jobs(task)

    assert result["status"] == "success"
    assert task.status == TaskStatus.COMPLETED
    assert task.total == 5
    assert task.success == 5
    assert task.errors == 0
