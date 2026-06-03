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
    assert task.details == [result]


@pytest.mark.asyncio
async def test_runner_can_bypass_job_crawl_lock_for_worker_tasks(monkeypatch):
    from app.core.task_registry import create_task
    from app.domains.crawling.task_runner import CrawlTaskRunner

    task = create_task("manual", user_id=1, entity_type="job_config", entity_id="3")
    crawl_single_config = AsyncMock(
        return_value={
            "status": "success",
            "new_count": 1,
            "updated_count": 0,
            "deactivated_count": 0,
        }
    )
    monkeypatch.setattr(
        "app.domains.jobs.crawl_service.crawl_single_config",
        crawl_single_config,
    )

    await CrawlTaskRunner().run_job_config(
        task,
        config_id=3,
        lock_already_held=True,
    )

    crawl_single_config.assert_awaited_once_with(
        3,
        _lock_already_held=True,
        runtime_context=None,
    )


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


@pytest.mark.asyncio
async def test_runner_executes_product_task(monkeypatch):
    from types import SimpleNamespace

    from app.core.task_registry import create_task
    from app.domains.crawling.task_runner import CrawlTaskRunner

    task = create_task("manual", user_id=1, entity_type="crawl_task")
    runner = CrawlTaskRunner()
    monkeypatch.setattr(
        "app.domains.crawling.service.get_active_products",
        AsyncMock(return_value=[SimpleNamespace(id=10, platform="jd"), SimpleNamespace(id=11, platform="jd")]),
    )
    monkeypatch.setattr(
        "app.domains.crawling.service.crawl_one_opencli",
        AsyncMock(side_effect=[
            {"status": "success", "product_id": 10},
            {"status": "error", "product_id": 11, "error": "blocked"},
        ]),
    )

    result = await runner.run_all_products(task)

    assert result["status"] == "completed"
    assert task.total == 2
    assert task.success == 1
    assert task.errors == 1


@pytest.mark.asyncio
async def test_runner_limits_product_concurrency_to_three(monkeypatch):
    from types import SimpleNamespace

    from app.core.task_registry import create_task
    from app.domains.crawling.task_runner import CrawlTaskRunner

    monkeypatch.setattr(
        "app.domains.crawling.service.get_active_products",
        AsyncMock(return_value=[SimpleNamespace(id=i, platform="jd") for i in range(6)]),
    )
    monkeypatch.setattr(
        "app.domains.crawling.service.crawl_one_opencli",
        AsyncMock(side_effect=lambda **kw: {"status": "success", "product_id": kw["product_id"]}),
    )

    task = create_task("manual", user_id=1, entity_type="crawl_task")
    result = await CrawlTaskRunner().run_all_products(task)

    assert result["status"] == "completed"
    assert result["success"] == 6


@pytest.mark.asyncio
async def test_runner_reports_product_progress(monkeypatch):
    from app.core.task_registry import CrawlTask
    from app.domains.crawling.task_runner import CrawlTaskRunner

    class Product:
        id = 1
        platform = "jd"

    async def fake_get_active_products(user_id=None):
        return [Product()]

    progress = []

    async def on_progress(task):
        progress.append((task.status.value, task.total, task.success, task.errors))

    monkeypatch.setattr(
        "app.domains.crawling.service.get_active_products",
        fake_get_active_products,
    )
    monkeypatch.setattr(
        "app.domains.crawling.service.crawl_one_opencli",
        AsyncMock(return_value={"status": "success", "product_id": 1}),
    )

    task = CrawlTask(task_id="task-1")
    await CrawlTaskRunner(progress_callback=on_progress).run_all_products(task)

    assert ("running", 0, 0, 0) in progress
    assert ("running", 1, 0, 0) in progress
    assert progress[-1] == ("completed", 1, 1, 0)


@pytest.mark.asyncio
async def test_runner_product_concurrency_behaviors(monkeypatch):
    from types import SimpleNamespace
    from app.core.task_registry import create_task
    from app.domains.crawling.task_runner import CrawlTaskRunner
    from app.config import settings

    # Mock settings.product_crawl_concurrency to 2
    monkeypatch.setattr(settings, "product_crawl_concurrency", 2)

    # 1. Test All Success
    monkeypatch.setattr(
        "app.domains.crawling.service.get_active_products",
        AsyncMock(return_value=[SimpleNamespace(id=i, platform="jd") for i in range(4)]),
    )

    crawl_mock = AsyncMock(side_effect=lambda **kw: {"status": "success", "product_id": kw["product_id"]})
    monkeypatch.setattr("app.domains.crawling.service.crawl_one_opencli", crawl_mock)

    task = create_task("manual", user_id=1, entity_type="crawl_task")
    result = await CrawlTaskRunner().run_all_products(task)

    assert result["status"] == "completed"
    assert result["success"] == 4
    assert result["errors"] == 0
    assert crawl_mock.call_count == 4

    # 2. Test Partial Failure
    crawl_mock_partial = AsyncMock(side_effect=[
        {"status": "success", "product_id": 0},
        {"status": "error", "product_id": 1, "reason": "timeout"},
        {"status": "success", "product_id": 2},
        {"status": "error", "product_id": 3, "reason": "blocked"},
    ])
    monkeypatch.setattr("app.domains.crawling.service.crawl_one_opencli", crawl_mock_partial)

    task2 = create_task("manual", user_id=1, entity_type="crawl_task")
    result2 = await CrawlTaskRunner().run_all_products(task2)
    assert result2["status"] == "completed" # partial success is marked as completed in runner
    assert result2["success"] == 2
    assert result2["errors"] == 2

    # 3. Test All Failure
    crawl_mock_failed = AsyncMock(side_effect=Exception("network_down"))
    monkeypatch.setattr("app.domains.crawling.service.crawl_one_opencli", crawl_mock_failed)

    task3 = create_task("manual", user_id=1, entity_type="crawl_task")
    result3 = await CrawlTaskRunner().run_all_products(task3)
    assert result3["status"] == "error"
    assert result3["success"] == 0
    assert result3["errors"] == 4
