"""Database-backed crawler profile pool."""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.crawler_paths import build_profile_dir
from app.core.profile_lease import ProfileLease
from app.models.crawl_profile import CrawlProfile

AVAILABLE = "available"
LEASED = "leased"
LOGIN_REQUIRED = "login_required"
COOLING_DOWN = "cooling_down"
DISABLED = "disabled"
BLOCKING_STATUSES = {LOGIN_REQUIRED, COOLING_DOWN, DISABLED}
DEFAULT_PROFILE_LEASE_SECONDS = 60 * 60


class ProfileAlreadyLeasedError(RuntimeError):
    """Raised when a profile directory is currently leased."""


class ProfileUnavailableError(RuntimeError):
    """Raised when a profile is not eligible for use."""


def _now() -> datetime:
    return datetime.now(UTC)


async def ensure_profile(
    db: AsyncSession,
    *,
    profile_key: str,
    root: str | Path | None = None,
    platform_hint: str | None = None,
) -> CrawlProfile:
    profile_dir = build_profile_dir(profile_key, root=root)
    result = await db.execute(
        select(CrawlProfile).where(CrawlProfile.profile_key == profile_key)
    )
    profile = result.scalar_one_or_none()
    current = _now()
    if profile is None:
        profile = CrawlProfile(
            profile_key=profile_key,
            profile_dir=str(profile_dir),
            status=AVAILABLE,
            platform_hint=platform_hint,
            created_at=current,
            updated_at=current,
        )
        db.add(profile)
    else:
        profile.profile_dir = str(profile_dir)
        if platform_hint and not profile.platform_hint:
            profile.platform_hint = platform_hint
        profile.updated_at = current
    await db.commit()
    await db.refresh(profile)
    return profile


async def _get_or_create_profile_for_update(
    db: AsyncSession,
    *,
    profile_key: str,
    root: str | Path | None,
    platform_hint: str | None,
) -> CrawlProfile:
    profile_dir = build_profile_dir(profile_key, root=root)
    current = _now()
    result = await db.execute(
        select(CrawlProfile)
        .where(CrawlProfile.profile_key == profile_key)
        .with_for_update()
    )
    profile = result.scalar_one_or_none()
    if profile is not None:
        profile.profile_dir = str(profile_dir)
        if platform_hint and not profile.platform_hint:
            profile.platform_hint = platform_hint
        profile.updated_at = current
        return profile

    profile = CrawlProfile(
        profile_key=profile_key,
        profile_dir=str(profile_dir),
        status=AVAILABLE,
        platform_hint=platform_hint,
        created_at=current,
        updated_at=current,
    )
    db.add(profile)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        result = await db.execute(
            select(CrawlProfile)
            .where(CrawlProfile.profile_key == profile_key)
            .with_for_update()
        )
        profile = result.scalar_one()
    return profile


class DatabaseProfilePool:
    def __init__(self, *, root: str | Path | None = None):
        self.root = root

    async def acquire(
        self,
        db: AsyncSession,
        *,
        platform: str,
        profile_key: str,
        owner: str,
        task_id: str,
        lease_seconds: int = DEFAULT_PROFILE_LEASE_SECONDS,
    ) -> ProfileLease:
        profile = await _get_or_create_profile_for_update(
            db,
            profile_key=profile_key,
            root=self.root,
            platform_hint=platform,
        )
        current = _now()
        if profile.status in BLOCKING_STATUSES:
            raise ProfileUnavailableError(
                f"Profile {profile_key!r} is {profile.status}"
            )
        if profile.lease_until and profile.lease_until > current:
            raise ProfileAlreadyLeasedError(
                f"Profile {profile_key!r} is leased by {profile.lease_owner}"
            )

        profile_dir = build_profile_dir(profile_key, root=self.root)
        profile_dir.mkdir(parents=True, exist_ok=True)
        profile.status = LEASED
        profile.lease_owner = owner
        profile.lease_task_id = task_id
        profile.lease_until = current + timedelta(seconds=lease_seconds)
        profile.last_used_at = current
        profile.updated_at = current
        await db.commit()
        await db.refresh(profile)

        return ProfileLease(
            platform=platform,
            profile_key=profile_key,
            profile_dir=profile_dir,
            owner=owner,
            task_id=task_id,
        )

    async def release(self, db: AsyncSession, lease: ProfileLease) -> None:
        result = await db.execute(
            select(CrawlProfile)
            .where(CrawlProfile.profile_key == lease.profile_key)
            .with_for_update()
        )
        profile = result.scalar_one_or_none()
        if profile is None:
            return
        if profile.lease_owner != lease.owner:
            return
        if lease.task_id is not None and profile.lease_task_id != lease.task_id:
            return
        if profile.status not in BLOCKING_STATUSES:
            profile.status = AVAILABLE
        profile.lease_owner = None
        profile.lease_task_id = None
        profile.lease_until = None
        profile.updated_at = _now()
        await db.commit()

    async def renew(
        self,
        db: AsyncSession,
        lease: ProfileLease,
        *,
        lease_seconds: int = DEFAULT_PROFILE_LEASE_SECONDS,
    ) -> None:
        result = await db.execute(
            select(CrawlProfile)
            .where(CrawlProfile.profile_key == lease.profile_key)
            .with_for_update()
        )
        profile = result.scalar_one_or_none()
        if profile is None:
            return
        if profile.lease_owner != lease.owner:
            return
        if lease.task_id is not None and profile.lease_task_id != lease.task_id:
            return
        current = _now()
        profile.lease_until = current + timedelta(seconds=lease_seconds)
        profile.last_used_at = current
        profile.updated_at = current
        await db.commit()

    @asynccontextmanager
    async def lease(
        self,
        db: AsyncSession,
        *,
        platform: str,
        profile_key: str,
        owner: str,
        task_id: str,
    ) -> AsyncIterator[ProfileLease]:
        acquired = await self.acquire(
            db,
            platform=platform,
            profile_key=profile_key,
            owner=owner,
            task_id=task_id,
        )
        try:
            yield acquired
        finally:
            await self.release(db, acquired)


async def recover_stale_profile_leases(
    db: AsyncSession,
    *,
    now: datetime | None = None,
) -> int:
    current = now or _now()
    result = await db.execute(
        select(CrawlProfile).where(
            CrawlProfile.lease_until.is_not(None),
            CrawlProfile.lease_until < current,
        )
    )
    profiles = result.scalars().all()
    for profile in profiles:
        profile.status = AVAILABLE
        profile.lease_owner = None
        profile.lease_task_id = None
        profile.lease_until = None
        profile.updated_at = current
    await db.commit()
    return len(profiles)
