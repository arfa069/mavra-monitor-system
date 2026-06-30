# Orval API Contract Integration Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make FastAPI OpenAPI the authoritative API contract, generate deterministic Axios-based Orval React Query clients that compile, and migrate ordinary JSON frontend requests to generated code without forcing SSE, downloads, redirects, or public assets through the generated client.

**Architecture:** FastAPI assigns stable operation IDs from the first router tag plus the route function name and exports a deterministic full OpenAPI document. Orval filters that document to canonical `/api/v1` JSON operations, generates Axios React Query code through the existing shared Axios client, and rejects any generated non-canonical URL. Frontend adoption proceeds domain by domain while SSE, profile backup download, OAuth redirects, and public media stay behind explicit hand-written transport adapters.

**Tech Stack:** FastAPI, Pydantic, OpenAPI 3.1, pytest, Orval 8, Axios, React Query, React, TypeScript, Vitest, MSW, Playwright, GitHub Actions, GitNexus.

---

## Implementation Status

Implemented and verified on 2026-06-14. The final result is recorded in
`docs/orval_api_contract_integration_report.md`; the follow-up cleanup commit
kept only the profile backup blob export as a hand-written Axios transport in
`frontend/src/features/jobs/api/profileBackupExport.ts` and moved profile backup
import to the generated Orval client.

## Execution Boundaries

- Execute this plan from a dedicated worktree.
- Before changing a function, class, or method, run GitNexus upstream impact analysis for that symbol.
- Warn before editing when GitNexus reports `HIGH` or `CRITICAL` risk.
- Run GitNexus `detect_changes` before every commit.
- Never edit files under `frontend/src/shared/api/generated/` manually.
- Do not run `scripts/start_server.ps1`; it starts a worker that can claim persisted tasks.
- Do not run real product or job crawls.
- Do not open, test, copy, import, export, or log in to a real crawl profile during automated verification.
- Do not trigger job matching analysis against the real backend.
- Do not test Home Assistant configuration or entity control against a real server.
- Browser tests remain mock-only and must fail closed on unregistered API calls.
- Keep `/health`, `/health/detailed`, `/docs`, `/redoc`, `/openapi.json`, and `/blog-media/*` outside the generated business client.
- Keep EventSource/SSE, OAuth redirects, and binary profile export as dedicated transport adapters.
- Backend route and schema changes must be followed by:

```powershell
python scripts/export_openapi.py
Set-Location frontend
npm run api:generate
Set-Location ..
```

## Original Baseline Before Implementation

This section records the pre-implementation state from 2026-06-14 and is kept
for historical comparison with the final remediation report.

- `frontend/openapi.json` contained 92 paths, 122 operations, and 101 component schemas.
- All 213 declared response media entries were `application/json`.
- 33 successful responses exported an empty schema.
- The generated directory contained stale `ApiV1`, `V1`, and unprefixed model variants because Orval cleanup was disabled.
- Orval emitted Fetch-style `RequestInit` code while `customInstance` accepted `AxiosRequestConfig`.
- `npm run build` failed with generated-client TypeScript errors.
- No application code imported `frontend/src/shared/api/generated/`.
- Application code contained approximately 110 direct `api.get/post/put/patch/delete` calls.
- The shared Axios client already owns `baseURL = "/api/v1"`.
- Generated OpenAPI paths also start with `/api/v1`, so the mutator must remove exactly one canonical prefix before handing a URL to Axios.

## File Map

### Contract foundation

- Create: `backend/app/core/openapi.py`
- Create: `backend/app/schemas/runtime_api.py`
- Create: `backend/app/schemas/scheduling.py`
- Create: `backend/tests/test_openapi_contract.py`
- Modify: `backend/app/main.py`
- Modify: affected domain routers under `backend/app/domains/`
- Modify: `scripts/export_openapi.py`

### Generator foundation

- Create: `frontend/orval.input.mjs`
- Create: `frontend/tests/unit/shared/orval-input.test.ts`
- Create: `frontend/tests/unit/shared/orval-mutator.test.ts`
- Create: `frontend/tests/unit/shared/generated-api-contract.test.ts`
- Modify: `frontend/orval.config.ts`
- Modify: `frontend/src/shared/api/mutator.ts`
- Modify: `frontend/package.json`
- Modify: `.gitattributes`
- Regenerate: `frontend/openapi.json`
- Regenerate: `frontend/src/shared/api/generated/`

### Consumer migration

- Modify or delete feature API facades under `frontend/src/features/*/api/`
- Modify feature hooks and React consumers under `frontend/src/features/`
- Modify manual feature types only when a generated schema is contract-equivalent
- Preserve dedicated adapters for SSE and profile backup export
- Modify MSW and Playwright mocks under `frontend/tests/`

### Drift prevention

- Create: `scripts/check_api_contract.py`
- Modify: `.github/workflows/ci.yml`
- Modify: `AGENTS.md`
- Modify: relevant living architecture documentation after implementation

## Special Transport Policy

The full OpenAPI document must describe these operations correctly, but Orval must exclude them from the ordinary React Query client:

| Path                                          | Transport owner          | Reason                                    |
| --------------------------------------------- | ------------------------ | ----------------------------------------- |
| `/api/v1/events/stream`                       | EventSource adapter      | SSE connection lifecycle                  |
| `/api/v1/dashboard/events`                    | EventSource adapter      | SSE connection lifecycle                  |
| `/api/v1/smart-home/entities/stream`          | EventSource adapter      | SSE connection lifecycle                  |
| `/api/v1/crawl-profiles/{profile_key}/export` | Axios blob adapter       | Binary response and filename header       |
| `/api/v1/auth/wechat/callback`                | Browser redirect         | `302` response and auth cookies           |
| `/blog-media/{file_name}`                     | Browser/public asset URL | Public file delivery outside business API |
| `/health`                                     | Infrastructure probe     | Root infrastructure path                  |
| `/health/detailed`                            | Infrastructure probe     | Root infrastructure path                  |
| `/api/v1`                                     | Service information      | Not a feature API operation               |

---

### Task 1: Add OpenAPI Contract Regression Tests

**Files:**

- Create: `backend/tests/test_openapi_contract.py`
- Read: `backend/tests/test_api_v1_routes.py`

- [ ] **Step 1: Write the stable operation ID test**

Create helpers that inspect the generated document:

```python
from fastapi.routing import APIRoute

from app.main import API_PREFIX, app


HTTP_METHODS = {"get", "post", "put", "patch", "delete"}


def _operation(path: str, method: str) -> dict:
    return app.openapi()["paths"][path][method]


def _expected_operation_id(route: APIRoute) -> str:
    tag = str((route.tags or ["default"])[0]).replace("-", "_")
    return f"{tag}_{route.name}"


def test_operation_ids_are_stable_and_unique():
    routes = [
        route
        for route in app.routes
        if isinstance(route, APIRoute)
    ]
    expected = [_expected_operation_id(route) for route in routes]

    assert len(expected) == len(set(expected))
    for route in routes:
        method = next(iter(route.methods)).lower()
        assert _operation(route.path, method)["operationId"] == _expected_operation_id(
            route
        )
```

- [ ] **Step 2: Write canonical path and special media tests**

Add exact assertions:

```python
def test_business_openapi_paths_use_only_the_canonical_prefix():
    paths = set(app.openapi()["paths"])
    business_paths = {
        path
        for path in paths
        if path not in {"/health", "/health/detailed", "/blog-media/{file_name}"}
    }

    assert all(path == API_PREFIX or path.startswith(f"{API_PREFIX}/") for path in business_paths)
    assert not any(path.startswith("/v1/") for path in paths)


def test_special_response_media_types_are_declared():
    schema = app.openapi()

    for path in (
        "/api/v1/events/stream",
        "/api/v1/dashboard/events",
        "/api/v1/smart-home/entities/stream",
    ):
        content = schema["paths"][path]["get"]["responses"]["200"]["content"]
        assert set(content) == {"text/event-stream"}

    export_content = schema["paths"][
        "/api/v1/crawl-profiles/{profile_key}/export"
    ]["post"]["responses"]["200"]["content"]
    assert set(export_content) == {"application/octet-stream"}

    callback_responses = schema["paths"]["/api/v1/auth/wechat/callback"]["get"][
        "responses"
    ]
    assert "302" in callback_responses
```

- [ ] **Step 3: Write the typed JSON success-response test**

Use an explicit special-response allowlist and require every other successful JSON response to have a non-empty schema:

```python
SPECIAL_OPERATIONS = {
    ("get", "/api/v1/events/stream"),
    ("get", "/api/v1/dashboard/events"),
    ("get", "/api/v1/smart-home/entities/stream"),
    ("post", "/api/v1/crawl-profiles/{profile_key}/export"),
    ("get", "/api/v1/auth/wechat/callback"),
    ("get", "/blog-media/{file_name}"),
}


def test_json_success_responses_have_explicit_schemas():
    failures: list[str] = []

    for path, path_item in app.openapi()["paths"].items():
        for method, operation in path_item.items():
            if method not in HTTP_METHODS or (method, path) in SPECIAL_OPERATIONS:
                continue
            for status_code, response in operation.get("responses", {}).items():
                if not str(status_code).startswith("2"):
                    continue
                content = response.get("content", {})
                if not content:
                    continue
                schema = content.get("application/json", {}).get("schema")
                if schema == {} or schema is None:
                    failures.append(
                        f"{method.upper()} {path} {status_code} "
                        f"{operation['operationId']}"
                    )

    assert failures == []
```

- [ ] **Step 4: Run the focused tests and record the expected failures**

Run:

```powershell
Set-Location backend
pytest tests/test_openapi_contract.py -q
Set-Location ..
```

Expected before implementation:

- Operation ID assertions fail because IDs include route paths.
- SSE and binary media assertions fail because they are exported as JSON.
- The typed JSON test reports the current untyped success operations.

- [ ] **Step 5: Run GitNexus impact checks before the next task**

Run upstream impact analysis for:

```text
app
stream_events
stream_dashboard_events
stream_entities
export_profile_backup
wechat_callback
```

Do not start Task 2 if a `HIGH` or `CRITICAL` result has not been reported.

---

### Task 2: Stabilize Operation IDs and Deterministic Export

**Files:**

- Create: `backend/app/core/openapi.py`
- Modify: `backend/app/main.py`
- Modify: `scripts/export_openapi.py`
- Test: `backend/tests/test_openapi_contract.py`

- [ ] **Step 1: Implement the operation ID generator**

Create `backend/app/core/openapi.py`:

```python
"""OpenAPI naming helpers."""

import re

from fastapi.routing import APIRoute


def _operation_token(value: str) -> str:
    token = re.sub(r"[^0-9A-Za-z_]+", "_", value).strip("_").lower()
    return token or "default"


def generate_operation_id(route: APIRoute) -> str:
    """Return a stable ID independent from the mounted URL prefix."""
    tag = _operation_token(str((route.tags or ["default"])[0]))
    return f"{tag}_{_operation_token(route.name)}"
```

- [ ] **Step 2: Wire the generator into FastAPI**

Modify `backend/app/main.py`:

```python
from app.core.openapi import generate_operation_id
```

Pass it to the app constructor:

```python
app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
    lifespan=lifespan,
    generate_unique_id_function=generate_operation_id,
)
```

- [ ] **Step 3: Export the app's actual schema deterministically**

Replace direct `get_openapi(...)` use in `scripts/export_openapi.py` with:

```python
def export_openapi() -> None:
    openapi_schema = app.openapi()
    frontend_path = os.path.join(project_root, "frontend", "openapi.json")

    with open(frontend_path, "w", encoding="utf-8", newline="\n") as file:
        json.dump(
            openapi_schema,
            file,
            indent=2,
            ensure_ascii=False,
            sort_keys=True,
        )
        file.write("\n")

    print(f"Successfully exported OpenAPI schema to {frontend_path}")
```

Remove the unused `get_openapi` import and avoid emoji in script output so CI logs remain encoding-safe.

- [ ] **Step 4: Run the naming tests**

Run:

```powershell
Set-Location backend
pytest tests/test_openapi_contract.py::test_operation_ids_are_stable_and_unique -q
Set-Location ..
```

Expected: pass with 122 unique operation IDs.

- [ ] **Step 5: Export twice and prove byte stability**

Run:

```powershell
python scripts/export_openapi.py
$first = (Get-FileHash frontend/openapi.json -Algorithm SHA256).Hash
python scripts/export_openapi.py
$second = (Get-FileHash frontend/openapi.json -Algorithm SHA256).Hash
if ($first -ne $second) { throw "OpenAPI export is not deterministic" }
```

Expected: both hashes are identical.

- [ ] **Step 6: Review and commit**

Run:

```text
detect_changes(repo="mavra-monitor-system", scope="unstaged")
```

Then:

```powershell
git add backend/app/core/openapi.py backend/app/main.py scripts/export_openapi.py backend/tests/test_openapi_contract.py
git diff --cached --check
git commit -m "test(api): stabilize openapi operation ids"
```

---

### Task 3: Correct JSON, SSE, Binary, Redirect, and File Contracts

**Files:**

