"""Authentication API routes.

提供用户认证相关功能：注册、登录、登出、获取当前用户信息。

## Endpoints

| Method | Path | Description | Auth Required |
|--------|------|-------------|---------------|
| POST | /auth/register | Register new user | No |
| POST | /auth/login | User login | No |
| POST | /auth/refresh | Refresh tokens | No (cookie) |
| POST | /auth/logout | User logout | Yes (cookie) |
| GET | /auth/me | Get current user info | Yes (cookie) |
| PATCH | /auth/me | Update profile | Yes (cookie) |
| POST | /auth/me/password | Change password | Yes (cookie) |
| GET | /auth/me/login-history | Login history | Yes (cookie) |
| GET | /auth/sessions | List all sessions | Yes (cookie) |
| DELETE | /auth/sessions/{id} | Delete a session | Yes (cookie) |
| DELETE | /auth/sessions | Delete other sessions | Yes (cookie) |

## Error Codes

| Status | Description |
|--------|-------------|
| 201 | Registration successful |
| 200 | Login/logout/me successful |
| 400 | Username or email already registered |
| 401 | Authentication failed |
| 403 | CSRF validation failed |
| 422 | Validation failed |
| 429 | Too many requests (locked for 15 min after 5 failures) |
"""
import logging
from datetime import datetime

from fastapi import APIRouter, Body, Depends, HTTPException, Request, Response, status
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.audit import log_audit, log_audit_from_request
from app.core.auth_cookies import (
    clear_auth_cookies,
    refresh_cookie_max_age,
    set_web_refresh_cookie,
)
from app.core.permissions import get_role_permissions
from app.core.security import (
    clear_login_attempts,
    create_access_token_sid,
    create_refresh_token,
    csrf_protect,
    decode_access_token_strict,
    delete_other_sessions,
    delete_session,
    get_access_token_expires_in_seconds,
    get_current_user,
    get_password_hash,
    get_session_by_id,
    get_session_by_refresh_token,
    get_user_sessions,
    is_account_locked,
    parse_device,
    record_failed_login,
    replace_user_session,
    rotate_session_refresh_token,
    stage_delete_other_sessions,
    validate_browser_origin,
    verify_password,
)
from app.database import get_db
from app.domains.auth import service as auth_service
from app.models.user import User
from app.schemas.auth import (
    AuthSessionResponse,
    BaseModel,
    LoginClientKind,
    LoginLogResponse,
    LogoutRequest,
    MessageResponse,
    PasswordChange,
    ProfileUpdate,
    RefreshTokenRequest,
    TokenLoginRequest,
    UserRegister,
    UserResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["auth"])


async def _user_response(user: User, db: AsyncSession) -> UserResponse:
    permissions = await get_role_permissions(db, user.role)
    return UserResponse(
        id=user.id,
        username=user.username,
        email=user.email,
        role=user.role,
        permissions=permissions,
        is_active=user.is_active,
        created_at=user.created_at,
    )


def _session_id_from_access_token(token: str | None) -> int | None:
    if not token:
        return None

    payload = decode_access_token_strict(token)
    if payload is None:
        return None
    try:
        return int(payload["sid"])
    except (KeyError, TypeError, ValueError):
        return None


def _bearer_session_id(request: Request) -> int | None:
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None
    return _session_id_from_access_token(auth_header[7:])


def _authenticated_session_id(request: Request) -> int | None:
    bearer_sid = _bearer_session_id(request)
    if bearer_sid is not None:
        return bearer_sid
    return _session_id_from_access_token(
        request.cookies.get(settings.auth_access_cookie_name)
    )


def _cleared_auth_error_response(detail: str) -> JSONResponse:
    response = JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"detail": detail},
    )
    clear_auth_cookies(response)
    return response


# ── Cookie helpers (see app.core.auth_cookies for implementation) ──────────


# ── Register ──────────────────────────────────────────────────────────────────


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED, tags=["auth"])
async def register(user_data: UserRegister, db: AsyncSession = Depends(get_db)):
    """Register a new user.

    Creates a new user account with username, email, and password.

    Args:
        user_data: User registration data (username, email, password)

    Returns:
        UserResponse: Created user information

    Raises:
        HTTPException 400: Username or email already exists
        HTTPException 422: Validation error (password too short, invalid email)
    """
    try:
        new_user = await auth_service.register_user(
            db,
            user_data=user_data,
            password_hash=get_password_hash(user_data.password),
        )
    except auth_service.UsernameConflictError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户名已注册",
        ) from None
    except auth_service.EmailConflictError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="邮箱已注册",
        ) from None

    await log_audit(
        db=db,
        action="user.register",
        actor_user_id=new_user.id,
        target_type="user",
        target_id=new_user.id,
        details={"username": new_user.username, "email": new_user.email},
        commit=True,
    )

    logger.info(f"User registered: {user_data.username}")
    return new_user


