from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.database import get_db
from app.domains.crawling import profile_service
from app.models.user import User
from app.schemas.crawl_profile import (
    CrawlProfileCreate,
    CrawlProfileResponse,
    CrawlProfileUpdate,
)

router = APIRouter(prefix="/crawl-profiles", tags=["crawl-profiles"])


@router.get("", response_model=list[CrawlProfileResponse])
async def list_profiles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await profile_service.list_profiles(db)


@router.post("", response_model=CrawlProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_profile(
    data: CrawlProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await profile_service.create_profile(
        db,
        profile_key=data.profile_key,
        platform_hint=data.platform_hint,
    )


@router.patch("/{profile_key}", response_model=CrawlProfileResponse)
async def update_profile(
    profile_key: str,
    data: CrawlProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await profile_service.update_profile(
            db,
            profile_key=profile_key,
            status=data.status,
            platform_hint=data.platform_hint,
            last_error=data.last_error,
        )
    except profile_service.CrawlProfileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Profile not found") from exc
    except profile_service.CrawlProfileLeaseActiveError as exc:
        raise HTTPException(status_code=409, detail="Profile lease is still active") from exc


@router.post("/{profile_key}/release-stale", response_model=CrawlProfileResponse)
async def release_stale_profile(
    profile_key: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await profile_service.release_stale_profile(db, profile_key=profile_key)
    except profile_service.CrawlProfileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Profile not found") from exc
    except profile_service.CrawlProfileLeaseActiveError as exc:
        raise HTTPException(status_code=409, detail="Profile lease is still active") from exc
