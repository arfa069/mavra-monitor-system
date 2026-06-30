# Canonical `/api/v1` Path Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task by task.

**Goal:** Expose every business API only at `/api/v1/*`, migrate every in-repository consumer in the same release, and make all legacy and `/v1/*` aliases return `404`.

**Architecture:** FastAPI owns one `API_PREFIX = "/api/v1"` and registers each business router once. The main React frontend owns that prefix in one shared API-base module while feature modules use resource-relative paths. Vite and production proxies preserve the browser path unchanged. OpenAPI and Orval outputs are regenerated mechanically, but the existing Orval mutator/type mismatch is not repaired in this migration.

**Tech Stack:** FastAPI, Pydantic/OpenAPI, pytest, React, TypeScript, Axios, Vitest, MSW, Playwright, Vite, Next.js, Orval, GitNexus.

---

## Non-Negotiable Boundaries

- The only business API namespace after the change is `/api/v1/*`.
- Do not add redirects, compatibility routers, `410` responses, or temporary aliases.
- Keep `/health`, `/health/detailed`, `/docs`, `/redoc`, and `/openapi.json` at the root.
- Keep persisted public assets at `/blog-media/*`.
- Keep the React page route `/auth/wechat/callback`; only the backend OAuth callback moves to `/api/v1/auth/wechat/callback`.
- Do not fix `frontend/orval.config.ts`, `frontend/src/shared/api/mutator.ts`, generated-hook adoption, or the known `RequestInit` versus `AxiosRequestConfig` build problem.
- Do not modify local `.env` files or commit secrets. Update tracked examples and document the operator action.
- Do not run real crawl, profile login/session/test, job matching analysis, Home Assistant configuration tests, or Home Assistant service controls.
- Do not run `scripts/start_server.ps1` during automated verification. It starts a worker and may claim persisted crawl tasks.
- Browser verification is mock-only. API requests must never escape through `route.continue()` or `route.fallback()`.
- Preserve unrelated uncommitted changes. Execute from a dedicated worktree created from a commit containing this plan and its approved design.

## Known Baseline

- Approved design: `docs/2026-06-12-single-api-path-design.md`.
- Current backend registration exposes legacy, `/v1`, and `/api/v1` aliases.
- Current browser flow is `/api/v1/*` -> Vite strips `/api` -> FastAPI receives `/v1/*`.
- Current generated client contains duplicate legacy, `/v1`, and `/api/v1` operations.
- The frontend build may still fail after regeneration because of the already identified Orval mutator typing mismatch. Record that result; do not expand scope.
- GitNexus previously rated `_include_application_routers` as MEDIUM impact because many backend tests import `app`. Re-run impact analysis immediately before editing because the index or worktree may have changed.

## Task 0: Prepare an Isolated Execution Worktree

**Files:**

- Read: `docs/2026-06-12-single-api-path-design.md`
- Read: `docs/2026-06-12-single-api-path-implementation-plan.md`
- Do not modify: the original checkout's unrelated dirty files

- [ ] **Step 1: Confirm the plan and design are committed**

Run from the original checkout:

```powershell
git status --short
git log -2 --oneline -- docs/2026-06-12-single-api-path-design.md docs/2026-06-12-single-api-path-implementation-plan.md
```

Expected: both documents are reachable from `HEAD`; unrelated dirty files remain unstaged.

- [ ] **Step 2: Create the dedicated worktree**

```powershell
git worktree add .worktrees/single-api-path -b codex/single-api-path HEAD
Set-Location .worktrees/single-api-path
```

Expected: a clean worktree on `codex/single-api-path`.

- [ ] **Step 3: Verify dependencies without starting services**

```powershell
Test-Path backend/.venv
Test-Path frontend/node_modules
Test-Path blog-frontend/node_modules
```

Install missing dependencies using the repository's normal commands, but do not start the backend, frontend, scheduler, or worker.

- [ ] **Step 4: Record the baseline path inventory**

```powershell
rg -n '/v1/|"/(auth|admin|alerts|config|products|jobs|events|dashboard|scheduler|crawl-profiles|smart-home|blog|crawl)(/|")' backend/tests -g '*.py'
rg -n "'/(auth|admin|alerts|config|products|jobs|events|dashboard|scheduler|crawl-profiles|smart-home|blog|crawl)(/|')" backend/tests -g '*.py'
rg -n '/v1/' frontend/src -g '*.ts' -g '*.tsx' --glob '!src/shared/api/generated/**'
rg -n '/v1|BLOG_API_BASE_URL|WECHAT_REDIRECT_URI' README.md .env.example blog-frontend doc backend/docs scripts
```

Expected: save the output in the execution notes. This is the migration checklist, not a reason to alter historical plans.

## Task 1: Move Backend Test Consumers to Canonical URLs

This task changes test call sites while the backend still supports all aliases. It creates a clean consumer baseline before removing routes.

**Files:**

