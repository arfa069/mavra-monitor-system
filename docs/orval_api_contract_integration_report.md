# Orval API Contract Integration Remediation Report

## Status

The Orval integration repair is implemented on branch
`orval-api-contract-integration`. The repair changes are currently in the
working tree and have not been committed.

## Contract And Transport Changes

- Smart Home service calls now use
  `POST /api/v1/smart-home/services/call`.
- `entity_id`, `service`, and `service_data` are carried in the request body,
  so entity IDs such as `light.office/main` are preserved.
- The legacy entity service path is not registered and returns `404`.
- Dynamic string path segments pass through `encodePathSegment()` before
  generated functions interpolate them.
- Profile backup import uses the Orval-generated multipart function.
- Only profile backup blob export remains a hand-written Axios transport:
  `frontend/src/features/jobs/api/profileBackupExport.ts`.

## Type Safety

- Removed reviewed `as any` and `as unknown as` escapes from feature API,
  hook, and consumer code.
- Jobs, admin, products, events, schedule, today, settings, blog, auth, and
  Smart Home now consume generated request/response types directly or map
  optional generated fields explicitly.
- Auth responses are normalized to application roles and known permissions.
- Smart Home normalization follows backend defaults:
  `available=true` and `token_configured=true`.

## Enforcement

`scripts/check_frontend_api_usage.py` now:

- Uses exact allowlists for direct Axios and shared client access.
- Rejects aliased default imports of `shared/api/client`.
- Rejects `as any` and `as unknown as` in feature API and hook files.
- Allows named utility imports such as `formatApiError`.

CI runs both the checker regression tests and the repository-wide usage scan.

## OpenAPI

- Paths: 92
- Schemas: 118
- Generated contract files checked for idempotence: 184

## Verification

- Backend API/OpenAPI/Smart Home selection: 76 passed, 1 skipped.
- Backend Smart Home router regression suite: 9 passed.
- Backend Ruff: passed.
- API usage checker tests: 4 passed.
- Frontend API usage scan: passed.
- Frontend lint: passed.
- Frontend unit tests: 95 passed.
- Vitest file-level parallelism is disabled to avoid Ant Design validation
  animation races under heavy worker contention.
- Frontend mock-only Playwright E2E: 27 passed.
- Frontend production build: passed.
- Blog frontend tests: 11 passed.
- Blog frontend production build: passed.
- `scripts/check_api_contract.py`: passed using a temporary Git index seeded
  with the intended generated artifacts; the real staging area was untouched.
- Contract export and Orval regeneration were hash-identical across all 184
  generated contract files.

No real crawl, profile mutation, job matching, or Home Assistant control action
was executed during verification.
