"""Tests for job crawling service."""
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


class TestParseSalary:
    """Test salary string parsing."""

    def test_parse_salary_range_k(self):
        from app.domains.jobs.crawl_service import parse_salary
        assert parse_salary("20-40K") == (20, 40)
        assert parse_salary("15-30k") == (15, 30)

    def test_parse_salary_with_bonus(self):
        from app.domains.jobs.crawl_service import parse_salary
        assert parse_salary("20-40K·14薪") == (20, 40)
        assert parse_salary("30-50K·16薪") == (30, 50)

    def test_parse_salary_single_value(self):
        from app.domains.jobs.crawl_service import parse_salary
        assert parse_salary("25K") == (25, 25)
        assert parse_salary("15k") == (15, 15)

    def test_parse_salary_negotiable(self):
        from app.domains.jobs.crawl_service import parse_salary
        assert parse_salary("面议") == (None, None)
        assert parse_salary("薪资面议") == (None, None)

    def test_parse_salary_none(self):
        from app.domains.jobs.crawl_service import parse_salary
        assert parse_salary(None) == (None, None)

    def test_parse_salary_empty(self):
        from app.domains.jobs.crawl_service import parse_salary
        assert parse_salary("") == (None, None)

    def test_parse_salary_invalid(self):
        from app.domains.jobs.crawl_service import parse_salary
        assert parse_salary("面薪") == (None, None)
        assert parse_salary("未知格式") == (None, None)

    def test_parse_salary_edge_cases(self):
        from app.domains.jobs.crawl_service import parse_salary
        # Leading/trailing whitespace
        assert parse_salary("  20-40K  ") == (20, 40)
        # Mixed case K
        assert parse_salary("20-40k") == (20, 40)
        # Salary with spaces (spaces are stripped, so still parses)
        assert parse_salary("20 - 40K") == (20, 40)
        # Very large numbers
        assert parse_salary("100-200K") == (100, 200)


class TestCreateAdapter:
    """Test job platform adapter selection."""

    def test_create_adapter_uses_boss_cloak(self):
        from app.domains.jobs import crawl_service
        from app.platforms import BossCloakExperimentalAdapter

        adapter = crawl_service._create_adapter("boss")

        assert isinstance(adapter, BossCloakExperimentalAdapter)


@pytest.mark.asyncio
async def test_crawl_scheduled_config_enqueues_task(monkeypatch):
    from app.domains.jobs import crawl_service

    monkeypatch.setattr(crawl_service, "_get_job_config_user_id", AsyncMock(return_value=7))

    # Mock create_crawl_task_record and related to avoid DB FK issues
    mock_rec = MagicMock()
    mock_rec.task_id = "test-task-123"
    created_kwargs = {}

    async def fake_create(db, **kw):
        created_kwargs.update(kw)
        return mock_rec

    monkeypatch.setattr("app.domains.crawling.task_store.create_crawl_task_record", fake_create)
    task = MagicMock()
    task.task_id = "test-task-123"
    task.user_id = 7
    monkeypatch.setattr("app.domains.crawling.task_store.runtime_task_from_record", MagicMock(return_value=task))

    result = await crawl_service.crawl_scheduled_config(3, "0 12 * * *")

    assert result == {"status": "pending", "task_id": "test-task-123"}
    assert created_kwargs["source"] == "cron"
    assert created_kwargs["task_type"] == "job_config"
    assert created_kwargs["platform"] == "boss"
    assert created_kwargs["profile_key"] == created_kwargs["payload"]["profile_key"]
    assert created_kwargs["user_id"] == 7
    assert created_kwargs["entity_type"] == "job_config"
    assert created_kwargs["entity_id"] == "3"
    assert created_kwargs["payload"] == {
        "config_id": 3,
        "source": "scheduled",
        "platform": "boss",
        "profile_key": created_kwargs["profile_key"],
        "cron_expression": "0 12 * * *",
    }


