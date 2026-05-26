from contextlib import asynccontextmanager

import pytest
from sqlalchemy import delete

from app.database import AsyncSessionLocal
from app.domains.crawling.browser_manager import (
    BrowserManager,
    BrowserProfileUnavailableError,
)
from app.domains.crawling.profile_pool import LOGIN_REQUIRED, ensure_profile
from app.models.crawl_profile import CrawlProfile


async def _clean_profile(profile_key: str):
    async with AsyncSessionLocal() as s:
        await s.execute(
            delete(CrawlProfile).where(CrawlProfile.profile_key == profile_key)
        )
        await s.commit()


class FakePage:
    def __init__(self):
        self.closed = False

    async def close(self):
        self.closed = True


class FakeContext:
    def __init__(self):
        self.closed = False
        self.pages = []

    async def new_page(self):
        page = FakePage()
        self.pages.append(page)
        return page

    async def close(self):
        self.closed = True


class FakeChromium:
    def __init__(self, context):
        self.context = context
        self.launch_args = None

    async def launch_persistent_context(self, user_data_dir, **kwargs):
        self.launch_args = {"user_data_dir": str(user_data_dir), **kwargs}
        return self.context


class FakePlaywright:
    def __init__(self, context):
        self.chromium = FakeChromium(context)


@asynccontextmanager
async def fake_playwright_factory(context):
    yield FakePlaywright(context)


@pytest.mark.asyncio
async def test_browser_manager_acquires_and_releases_profile():
    profile_key = "product-jd-test-acquire"
    await _clean_profile(profile_key)
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key=profile_key, platform_hint="jd")
    fake_context = FakeContext()
    manager = BrowserManager(
        db_factory=lambda: AsyncSessionLocal(),
        playwright_factory=lambda: fake_playwright_factory(fake_context),
    )

    async with manager.acquire(
        platform="jd",
        profile_key=profile_key,
        owner="test-owner",
        task_id="task-1",
    ) as session:
        page = await session.new_page()
        await session.close_page(page)
        assert page.closed is True
        assert session.profile_key == profile_key

    assert fake_context.closed is True


@pytest.mark.asyncio
async def test_browser_manager_refuses_login_required_before_launch():
    profile_key = "product-jd-test-login"
    await _clean_profile(profile_key)
    async with AsyncSessionLocal() as db:
        profile = await ensure_profile(
            db,
            profile_key=profile_key,
            platform_hint="jd",
        )
        profile.status = LOGIN_REQUIRED
        await db.commit()
    fake_context = FakeContext()
    manager = BrowserManager(
        db_factory=lambda: AsyncSessionLocal(),
        playwright_factory=lambda: fake_playwright_factory(fake_context),
    )

    with pytest.raises(BrowserProfileUnavailableError) as exc:
        async with manager.acquire(
            platform="jd",
            profile_key=profile_key,
            owner="test-owner",
            task_id="task-1",
        ):
            pass

    assert "login_required" in str(exc.value)
    assert fake_context.closed is False


@pytest.mark.asyncio
async def test_browser_manager_records_startup_failure():
    profile_key = "product-jd-test-broken"
    await _clean_profile(profile_key)
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key=profile_key, platform_hint="jd")

    class BrokenChromium:
        async def launch_persistent_context(self, user_data_dir, **kwargs):
            raise RuntimeError("browser failed to start")

    class BrokenPlaywright:
        chromium = BrokenChromium()

    @asynccontextmanager
    async def broken_factory():
        yield BrokenPlaywright()

    manager = BrowserManager(
        db_factory=lambda: AsyncSessionLocal(),
        playwright_factory=broken_factory,
    )

    with pytest.raises(RuntimeError, match="browser failed to start"):
        async with manager.acquire(
            platform="jd",
            profile_key=profile_key,
            owner="test-owner",
            task_id="task-1",
        ):
            pass

    from app.domains.crawling.profile_service import get_profile

    async with AsyncSessionLocal() as db:
        profile = await get_profile(db, profile_key)
        assert "browser failed to start" in profile.last_error


@pytest.mark.parametrize("status", ["login_required", "disabled", "cooling_down"])
@pytest.mark.asyncio
async def test_browser_manager_blocked_statuses_fail_before_launch(status):
    profile_key = f"product-jd-test-{status}"
    await _clean_profile(profile_key)
    async with AsyncSessionLocal() as db:
        profile = await ensure_profile(db, profile_key=profile_key, platform_hint="jd")
        profile.status = status
        await db.commit()
    fake_context = FakeContext()
    manager = BrowserManager(
        db_factory=lambda: AsyncSessionLocal(),
        playwright_factory=lambda: fake_playwright_factory(fake_context),
    )

    with pytest.raises(BrowserProfileUnavailableError):
        async with manager.acquire(
            platform="jd",
            profile_key=profile_key,
            owner="test-owner",
            task_id="task-1",
        ):
            pass

    assert fake_context.pages == []