- Create: `backend/app/schemas/runtime_api.py`
- Create: `backend/app/schemas/scheduling.py`
- Modify: `backend/app/schemas/admin.py`
- Modify: `backend/app/schemas/product.py`
- Modify: `backend/app/schemas/job_match.py`
- Modify: `backend/app/main.py`
- Modify: `backend/app/domains/products/router.py`
- Modify: `backend/app/domains/alerts/router.py`
- Modify: `backend/app/domains/jobs/router.py`
- Modify: `backend/app/domains/admin/router.py`
- Modify: `backend/app/domains/scheduling/router.py`
- Modify: `backend/app/domains/crawling/router.py`
- Modify: `backend/app/domains/crawling/profile_router.py`
- Modify: `backend/app/domains/events/router.py`
- Modify: `backend/app/domains/dashboard/router.py`
- Modify: `backend/app/domains/smart_home/router.py`
- Modify: `backend/app/domains/auth/wechat_router.py`
- Modify: `backend/app/domains/blog/router.py`
- Test: `backend/tests/test_openapi_contract.py`
- Test: existing domain API tests

- [ ] **Step 1: Add shared runtime response schemas**

Create `backend/app/schemas/runtime_api.py` with the exact current task payload:

```python
"""Schemas shared by durable task APIs."""

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel


class MessageResponse(BaseModel):
    message: str


class TaskQueuedResponse(BaseModel):
    status: Literal["pending", "skipped", "error"]
    task_id: str | None = None
    message: str | None = None
    reason: str | None = None


class TaskProgressResponse(BaseModel):
    task_id: str
    status: Literal["pending", "running", "completed", "failed", "error"]
    total: int = 0
    success: int = 0
    errors: int = 0
    reason: str | None = None
    worker_id: str | None = None
    heartbeat_at: datetime | None = None
    lease_until: datetime | None = None
    started_at: datetime | None = None
    finished_at: datetime | None = None
    details: list[Any] | None = None


class TaskErrorResponse(BaseModel):
    status: Literal["error"]
    reason: str


class MatchTaskQueuedResponse(BaseModel):
    status: Literal["pending", "completed"]
    task_id: str | None
    total: int
    reason: str | None = None


class CrawlerWorkerResponse(BaseModel):
    worker_id: str
    kind: str
    platform: str | None
    hostname: str
    pid: int
    status: str
    started_at: datetime | None
    last_heartbeat_at: datetime | None
    stopped_at: datetime | None


class CleanupResultResponse(BaseModel):
    status: Literal["completed"]
    deleted_crawl_logs: int
    deleted_price_history: int
    cutoff_date: datetime
    retention_days: int


class ServiceInfoResponse(BaseModel):
    name: str
    status: Literal["ok"]
    docs: str
    prefixes: list[str]


class HealthResponse(BaseModel):
    status: Literal["starting", "healthy", "unhealthy"]
```

- [ ] **Step 2: Add scheduling response schemas**

Create `backend/app/schemas/scheduling.py`:

```python
"""Scheduler status response schemas."""

from pydantic import BaseModel, Field


class ScheduleInfo(BaseModel):
    cron_expression: str | None = None
    next_run_at: str | None = None


class JobConfigScheduleInfo(ScheduleInfo):
    config_id: int


class ProductCronSchedulesResponse(BaseModel):
    platforms: dict[str, ScheduleInfo] = Field(default_factory=dict)


class JobConfigSchedulesResponse(BaseModel):
    configs: list[JobConfigScheduleInfo] = Field(default_factory=list)


class SchedulerJobsResponse(BaseModel):
    product_platforms: dict[str, ScheduleInfo] = Field(default_factory=dict)
    job_configs: dict[str, ScheduleInfo] = Field(default_factory=dict)


class SchedulerStatusResponse(BaseModel):
    scheduler: str
    timezone: str | None = None
    jobs: SchedulerJobsResponse | None = None
```

- [ ] **Step 3: Add small domain response schemas**

Add:

```python
class ResourcePermissionGrantResponse(BaseModel):
    granted: int
```

to `backend/app/schemas/admin.py`.

Add:

```python
class RolePermissionUpdateResponse(BaseModel):
    role: str
    permissions: list[str]
```

to `backend/app/schemas/admin.py`.

Use `MessageResponse` for JSON delete responses that already return a message. Do not change those endpoints to `204` in this task because that would change established frontend behavior.

- [ ] **Step 4: Attach response models to current JSON operations**

Add exact `response_model` declarations:

```python
@router.post("/crawl-now", response_model=TaskQueuedResponse)
@router.get("/status/{task_id}", response_model=TaskProgressResponse)
@router.get("/result/{task_id}", response_model=TaskProgressResponse)
@router.get("/workers", response_model=list[CrawlerWorkerResponse])
@router.post("/cleanup", response_model=CleanupResultResponse)
```

Apply the same `TaskQueuedResponse` and `TaskProgressResponse` models to job crawl trigger/status/result operations.

Apply `MatchTaskQueuedResponse` to both job match enqueue operations and `TaskProgressResponse` to the job match task-status operation.

Apply:

```python
response_model=ProductCronSchedulesResponse
response_model=JobConfigSchedulesResponse
response_model=SchedulerStatusResponse
response_model=ResourcePermissionGrantResponse
response_model=RolePermissionUpdateResponse
response_model=MessageResponse
```

to their corresponding current JSON-returning routes.

Keep runtime status codes and response bodies unchanged. Where a route currently
returns `JSONResponse`, declare each existing non-200 status explicitly.

Use `TaskErrorResponse` for task-not-found `404` payloads. Use
`TaskProgressResponse` for `202` and failed-task payloads that include a
`task_id`.

In `backend/app/main.py`, preserve all three function bodies and change only
their decorators:

```python
@app.get(API_PREFIX, response_model=ServiceInfoResponse)

@app.get(
    "/health",
    response_model=HealthResponse,
    responses={503: {"model": HealthResponse}},
)

@app.get("/health/detailed", response_model=HealthResponse)
```

- [ ] **Step 5: Declare special response classes and media**

For each SSE route, declare:

```python
@router.get(
    "/stream",
    response_class=StreamingResponse,
    responses={
        200: {
            "description": "Server-sent event stream",
            "content": {"text/event-stream": {"schema": {"type": "string"}}},
        }
    },
)
```

Use the route's actual path for dashboard and smart-home decorators.

For profile export:

```python
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
```

For the WeChat callback, set `response_class=RedirectResponse` and declare `302`.

For blog media delivery, set `response_class=FileResponse`. Do not move the route under `/api/v1`.

- [ ] **Step 6: Run contract and domain tests**

Run:

```powershell
Set-Location backend
pytest tests/test_openapi_contract.py tests/test_api_v1_routes.py tests/test_api.py tests/test_jobs_api.py tests/test_crawl_profile_api.py tests/test_auth_api.py -q
Set-Location ..
```

Expected:

- Contract tests pass.
- Existing JSON payload assertions remain unchanged.
- No test opens a browser profile or starts a crawl.

- [ ] **Step 7: Review and commit**

Run GitNexus `detect_changes`, verify only contract and schema flows are affected, then:

```powershell
git add backend/app backend/tests/test_openapi_contract.py
git diff --cached --check
git commit -m "fix(api): publish typed openapi responses"
```

---

### Task 4: Make Orval Axios-Based, Clean, and Canonical

**Files:**

- Create: `frontend/orval.input.mjs`
- Create: `frontend/tests/unit/shared/orval-input.test.ts`
- Create: `frontend/tests/unit/shared/orval-mutator.test.ts`
- Modify: `frontend/orval.config.ts`
- Modify: `frontend/src/shared/api/mutator.ts`
- Modify: `.gitattributes`

- [ ] **Step 1: Write the Orval input-filter test**

Create `frontend/tests/unit/shared/orval-input.test.ts`:

```typescript
import { describe, expect, it } from "vitest";
import filterOrvalInput, {
  ORVAL_EXCLUDED_PATHS,
} from "../../../orval.input.mjs";

describe("Orval input filter", () => {
  it("keeps canonical JSON APIs and removes special transports", () => {
    const spec = {
      paths: {
        "/api/v1/products": { get: {} },
        "/api/v1/events/stream": { get: {} },
        "/health": { get: {} },
      },
      components: { schemas: { ProductResponse: { type: "object" } } },
    };

    const filtered = filterOrvalInput(spec);

    expect(filtered.paths).toEqual({
      "/api/v1/products": { get: {} },
    });
    expect(filtered.components).toBe(spec.components);
    expect(ORVAL_EXCLUDED_PATHS).toContain("/health");
  });
});
```

- [ ] **Step 2: Implement the input filter**

Create `frontend/orval.input.mjs`:

```javascript
export const ORVAL_EXCLUDED_PATHS = [
  "/api/v1",
  "/api/v1/auth/wechat/callback",
  "/api/v1/crawl-profiles/{profile_key}/export",
  "/api/v1/dashboard/events",
  "/api/v1/events/stream",
  "/api/v1/smart-home/entities/stream",
  "/blog-media/{file_name}",
  "/health",
  "/health/detailed",
];

const excluded = new Set(ORVAL_EXCLUDED_PATHS);

export default function filterOrvalInput(spec) {
  return {
    ...spec,
    paths: Object.fromEntries(
      Object.entries(spec.paths ?? {}).filter(([path]) => !excluded.has(path)),
    ),
  };
}
```

- [ ] **Step 3: Write canonical mutator tests**

Create `frontend/tests/unit/shared/orval-mutator.test.ts`:

```typescript
import { beforeEach, describe, expect, it, vi } from "vitest";
import api from "@/shared/api/client";
import { customInstance, normalizeGeneratedApiUrl } from "@/shared/api/mutator";

vi.mock("@/shared/api/client", () => ({
  default: vi.fn(),
}));

describe("Orval Axios mutator", () => {
  beforeEach(() => {
    vi.mocked(api).mockReset();
  });

  it("removes exactly one canonical prefix", () => {
    expect(normalizeGeneratedApiUrl("/api/v1/products")).toBe("/products");
    expect(normalizeGeneratedApiUrl("/api/v1")).toBe("/");
  });

  it("preserves query strings", () => {
    expect(normalizeGeneratedApiUrl("/api/v1/products?page=2")).toBe(
      "/products?page=2",
    );
  });

  it("rejects infrastructure and double-prefixed URLs", () => {
    expect(() => normalizeGeneratedApiUrl("/health")).toThrow(
      "non-canonical URL",
    );
    expect(() => normalizeGeneratedApiUrl("/api/v1/api/v1/products")).toThrow(
      "double API prefix",
    );
  });

  it("merges generated and caller headers before using shared Axios", async () => {
    vi.mocked(api).mockResolvedValue({ data: { id: 1 } } as never);

    await customInstance(
      {
        url: "/api/v1/products",
        method: "POST",
        headers: { "Content-Type": "application/json" },
        data: { title: "A" },
      },
      { headers: { "X-Test": "yes" } },
    );

    expect(api).toHaveBeenCalledWith(
      expect.objectContaining({
        url: "/products",
        headers: expect.objectContaining({
          "Content-Type": "application/json",
          "X-Test": "yes",
        }),
      }),
    );
  });
});
```

- [ ] **Step 4: Implement strict URL normalization**

Modify `frontend/src/shared/api/mutator.ts`:

```typescript
import type { AxiosError, AxiosRequestConfig } from "axios";
import api from "./client";

const CANONICAL_API_PREFIX = "/api/v1";

export function normalizeGeneratedApiUrl(url: string | undefined): string {
  if (!url) {
    throw new Error("Orval generated a request without a URL");
  }
  if (url.includes(`${CANONICAL_API_PREFIX}${CANONICAL_API_PREFIX}`)) {
    throw new Error(`Orval generated a double API prefix: ${url}`);
  }
  if (url === CANONICAL_API_PREFIX) {
    return "/";
  }
  if (!url.startsWith(`${CANONICAL_API_PREFIX}/`)) {
    throw new Error(`Orval generated a non-canonical URL: ${url}`);
  }
  return url.slice(CANONICAL_API_PREFIX.length);
}

export const customInstance = <T>(
  config: AxiosRequestConfig,
  options?: AxiosRequestConfig,
): Promise<T> => {
  const mergedConfig: AxiosRequestConfig = {
    ...config,
    ...options,
    headers: {
      ...config.headers,
      ...options?.headers,
    },
    url: normalizeGeneratedApiUrl(options?.url ?? config.url),
  };

  return api(mergedConfig).then(({ data }) => data);
};

export type ErrorType<Error> = AxiosError<Error>;
export type BodyType<BodyData> = BodyData;
```

- [ ] **Step 5: Configure Orval**

Modify `frontend/orval.config.ts`:

```typescript
import { defineConfig } from "orval";

export default defineConfig({
  api: {
    input: {
      target: "./openapi.json",
      override: {
        transformer: "./orval.input.mjs",
      },
    },
    output: {
      mode: "tags-split",
      target: "src/shared/api/generated/endpoints.ts",
      schemas: "src/shared/api/generated/models",
      client: "react-query",
      httpClient: "axios",
      clean: true,
      override: {
        mutator: {
          path: "src/shared/api/mutator.ts",
          name: "customInstance",
        },
      },
    },
    hooks: {
      afterAllFilesWrite: "eslint --fix src/shared/api/generated",
    },
  },
});
```

