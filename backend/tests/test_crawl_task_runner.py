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
        "app.domains.products.repository.list_product_profile_bindings",
        AsyncMock(return_value=[SimpleNamespace(platform="jd", profile_key="product-jd-default")]),
    )
    monkeypatch.setattr(
        "app.domains.crawling.task_runner.asyncio.sleep",
        AsyncMock(),
    )
    monkeypatch.setattr(
        "app.domains.crawling.task_runner.crawl_products_with_profile",
        AsyncMock(return_value=[
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

    call_count = 0

    async def fake_crawl_products_with_profile(*, product_ids, platform, profile_key, task_id):
        nonlocal call_count
        call_count += 1
        return [{"status": "success", "product_id": pid} for pid in product_ids]

    monkeypatch.setattr(
        "app.domains.crawling.service.get_active_products",
        AsyncMock(return_value=[SimpleNamespace(id=i, platform="jd") for i in range(6)]),
    )
    monkeypatch.setattr(
        "app.domains.products.repository.list_product_profile_bindings",
        AsyncMock(return_value=[SimpleNamespace(platform="jd", profile_key="product-jd-default")]),
    )
    monkeypatch.setattr(
        "app.domains.crawling.task_runner.crawl_products_with_profile",
        fake_crawl_products_with_profile,
    )
    monkeypatch.setattr(
        "app.domains.crawling.task_runner.asyncio.sleep",
        AsyncMock(),
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

    async def fake_crawl_products_with_profile(*, product_ids, platform, profile_key, task_id):
        return [{"status": "success", "product_id": pid} for pid in product_ids]

    progress = []

    async def on_progress(task):
        progress.append((task.status.value, task.total, task.success, task.errors))

    monkeypatch.setattr(
        "app.domains.crawling.service.get_active_products",
        fake_get_active_products,
    )
    class Binding:
        platform = "jd"
        profile_key = "product-jd-default"

    monkeypatch.setattr(
        "app.domains.products.repository.list_product_profile_bindings",
        AsyncMock(return_value=[Binding()]),
    )
    monkeypatch.setattr(
        "app.domains.crawling.task_runner.crawl_products_with_profile",
        fake_crawl_products_with_profile,
    )

    task = CrawlTask(task_id="task-1")
    await CrawlTaskRunner(progress_callback=on_progress).run_all_products(task)

    assert ("running", 0, 0, 0) in progress
    assert ("running", 1, 0, 0) in progress
    assert progress[-1] == ("completed", 1, 1, 0)