@pytest.mark.asyncio
async def test_manual_job_config_enqueue_emits_event_center_log(monkeypatch):
    from app.domains.jobs import crawl_service

    emitted = []

    async def fake_emit(**kwargs):
        emitted.append(kwargs)

    class FakeConfig:
        platform = "boss"
        profile_key = "default"

    class FakeSession:
        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return False

        async def get(self, model, key):
            return FakeConfig()

    async def fake_create(db, **kwargs):
        record = MagicMock()
        record.id = 123
        record.task_id = "manual-task-123"
        record.task_type = kwargs["task_type"]
        record.platform = kwargs["platform"]
        record.profile_key = kwargs["profile_key"]
        record.source = kwargs["source"]
        record.user_id = kwargs["user_id"]
        record.entity_type = kwargs["entity_type"]
        record.entity_id = kwargs["entity_id"]
        record.payload_json = kwargs["payload"]
        return record

    task = MagicMock()
    task.task_id = "manual-task-123"
    task.user_id = 7

    monkeypatch.setattr(crawl_service, "AsyncSessionLocal", lambda: FakeSession())
    monkeypatch.setattr(crawl_service, "emit_system_log_detached", fake_emit)
    monkeypatch.setattr("app.domains.crawling.task_store.create_crawl_task_record", fake_create)
    monkeypatch.setattr("app.domains.crawling.task_store.runtime_task_from_record", MagicMock(return_value=task))

    result = await crawl_service.crawl_single_config_background(3, user_id=7)

    assert result is task
    assert emitted == [
        {
            "category": "runtime",
            "event_type": "job_crawl.enqueued",
            "source": "jobs",
            "severity": "info",
            "status": "pending",
            "message": "Job crawl for config 3 enqueued",
            "user_id": 7,
            "entity_type": "job_config",
            "entity_id": "3",
            "payload": {
                "task_id": "manual-task-123",
                "config_id": 3,
                "platform": "boss",
                "profile_key": "default",
            },
        }
    ]


class TestBuildCrawlUrl:
    """Test crawl URL normalization from stored config fields."""

    def test_build_crawl_url_adds_keyword_and_city_when_missing(self):
        from app.domains.jobs.crawl_service import _build_crawl_url

        config = MagicMock()
        config.url = "https://www.zhipin.com/web/geek/jobs"
        config.keyword = "IT服务台"
        config.city_code = "101280100"

        assert _build_crawl_url(config) == (
            "https://www.zhipin.com/web/geek/jobs?"
            "query=IT%E6%9C%8D%E5%8A%A1%E5%8F%B0&city=101280100"
        )

    def test_build_crawl_url_preserves_existing_query_params(self):
        from app.domains.jobs.crawl_service import _build_crawl_url

        config = MagicMock()
        config.url = "https://www.zhipin.com/web/geek/jobs?query=python&city=101280100"
        config.keyword = "IT服务台"
        config.city_code = "101280100"

        assert _build_crawl_url(config) == config.url


