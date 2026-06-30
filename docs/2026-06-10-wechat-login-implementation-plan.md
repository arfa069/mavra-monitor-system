# WeChat Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a complete browser WeChat login flow that starts inside `/login`, returns to a frontend callback route, restores cookie-first auth for already-bound users, and lets unbound users either bind an existing account or register a new one in the same flow.

**Architecture:** Keep the backend as the authentication source of truth and make the frontend responsible for orchestration and presentation. The backend owns QR URL generation, state validation, OAuth code exchange, cookie creation, and callback redirection; the frontend owns the login-page QR panel, callback-route status machine, unbound bind/register UI, and post-login navigation.

**Tech Stack:** FastAPI, Pydantic, SQLAlchemy async, httpx, React 18, React Router, Ant Design, Axios, Vitest, MSW, Playwright.

---

## Non-Negotiable Safety Boundary

No step in this plan may perform a real WeChat login during automated verification.

- Backend tests must mock outbound requests to `api.weixin.qq.com`.
- Frontend unit tests must use MSW; no request may leave the test process.
- Frontend E2E must mock `/api/v1/auth/wechat/**`; do not depend on a live backend callback, a real app id, or real credentials.
- Do not add `.env` secrets, real WeChat IDs, or temporary manual QA credentials to the repository.
- Do not store `temp_token` in `localStorage` or `sessionStorage`.

## File Structure

### Backend contract and redirect flow

- Modify: `backend/app/config.py`
- Modify: `backend/app/schemas/auth.py`
- Modify: `backend/app/domains/auth/wechat_router.py`
- Create: `backend/tests/test_wechat_auth_flow.py`
- Modify: `backend/tests/test_permissions_and_audit.py`

### Frontend auth flow

- Modify: `frontend/package.json`
- Modify: `frontend/package-lock.json`
- Modify: `frontend/src/App.tsx`
- Modify: `frontend/src/features/auth/api/auth.ts`
- Modify: `frontend/src/features/auth/index.ts`
- Modify: `frontend/src/features/auth/LoginPage.tsx`
- Create: `frontend/src/features/auth/WeChatAuthCallbackPage.tsx`
- Create: `frontend/src/features/auth/components/WeChatLoginPanel.tsx`
- Create: `frontend/src/features/auth/components/WeChatAccountLinkPanel.tsx`
- Create: `frontend/src/features/auth/wechatCallback.ts`

### Frontend tests

- Modify: `frontend/tests/unit/auth/login-page.test.tsx`
- Create: `frontend/tests/unit/auth/wechat-auth-callback-page.test.tsx`
- Modify: `frontend/tests/e2e/fixtures/app-test.ts`
- Modify: `frontend/tests/e2e/auth.spec.ts`

### Documentation

- Modify: `doc/reference-config.md`
- Modify: `doc/reference-api-auth.md`

---

### Task 1: Normalize the Backend WeChat Request Contract

**Files:**

- Modify: `backend/app/config.py`
- Modify: `backend/app/schemas/auth.py`
- Modify: `backend/app/domains/auth/wechat_router.py`
- Create: `backend/tests/test_wechat_auth_flow.py`

- [ ] **Step 1: Write failing backend tests for QR `next` handling and JSON bind/register bodies**

Create `backend/tests/test_wechat_auth_flow.py` with:

```python
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.database import get_db
from app.domains.auth import wechat_router
from app.main import app


@pytest.fixture
def mock_db():
    session = AsyncMock()
    session.execute = AsyncMock()
    session.commit = AsyncMock()
    session.flush = AsyncMock()
    session.refresh = AsyncMock()
    session.add = MagicMock()

    async def _override():
        yield session

    app.dependency_overrides[get_db] = _override
    yield session
    app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_wechat_qr_preserves_safe_next(monkeypatch):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/auth/wechat/qr", params={"next": "/jobs"})

    assert response.status_code == 200
    data = response.json()
    assert data["state"]
    assert "state=" in data["qr_url"]
    assert wechat_router._state_cache[data["state"]].next_path == "/jobs"


@pytest.mark.asyncio
async def test_wechat_qr_rejects_external_next(monkeypatch):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/auth/wechat/qr",
            params={"next": "https://evil.example/callback"},
        )

    assert response.status_code == 200
    data = response.json()
    assert "state=" in data["qr_url"]
    assert wechat_router._state_cache[data["state"]].next_path == "/today"


@pytest.mark.asyncio
async def test_wechat_bind_accepts_json_body(monkeypatch, mock_db):
    from app.core.security import get_password_hash

    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")
    monkeypatch.setattr(
        "app.core.security.decode_access_token",
        lambda token: {"temp": True, "wechat_openid": "openid-1"},
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_login",
        AsyncMock(return_value=None),
    )

    user = MagicMock()
    user.id = 1
    user.username = "bound-user"
    user.email = "bound@example.com"
    user.role = "user"
    user.is_active = True
    user.created_at = "2026-06-10T00:00:00+00:00"
    user.hashed_password = get_password_hash("SecurePass1!")

    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_bind",
        AsyncMock(return_value=user),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.bind_wechat_openid",
        AsyncMock(return_value=user),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.get_role_permissions",
        AsyncMock(return_value=["job:read"]),
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/auth/wechat/bind",
            json={
                "temp_token": "temp-token",
                "username": "bound-user",
                "password": "SecurePass1!",
            },
        )

    assert response.status_code == 200
    assert response.json()["username"] == "bound-user"
```