- Modify: `backend/tests/test_admin_permissions.py`
- Modify: `backend/tests/test_admin_users.py`
- Modify: `backend/tests/test_alerts.py`
- Modify: `backend/tests/test_api.py`
- Modify: `backend/tests/test_audit_best_effort.py`
- Modify: `backend/tests/test_audit_logs_listing.py`
- Modify: `backend/tests/test_auth.py`
- Modify: `backend/tests/test_auth_api.py`
- Modify: `backend/tests/test_blog_router.py`
- Modify: `backend/tests/test_blog_service.py`
- Modify: `backend/tests/test_boss_cloak_experimental.py`
- Modify: `backend/tests/test_crawl_profile_api.py`
- Modify: `backend/tests/test_crawler_worker_registry.py`
- Modify: `backend/tests/test_dashboard.py`
- Modify: `backend/tests/test_e2e_crawl_flow.py`
- Modify: `backend/tests/test_health_endpoint.py` only where it calls business APIs
- Modify: `backend/tests/test_integration_crawl_phase1.py`
- Modify: `backend/tests/test_integration_crawl_phase2.py`
- Modify: `backend/tests/test_integration_realdb.py`
- Modify: `backend/tests/test_job_crawl.py`
- Modify: `backend/tests/test_job_match_api.py`
- Modify: `backend/tests/test_jobs_api.py`
- Modify: `backend/tests/test_permissions_and_audit.py`
- Modify: `backend/tests/test_phase_c_integration.py`
- Modify: `backend/tests/test_scheduler_status_auth.py`
- Modify: `backend/tests/test_smart_home_router.py`
- Modify: `backend/tests/test_user_management_realdb.py`
- Modify: `backend/tests/test_wechat_auth_flow.py`
- Modify: `backend/tests/test_wechat_auth_password_policy.py`
- Defer: `backend/tests/test_api_v1_routes.py`
- Defer: `backend/tests/test_event_center.py`

- [ ] **Step 1: Mechanically rewrite direct API test calls**

Run from the repository root:

```powershell
$files = Get-ChildItem backend/tests -File -Filter '*.py' |
  Where-Object {
    $_.Name -notin @(
      'test_api_v1_routes.py',
      'test_event_center.py'
    )
  }

$prefixes = @(
  'auth',
  'admin',
  'alerts',
  'config',
  'products',
  'jobs',
  'events',
  'dashboard',
  'scheduler',
  'crawl-profiles',
  'smart-home',
  'blog',
  'crawl'
)

foreach ($file in $files) {
  $text = [IO.File]::ReadAllText($file.FullName)

  foreach ($quote in @('"', "'")) {
    $text = $text.Replace("$quote/products/crawl/", "$quote/api/v1/crawl/")
    $text = $text.Replace("$quote/v1/", "$quote/api/v1/")

    foreach ($prefix in $prefixes) {
      $text = $text.Replace("$quote/$prefix/", "$quote/api/v1/$prefix/")
      $text = $text.Replace("$quote/$prefix$quote", "$quote/api/v1/$prefix$quote")
    }
  }

  [IO.File]::WriteAllText(
    $file.FullName,
    $text,
    [Text.UTF8Encoding]::new($false)
  )
}
```

The replacement is intentionally limited to quoted path literals. It must not alter:

- `http://localhost:3000/auth/wechat/callback`
- `/health` and `/health/detailed`
- `/blog-media/*`
- frontend page-route assertions
- external service URLs

- [ ] **Step 2: Review the mechanical diff**

```powershell
git diff -- backend/tests
rg -n '/api/v1/api/v1|/api/v1/v1' backend/tests -g '*.py'
rg -n '/v1/|"/(auth|admin|alerts|config|products|jobs|events|dashboard|scheduler|crawl-profiles|smart-home|blog|crawl)(/|")' backend/tests -g '*.py'
rg -n "'/(auth|admin|alerts|config|products|jobs|events|dashboard|scheduler|crawl-profiles|smart-home|blog|crawl)(/|')" backend/tests -g '*.py'
```

Expected:

- No double prefixes.
- Remaining old paths are confined to the two deferred contract files, intentional frontend callback URLs, or comments that explicitly describe removed paths.

- [ ] **Step 3: Run backend tests before route removal**

```powershell
Set-Location backend
pytest -q -m "not live"
Set-Location ..
```

Expected: the canonicalized tests still pass because `/api/v1/*` already exists. If any test attempts an external crawl, browser profile, matching analysis, or device control, stop that test and replace its boundary with a mock before continuing.

- [ ] **Step 4: Check affected flows before the test-only commit**

Use GitNexus:

```text
detect_changes(repo="mavra-monitor-system", scope="unstaged")
```

Expected: only backend test consumers are affected; no runtime process should be changed.

- [ ] **Step 5: Commit the test consumer migration**

```powershell
git add backend/tests
git diff --cached --check
git commit -m "test(api): use canonical api v1 paths"
```

## Task 2: Remove Backend Aliases and Synchronize the Contract

**Files:**

- Modify: `backend/app/main.py`
- Modify: `backend/app/domains/auth/wechat_router.py`
- Modify: `backend/tests/test_api_v1_routes.py`
- Modify: `backend/tests/test_event_center.py`
- Modify: `backend/tests/test_wechat_auth_flow.py`
- Regenerate: `frontend/openapi.json`
- Regenerate: `frontend/src/shared/api/generated/**`
- Do not modify: `frontend/orval.config.ts`
- Do not modify: `frontend/src/shared/api/mutator.ts`

- [ ] **Step 1: Run mandatory GitNexus impact analysis before editing**

