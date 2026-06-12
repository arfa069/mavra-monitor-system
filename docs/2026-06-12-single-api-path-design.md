# Single API Path Design

**Date:** 2026-06-12

**Status:** Approved for implementation planning

## 1. Goal

Consolidate all business API traffic onto one canonical path:

```text
/api/v1/*
```

After the migration:

- FastAPI registers each business router exactly once under `/api/v1`.
- Browser requests, direct backend requests, tests, scripts, documentation, SSE, uploads, downloads, and OAuth callbacks use the same URL.
- Legacy unversioned paths such as `/auth/*` and `/products/*` return `404`.
- Intermediate `/v1/*` paths return `404`.
- No redirect or compatibility layer remains.

This is an intentional breaking change. Existing clients must migrate before or with the deployment.

## 2. Current Problem

`backend/app/main.py` currently registers the same application routers three times:

```text
/<resource>
/v1/<resource>
/api/v1/<resource>
```

The frontend adds another translation layer:

```text
business code: /v1/products
Axios baseURL: /api
browser URL:   /api/v1/products
Vite rewrite: /v1/products
backend URL:  /v1/products
```

This causes several problems:

- Backend route tables and OpenAPI expose duplicate operations.
- Development URLs differ from the paths FastAPI actually receives.
- Tests protect all three aliases, making removal harder.
- SSE and authentication refresh bypass the normal API client and hardcode paths.
- Direct backend clients and proxied browser clients use different mental models.
- Documentation alternates between legacy, `/v1`, and `/api/v1` examples.

## 3. Decision

Use `/api/v1` as the only business API prefix and forward it unchanged through every network layer.

The request path must remain identical from caller to FastAPI:

```text
frontend resource call: /products
Axios baseURL:          /api/v1
browser request:        /api/v1/products
Vite proxy request:     /api/v1/products
FastAPI route:          /api/v1/products
```

### 3.1 Backend registration

Define one shared prefix near the application router registry:

```python
API_PREFIX = "/api/v1"
```

Register application routers once:

```python
for router in _APPLICATION_ROUTERS:
    app.include_router(router, prefix=API_PREFIX)
```

Register special routers under the same prefix:

```python
app.include_router(crawl_router, prefix=API_PREFIX)
```

Keep the public blog-media asset router at `/blog-media/*`; it is not a
business API router and its URLs are persisted in blog content.

Remove:

- Unprefixed `_include_application_routers()`.
- `/v1` router registration.
- Unprefixed `/products/crawl/*` compatibility registration.
- `/v1` API root.
- Any test whose purpose is to require legacy aliases.

Keep one service-information endpoint:

```text
GET /api/v1
```

### 3.2 Frontend HTTP client

The shared Axios client owns the API prefix:

```typescript
const api = axios.create({
  baseURL: "/api/v1",
  timeout: API_TIMEOUT_MS,
  withCredentials: true,
});
```

Feature API modules use resource-relative paths:

```typescript
api.get("/products");
api.post("/auth/login", data);
api.get("/jobs/configs");
```

Feature modules must not include `/api`, `/v1`, or `/api/v1`.

Authentication refresh must use the same configured Axios instance or a deliberately isolated refresh client with the same `/api/v1` base. It must not retain a separately hardcoded `/api/v1/auth/refresh` URL.

### 3.3 Development proxy

Vite proxies `/api` to FastAPI without rewriting the path:

```typescript
proxy: {
  "/api": {
    target: "http://127.0.0.1:8000",
    changeOrigin: true,
  },
}
```

The existing rewrite that removes `/api` must be deleted.

### 3.4 Production proxy

Production reverse proxies must preserve the incoming URI:

```text
/api/v1/products -> backend /api/v1/products
```

The proxy must not:

- Strip `/api`.
- Add another `/api`.
- Translate `/api/v1` to `/v1`.
- Redirect API requests to another prefix.

SSE proxy locations must also disable response buffering and use timeouts appropriate for long-lived connections.

## 4. Paths Outside the Business API

The project still has multiple URL namespaces, but only one business API namespace.

The following infrastructure endpoints remain outside `/api/v1`:

```text
/health
/health/detailed
/docs
/redoc
/openapi.json
```

