# Orval Integration Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair the reviewed Orval contract, path encoding, type-safety, enforcement, and documentation gaps.

**Architecture:** Move slash-bearing Smart Home entity IDs from the URL path into the request body. Keep generated transports authoritative, use a shared encoder for remaining string path segments, and retain feature wrappers only for application behavior such as polling and cache invalidation.

**Tech Stack:** FastAPI, Pydantic, OpenAPI 3.1, Orval 8, Axios, React Query, TypeScript, Vitest, pytest, Playwright, GitNexus.

---

### Task 1: Smart Home service-call contract

**Files:**
- Modify: `backend/app/schemas/smart_home.py`
- Modify: `backend/app/domains/smart_home/router.py`
- Modify: `backend/tests/test_smart_home_router.py`
- Modify: `frontend/src/features/smart-home/api/smartHome.ts`
- Test: `frontend/tests/unit/smart-home/smart-home-api.test.ts`

- [x] Add a failing backend test that posts `light.office/main` to
  `/api/v1/smart-home/services/call` and verifies the service receives the
  unchanged entity ID.
- [x] Run the targeted pytest and confirm the route is missing.
- [x] Add `entity_id` to `SmartHomeServiceRequest` and move the route to
  `/services/call`.
- [x] Run the targeted pytest and confirm it passes.
- [x] Export OpenAPI and regenerate Orval.
- [x] Add a failing frontend test asserting the generated call uses
  `/smart-home/services/call` and places `light.office/main` in JSON data.
- [x] Update the feature adapter to compose the generated request body.
- [x] Run the frontend test and confirm it passes.

### Task 2: Safe dynamic path segments and profile import

**Files:**
- Create: `frontend/src/shared/api/path.ts`
- Create: `frontend/tests/unit/shared/api-path.test.ts`
- Modify: `frontend/src/features/jobs/api/jobs.ts`
- Rename: `frontend/src/features/jobs/api/profileBackup.ts` to
  `frontend/src/features/jobs/api/profileBackupExport.ts`
- Modify: `frontend/src/features/jobs/hooks/useJobs.ts`

- [x] Add failing unit tests for encoding `profile name#1` exactly once.
- [x] Implement `encodePathSegment(value)` as `encodeURIComponent(value)`.
- [x] Pass crawl-profile keys and other generated string path arguments through
  the helper at feature boundaries.
- [x] Replace hand-written multipart import with
  `crawlProfilesImportProfileBackup`.
- [x] Keep only blob export in `profileBackupExport.ts`.
- [x] Run jobs and shared API unit tests.

### Task 3: Remove reviewed type escapes

**Files:**
- Modify: `frontend/src/features/jobs/api/jobs.ts`
- Modify: `frontend/src/features/jobs/api/job_match.ts`
- Modify: `frontend/src/features/jobs/types.ts`
- Modify: `frontend/src/features/products/api/crawl.ts`
- Modify: `frontend/src/features/products/hooks/useProducts.ts`
- Modify: `frontend/src/features/admin/api/admin.ts`
- Modify: `frontend/src/features/admin/AdminUsersPage.tsx`
- Modify: `frontend/src/features/blog/api/blog.ts`
- Modify: `frontend/src/features/blog/BlogAdminPage.tsx`
- Modify: affected auth, smart-home, schedule, settings, and today files only
  where the reviewed assertion is unnecessary.

- [x] Add or update type-level/unit coverage for affected adapters.
- [x] Replace local duplicate response interfaces with generated model aliases
  where shapes match.
- [x] Remove unused synchronous match analysis and return
  `MatchTaskQueuedResponse` from the async path.
- [x] Remove `as any` and `as unknown as` from feature API/hook files.
- [x] Run TypeScript build and focused unit tests after each domain.

### Task 4: Enforcement and documentation

**Files:**
- Modify: `scripts/check_frontend_api_usage.py`
- Create or modify: tests for `check_frontend_api_usage.py`
- Modify: `.github/workflows/ci.yml` if command coverage changes
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `doc/frontend-architecture.md`
- Modify: `docs/orval_api_contract_integration_report.md`

- [x] Add failing checker tests proving a new `shared/api/*.ts` Axios import is
  rejected and the blob export adapter is allowed.
- [x] Remove the directory-wide Axios exemption and use exact allowlists.
- [x] Reject type escapes in feature API/hook files.
- [x] Correct Vite proxy ownership and generated-hooks wording.
- [x] Record actual hand-written transports and verification counts.

### Task 5: Full verification

**Files:**
- Verify only; no new production behavior.

- [x] Run `python scripts/check_api_contract.py`.
- [x] Run backend Ruff and the API/OpenAPI test selection.
- [x] Run frontend API usage check, lint, unit tests, and build.
- [x] Run mock-only Playwright E2E.
- [x] Run blog tests and build.
- [x] Confirm `git status` contains only intended source/document changes and
  generated artifacts are deterministic.
- [x] Run GitNexus `detect_changes` against `main`.
- [x] Perform a separate code-review pass and resolve blocking findings.