```text
impact(
  repo="mavra-monitor-system",
  target="_include_application_routers",
  direction="upstream",
  maxDepth=3,
  includeTests=true
)

impact(
  repo="mavra-monitor-system",
  target="_is_event_center_path",
  direction="upstream",
  maxDepth=3,
  includeTests=true
)

impact(
  repo="mavra-monitor-system",
  target="api_root",
  direction="upstream",
  maxDepth=3,
  includeTests=true
)

impact(
  repo="mavra-monitor-system",
  target="get_wechat_qr_url",
  direction="upstream",
  maxDepth=3,
  includeTests=true
)

api_impact(
  repo="mavra-monitor-system",
  file="backend/app/main.py"
)
```

Expected: `_include_application_routers` may remain MEDIUM because tests import `app`. If any result is HIGH or CRITICAL, report it and reassess before editing.

- [ ] **Step 2: Write the failing route contract**

Replace `backend/tests/test_api_v1_routes.py` with tests equivalent to:

```python
"""Tests for the single canonical business API prefix."""

import pytest
from fastapi.testclient import TestClient

from app.main import app


def test_only_canonical_business_routes_are_registered():
    paths = {route.path for route in app.routes}

    canonical = {
        "/api/v1/auth/login",
        "/api/v1/products",
        "/api/v1/crawl/crawl-now",
        "/api/v1/events/stream",
        "/api/v1/scheduler/status",
        "/api/v1/auth/wechat/callback",
    }
    removed = {
        "/auth/login",
        "/products",
        "/products/crawl/crawl-now",
        "/events/stream",
        "/v1/auth/login",
        "/v1/products",
        "/v1/crawl/crawl-now",
        "/v1/events/stream",
    }

    assert canonical <= paths
    assert paths.isdisjoint(removed)


def test_canonical_api_root_returns_one_prefix():
    response = TestClient(app).get("/api/v1")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["prefixes"] == ["/api/v1"]


@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("POST", "/auth/login"),
        ("GET", "/products"),
        ("POST", "/products/crawl/crawl-now"),
        ("POST", "/v1/auth/login"),
        ("GET", "/v1/products"),
        ("POST", "/v1/crawl/crawl-now"),
    ],
)
def test_removed_business_aliases_return_404_without_redirect(method, path):
    response = TestClient(app).request(method, path, follow_redirects=False)

    assert response.status_code == 404
    assert "location" not in response.headers
```

- [ ] **Step 3: Tighten Event Center path tests**

In `backend/tests/test_event_center.py`:

- Change endpoint calls from `/events...` to `/api/v1/events...`.
- Replace the path exclusion assertions with:

```python
def test_event_center_paths_are_excluded_from_platform_http_logging():
    from app.main import _is_event_center_path

    assert _is_event_center_path("/api/v1/events")
    assert _is_event_center_path("/api/v1/events/stream")
    assert not _is_event_center_path("/events")
    assert not _is_event_center_path("/v1/events")
    assert not _is_event_center_path("/api/v1/jobs")
```

- [ ] **Step 4: Add the WeChat callback default regression test**

In `backend/tests/test_wechat_auth_flow.py`, use only `/api/v1/auth/wechat/*` for backend requests. Add a test that parses the QR URL rather than matching raw query text:

```python
from urllib.parse import parse_qs, urlparse


@pytest.mark.asyncio
async def test_wechat_qr_uses_canonical_backend_callback_by_default(
    monkeypatch,
    async_client,
):
    monkeypatch.setattr(settings, "wechat_login_enabled", True)
    monkeypatch.setattr(settings, "wechat_app_id", "test-app")
    monkeypatch.setattr(settings, "wechat_app_secret", "test-secret")
    monkeypatch.setattr(settings, "wechat_redirect_uri", None)

    response = await async_client.get("/api/v1/auth/wechat/qr")

    assert response.status_code == 200
    query = parse_qs(urlparse(response.json()["qr_url"]).query)
    assert query["redirect_uri"] == [
        "http://localhost:8000/api/v1/auth/wechat/callback"
    ]
```

Adapt fixture names to the file's existing fixtures; do not introduce a second app/client setup.

- [ ] **Step 5: Run the contract tests and observe failure**

```powershell
Set-Location backend
pytest -q tests/test_api_v1_routes.py tests/test_event_center.py tests/test_wechat_auth_flow.py
Set-Location ..
```

Expected: failures show legacy routes are still registered, `/v1` still exists, Event Center still recognizes aliases, and the default WeChat callback still lacks `/api/v1`.

- [ ] **Step 6: Implement one backend prefix**

In `backend/app/main.py`, introduce and use one constant:

```python
API_PREFIX = "/api/v1"


def _is_event_center_path(path: str) -> bool:
    event_prefix = f"{API_PREFIX}/events"
    return path == event_prefix or path.startswith(f"{event_prefix}/")
```

Replace parameterized registration with:

```python
def _include_application_routers() -> None:
    for router in _APPLICATION_ROUTERS:
        app.include_router(router, prefix=API_PREFIX)


_include_application_routers()
app.include_router(crawl_router, prefix=API_PREFIX)
app.include_router(blog_media_router)
```

Delete:

- `_include_application_routers()` at the root.
- `_include_application_routers(prefix="/v1")`.
- `_include_application_routers(prefix="/api/v1")`.
- `crawl_router` registrations at `/products` and `/v1`.
- All comments describing the Vite rewrite as required behavior.

Keep one root:

```python
@app.get(API_PREFIX)
async def api_root():
    return {
        "name": settings.app_name,
        "status": "ok",
        "docs": "/docs",
        "prefixes": [API_PREFIX],
    }
```

In `backend/app/domains/auth/wechat_router.py`, change only the backend callback default:

```python
redirect_uri = (
    settings.wechat_redirect_uri
    or "http://localhost:8000/api/v1/auth/wechat/callback"
)
```

Keep `_get_frontend_callback_url()` at:

```text
http://localhost:3000/auth/wechat/callback
```

- [ ] **Step 7: Run backend verification**

```powershell
Set-Location backend
pytest -q tests/test_api_v1_routes.py tests/test_event_center.py tests/test_wechat_auth_flow.py
pytest -q -m "not live"
ruff check app/main.py app/domains/auth/wechat_router.py tests/test_api_v1_routes.py tests/test_event_center.py tests/test_wechat_auth_flow.py
Set-Location ..
```

Expected: all selected and non-live backend tests pass. No service or worker is started.

- [ ] **Step 8: Export OpenAPI and regenerate Orval output**

These files must be committed with the backend route changes:

```powershell
python scripts/export_openapi.py
Set-Location frontend
npm run api:generate
Set-Location ..
```

Expected:

- `frontend/openapi.json` contains one operation per business endpoint.
- Generated files no longer contain `/v1/*` or unprefixed business operations.
- Generated files still contain `/api/v1/*`.

- [ ] **Step 9: Validate the generated contract structurally**

```powershell
@'
import json
from pathlib import Path

schema = json.loads(Path("frontend/openapi.json").read_text(encoding="utf-8"))
paths = set(schema["paths"])

required = {
    "/api/v1/auth/login",
    "/api/v1/products",
    "/api/v1/crawl/crawl-now",
    "/api/v1/events/stream",
    "/api/v1/auth/wechat/callback",
    "/health",
    "/health/detailed",
}
removed = {
    "/auth/login",
    "/products",
    "/products/crawl/crawl-now",
    "/v1/auth/login",
    "/v1/products",
    "/v1/crawl/crawl-now",
}

assert required <= paths, sorted(required - paths)
assert paths.isdisjoint(removed), sorted(paths & removed)
assert any(path.startswith("/blog-media/") for path in paths)
'@ | python -

rg -n '/v1/' frontend/src/shared/api/generated
```

Expected: Python exits `0`; the `rg` command prints no generated `/v1/*` paths.

- [ ] **Step 10: Review impact and commit backend plus generated artifacts together**

```text
detect_changes(repo="mavra-monitor-system", scope="unstaged")
```

Review the generated diff for route deletion only, then:

```powershell
git add backend/app/main.py backend/app/domains/auth/wechat_router.py backend/tests/test_api_v1_routes.py backend/tests/test_event_center.py backend/tests/test_wechat_auth_flow.py frontend/openapi.json frontend/src/shared/api/generated
git diff --cached --check
git commit -m "refactor(api): expose only canonical api v1 routes"
```

This is a branch checkpoint, not a deployable mixed-version release. Do not deploy until all consumers are migrated.

## Task 3: Make the Main Frontend Preserve `/api/v1`

**Files:**

- Create: `frontend/src/shared/api/base.ts`
- Modify: `frontend/src/shared/api/client.ts`
- Modify: `frontend/vite.config.ts`
- Modify: `frontend/src/features/admin/api/admin.ts`
- Modify: `frontend/src/features/alerts/api/alerts.ts`
- Modify: `frontend/src/features/auth/api/auth.ts`
- Modify: `frontend/src/features/blog/api/blog.ts`
- Modify: `frontend/src/features/dashboard/DashboardPage.tsx`
- Modify: `frontend/src/features/dashboard/hooks/useDashboardSSE.ts`
- Modify: `frontend/src/features/dashboard/hooks/useDashboardTrends.ts`
- Modify: `frontend/src/features/dashboard/hooks/useRecentAlerts.ts`
- Modify: `frontend/src/features/events/api/events.ts`
- Modify: `frontend/src/features/jobs/api/job_match.ts`
- Modify: `frontend/src/features/jobs/api/jobs.ts`
- Modify: `frontend/src/features/products/api/crawl.ts`
- Modify: `frontend/src/features/products/api/products.ts`
- Modify: `frontend/src/features/settings/api/config.ts`
- Modify: `frontend/src/features/smart-home/api/smartHome.ts`
- Modify: `frontend/src/features/today/hooks/useTodayData.ts`
- Modify: `frontend/tests/unit/shared/api-client.test.ts`
- Modify: `frontend/tests/unit/dashboard/dashboard-sse.test.tsx`
- Modify: `frontend/tests/unit/events/events.test.tsx`
- Modify: `frontend/tests/unit/smart-home/smart-home-sse.test.tsx`
- Modify: `frontend/tests/e2e/fixtures/api-mock.ts`
- Modify: `frontend/tests/e2e/fixtures/api-mock.spec.ts`
- Modify: `frontend/tests/e2e/fixtures/app-test.ts`
- Do not manually modify: `frontend/src/shared/api/generated/**`

- [ ] **Step 1: Run mandatory impact analysis**

Use GitNexus on the shared client and SSE URL builders before editing:

```text
impact(
  repo="mavra-monitor-system",
  target="frontend/src/shared/api/client.ts",
  direction="upstream",
  maxDepth=3,
  includeTests=true
)

impact(
  repo="mavra-monitor-system",
  target="buildStreamUrl",
  direction="upstream",
  maxDepth=3,
  includeTests=true
)

impact(
  repo="mavra-monitor-system",
  target="useDashboardSSE",
  direction="upstream",
  maxDepth=3,
  includeTests=true
)
```