# ── Login ─────────────────────────────────────────────────────────────────────


@router.post("/login", response_model=AuthSessionResponse, tags=["auth"])
async def login(
    login_data: TokenLoginRequest,
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    """Login and return a token-first session.

    Web clients receive the access token in the response and an HttpOnly
    refresh cookie. Native clients receive both tokens in the response body.

    Raises:
        HTTPException 401: Invalid username or password
        HTTPException 429: Account locked (5 failed attempts, 15 min lockout)
    """
    user = await auth_service.get_user_for_login(db, username=login_data.username)

    if user is None:
        await record_failed_login(login_data.username)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误",
        )

    # Check if account is locked
    is_locked, minutes_remaining = await is_account_locked(login_data.username)
    if is_locked:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"登录尝试次数过多，请 {minutes_remaining} 分钟后再试",
        )

    # Reject soft-deleted users before password check to avoid info leak
    if user.deleted_at is not None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户已被禁用",
        )

    if not verify_password(login_data.password, user.hashed_password):
        await record_failed_login(login_data.username)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误",
        )

    # Clear failed login attempts
    await clear_login_attempts(login_data.username)

    # ── Create refresh-token-based session ────────────────────────────────
    refresh_token = create_refresh_token()
    device = parse_device(request.headers.get("user-agent", ""))
    ip_address = request.client.host if request.client else ""

    session = await replace_user_session(
        user_id=user.id,
        refresh_token=refresh_token,
        device=device,
        ip_address=ip_address,
        db=db,
    )
    # Flush to get session.id from the DB sequence
    await db.flush()

    # ── Create access and CSRF tokens ─────────────────────────────────────
    access_token = create_access_token_sid(
        user_id=user.id,
        username=user.username,
        session_id=session.id,
    )
    if login_data.client_kind == LoginClientKind.web:
        set_web_refresh_cookie(
            response,
            refresh_token,
            max_age=refresh_cookie_max_age(
                getattr(session, "refresh_expires_at", None),
                getattr(session, "last_active_at", None),
            ),
        )

    # ── Login log ─────────────────────────────────────────────────────────
    await auth_service.add_login_log(
        db,
        user_id=user.id,
        ip_address=ip_address,
        user_agent=request.headers.get("user-agent", ""),
    )

    # ── Audit & commit ────────────────────────────────────────────────────
    await log_audit_from_request(
        request,
        db,
        action="auth.login",
        actor_user_id=user.id,
        target_type="user",
        target_id=user.id,
        details={"username": user.username, "ip_address": ip_address},
        commit=True,
    )

    logger.info(f"User logged in: {user.username}")

    return AuthSessionResponse(
        access_token=access_token,
        refresh_token=(
            refresh_token
            if login_data.client_kind == LoginClientKind.native
            else None
        ),
        expires_in=get_access_token_expires_in_seconds(),
        user=await _user_response(user, db),
    )


# ── Refresh ───────────────────────────────────────────────────────────────────


@router.post("/refresh", response_model=AuthSessionResponse, tags=["auth"])
async def refresh(
    request: Request,
    response: Response,
    refresh_data: RefreshTokenRequest | None = Body(default=None),
    db: AsyncSession = Depends(get_db),
):
    """Refresh auth tokens using a native body token or Web cookie.

    Validates the refresh token, rotates it (token rotation), and sets
    fresh cookies on the response.

    Returns:
        UserResponse: Current user profile with permissions
    """
    body_refresh_token = refresh_data.refresh_token if refresh_data else None
    cookie_refresh_token = request.cookies.get(settings.auth_refresh_cookie_name)
    refresh_token = body_refresh_token or cookie_refresh_token
    if not refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="未提供刷新令牌",
        )

    uses_cookie = body_refresh_token is None
    if uses_cookie:
        validate_browser_origin(request)

    session = await get_session_by_refresh_token(refresh_token, db)
    if session is None:
        if uses_cookie:
            return _cleared_auth_error_response("刷新令牌无效或已过期")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="刷新令牌无效或已过期",
        )

    # Fetch user (must exist and not be soft-deleted)
    result = await db.execute(
        select(User).where(
            User.id == session.user_id,
            User.deleted_at.is_(None),
        )
    )
    user = result.scalar_one_or_none()
    if user is None:
        if uses_cookie:
            return _cleared_auth_error_response("用户不存在或已被删除")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户不存在或已被删除",
        )

    # Rotate refresh token (old one is invalidated)
    new_refresh_token = create_refresh_token()
    await rotate_session_refresh_token(session, new_refresh_token, db)

    # Create fresh access and CSRF tokens
    access_token = create_access_token_sid(
        user_id=user.id,
        username=user.username,
        session_id=session.id,
    )
    if uses_cookie:
        set_web_refresh_cookie(
            response,
            new_refresh_token,
            max_age=refresh_cookie_max_age(
                getattr(session, "refresh_expires_at", None),
                getattr(session, "last_active_at", None),
            ),
        )

    await db.commit()

    logger.info(f"Tokens refreshed for user: {user.username}")
    return AuthSessionResponse(
        access_token=access_token,
        refresh_token=None if uses_cookie else new_refresh_token,
        expires_in=get_access_token_expires_in_seconds(),
        user=await _user_response(user, db),
    )


