"""WeChat OAuth login API routes.

Provides WeChat QR code login, callback handling, and account binding.
Feature-flagged: returns 503 when WeChat login is not configured.
"""
import logging
import secrets
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from urllib.parse import urlencode, urlsplit, urlunsplit

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.audit import log_audit_from_request
from app.core.auth_cookies import set_auth_cookies
from app.core.permissions import get_role_permissions
from app.core.security import (
    create_access_token,
    create_access_token_sid,
    create_csrf_token,
    create_refresh_token,
    create_session,
    get_password_hash,
    parse_device,
)
from app.database import get_db
from app.domains.auth import service as auth_service
from app.models.user import User
from app.schemas.auth import (
    UserResponse,
    WeChatBindRequest,
    WeChatQrResponse,
    WeChatRegisterRequest,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth/wechat", tags=["wechat"])

# In-memory state cache (short-lived, expires in 10 minutes)


@dataclass(slots=True)
class WeChatStateEntry:
    issued_at: datetime
    next_path: str


_state_cache: dict[str, WeChatStateEntry] = {}

WECHAT_QR_CONNECT_URL = "https://open.weixin.qq.com/connect/qrconnect"
WECHAT_TOKEN_URL = "https://api.weixin.qq.com/sns/oauth2/access_token"
WECHAT_USERINFO_URL = "https://api.weixin.qq.com/sns/userinfo"


# ── Cookie helpers (see app.core.auth_cookies) ─────────────────────────────


async def _create_wechat_auth_session(
    user: User,
    request: Request,
    response: Response,
    db: AsyncSession,
) -> UserResponse:
    """Create refresh-token session, set auth cookies, and return user info."""
    refresh_token = create_refresh_token()
    device = parse_device(request.headers.get("user-agent", ""))
    ip_address = request.client.host if request.client else ""

    session = await create_session(
        user_id=user.id,
        refresh_token=refresh_token,
        device=device,
        ip_address=ip_address,
        db=db,
    )
    await db.flush()

    access_token = create_access_token_sid(
        user_id=user.id,
        username=user.username,
        session_id=session.id,
    )
    csrf_token = create_csrf_token()

    set_auth_cookies(response, access_token, refresh_token, csrf_token)

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


def _cleanup_expired_states() -> None:
    """Remove expired states from cache."""
    now = datetime.now(UTC)
    expired = [
        key
        for key, entry in _state_cache.items()
        if now - entry.issued_at > timedelta(minutes=10)
    ]
    for k in expired:
        del _state_cache[k]


def _normalize_next_path(raw_next: str | None) -> str:
    """Allow only in-app relative paths for post-login redirects."""
    if not raw_next:
        return "/today"
    if not raw_next.startswith("/") or raw_next.startswith("//"):
        return "/today"

    split = urlsplit(raw_next)
    if split.scheme or split.netloc:
        return "/today"

    path = split.path or "/today"
    return urlunsplit(("", "", path, split.query, ""))


def _get_frontend_callback_url() -> str:
    """Return the frontend callback landing URL for browser flows."""
    return settings.wechat_frontend_callback_url or "http://localhost:3000/auth/wechat/callback"


def _build_frontend_callback_redirect(
    *,
    status_value: str,
    next_path: str | None = None,
    reason: str | None = None,
    temp_token: str | None = None,
) -> str:
    """Build the frontend callback URL with status query and optional fragment token."""
    base = urlsplit(_get_frontend_callback_url())
    query_items = [("status", status_value)]
    if next_path:
        query_items.append(("next", next_path))
    if reason:
        query_items.append(("reason", reason))
    fragment = urlencode({"temp_token": temp_token}) if temp_token else ""
    return urlunsplit(
        (base.scheme, base.netloc, base.path, urlencode(query_items), fragment)
    )


def _redirect_to_frontend_error(reason: str) -> RedirectResponse:
    """Redirect callback failures to the frontend error state."""
    return RedirectResponse(
        url=_build_frontend_callback_redirect(
            status_value="error",
            reason=reason,
        ),
        status_code=status.HTTP_302_FOUND,
    )


def _check_wechat_enabled() -> None:
    """Raise 503 if WeChat login is not configured."""
    if not settings.wechat_login_enabled:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="微信登录未启用",
        )
    if not settings.wechat_app_id or not settings.wechat_app_secret:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="微信登录配置不完整",
        )


@router.get("/qr", response_model=WeChatQrResponse)
async def get_wechat_qr_url(next: str | None = None):
    """Generate WeChat QR code authorization URL.

    Returns a URL for the user to scan with WeChat.
    The state parameter is randomly generated and cached for 10 minutes.
    """
    _check_wechat_enabled()

    _cleanup_expired_states()
    state = secrets.token_urlsafe(32)
    _state_cache[state] = WeChatStateEntry(
        issued_at=datetime.now(UTC),
        next_path=_normalize_next_path(next),
    )

    redirect_uri = (
        settings.wechat_redirect_uri
        or "http://localhost:8000/api/v1/auth/wechat/callback"
    )
    qr_url = (
        f"{WECHAT_QR_CONNECT_URL}"
        f"?appid={settings.wechat_app_id}"
        f"&redirect_uri={redirect_uri}"
        f"&response_type=code"
        f"&scope=snsapi_login"
        f"&state={state}"
    )

    return WeChatQrResponse(qr_url=qr_url, state=state)


