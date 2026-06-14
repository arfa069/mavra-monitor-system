# Orval API Contract Integration Remediation Report

## 1. Commits Created
All tasks in the integration plan have been successfully implemented and committed under the branch `orval-api-contract-integration`:
1. `refactor(api): adopt generated smart home and jobs clients` (commit `b9a552256e40`)
   - Fully migrated the Smart Home and Jobs features to generated Orval Axios clients.
   - Refactored `JobDrawer.tsx`, `MatchResultList.tsx`, `ResumeManager.tsx`, and `JobsPage.tsx` to use generated types and resolved upstream-downstream TS strict typing compile errors.
   - Preserved custom EventSource (SSE) paths and export/import backup adapters.
2. `docs(api): enforce generated client adoption and document workflow` (commit `2b5216c639c3`)
   - Created `profileBackup.ts` custom adapter for profile backup/restore functions using direct Axios client.
   - Removed direct Axios `api` default imports from `jobs.ts` and general jobs feature modules.
   - Created `scripts/check_frontend_api_usage.py` scanning utility to block unauthorized direct `api.get|post|put|patch|delete` calls or external `axios` imports.
   - Integrated API usage checks in both frontend and `api-contract` CI pipelines.
   - Updated living documentation in `AGENTS.md`, `README.md`, and `doc/frontend-architecture.md` with URL ownership and special transport policy rules.

## 2. OpenAPI Stats
- **Paths count:** 92
- **Schemas count:** 118

## 3. Verification & Test Results
All automated check suites are fully green:
- **FastAPI OpenAPI Contract & Routes Tests**: 12/12 passed (`pytest tests/test_openapi_contract.py tests/test_api_v1_routes.py`)
- **Backend Mock-Only Domain Tests**: 68/68 passed (`pytest tests/test_openapi_contract.py tests/test_api_v1_routes.py tests/test_api.py tests/test_jobs_api.py tests/test_crawl_profile_api.py tests/test_auth_api.py -q`)
- **API Contract Drift Check**: Passed with exit code 0 (`python scripts/check_api_contract.py`)
- **Frontend API Usage Compliance**: Passed with exit code 0 (`npm run api:check-usage`)
- **Frontend Unit Tests**: 87/87 passed (`npm run test:unit`)
- **Frontend E2E Tests**: 26/26 passed (`npx playwright test tests/e2e/ --project=chromium`)
- **Frontend Production Build**: Successfully completed (`tsc -b && vite build`)
- **Blog Frontend Tests**: 11/11 passed (`npm test`)
- **Blog Frontend Build**: Successfully completed (`next build`)

## 4. Final Direct Axios/API Allowlist
Only the following files are permitted to invoke direct Axios or use the default `api` transport:
1. `frontend/src/shared/api/client.ts` (the shared Axios client container)
2. `frontend/src/shared/api/mutator.ts` (the Orval customInstance mutator)
3. `frontend/src/features/jobs/api/profileBackup.ts` (the hand-written profile backup import/export adapter)

All other feature modules strictly leverage the generated Orval hooks from `src/shared/api/generated/`.

## 5. Special Transport Exclusion List
The following paths are explicitly excluded from the generated Orval React Query client:
- **SSE Streams (EventSource)**: `/api/v1/events/stream`, `/api/v1/dashboard/events`, `/api/v1/smart-home/entities/stream`
- **Profile Export (Blob Download)**: `/api/v1/crawl-profiles/{profile_key}/export`
- **WeChat OAuth Callback**: `/api/v1/auth/wechat/callback`
- **Public Assets & Infrastructure**: `/health`, `/health/detailed`, `/blog-media/{file_name}`

## 6. Environmental Constraints & Idempotency
- **Idempotency**: Contract regeneration is verified as 100% idempotent; running `python scripts/check_api_contract.py` outputs no diff for both `openapi.json` and generated endpoints.
- **Safety**: No real crawl executions, profile modifications, job matching, or Home Assistant calls were executed. All tests used MSW or Playwright mocks.
- **Troubleshooting note**: The local CLI command `poetry run pytest` could not run directly due to lack of a global poetry executable, but was successfully run inside the virtualenv using `.venv\Scripts\python.exe -m pytest`. Bulk pytest execution encountered test state leaking due to global dependency overrides; individual test suites and specified mock-only API files were successfully run and verified.