# ── Logout ────────────────────────────────────────────────────────────────────


@router.post("/logout", response_model=MessageResponse, tags=["auth"])
async def logout(
    request: Request,
    response: Response,
    logout_data: LogoutRequest | None = Body(default=None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    _=Depends(csrf_protect),
):
    """Logout current user.

    Deletes the current session and clears all auth cookies.

    Returns:
        MessageResponse: Logout success message
    """
    bearer_sid = _bearer_session_id(request)
    try:
        if bearer_sid is not None:
            session = await get_session_by_id(
                bearer_sid,
                current_user.id,
                db,
            )
        else:
            body_refresh_token = logout_data.refresh_token if logout_data else None
            cookie_refresh_token = request.cookies.get(
                settings.auth_refresh_cookie_name
            )
            refresh_token = body_refresh_token or cookie_refresh_token
            if cookie_refresh_token and not body_refresh_token:
                validate_browser_origin(request)
            session = (
                await get_session_by_refresh_token(refresh_token, db)
                if refresh_token
                else None
            )
        if session and session.user_id == current_user.id:
            await db.delete(session)
            await db.commit()
    except HTTPException:
        raise
    except Exception:
        logger.exception("Failed to delete session on logout")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="登出失败，请稍后重试",
        ) from None

    clear_auth_cookies(response)

    await log_audit_from_request(
        request,
        db,
        action="auth.logout",
        actor_user_id=current_user.id,
        target_type="user",
        target_id=current_user.id,
        details={"username": current_user.username},
        commit=True,
    )
    logger.info(f"User logged out: {current_user.username}")
    return MessageResponse(message="登出成功")


# ── Get / Update current user ─────────────────────────────────────────────────


