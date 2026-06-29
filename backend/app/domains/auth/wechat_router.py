"""WeChat OAuth login API routes.

Provides WeChat QR code login, callback handling, and account binding.
Feature-flagged: returns 503 when WeChat login is not configured.
"""
import json
import logging
import secrets
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from urllib.parse import urlencode, urlsplit, urlunsplit

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from fastapi.responses import RedirectResponse
from redis.exceptions import RedisError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.audit import log_audit_from_request
from app.core.auth_cookies import (
    refresh_cookie_max_age,
    set_auth_cookies,
    set_web_refresh_cookie,
)
from app.core.permissions import get_role_permissions
from app.core.redis_client import get_redis
from app.core.security import (
    create_access_token,
    create_access_token_sid,
    create_csrf_token,
    create_refresh_token,
    get_access_token_expires_in_seconds,
    get_password_hash,
    parse_device,
    replace_user_session,
)
from app.database import get_db
from app.domains.auth import service as auth_service
from app.models.user import User
from app.schemas.auth import (
    AuthSessionResponse,
    LoginClientKind,
    UserResponse,
    WeChatBindRequest,
    WeChatExchangeRequest,
    WeChatExchangeResponse,
    WeChatQrResponse,
    WeChatRegisterRequest,
    WeChatUnboundResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth/wechat", tags=["wechat"])

# In-memory state cache (short-lived, expires in 10 minutes)


@dataclass(slots=True)
class WeChatStateEntry:
    issued_at: datetime
    next_path: str
    callback_url: str = ""


_state_cache: dict[str, WeChatStateEntry] = {}
EXCHANGE_CODE_TTL_SECONDS = 600


@dataclass(slots=True)
class WeChatExchangeEntry:
    issued_at: datetime
    status: str
    openid: str
    next_path: str


class InMemoryWeChatExchangeCodeStore:
    """Process-local fallback used when Redis is unavailable."""

    def __init__(self) -> None:
        self._entries: dict[str, WeChatExchangeEntry] = {}

    def _cleanup_expired(self) -> None:
        now = datetime.now(UTC)
        expired = [
            code
            for code, entry in self._entries.items()
            if now - entry.issued_at > timedelta(seconds=EXCHANGE_CODE_TTL_SECONDS)
        ]
        for code in expired:
            del self._entries[code]

    async def save(self, code: str, entry: WeChatExchangeEntry) -> None:
        self._cleanup_expired()
        self._entries[code] = entry

    async def consume(self, code: str) -> WeChatExchangeEntry | None:
        self._cleanup_expired()
        return self._entries.pop(code, None)


class RedisWeChatExchangeCodeStore:
    """Redis-backed one-time exchange-code store with local fallback."""

    def __init__(self) -> None:
        self._fallback = InMemoryWeChatExchangeCodeStore()

    @staticmethod
    def _key(code: str) -> str:
        return f"wechat_exchange:{code}"

    @staticmethod
    def _serialize(entry: WeChatExchangeEntry) -> str:
        return json.dumps(
            {
                "issued_at": entry.issued_at.isoformat(),
                "status": entry.status,
                "openid": entry.openid,
                "next_path": entry.next_path,
            }
        )

    @staticmethod
    def _deserialize(raw_value: bytes | str) -> WeChatExchangeEntry | None:
        if isinstance(raw_value, bytes):
            raw_value = raw_value.decode("utf-8")
        try:
            data = json.loads(raw_value)
            return WeChatExchangeEntry(
                issued_at=datetime.fromisoformat(data["issued_at"]),
                status=data["status"],
                openid=data["openid"],
                next_path=_normalize_next_path(data.get("next_path")),
            )
        except (KeyError, TypeError, ValueError, json.JSONDecodeError):
            return None

    async def save(self, code: str, entry: WeChatExchangeEntry) -> None:
        try:
            redis_client = await get_redis()
            await redis_client.set(
                self._key(code),
                self._serialize(entry),
                ex=EXCHANGE_CODE_TTL_SECONDS,
            )
        except RedisError:
            logger.exception("Redis unavailable for WeChat exchange-code save")
            await self._fallback.save(code, entry)

    async def consume(self, code: str) -> WeChatExchangeEntry | None:
        try:
            redis_client = await get_redis()
            raw_value = await redis_client.execute_command("GETDEL", self._key(code))
        except RedisError:
            logger.exception("Redis unavailable for WeChat exchange-code consume")
            return await self._fallback.consume(code)
        if not raw_value:
            return await self._fallback.consume(code)
        return self._deserialize(raw_value)


_exchange_code_store = RedisWeChatExchangeCodeStore()

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

    session = await replace_user_session(
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

    set_auth_cookies(
        response,
        access_token,
        refresh_token,
        csrf_token,
        refresh_max_age=refresh_cookie_max_age(
            getattr(session, "refresh_expires_at", None),
            getattr(session, "last_active_at", None),
        ),
    )

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


async def _create_wechat_token_session(
    user: User,
    request: Request,
    response: Response,
    db: AsyncSession,
    client_kind: LoginClientKind,
) -> AuthSessionResponse:
    """Create a token-first WeChat session for exchange-code consumers."""
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
    await db.flush()

    access_token = create_access_token_sid(
        user_id=user.id,
        username=user.username,
        session_id=session.id,
    )
    if client_kind == LoginClientKind.web:
        set_web_refresh_cookie(
            response,
            refresh_token,
            max_age=refresh_cookie_max_age(
                getattr(session, "refresh_expires_at", None),
                getattr(session, "last_active_at", None),
            ),
        )

    permissions = await get_role_permissions(db, user.role)
    return AuthSessionResponse(
        access_token=access_token,
        refresh_token=(
            refresh_token
            if client_kind == LoginClientKind.native
            else None
        ),
        expires_in=get_access_token_expires_in_seconds(),
        user=UserResponse(
            id=user.id,
            username=user.username,
            email=user.email,
            role=user.role,
            permissions=permissions,
            is_active=user.is_active,
            created_at=user.created_at,
        ),
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


def _get_frontend_callback_url(platform: str | None = None) -> str:
    """Return the platform callback landing URL."""
    normalized_platform = (platform or "web").lower()
    if normalized_platform == "android":
        return settings.wechat_android_callback_url
    if normalized_platform == "ios":
        return settings.wechat_ios_callback_url
    if normalized_platform == "windows":
        return settings.wechat_windows_callback_url
    return (
        settings.wechat_flutter_web_callback_url
        or settings.wechat_frontend_callback_url
        or "http://localhost:3000/auth/wechat/callback"
    )


def _build_frontend_callback_redirect(
    *,
    status_value: str,
    callback_url: str | None = None,
    next_path: str | None = None,
    reason: str | None = None,
    exchange_code: str | None = None,
) -> str:
    """Build the platform callback URL with status query and exchange code."""
    base = urlsplit(callback_url or _get_frontend_callback_url())
    query_items = [("status", status_value)]
    if next_path:
        query_items.append(("next", next_path))
    if exchange_code:
        query_items.append(("exchange_code", exchange_code))
    if reason:
        query_items.append(("reason", reason))
    return urlunsplit((base.scheme, base.netloc, base.path, urlencode(query_items), ""))


def _redirect_to_frontend_error(
    reason: str,
    callback_url: str | None = None,
) -> RedirectResponse:
    """Redirect callback failures to the frontend error state."""
    return RedirectResponse(
        url=_build_frontend_callback_redirect(
            status_value="error",
            callback_url=callback_url,
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
async def get_wechat_qr_url(
    next: str | None = None,
    platform: str | None = None,
):
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
        callback_url=_get_frontend_callback_url(platform),
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
        302: {"description": "Redirects with a one-time exchange code"}
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
    If the openid is already bound to a user, stores a short-lived code for
    token-first exchange. Otherwise, stores a code for temp-token exchange.
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
        return _redirect_to_frontend_error("oauth_failed", state_entry.callback_url)

    openid = token_data.get("openid")
    if not openid:
        return _redirect_to_frontend_error(
            "wechat_identity_missing",
            state_entry.callback_url,
        )

    user = await auth_service.get_user_for_wechat_login(db, openid=openid)

    if user:
        if not user.is_active:
            return _redirect_to_frontend_error(
                "user_disabled",
                state_entry.callback_url,
            )

        exchange_code = secrets.token_urlsafe(32)
        await _exchange_code_store.save(
            exchange_code,
            WeChatExchangeEntry(
                issued_at=datetime.now(UTC),
                status="success",
                openid=openid,
                next_path=state_entry.next_path,
            ),
        )
        return RedirectResponse(
            url=_build_frontend_callback_redirect(
                status_value="success",
                callback_url=state_entry.callback_url,
                next_path=state_entry.next_path,
                exchange_code=exchange_code,
            ),
            status_code=status.HTTP_302_FOUND,
        )

    exchange_code = secrets.token_urlsafe(32)
    await _exchange_code_store.save(
        exchange_code,
        WeChatExchangeEntry(
            issued_at=datetime.now(UTC),
            status="unbound",
            openid=openid,
            next_path=state_entry.next_path,
        ),
    )
    return RedirectResponse(
        url=_build_frontend_callback_redirect(
            status_value="unbound",
            callback_url=state_entry.callback_url,
            next_path=state_entry.next_path,
            exchange_code=exchange_code,
        ),
        status_code=status.HTTP_302_FOUND,
    )


@router.post("/exchange", response_model=WeChatExchangeResponse)
async def exchange_wechat_code(
    payload: WeChatExchangeRequest,
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    """Consume a one-time WeChat callback code and return a token-first result."""
    _check_wechat_enabled()

    entry = await _exchange_code_store.consume(payload.exchange_code)
    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="微信交换码无效或已过期",
        )

    if entry.status == "unbound":
        temp_token = create_access_token(
            data={"wechat_openid": entry.openid, "temp": True},
            expires_delta=timedelta(minutes=10),
        )
        return WeChatExchangeResponse(
            status="unbound",
            unbound=WeChatUnboundResponse(
                temp_token=temp_token,
                next_path=entry.next_path,
            ),
        )

    if entry.status != "success":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="微信交换码状态无效",
        )

    user = await auth_service.get_user_for_wechat_login(db, openid=entry.openid)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="微信账号尚未绑定",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户已被禁用",
        )

    session_response = await _create_wechat_token_session(
        user,
        request,
        response,
        db,
        payload.client_kind,
    )

    await log_audit_from_request(
        request,
        db,
        action="auth.login",
        actor_user_id=user.id,
        target_type="user",
        target_id=user.id,
        details={"username": user.username, "method": "wechat_exchange"},
        commit=True,
    )

    return WeChatExchangeResponse(status="success", session=session_response)


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