- [ ] **Step 2: Run the backend tests to confirm the current contract fails**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; $env:JWT_SECRET_KEY='test-secret-key-for-wechat-plan'; pytest tests/test_wechat_auth_flow.py -q --tb=short"
```

Expected:

- `GET /auth/wechat/qr` does not yet sanitize and persist `next`
- `POST /auth/wechat/bind` still reads scalar params instead of JSON body

- [ ] **Step 3: Add explicit WeChat schemas and `next` sanitization**

Update `backend/app/schemas/auth.py` with:

```python
class WeChatQrResponse(BaseModel):
    qr_url: str
    state: str


class WeChatBindRequest(BaseModel):
    temp_token: str
    username: str
    password: str


class WeChatRegisterRequest(BaseModel):
    temp_token: str
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., max_length=100)

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        return validate_password_strength(value)
```

Update `backend/app/config.py` with:

```python
wechat_frontend_callback_url: str | None = None
```

Update `backend/app/domains/auth/wechat_router.py` with:

```python
from dataclasses import dataclass
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from app.schemas.auth import (
    UserResponse,
    WeChatBindRequest,
    WeChatQrResponse,
    WeChatRegisterRequest,
)


@dataclass(slots=True)
class WeChatStateEntry:
    issued_at: datetime
    next_path: str
    source: str = "login_page"


_state_cache: dict[str, WeChatStateEntry] = {}


def _normalize_next_path(raw_next: str | None) -> str:
    if not raw_next:
        return "/today"
    if not raw_next.startswith("/") or raw_next.startswith("//"):
        return "/today"
    split = urlsplit(raw_next)
    if split.scheme or split.netloc:
        return "/today"
    return urlunsplit(("", "", split.path or "/today", split.query, ""))
```

- [ ] **Step 4: Move QR, bind, and register endpoints onto explicit body/response contracts**

Update `backend/app/domains/auth/wechat_router.py` endpoint signatures to:

```python
@router.get("/qr", response_model=WeChatQrResponse)
async def get_wechat_qr_url(next: str | None = None):
    _check_wechat_enabled()

    _cleanup_expired_states()
    state = secrets.token_urlsafe(32)
    next_path = _normalize_next_path(next)
    _state_cache[state] = WeChatStateEntry(
        issued_at=datetime.now(UTC),
        next_path=next_path,
    )

    redirect_uri = settings.wechat_redirect_uri or "http://localhost:8000/auth/wechat/callback"
    qr_url = (
        f"{WECHAT_QR_CONNECT_URL}"
        f"?appid={settings.wechat_app_id}"
        f"&redirect_uri={redirect_uri}"
        f"&response_type=code"
        f"&scope=snsapi_login"
        f"&state={state}"
    )
    return WeChatQrResponse(qr_url=qr_url, state=state)