class TestProcessJobResults:
    """Test process_job_results dedup and grace period logic."""

    @pytest.mark.asyncio
    async def test_process_job_results_creates_new_jobs(self):
        """New jobs should be inserted with is_active=True."""
        from app.domains.jobs.crawl_service import process_job_results

        mock_config = MagicMock()
        mock_config.id = 1
        mock_config.notify_on_new = False
        mock_config.deactivation_threshold = 3

        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = []
        mock_result.scalar_one_or_none.return_value = None

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(return_value=mock_result)
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.flush = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            with patch("app.domains.jobs.crawl_service.update_job_detail", new_callable=AsyncMock):
                result = await process_job_results(1, [{"job_id": "abc123", "title": "Dev"}], 1)

        assert result["new_count"] == 1
        assert result["deactivated_count"] == 0

    @pytest.mark.asyncio
    async def test_process_job_results_skips_detail_wait_when_boss_description_present(self):
        """Boss search results with descriptions should not pay detail fetch throttling cost."""
        from app.domains.jobs.crawl_service import process_job_results

        mock_config = MagicMock()
        mock_config.id = 1
        mock_config.notify_on_new = False
        mock_config.deactivation_threshold = 3
        mock_config.enable_match_analysis = False

        empty_result = MagicMock()
        empty_result.scalars.return_value.all.return_value = []
        id_result = MagicMock()
        id_result.all.return_value = [(123, "abc123")]

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(side_effect=[
            empty_result,  # active jobs
            empty_result,  # existing jobs by job_id
            empty_result,  # dedup query
            id_result,  # inserted internal IDs
        ])
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.flush = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            with (
                patch("app.domains.jobs.crawl_service.update_job_detail", new_callable=AsyncMock) as update_detail,
                patch("app.domains.jobs.crawl_service.asyncio.sleep", new_callable=AsyncMock) as sleep,
            ):
                result = await process_job_results(
                    1,
                    [{"job_id": "abc123", "title": "Dev", "description": "Already in search JSON"}],
                    1,
                    platform="boss",
                )

        assert result["new_count"] == 1
        update_detail.assert_not_called()
        sleep.assert_not_called()

    @pytest.mark.asyncio
    async def test_process_job_results_skips_51job_detail_when_description_present(self):
        """51job should not hit WAF-prone detail pages only to backfill address."""
        from app.domains.jobs.crawl_service import process_job_results

        mock_config = MagicMock()
        mock_config.id = 1
        mock_config.notify_on_new = False
        mock_config.deactivation_threshold = 3
        mock_config.enable_match_analysis = False

        empty_result = MagicMock()
        empty_result.scalars.return_value.all.return_value = []
        inserted_result = MagicMock()
        inserted_result.scalars.return_value.all.return_value = []

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(side_effect=[
            empty_result,  # active jobs
            empty_result,  # existing jobs by job_id
            empty_result,  # dedup query
            inserted_result,  # inserted jobs needing detail
        ])
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.flush = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            with (
                patch("app.domains.jobs.crawl_service.update_job_detail", new_callable=AsyncMock) as update_detail,
                patch("app.domains.jobs.crawl_service.asyncio.sleep", new_callable=AsyncMock),
            ):
                update_detail.return_value = {
                    "success": True,
                    "detail": {"description": "Already in search JSON", "address": "上海"},
                }
                result = await process_job_results(
                    1,
                    [{"job_id": "abc123", "title": "Dev", "description": "Already in search JSON"}],
                    1,
                    platform="51job",
                )

        assert result["new_count"] == 1
        update_detail.assert_not_called()

    @pytest.mark.asyncio
    async def test_process_job_results_deduplicates_current_batch_by_job_id(self):
        """Duplicate job IDs in one crawl response should not violate DB uniqueness."""
        from app.domains.jobs.crawl_service import process_job_results

        mock_config = MagicMock()
        mock_config.id = 1
        mock_config.notify_on_new = False
        mock_config.deactivation_threshold = 3
        mock_config.enable_match_analysis = False

        empty_result = MagicMock()
        empty_result.scalars.return_value.all.return_value = []
        id_result = MagicMock()
        id_result.all.return_value = [(123, "abc123")]

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(side_effect=[
            empty_result,
            empty_result,
            empty_result,
            id_result,
        ])
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.flush = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            result = await process_job_results(
                1,
                [
                    {"job_id": "abc123", "title": "First", "description": "D"},
                    {"job_id": "abc123", "title": "Duplicate", "description": "D"},
                ],
                2,
                platform="51job",
            )

        assert result["new_count"] == 1
        assert mock_db.add.call_count == 2
        added_records = [call.args[0] for call in mock_db.add.call_args_list]
        crawl_log = added_records[-1]
        assert crawl_log.total_jobs_count == 1

    @pytest.mark.asyncio
    async def test_process_job_results_updates_existing_job(self):
        """Existing jobs should be updated and reactivated."""
        from app.domains.jobs.crawl_service import process_job_results

        mock_config = MagicMock()
        mock_config.id = 1
        mock_config.notify_on_new = False
        mock_config.deactivation_threshold = 3

        existing_job = MagicMock()
        existing_job.job_id = "abc123"
        existing_job.search_config_id = 1
        existing_job.is_active = True
        existing_job.consecutive_miss_count = 1
        existing_job.title = "Old Title"
        existing_job.last_active_at = None

        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [existing_job]
        mock_result.scalar_one_or_none.return_value = existing_job

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(return_value=mock_result)
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            result = await process_job_results(1, [{"job_id": "abc123", "title": "New Title"}], 1)

        assert result["new_count"] == 0
        assert result["updated_count"] == 1
        assert existing_job.is_active is True
        assert existing_job.consecutive_miss_count == 0  # Reset on presence

    @pytest.mark.asyncio
    async def test_process_job_results_retries_failed_detail_items(self):
        """A transient detail failure should be retried after the first detail pass."""
        from app.domains.jobs.crawl_service import process_job_results

        mock_config = MagicMock()
        mock_config.id = 1
        mock_config.notify_on_new = False
        mock_config.deactivation_threshold = 3
        mock_config.enable_match_analysis = False

        existing_job = MagicMock()
        existing_job.id = 99
        existing_job.job_id = "abc123"
        existing_job.search_config_id = 1
        existing_job.is_active = True
        existing_job.consecutive_miss_count = 0
        existing_job.description = ""
        existing_job.address = ""

        active_result = MagicMock()
        active_result.scalars.return_value.all.return_value = [existing_job]
        existing_result = MagicMock()
        existing_result.scalars.return_value.all.return_value = [existing_job]

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(side_effect=[active_result, existing_result])
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()

        update_detail = AsyncMock(side_effect=[
            {"success": False, "error": "Cookie expired"},
            {"success": True, "detail": {"description": "D", "address": "A"}},
        ])

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            with (
                patch("app.domains.jobs.crawl_service.update_job_detail", update_detail),
                patch("app.domains.jobs.crawl_service.asyncio.sleep", new_callable=AsyncMock) as sleep,
                patch("app.domains.jobs.crawl_service.random.uniform", return_value=0.0) as random_uniform,
            ):
                result = await process_job_results(
                    1,
                    [{"job_id": "abc123", "title": "Dev", "description": "", "address": ""}],
                    1,
                )

        assert result["updated_count"] == 1
        assert update_detail.await_count == 2
        # Now passes Job objects, not raw ints
        assert update_detail.await_args_list[0].args[0] is existing_job
        assert update_detail.await_args_list[1].args[0] is existing_job
        assert update_detail.await_args_list[0].kwargs["db"] is mock_db
        assert update_detail.await_args_list[1].kwargs["db"] is mock_db
        sleep.assert_awaited()
        detail_delay_calls = [
            call.args
            for call in random_uniform.call_args_list
            if call.args == (5.0, 10.0)
        ]
        assert len(detail_delay_calls) == 2

    @pytest.mark.asyncio
    async def test_process_job_results_does_not_retry_unavailable_liepin_detail(self):
        """Permanent Liepin detail shells should not enter the retry queue."""
        from app.domains.jobs.crawl_service import process_job_results

        mock_config = MagicMock()
        mock_config.id = 1
        mock_config.notify_on_new = False
        mock_config.deactivation_threshold = 3
        mock_config.enable_match_analysis = False
        mock_config.profile_key = "liepin"

        existing_job = MagicMock()
        existing_job.id = 99
        existing_job.job_id = "75755585"
        existing_job.search_config_id = 1
        existing_job.is_active = True
        existing_job.consecutive_miss_count = 0
        existing_job.description = ""
        existing_job.address = ""

        active_result = MagicMock()
        active_result.scalars.return_value.all.return_value = [existing_job]
        existing_result = MagicMock()
        existing_result.scalars.return_value.all.return_value = [existing_job]

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(side_effect=[active_result, existing_result])
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()

        update_detail = AsyncMock(return_value={
            "success": False,
            "failure_category": "detail_unavailable",
            "error": "Liepin detail URL returned redirect shell",
        })

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            with (
                patch("app.domains.jobs.crawl_service.update_job_detail", update_detail),
                patch("app.domains.jobs.crawl_service.asyncio.sleep", new_callable=AsyncMock) as sleep,
            ):
                result = await process_job_results(
                    1,
                    [{"job_id": "75755585", "title": "Dev", "description": "", "address": ""}],
                    1,
                    platform="liepin",
                )

        assert result["updated_count"] == 1
        update_detail.assert_awaited_once()
        sleep.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_process_job_results_grace_period_deactivation(self):
        """Job should be deactivated when threshold reached (threshold=2, miss_count goes 1->2)."""
        from app.domains.jobs.crawl_service import process_job_results

        mock_config = MagicMock()
        mock_config.id = 999
        mock_config.notify_on_new = False
        mock_config.deactivation_threshold = 2

        # Job "abc" is NOT in current crawl (seen_job_ids only contains "xyz")
        existing_job = MagicMock()
        existing_job.job_id = "abc"
        existing_job.search_config_id = 999
        existing_job.is_active = True
        existing_job.consecutive_miss_count = 1
        existing_job.last_active_at = None

        # Current crawl has job "xyz" but NOT "abc" → abc gets deactivation logic
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [existing_job]
        mock_result.scalar_one_or_none.return_value = None

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(return_value=mock_result)
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.flush = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            # Crawl has "xyz" (so seen_job_ids is non-empty), but "abc" is absent
            result = await process_job_results(999, [{"job_id": "xyz", "title": "Other"}], 1)

        assert result["deactivated_count"] == 1
        assert existing_job.is_active is False
        assert existing_job.consecutive_miss_count == 2

    @pytest.mark.asyncio
    async def test_process_job_results_grace_period_not_yet_deactivated(self):
        """Job should NOT be deactivated until threshold is reached (threshold=2, miss_count 0->1)."""
        from app.domains.jobs.crawl_service import process_job_results

        mock_config = MagicMock()
        mock_config.id = 999
        mock_config.notify_on_new = False
        mock_config.deactivation_threshold = 2

        # Job "abc" is NOT in current crawl (seen_job_ids only contains "xyz")
        existing_job = MagicMock()
        existing_job.job_id = "abc"
        existing_job.search_config_id = 999
        existing_job.is_active = True
        existing_job.consecutive_miss_count = 0
        existing_job.last_active_at = None

        # Current crawl has job "xyz" but NOT "abc" → abc gets miss counter logic
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [existing_job]
        mock_result.scalar_one_or_none.return_value = None

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(return_value=mock_result)
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.flush = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            # Crawl has "xyz" (so seen_job_ids is non-empty), but "abc" is absent
            result = await process_job_results(999, [{"job_id": "xyz", "title": "Other"}], 1)

        assert result["deactivated_count"] == 0
        assert existing_job.is_active is True
        assert existing_job.consecutive_miss_count == 1  # Incremented but not deactivated


