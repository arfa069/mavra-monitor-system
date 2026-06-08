"""Unit tests for job match service helpers."""

from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.core.task_registry import CrawlTask, TaskStatus
from app.models.job_match import MatchResult


@pytest.mark.asyncio
async def test_get_jobs_needing_analysis_scopes_jobs_by_user():
    """Job lookup includes JobSearchConfig.user_id when user_id is provided."""
    from app.domains.jobs.match_service import _get_jobs_needing_analysis

    empty_result = MagicMock()
    empty_result.scalars.return_value.all.return_value = []
    calls = []

    class FakeDB:
        async def execute(self, statement):
            calls.append(statement)
            return empty_result

    await _get_jobs_needing_analysis(FakeDB(), resume_id=1, job_ids=[10], user_id=5)

    assert len(calls) == 2
    rendered_query = str(calls[1])
    assert "JOIN jobs_search_configs" in rendered_query
    assert "jobs_search_configs.user_id" in rendered_query


def test_should_notify_match_threshold():
    """Consider-or-better recommendations should notify."""
    from app.domains.jobs.match_service import should_notify_match

    assert should_notify_match("强烈推荐") is True
    assert should_notify_match("可以考虑") is True
    assert should_notify_match("不太匹配") is False
    assert should_notify_match(None) is False


def test_job_has_required_match_fields_ignores_salary_and_location():
    """Match analysis requires title/company/description, not salary/location."""
    from app.domains.jobs.match_service import job_has_required_match_fields

    assert job_has_required_match_fields(
        SimpleNamespace(
            title="Python Engineer",
            company="Acme",
            description="Build APIs",
            salary=None,
            location=None,
        )
    )
    assert not job_has_required_match_fields(
        SimpleNamespace(title="Python Engineer", company="Acme", description="")
    )


@pytest.mark.asyncio
async def test_upsert_match_result_creates_new_record():
    """upsert_match_result inserts a new MatchResult when none exists."""
    from app.domains.jobs.llm.provider import MatchAnalysis
    from app.domains.jobs.match_service import upsert_match_result

    # UPSERT RETURNING MatchResult + xmax → returns the freshly-loaded row
    fresh_row = MagicMock()
    fresh_row.match_score = 83
    fresh_row.resume_id = 2
    upsert_result = MagicMock()
    upsert_result.mappings.return_value.one.return_value = {
        MatchResult: fresh_row,
        "xmax": 0,
    }

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=upsert_result)

    analysis = MatchAnalysis(
        match_score=83,
        match_reason="Good backend fit",
        apply_recommendation="可以考虑",
        model_used="gpt-4o-mini",
    )

    result, was_created = await upsert_match_result(
        db=mock_db,
        user_id=1,
        resume_id=2,
        job_id=3,
        analysis=analysis,
    )

    assert was_created is True
    assert result.match_score == 83
    assert result.resume_id == 2
    # Single UPSERT RETURNING = 1 execute
    assert mock_db.execute.await_count == 1
    # No separate db.get() needed — RETURNING returns the row directly
    mock_db.get.assert_not_called()


@pytest.mark.asyncio
async def test_upsert_match_result_updates_existing_record():
    """upsert_match_result updates an existing MatchResult in-place."""
    from app.domains.jobs.llm.provider import MatchAnalysis
    from app.domains.jobs.match_service import upsert_match_result

    # UPSERT RETURNING MatchResult + xmax → returns the updated row
    refreshed = MagicMock()
    refreshed.match_score = 92
    refreshed.apply_recommendation = "强烈推荐"
    upsert_result = MagicMock()
    upsert_result.mappings.return_value.one.return_value = {
        MatchResult: refreshed,
        "xmax": 12345,
    }

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=upsert_result)

    analysis = MatchAnalysis(
        match_score=92,
        match_reason="Excellent fit",
        apply_recommendation="强烈推荐",
        model_used="gpt-4o-mini",
    )

    result, was_created = await upsert_match_result(
        db=mock_db,
        user_id=1,
        resume_id=2,
        job_id=3,
        analysis=analysis,
    )

    assert was_created is False
    assert result is refreshed
    assert result.match_score == 92
    assert result.apply_recommendation == "强烈推荐"
    # Single UPSERT RETURNING = 1 execute
    assert mock_db.execute.await_count == 1
    # No separate db.get() needed — RETURNING returns the row directly
    mock_db.get.assert_not_called()