- [ ] **Step 6: Pin generated line endings**

Add to `.gitattributes`:

```gitattributes
frontend/openapi.json text eol=lf
frontend/src/shared/api/generated/** text eol=lf
```

- [ ] **Step 7: Run unit tests**

Run:

```powershell
Set-Location frontend
npm run test:unit -- tests/unit/shared/orval-input.test.ts tests/unit/shared/orval-mutator.test.ts tests/unit/shared/api-client.test.ts
Set-Location ..
```

Expected: pass.

- [ ] **Step 8: Review and commit**

Run GitNexus impact analysis for `customInstance`, then `detect_changes`, then:

```powershell
git add .gitattributes frontend/orval.config.ts frontend/orval.input.mjs frontend/src/shared/api/mutator.ts frontend/tests/unit/shared
git diff --cached --check
git commit -m "fix(orval): generate through canonical axios client"
```

---

### Task 5: Regenerate a Clean Client and Restore the Frontend Build

**Files:**

- Regenerate: `frontend/openapi.json`
- Regenerate: `frontend/src/shared/api/generated/`
- Create: `frontend/tests/unit/shared/generated-api-contract.test.ts`
- Modify: `frontend/package.json`

- [ ] **Step 1: Export and regenerate**

Run:

```powershell
python scripts/export_openapi.py
Set-Location frontend
npm run api:generate
Set-Location ..
```

Expected:

- Generated functions accept Axios request options.
- Generated files contain no `RequestInit`.
- Stale path-family models are deleted.
- Generated operation names derive from stable IDs such as `products_list_products`.

- [ ] **Step 2: Add a generated-tree regression test**

Create `frontend/tests/unit/shared/generated-api-contract.test.ts`:

```typescript
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const generatedRoot = join(process.cwd(), "src", "shared", "api", "generated");

function generatedFiles(directory: string): string[] {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? generatedFiles(path) : [path];
  });
}

describe("generated API tree", () => {
  it("contains Axios output without stale path-family artifacts", () => {
    const files = generatedFiles(generatedRoot);
    const source = files
      .filter((file) => file.endsWith(".ts"))
      .map((file) => readFileSync(file, "utf8"))
      .join("\n");
    const names = files.map((file) => file.split(/[\\/]/).at(-1) ?? "");

    expect(source).not.toContain("RequestInit");
    expect(source).not.toMatch(/(?:return `|["'])\/v1\//);
    expect(source).not.toContain("return `/health");
    expect(names.some((name) => name.includes("ApiV1"))).toBe(false);
    expect(names.some((name) => /^.*V1.*Params\.ts$/.test(name))).toBe(false);
  });
});
```

- [ ] **Step 3: Add a generation check script**

Add to `frontend/package.json`:

```json
"api:check-generated": "vitest run tests/unit/shared/generated-api-contract.test.ts"
```

- [ ] **Step 4: Run build and focused tests**

Run:

```powershell
Set-Location frontend
npm run api:check-generated
npm run lint
npm run build
Set-Location ..
```

Expected: all commands pass. Do not begin consumer migration while the build is red.

- [ ] **Step 5: Prove regeneration is idempotent**

Run:

```powershell
python scripts/export_openapi.py
Set-Location frontend
npm run api:generate
Set-Location ..
git diff --exit-code -- frontend/openapi.json frontend/src/shared/api/generated
```

Expected: no diff.

- [ ] **Step 6: Review and commit**

Run GitNexus `detect_changes`, then:

```powershell
git add frontend/openapi.json frontend/src/shared/api/generated frontend/tests/unit/shared/generated-api-contract.test.ts frontend/package.json
git diff --cached --check
git commit -m "build(api): regenerate deterministic orval client"
```

---

### Task 6: Add the API Contract Drift Gate to CI

**Files:**

- Create: `scripts/check_api_contract.py`
- Modify: `.github/workflows/ci.yml`
- Modify: `frontend/package.json`

- [ ] **Step 1: Create a cross-platform contract checker**

Create `scripts/check_api_contract.py`:

```python
"""Regenerate API artifacts and fail when tracked output changes."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
FRONTEND_ROOT = PROJECT_ROOT / "frontend"


def run(command: list[str], *, cwd: Path) -> None:
    subprocess.run(command, cwd=cwd, check=True)


def main() -> None:
    npm = "npm.cmd" if os.name == "nt" else "npm"

    run(["python", "scripts/export_openapi.py"], cwd=PROJECT_ROOT)
    run([npm, "run", "api:generate"], cwd=FRONTEND_ROOT)
    run(
        [
            "git",
            "diff",
            "--exit-code",
            "--",
            "frontend/openapi.json",
            "frontend/src/shared/api/generated",
        ],
        cwd=PROJECT_ROOT,
    )


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Add a package convenience command**

Add:

```json
"api:check": "python ../scripts/check_api_contract.py"
```

to `frontend/package.json`.

- [ ] **Step 3: Add a dedicated CI job**

Add an `api-contract` job to `.github/workflows/ci.yml`:

```yaml
api-contract:
  name: API contract
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: "3.11"

    - name: Install Poetry
      uses: snok/install-poetry@v1

    - name: Install backend dependencies
      run: poetry install --with dev
      working-directory: backend

    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: "20"
        cache: "npm"
        cache-dependency-path: frontend/package-lock.json

    - name: Install frontend dependencies
      run: npm ci
      working-directory: frontend

    - name: Verify generated API artifacts
      run: poetry run python ../scripts/check_api_contract.py
      working-directory: backend

    - name: Build generated frontend client
      run: npm run build
      working-directory: frontend
```

- [ ] **Step 4: Run the checker locally from a clean generated state**

Run:

```powershell
python scripts/check_api_contract.py
```

Expected: exit code `0` and no generated diff.

- [ ] **Step 5: Review and commit**

Run GitNexus `detect_changes`, then:

```powershell
git add scripts/check_api_contract.py .github/workflows/ci.yml frontend/package.json
git diff --cached --check
git commit -m "ci(api): reject stale generated contracts"
```

---

### Task 7: Migrate Config, Scheduler, Dashboard, Events, and Alerts

**Files:**

- Modify or delete: `frontend/src/features/settings/api/config.ts`
- Modify: `frontend/src/features/settings/SettingsPage.tsx`
- Modify: `frontend/src/features/settings/types.ts`
- Modify: `frontend/src/features/dashboard/DashboardPage.tsx`
- Modify: `frontend/src/features/dashboard/hooks/useDashboardTrends.ts`
- Modify: `frontend/src/features/dashboard/hooks/useRecentAlerts.ts`
- Modify: `frontend/src/features/events/api/events.ts`
- Modify: `frontend/src/features/events/EventCenterPage.tsx`
- Modify or delete: `frontend/src/features/alerts/api/alerts.ts`
- Modify: `frontend/src/features/alerts/hooks/useAlerts.ts`
- Test: existing settings, dashboard, events, and alert tests

- [ ] **Step 1: Add failing tests that assert generated functions are used**

Mock these generated modules in the existing unit tests:

```text
@/shared/api/generated/config/config
@/shared/api/generated/scheduler/scheduler
@/shared/api/generated/dashboard/dashboard
@/shared/api/generated/events/events
@/shared/api/generated/alerts/alerts
```

Assert query parameters, mutation bodies, enabled flags, and invalidation behavior. Keep SSE tests pointed at the existing EventSource adapters.

- [ ] **Step 2: Replace ordinary JSON calls with generated hooks**

Use generated operations based on these stable IDs:

```text
config_get_config
config_update_config_partial
scheduler_get_scheduler_status
dashboard_get_dashboard_kpi
dashboard_get_trend_data
dashboard_get_recent_alerts
events_list_events
alerts_list_alerts
alerts_get_alert
alerts_create_alert
alerts_update_alert
alerts_delete_alert
```

Import generated React Query hooks or generated query-option builders into feature hooks. Preserve feature-specific query keys only when they represent UI state not already encoded in generated parameters.

- [ ] **Step 3: Keep SSE adapters hand-written**

Do not replace:

```text
frontend/src/features/dashboard/hooks/useDashboardSSE.ts
frontend/src/features/events/api/events.ts buildStreamUrl
```

Only remove ordinary JSON Axios use from `events.ts`; keep its canonical `apiUrl(...)` SSE builder.

- [ ] **Step 4: Replace equivalent manual types**

Re-export generated schemas from feature `types.ts` where field names and optionality match exactly. Keep UI-only types such as chart view models and form state local.

- [ ] **Step 5: Run focused verification**

Run:

```powershell
Set-Location frontend
npm run test:unit -- tests/unit/settings/settings-page.test.tsx tests/unit/dashboard/dashboard-sse.test.tsx tests/unit/events/events.test.tsx
npm run lint
npm run build
Set-Location ..
```

Expected: pass.

- [ ] **Step 6: Review and commit**

Run GitNexus impact analysis for every modified feature hook, then `detect_changes`, then:

```powershell
git add frontend/src/features/settings frontend/src/features/dashboard frontend/src/features/events frontend/src/features/alerts frontend/tests/unit
git diff --cached --check
git commit -m "refactor(api): adopt generated read-side hooks"
```

---

### Task 8: Migrate Products, Product Scheduling, and Product Crawl Polling

**Files:**

- Modify or delete: `frontend/src/features/products/api/products.ts`
- Modify or delete: `frontend/src/features/products/api/crawl.ts`
- Modify: `frontend/src/features/products/hooks/useProducts.ts`
- Modify: product pages and dialogs that consume these APIs
- Modify: `frontend/src/features/products/types.ts`
- Test: `frontend/tests/unit/products/product-form-modal.test.tsx`
- Test: mock-only product E2E coverage

- [ ] **Step 1: Add generated-client mocks to product tests**

Cover ordinary CRUD, batches, history, cron configuration, profile binding, and polling. For crawl triggers, mock the generated mutation and never allow a network call.

- [ ] **Step 2: Migrate product operations**

Use generated operations based on:

```text
products_list_products
products_get_product
products_create_product
products_update_product
products_delete_product
products_batch_create_products
products_batch_delete_products
products_batch_update_products
products_get_product_history
products_list_product_cron_configs
products_create_product_cron_config
products_update_product_cron_config
products_delete_product_cron_config
products_get_product_cron_schedules
products_list_product_profile_bindings
products_upsert_product_profile_binding
products_delete_product_profile_binding
```

- [ ] **Step 3: Migrate crawl trigger and polling without executing a crawl**

Use:

```text
products_crawl_crawl_now
products_crawl_get_crawl_status
products_crawl_get_crawl_result
products_crawl_get_crawl_logs
```

Preserve:

- Existing polling intervals.
- Poll stop conditions.
- Existing timeout behavior.
- Existing user notifications.
- Existing React Query invalidation after completion.

All tests must use Vitest/MSW or Playwright mocks. The E2E firewall must continue blocking `POST /api/v1/crawl/crawl-now`.

- [ ] **Step 4: Run focused verification**

Run:

```powershell
Set-Location frontend
npm run test:unit -- tests/unit/products/product-form-modal.test.tsx tests/unit/review-regressions.test.ts
npm run lint
npm run build
Set-Location ..
```

Expected: pass with no live crawl.

- [ ] **Step 5: Review and commit**

Run GitNexus impact analysis for `useProducts` and affected product hooks, then `detect_changes`, then:

```powershell
git add frontend/src/features/products frontend/tests
git diff --cached --check
git commit -m "refactor(products): adopt generated api hooks"
```

---

### Task 9: Migrate Admin, Blog, and Authentication JSON Operations

**Files:**

- Modify or delete: `frontend/src/features/admin/api/admin.ts`
- Modify: `frontend/src/features/admin/hooks/useAdmin.ts`
- Modify: admin pages
- Modify or delete: `frontend/src/features/blog/api/blog.ts`
- Modify: `frontend/src/features/blog/BlogAdminPage.tsx`
- Modify or delete: `frontend/src/features/auth/api/auth.ts`
- Modify: auth pages, profile page, WeChat panels, and auth context
- Modify: matching feature types only when generated schemas are equivalent
- Preserve: frontend WeChat callback page routing

- [ ] **Step 1: Extend unit tests with generated module mocks**

Cover:

- Admin users, audit logs, resource permissions, and role permissions.
- Blog post CRUD, category/tag reads, and multipart upload.
- Login, registration, logout, current user, profile update, password change, user config, WeChat QR, bind, and registration.

- [ ] **Step 2: Migrate admin operations**

Use stable operations:

```text
admin_list_users
admin_create_user
admin_update_user
admin_delete_user
admin_list_audit_logs
admin_list_resource_permissions
admin_grant_resource_permission
admin_revoke_resource_permission
admin_update_resource_permission
admin_get_role_permission_matrix
admin_update_role_permissions
```

- [ ] **Step 3: Migrate blog JSON and multipart operations**

Use:

```text
blog_list_admin_posts
blog_get_admin_post
blog_create_admin_post
blog_update_admin_post
blog_delete_admin_post
blog_upload_blog_media
blog_list_categories
blog_list_tags
```

Verify that upload still sends `multipart/form-data` and returned asset URLs remain `/blog-media/*`.

- [ ] **Step 4: Migrate auth and WeChat JSON operations**

Use:

```text
auth_login
auth_register
auth_logout
auth_get_me
auth_update_me
auth_change_password
config_update_config_partial
wechat_get_wechat_qr_url
wechat_bind_wechat_account
wechat_register_with_wechat
```

Keep the backend WeChat callback excluded from Orval. Keep the frontend page `/auth/wechat/callback` unchanged.

Delete the unused `authApi.updateConfig()` call to `/auth/me/config`; the
backend has no such route. If a current consumer is discovered during impact
analysis, migrate that consumer to `config_update_config_partial` and its
generated `UserConfigUpdate` schema.

Do not replace the shared Axios client's internal refresh request with a generated hook. The 401 interceptor must continue to call the isolated refresh Axios instance so refresh cannot recursively enter the interceptor.

- [ ] **Step 5: Run focused verification**

Run:

```powershell
Set-Location frontend
npm run test:unit -- tests/unit/admin/admin-users-page.test.tsx tests/unit/blog/blog-admin-page.test.tsx tests/unit/auth tests/unit/shared/auth-context.test.tsx tests/unit/shared/api-client.test.ts
npm run lint
npm run build
Set-Location ..
```

Expected: pass.

- [ ] **Step 6: Review and commit**

Run GitNexus impact analysis for auth context and affected feature hooks, then `detect_changes`, then:

```powershell
git add frontend/src/features/admin frontend/src/features/blog frontend/src/features/auth frontend/src/shared/contexts frontend/tests/unit
git diff --cached --check
git commit -m "refactor(api): adopt generated admin blog auth clients"
```

---

### Task 10: Migrate Smart Home and Jobs Last

**Files:**

- Modify ordinary JSON operations in `frontend/src/features/smart-home/`
- Modify ordinary JSON operations in `frontend/src/features/jobs/`
- Create: `frontend/src/features/jobs/api/profileBackupExport.ts`
- Preserve Smart Home SSE adapter
- Preserve profile export blob adapter
- Test: smart-home, jobs, schedule, and profile-management unit tests
- Test: mock-only jobs and smart-home E2E scenarios

- [ ] **Step 1: Add failing generated-module mocks**

Tests must cover:

- Smart Home config, entities, summary, and service payload construction.
- Job config CRUD and schedules.
- Job list and details.
- Resume and match-result CRUD/read flows.
- Crawl task polling.
- Crawl profile CRUD, rename, copy, stale release, login-session state, test result, and import.

Dangerous mutations remain blocked by the Playwright firewall.

- [ ] **Step 2: Migrate Smart Home ordinary JSON operations**

Use:

```text
smart_home_get_config
smart_home_update_config
smart_home_test_config
smart_home_list_entities
smart_home_get_summary
smart_home_call_service
```

Keep `buildStreamUrl()` and `useSmartHomeSSE.ts` hand-written.

Keep `encodeURIComponent(entityId)` behavior. Add a unit assertion for an entity ID such as `light.office/main` so it is encoded exactly once.

- [ ] **Step 3: Migrate job, resume, matching, and schedule operations**

Use stable operation IDs under:

```text
jobs_list_configs
jobs_get_config
jobs_create_config
jobs_update_config
jobs_delete_config
jobs_update_config_cron
jobs_list_jobs
jobs_get_job
jobs_list_resumes
jobs_create_resume
jobs_update_resume
jobs_delete_resume
jobs_list_match_results
jobs_trigger_match_analysis
jobs_trigger_match_analysis_async
jobs_get_match_analysis_task_status
jobs_get_job_config_schedules
jobs_crawl_now
jobs_crawl_single
jobs_get_job_crawl_status
jobs_get_job_crawl_result
jobs_get_job_crawl_logs
```

Preserve current polling, timeouts, completion behavior, and cache invalidation.

- [ ] **Step 4: Migrate crawl profile JSON and multipart import**

Use:

```text
crawl_profiles_get_runtime_capabilities
crawl_profiles_list_profiles
crawl_profiles_create_profile
crawl_profiles_update_profile
crawl_profiles_rename_profile
crawl_profiles_copy_profile
crawl_profiles_delete_profile
crawl_profiles_release_stale_profile
crawl_profiles_open_login_session
crawl_profiles_get_login_session
crawl_profiles_close_login_session
crawl_profiles_test_profile
crawl_profiles_import_profile_backup
```

Keep profile export in a dedicated adapter:

```typescript
export function exportProfileBackup(profileKey: string, password: string) {
  return api.post<Blob>(
    `/crawl-profiles/${encodeURIComponent(profileKey)}/export`,
    { password },
    { responseType: "blob" },
  );
}
```

Keep profile keys encoded exactly once in both generated calls and the export adapter.

- [ ] **Step 5: Run focused verification**

Run:

```powershell
Set-Location frontend
npm run test:unit -- tests/unit/smart-home tests/unit/jobs tests/unit/schedule
npm run lint
npm run build
Set-Location ..
```

Expected: pass without real profile, crawl, matching, or Home Assistant calls.

- [ ] **Step 6: Review and commit**

Run GitNexus impact analysis for modified Smart Home and jobs hooks, then `detect_changes`, then:

```powershell
git add frontend/src/features/smart-home frontend/src/features/jobs frontend/src/features/schedule frontend/tests
git diff --cached --check
git commit -m "refactor(api): adopt generated jobs and smart home clients"
```

---

### Task 11: Enforce the Manual Transport Allowlist

**Files:**

- Create: `scripts/check_frontend_api_usage.py`
- Modify: `frontend/package.json`
- Modify: `.github/workflows/ci.yml`
- Modify: remaining dedicated adapters

- [ ] **Step 1: Define the only allowed direct Axios files**

The final allowlist is:

```text
frontend/src/shared/api/client.ts
frontend/src/shared/api/mutator.ts
frontend/src/features/jobs/api/profileBackupExport.ts
```

SSE adapters use `EventSource`, not Axios, and therefore do not need an Axios allowlist entry.

- [ ] **Step 2: Create the usage checker**

Create `scripts/check_frontend_api_usage.py` to scan `frontend/src` for:

```regex
\bapi\.(get|post|put|patch|delete)\s*\(
```

Fail when a match appears outside the allowlist. Also fail when application code imports from `axios` outside `frontend/src/shared/api/` and the profile backup adapter.

- [ ] **Step 3: Add commands and CI execution**

Add:

```json
"api:check-usage": "python ../scripts/check_frontend_api_usage.py"
```

Run it in both the API contract CI job and the normal frontend job before build.

- [ ] **Step 4: Verify usage and generated imports**

Run:

```powershell
Set-Location frontend
npm run api:check-usage
rg -n "shared/api/generated" src
Set-Location ..
```

Expected:

- The usage checker passes.
- Generated imports exist across migrated domains.
- No ordinary feature API module calls Axios directly.

- [ ] **Step 5: Review and commit**

Run GitNexus `detect_changes`, then:

```powershell
git add scripts/check_frontend_api_usage.py frontend/package.json .github/workflows/ci.yml frontend/src
git diff --cached --check
git commit -m "ci(api): enforce generated client adoption"
```

---

### Task 12: Update Repository Guidance and Living Documentation

**Files:**

- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `doc/frontend-architecture.md`
- Modify: `doc/backend-architecture.md`
- Modify: API workflow documentation discovered by a scoped scan
- Preserve: dated historical plans

- [ ] **Step 1: Update the Orval workflow guidance**

Document:

```text
1. Change FastAPI routes and Pydantic schemas.
2. Run python scripts/export_openapi.py.
3. Run npm run api:generate in frontend.
4. Run python scripts/check_api_contract.py.
5. Use generated hooks for ordinary JSON operations.
6. Use dedicated adapters only for SSE, profile backup blob export,
   browser redirects, and public media.
7. Commit backend, openapi.json, and generated output together.
```

- [ ] **Step 2: Document the URL ownership rule**

State:

- FastAPI and OpenAPI expose canonical `/api/v1` paths.
- Generated URLs contain `/api/v1`.
- `customInstance` strips exactly one `/api/v1` before calling the shared Axios client.
- The shared Axios client remains the only owner of browser request `baseURL`.
- Non-canonical generated URLs throw instead of silently becoming `/api/v1/health` or another incorrect path.

- [ ] **Step 3: Document special transports**

List the exact exclusions from the Special Transport Policy table and their owning adapters.

- [ ] **Step 4: Scan for stale workflow instructions**

Run:

```powershell
rg -n "Orval|api:generate|export_openapi|shared/api/generated|axios\\.(get|post)|api\\.(get|post)" AGENTS.md README.md doc docs
```

Update living guidance. Keep dated historical plans unchanged unless they claim to be current instructions.

- [ ] **Step 5: Review and commit**

Run GitNexus `detect_changes`, then:

```powershell
git add AGENTS.md README.md doc
git diff --cached --check
git commit -m "docs(api): document generated client workflow"
```

---

### Task 13: Final Verification, Independent Review, and Completion Report

**Files:**

- No planned source changes unless verification finds a defect
- Create or update: implementation report under `docs/`

- [ ] **Step 1: Verify backend contract and domain behavior**

Run:

```powershell
Set-Location backend
ruff check .
pytest tests/test_openapi_contract.py tests/test_api_v1_routes.py -q
pytest -q -m "not live"
Set-Location ..
```

Expected: pass. If the repository has tests without a `live` marker that can trigger external crawling, run the known mock-only backend suite instead and record the excluded files.

- [ ] **Step 2: Verify contract generation**

Run:

```powershell
python scripts/check_api_contract.py
```

Expected: pass with no generated diff.

- [ ] **Step 3: Verify frontend quality**

Run:

```powershell
Set-Location frontend
npm run api:check-generated
npm run api:check-usage
npm run lint
npm run test:coverage
npm run build
npm run test:e2e
Set-Location ..
```

Expected:

- Unit and coverage checks pass.
- Build passes.
- All Playwright API calls are mocked.
- The firewall records no unmocked or blocked requests.
- No real crawl, profile, match, or Home Assistant action occurs.

- [ ] **Step 4: Verify the blog frontend**

Run:

```powershell
Set-Location blog-frontend
npm test
npm run build
Set-Location ..
```

Expected: pass.

- [ ] **Step 5: Run final static scans**

Run:

```powershell
rg -n "RequestInit" frontend/src/shared/api/generated
rg -n "/api/v1/api/v1|/api/v1/v1" frontend backend
rg -n "\bapi\.(get|post|put|patch|delete)\s*\(" frontend/src
rg -n "shared/api/generated" frontend/src
```

Expected:

- No generated `RequestInit`.
- No duplicate API prefix.
- Direct Axios calls appear only in the approved allowlist.
- Generated imports exist in every migrated ordinary JSON domain.

- [ ] **Step 6: Run GitNexus final change detection**

Run:

```text
detect_changes(repo="mavra-monitor-system", scope="compare", base_ref="main")
```

Expected affected areas:

- OpenAPI generation.
- API response schemas.
- Shared frontend API transport.
- Generated React Query clients.
- Feature data access.
- CI and documentation.

Investigate unexpected crawler execution, scheduler runtime, database schema, or profile lifecycle flows before proceeding.

- [ ] **Step 7: Run verification and code review as separate passes**

First invoke `verification-before-completion` with the exact command results.

Then invoke `requesting-code-review` in a separate pass. Review for:

- Double-prefix behavior.
- Missing operation IDs.
- Accidental Orval inclusion of special transports.
- Response-model drift from runtime payloads.
- Lost query parameters.
- Lost Axios timeout or credential behavior.
- Incorrect React Query invalidation.
- Unencoded entity IDs or profile keys.
- Refresh-loop regression.
- Multipart upload regression.
- Binary download regression.
- Unmocked dangerous requests.
- Stale generated files.

Fix actionable findings and rerun affected commands.

- [ ] **Step 8: Write the implementation report**

Create `docs/orval_api_contract_integration_report.md` containing:

- Commits created.
- Operation and schema counts after migration.
- Contract, backend, frontend, E2E, and blog command results.
- Final direct Axios allowlist.
- Final special transport exclusion list.
- Confirmation that generation is idempotent.
- Confirmation that no real crawl/profile/matching/Home Assistant operation was triggered.
- Any environmental command that could not run and its exact error.

## Completion Criteria

- FastAPI exports stable unique operation IDs.
- The full OpenAPI document declares correct JSON, SSE, binary, redirect, and file responses.
- Orval filters out special transports and root infrastructure paths.
- Orval emits Axios React Query code and cleans stale generated artifacts.
- `customInstance` strips exactly one canonical prefix and uses shared Axios behavior.
- Frontend build passes.
- Contract regeneration is idempotent.
- CI rejects stale OpenAPI or generated output.
- Ordinary JSON feature calls use generated code.
- Direct Axios is limited to the shared client, Orval mutator, and profile backup blob adapter.
- SSE, OAuth callback, public media, and blob export retain dedicated transports.
- Mock-only E2E blocks dangerous operations.
- Backend, frontend, blog, generation, verification, and independent review evidence is recorded.
