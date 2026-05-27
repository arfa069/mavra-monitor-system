import shutil
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.crawler_paths import build_profile_dir
from app.core.system_log import emit_system_log_detached
from app.domains.crawling.profile_pool import (
    AVAILABLE,
    DISABLED,
    LOGIN_REQUIRED,
    ensure_profile,
)
from app.models.crawl_profile import CrawlProfile


class CrawlProfileNotFoundError(LookupError):
    """Raised when a crawl profile does not exist."""


class CrawlProfileLeaseActiveError(RuntimeError):
    """Raised when a non-expired lease is still active."""


class CrawlProfileInUseError(RuntimeError):
    """Raised when a crawl profile is referenced by configs."""


async def list_profiles(db: AsyncSession) -> list[CrawlProfile]:
    result = await db.execute(select(CrawlProfile).order_by(CrawlProfile.profile_key))
    return list(result.scalars().all())


async def create_profile(db: AsyncSession, *, profile_key: str, platform_hint: str | None) -> CrawlProfile:
    profile = await ensure_profile(db, profile_key=profile_key, platform_hint=platform_hint)
    build_profile_dir(profile_key).mkdir(parents=True, exist_ok=True)
    await emit_system_log_detached(
        category="runtime",
        event_type="crawl_profile.created",
        source="crawler",
        severity="info",
        status="success",
        message=f"Crawl profile {profile_key} created",
        entity_type="crawl_profile",
        entity_id=profile_key,
        payload={"profile_key": profile_key, "platform_hint": platform_hint},
    )
    return profile


async def delete_profile(db: AsyncSession, *, profile_key: str) -> None:
    from app.models.job import JobSearchConfig
    from app.models.product import ProductPlatformCron

    profile = await get_profile(db, profile_key)
    current = datetime.now(UTC)
    if profile.lease_until is not None and profile.lease_until > current:
        raise CrawlProfileLeaseActiveError(profile_key)

    job_ref = await db.execute(
        select(JobSearchConfig.id).where(JobSearchConfig.profile_key == profile_key).limit(1)
    )
    product_ref = await db.execute(
        select(ProductPlatformCron.id).where(ProductPlatformCron.profile_key == profile_key).limit(1)
    )
    if job_ref.scalar_one_or_none() is not None or product_ref.scalar_one_or_none() is not None:
        raise CrawlProfileInUseError(profile_key)

    profile_dir = build_profile_dir(profile_key)
    await db.delete(profile)
    await db.commit()
    if profile_dir.exists():
        shutil.rmtree(profile_dir)
    await emit_system_log_detached(
        category="runtime",
        event_type="crawl_profile.deleted",
        source="crawler",
        severity="warning",
        status="success",
        message=f"Crawl profile {profile_key} deleted",
        entity_type="crawl_profile",
        entity_id=profile_key,
        payload={"profile_key": profile_key},
    )


async def get_profile(db: AsyncSession, profile_key: str) -> CrawlProfile:
    build_profile_dir(profile_key)
    result = await db.execute(select(CrawlProfile).where(CrawlProfile.profile_key == profile_key))
    profile = result.scalar_one_or_none()
    if profile is None:
        raise CrawlProfileNotFoundError(profile_key)
    return profile


async def update_profile(
    db: AsyncSession,
    *,
    profile_key: str,
    status: str | None,
    platform_hint: str | None,
    last_error: str | None,
) -> CrawlProfile:
    profile = await get_profile(db, profile_key)
    current = datetime.now(UTC)
    if status is not None:
        if status == AVAILABLE:
            if profile.lease_until is not None and profile.lease_until > current:
                raise CrawlProfileLeaseActiveError(profile_key)
            profile.lease_owner = None
            profile.lease_task_id = None
            profile.lease_until = None
        profile.status = status
    if platform_hint is not None:
        profile.platform_hint = platform_hint
    if last_error is not None:
        profile.last_error = last_error
    profile.updated_at = current
    await db.commit()
    await db.refresh(profile)
    await emit_system_log_detached(
        category="runtime",
        event_type="crawl_profile.updated",
        source="crawler",
        severity="warning" if status in {LOGIN_REQUIRED, DISABLED} else "info",
        status="success",
        message=f"Crawl profile {profile_key} updated",
        entity_type="crawl_profile",
        entity_id=profile_key,
        payload={"profile_key": profile_key, "status": profile.status},
    )
    return profile


async def release_stale_profile(db: AsyncSession, *, profile_key: str) -> CrawlProfile:
    profile = await get_profile(db, profile_key)
    current = datetime.now(UTC)
    if profile.lease_until is not None and profile.lease_until > current:
        raise CrawlProfileLeaseActiveError(profile_key)
    profile.status = AVAILABLE
    profile.lease_owner = None
    profile.lease_task_id = None
    profile.lease_until = None
    profile.updated_at = current
    await db.commit()
    await db.refresh(profile)
    await emit_system_log_detached(
        category="runtime",
        event_type="crawl_profile.stale_lease_released",
        source="crawler",
        severity="warning",
        status="success",
        message=f"Stale lease released for crawl profile {profile_key}",
        entity_type="crawl_profile",
        entity_id=profile_key,
        payload={"profile_key": profile_key},
    )
    return profile
