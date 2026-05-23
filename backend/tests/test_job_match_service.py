"""Unit tests for job match service helpers."""

from unittest.mock import AsyncMock, MagicMock

import pytest


def test_should_notify_match_threshold():
    """Scores above 70 should notify."""
    from app.domains.jobs.match_service import should_notify_match

    assert should_notify_match(71) is True
    assert should_notify_match(100) is True
    assert should_notify_match(70) is False


@pytest.mark.asyncio
async def test_upsert_match_result_creates_new_record():
    """upsert_match_result inserts a new MatchResult when none exists."""
    from app.domains.jobs.match_service import upsert_match_result
    from app.services.llm_provider import MatchAnalysis

    # SELECT existence → not found
    select_result = MagicMock()
    select_result.scalar_one_or_none.return_value = None

    # UPSERT RETURNING MatchResult → returns the freshly-loaded row
    fresh_row = MagicMock()
    fresh_row.match_score = 83
    fresh_row.resume_id = 2
    upsert_result = MagicMock()
    upsert_result.scalar_one.return_value = fresh_row

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(side_effect=[select_result, upsert_result])

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
    # Lightweight SELECT + single UPSERT RETURNING = 2 executes
    assert mock_db.execute.await_count == 2
    # No separate db.get() needed — RETURNING returns the row directly
    mock_db.get.assert_not_called()


@pytest.mark.asyncio
async def test_upsert_match_result_updates_existing_record():
    """upsert_match_result updates an existing MatchResult in-place."""
    from app.domains.jobs.match_service import upsert_match_result
    from app.services.llm_provider import MatchAnalysis

    # SELECT existence → returns id 17
    select_result = MagicMock()
    select_result.scalar_one_or_none.return_value = 17

    # UPSERT RETURNING MatchResult → returns the updated row
    refreshed = MagicMock()
    refreshed.match_score = 92
    refreshed.apply_recommendation = "强烈推荐"
    upsert_result = MagicMock()
    upsert_result.scalar_one.return_value = refreshed

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(side_effect=[select_result, upsert_result])

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
    # Lightweight SELECT + single UPSERT RETURNING = 2 executes
    assert mock_db.execute.await_count == 2
    # No separate db.get() needed — RETURNING returns the row directly
    mock_db.get.assert_not_called()
