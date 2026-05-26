from pathlib import Path
from types import SimpleNamespace

import pytest


def test_create_adapter_uses_runtime_profile_dir(monkeypatch, tmp_path):
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
        profile_dir=tmp_path / "profiles" / "job-a",
        task_id="task-1",
        config_id=101,
        run_id="run-1",
    )

    crawl_service._create_adapter("boss", runtime_context=context)

    assert captured["profile_dir"] == tmp_path / "profiles" / "job-a"
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