@router.get(
    "/callback",
    response_class=RedirectResponse,
    responses={
        302: {
            "description": "Redirects to frontend WeChat callback page with tokens",
        }
    },
)
async def wechat_callback(
    code: str,
    state: str,
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    """Handle WeChat OAuth callback.

    Exchanges code for access_token and openid.
    If the openid is already bound to a user, logs them in (sets auth cookies).
    Otherwise, returns a temporary token for binding/registration.
    """
    _check_wechat_enabled()

    # Validate state
    _cleanup_expired_states()
    state_entry = _state_cache.pop(state, None)
    if state_entry is None:
        return _redirect_to_frontend_error("state_expired")

    # Exchange code for token
    async with httpx.AsyncClient() as client:
        token_resp = await client.get(
            WECHAT_TOKEN_URL,
            params={
                "appid": settings.wechat_app_id,
                "secret": settings.wechat_app_secret,
                "code": code,
                "grant_type": "authorization_code",
            },
        )

    token_data = token_resp.json()
    if "errcode" in token_data:
        logger.error("WeChat token exchange failed: %s", token_data)
        return _redirect_to_frontend_error("oauth_failed")

    openid = token_data.get("openid")
    if not openid:
        return _redirect_to_frontend_error("wechat_identity_missing")

    user = await auth_service.get_user_for_wechat_login(db, openid=openid)

    if user:
        # Already bound - login (set auth cookies)
        if not user.is_active:
            return _redirect_to_frontend_error("user_disabled")

        redirect_response = RedirectResponse(
            url=_build_frontend_callback_redirect(
                status_value="success",
                next_path=state_entry.next_path,
            ),
            status_code=status.HTTP_302_FOUND,
        )

        await _create_wechat_auth_session(user, request, redirect_response, db)

        await log_audit_from_request(
            request,
            db,
            action="auth.login",
            actor_user_id=user.id,
            target_type="user",
            target_id=user.id,
            details={"username": user.username, "method": "wechat"},
            commit=True,
        )

        return redirect_response

    # Not bound - return temporary token for binding
    temp_token = create_access_token(
        data={"wechat_openid": openid, "temp": True},
        expires_delta=timedelta(minutes=10),
    )

    return RedirectResponse(
        url=_build_frontend_callback_redirect(
            status_value="unbound",
            next_path=state_entry.next_path,
            temp_token=temp_token,
        ),
        status_code=status.HTTP_302_FOUND,
    )


@router.post("/bind", response_model=UserResponse)
async def bind_wechat_account(
    payload: WeChatBindRequest,
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    """Bind WeChat account to an existing user.

    Args:
        temp_token: Temporary token from callback
        username: Existing username
        password: Existing password
    """
    _check_wechat_enabled()

    from app.core.security import decode_access_token, verify_password

    temp_token = payload.temp_token
    username = payload.username
    password = payload.password

    payload = decode_access_token(temp_token)
    if not payload or not payload.get("temp") or not payload.get("wechat_openid"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="无效的临时令牌",
        )

    openid = payload["wechat_openid"]

    if await auth_service.get_user_for_wechat_login(db, openid=openid):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="该微信账号已绑定其他用户",
        )

    user = await auth_service.get_user_for_wechat_bind(db, username=username)

    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户已被禁用",
        )

    try:
        user = await auth_service.bind_wechat_openid(db, user=user, openid=openid)
    except auth_service.WeChatOpenidConflictError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="该微信 openid 已绑定其他用户",
        ) from None

    # Create cookie-based auth session
    user_resp = await _create_wechat_auth_session(user, request, response, db)

    await log_audit_from_request(
        request,
        db,
        action="user.wechat_bind",
        actor_user_id=user.id,
        target_type="user",
        target_id=user.id,
        details={"username": user.username, "method": "bind_existing"},
        commit=True,
    )

    return user_resp


@router.post("/register", response_model=UserResponse)
async def register_with_wechat(
    payload: WeChatRegisterRequest,
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    """Register a new user and bind WeChat account.

    Args:
        temp_token: Temporary token from callback
        username: New username
        email: New email
        password: New password
    """
    _check_wechat_enabled()

    from app.core.security import decode_access_token

    temp_token = payload.temp_token
    username = payload.username
    email = payload.email
    password = payload.password

    payload = decode_access_token(temp_token)
    if not payload or not payload.get("temp") or not payload.get("wechat_openid"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="无效的临时令牌",
        )

    openid = payload["wechat_openid"]

    if await auth_service.get_user_for_wechat_login(db, openid=openid):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="该微信账号已绑定其他用户",
        )

    try:
        new_user = await auth_service.register_wechat_user(
            db,
            username=username,
            email=email,
            password_hash=get_password_hash(password),
            openid=openid,
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
    except auth_service.WeChatOpenidConflictError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="该微信账号已绑定其他用户",
        ) from None

    # Create cookie-based auth session
    user_resp = await _create_wechat_auth_session(new_user, request, response, db)

    await log_audit_from_request(
        request,
        db,
        action="user.register",
        actor_user_id=new_user.id,
        target_type="user",
        target_id=new_user.id,
        details={"username": new_user.username, "email": new_user.email, "method": "wechat"},
        commit=True,
    )

    return user_resp
