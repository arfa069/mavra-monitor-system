from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.database import get_db
from app.domains.crawling import profile_runtime_service, profile_service
from app.models.user import User
from app.schemas.crawl_profile import (
    CrawlProfileBackupExportRequest,
    CrawlProfileBackupImportResponse,
    CrawlProfileCreate,
    CrawlProfileLoginSessionRequest,
    CrawlProfileLoginSessionResponse,
    CrawlProfileResponse,
    CrawlProfileRuntimeCapabilities,
    CrawlProfileTestRequest,
    CrawlProfileTestResponse,
    CrawlProfileUpdate,
)

router = APIRouter(prefix="/crawl-profiles", tags=["crawl-profiles"])


def _require_admin(current_user: User) -> None:
    if current_user.role not in {"admin", "super_admin"}:
        raise HTTPException(status_code=403, detail="Admin role required")


@router.get("/runtime-capabilities", response_model=CrawlProfileRuntimeCapabilities)
async def get_runtime_capabilities(
    current_user: User = Depends(get_current_user),
):
    return profile_runtime_service.runtime_capabilities()


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


@router.post("/{profile_key}/login-session", response_model=CrawlProfileLoginSessionResponse)
async def open_login_session(
    profile_key: str,
    data: CrawlProfileLoginSessionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await profile_runtime_service.open_login_session(
            db,
            profile_key=profile_key,
            platform_name=data.platform,
            start_url=data.start_url,
        )
    except profile_service.CrawlProfileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Profile not found") from exc
    except profile_service.CrawlProfileLeaseActiveError as exc:
        raise HTTPException(status_code=409, detail="Profile lease is still active") from exc
    except profile_runtime_service.ProfileAlreadyOpenError as exc:
        raise HTTPException(status_code=409, detail="Profile login session is already open") from exc
    except profile_runtime_service.ProfileAlreadyOpenError as exc:
        raise HTTPException(status_code=409, detail="Profile login session is already open") from exc
    except profile_runtime_service.ProfileRuntimeUnsupportedError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/{profile_key}/login-session", response_model=CrawlProfileLoginSessionResponse)
async def get_login_session(
    profile_key: str,
    current_user: User = Depends(get_current_user),
):
    return await profile_runtime_service.get_login_session(profile_key)


@router.post("/{profile_key}/login-session/close", response_model=CrawlProfileLoginSessionResponse)
async def close_login_session(
    profile_key: str,
    current_user: User = Depends(get_current_user),
):
    return await profile_runtime_service.close_login_session(profile_key)


@router.post("/{profile_key}/test", response_model=CrawlProfileTestResponse)
async def test_profile(
    profile_key: str,
    data: CrawlProfileTestRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await profile_runtime_service.test_profile(
            db,
            profile_key=profile_key,
            platform_name=data.platform,
            start_url=data.start_url,
        )
    except profile_service.CrawlProfileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Profile not found") from exc
    except profile_service.CrawlProfileLeaseActiveError as exc:
        raise HTTPException(status_code=409, detail="Profile lease is still active") from exc
    except profile_runtime_service.ProfileAlreadyOpenError as exc:
        raise HTTPException(status_code=409, detail="Profile login session is already open") from exc


@router.post("/{profile_key}/export")
async def export_profile_backup(
    profile_key: str,
    data: CrawlProfileBackupExportRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    try:
        content = await profile_runtime_service.export_profile_backup(
            db,
            profile_key=profile_key,
            password=data.password,
        )
    except profile_service.CrawlProfileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Profile not found") from exc
    except profile_service.CrawlProfileLeaseActiveError as exc:
        raise HTTPException(status_code=409, detail="Profile lease is still active") from exc
    return Response(
        content=content,
        media_type="application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="{profile_key}.pmprofile"'},
    )


@router.post("/{profile_key}/import", response_model=CrawlProfileBackupImportResponse)
async def import_profile_backup(
    profile_key: str,
    password: str = Form(...),
    force: bool = Form(False),
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    try:
        await profile_runtime_service.import_profile_backup(
            db,
            profile_key=profile_key,
            password=password,
            data=await file.read(),
            force=force,
        )
    except profile_service.CrawlProfileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Profile not found") from exc
    except profile_service.CrawlProfileLeaseActiveError as exc:
        raise HTTPException(status_code=409, detail="Profile lease is still active") from exc
    except (
        profile_runtime_service.ProfileAlreadyOpenError,
        profile_runtime_service.ProfileBackupError,
    ) as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    return CrawlProfileBackupImportResponse(profile_key=profile_key, imported=True)
