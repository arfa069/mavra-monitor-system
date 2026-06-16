# Final Gate 01: Backend Pytest Closure Plan

> **For agentic workers:** use the `executing-plans` workflow for this gate. Keep the backend test environment isolated from production data and record all evidence in `docs/flutter-migration/final-verification-report.md` when this gate is executed.

## Goal

Make the full backend suite pass with:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/backend
uv run --extra dev python -m pytest
```

This gate is complete only when the full command exits with zero failures and the final output is copied into the final verification report.

## Scope

- PostgreSQL and Redis test environment configuration.
- Route inventory test failures involving `_IncludedRouter.path`.
- Audit best-effort login/logout failures.
- Backend-only test fixes needed to make the existing suite green.

Out of scope:

- Real crawler runs.
- Real Profile login, import, export, or browser session mutation.
- Job matching tasks.
- Home Assistant service calls or device control.

## Execution Plan

1. Capture the current focused failure shape.

   ```powershell
   cd C:/Users/arfac/Documents/mavra-monitor-system/backend
   uv run --extra dev python -m pytest tests/test_api_v1_routes.py tests/test_audit_best_effort.py -q
   ```

2. Configure local test services explicitly.

   Use a database whose name clearly marks it as test-only. Do not point this suite at a development or production database.

   ```powershell
   cd C:/Users/arfac/Documents/mavra-monitor-system/backend
   $env:DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/pricemonitor_pytest"
   $env:REDIS_URL = "redis://localhost:6379/15"
   $env:JWT_SECRET_KEY = "local-pytest-only-jwt-secret-key-2026"
   uv run --extra dev alembic upgrade head
   ```

3. Re-run the full suite once the service credentials are known-good.

   ```powershell
   cd C:/Users/arfac/Documents/mavra-monitor-system/backend
   uv run --extra dev python -m pytest
   ```

4. If the route inventory test still fails, fix the route collection logic rather than weakening the assertion.

   The expected repair is to ignore non-route wrapper objects that do not expose `path`, for example by collecting only non-empty `getattr(route, "path", None)` values in `backend/tests/test_api_v1_routes.py`.

5. If the audit best-effort tests still fail, isolate the failure by login and logout path.

   - Verify auth database mocks still match the current login response shape.
   - Patch the exact audit function imported by the auth router.
   - Ensure the logout mock covers the current token, session, refresh-token, and audit query sequence.
   - Keep the assertion that audit failure is best-effort and must not break successful auth behavior.

6. Re-run targeted tests after each repair.

   ```powershell
   cd C:/Users/arfac/Documents/mavra-monitor-system/backend
   uv run --extra dev python -m pytest tests/test_api_v1_routes.py tests/test_audit_best_effort.py -q
   ```

7. Run the full suite again.

   ```powershell
   cd C:/Users/arfac/Documents/mavra-monitor-system/backend
   uv run --extra dev python -m pytest
   ```

## Acceptance Criteria

- `uv run --extra dev python -m pytest` exits `0`.
- Route inventory assertions still prove that business APIs live under `/api/v1`.
- Audit best-effort tests still prove login/logout continue when audit logging fails.
- No test connects to production services.
- No real crawler, Profile, job matching, or Home Assistant side effect is triggered.

## Evidence To Record

Update both files after this gate runs:

- `docs/flutter-migration/final-verification-report.md`
- `docs/flutter-migration/platform-verification-matrix.md`

Record:

- PostgreSQL database name and Redis database index used.
- Focused test command output.
- Full pytest final summary.
- Any backend test files changed.