If `buildStreamUrl` is ambiguous, disambiguate with `file_path`. Stop and report any HIGH or CRITICAL result.

- [ ] **Step 2: Write frontend URL and refresh regressions first**

In `frontend/tests/unit/shared/api-client.test.ts`:

- Change resource calls from `/v1/config` to `/config`.
- Change protected calls from `/v1/protected-*` to `/protected-*`.
- Keep MSW handlers at `/api/v1/*`.
- Add:

```typescript
import { API_BASE_URL, apiUrl } from "@/shared/api/base";

it("owns the canonical API prefix in one place", () => {
  expect(API_BASE_URL).toBe("/api/v1");
  expect(apiUrl("/events/stream")).toBe("/api/v1/events/stream");
});
```

Keep the concurrent `401` test and its assertion that only one request reaches `/api/v1/auth/refresh`.

In the SSE tests, add exact URL and credentials assertions:

```typescript
expect(esInstance.url).toBe("/api/v1/dashboard/events");
expect(esInstance.options).toEqual({ withCredentials: true });
```

```typescript
expect(eventsApi.buildStreamUrl({ kind: "system" } as any)).toBe(
  "/api/v1/events/stream?kind=system",
);
```

```typescript
expect(smartHomeApi.buildStreamUrl()).toBe(
  "/api/v1/smart-home/entities/stream",
);
```

- [ ] **Step 3: Strengthen the mock-only E2E firewall**

In `frontend/tests/e2e/fixtures/api-mock.ts`:

- Match only paths beginning with `/api/` or `/v1/`.
- Delete the `route.continue()` branch.
- Record `/v1/*` as a legacy-path violation and return `501`.
- Keep dangerous canonical endpoints blocked.
- Keep unregistered canonical endpoints returning `501`.

The handler should contain:

```typescript
if (path.startsWith("/v1/")) {
  this.violations.push(`LEGACY ${key}`);
  await route.fulfill({
    status: 501,
    contentType: "application/json",
    body: JSON.stringify({ detail: `Legacy API path rejected: ${key}` }),
  });
  return;
}
```

Add a direct `ApiMock` test in `frontend/tests/e2e/fixtures/api-mock.spec.ts`:

```typescript
test("records LEGACY and rejects v1 calls", async ({ page }) => {
  const api = new ApiMock();
  await api.install(page);
  await page.goto("/");

  const status = await page.evaluate(async () => {
    const response = await fetch("/v1/products");
    return response.status;
  });

  expect(status).toBe(501);
  expect(api.getViolations()).toContain("LEGACY GET /v1/products");
});
```

This spec uses `ApiMock` directly, so the normal `app-test.ts` teardown does not reject the intentionally recorded violation.

Remove this compatibility handler from `frontend/tests/e2e/fixtures/app-test.ts`:

```typescript
api.use("GET", "/v1/dashboard/events", () => ({ body: [] }));
```

- [ ] **Step 4: Run tests and observe the current failures**

```powershell
Set-Location frontend
npm run test:unit -- tests/unit/shared/api-client.test.ts tests/unit/dashboard/dashboard-sse.test.tsx tests/unit/events/events.test.tsx tests/unit/smart-home/smart-home-sse.test.tsx
npx playwright test tests/e2e/fixtures/api-mock.spec.ts --project=chromium
Set-Location ..
```

Expected: URL assertions fail until the shared base, resource paths, and firewall are changed.

- [ ] **Step 5: Add the shared API base**

Create `frontend/src/shared/api/base.ts`:

```typescript
const DEFAULT_API_BASE_URL = "/api/v1";

export const API_BASE_URL = (
  import.meta.env.VITE_API_URL?.trim() || DEFAULT_API_BASE_URL
).replace(/\/+$/, "");

export function apiUrl(path: `/${string}`): string {
  return `${API_BASE_URL}${path}`;
}
```

Do not accept a path without a leading slash; the template-literal type keeps resource-path usage consistent.

- [ ] **Step 6: Make Axios own the prefix and isolate refresh**

In `frontend/src/shared/api/client.ts`:

```typescript
import { API_BASE_URL } from "@/shared/api/base";

const API_TIMEOUT_MS = 300_000;

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: API_TIMEOUT_MS,
  withCredentials: true,
});

const refreshApi = axios.create({
  baseURL: API_BASE_URL,
  timeout: API_TIMEOUT_MS,
  withCredentials: true,
});
```

Change refresh to:

```typescript
await refreshApi.post("/auth/refresh");
```

Keep refresh isolated from the normal response interceptor so it cannot enter its own `401` retry loop. Preserve the existing queue, `_retry`, login/current-user exclusions, and redirect behavior.

- [ ] **Step 7: Convert feature modules to resource-relative paths**

Use a scoped mechanical rewrite, excluding generated code:

```powershell
Set-Location frontend
$files = rg -l '/v1/' src -g '*.ts' -g '*.tsx' --glob '!src/shared/api/generated/**'

foreach ($file in $files) {
  $text = [IO.File]::ReadAllText($file)
  $text = $text.Replace('"/v1/', '"/')
  $text = $text.Replace("'/v1/", "'/")
  $text = $text.Replace('`/v1/', '`/')
  [IO.File]::WriteAllText(
    $file,
    $text,
    [Text.UTF8Encoding]::new($false)
  )
}
Set-Location ..
```

