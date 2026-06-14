# Orval Integration Repair Design

## Goal

Close the gaps found during independent review of the Orval integration without
rewriting the generated client or changing unrelated application behavior.

## Contract Boundary

Home Assistant entity IDs may contain `/`. Such values cannot be represented
reliably by FastAPI's normal path parameter because Starlette decodes `%2F`
before route matching. Replace:

```text
POST /api/v1/smart-home/entities/{entity_id}/service
```

with:

```text
POST /api/v1/smart-home/services/call
```

The request body contains `entity_id`, `service`, and `service_data`. The
frontend keeps its existing `callService(entityId, data)` feature API, but
builds the generated request body explicitly.

Other dynamic string path segments remain path parameters. Feature adapters
must pass them through a shared `encodePathSegment()` helper exactly once
before calling generated functions. Crawl profile keys reject `/` and `\` at
validation time, so this protects spaces and URL-reserved characters without
changing profile storage semantics.

## Generated Client Adoption

Ordinary JSON and multipart operations use Orval-generated functions, hooks, or
query-option builders. The profile backup import uses
`crawlProfilesImportProfileBackup`; only blob export remains a hand-written
Axios adapter.

Feature hooks may remain as application-facing wrappers when they own polling,
cache invalidation, UI query keys, or response mapping. These wrappers must not
replace generated return types with `any` or `unknown` assertions.

## Type Safety

The repair removes the reviewed high-risk type escapes from jobs, admin,
products, blog, smart home, and auth call sites. Generated models are used
directly where their shape matches. UI-only types remain local and are mapped
explicitly only when their shape genuinely differs.

The synchronous match-analysis adapter is removed if unused. The asynchronous
adapter returns the generated `MatchTaskQueuedResponse`.

## Enforcement

`scripts/check_frontend_api_usage.py` uses exact allowlists:

- `frontend/src/shared/api/client.ts`
- `frontend/src/shared/api/mutator.ts`
- the blob export adapter

No directory-wide Axios exemption is allowed. The checker also rejects new
`as any` and `as unknown as` escapes in feature API and hook files, with exact
file/line exemptions only if a real incompatibility is documented.

## Documentation

Repository guidance states that Vite forwards `/api/v1/...` unchanged. It also
distinguishes generated transport functions from feature-level React Query
wrappers and lists only the actual hand-written transport exceptions.

## Verification

Automated verification must not start real crawlers, open profiles, import or
export real profile data, or control Home Assistant devices. Required evidence:

- Smart Home request-body regression tests, including `light.office/main`.
- Path segment encoding tests for profile keys with reserved characters.
- Backend OpenAPI and canonical route tests.
- Orval export/generation idempotence.
- Frontend lint, unit tests, mock-only Playwright E2E, and production build.
- Blog tests and build.
- Backend Ruff and targeted API tests.
- GitNexus change detection and a separate final code-review pass.