class TestUpdateJobDetail:
    """Test update_job_detail service function."""

    @pytest.mark.asyncio
    async def test_update_job_detail_success(self):
        """update_job_detail should update job record with detail data."""
        from app.domains.jobs.crawl_service import update_job_detail

        mock_job = MagicMock()
        mock_job.id = 1
        mock_job.job_id = "test_encrypt_id"
        mock_job.description = None
        mock_job.address = None

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_job)
        mock_db.commit = AsyncMock()

        mock_adapter = MagicMock()
        mock_adapter.crawl_detail = AsyncMock(return_value={
            "success": True,
            "detail": {
                "description": "岗位职责: ...",
                "address": "深圳南山区",
                "title": "Java",
            },
        })

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            with patch("app.platforms.BossCloakExperimentalAdapter") as mock_adapter_cls:
                mock_adapter_cls.return_value = mock_adapter
                result = await update_job_detail(1)

        assert result["success"] is True
        assert result["detail"]["description"] == "岗位职责: ..."
        assert mock_job.description == "岗位职责: ..."
        assert mock_job.address == "深圳南山区"

    @pytest.mark.asyncio
    async def test_update_job_detail_reuses_session_without_commit(self):
        """Batch detail updates can reuse the caller's session and defer commit."""
        from app.domains.jobs.crawl_service import update_job_detail

        mock_job = MagicMock()
        mock_job.id = 1
        mock_job.job_id = "test_encrypt_id"
        mock_job.description = None
        mock_job.address = None

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_job)
        mock_db.commit = AsyncMock()

        mock_adapter = MagicMock()
        mock_adapter.crawl_detail = AsyncMock(return_value={
            "success": True,
            "detail": {
                "description": "岗位职责: ...",
                "address": "深圳南山区",
            },
        })

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            result = await update_job_detail(
                1,
                adapter=mock_adapter,
                db=mock_db,
                commit=False,
            )

        assert result["success"] is True
        assert mock_job.description == "岗位职责: ..."
        mock_db.commit.assert_not_awaited()
        mock_session.assert_not_called()

    @pytest.mark.asyncio
    async def test_update_job_detail_not_found(self):
        """update_job_detail should return error if job not found."""
        from app.domains.jobs.crawl_service import update_job_detail

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=None)

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            result = await update_job_detail(999)

        assert result["success"] is False
        assert "not found" in result["error"].lower()

    @pytest.mark.asyncio
    async def test_update_job_detail_accepts_job_object_skips_db_get(self):
        """Passing a Job object should skip db.get()."""
        from app.domains.jobs.crawl_service import update_job_detail
        from app.models.job import Job

        mock_job = MagicMock(spec=Job)
        mock_job.id = 1
        mock_job.job_id = "test_encrypt_id"
        mock_job.description = None
        mock_job.address = None

        mock_db = MagicMock()
        mock_db.get = AsyncMock()  # should NOT be called
        mock_db.commit = AsyncMock()

        mock_adapter = MagicMock()
        mock_adapter.crawl_detail = AsyncMock(return_value={
            "success": True,
            "detail": {"description": "岗位职责", "address": "深圳"},
        })

        result = await update_job_detail(
            mock_job,  # Pass Job object, not int
            adapter=mock_adapter,
            db=mock_db,
            commit=False,
        )

        assert result["success"] is True
        mock_db.get.assert_not_called()  # Key: no db.get() for loaded Job
        mock_db.commit.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_update_job_detail_passes_51job_url_to_adapter(self):
        """51job detail fetch should use the exact URL captured from search results."""
        from app.domains.jobs.crawl_service import update_job_detail
        from app.models.job import Job

        mock_job = MagicMock(spec=Job)
        mock_job.id = 1
        mock_job.job_id = "171250658"
        mock_job.url = "https://jobs.51job.com/shanghai-jaq/171250658.html"
        mock_job.description = None
        mock_job.address = None

        mock_db = MagicMock()
        mock_db.get = AsyncMock()
        mock_db.commit = AsyncMock()

        mock_adapter = MagicMock()
        mock_adapter.crawl_detail = AsyncMock(return_value={
            "success": True,
            "detail": {"description": "岗位职责", "address": "上海"},
        })

        result = await update_job_detail(
            mock_job,
            adapter=mock_adapter,
            platform="51job",
            db=mock_db,
            commit=False,
        )

        assert result["success"] is True
        mock_adapter.crawl_detail.assert_awaited_once_with(
            "171250658",
            "https://jobs.51job.com/shanghai-jaq/171250658.html",
        )
        mock_db.get.assert_not_called()


