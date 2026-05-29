from __future__ import annotations

import logging
from collections.abc import AsyncIterator, Callable
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from uuid import uuid4

from playwright.async_api import BrowserContext, Page, async_playwright
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.crawler_paths import build_profile_dir
from app.core.profile_lease import ProfileLease
from app.core.system_log import emit_system_log_detached
from app.database import AsyncSessionLocal
from app.domains.crawling.profile_pool import (
    COOLING_DOWN,
    DISABLED,
    LOGIN_REQUIRED,
    DatabaseProfilePool,
    ProfileAlreadyLeasedError,
    ProfileUnavailableError,
)
from app.domains.crawling.profile_service import get_profile

BLOCKED_PROFILE_STATUSES = {LOGIN_REQUIRED, DISABLED, COOLING_DOWN}
logger = logging.getLogger(__name__)


class BrowserProfileUnavailableError(RuntimeError):
    """Raised when a profile cannot be leased or used."""


class BrowserPageLimitError(RuntimeError):
    """Raised when a session tries to open more pages than allowed."""


@dataclass
class BrowserSession:
    profile_key: str
    profile_dir: Path
    platform: str
    context: BrowserContext
    max_pages: int = 1
    _open_pages: set[Page] = field(default_factory=set)

    async def new_page(self) -> Page:
        if len(self._open_pages) >= self.max_pages:
            raise BrowserPageLimitError(
                f"profile {self.profile_key} reached max_pages={self.max_pages}"
            )
        page = await self.context.new_page()
        self._open_pages.add(page)
        return page

    async def close_page(self, page: Page) -> None:
        try:
            await page.close()
        except Exception as exc:
            logger.debug(
                "Ignoring product browser page close failure for profile %s: %s",
                self.profile_key,
                exc,
            )
        finally:
            self._open_pages.discard(page)

    async def close(self) -> None:
        for page in list(self._open_pages):
            await self.close_page(page)
        try:
            await self.context.close()
        except Exception as exc:
            logger.debug(
                "Ignoring product browser context close failure for profile %s: %s",
                self.profile_key,
                exc,
            )


class BrowserManager:
    def __init__(
        self,
        *,
        db_factory: async_sessionmaker[AsyncSession] | Callable[[], AsyncSession] = AsyncSessionLocal,
        playwright_factory=async_playwright,
        max_pages: int = 1,
    ) -> None:
        self._db_factory = db_factory
        self._playwright_factory = playwright_factory
        self._max_pages = max_pages

    @asynccontextmanager
    async def _db(self) -> AsyncIterator[AsyncSession]:
        session_or_cm = self._db_factory()
        if hasattr(session_or_cm, "__aenter__"):
            async with session_or_cm as session:
                yield session
        else:
            yield session_or_cm

    async def _mark_profile_error(self, profile_key: str, error: str) -> None:
        async with self._db() as db:
            profile = await get_profile(db, profile_key)
            profile.last_error = error[:2000]
            profile.updated_at = datetime.now(UTC)
            await db.commit()

    async def _assert_profile_usable(self, db: AsyncSession, profile_key: str) -> None:
        profile = await get_profile(db, profile_key)
        if profile.status in BLOCKED_PROFILE_STATUSES:
            await emit_system_log_detached(
                category="runtime",
                event_type=f"product_profile.{profile.status}",
                source="crawler",
                severity="warning",
                status="failed",
                message=f"Product profile {profile_key} is {profile.status}",
                entity_type="crawl_profile",
                entity_id=profile_key,
                payload={"profile_key": profile_key, "status": profile.status},
            )
            raise BrowserProfileUnavailableError(
                f"profile {profile_key} is {profile.status}"
            )

    @asynccontextmanager
    async def acquire(
        self,
        *,
        platform: str,
        profile_key: str,
        owner: str,
        task_id: str | None = None,
    ) -> AsyncIterator[BrowserSession]:
        task_id = task_id or str(uuid4())
        profile_dir = build_profile_dir(profile_key)
        context: BrowserContext | None = None
        session: BrowserSession | None = None
        lease: ProfileLease | None = None
        async with self._db() as db:
            await self._assert_profile_usable(db, profile_key)
            pool = DatabaseProfilePool()
            try:
                lease = await pool.acquire(
                    db,
                    platform=platform,
                    profile_key=profile_key,
                    owner=owner,
                    task_id=task_id,
                )
            except ProfileAlreadyLeasedError as exc:
                await emit_system_log_detached(
                    category="runtime",
                    event_type="product_profile.leased",
                    source="crawler",
                    severity="warning",
                    status="failed",
                    message=f"Product profile {profile_key} is already leased",
                    entity_type="crawl_profile",
                    entity_id=profile_key,
                    payload={"profile_key": profile_key, "task_id": task_id},
                )
                raise BrowserProfileUnavailableError(
                    f"profile {profile_key} is already leased"
                ) from exc
            except ProfileUnavailableError as exc:
                raise BrowserProfileUnavailableError(str(exc)) from exc

        try:
            async with self._playwright_factory() as playwright:
                try:
                    context = await playwright.chromium.launch_persistent_context(
                        str(profile_dir),
                        headless=True,
                        args=["--disable-blink-features=AutomationControlled"],
                    )
                except Exception as exc:
                    await self._mark_profile_error(profile_key, str(exc))
                    await emit_system_log_detached(
                        category="runtime",
                        event_type="product_browser.start_failed",
                        source="crawler",
                        severity="error",
                        status="failed",
                        message=f"Product browser failed for {profile_key}: {exc}",
                        entity_type="crawl_profile",
                        entity_id=profile_key,
                        payload={"profile_key": profile_key, "platform": platform},
                    )
                    raise

                await emit_system_log_detached(
                    category="runtime",
                    event_type="product_browser.session_started",
                    source="crawler",
                    severity="info",
                    status="success",
                    message=f"Product browser session started for {profile_key}",
                    entity_type="crawl_profile",
                    entity_id=profile_key,
                    payload={"profile_key": profile_key, "platform": platform},
                )
                session = BrowserSession(
                    profile_key=profile_key,
                    profile_dir=profile_dir,
                    platform=platform,
                    context=context,
                    max_pages=self._max_pages,
                )
                yield session
        finally:
            try:
                if session is not None:
                    await session.close()
                elif context is not None:
                    await context.close()
            finally:
                if context is not None:
                    await emit_system_log_detached(
                        category="runtime",
                        event_type="product_browser.session_closed",
                        source="crawler",
                        severity="info",
                        status="success",
                        message=f"Product browser session closed for {profile_key}",
                        entity_type="crawl_profile",
                        entity_id=profile_key,
                        payload={"profile_key": profile_key, "platform": platform},
                    )
                async with self._db() as db:
                    if lease is not None:
                        await DatabaseProfilePool().release(db, lease)
