import shutil
from datetime import UTC, datetime

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.crawler_paths import build_profile_dir
from app.core.system_log import emit_system_log_detached
from app.domains.crawling.profile_pool import (
    AVAILABLE,
    DISABLED,
    LOGIN_REQUIRED,
    ensure_profile,
)
from app.domains.crawling.profile_utils import (
    CrawlProfileLeaseActiveError,
    assert_profile_not_leased,
)
from app.models.crawl_profile import CrawlProfile


async def _emit_profile_event(
    profile_key: str,
    event_type: str,
    *,
    message: str,
    severity: str = "info",
    status: str = "success",
    payload: dict | None = None,
) -> None:
    """Emit a system log event for a crawl profile operation."""
    await emit_system_log_detached(
        category="runtime",
        event_type=event_type,
        source="crawler",
        severity=severity,
        status=status,
        message=message,
        entity_type="crawl_profile",
        entity_id=profile_key,
        payload=payload,
    )


class CrawlProfileNotFoundError(LookupError):
    """Raised when a crawl profile does not exist."""


class CrawlProfileInUseError(RuntimeError):
    """Raised when a crawl profile is referenced by configs."""


class CrawlProfileAlreadyExistsError(RuntimeError):
    """Raised when a target crawl profile key already exists."""


async def list_profiles(db: AsyncSession) -> list[CrawlProfile]:
    result = await db.execute(select(CrawlProfile).order_by(CrawlProfile.profile_key))
    return list(result.scalars().all())


async def create_profile(db: AsyncSession, *, profile_key: str, platform_hint: str | None) -> CrawlProfile:
    profile = await ensure_profile(db, profile_key=profile_key, platform_hint=platform_hint)
    build_profile_dir(profile_key).mkdir(parents=True, exist_ok=True)
    await _emit_profile_event(
        profile_key,
        "crawl_profile.created",
        message=f"Crawl profile {profile_key} created",
        payload={"profile_key": profile_key, "platform_hint": platform_hint},
    )
    return profile


async def _profile_exists(db: AsyncSession, profile_key: str) -> bool:
    result = await db.execute(select(CrawlProfile.id).where(CrawlProfile.profile_key == profile_key))
    return result.scalar_one_or_none() is not None


def _copy_profile_key(profile_key: str, counter: int | None = None) -> str:
    suffix = "-copy" if counter is None else f"-copy-{counter}"
    return f"{profile_key[: 80 - len(suffix)]}{suffix}"


async def rename_profile(
    db: AsyncSession,
    *,
    profile_key: str,
    new_profile_key: str,
) -> CrawlProfile:
    from app.models.job import JobSearchConfig
    from app.models.product import ProductPlatformCron, ProductPlatformProfileBinding

    if profile_key == new_profile_key:
        return await get_profile(db, profile_key)

    profile = await get_profile(db, profile_key)
    assert_profile_not_leased(profile)
    build_profile_dir(new_profile_key)
    if await _profile_exists(db, new_profile_key):
        raise CrawlProfileAlreadyExistsError(new_profile_key)

    old_dir = build_profile_dir(profile_key)
    new_dir = build_profile_dir(new_profile_key)
    if new_dir.exists():
        raise CrawlProfileAlreadyExistsError(new_profile_key)

    moved_dir = False
    created_dir = False
    if old_dir.exists():
        old_dir.rename(new_dir)
        moved_dir = True
    else:
        new_dir.mkdir(parents=True, exist_ok=False)
        created_dir = True

    current = datetime.now(UTC)
    renamed = CrawlProfile(
        profile_key=new_profile_key,
        profile_dir=str(new_dir),
        status=profile.status,
        platform_hint=profile.platform_hint,
        lease_owner=profile.lease_owner,
        lease_task_id=profile.lease_task_id,
        lease_until=profile.lease_until,
        last_used_at=profile.last_used_at,
        last_error=profile.last_error,
        created_at=profile.created_at,
        updated_at=current,
    )
    try:
        db.add(renamed)
        await db.flush()
        await db.execute(
            update(JobSearchConfig)
            .where(JobSearchConfig.profile_key == profile_key)
            .values(profile_key=new_profile_key)
        )
        await db.execute(
            update(ProductPlatformCron)
            .where(ProductPlatformCron.profile_key == profile_key)
            .values(profile_key=new_profile_key)
        )
        await db.execute(
            update(ProductPlatformProfileBinding)
            .where(ProductPlatformProfileBinding.profile_key == profile_key)
            .values(profile_key=new_profile_key)
        )
        await db.delete(profile)
        await db.commit()
        await db.refresh(renamed)
    except Exception:
        await db.rollback()
        if moved_dir and new_dir.exists() and not old_dir.exists():
            new_dir.rename(old_dir)
        elif created_dir and new_dir.exists():
            shutil.rmtree(new_dir)
        raise

    await _emit_profile_event(
        new_profile_key,
        "crawl_profile.renamed",
        message=f"Crawl profile {profile_key} renamed to {new_profile_key}",
        payload={"old_profile_key": profile_key, "profile_key": new_profile_key},
    )
    return renamed


