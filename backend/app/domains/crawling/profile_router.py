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
    CrawlProfileRenameRequest,
    CrawlProfileResponse,
    CrawlProfileRuntimeCapabilities,
    CrawlProfileTestRequest,
    CrawlProfileTestResponse,
    CrawlProfileUpdate,
)

router = APIRouter(prefix="/crawl-profiles", tags=["crawl-profiles"])

# All profile exceptions that map to HTTPException responses
_PROFILE_EXCEPTIONS = (
    profile_service.CrawlProfileNotFoundError,
    profile_service.CrawlProfileLeaseActiveError,
    profile_service.CrawlProfileAlreadyExistsError,
    profile_service.CrawlProfileInUseError,
    profile_runtime_service.ProfileAlreadyOpenError,
    profile_runtime_service.ProfileRuntimeUnsupportedError,
    profile_runtime_service.ProfileBackupError,
)


def _require_admin(current_user: User) -> None:
    if current_user.role not in {"admin", "super_admin"}:
        raise HTTPException(status_code=403, detail="Admin role required")


def _raise_profile_http(exc: Exception) -> None:
    """Map profile domain exceptions to HTTPExceptions."""
    if isinstance(exc, profile_service.CrawlProfileNotFoundError):
        raise HTTPException(status_code=404, detail="Profile not found") from exc
    if isinstance(exc, profile_service.CrawlProfileLeaseActiveError):
        raise HTTPException(status_code=409, detail="Profile lease is still active") from exc
    if isinstance(exc, profile_service.CrawlProfileAlreadyExistsError):
        raise HTTPException(status_code=409, detail="Profile already exists") from exc
    if isinstance(exc, profile_service.CrawlProfileInUseError):
        raise HTTPException(status_code=409, detail="Profile is used by configs") from exc
    if isinstance(exc, profile_runtime_service.ProfileAlreadyOpenError):
        raise HTTPException(status_code=409, detail="Profile login session is already open") from exc
    if isinstance(exc, profile_runtime_service.ProfileRuntimeUnsupportedError):
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if isinstance(exc, profile_runtime_service.ProfileBackupError):
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    raise


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


@router.post("/{profile_key}/rename", response_model=CrawlProfileResponse)
async def rename_profile(
    profile_key: str,
    data: CrawlProfileRenameRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if profile_runtime_service.is_login_session_open(profile_key):
        raise HTTPException(status_code=409, detail="Profile login session is already open")
    try:
        return await profile_service.rename_profile(
            db,
            profile_key=profile_key,
            new_profile_key=data.profile_key,
        )
    except _PROFILE_EXCEPTIONS as exc:
        _raise_profile_http(exc)


@router.post("/{profile_key}/copy", response_model=CrawlProfileResponse, status_code=status.HTTP_201_CREATED)
async def copy_profile(
    profile_key: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if profile_runtime_service.is_login_session_open(profile_key):
        raise HTTPException(status_code=409, detail="Profile login session is already open")
    try:
        return await profile_service.copy_profile(db, profile_key=profile_key)
    except _PROFILE_EXCEPTIONS as exc:
        _raise_profile_http(exc)


@router.delete("/{profile_key}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(
    profile_key: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if profile_runtime_service.is_login_session_open(profile_key):
        raise HTTPException(status_code=409, detail="Profile login session is already open")
    try:
        await profile_service.delete_profile(db, profile_key=profile_key)
    except _PROFILE_EXCEPTIONS as exc:
        _raise_profile_http(exc)
    return None


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
    except _PROFILE_EXCEPTIONS as exc:
        _raise_profile_http(exc)


@router.post("/{profile_key}/release-stale", response_model=CrawlProfileResponse)
async def release_stale_profile(
    profile_key: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await profile_service.release_stale_profile(db, profile_key=profile_key)
    except _PROFILE_EXCEPTIONS as exc:
        _raise_profile_http(exc)


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
    except _PROFILE_EXCEPTIONS as exc:
        _raise_profile_http(exc)


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
    except _PROFILE_EXCEPTIONS as exc:
        _raise_profile_http(exc)


@router.post(
    "/{profile_key}/export",
    response_class=Response,
    responses={
        200: {
            "description": "Encrypted crawl profile backup",
            "content": {
                "application/octet-stream": {
                    "schema": {"type": "string", "format": "binary"}
                }
            },
            "headers": {
                "Content-Disposition": {
                    "schema": {"type": "string"},
                    "description": "Attachment filename",
                }
            },
        }
    },
)
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
    except _PROFILE_EXCEPTIONS as exc:
        _raise_profile_http(exc)
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
    except _PROFILE_EXCEPTIONS as exc:
        _raise_profile_http(exc)
    return CrawlProfileBackupImportResponse(profile_key=profile_key, imported=True)