Review every changed call. Examples:

```typescript
api.get("/products");
api.post("/auth/login", data);
api.get(`/jobs/${jobId}`);
api.post(`/crawl-profiles/${encodeURIComponent(profileKey)}/import`, formData);
```

Do not remove `encodeURIComponent` from entity IDs, profile keys, slugs, or other path parameters.

- [ ] **Step 8: Use the shared base for all SSE URLs**

Examples:

```typescript
import { apiUrl } from "@/shared/api/base";

new EventSource(apiUrl("/dashboard/events"), {
  withCredentials: true,
});
```

```typescript
buildStreamUrl(params) {
  const searchParams = new URLSearchParams();
  // Preserve the existing non-empty filter logic.
  const query = searchParams.toString();
  return apiUrl(`/events/stream${query ? `?${query}` : ""}`);
}
```

```typescript
buildStreamUrl: () => apiUrl("/smart-home/entities/stream"),
```

Preserve reconnect behavior and Event Center query parameters.

- [ ] **Step 9: Remove the Vite rewrite**

In `frontend/vite.config.ts`, keep the proxy and delete only `rewrite`:

```typescript
proxy: {
  "/api": {
    target: "http://127.0.0.1:8000",
    changeOrigin: true,
  },
},
```

The browser and FastAPI must now see the same `/api/v1/*` path.

- [ ] **Step 10: Review runtime path invariants**

