from pathlib import Path
from types import SimpleNamespace

import pytest


def test_create_adapter_uses_runtime_profile_dir(monkeypatch):
    from app.domains.jobs import crawl_service
    from app.domains.jobs.runtime import JobCrawlRuntimeContext

    captured = {}

    class FakeBoss:
        def __init__(self, **kwargs):
            captured.update(kwargs)

    monkeypatch.setattr(
        "app.platforms.BossCloakExperimentalAdapter",
        FakeBoss,
    )

    context = JobCrawlRuntimeContext(
        platform="boss",
        profile_key="job-a",
        profile_dir=Path("profiles/job-a"),
        task_id="task-1",
        config_id=101,
        run_id="run-1",
    )

    crawl_service._create_adapter("boss", runtime_context=context)

    assert captured["profile_dir"] == Path("profiles/job-a")
    assert captured["runtime_context"] == context


@pytest.mark.asyncio
async def test_task_runner_forwards_runtime_context(monkeypatch):
    from app.domains.crawling.task_runner import CrawlTaskRunner
    from app.domains.jobs.runtime import JobCrawlRuntimeContext

    calls = []

    async def fake_crawl_single_config(config_id, **kwargs):
        calls.append((config_id, kwargs))
        return {"status": "success", "new_count": 0, "updated_count": 0, "deactivated_count": 0}

    monkeypatch.setattr(
        "app.domains.jobs.crawl_service.crawl_single_config",
        fake_crawl_single_config,
    )

    task = SimpleNamespace(status=None, total=0, success=0, errors=0, reason=None)
    context = JobCrawlRuntimeContext(
        platform="boss",
        profile_key="job-a",
        profile_dir=Path("profiles/job-a"),
        task_id="task-1",
        config_id=101,
        run_id="run-1",
    )

    await CrawlTaskRunner().run_job_config(
        task, config_id=101, runtime_context=context
    )

    assert calls[0][1]["runtime_context"] == context


@pytest.mark.asyncio
async def test_crawl_single_config_preserves_runtime_context_through_lock(
    monkeypatch
):
    from app.domains.jobs import crawl_service
    from app.domains.jobs.runtime import JobCrawlRuntimeContext

    class FakeSession:
        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return None

        async def get(self, _model, _config_id):
            return SimpleNamespace(
                id=101,
                platform="boss",
                profile_key="job-a",
                url="https://www.zhipin.com/web/geek/job?query=python",
                keyword=None,
                city_code=None,
            )

        def add(self, _item):
            return None

        async def commit(self):
            return None

    class FakeAdapter:
        async def crawl(self, _url):
            return {"success": False, "error": "stop"}

    captured = {}

    def fake_create_adapter(_platform, *, runtime_context=None):
        captured["runtime_context"] = runtime_context
        return FakeAdapter()

    context = JobCrawlRuntimeContext(
        platform="boss",
        profile_key="job-a",
        profile_dir=Path("profiles/job-a"),
        task_id="task-1",
        config_id=101,
        run_id="run-1",
    )

    monkeypatch.setattr(crawl_service, "AsyncSessionLocal", lambda: FakeSession())
    monkeypatch.setattr(crawl_service, "_create_adapter", fake_create_adapter)

    result = await crawl_service.crawl_single_config(101, runtime_context=context)

    assert result == {"status": "error", "error": "stop"}
    assert captured["runtime_context"] == context
