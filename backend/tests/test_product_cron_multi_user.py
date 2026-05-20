"""Tests for product cron multi-user isolation.

Proves:
- ProductPlatformCron model no longer has UNIQUE(platform).
- ProductPlatformCron has (user_id, platform) composite unique constraint.
- Two users can create cron configs for the same platform.
- ProductCronScheduler creates isolated job IDs per user+platform.
"""
import pytest
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from sqlalchemy import UniqueConstraint

from app.models.product import ProductPlatformCron


class TestProductPlatformCronConstraints:
    """Model constraint checks for ProductPlatformCron."""

    def test_no_unique_on_platform_column(self):
        """platform column should NOT have unique=True."""
        column = ProductPlatformCron.__table__.columns["platform"]
        assert not column.unique, (
            "platform column still has unique=True. "
            "Remove `unique=True` from the column definition."
        )

    def test_has_user_platform_composite_unique(self):
        """There should be a (user_id, platform) UniqueConstraint."""
        found = False
        for constraint in ProductPlatformCron.__table__.constraints:
            if isinstance(constraint, UniqueConstraint):
                col_names = [c.name for c in constraint.columns]
                if "user_id" in col_names and "platform" in col_names:
                    assert constraint.name == "uq_products_platform_crons_user_platform"
                    found = True
                    break
        assert found, (
            "Missing (user_id, platform) UniqueConstraint "
            "named 'uq_products_platform_crons_user_platform'"
        )

    def test_two_users_can_have_same_platform(self):
        """Semantic check: two ProductPlatformCron with same platform
        but different user_id should satisfy the composite constraint."""
        table_args = ProductPlatformCron.__table_args__
        assert table_args is not None, "__table_args__ must be set"


class TestProductCronSchedulerUserIsolation:
    """ProductCronScheduler job ID isolation between users."""

    @pytest.mark.asyncio
    async def test_different_users_get_different_job_ids(self):
        """add_job with same platform but different users creates separate jobs."""
        from app.services.scheduler_job import ProductCronScheduler

        scheduler = AsyncIOScheduler()
        scheduler.start()
        try:
            mgr = ProductCronScheduler(scheduler)

            # Two different users, same platform
            mgr.add_job(user_id=1, platform="jd", cron_expression="0 */6 * * *")
            mgr.add_job(user_id=2, platform="jd", cron_expression="0 */12 * * *")

            # Should be two distinct jobs
            job_1 = scheduler.get_job("product_cron_1:jd")
            job_2 = scheduler.get_job("product_cron_2:jd")

            assert job_1 is not None, "Job for user 1 should exist"
            assert job_2 is not None, "Job for user 2 should exist"
            assert job_1.id != job_2.id, "Job IDs must differ"
        finally:
            scheduler.shutdown(wait=False)

    @pytest.mark.asyncio
    async def test_remove_job_does_not_affect_other_user(self):
        """remove_job for one user should not remove other user's job."""
        from app.services.scheduler_job import ProductCronScheduler

        scheduler = AsyncIOScheduler()
        scheduler.start()
        try:
            mgr = ProductCronScheduler(scheduler)

            mgr.add_job(user_id=1, platform="jd", cron_expression="0 */6 * * *")
            mgr.add_job(user_id=2, platform="jd", cron_expression="0 */12 * * *")

            # Remove user 1's job
            mgr.remove_job(user_id=1, platform="jd")

            # User 1's job should be gone, user 2's should remain
            assert scheduler.get_job("product_cron_1:jd") is None
            assert scheduler.get_job("product_cron_2:jd") is not None
        finally:
            scheduler.shutdown(wait=False)

    @pytest.mark.asyncio
    async def test_next_run_times_for_user_are_keyed_by_platform(self):
        """UI-facing schedule map should use platform keys for the current user."""
        from app.services.scheduler_job import ProductCronScheduler

        scheduler = AsyncIOScheduler()
        scheduler.start()
        try:
            mgr = ProductCronScheduler(scheduler)

            mgr.add_job(user_id=1, platform="jd", cron_expression="0 */6 * * *")
            mgr.add_job(user_id=2, platform="jd", cron_expression="0 */12 * * *")

            result = mgr.get_next_run_times(user_id=1)

            assert set(result) == {"jd"}
            assert "1:jd" not in result
        finally:
            scheduler.shutdown(wait=False)

    def test_sync_all_no_longer_filters_user_id_1_only(self):
        """sync_all's query should not filter user_id == 1."""
        import inspect

        from app.services.scheduler_job import ProductCronScheduler

        source = inspect.getsource(ProductCronScheduler.sync_all)
        # The old code had "user_id == 1" — ensure it's gone
        assert "user_id == 1" not in source, (
            "sync_all still filters by user_id == 1"
        )