@router.get("/me", response_model=UserResponse, tags=["auth"])
async def get_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current user information.

    Returns the authenticated user's profile information.

    Returns:
        UserResponse: Current user profile with permissions
    """
    permissions = await get_role_permissions(db, current_user.role)
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "role": current_user.role,
        "permissions": permissions,
        "is_active": current_user.is_active,
        "created_at": current_user.created_at,
    }


@router.patch("/me", response_model=UserResponse, tags=["auth"])
async def update_me(
    update_data: ProfileUpdate,
    response: Response,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    _=Depends(csrf_protect),
):
    """Update current user's profile (username, email).

    Args:
        update_data: Profile update data (username, email)
        current_user: Authenticated user (from cookie)
        db: Database session

    Returns:
        UserResponse: Updated user profile

    Raises:
        HTTPException 400: Username or email already exists
    """
    try:
        current_user = await auth_service.update_profile(
            db, user=current_user, update_data=update_data
        )
    except auth_service.UsernameConflictError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户名已存在",
        ) from None
    except auth_service.EmailConflictError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="邮箱已存在",
        ) from None
    except IntegrityError as e:
        await db.rollback()
        logger.error(f"IntegrityError in update_me: {e}")
        error_msg = str(e.orig).lower()
        if "username" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="用户名已存在",
            )
        elif "email" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="邮箱已存在",
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="数据冲突，请检查用户名或邮箱是否已被使用",
        )

    logger.info(f"Profile updated for user: {current_user.username}")
    permissions = await get_role_permissions(db, current_user.role)
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "role": current_user.role,
        "permissions": permissions,
        "is_active": current_user.is_active,
        "created_at": current_user.created_at,
    }


@router.post("/me/password", response_model=AuthSessionResponse, tags=["auth"])
async def change_password(
    request: Request,
    response: Response,
    password_data: PasswordChange,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    _=Depends(csrf_protect),
):
    """Change current user's password.

    Validates current session before mutation, then invalidates other sessions
    in the same transaction as the password update. Rotates the current session's
    refresh token and sets fresh cookies.

    Args:
        password_data: Password change data (old_password, new_password)
        current_user: Authenticated user (from cookie)
        db: Database session

    Returns:
        MessageResponse: Success message

    Raises:
        HTTPException 400: Old password is incorrect
        HTTPException 401: Current session is invalid/missing
    """
    # Verify old password
    if not verify_password(password_data.old_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="原密码错误",
        )

    # Resolve current session from refresh token cookie
    body_refresh_token = password_data.refresh_token
    cookie_refresh_token = request.cookies.get(settings.auth_refresh_cookie_name)
    refresh_token = body_refresh_token or cookie_refresh_token
    if not refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：当前会话不存在或已失效",
        )
    if cookie_refresh_token and not body_refresh_token:
        validate_browser_origin(request)

    session = await get_session_by_refresh_token(refresh_token, db)
    authenticated_sid = _authenticated_session_id(request)
    if (
        session is None
        or session.user_id != current_user.id
        or (
            authenticated_sid is not None
            and session.id != authenticated_sid
        )
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：当前会话不存在或已失效",
        )

    # Update password
    current_user.hashed_password = get_password_hash(password_data.new_password)

    # Stage deletion of all other sessions (same transaction)
    await stage_delete_other_sessions(session.id, current_user.id, db)

    # Rotate current session's refresh token
    new_refresh_token = create_refresh_token()
    await rotate_session_refresh_token(session, new_refresh_token, db)

    # Create fresh access token
    access_token = create_access_token_sid(
        user_id=current_user.id,
        username=current_user.username,
        session_id=session.id,
    )

    # Commit password change and session cleanup together
    await db.commit()

    uses_cookie = body_refresh_token is None
    if uses_cookie:
        set_web_refresh_cookie(
            response,
            new_refresh_token,
            max_age=refresh_cookie_max_age(
                getattr(session, "refresh_expires_at", None),
                getattr(session, "last_active_at", None),
            ),
        )

    logger.info(f"Password changed for user: {current_user.username}")

    # Best-effort audit after business commit
    await log_audit_from_request(
        request,
        db,
        action="user.password_change",
        actor_user_id=current_user.id,
        target_type="user",
        target_id=current_user.id,
        details={"username": current_user.username},
        commit=True,
    )

    return AuthSessionResponse(
        access_token=access_token,
        refresh_token=None if uses_cookie else new_refresh_token,
        expires_in=get_access_token_expires_in_seconds(),
        user=await _user_response(current_user, db),
    )


# ── Session management ────────────────────────────────────────────────────────


class SessionResponse(BaseModel):
    id: int
    device: str | None
    ip_address: str | None
    last_active_at: datetime
    created_at: datetime
    model_config = {"from_attributes": True}


@router.get("/sessions", response_model=list[SessionResponse])
async def list_my_sessions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all active sessions for current user."""
    sessions = await get_user_sessions(current_user.id, db)
    return sessions


@router.delete("/sessions/{session_id}", response_model=MessageResponse)
async def delete_a_session(
    session_id: int,
    request: Request,
    response: Response,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    _=Depends(csrf_protect),
):
    """Delete a specific session (logout from a device).

    If the deleted session is the current one, auth cookies are cleared.
    """
    # Determine if deleting the current session (to clear cookies)
    current_session_id = None
    refresh_token = request.cookies.get(settings.auth_refresh_cookie_name)
    if refresh_token:
        current_session = await get_session_by_refresh_token(refresh_token, db)
        if current_session:
            current_session_id = current_session.id

    deleted = await delete_session(session_id, current_user.id, db)
    if not deleted:
        raise HTTPException(status_code=404, detail="会话不存在")

    if current_session_id == session_id:
        clear_auth_cookies(response)

    return MessageResponse(message="已登出该设备")


@router.delete("/sessions", response_model=MessageResponse)
async def delete_other_sessions_endpoint(
    current_user: User = Depends(get_current_user),
    session_id: int = Body(...),
    db: AsyncSession = Depends(get_db),
    _=Depends(csrf_protect),
):
    """Logout from all other devices."""
    count = await delete_other_sessions(session_id, current_user.id, db)
    return MessageResponse(message=f"已登出 {count} 个其他设备")


# ── Login history ─────────────────────────────────────────────────────────────


@router.get("/me/login-history", response_model=list[LoginLogResponse])
async def get_my_login_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get login history for current user.

    Returns list of recent login records.
    """
    return await auth_service.list_login_history(db, user_id=current_user.id)
