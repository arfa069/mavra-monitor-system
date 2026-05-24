# HttpOnly Cookie + Refresh Session Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Run GitNexus impact analysis before editing auth symbols.

**Goal:** Replace browser `localStorage` bearer-token auth with HttpOnly Cookie auth, short-lived access JWTs, refresh tokens, CSRF protection, and session-table-backed device/session control.

**Architecture:** Authentication becomes Cookie-first and Cookie-only for browser clients. Access JWTs are short-lived and stored in HttpOnly cookies; refresh tokens are opaque random strings stored only as hashes in `users_sessions`. The session table remains the server-side revocation and device state source.

**Tech Stack:** FastAPI, SQLAlchemy async, Alembic, React, Vite, Axios, EventSource/SSE.

---

## Summary

The current browser auth path stores `auth_token` in `localStorage` and sends `Authorization: Bearer <token>`. This plan removes that browser risk surface in one cut:

- No compatibility window for old Bearer/localStorage auth.
- Cookies use `SameSite=Lax`.
- Unsafe requests require CSRF protection.
- `users_sessions` manages refresh token hashes and device state.
- Existing user lifecycle semantics stay unchanged: `deleted_at` is the auth truth; `is_active` remains compatibility surface only.

After this change, existing sessions cannot be converted safely and users must log in again.

## 2026-05-24 审查记录

本计划于 2026-05-24 对照项目重构后的实际代码审查，发现以下需要修正的问题，已同步修改到各 Task 中：

- **路径过时**: 前端文件路径引用的是重构前的旧结构 (`frontend/src/shared/api/client.ts`, `frontend/src/contexts/`, `frontend/src/hooks/`)。已全部更新为重构后的路径 (`frontend/src/shared/`, `frontend/src/features/`)。
- **Session 模型变更**: 原计划将 `token_hash` 改名为 `refresh_token_hash`，但 `get_current_user` 依赖 `token_hash` 做 JWT 会话校验。修正为两列并存：保留 `token_hash` 不动，新增 `refresh_token_hash`。access JWT 通过 `sid` claim 查 `Session.id`，不再哈希 JWT 原文。
- **CSRF 设计**: 补充了 CSRF dependency 在 auth 链中的位置——在 `get_current_user` 之后、业务 handler 之前。
- **登录返回 schema**: 明确登录返回 `UserResponse`（含 permissions），不再返回 `TokenResponse`。
- **Session 创建时序**: 登录流程修正为「验证密码 → 创建 session → 生成带 sid 的 JWT → 写 refresh_token_hash → 设 Cookie」。
- **`get_current_user` 重写影响面**: 标注了依赖此函数的 router 数量，建议先跑 GitNexus blast radius。
- **Token 过期时间变更**: 从 60 分钟→15 分钟，补充了选择理由（短生命周期减少泄露窗口，配合 refresh token 保持体验）。

## Key Contract Changes

### Backend API

- `POST /auth/login`
  - Validates username/password.
  - Creates a session row.
  - Sets:
    - `pm_access_token`: HttpOnly access JWT cookie, 15 minutes.
    - `pm_refresh_token`: HttpOnly opaque refresh token cookie, 14 days.
    - `pm_csrf_token`: non-HttpOnly CSRF cookie.
  - Returns current user profile and permissions.
  - Does not return `access_token`.

- `POST /auth/refresh`
  - Reads `pm_refresh_token`.
  - Finds matching `users_sessions.refresh_token_hash`.
  - Verifies `refresh_expires_at`.
  - Rotates refresh token and hash.
  - Sets new access, refresh, and CSRF cookies.
  - Returns current user profile and permissions.

- `POST /auth/logout`
  - Requires valid Cookie auth and CSRF token.
  - Deletes the current session row.
  - Clears auth and CSRF cookies.

- Protected APIs
  - Use Cookie auth only.
  - Do not accept `Authorization: Bearer` as a browser auth fallback.

- SSE endpoints
  - Remove token query authentication.
  - Authenticate through the same Cookie/session path.

### Cookies

Use these default cookie names:

- `pm_access_token`
- `pm_refresh_token`
- `pm_csrf_token`

Cookie defaults:

- `HttpOnly=True` for access and refresh cookies.
- `HttpOnly=False` for CSRF cookie.
- `SameSite=Lax`.
- `Secure=True` outside local development.
- `Path=/`.

### CSRF

For unsafe methods (`POST`, `PATCH`, `PUT`, `DELETE`):

- Frontend reads `pm_csrf_token`.
- Frontend sends `X-CSRF-Token`.
- Backend compares header value with cookie value.
- Missing or mismatched token returns `403`.

Safe methods (`GET`, `HEAD`, `OPTIONS`) do not require CSRF header.

## Implementation Tasks

### Task 1: Backend Token And Cookie Primitives

Modify `backend/app/config.py`, `backend/app/core/tokens.py`, and add a small cookie helper module if needed.

- Add settings:
  - `auth_access_cookie_name = "pm_access_token"`
  - `auth_refresh_cookie_name = "pm_refresh_token"`
  - `auth_csrf_cookie_name = "pm_csrf_token"`
  - `auth_csrf_header_name = "X-CSRF-Token"`
  - `access_token_expire_minutes = 15`
  - `refresh_token_expire_days = 14`
  - `auth_cookie_samesite = "lax"`
  - `auth_cookie_secure = not debug`
- Keep JWT algorithm and secret sourced from existing JWT settings.
- Add access JWT helpers:
  - `create_access_token(user_id: int, username: str, session_id: int)`.
  - Payload must include `sub`, `username`, `sid`, `typ="access"`, and `exp`.
  - Decode must reject invalid, expired, wrong `typ`, missing `sub`, and missing `sid`.
- Add opaque token helpers:
  - `create_refresh_token() -> str` using `secrets.token_urlsafe(48)`.
  - `hash_token(token: str) -> str` using SHA256 hex digest.
- Add CSRF helper:
  - `create_csrf_token() -> str` using `secrets.token_urlsafe(32)`.

Tests:

- Access token has `typ="access"` and `sid`.
- Expired or malformed access token returns authentication failure.
- Refresh token hashes are deterministic and never store the raw value.

### Task 2: Session Table Migration And Model

Modify `backend/app/models/session.py` and create an Alembic migration.

Schema target for `users_sessions`:

- Add `refresh_token_hash` column (String(64), unique, nullable initially, index). Keep existing `token_hash` column unchanged for access-token session validation. After access JWT moves to `sid`-based lookup, `token_hash` can be dropped in a follow-up migration.
- Add `refresh_expires_at DateTime(timezone=True), nullable=False`.
- Keep `user_id`, `device`, `ip_address`, `last_active_at`, `created_at`, `updated_at`.
- Keep a unique index/constraint on `refresh_token_hash`.

Migration policy:

- Existing sessions are not migrated as valid refresh sessions.
- The migration may clear existing session rows before enforcing `refresh_expires_at NOT NULL`, or add the column with a temporary value and then delete legacy rows.
- After deployment, users must log in again.

Tests:

- Session model exposes `refresh_token_hash` and `refresh_expires_at`.
- Session creation stores only the hash.
- Max session count remains 5 and removes the oldest session.

### Task 3: Session Helpers

Modify `backend/app/core/sessions.py`.

Required helpers:

- `create_session(user_id, refresh_token, device, ip_address, db) -> Session`
  - Hashes refresh token.
  - Sets `refresh_expires_at`.
  - Enforces max 5 sessions per user.
  - Commits only where current helper compatibility requires it.

- `get_session_by_refresh_token(refresh_token, db) -> Session | None`
  - Hashes input token.
  - Requires matching `refresh_token_hash`.
  - Requires `refresh_expires_at > now`.

- `rotate_session_refresh_token(session, new_refresh_token, db) -> None`
  - Updates hash and expiry.
  - Updates `last_active_at`.
  - Caller controls commit in sensitive flows.

- `get_session_by_id(session_id, user_id, db) -> Session | None`
  - Used by access-token auth.