```powershell
Set-Location frontend
rg -n '/v1/' src -g '*.ts' -g '*.tsx' --glob '!src/shared/api/generated/**'
rg -n 'api\.(get|post|put|patch|delete).*"/api|api\.(get|post|put|patch|delete).*`/api' src -g '*.ts' -g '*.tsx' --glob '!src/shared/api/generated/**'
rg -n 'rewrite:\s*\(' vite.config.ts
Set-Location ..
```

Expected: no output. The only runtime `/api/v1` ownership should be the shared base module, while generated code contains canonical full paths by design.

- [ ] **Step 11: Run main frontend verification**

```powershell
Set-Location frontend
npm run test:unit
npm run test:e2e
npm run lint
Set-Location ..
```

Expected:

- Unit tests pass.
- Playwright passes using only the mock firewall.
- No live API, crawl, profile, matching, or control request escapes.
- Lint passes or any pre-existing generated lint issue is recorded separately.

- [ ] **Step 12: Review impact and commit**

```text
detect_changes(repo="mavra-monitor-system", scope="unstaged")
```

Expected: affected flows are the shared HTTP client, feature API consumers, SSE consumers, Vite development proxy, and mock-backed tests.

```powershell
git add frontend/src frontend/tests frontend/vite.config.ts
git diff --cached --check
git commit -m "refactor(frontend): preserve canonical api v1 paths"
```

## Task 4: Migrate Blog and OAuth Configuration Surfaces

**Files:**

- Modify: `blog-frontend/src/lib/blog.ts`
- Modify: `blog-frontend/src/lib/blog.test.ts`
- Modify: `.env.example`
- Modify: `README.md`
- Do not modify: `.env`
- Do not modify: `blog-frontend/.env*` files containing local secrets

- [ ] **Step 1: Add a failing blog default test**

Extend `blog-frontend/src/lib/blog.test.ts`:

```typescript
import { apiBaseUrl, buildArticleJsonLd, canonicalUrl } from "./blog";

it("defaults the backend API base to the canonical prefix", () => {
  const previous = process.env.BLOG_API_BASE_URL;
  delete process.env.BLOG_API_BASE_URL;

  try {
    expect(apiBaseUrl()).toBe("http://127.0.0.1:8000/api/v1");
  } finally {
    if (previous === undefined) {
      delete process.env.BLOG_API_BASE_URL;
    } else {
      process.env.BLOG_API_BASE_URL = previous;
    }
  }
});
```

- [ ] **Step 2: Run the focused test and observe failure**

```powershell
Set-Location blog-frontend
npm test -- src/lib/blog.test.ts
Set-Location ..
```

Expected: the default remains `http://127.0.0.1:8000/v1`.

- [ ] **Step 3: Change only the API base default**

In `blog-frontend/src/lib/blog.ts`:

```typescript
const DEFAULT_API_BASE_URL = "http://127.0.0.1:8000/api/v1";
```

Keep:

- Resource paths such as `/blog/posts`.
- Public asset handling for `/blog-media/*`.
- `BLOG_BACKEND_ORIGIN` as an origin without a path.

- [ ] **Step 4: Update tracked environment examples**

In `.env.example`:

```dotenv
BLOG_API_BASE_URL=http://127.0.0.1:8000/api/v1
WECHAT_REDIRECT_URI=http://localhost:8000/api/v1/auth/wechat/callback
WECHAT_FRONTEND_CALLBACK_URL=http://localhost:3000/auth/wechat/callback
```

Update the corresponding README examples. Do not edit or stage real local `.env` files. Before deployment, the operator must update:

- The production `WECHAT_REDIRECT_URI`.
- The WeChat platform callback whitelist.
- The deployed blog frontend's `BLOG_API_BASE_URL`.

- [ ] **Step 5: Verify blog behavior**

```powershell
Set-Location blog-frontend
npm test
npm run build
Set-Location ..
```

Expected: tests and build pass; generated article asset URLs still use `/blog-media/*`.

- [ ] **Step 6: Review impact and commit**

Use GitNexus impact analysis on `apiBaseUrl` before editing if it was not already run, then:

```text
detect_changes(repo="mavra-monitor-system", scope="unstaged")
```

```powershell
git add blog-frontend/src/lib/blog.ts blog-frontend/src/lib/blog.test.ts .env.example README.md
git diff --cached --check
git commit -m "docs(config): use canonical api callback urls"
```

## Task 5: Synchronize Living Documentation and Runnable Examples

Historical plans under `docs/` and `backend/docs/superpowers/` remain historical unless they are presented as current instructions.

**Files to inspect and modify only when they contain live old-path guidance:**

- `README.md`
- `ARCHITECTURE.md`
- `backend/tests/manual_verification_checklist.md`
- `backend/docs/auth-error-codes.md`
- `doc/backend-architecture.md`
- `doc/explanation-auth-rbac.md`
- `doc/explanation-scheduler.md`
- `doc/explanation-sse-realtime.md`
- `doc/frontend-architecture.md`
- `doc/howto-add-product.md`
- `doc/howto-boss-profile.md`
- `doc/howto-cron-schedule.md`
- `doc/howto-debug-crawl.md`
- `doc/howto-deploy-worker.md`
- `doc/howto-feishu-webhook.md`
- `doc/howto-rbac.md`
- `doc/permission-architecture.md`
- `doc/reference-api-auth.md`
- `doc/reference-api-jobs.md`
- `doc/reference-api-products.md`
- `doc/reference-config.md`
- `doc/tutorial-getting-started.md`
- `doc/tutorial-job-monitoring.md`
- `doc/tutorial-smart-home.md`
- Relevant tracked proxy/deployment configuration discovered by the scan

- [ ] **Step 1: Find live old-path examples**

```powershell
rg -n 'localhost:8000/(v1|auth|admin|alerts|config|products|jobs|events|dashboard|scheduler|crawl-profiles|smart-home|blog|crawl)|(^|[^a-zA-Z])/v1/' README.md ARCHITECTURE.md doc backend/docs backend/tests/manual_verification_checklist.md scripts .env.example
rg -n 'proxy_pass|rewrite.*api|location\s+/api' . -g '*.conf' -g '*.nginx' -g '*.yaml' -g '*.yml' -g '*.toml'
```

- [ ] **Step 2: Update only current commands and architecture statements**

Use `/api/v1/*` for all business API examples. Preserve:

```text
/health
/health/detailed
/docs
/redoc
/openapi.json
/blog-media/*
/auth/wechat/callback   # React page route only
```

Document that proxies preserve `/api/v1` unchanged and SSE locations need buffering disabled and long read timeouts.

- [ ] **Step 3: Document the breaking release**

Add a concise migration note to the primary architecture or README surface:

```text
Business APIs are available only under /api/v1.
Legacy unversioned and /v1 aliases return 404 and are not redirected.
Backend and clients must be deployed from the same revision.
```

- [ ] **Step 4: Review documentation paths**

```powershell
rg -n 'localhost:8000/(v1|auth|admin|alerts|config|products|jobs|events|dashboard|scheduler|crawl-profiles|smart-home|blog|crawl)|(^|[^a-zA-Z])/v1/' README.md ARCHITECTURE.md doc backend/docs backend/tests/manual_verification_checklist.md scripts .env.example
```

Expected: remaining matches are explicitly historical, frontend page routes, or text describing removed aliases.

- [ ] **Step 5: Review impact and commit**

```text
detect_changes(repo="mavra-monitor-system", scope="unstaged")
```

```powershell
git add README.md ARCHITECTURE.md doc backend/docs backend/tests/manual_verification_checklist.md scripts .env.example
git diff --cached --check
git commit -m "docs(api): document canonical api v1 namespace"
```

Stage only files actually changed. Do not stage unrelated files or historical plans changed accidentally by a bulk replacement.

## Task 6: Run End-to-End Static and Automated Verification

This task verifies the branch without starting live services.

- [ ] **Step 1: Verify backend route shape directly**

```powershell
Set-Location backend
@'
from fastapi.testclient import TestClient
from app.main import app

paths = {route.path for route in app.routes}
assert "/api/v1/products" in paths
assert "/products" not in paths
assert "/v1/products" not in paths
assert "/blog-media/{file_path:path}" in paths

client = TestClient(app)
assert client.get("/api/v1").status_code == 200
assert client.get("/products", follow_redirects=False).status_code == 404
assert client.get("/v1/products", follow_redirects=False).status_code == 404
'@ | python -
Set-Location ..
```

If the exact blog-media route parameter name differs, assert the discovered `/blog-media/` route rather than renaming the route.

- [ ] **Step 2: Run backend quality checks**

```powershell
Set-Location backend
ruff check .
pytest -q -m "not live"
Set-Location ..
```

Expected: checks pass without external crawling or profile creation.

- [ ] **Step 3: Re-run contract synchronization and require a clean result**

```powershell
python scripts/export_openapi.py
Set-Location frontend
npm run api:generate
Set-Location ..
git diff --exit-code -- frontend/openapi.json frontend/src/shared/api/generated
```

Expected: no diff after regeneration.

- [ ] **Step 4: Run main frontend checks**

```powershell
Set-Location frontend
npm run lint
npm run test:unit
npm run test:e2e
npm run build
Set-Location ..
```

Expected:

- Lint, unit tests, and mock-only E2E pass.
- If `npm run build` still fails only with the known generated `RequestInit` versus `AxiosRequestConfig` mismatch, capture the exact error as an existing Orval blocker.
- Do not change Orval configuration or generated client architecture in response.
- Any new migration-related build failure must be fixed before completion.

- [ ] **Step 5: Run blog frontend checks**

```powershell
Set-Location blog-frontend
npm test
npm run build
Set-Location ..
```

Expected: pass.

- [ ] **Step 6: Run final runtime path scans**

```powershell
rg -n '/api/v1/api/v1|/api/v1/v1' backend frontend blog-frontend scripts README.md ARCHITECTURE.md doc

rg -n '/v1/' frontend/src frontend/tests backend/app backend/tests blog-frontend/src blog-frontend/app scripts

rg -n 'baseURL:\s*"/api"|rewrite:\s*\(path.*replace\(\^?/api' frontend/src frontend/vite.config.ts

rg -n 'http://localhost:8000/auth/wechat/callback|http://127\.0\.0\.1:8000/v1' .env.example README.md backend/app blog-frontend/src doc backend/docs
```

Expected:

- No double prefix.
- No runtime `/v1/*` consumer.
- No Vite prefix-stripping rewrite.
- No old backend WeChat callback or blog API default.
- Any remaining `/auth/wechat/callback` is the frontend page route or explanatory text.

- [ ] **Step 7: Verify boundary cases**

Confirm through existing or newly added tests:

- Cookies still use `Path=/` for set and clear.
- Unsafe Axios requests still add `X-CSRF-Token`.
- Refresh remains exempt from the normal retry interceptor.
- Two simultaneous `401` responses cause one refresh.
- SSE uses canonical URLs, query parameters, credentials, and reconnects to the same URL.
- Blog upload API is `/api/v1/blog/admin/uploads`, while returned assets remain `/blog-media/*`.
- Profile import/export remains canonical and preserves multipart/blob behavior.
- Encoded Smart Home entity IDs and profile keys remain encoded once.
- `/health`, `/health/detailed`, docs, and OpenAPI remain root infrastructure paths.

Do not validate these boundaries with real crawl, real profile, or real Home Assistant actions.

## Task 7: Independent Quality Gates and Release Readiness

Verification and code review must be separate passes.

- [ ] **Step 1: Run the verification pass**

Invoke `verification-before-completion` with the exact command results from Task 6. It must distinguish:

- Passed checks.
- Skipped live operations.
- The known Orval build blocker, if still present.
- Any environmental failure.

- [ ] **Step 2: Run the independent code-review pass**

Invoke `requesting-code-review` after verification. Review for:

- Hidden aliases or redirects.
- Duplicate prefixes.
- Proxy path rewriting.
- Refresh-loop regressions.
- SSE credentials/query loss.
- OAuth backend/frontend callback confusion.
- Upload/download redirect risks.
- Accidental `/blog-media` migration.
- Unmocked Playwright network escape.
- Historical documentation changed as if it were current.

Resolve actionable findings and re-run the affected checks.

- [ ] **Step 3: Run final GitNexus change detection**

```text
detect_changes(repo="mavra-monitor-system", scope="compare", base_ref="main")
```

Expected: affected processes match API registration, frontend API consumption, SSE, OAuth callback generation, blog API consumption, and tests/docs. Investigate any crawler runtime, scheduler behavior, database schema, or unrelated config flow.

- [ ] **Step 4: Confirm atomic deployment prerequisites**

Do not deploy unless all are true:

- Backend and both frontends are built from the same revision.
- Production proxy preserves `/api/v1`.
- WeChat production callback and platform whitelist are updated.
- Blog frontend `BLOG_API_BASE_URL` is updated.
- Mixed old/new rolling instances cannot serve one another.
- Rollback artifacts for backend and both frontends are available as one unit.

If atomic deployment is not guaranteed, stop and request a revised compatibility policy. Do not silently reintroduce aliases.

- [ ] **Step 5: Prepare the final implementation report**

Report:

- Exact commits.
- Backend, frontend, blog, and generation command results.
- Representative canonical paths verified.
- Representative legacy paths verified as `404`.
- Mock-only safety confirmation.
- Any known Orval blocker left intentionally unresolved.
- Deployment configuration actions that remain external to the repository.

## Rollback Plan

Rollback must restore backend and all clients to the previous revision together.

1. Revert the release as one unit; do not roll back only the backend or only one frontend.
2. Restore the previous proxy behavior only with the matching previous application revision.
3. Restore the previous WeChat callback whitelist if the old revision requires it.
4. Watch backend `404` rates and OAuth callback failures during rollback.
5. Do not use an emergency redirect as a substitute for a coherent rollback.

## Completion Criteria

- Every business router is registered once under `/api/v1`.
- Representative legacy and `/v1` routes return `404` without redirects.
- Main frontend feature modules use resource-relative paths.
- Axios and SSE share one canonical API base.
- Vite preserves `/api/v1` unchanged.
- Backend OAuth callback is canonical; frontend callback page is unchanged.
- Blog frontend defaults to `/api/v1`.
- OpenAPI and generated Orval output contain no duplicate aliases.
- Root infrastructure and `/blog-media/*` remain available.
- Backend, unit, mock-only E2E, and blog checks have evidence.
- Any known Orval build failure is reported without scope expansion.
- GitNexus verification and independent code review are complete.
- No real crawl, profile, matching, or Home Assistant operation was triggered.