These are not legacy business aliases. Moving them would unnecessarily break probes and framework tooling.

The public asset namespace also remains outside `/api/v1`:

```text
/blog-media/*
```

Uploaded blog records currently store URLs such as `/blog-media/cover.webp`.
Moving this route would break existing article images, Open Graph images, and
rich-text content. Media upload is an API operation under
`POST /api/v1/blog/admin/uploads`; media delivery is a stable public asset URL.

Frontend page routes also remain unchanged:

```text
/today
/jobs
/products
/dashboard
/auth/wechat/callback
```

The frontend callback route `/auth/wechat/callback` is a React page. It must not be confused with the backend OAuth callback at `/api/v1/auth/wechat/callback`.

## 5. Breaking-Change Policy

The migration is an immediate cutover.

Old paths return `404 Not Found`:

```text
/auth/login
/products
/jobs
/crawl/crawl-now
/products/crawl/crawl-now
/v1/auth/login
/v1/products
/v1/jobs
/v1/crawl/crawl-now
```

The backend must not return `301`, `302`, `307`, or `308` for old API paths. Redirects are unsafe or ambiguous for:

- POST and PATCH request bodies.
- Cookie and CSRF behavior.
- SSE connections.
- Multipart profile imports.
- File downloads.
- OAuth callbacks.

The backend must not return `410 Gone`; the chosen behavior is normal route absence through `404`.

## 6. Boundary Cases

### 6.1 Authentication cookies

Authentication cookies currently use `Path=/`. That remains unchanged.

This preserves cookie availability for:

- `/api/v1/auth/*`.
- SSE connections.
- The frontend application.
- OAuth callback responses.

Cookie names, `HttpOnly`, `SameSite`, `Secure`, expiration, rotation, and CSRF behavior do not change.

Cookie clearing must continue using the same `Path=/`, otherwise old cookies could survive logout.

### 6.2 CSRF

Unsafe requests under `/api/v1` continue to receive `X-CSRF-Token` from the shared Axios interceptor.

`POST /api/v1/auth/refresh` remains the existing exception that relies on the HttpOnly refresh cookie and does not require the CSRF header.

The migration must verify that changing Axios `baseURL` does not cause:

- Duplicate prefixes such as `/api/v1/api/v1/config`.
- Missing CSRF headers on feature mutations.
- Refresh requests entering the normal 401 retry loop.

### 6.3 Concurrent token refresh

The existing single-refresh queue remains behaviorally unchanged:

- The first eligible `401` starts refresh.
- Concurrent failed requests wait in the queue.
- Refresh uses `/api/v1/auth/refresh`.
- Queued requests replay using their original Axios configs.
- Login and current-user initialization remain excluded from refresh loops.
- Failed refresh redirects the browser to `/login`.

Tests must cover two simultaneous protected requests and assert one refresh call.

### 6.4 Server-Sent Events

All SSE URLs become canonical:

```text
GET /api/v1/dashboard/events
GET /api/v1/events/stream
GET /api/v1/smart-home/entities/stream
```

SSE clients cannot rely on Axios, so URL construction must use one shared API base constant or helper.

SSE requirements:

- `withCredentials: true`.
- No redirect through an old path.
- Proxy buffering disabled.
- Cache disabled where currently required.
- Long-lived proxy read timeout.
- Query parameters preserved for Event Center filters.
- Automatic reconnect continues to target the canonical path.

### 6.5 WeChat OAuth

The backend OAuth callback becomes:

```text
http://localhost:8000/api/v1/auth/wechat/callback
```

Production `WECHAT_REDIRECT_URI` values and the WeChat platform callback whitelist must be updated before deployment.

The frontend landing page remains:

```text
http://localhost:3000/auth/wechat/callback
```

`WECHAT_FRONTEND_CALLBACK_URL` therefore does not gain `/api/v1`.

The QR response must embed the canonical backend callback. Bound-user, unbound-user, expired-state, disabled-user, and OAuth-failure redirects must still land on the frontend page.

### 6.6 Blog frontend

The separate blog frontend currently defaults to a backend `/v1` base. Its API base becomes:

```text
BLOG_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

`BLOG_BACKEND_ORIGIN` remains an origin without a path:

```text
BLOG_BACKEND_ORIGIN=http://127.0.0.1:8000
```

Public blog reads, admin post management, and media upload must all use `/api/v1/blog/*`.

### 6.7 Uploads and downloads

The following operations must use the canonical prefix without redirects:

- Blog media multipart upload.
- Crawl-profile encrypted backup import.
- Crawl-profile encrypted backup export.

The uploaded blog media returned by the upload API must continue using a
`/blog-media/*` public URL. The API prefix applies to the upload operation, not
to the stored asset URL.

Verification must check:

- Multipart boundaries and form fields remain intact.
- Export responses retain filename and content-disposition headers.
- Blob handling remains correct in the frontend.
- Long request timeouts remain available where already configured.

### 6.8 URL-encoded path parameters

Smart Home entity IDs and crawl profile keys may contain punctuation. Callers must continue encoding path parameters before appending them to canonical resource paths.

Changing the base URL must not introduce double encoding or convert encoded slashes into path separators.

### 6.9 CORS and direct backend access

Browser development normally uses the same-origin Vite proxy. Direct backend access still supports:

```text
http://localhost:8000/api/v1/*
```

Cross-origin deployments continue to require:

- Explicit `ALLOWED_ORIGINS`.
- `allow_credentials=True`.
- Cookie settings appropriate for HTTPS and deployment topology.
- Credentialed SSE support.

No CORS rule should reference the removed `/v1` or legacy paths because CORS is origin-based, not route-based.

### 6.10 Health checks and startup scripts

Service launchers and infrastructure probes continue to use `/health` or `/health/detailed`.

They must not be migrated to `/api/v1/health`.

The backend URL printed by the startup script may remain the service origin. Documentation may additionally advertise `/api/v1` as the business API root.

### 6.11 OpenAPI and Orval boundary

The route consolidation naturally changes FastAPI's OpenAPI document to contain one business path per operation.

This design does not include:

- Repairing the current Orval Axios mutator mismatch.
- Migrating feature code to generated hooks.
- Redesigning Orval output names or tags.
- Addressing generated-client build failures unrelated to route aliases.

Implementation planning must keep those Orval issues separate. It may export the new OpenAPI contract as required by repository policy, but must not expand the task into an Orval adoption project without separate approval.

After backend route registration changes, implementation must still run the
repository's contract synchronization commands:

```powershell
python scripts/export_openapi.py
cd frontend
npm run api:generate
```

The expected generated diff removes legacy and `/v1` operation duplicates and
retains only `/api/v1` business operations. This mechanical synchronization
does not authorize changes to `orval.config.ts`, the custom mutator, generated
hook consumption, or unrelated generated-client typing.

If the frontend build continues to fail with the already identified
`RequestInit` versus `AxiosRequestConfig` mismatch, implementation must report
that result accurately as a known Orval blocker. It must not repair that
separate problem as part of the single-path migration.

## 7. Consumer Migration

All consumers must move in the same change because old paths are removed immediately.

### 7.1 Runtime consumers

- Main React frontend Axios client.
- React feature API modules.
- Dashboard, Event Center, and Smart Home SSE clients.
- Authentication refresh interceptor.
- Blog frontend server-side API client.
- WeChat OAuth callback configuration.
- Direct scripts and curl examples.

### 7.2 Test consumers

- Backend route and domain tests.
- Backend integration and E2E tests.
- Frontend unit-test MSW handlers.
- Frontend Playwright API mocks and firewall rules.
- SSE tests.
- Authentication refresh-queue tests.
- Blog frontend tests, if present.

Test helpers should define a shared canonical prefix instead of repeating path translation rules.

### 7.3 Documentation consumers

- Root README.
- Backend and frontend architecture documents.
- Authentication, permissions, scheduler, SSE, crawler, profile, product, deployment, and configuration documentation.
- Environment examples.
- Manual verification checklist.

Historical implementation plans may remain historical records when clearly dated. Living documentation and runnable commands must use `/api/v1`.

## 8. Testing Strategy

### 8.1 Route registration tests

Assert representative canonical routes are registered:

```text
/api/v1/auth/login
/api/v1/products
/api/v1/crawl/crawl-now
/api/v1/events/stream
/api/v1/scheduler/status
/api/v1/auth/wechat/callback
```

Assert representative removed routes are absent and return `404`:

```text
/auth/login
/products
/products/crawl/crawl-now
/v1/auth/login
/v1/products
/v1/crawl/crawl-now
```

### 8.2 Backend domain tests

Update tests to call canonical URLs while preserving their existing assertions for:

- Authentication and session rotation.
- RBAC and resource permissions.
- Products and alerts.
- Jobs, matching, and crawl tasks.
- Crawl profiles and worker registry.
- Configuration and scheduler status.
- Dashboard and Event Center.
- Smart Home.
- Blog and media upload.

This migration changes routing, not domain behavior.

### 8.3 Frontend unit tests

Verify:

- Axios produces `/api/v1/<resource>`.
- Feature modules cannot accidentally double-prefix requests.
- CSRF headers still reach unsafe requests.
- Concurrent refresh calls remain deduplicated.
- SSE helpers produce canonical URLs with query parameters.
- Authentication and feature mocks only match `/api/v1`.

### 8.4 Browser tests

Mock-only browser tests must confirm:

- Login and current-user restoration use `/api/v1`.
- Main navigation loads data from canonical endpoints.
- Event Center and Smart Home initialize canonical SSE URLs.
- WeChat frontend callback page behavior remains unchanged.
- The API firewall rejects unexpected `/v1/*` requests.

Browser verification must not trigger real crawl, profile login, profile test, matching analysis, or Home Assistant control requests.

### 8.5 Static path scan

The final scan must distinguish API URLs from frontend routes and prose.

Runtime code must not contain business requests beginning with:

```text
/v1/
/auth/
/products/
/jobs/
/events/
/smart-home/
```

Exceptions must be explicit:

- React page routes.
- Infrastructure endpoints.
- External service URLs.
- Historical documents that are intentionally preserved.

## 9. Deployment Order

Because no compatibility layer remains, backend and all clients must deploy atomically.

Required order within one release:

1. Update external OAuth callback configuration.
2. Build backend and both frontends from the same revision.
3. Update reverse-proxy configuration to preserve `/api/v1`.
4. Deploy backend and frontend artifacts together.
5. Run canonical-path smoke checks.
6. Verify old paths return `404`.

Rolling deployments with mixed old and new application versions are not supported unless the deployment platform guarantees that old clients cannot reach the new backend.

If atomic deployment cannot be guaranteed, implementation must stop and request a revised compatibility policy rather than silently adding redirects.

## 10. Observability

After deployment, inspect access logs for:

```text
/v1/
/auth/
/products/
/jobs/
/events/
```

Any legacy business-path traffic indicates an unconverted consumer.

Monitoring should distinguish expected frontend page routes from backend API traffic by host, port, or upstream service, not by path text alone.

404 spikes on the backend immediately after release are a rollback signal unless they come from explicit old-path verification checks.

## 11. Success Criteria

The migration is complete only when all of the following are true:

- Each business router is registered once.
- `/api/v1` is the only business API prefix.
- Vite and production proxies preserve the path.
- Frontend feature modules use resource-relative paths.
- SSE uses canonical URLs.
- WeChat backend callback uses `/api/v1`.
- Blog frontend uses `/api/v1`.
- Cookie, CSRF, refresh, upload, download, and SSE behavior is verified.
- `/health`, `/docs`, and frontend page routes remain available at their existing paths.
- Existing `/blog-media/*` asset URLs remain available.
- Representative legacy and `/v1` paths return `404`.
- Tests and living documentation no longer require old API aliases.
- No redirect or hidden compatibility registration remains.

## 12. Out of Scope

- Fixing Orval configuration or generated-client TypeScript errors.
- Migrating feature modules to Orval-generated hooks.
- Changing API request or response schemas.
- Changing authentication, authorization, CSRF, or cookie policy.
- Changing frontend page routes.
- Moving infrastructure endpoints under `/api/v1`.
- Moving persisted blog-media asset URLs under `/api/v1`.
- Adding a deprecation period, redirect, or compatibility router.
- Triggering real crawl or profile operations during verification.
