import pytest
from sqlalchemy import delete, select

from app.database import AsyncSessionLocal
from app.models.crawl_profile import CrawlProfile as CrawlProfileModel


def test_crawl_profile_model_table_name_and_required_columns():
    from app.models.crawl_profile import CrawlProfile

    columns = CrawlProfile.__table__.columns

    assert CrawlProfile.__tablename__ == "crawl_profiles"
    assert columns["profile_key"].nullable is False
    assert columns["profile_dir"].nullable is False
    assert columns["status"].nullable is False


async def _clean_profiles():
    async with AsyncSessionLocal() as s:
        await s.execute(delete(CrawlProfileModel))
        await s.commit()


@pytest.mark.asyncio
async def test_profile_pool_acquires_and_releases_profile(tmp_path):
    from app.domains.crawling.profile_pool import DatabaseProfilePool

    await _clean_profiles()
    async with AsyncSessionLocal() as db:
        pool = DatabaseProfilePool(root=tmp_path)

        lease = await pool.acquire(
            db, platform="boss", profile_key="default", owner="task-1", task_id="task-1",
        )

        assert lease.profile_key == "default"
        assert lease.profile_dir == tmp_path / "profiles" / "default"

        await pool.release(db, lease)
        second = await pool.acquire(
            db, platform="51job", profile_key="default", owner="task-2", task_id="task-2",
        )

        assert second.profile_key == "default"


@pytest.mark.asyncio
async def test_profile_pool_rejects_same_profile_across_platforms(tmp_path):
    from app.domains.crawling.profile_pool import (
        DatabaseProfilePool,
        ProfileAlreadyLeasedError,
    )

    await _clean_profiles()
    async with AsyncSessionLocal() as db:
        pool = DatabaseProfilePool(root=tmp_path)
        await pool.acquire(
            db, platform="boss", profile_key="default", owner="task-1", task_id="task-1",
        )

        with pytest.raises(ProfileAlreadyLeasedError):
            await pool.acquire(
                db, platform="51job", profile_key="default", owner="task-2", task_id="task-2",
            )


@pytest.mark.asyncio
async def test_profile_pool_allows_different_profiles(tmp_path):
    from app.domains.crawling.profile_pool import DatabaseProfilePool

    await _clean_profiles()
    async with AsyncSessionLocal() as db:
        pool = DatabaseProfilePool(root=tmp_path)
        first = await pool.acquire(
            db, platform="boss", profile_key="profile-a", owner="task-1", task_id="task-1",
        )
        second = await pool.acquire(
            db, platform="boss", profile_key="profile-b", owner="task-2", task_id="task-2",
        )

        assert first.profile_dir != second.profile_dir


@pytest.mark.asyncio
async def test_profile_pool_rejects_login_required_profile(tmp_path):
    from app.domains.crawling.profile_pool import (
        DatabaseProfilePool,
        ProfileUnavailableError,
        ensure_profile,
    )

    await _clean_profiles()
    async with AsyncSessionLocal() as db:
        profile = await ensure_profile(db, profile_key="default", root=tmp_path)
        profile.status = "login_required"
        await db.commit()

        pool = DatabaseProfilePool(root=tmp_path)
        with pytest.raises(ProfileUnavailableError):
            await pool.acquire(
                db, platform="boss", profile_key="default", owner="task-1", task_id="task-1",
            )


@pytest.mark.asyncio
async def test_profile_pool_old_lease_cannot_release_new_owner(tmp_path):
    from datetime import UTC, datetime, timedelta

    from app.domains.crawling.profile_pool import DatabaseProfilePool

    await _clean_profiles()
    async with AsyncSessionLocal() as db:
        pool = DatabaseProfilePool(root=tmp_path)
        first = await pool.acquire(
            db,
            platform="boss",
            profile_key="default",
            owner="task-1",
            task_id="task-1",
            lease_seconds=1,
        )
        result = await db.execute(
            select(CrawlProfileModel).where(CrawlProfileModel.profile_key == "default")
        )
        profile = result.scalar_one()
        profile.lease_until = datetime.now(UTC) - timedelta(seconds=1)
        await db.commit()

        await pool.acquire(
            db,
            platform="51job",
            profile_key="default",
            owner="task-2",
            task_id="task-2",
        )
        await pool.release(db, first)

        result = await db.execute(
            select(CrawlProfileModel).where(CrawlProfileModel.profile_key == "default")
        )
        profile = result.scalar_one()
        assert profile.lease_owner == "task-2"
        assert profile.lease_task_id == "task-2"
        assert profile.status == "leased"


@pytest.mark.asyncio
async def test_profile_pool_old_lease_cannot_renew_new_owner(tmp_path):
    from datetime import UTC, datetime, timedelta

    from app.domains.crawling.profile_pool import DatabaseProfilePool

    await _clean_profiles()
    async with AsyncSessionLocal() as db:
        pool = DatabaseProfilePool(root=tmp_path)
        first = await pool.acquire(
            db,
            platform="boss",
            profile_key="default",
            owner="task-1",
            task_id="task-1",
            lease_seconds=1,
        )
        result = await db.execute(
            select(CrawlProfileModel).where(CrawlProfileModel.profile_key == "default")
        )
        profile = result.scalar_one()
        profile.lease_until = datetime.now(UTC) - timedelta(seconds=1)
        await db.commit()

        await pool.acquire(
            db,
            platform="51job",
            profile_key="default",
            owner="task-2",
            task_id="task-2",
        )
        result = await db.execute(
            select(CrawlProfileModel).where(CrawlProfileModel.profile_key == "default")
        )
        profile = result.scalar_one()
        second_until = profile.lease_until

        await pool.renew(db, first, lease_seconds=3600)

        result = await db.execute(
            select(CrawlProfileModel).where(CrawlProfileModel.profile_key == "default")
        )
        profile = result.scalar_one()
        assert profile.lease_owner == "task-2"
        assert profile.lease_until == second_until