async def copy_profile(db: AsyncSession, *, profile_key: str) -> CrawlProfile:
    profile = await get_profile(db, profile_key)
    assert_profile_not_leased(profile)

    new_profile_key = _copy_profile_key(profile_key)
    counter = 2
    while await _profile_exists(db, new_profile_key) or build_profile_dir(new_profile_key).exists():
        new_profile_key = _copy_profile_key(profile_key, counter)
        counter += 1

    old_dir = build_profile_dir(profile_key)
    new_dir = build_profile_dir(new_profile_key)
    if old_dir.exists():
        shutil.copytree(old_dir, new_dir)
    else:
        new_dir.mkdir(parents=True, exist_ok=False)

    current = datetime.now(UTC)
    copied = CrawlProfile(
        profile_key=new_profile_key,
        profile_dir=str(new_dir),
        status=AVAILABLE,
        platform_hint=profile.platform_hint,
        created_at=current,
        updated_at=current,
    )
    try:
        db.add(copied)
        await db.commit()
        await db.refresh(copied)
    except Exception:
        await db.rollback()
        if new_dir.exists():
            shutil.rmtree(new_dir)
        raise

    await _emit_profile_event(
        new_profile_key,
        "crawl_profile.copied",
        message=f"Crawl profile {profile_key} copied to {new_profile_key}",
        payload={"source_profile_key": profile_key, "profile_key": new_profile_key},
    )
    return copied


async def delete_profile(db: AsyncSession, *, profile_key: str) -> None:
    from app.models.job import JobSearchConfig
    from app.models.product import ProductPlatformCron, ProductPlatformProfileBinding

    profile = await get_profile(db, profile_key)
    assert_profile_not_leased(profile)

    job_ref = await db.execute(
        select(JobSearchConfig.id).where(JobSearchConfig.profile_key == profile_key).limit(1)
    )
    if job_ref.scalar_one_or_none() is not None:
        raise CrawlProfileInUseError(profile_key)

    profile_dir = build_profile_dir(profile_key)
    await db.execute(
        delete(ProductPlatformProfileBinding).where(
            ProductPlatformProfileBinding.profile_key == profile_key
        )
    )
    await db.execute(
        update(ProductPlatformCron)
        .where(ProductPlatformCron.profile_key == profile_key)
        .values(profile_key=None)
    )
    await db.delete(profile)
    await db.commit()
    if profile_dir.exists():
        shutil.rmtree(profile_dir)
    await _emit_profile_event(
        profile_key,
        "crawl_profile.deleted",
        severity="warning",
        message=f"Crawl profile {profile_key} deleted",
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
    await _emit_profile_event(
        profile_key,
        "crawl_profile.updated",
        severity="warning" if status in {LOGIN_REQUIRED, DISABLED} else "info",
        message=f"Crawl profile {profile_key} updated",
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
    await _emit_profile_event(
        profile_key,
        "crawl_profile.stale_lease_released",
        severity="warning",
        message=f"Stale lease released for crawl profile {profile_key}",
        payload={"profile_key": profile_key},
    )
    return profile