- Existing delete helpers continue to delete by session id and user id.

Tests:

- Refresh lookup fails when expired.
- Refresh lookup fails after logout deletion.
- Rotation invalidates the old refresh token.

### Task 4: Cookie-Based Authentication Dependency

Modify `backend/app/core/security.py`.

Required behavior:

- Replace `OAuth2PasswordBearer` as the main auth source with Cookie extraction from `Request`.
- `get_current_user` reads `pm_access_token`.
- It decodes and validates access JWT.
- It validates `sid` as an integer.
- It loads `users_sessions.id == sid` and `user_id == sub`.
- It loads `users.deleted_at is null`.
- It does not check `users.is_active`.
- It returns 401 for:
  - Missing cookie.
  - Invalid/expired access token.
  - Wrong token type.
  - Missing/deleted session.
  - Deleted user.
  - Malformed `sub` or `sid`.

Add or wire a CSRF dependency/middleware (runs AFTER `get_current_user`, before business handler):

- Defined as a FastAPI dependency: `def csrf_protect(request: Request) -> None`.
- Injected per-router or per-endpoint on unsafe methods via `Depends(csrf_protect)`.
- Compares `pm_csrf_token` Cookie with `X-CSRF-Token` header.
- Returns 403 on missing or mismatch.

> **影响面注意**: `get_current_user` 被 8 个 domain router 和多个内部依赖引用。重写前务必先跑 `gitnexus impact(target=\"get_current_user\", direction=\"upstream\")` 确认 blast radius。

- Enforce only unsafe methods.
- Compare `pm_csrf_token` Cookie with `X-CSRF-Token`.
- Return 403 on missing or mismatch.

Tests:

- `/auth/me` succeeds with access Cookie.
- `/auth/me` fails with only Authorization header.
- Malformed `sid` returns 401, not 500.
- Deleted user returns 401.
- Session deletion invalidates access token immediately.

### Task 5: Auth Routes

Modify `backend/app/domains/auth/router.py` and `backend/app/schemas/auth.py`.

Required behavior:

- `login`
  - Keeps Redis lockout behavior.
  - Rejects `deleted_at is not null`.
  - Creates refresh token and session.
  - Creates access token using session id.
  - Sets access, refresh, and CSRF cookies.
  - Returns the same user shape as `/auth/me`, including permissions.
  - Does not return bearer token.

- `refresh`
  - Reads refresh Cookie.
  - Validates session and user.
  - Rotates refresh token.
  - Sets new cookies.
  - Returns current user shape.

- `logout`
  - Deletes current session.
  - Clears all auth cookies.
  - Keeps best-effort audit logging.

- `change_password`
  - Requires current session.
  - Updates password and deletes all other sessions in the same transaction.
  - Rotates current session refresh token and sets fresh cookies.

- Session management endpoints
  - Continue listing/deleting sessions by id.
  - Deleting the current session should clear cookies or return a message that causes frontend logout.

Tests:

- Login response has no `access_token`.
- Login sets three cookies.
- Refresh rotates refresh token and updates DB hash.
- Reusing old refresh token after rotation fails.
- Logout clears cookies and invalidates current session.
- Password change invalidates other sessions.

### Task 6: Non-Standard Auth Entrypoints

Modify `backend/app/domains/events/router.py`, `backend/app/domains/dashboard/router.py`, and `backend/app/domains/auth/wechat_router.py`.

Required behavior:

- Event Center SSE authenticates from Cookie and no longer accepts `token` query param.
- Dashboard SSE authenticates from Cookie and no longer accepts `token` query param.
- Middleware best-effort logging may decode Cookie access token for user id.
- WeChat successful login/bind/register sets the same cookies as password login.
- WeChat callback temp token remains short-lived and single-purpose; it is not stored in localStorage.

Tests:

- SSE rejects query-token-only requests.
- SSE accepts valid Cookie session.
- WeChat login path uses Cookie response contract.

### Task 7: Frontend API Client

Modify `frontend/src/shared/api/client.ts`.

Required behavior:

- Set `withCredentials: true`.
- Remove Authorization header injection.
- Add CSRF header for unsafe methods by reading `pm_csrf_token` from `document.cookie`.
- On 401:
  - If request is not `/auth/login` and has not already retried, call `POST /auth/refresh`.
  - Retry the original request once.
  - If refresh fails, redirect to `/login`.
- Keep existing user-facing error notifications.

Tests or checks:

- Unit-level helper test if frontend test infra exists; otherwise manual browser verification.
- Confirm network requests include Cookie automatically and unsafe requests include `X-CSRF-Token`.

### Task 8: Frontend Auth State And Login

Modify `frontend/src/shared/contexts/AuthContext.tsx`, `frontend/src/features/auth/api/auth.ts`, and login/register pages.

Required behavior:

- Remove `token` from `AuthContext`.
- Remove all `localStorage.auth_token` reads/writes.
- Do not cache auth user as source of truth; initialize by calling `/auth/me`.
- `login()` should accept a `User`, not a token.
- `logout()` should call `/auth/logout` and then clear in-memory user state.
- Login page uses `/auth/login` response user data directly.
- Register page follows the new response contract if it currently expects token output.

Tests or checks:

- Fresh page load restores auth through Cookie and `/auth/me`.
- `localStorage.auth_token` is absent after login.
- Logout redirects or updates UI as expected.

### Task 9: Frontend SSE

Modify `frontend/src/features/dashboard/hooks/useDashboardSSE.ts` and `frontend/src/features/events/api/events.ts`.

Required behavior:

- Remove token query parameters from EventSource URLs.
- Rely on same-origin `/api/...` URLs so cookies are included.
- Dashboard SSE hook no longer requires a token parameter.
- Event Center stream builder no longer reads `localStorage`.

Tests or checks:

- Dashboard SSE connects after login.
- Event Center SSE connects after login.
- After logout, SSE reconnect attempts fail with 401 or close cleanly.

### Task 10: Documentation And Cleanup

Update documentation after implementation:

- `doc/backend-architecture.md`: document Cookie + refresh session auth.
- `doc/frontend-architecture.md`: document no localStorage auth token and Axios credential flow.
- `doc/permission-architecture.md`: mention permissions still derive from role and `/auth/me`.
- `doc/auth-cookie-refresh-implementation-plan.md`: mark implementation status if desired.

Cleanup:

- Remove stale `auth_token` constants.
- Remove stale bearer-token examples from auth docs/comments.
- Search for `Authorization`, `auth_token`, `access_token`, and `token=` to ensure no browser auth path remains.

## Verification Plan

Run backend targeted tests first:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_auth.py tests/test_sessions.py tests/test_event_center.py tests/test_dashboard.py -v"
```

Run backend full verification:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check ."
```

Run frontend checks:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run lint"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"
```

Run real browser verification:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"
```

Manual browser checks:

- Login with the default test account.
- Confirm `localStorage.auth_token` is absent.
- Confirm access and refresh cookies are HttpOnly.
- Confirm unsafe requests include `X-CSRF-Token`.
- Refresh the page and confirm `/auth/me` restores the session.
- Trigger Dashboard SSE and Event Center SSE.
- Logout and confirm `/auth/me` returns 401.
- Confirm old copied Bearer token does not authenticate.
- Change password and confirm other sessions are invalidated.

Before commit:

- Run GitNexus `detect_changes`.
- Confirm changed execution flows are auth/session/SSE/frontend-auth only.

## Assumptions And Defaults

- This is a breaking auth migration with no Bearer/localStorage compatibility window.
- Users must log in again after migration.
- Local development uses Vite `/api` same-origin proxy, so `SameSite=Lax` works.
- Future cross-site deployment needs a separate cookie/CORS review.
- Access token lifetime is 15 minutes（从原 60 分钟缩短，减少 JWT 泄露窗口。配合自动 refresh，用户无感知）。
- Refresh token lifetime is 14 days.
- Maximum sessions per user remains 5.
- `deleted_at` remains the only auth lifecycle truth.
