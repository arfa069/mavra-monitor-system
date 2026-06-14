# Canonical API Path Migration Report

**Date:** 2026-06-13

**Canonical business API namespace:** `/api/v1/*`

**Status:** Route migration verified; follow-up Orval type-check blocker resolved on 2026-06-14.

## Scope

The migration removes root-level and `/v1/*` business route aliases. FastAPI,
the main React frontend, the blog frontend, tests, examples, and generated API
clients now use `/api/v1/*`. Infrastructure endpoints such as `/health` and
`/blog-media/{file_name}` remain outside the business API namespace.

## Implementation Commits

| Commit | Change |
| --- | --- |
| `1df2d1c7` | Canonicalize backend API test paths |
| `6563a2b7` | Expose business routes only under `/api/v1` |
| `23f20a82` | Preserve `/api/v1` paths in the main frontend |
| `918ceefb` | Update callback configuration examples |
| `e78da175` | Document the canonical API namespace |
| `f201800b` | Fix remaining backend test paths with query strings |
| `d2308fe0` | Update blog API base URL documentation |
| `9a493180` | Add the smart-home summary E2E mock |
| `57201429` | Removed legacy firewall checks; corrected by the post-review work below |

The post-review correction restores the Playwright firewall regression tests,
rejects `/v1/*` requests inside E2E with status `501`, updates current
architecture documentation, and adds this report.

## Verification Results

### Backend Routes

- FastAPI route count: `126`.
- No duplicate method/path registrations were found.
- No business routes were registered at the root or under `/v1/*`.
- `GET /api/v1/products` returned `401`, proving that the canonical route
  exists and is protected.
- `GET /products`, `GET /v1/products`, `GET /auth/login`, and
  `GET /v1/auth/login` returned `404` without redirects.
- Route-focused pytest result: `24 passed`.
  - `tests/test_api_v1_routes.py`
  - `tests/test_event_center.py`
  - `tests/test_wechat_auth_flow.py`

### OpenAPI And Orval

- OpenAPI paths: `92`.
- Operations: `122`.
- Duplicate `operationId` values: `0`.
- Root-level or `/v1/*` business paths in OpenAPI: `0`.
- Legacy business paths in generated TypeScript: `0`.
- `scripts/export_openapi.py`: passed.
- `npm run api:generate`: passed.
- Content diff for `frontend/openapi.json` and
  `frontend/src/shared/api/generated/`: clean.
- On Windows with `core.autocrlf=true`, generation emits LF-to-CRLF warnings;
  these warnings do not represent semantic generated-code changes.

### Main Frontend

- ESLint: passed.
- Vitest: `81 passed`.
- Playwright: `26 passed`, including four API firewall regression tests.
- The E2E firewall rejects:
  - unregistered `/api/*` requests;
  - dangerous canonical operations;
  - all unexpected `/v1/*` legacy requests.
- No Playwright route uses `route.continue()` or `route.fallback()`.
- API requests in these E2E tests were fulfilled or rejected by the in-process
  Playwright firewall; no live backend, crawler worker, browser profile, or
  Home Assistant operation was invoked.

### Blog Frontend

- Vitest: `11 passed`.
- Next.js production build: passed.

## Follow-Up Orval Blocker Resolution

At the end of the route migration, the main frontend production build was not
green:

```text
npm run build
build_exit=2
```

TypeScript reports incompatibilities between Orval-generated call signatures
and `frontend/src/shared/api/mutator.ts`, primarily:

- `RequestInit` versus `AxiosRequestConfig`;
- `GenericAbortSignal` versus DOM `AbortSignal`;
- generated URL strings being passed where an Axios configuration is expected.

This blocker predated the post-review firewall and documentation correction.
It was resolved by the 2026-06-14 Orval API contract integration follow-up,
which regenerated Axios-compatible clients, migrated ordinary JSON feature
calls to generated code, enforced the manual transport allowlist, and restored a
green frontend production build.

## Verification Boundaries

- No real crawl, browser profile login, LLM analysis, worker execution, or
  smart-home device control was triggered.
- The repository-wide backend test suite was not used as the acceptance gate
  for this correction. The route-focused backend tests and structural route
  inspection are the relevant checks.
- The full service launcher was not run because it starts the crawler worker
  and could execute queued real work.

## Deployment Actions

Before deployment:

1. Build the backend and both frontends from the same revision.
2. Ensure the production proxy preserves `/api/v1` without stripping `/api`.
3. Update the WeChat callback URL and platform whitelist to canonical URLs.
4. Set the blog frontend `BLOG_API_BASE_URL` to the canonical API base.
5. Deploy atomically so old and new route policies cannot be mixed.
6. Keep backend and both frontend rollback artifacts as one release unit.