class TestAdapterSharing:
    """Verify single adapter is reused across multiple configs."""

    @pytest.mark.asyncio
    async def test_crawl_single_config_reuses_adapter(self):
        """When adapter is passed, it should not create a new one."""
        from app.domains.jobs.crawl_service import crawl_single_config

        mock_adapter = MagicMock()
        mock_adapter.crawl = AsyncMock(return_value={
            "success": True,
            "jobs": [{"job_id": "j1", "title": "Test", "company": "Co",
                      "salary": "20K", "location": "BJ", "experience": "3年",
                      "education": "本科", "url": "https://zhipin.com/job_detail/j1.html"}],
            "count": 1,
        })

        mock_config = MagicMock()
        mock_config.id = 1
        mock_config.url = "https://www.zhipin.com/web/geek/jobs?query=test"

        # Build proper mock chain: db.execute() -> result -> result.scalars() -> scalars.all()
        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=[])
        mock_result = MagicMock()
        mock_result.scalars = MagicMock(return_value=mock_scalars)

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(return_value=mock_result)
        mock_db.add = MagicMock()
        mock_db.flush = AsyncMock()
        mock_db.commit = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            with patch("app.domains.jobs.notification_service.send_new_job_notification"):
                result = await crawl_single_config(1, adapter=mock_adapter)

        assert result["status"] == "success"
        mock_adapter.crawl.assert_called_once()

    @pytest.mark.asyncio
    async def test_crawl_single_config_creates_adapter_when_none(self):
        """When no adapter is passed, a new BossCloakExperimentalAdapter should be created."""
        from app.domains.jobs.crawl_service import crawl_single_config

        mock_config = MagicMock()
        mock_config.id = 1
        mock_config.url = "https://www.zhipin.com/web/geek/jobs?query=test"

        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=[])
        mock_result = MagicMock()
        mock_result.scalars = MagicMock(return_value=mock_scalars)

        mock_db = MagicMock()
        mock_db.get = AsyncMock(return_value=mock_config)
        mock_db.execute = AsyncMock(return_value=mock_result)
        mock_db.add = MagicMock()
        mock_db.flush = AsyncMock()
        mock_db.commit = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session:
            mock_session.return_value.__aenter__.return_value = mock_db
            mock_session.return_value.__aexit__.return_value = None

            with patch("app.platforms.BossCloakExperimentalAdapter") as mock_cls:
                mock_adapter = MagicMock()
                mock_adapter.crawl = AsyncMock(return_value={
                    "success": True, "jobs": [], "count": 0,
                })
                mock_cls.return_value = mock_adapter

                await crawl_single_config(1)  # no adapter passed

        mock_cls.assert_called_once()

    @pytest.mark.asyncio
    async def test_crawl_all_searches_creates_one_adapter(self):
        """crawl_all_job_searches should create exactly ONE adapter for all configs.

        Patches crawl_single_config at its import location to avoid DB internals,
        then verifies the shared adapter is passed correctly.
        """
        from app.domains.jobs.crawl_service import crawl_all_job_searches

        # Mock result for: result.scalars().all() -> [3 configs]
        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=[
            MagicMock(id=1, url="https://www.zhipin.com/web/geek/jobs?query=a", profile_key="default"),
            MagicMock(id=2, url="https://www.zhipin.com/web/geek/jobs?query=b", profile_key="default"),
            MagicMock(id=3, url="https://www.zhipin.com/web/geek/jobs?query=c", profile_key="default"),
        ])
        mock_execute_result = MagicMock()
        mock_execute_result.scalars = MagicMock(return_value=mock_scalars)

        mock_db = MagicMock()
        mock_db.execute = AsyncMock(return_value=mock_execute_result)
        mock_db.get = AsyncMock()
        mock_db.add = MagicMock()
        mock_db.flush = AsyncMock()
        mock_db.commit = AsyncMock()

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session_cls:
            mock_session_cls.return_value.__aenter__.return_value = mock_db
            mock_session_cls.return_value.__aexit__.return_value = None

            with patch("app.domains.jobs.crawl_service.crawl_single_config") as mock_crawl_single:
                mock_crawl_single.return_value = {
                    "status": "success", "new_count": 1, "updated_count": 0,
                    "deactivated_count": 0,
                }

                from contextlib import asynccontextmanager
                from pathlib import Path

                from app.domains.crawling.profile_pool import ProfileLease

                @asynccontextmanager
                async def fake_lease(self, db, *, platform, profile_key, owner, task_id):
                    yield ProfileLease(
                        platform=platform,
                        profile_key=profile_key,
                        profile_dir=Path("profiles") / profile_key,
                        owner=owner,
                        task_id=task_id,
                    )

                with patch(
                    "app.domains.crawling.profile_pool.DatabaseProfilePool.lease",
                    fake_lease,
                ), patch("app.domains.jobs.crawl_service._create_adapter") as mock_adapter_cls:
                    mock_adapter = MagicMock()
                    mock_adapter_cls.return_value = mock_adapter

                    result = await crawl_all_job_searches(source="test")

        assert mock_adapter_cls.call_count == 1, \
            f"Expected 1 adapter, got {mock_adapter_cls.call_count}"
        assert mock_crawl_single.call_count == 3, \
            f"Expected 3 crawl_single_config calls, got {mock_crawl_single.call_count}"
        for _, kwargs in mock_crawl_single.call_args_list:
            assert kwargs.get("adapter") is mock_adapter, \
                "All crawl_single_config calls should receive the shared adapter"
        assert result["total"] == 3

    @pytest.mark.asyncio
    async def test_crawl_all_searches_filters_by_user_id(self):
        """Manual all-config crawls should only select the current user's configs."""
        from app.domains.jobs.crawl_service import crawl_all_job_searches

        async def execute(statement):
            assert "jobs_search_configs.user_id" in str(statement)
            mock_scalars = MagicMock()
            mock_scalars.all = MagicMock(return_value=[])
            mock_result = MagicMock()
            mock_result.scalars = MagicMock(return_value=mock_scalars)
            return mock_result

        mock_db = MagicMock()
        mock_db.execute = AsyncMock(side_effect=execute)

        with patch("app.domains.jobs.crawl_service.AsyncSessionLocal") as mock_session_cls:
            mock_session_cls.return_value.__aenter__.return_value = mock_db
            mock_session_cls.return_value.__aexit__.return_value = None

            result = await crawl_all_job_searches(source="test", user_id=42)

        assert result["status"] == "completed"
        assert result["total"] == 0

    @pytest.mark.asyncio
    async def test_crawl_single_config_skips_when_job_crawl_lock_is_held(self):
        """Overlapping job crawls should be skipped instead of running concurrently."""
        from app.domains.jobs import crawl_service as job_crawl

        await job_crawl._JOB_CRAWL_LOCK.acquire()
        try:
            result = await job_crawl.crawl_single_config(1)
        finally:
            job_crawl._JOB_CRAWL_LOCK.release()

        assert result["status"] == "skipped"
        assert result["reason"] == "another_job_crawl_in_progress"


def test_config_profile_key_extracts_from_config():
    from app.domains.jobs.crawl_service import _config_profile_key

    config = MagicMock()
    config.profile_key = "job-a"
    assert _config_profile_key(config) == "job-a"


def test_config_profile_key_defaults_when_missing():
    from app.domains.jobs.crawl_service import _config_profile_key

    config = MagicMock()
    config.profile_key = None
    assert _config_profile_key(config) == "default"


def test_config_profile_key_defaults_when_none():
    from app.domains.jobs.crawl_service import _config_profile_key

    assert _config_profile_key(None) == "default"
