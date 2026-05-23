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
    async def test_process_job_results_skips_detail_wait_when_description_present(self):
        """Search results with descriptions should not pay detail fetch throttling cost."""
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
                    platform="51job",
                )

        assert result["new_count"] == 1
        update_detail.assert_not_called()
        sleep.assert_not_called()

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


class TestCrawlDetail:
    """Test job detail scraping."""

    @pytest.mark.asyncio
    async def test_acquire_cookies_uses_session_before_cdp(self):
        """Boss cookie acquisition should reuse in-memory cookies before CDP."""
        from app.platforms.boss import BossZhipinAdapter

        adapter = BossZhipinAdapter()
        session = adapter._get_session()
        session.cookies.set("__zp_stoken__", "session", domain=".zhipin.com", path="/")

        with patch.object(
            BossZhipinAdapter,
            "_get_cookies_via_raw_cdp",
            new_callable=AsyncMock,
        ) as cdp:
            result = await adapter._acquire_cookies(session)

        assert result is True
        cdp.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_acquire_cookies_uses_cdp_without_disk_cache(self):
        """Boss cookie acquisition should read CDP directly instead of disk cache."""
        from app.platforms.boss import BossZhipinAdapter

        adapter = BossZhipinAdapter()
        session = adapter._get_session()

        with patch.object(
            BossZhipinAdapter,
            "_get_cookies_via_raw_cdp",
            new_callable=AsyncMock,
            return_value={"__zp_stoken__": "cdp", "other": "cookie"},
        ) as cdp:
            result = await adapter._acquire_cookies(session)

        assert result is True
        cdp.assert_awaited_once()
        assert session.cookies.get("__zp_stoken__") == "cdp"

    @pytest.mark.asyncio
    async def test_acquire_cookies_refreshes_when_cdp_has_no_stoken(self):
        """Boss cookie acquisition should actively refresh when existing CDP cookies are stale."""
        from app.platforms.boss import BossZhipinAdapter

        adapter = BossZhipinAdapter()
        session = adapter._get_session()

        with (
            patch.object(
                BossZhipinAdapter,
                "_get_cookies_via_raw_cdp",
                new_callable=AsyncMock,
                return_value={},
            ) as cdp,
            patch.object(
                BossZhipinAdapter,
                "_refresh_cookies_via_cdp_target",
                new_callable=AsyncMock,
                return_value={"__zp_stoken__": "fresh", "other": "cookie"},
            ) as refresh,
        ):
            result = await adapter._acquire_cookies(session)

        assert result is True
        cdp.assert_awaited_once()
        refresh.assert_awaited_once()
        assert session.cookies.get("__zp_stoken__") == "fresh"

    @pytest.mark.asyncio
    async def test_crawl_detail_success(self):
        """crawl_detail should return parsed job details."""
        from app.platforms.boss import BossZhipinAdapter

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "code": 0,
            "zpData": {
                "jobInfo": {
                    "jobName": "Java",
                    "salaryDesc": "10-15K·14薪",
                    "locationName": "深圳",
                    "address": "深圳南山区前海周大福金融大厦1401-05",
                    "experienceName": "在校/应届",
                    "degreeName": "本科",
                    "postDescription": "岗位职责: ...",
                },
                "bossInfo": {"name": "李俊滨", "title": "AI全栈工程师"},
                "brandComInfo": {"brandName": "望尘科技"},
            },
        }

        with patch("app.platforms.boss.CffiSession") as mock_session_cls:
            mock_session = MagicMock()
            mock_session.get.return_value = mock_response
            mock_session.cookies.get_dict.return_value = {"__zp_stoken__": "fake"}
            mock_session_cls.return_value = mock_session

            adapter = BossZhipinAdapter()
            result = await adapter.crawl_detail("test_security_id")

        assert result["success"] is True
        assert result["detail"]["title"] == "Java"
        assert result["detail"]["address"] == "深圳南山区前海周大福金融大厦1401-05"
        assert result["detail"]["description"] == "岗位职责: ..."
        assert result["detail"]["company"] == "望尘科技"

    @pytest.mark.asyncio
    async def test_crawl_detail_no_cookies(self):
        """crawl_detail should fail gracefully when all cookie sources fail."""
        from app.platforms.boss import BossZhipinAdapter

        with patch.object(
            BossZhipinAdapter,
            "_refresh_cookies_via_cdp_target",
            new_callable=AsyncMock,
            return_value={},
        ) as mock_refresh:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"code": 37, "message": "Cookie expired"}

            with (
                patch("app.platforms.boss.CffiSession") as mock_session_cls,
                patch("app.platforms.boss.asyncio.sleep", new_callable=AsyncMock),
            ):
                mock_session = MagicMock()
                mock_session.get.return_value = mock_response
                mock_session.cookies.get.return_value = ""  # no __zp_stoken__
                mock_session_cls.return_value = mock_session

                adapter = BossZhipinAdapter()
                result = await adapter.crawl_detail("test_security_id")

        assert result["success"] is False
        assert "Cookie expired" in result["error"]
        assert mock_refresh.await_count == 2

    @pytest.mark.asyncio
    async def test_crawl_detail_api_error(self):
        """crawl_detail should retry once on code=37 then return a helpful error."""
        from app.platforms.boss import BossZhipinAdapter

        with patch.object(
            BossZhipinAdapter, "_refresh_cookies_via_cdp_target",
            new_callable=AsyncMock, return_value={"__zp_stoken__": "fake"},
        ) as mock_refresh:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"code": 37, "message": "Cookie expired"}

            with (
                patch("app.platforms.boss.CffiSession") as mock_session_cls,
                patch("app.platforms.boss.asyncio.sleep", new_callable=AsyncMock),
            ):
                mock_session = MagicMock()
                mock_session.get.return_value = mock_response
                mock_session.cookies.get_dict.return_value = {"__zp_stoken__": "old"}
                mock_session_cls.return_value = mock_session

                adapter = BossZhipinAdapter()
                result = await adapter.crawl_detail("test_security_id")

        assert result["success"] is False
        assert "Cookie expired" in result["error"]
        # code=37 时应该通过 CDP 临时 target 主动刷新 cookie 再重试
        assert mock_refresh.await_count == 2

    @pytest.mark.asyncio
    async def test_crawl_detail_refreshes_cookie_then_succeeds(self):
        """crawl_detail should recover from code=37 when CDP refresh returns a new stoken."""
        from app.platforms.boss import BossZhipinAdapter

        expired_response = MagicMock()
        expired_response.status_code = 200
        expired_response.json.return_value = {"code": 37, "message": "Cookie expired"}
        success_response = MagicMock()
        success_response.status_code = 200
        success_response.json.return_value = {
            "code": 0,
            "zpData": {
                "jobInfo": {
                    "jobName": "Java",
                    "address": "深圳南山区",
                    "postDescription": "岗位职责: ...",
                },
                "brandComInfo": {"brandName": "望尘科技"},
            },
        }

        with patch.object(
            BossZhipinAdapter,
            "_refresh_cookies_via_cdp_target",
            new_callable=AsyncMock,
            return_value={"__zp_stoken__": "fresh", "other": "cookie"},
        ) as mock_refresh:
            with patch("app.platforms.boss.CffiSession") as mock_session_cls:
                mock_session = MagicMock()
                mock_session.get.side_effect = [expired_response, success_response]
                mock_session.cookies.get_dict.return_value = {"__zp_stoken__": "old"}
                mock_session_cls.return_value = mock_session

                adapter = BossZhipinAdapter()
                result = await adapter.crawl_detail("test_security_id")

        assert result["success"] is True
        assert result["detail"]["description"] == "岗位职责: ..."
        assert result["detail"]["address"] == "深圳南山区"
        mock_refresh.assert_awaited_once()
        mock_session.cookies.set.assert_any_call(
            "__zp_stoken__",
            "fresh",
            domain=".zhipin.com",
            path="/",
        )

    @pytest.mark.asyncio
    async def test_crawl_detail_allows_two_cookie_refreshes(self):
        """crawl_detail should tolerate repeated code=37 before succeeding."""
        from app.platforms.boss import BossZhipinAdapter

        expired_response = MagicMock()
        expired_response.status_code = 200
        expired_response.json.return_value = {"code": 37, "message": "Cookie expired"}
        success_response = MagicMock()
        success_response.status_code = 200
        success_response.json.return_value = {
            "code": 0,
            "zpData": {
                "jobInfo": {
                    "address": "深圳南山区",
                    "postDescription": "岗位职责: ...",
                },
                "brandComInfo": {"brandName": "望尘科技"},
            },
        }

        with patch.object(
            BossZhipinAdapter,
            "_refresh_cookies_via_cdp_target",
            new_callable=AsyncMock,
            return_value={"__zp_stoken__": "fresh"},
        ) as mock_refresh:
            with (
                patch("app.platforms.boss.CffiSession") as mock_session_cls,
                patch("app.platforms.boss.asyncio.sleep", new_callable=AsyncMock),
            ):
                mock_session = MagicMock()
                mock_session.get.side_effect = [
                    expired_response,
                    expired_response,
                    success_response,
                ]
                mock_session.cookies.get_dict.return_value = {"__zp_stoken__": "old"}
                mock_session_cls.return_value = mock_session

                adapter = BossZhipinAdapter()
                result = await adapter.crawl_detail("test_security_id")

        assert result["success"] is True
        assert result["detail"]["description"] == "岗位职责: ..."
        assert mock_refresh.await_count == 2

    @pytest.mark.asyncio
    async def test_crawl_refreshes_cookie_then_succeeds(self):
        """crawl should recover from code=37 by refreshing CDP cookies in memory."""
        from app.platforms.boss import BossZhipinAdapter

        expired_response = MagicMock()
        expired_response.status_code = 200
        expired_response.json.return_value = {"code": 37, "message": "Cookie expired"}
        expired_response.text = ""
        success_response = MagicMock()
        success_response.status_code = 200
        success_response.json.return_value = {
            "code": 0,
            "zpData": {
                "jobList": [{
                    "securityId": "security",
                    "encryptJobId": "encrypt",
                    "jobName": "Java",
                    "brandName": "望尘科技",
                }],
                "hasMore": False,
            },
        }
        success_response.text = ""

        with (
            patch.object(
                BossZhipinAdapter,
                "_get_cookies_via_raw_cdp",
                new_callable=AsyncMock,
                return_value={"__zp_stoken__": "old"},
            ),
            patch.object(
                BossZhipinAdapter,
                "_refresh_cookies_via_cdp_target",
                new_callable=AsyncMock,
                return_value={"__zp_stoken__": "fresh"},
            ) as mock_refresh,
            patch("app.platforms.boss.CffiSession") as mock_session_cls,
        ):
            mock_session = MagicMock()
            mock_session.get.side_effect = [expired_response, success_response]
            mock_session.cookies.get.return_value = ""
            mock_session_cls.return_value = mock_session

            adapter = BossZhipinAdapter()
            result = await adapter.crawl("https://www.zhipin.com/web/geek/jobs?query=java")

        assert result["success"] is True
        assert result["count"] == 1
        mock_refresh.assert_awaited_once()
        mock_session.cookies.set.assert_any_call(
            "__zp_stoken__",
            "fresh",
            domain=".zhipin.com",
            path="/",
        )


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

            with patch("app.platforms.BossZhipinAdapter") as mock_adapter_cls:
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
        """When no adapter is passed, a new BossZhipinAdapter should be created."""
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

            with patch("app.platforms.BossZhipinAdapter") as mock_cls:
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
            MagicMock(id=1, url="https://www.zhipin.com/web/geek/jobs?query=a"),
            MagicMock(id=2, url="https://www.zhipin.com/web/geek/jobs?query=b"),
            MagicMock(id=3, url="https://www.zhipin.com/web/geek/jobs?query=c"),
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

                with patch("app.platforms.BossZhipinAdapter") as mock_adapter_cls:
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