@router.post("/bind", response_model=UserResponse)
async def bind_wechat_account(
    payload: WeChatBindRequest,
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    temp_token = payload.temp_token
    username = payload.username
    password = payload.password
```

and:

```python
@router.post("/register", response_model=UserResponse)
async def register_with_wechat(
    payload: WeChatRegisterRequest,
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    temp_token = payload.temp_token
    username = payload.username
    email = payload.email
    password = payload.password
```

Do not keep duplicate manual password-strength validation after `WeChatRegisterRequest` is in place.

- [ ] **Step 5: Re-run the backend contract tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; $env:JWT_SECRET_KEY='test-secret-key-for-wechat-plan'; pytest tests/test_wechat_auth_flow.py tests/test_wechat_auth_password_policy.py -q --tb=short"
```

Expected:

- PASS for QR `next` handling
- PASS for JSON body binding
- PASS for existing strong-password rejection on WeChat registration

- [ ] **Step 6: Commit the backend contract cleanup**

Run:

```bash
git add backend/app/config.py backend/app/schemas/auth.py backend/app/domains/auth/wechat_router.py backend/tests/test_wechat_auth_flow.py
git commit -m "feat(auth): normalize wechat auth request contracts"
```

### Task 2: Redirect WeChat Callback Back to the Frontend

**Files:**

- Modify: `backend/app/domains/auth/wechat_router.py`
- Create: `backend/tests/test_wechat_auth_flow.py`
- Modify: `backend/tests/test_permissions_and_audit.py`

- [ ] **Step 1: Add failing callback redirect tests for success, unbound, and error cases**

Extend `backend/tests/test_wechat_auth_flow.py` with:

```python
@pytest.mark.asyncio
async def test_wechat_callback_redirects_bound_user_to_frontend(monkeypatch, mock_db):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.settings.wechat_frontend_callback_url",
        "http://localhost:3000/auth/wechat/callback",
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.httpx.AsyncClient.get",
        AsyncMock(return_value=MagicMock(json=lambda: {"openid": "openid-1"})),
    )

    user = MagicMock()
    user.id = 1
    user.username = "wechat-user"
    user.email = "wechat@example.com"
    user.role = "user"
    user.is_active = True
    user.created_at = "2026-06-10T00:00:00+00:00"

    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_login",
        AsyncMock(return_value=user),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.get_role_permissions",
        AsyncMock(return_value=["job:read"]),
    )

    qr_transport = ASGITransport(app=app)
    async with AsyncClient(transport=qr_transport, base_url="http://test") as client:
        qr = await client.get("/auth/wechat/qr", params={"next": "/jobs"})
        state = qr.json()["state"]
        response = await client.get(
            f"/auth/wechat/callback?code=valid-code&state={state}",
            follow_redirects=False,
        )

    assert response.status_code == 302
    assert response.headers["location"].startswith(
        "http://localhost:3000/auth/wechat/callback?status=success"
    )
    assert "pm_access_token=" in response.headers.get("set-cookie", "")


@pytest.mark.asyncio
async def test_wechat_callback_redirects_unbound_user_with_fragment(monkeypatch, mock_db):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.settings.wechat_frontend_callback_url",
        "http://localhost:3000/auth/wechat/callback",
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.httpx.AsyncClient.get",
        AsyncMock(return_value=MagicMock(json=lambda: {"openid": "openid-2"})),
    )
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.auth_service.get_user_for_wechat_login",
        AsyncMock(return_value=None),
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        qr = await client.get("/auth/wechat/qr", params={"next": "/today"})
        state = qr.json()["state"]
        response = await client.get(
            f"/auth/wechat/callback?code=valid-code&state={state}",
            follow_redirects=False,
        )

    assert response.status_code == 302
    assert "status=unbound" in response.headers["location"]
    assert "#temp_token=" in response.headers["location"]


@pytest.mark.asyncio
async def test_wechat_callback_redirects_state_error(monkeypatch):
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_login_enabled", True)
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_id", "wx-app")
    monkeypatch.setattr("app.domains.auth.wechat_router.settings.wechat_app_secret", "wx-secret")
    monkeypatch.setattr(
        "app.domains.auth.wechat_router.settings.wechat_frontend_callback_url",
        "http://localhost:3000/auth/wechat/callback",
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/auth/wechat/callback?code=bad&state=missing",
            follow_redirects=False,
        )

    assert response.status_code == 302
    assert "status=error" in response.headers["location"]
    assert "reason=state_expired" in response.headers["location"]
```

- [ ] **Step 2: Run the failing callback tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; $env:JWT_SECRET_KEY='test-secret-key-for-wechat-plan'; pytest tests/test_wechat_auth_flow.py::test_wechat_callback_redirects_bound_user_to_frontend tests/test_wechat_auth_flow.py::test_wechat_callback_redirects_unbound_user_with_fragment tests/test_wechat_auth_flow.py::test_wechat_callback_redirects_state_error -q --tb=short"
```

Expected:

- current callback returns JSON or raises `HTTPException`
- no frontend redirect contract exists yet

- [ ] **Step 3: Add a frontend callback URL builder and reason-code redirect helpers**

Update `backend/app/domains/auth/wechat_router.py` with:

```python
from fastapi.responses import RedirectResponse


def _get_frontend_callback_url() -> str:
    return (
        settings.wechat_frontend_callback_url
        or "http://localhost:3000/auth/wechat/callback"
    )


def _build_frontend_callback_redirect(
    *,
    status_value: str,
    next_path: str | None = None,
    reason: str | None = None,
    temp_token: str | None = None,
) -> str:
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
    return RedirectResponse(
        _build_frontend_callback_redirect(status_value="error", reason=reason),
        status_code=status.HTTP_302_FOUND,
    )
```

- [ ] **Step 4: Convert callback branches from JSON responses/exceptions into browser redirects**

Update `backend/app/domains/auth/wechat_router.py` callback branches to:

```python
    state_entry = _state_cache.pop(state, None)
    if state_entry is None:
        return _redirect_to_frontend_error("state_expired")
```

```python
    if "errcode" in token_data:
        logger.error("WeChat token exchange failed: %s", token_data)
        return _redirect_to_frontend_error("oauth_failed")

    openid = token_data.get("openid")
    if not openid:
        return _redirect_to_frontend_error("wechat_identity_missing")
```

```python
    if user:
        await _create_wechat_auth_session(user, request, response, db)
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
        response.status_code = status.HTTP_302_FOUND
        response.headers["location"] = _build_frontend_callback_redirect(
            status_value="success",
            next_path=state_entry.next_path,
        )
        return response
```

```python
    temp_token = create_access_token(
        data={"wechat_openid": openid, "temp": True},
        expires_delta=timedelta(minutes=10),
    )
    return RedirectResponse(
        _build_frontend_callback_redirect(
            status_value="unbound",
            next_path=state_entry.next_path,
            temp_token=temp_token,
        ),
        status_code=status.HTTP_302_FOUND,
    )
```

Do not change the disabled-feature behavior in `test_permissions_and_audit.py`; disabled endpoints should still return `503`.

- [ ] **Step 5: Re-run backend callback tests and the existing disabled-feature guard**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; $env:JWT_SECRET_KEY='test-secret-key-for-wechat-plan'; pytest tests/test_wechat_auth_flow.py tests/test_permissions_and_audit.py::TestWeChatDisabled -q --tb=short"
```

Expected:

- PASS for success redirect
- PASS for unbound redirect with fragment token
- PASS for invalid-state redirect
- PASS for existing `503` disabled guard

- [ ] **Step 6: Commit the callback redirect contract**

Run:

```bash
git add backend/app/domains/auth/wechat_router.py backend/tests/test_wechat_auth_flow.py backend/tests/test_permissions_and_audit.py
git commit -m "feat(auth): redirect wechat callback to frontend"
```

### Task 3: Add Frontend Callback Routing and WeChat API Helpers

**Files:**

- Modify: `frontend/src/App.tsx`
- Modify: `frontend/src/features/auth/api/auth.ts`
- Modify: `frontend/src/features/auth/index.ts`
- Create: `frontend/src/features/auth/WeChatAuthCallbackPage.tsx`
- Create: `frontend/src/features/auth/wechatCallback.ts`
- Create: `frontend/tests/unit/auth/wechat-auth-callback-page.test.tsx`

- [ ] **Step 1: Write failing unit tests for callback status parsing and token cleanup**

Create `frontend/tests/unit/auth/wechat-auth-callback-page.test.tsx` with:

```tsx
import { screen, waitFor } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { beforeEach, describe, expect, it, vi } from "vitest";

import WeChatAuthCallbackPage from "@/features/auth/WeChatAuthCallbackPage";
import { server } from "../mocks/server";
import { renderWithApp } from "../test-utils";

const mockNavigate = vi.fn();
const mockLocation = {
  pathname: "/auth/wechat/callback",
  search: "",
  hash: "",
};
const replaceStateSpy = vi
  .spyOn(window.history, "replaceState")
  .mockImplementation(() => {});

vi.mock("react-router-dom", async () => {
  const actual = await vi.importActual("react-router-dom");
  return {
    ...actual,
    useNavigate: () => mockNavigate,
    useLocation: () => mockLocation,
  };
});

describe("WeChatAuthCallbackPage", () => {
  beforeEach(() => {
    mockNavigate.mockReset();
    replaceStateSpy.mockClear();
  });

  it("restores auth on success and navigates to next", async () => {
    mockLocation.search = "?status=success&next=%2Fjobs";
    mockLocation.hash = "";

    server.use(
      http.get("/api/v1/auth/me", () =>
        HttpResponse.json({
          id: 1,
          username: "wechat-user",
          email: "wechat@example.com",
          role: "user",
          permissions: ["job:read"],
        }),
      ),
    );

    renderWithApp(<WeChatAuthCallbackPage />);

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith("/jobs", { replace: true });
    });
  });

  it("shows account-link panel when callback is unbound", async () => {
    mockLocation.search = "?status=unbound&next=%2Ftoday";
    mockLocation.hash = "#temp_token=temp-1";

    renderWithApp(<WeChatAuthCallbackPage />);

    expect(
      await screen.findByRole("tab", { name: "绑定已有账号" }),
    ).toBeInTheDocument();
    expect(replaceStateSpy).toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run the callback unit test and confirm the route/component is missing**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/auth/wechat-auth-callback-page.test.tsx"
```

Expected:

- import failure for `WeChatAuthCallbackPage`
- missing helper functions and auth API methods

- [ ] **Step 3: Add typed WeChat API methods and callback parsing helpers**

Update `frontend/src/features/auth/api/auth.ts` with:

```ts
export interface WeChatQrResponse {
  qr_url: string;
  state: string;
}

export interface WeChatBindRequest {
  temp_token: string;
  username: string;
  password: string;
}

export interface WeChatRegisterWithBindRequest {
  temp_token: string;
  username: string;
  email: string;
  password: string;
}

export const authApi = {
  getWeChatQr: (nextPath?: string) =>
    api.get<WeChatQrResponse>("/v1/auth/wechat/qr", {
      params: nextPath ? { next: nextPath } : undefined,
    }),

  bindWeChat: (data: WeChatBindRequest) =>
    api.post<User>("/v1/auth/wechat/bind", data),

  registerWithWeChat: (data: WeChatRegisterWithBindRequest) =>
    api.post<User>("/v1/auth/wechat/register", data),
};
```

Create `frontend/src/features/auth/wechatCallback.ts`:

```ts
export type WeChatCallbackStatus = "success" | "unbound" | "error";

export interface WeChatCallbackState {
  status: WeChatCallbackStatus | null;
  next: string;
  reason: string | null;
  tempToken: string | null;
}

export function parseWeChatCallback(
  search: string,
  hash: string,
): WeChatCallbackState {
  const query = new URLSearchParams(search);
  const fragment = new URLSearchParams(hash.replace(/^#/, ""));
  return {
    status: (query.get("status") as WeChatCallbackStatus | null) ?? null,
    next: query.get("next") || "/today",
    reason: query.get("reason"),
    tempToken: fragment.get("temp_token"),
  };
}

export function clearWeChatCallbackHash(
  pathname: string,
  search: string,
): void {
  window.history.replaceState({}, document.title, `${pathname}${search}`);
}
```

- [ ] **Step 4: Add a dedicated frontend callback page and route it outside `PublicRoute`**

Create `frontend/src/features/auth/WeChatAuthCallbackPage.tsx`:

```tsx
import { Alert, Button, Card, Spin, Tabs } from "antd";
import { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";

import { authApi } from "./api/auth";
import { parseWeChatCallback, clearWeChatCallbackHash } from "./wechatCallback";
import { useAuth } from "@/shared/contexts/AuthContext";
import WeChatAccountLinkPanel from "./components/WeChatAccountLinkPanel";

export default function WeChatAuthCallbackPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const { login } = useAuth();
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const callbackState = parseWeChatCallback(location.search, location.hash);

  useEffect(() => {
    if (callbackState.tempToken) {
      clearWeChatCallbackHash(location.pathname, location.search);
    }

    if (callbackState.status === "success") {
      authApi
        .getMe()
        .then((response) => {
          login(response.data);
          navigate(callbackState.next, { replace: true });
        })
        .catch(() => {
          setError("登录状态恢复失败，请重试");
        })
        .finally(() => setLoading(false));
      return;
    }

    setLoading(false);
  }, [
    callbackState.next,
    callbackState.status,
    callbackState.tempToken,
    location.pathname,
    location.search,
    login,
    navigate,
  ]);

  if (loading) {
    return <Spin size="large" />;
  }

  if (callbackState.status === "unbound" && callbackState.tempToken) {
    return (
      <WeChatAccountLinkPanel
        nextPath={callbackState.next}
        tempToken={callbackState.tempToken}
      />
    );
  }

  if (callbackState.status === "error" || error) {
    return (
      <Card>
        <Alert type="error" message={error || "微信登录失败，请重新扫码"} />
        <Button onClick={() => navigate("/login", { replace: true })}>
          返回登录页
        </Button>
      </Card>
    );
  }

  return <Spin size="large" />;
}
```

Update `frontend/src/App.tsx`:

```tsx
const WeChatAuthCallbackPage = React.lazy(() =>
  import("@/features/auth").then((m) => ({
    default: m.WeChatAuthCallbackPage,
  })),
);
```

and add a dedicated route before the public/protected groups:

```tsx
<Route path="/auth/wechat/callback" element={<WeChatAuthCallbackPage />} />
```

Update `frontend/src/features/auth/index.ts`:

```ts
export { default as WeChatAuthCallbackPage } from "./WeChatAuthCallbackPage";
```

Do not wrap `/auth/wechat/callback` in `PublicRoute`; already-authenticated success redirects must be allowed to finish.

- [ ] **Step 5: Re-run the callback unit tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/auth/wechat-auth-callback-page.test.tsx"
```

Expected:

- PASS for success-path navigation
- PASS for unbound panel render
- PASS for token hash cleanup from the browser URL

- [ ] **Step 6: Commit the callback-route frontend infrastructure**

Run:

```bash
git add frontend/src/App.tsx frontend/src/features/auth/api/auth.ts frontend/src/features/auth/index.ts frontend/src/features/auth/WeChatAuthCallbackPage.tsx frontend/src/features/auth/wechatCallback.ts frontend/tests/unit/auth/wechat-auth-callback-page.test.tsx
git commit -m "feat(auth): add frontend wechat callback route"
```

### Task 4: Add the Login-Page WeChat Panel and the Unbound Account-Link UI

**Files:**

- Modify: `frontend/package.json`
- Modify: `frontend/package-lock.json`
- Modify: `frontend/src/features/auth/LoginPage.tsx`
- Create: `frontend/src/features/auth/components/WeChatLoginPanel.tsx`
- Create: `frontend/src/features/auth/components/WeChatAccountLinkPanel.tsx`
- Modify: `frontend/tests/unit/auth/login-page.test.tsx`

- [ ] **Step 1: Add failing login-page tests for the expandable WeChat panel**

Extend `frontend/tests/unit/auth/login-page.test.tsx` with:

```tsx
it("expands the WeChat panel and renders a QR code after loading", async () => {
  server.use(
    http.get("/api/v1/auth/wechat/qr", () =>
      HttpResponse.json({
        qr_url: "https://open.weixin.qq.com/connect/qrconnect?state=abc",
        state: "abc",
      }),
    ),
  );

  renderWithApp(<LoginPage />);

  const user = userEvent.setup();
  await user.click(screen.getByRole("button", { name: /wechat login/i }));

  expect(await screen.findByText("Scan with WeChat")).toBeInTheDocument();
  expect(screen.getByTitle("WeChat login QR")).toBeInTheDocument();
});

it("shows a disabled-state message when WeChat login is unavailable", async () => {
  server.use(
    http.get("/api/v1/auth/wechat/qr", () =>
      HttpResponse.json({ detail: "微信登录未启用" }, { status: 503 }),
    ),
  );

  renderWithApp(<LoginPage />);

  const user = userEvent.setup();
  await user.click(screen.getByRole("button", { name: /wechat login/i }));

  expect(await screen.findByText("当前环境未启用微信登录")).toBeInTheDocument();
});
```

- [ ] **Step 2: Run the login-page unit tests to confirm the panel does not exist yet**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/auth/login-page.test.tsx"
```

Expected:

- no expandable WeChat panel
- current button is disabled

- [ ] **Step 3: Add a QR rendering dependency and build the login-page panel**

Install a small QR renderer:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm install react-qr-code"
```

Create `frontend/src/features/auth/components/WeChatLoginPanel.tsx`:

```tsx
import { Alert, Button, Card, Spin, Typography } from "antd";
import QRCode from "react-qr-code";
import { useEffect, useState } from "react";

import { authApi } from "../api/auth";
import { formatApiError } from "@/shared/api/client";

interface Props {
  nextPath: string;
  onClose: () => void;
}

export default function WeChatLoginPanel({ nextPath, onClose }: Props) {
  const [loading, setLoading] = useState(true);
  const [qrUrl, setQrUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    authApi
      .getWeChatQr(nextPath)
      .then((response) => setQrUrl(response.data.qr_url))
      .catch((err) => {
        const message = formatApiError(err, "当前环境未启用微信登录");
        setError(
          message.includes("未启用") ? "当前环境未启用微信登录" : message,
        );
      })
      .finally(() => setLoading(false));
  }, [nextPath]);

  if (loading) return <Spin size="small" />;
  if (error) return <Alert type="warning" message={error} />;
  if (!qrUrl) return <Alert type="error" message="二维码加载失败，请重试" />;

  return (
    <Card>
      <Typography.Title level={4}>Scan with WeChat</Typography.Title>
      <div title="WeChat login QR">
        <QRCode value={qrUrl} size={180} />
      </div>
      <Typography.Paragraph>
        使用微信扫一扫并确认网页登录，成功后会自动返回当前页面继续登录。
      </Typography.Paragraph>
      <Button onClick={onClose}>返回账号登录</Button>
    </Card>
  );
}
```

- [ ] **Step 4: Replace the placeholder login button and add the unbound bind/register panel**

Create `frontend/src/features/auth/components/WeChatAccountLinkPanel.tsx`:

```tsx
import { App, Button, Form, Input, Tabs } from "antd";
import { useNavigate } from "react-router-dom";

import { authApi } from "../api/auth";
import { strongPasswordMessage, strongPasswordRule } from "../passwordPolicy";
import { formatApiError } from "@/shared/api/client";
import { useAuth } from "@/shared/contexts/AuthContext";

interface Props {
  tempToken: string;
  nextPath: string;
}

export default function WeChatAccountLinkPanel({ tempToken, nextPath }: Props) {
  const navigate = useNavigate();
  const { login } = useAuth();
  const message = App.useApp().message;

  const bindTab = (
    <Form
      layout="vertical"
      onFinish={(values) =>
        authApi
          .bindWeChat({ temp_token: tempToken, ...values })
          .then((response) => {
            login(response.data);
            navigate(nextPath, { replace: true });
          })
          .catch((error) => {
            message.error(formatApiError(error, "绑定失败，请重新扫码"));
          })
      }
    >
      <Form.Item name="username" label="Username" rules={[{ required: true }]}>
        <Input />
      </Form.Item>
      <Form.Item name="password" label="Password" rules={[{ required: true }]}>
        <Input.Password />
      </Form.Item>
      <Button htmlType="submit" type="primary">
        绑定已有账号
      </Button>
    </Form>
  );

  const registerTab = (
    <Form
      layout="vertical"
      onFinish={(values) =>
        authApi
          .registerWithWeChat({ temp_token: tempToken, ...values })
          .then((response) => {
            login(response.data);
            navigate(nextPath, { replace: true });
          })
          .catch((error) => {
            message.error(formatApiError(error, "注册失败，请重新扫码"));
          })
      }
    >
      <Form.Item name="username" label="Username" rules={[{ required: true }]}>
        <Input />
      </Form.Item>
      <Form.Item
        name="email"
        label="Email"
        rules={[{ required: true, type: "email" }]}
      >
        <Input />
      </Form.Item>
      <Form.Item
        name="password"
        label="Password"
        rules={[{ required: true }, strongPasswordRule()]}
        extra={strongPasswordMessage}
      >
        <Input.Password />
      </Form.Item>
      <Button htmlType="submit" type="primary">
        注册新账号
      </Button>
    </Form>
  );

  return (
    <Tabs
      items={[
        { key: "bind", label: "绑定已有账号", children: bindTab },
        { key: "register", label: "注册新账号", children: registerTab },
      ]}
    />
  );
}
```

Update `frontend/src/features/auth/LoginPage.tsx`:

```tsx
import { useState } from "react";
import WeChatLoginPanel from "./components/WeChatLoginPanel";

const from =
  (location.state as { from?: { pathname: string } })?.from?.pathname ||
  "/today";
const [showWeChatPanel, setShowWeChatPanel] = useState(false);
```

Replace the disabled placeholder button with:

```tsx
<div style={{ marginTop: 16 }}>
  <Button
    size="large"
    block
    onClick={() => setShowWeChatPanel((current) => !current)}
  >
    WeChat Login
  </Button>
</div>;

{
  showWeChatPanel ? (
    <div style={{ marginTop: 16 }}>
      <WeChatLoginPanel
        nextPath={from}
        onClose={() => setShowWeChatPanel(false)}
      />
    </div>
  ) : null;
}
```

- [ ] **Step 5: Run the focused frontend unit tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/auth/login-page.test.tsx tests/unit/auth/wechat-auth-callback-page.test.tsx"
```

Expected:

- PASS for login-page QR panel expansion
- PASS for disabled-state messaging
- PASS for callback unbound rendering and success navigation

- [ ] **Step 6: Commit the login-page WeChat UI**

Run:

```bash
git add frontend/package.json frontend/package-lock.json frontend/src/features/auth/LoginPage.tsx frontend/src/features/auth/components/WeChatLoginPanel.tsx frontend/src/features/auth/components/WeChatAccountLinkPanel.tsx frontend/tests/unit/auth/login-page.test.tsx
git commit -m "feat(auth): add login page wechat flow"
```

### Task 5: Cover the Browser Flow End-to-End and Update Reference Docs

**Files:**

- Modify: `frontend/tests/e2e/fixtures/app-test.ts`
- Modify: `frontend/tests/e2e/auth.spec.ts`
- Modify: `doc/reference-config.md`
- Modify: `doc/reference-api-auth.md`

- [ ] **Step 1: Add failing browser tests for success, unbound-bind, and error callback states**

Extend `frontend/tests/e2e/auth.spec.ts` with:

```tsx
test("supports WeChat success callback and navigates to the next path", async ({
  page,
  api,
}) => {
  api.use("GET", "/api/v1/auth/me", () => ({
    status: 200,
    body: adminUser,
  }));

  await page.goto("/auth/wechat/callback?status=success&next=%2Fjobs");
  await page.waitForURL("**/jobs");
  await expect(page).toHaveURL(/.*\/jobs/);
});

test("supports WeChat unbound flow by binding an existing account", async ({
  page,
  api,
}) => {
  api.use("POST", "/api/v1/auth/wechat/bind", () => ({
    status: 200,
    body: adminUser,
  }));

  await page.goto(
    "/auth/wechat/callback?status=unbound&next=%2Ftoday#temp_token=temp-1",
  );
  await page.fill('input[name="username"]', "default");
  await page.fill('input[name="password"]', "Adminf8869!@");
  await page.click('button:has-text("绑定已有账号")');

  await page.waitForURL("**/today");
  await expect(page).toHaveURL(/.*\/today/);
});

test("shows a callback error message and returns to /login", async ({
  page,
}) => {
  await page.goto("/auth/wechat/callback?status=error&reason=state_expired");
  await expect(page.getByText("微信登录失败，请重新扫码")).toBeVisible();
});
```

- [ ] **Step 2: Run the E2E auth suite and confirm the WeChat flow fails before implementation**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; $env:E2E_BASE_URL='http://localhost:3000'; npx playwright test tests/e2e/auth.spec.ts --project=chromium"
```

Expected:

- callback route or WeChat panel is missing
- new auth flow cases fail

- [ ] **Step 3: Add default WeChat API mocks and stabilize the browser-level flow**

Update `frontend/tests/e2e/fixtures/app-test.ts` with default WeChat mocks:

```ts
api.use("GET", "/api/v1/auth/wechat/qr", () => ({
  body: {
    qr_url: "https://open.weixin.qq.com/connect/qrconnect?state=test-state",
    state: "test-state",
  },
}));
api.use("POST", "/api/v1/auth/wechat/bind", () => ({
  body: adminUser,
}));
api.use("POST", "/api/v1/auth/wechat/register", () => ({
  body: adminUser,
}));
```

Keep the suite mock-only; do not add `route.continue()` fallthrough for any `/api/v1/auth/wechat/**` request.

- [ ] **Step 4: Update human-facing auth/config reference docs**

Update `doc/reference-config.md` with:

```md
| `WECHAT_FRONTEND_CALLBACK_URL` | `http://localhost:3000/auth/wechat/callback` | 前端微信回流展示页 |
```

Update `doc/reference-api-auth.md` to explain:

```md
- `GET /auth/wechat/qr` accepts optional `next`, limited to站内相对路径。
- `GET /auth/wechat/callback` no longer returns a final JSON login payload for browsers.
- 已绑定用户会在后端写入 cookie 后重定向到前端 `/auth/wechat/callback?status=success&next=...`
- 未绑定用户会重定向到前端 `/auth/wechat/callback?status=unbound&next=...#temp_token=...`
- `temp_token` 仅用于绑定或注册，不落盘，不通过 query 传播。
```

- [ ] **Step 5: Run the final verification set**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; $env:JWT_SECRET_KEY='test-secret-key-for-wechat-plan'; pytest tests/test_wechat_auth_flow.py tests/test_permissions_and_audit.py tests/test_wechat_auth_password_policy.py -q --tb=short"
```

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/auth/login-page.test.tsx tests/unit/auth/wechat-auth-callback-page.test.tsx"
```

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run lint"
```

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run build"
```

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; $env:E2E_BASE_URL='http://localhost:3000'; npx playwright test tests/e2e/auth.spec.ts --project=chromium"
```

Expected:

- backend WeChat flow tests pass without real external calls
- frontend unit tests pass with MSW only
- lint and build pass
- Playwright auth suite passes with the in-process API firewall

- [ ] **Step 6: Commit the tests and docs**

Run:

```bash
git add frontend/tests/e2e/fixtures/app-test.ts frontend/tests/e2e/auth.spec.ts doc/reference-config.md doc/reference-api-auth.md
git commit -m "test(auth): cover wechat login browser flow"
```

## Self-Review

### Spec coverage

- 登录页内微信入口：Task 4
- 后端 `next`/state/callback 重定向契约：Task 1 and Task 2
- 前端 callback 分流：Task 3
- 未绑定绑定/注册双路径：Task 4
- mock-only 测试边界：Task 5
- 文档与配置项更新：Task 5

No approved requirement from `docs/2026-06-10-wechat-login-design.md` is left without a matching task.

### Placeholder scan

- No `TODO` / `TBD`
- No “similar to previous task” references
- Every test/run step includes a concrete command

### Type consistency

The plan uses the same names throughout:

- `WeChatQrResponse`
- `WeChatBindRequest`
- `WeChatRegisterRequest`
- `WeChatAuthCallbackPage`
- `WeChatLoginPanel`
- `WeChatAccountLinkPanel`