@pytest.mark.asyncio
async def test_enqueue_job_match_analysis_returns_completed_when_no_work():
    """enqueue_job_match_analysis returns completed without creating task when all up to date."""
    from app.domains.jobs.match_service import enqueue_job_match_analysis

    with patch("app.domains.jobs.match_service._get_jobs_needing_analysis", new_callable=AsyncMock) as mock_need:
        mock_need.return_value = []

        mock_db = AsyncMock()
        result = await enqueue_job_match_analysis(
            mock_db,
            resume_id=1,
            job_ids=[10, 20],
            user_id=1,
            source="manual",
        )

    assert result["status"] == "completed"
    assert result["task_id"] is None
    assert result["reason"] == "all_up_to_date"
    assert result["total"] == 0
    mock_db.add.assert_not_called()
    mock_need.assert_awaited_once_with(mock_db, 1, [10, 20], user_id=1)


@pytest.mark.asyncio
async def test_enqueue_job_match_analysis_creates_task_when_work_exists():
    """enqueue_job_match_analysis creates a crawl_task record when jobs need analysis."""
    from app.domains.jobs.match_service import enqueue_job_match_analysis

    mock_job = MagicMock()
    mock_job.id = 10

    with patch("app.domains.jobs.match_service._get_jobs_needing_analysis", new_callable=AsyncMock) as mock_need:
        mock_need.return_value = [mock_job]

        mock_db = AsyncMock()
        mock_db.add = MagicMock()
        result = await enqueue_job_match_analysis(
            mock_db,
            resume_id=1,
            job_ids=[10],
            user_id=1,
            source="manual",
        )

    assert result["status"] == "pending"
    assert result["task_id"] is not None
    assert result["total"] == 1
    mock_db.add.assert_called_once()
    assert mock_db.commit.await_count == 2
    assert mock_db.refresh.await_count == 2
    mock_need.assert_awaited_once_with(mock_db, 1, [10], user_id=1)


@pytest.mark.asyncio
async def test_execute_match_analysis_all_items_failed(monkeypatch):
    """All LLM calls fail → task fails with all_items_failed."""
    from app.domains.jobs.match_service import _execute_match_analysis

    mock_db = AsyncMock()

    # Mock resume
    resume = MagicMock()
    resume.user_id = 1
    resume.id = 1
    resume.name = "Test"
    resume.resume_text = "Python"
    mock_db.get = AsyncMock(return_value=resume)

    # Mock job needing analysis
    mock_job = MagicMock()
    mock_job.id = 10
    mock_job.title = "Python Engineer"
    mock_job.company = "TestCo"
    mock_job.salary = "20-30K"
    mock_job.location = "Shanghai"
    mock_job.description = "Build APIs"
    mock_job.experience = "3-5年"
    mock_job.education = "本科"

    monkeypatch.setattr(
        "app.domains.jobs.match_service._get_jobs_needing_analysis",
        AsyncMock(return_value=[mock_job]),
    )

    monkeypatch.setattr(
        "app.domains.jobs.match_service.get_cached_user_config",
        AsyncMock(return_value={}),
    )

    # Mock upsert_match_result to avoid DB dependency
    monkeypatch.setattr(
        "app.domains.jobs.match_service.upsert_match_result",
        AsyncMock(return_value=(MagicMock(), True)),
    )

    # Mock LLM provider to always fail
    class FailingProvider:
        async def analyze_match(self, **kwargs):
            raise Exception("LLM failure")

    monkeypatch.setattr(
        "app.domains.jobs.match_service.get_llm_provider",
        lambda: FailingProvider(),
    )

    task = CrawlTask(task_id="test", status=TaskStatus.RUNNING)
    await _execute_match_analysis(task, resume_id=1, job_ids=[10], db=mock_db)

    assert task.status == TaskStatus.FAILED
    assert task.reason == "all_items_failed"
    assert task.errors > 0
    assert task.success == 0
