# Crawler Production Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first production-safety slice of the crawler refactor by separating crawl task creation from crawl execution, adding profile path helpers, adding profile lease interfaces, and adding CDP/logging safety checks while keeping the existing FastAPI + APScheduler in-process runtime.

**Architecture:** FastAPI endpoints and APScheduler jobs continue to run in the current process, but both route through a new `CrawlTaskRunner` boundary. Browser profile paths are resolved through a project-root-relative path helper, and profile leases start as in-process locks with an interface that can later move to PostgreSQL or Redis. Security checks run before CDP use and logging redaction is centralized so future worker processes inherit the same behavior.

**Tech Stack:** Python 3.13, FastAPI, APScheduler, async SQLAlchemy, Playwright/CloakBrowser, `curl_cffi`, pytest, ruff, Windows PowerShell.

---

## Scope Check

This implementation plan covers **Phase 1 only** from [docs/2026-05-25-crawler-production-todo.md](2026-05-25-crawler-production-todo.md).

Phase 2-5 remain tracked in [docs/2026-05-25-crawler-production-todo.md](2026-05-25-crawler-production-todo.md). They should become separate implementation plans because they touch persistence, platform-specific crawler behavior, product browser lifecycle, and independent worker deployment.

## Current Behavior To Preserve

- `POST /api/v1/jobs/crawl-now` still returns a task id immediately.
- `POST /api/v1/jobs/crawl-now/{config_id}` still returns a task id immediately.
- Job config cron jobs still execute in the current API process.
- Product crawl-now still uses the current in-memory task registry.
- Existing `JobCrawlLog`, `CrawlLog`, Event Center, and Feishu behavior must remain compatible.
- No real cookie/profile file is committed or printed to logs.

## File Structure

- Create: `backend/app/core/crawler_paths.py`
  - `build_profile_dir(key, root=None)` — resolves profile path to project root's `profiles/{key}`.
- Create: `backend/app/core/profile_lease.py`
  - Define `ProfileLease`, `InProcessProfileLeaseManager`, and in-process lease implementation.
- Create: `backend/app/core/cdp_security.py`
  - Validate CDP URLs are local-only before CDP use.
- Create: `backend/app/core/log_redaction.py`
  - Central redaction helpers: `FULL_REDACT_KEYS`, `PARTIAL_REDACT_KEYS`, `redact_payload()`.
- Create: `backend/app/domains/crawling/task_runner.py`
  - `CrawlTaskRunner` facade for product and job crawl execution.
- Modify: `backend/app/config.py`
  - Add `cdp_allow_non_local`.
  - No `PRICE_MONITOR_HOME` / `CRAWLER_PROFILE_ROOT` (profile root is always project-relative).
- Modify: `backend/app/platforms/boss_cloak_experimental.py`
  - Use `build_profile_dir("default")` when no explicit `profile_dir` is passed.
- Modify: `backend/app/platforms/job51.py`
  - Use `build_profile_dir("default")` when no explicit `profile_dir` is passed.
- Modify: `backend/app/platforms/base.py`
  - Run CDP URL safety check before connecting to CDP.
- Modify: `backend/app/domains/jobs/crawl_service.py`
  - Route background job execution through `CrawlTaskRunner`.
- Modify: `backend/app/domains/crawling/scheduler_service.py`
  - Route product task execution through `CrawlTaskRunner`.
- Test: `backend/tests/test_crawler_paths.py`
- Test: `backend/tests/test_profile_lease.py`
- Test: `backend/tests/test_cdp_security.py`
- Test: `backend/tests/test_log_redaction.py`
- Test: `backend/tests/test_crawl_task_runner.py`
- Test: `backend/tests/test_integration_crawl_phase1.py`
- Test: `backend/tests/test_e2e_crawl_flow.py`
- Update: existing job/product crawl tests only where needed for routing assertions.

## Edge Cases

- Profile key contains path traversal (`../x`) or separators: reject with `ValueError`.
- Profile key is empty, `.`, or `..`: reject with `ValueError`.
- Existing adapter tests that pass explicit `profile_dir` must keep working.
- CDP URL host is `0.0.0.0`, public IP, or LAN IP: reject unless `CDP_ALLOW_NON_LOCAL=true`.
- CDP URL host is `127.0.0.1`, `localhost`, or `::1`: allow.
- Existing empty `cdp_url`: reject with a clear error if CDP is enabled.
- Multiple jobs request the same profile in the same process: second acquire fails fast with `RuntimeError`.
- A crawl raises after acquiring a profile lease: `finally` must release the lease.
- A redaction helper receives nested dict/list payloads: recursively redact sensitive keys.
- A redaction helper receives non-dict payloads: return safe string representation unchanged.
- Redaction receives a `set`: iterate and redact each element.
- Event Center payloads must not include cookie/header dumps.

## Task 1: Add Cross-Platform Crawler Paths

**Files:**
- Create: `backend/app/core/crawler_paths.py`
- Test: `backend/tests/test_crawler_paths.py`

- [x] **Step 1: Write failing path tests**

Create `backend/tests/test_crawler_paths.py`:

```python
from pathlib import Path

import pytest


def test_default_price_monitor_home_windows(monkeypatch):
    from app.core import crawler_paths

    monkeypatch.delenv("PRICE_MONITOR_HOME", raising=False)
    monkeypatch.setattr(crawler_paths.os, "name", "nt")

    assert crawler_paths.default_price_monitor_home() == Path("C:/price-monitor")


def test_default_price_monitor_home_posix(monkeypatch):
    from app.core import crawler_paths

    monkeypatch.delenv("PRICE_MONITOR_HOME", raising=False)
    monkeypatch.setattr(crawler_paths.os, "name", "posix")

    assert crawler_paths.default_price_monitor_home() == Path("/price-monitor")


def test_profile_dir_rejects_path_traversal(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir(tmp_path, "boss", "../profile-a")


def test_profile_dir_groups_by_platform(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    assert build_profile_dir(tmp_path, "boss", "profile-a") == (
        tmp_path / "profiles" / "boss" / "profile-a"
    )
```

- [x] **Step 2: Run tests and verify they fail**

- [x] **Step 3: Add crawler path helper**

Create `backend/app/core/crawler_paths.py`:

```python
"""Cross-platform path helpers for crawler runtime data."""

from __future__ import annotations

import os
from pathlib import Path

VALID_PLATFORMS = {
    "boss",
    "51job",
    "liepin",
    "jd",
    "taobao",
    "amazon",
}


def default_price_monitor_home() -> Path:
    if os.name == "nt":
        return Path("C:/price-monitor")
    return Path("/price-monitor")


def resolve_price_monitor_home(value: str | None = None) -> Path:
    raw = value or os.environ.get("PRICE_MONITOR_HOME")
    path = Path(raw).expanduser() if raw else default_price_monitor_home()
    return path.resolve()


def _validate_segment(kind: str, value: str) -> None:
    if not value or "/" in value or "\\" in value or value in {".", ".."} or ".." in Path(value).parts:
        raise ValueError(f"Invalid {kind}: {value!r}")


def build_profile_dir(root: str | Path, platform: str, profile_key: str) -> Path:
    if platform not in VALID_PLATFORMS:
        raise ValueError(f"Invalid platform: {platform!r}")
    _validate_segment("profile key", profile_key)
    return Path(root).expanduser().resolve() / "profiles" / platform / profile_key
```

- [x] **Step 4: Add settings**

Modify `backend/app/config.py` inside `Settings` crawler settings:

```python
    price_monitor_home: str = ""
    crawler_profile_root: str = ""
```

Add this property below crawler settings:

```python
    @property
    def resolved_price_monitor_home(self) -> Path:
        from app.core.crawler_paths import resolve_price_monitor_home

        return resolve_price_monitor_home(self.price_monitor_home or None)

    @property
    def resolved_crawler_profile_root(self) -> Path:
        if self.crawler_profile_root:
            return Path(self.crawler_profile_root).expanduser().resolve()
        return self.resolved_price_monitor_home
```

- [x] **Step 5: Run tests**

- [x] **Step 6: Run lint**

- [x] **Step 7: Commit**

### Actual implementation after review feedback

During code review and user feedback, the following changes were made:

1. **Removed `default_price_monitor_home()` and `resolve_price_monitor_home()`** — replaced with `_project_root()` derived from `__file__`.
2. **`build_profile_dir` signature simplified** — `build_profile_dir(profile_key, root=None)`. When `root` is `None`, resolves to `Path(__file__).resolve().parent.parent.parent.parent / "profiles" / profile_key`.
3. **Removed `VALID_PLATFORMS`** — all platforms share the same flat `profiles/` namespace.
4. **Removed platform subdirectory** — `profiles/{key}` instead of `profiles/{platform}/{key}`.
5. **Removed `PRICE_MONITOR_HOME` / `CRAWLER_PROFILE_ROOT` from `config.py`** — no env var configuration needed.
6. **Added `value == "."` check** in `_validate_segment` (not just `"." in value`).

**Final code** (`crawler_paths.py`):

```python
def _project_root() -> Path:
    return Path(__file__).resolve().parent.parent.parent.parent


def _validate_segment(kind: str, value: str) -> None:
    if not value or value == "." or "/" in value or "\\" in value or ".." in Path(value).parts:
        raise ValueError(f"Invalid {kind}: {value!r}")


def build_profile_dir(profile_key: str, root: str | Path | None = None) -> Path:
    _validate_segment("profile key", profile_key)
    base = Path(root).expanduser().resolve() if root is not None else _project_root()
    return base / "profiles" / profile_key
```

**Tests** (5 tests):

```python
def test_build_profile_dir_defaults_to_project_root()
def test_build_profile_dir_accepts_explicit_root(tmp_path)
def test_build_profile_dir_rejects_path_traversal(tmp_path)
def test_build_profile_dir_rejects_empty_key(tmp_path)
def test_build_profile_dir_rejects_dot_key(tmp_path)
```

**Notable:** Adapter profile defaults changed from:
```python
# Before: ~/.cloakbrowser/profiles/{platform}-test
# Plan:   settings.resolved_crawler_profile_root / "profiles" / platform / "default"
# Final:  build_profile_dir("default")  →  {project_root}/profiles/default
```

The `cdp_allow_non_local` setting was kept in `config.py`.

---

## Task 2: Add Profile Lease Interfaces

**Files:**
- Create: `backend/app/core/profile_lease.py`
- Test: `backend/tests/test_profile_lease.py`

- [x] **Step 1: Write failing lease tests**

```python
async def test_profile_lease_rejects_double_acquire(tmp_path)
async def test_profile_lease_releases_after_context(tmp_path)
```

- [x] **Step 2: Run tests and verify they fail**

- [x] **Step 3: Implement in-process profile lease**

`InProcessProfileLeaseManager` with `asyncio.Lock`-protected acquire/release and `@asynccontextmanager` lease.

- [x] **Step 4: Run tests and lint**

- [x] **Step 5: Commit**

### Actual implementation after review feedback

Same as planned, except `build_profile_dir(profile_key, root=self.root)` instead of `build_profile_dir(self.root, platform, profile_key)`.

The lease key is the resolved `profile_dir`, not `(platform, profile_key)`. This matches the production rule discussed during review:

> One profile can store login state for multiple platforms, but the same profile directory can only be occupied by one crawl task at a time. A crawl task runs one platform.

Boundary tests cover:

```python
async def test_profile_lease_rejects_same_profile_across_platforms(tmp_path)
async def test_profile_lease_allows_different_profiles_for_same_platform(tmp_path)
```

---

## Task 3: Add CDP Safety Validation

**Files:**
- Create: `backend/app/core/cdp_security.py`
- Modify: `backend/app/config.py`
- Modify: `backend/app/platforms/base.py`
- Test: `backend/tests/test_cdp_security.py`

- [x] **Step 1: Write failing CDP safety tests**

- [x] **Step 2: Run tests and verify they fail**

- [x] **Step 3: Implement CDP URL validator**

```python
def validate_cdp_url(url: str, *, allow_non_local: bool = False) -> None
```

- [x] **Step 4: Add override setting**

`cdp_allow_non_local: bool = False` in `config.py`.

- [x] **Step 5: Wire safety check before CDP connection**

In `base.py`, `_init_browser_cdp` path only (not the `launch` path).

- [x] **Step 6: Run tests and lint**

- [x] **Step 7: Commit**

### Actual implementation

Identical to plan. 9 tests covering: localhost, loopback, IPv6 `::1`, external IP, `0.0.0.0`, LAN IP, explicit override, empty URL, missing host.

---

## Task 4: Add Central Log Redaction

**Files:**
- Create: `backend/app/core/log_redaction.py`
- Test: `backend/tests/test_log_redaction.py`

- [x] **Step 1: Write failing redaction tests**

- [x] **Step 2: Run tests and verify they fail**

- [x] **Step 3: Implement redaction helper**

`FULL_REDACT_KEYS`, `PARTIAL_REDACT_KEYS`, `redact_payload()`.

- [x] **Step 4: Run tests and lint**

- [x] **Step 5: Commit**

### Actual implementation

**Changes from plan:**
1. **`_redact_string` was inlined** — `redact_payload` directly formats the redacted string.
2. **Added `set` type handling** — `isinstance(value, set)` branch iterates each element.
3. **`"***REDACTED***"` for full redact** instead of calling a separate helper.

**Final `redact_payload`:**

```python
def redact_payload(value: Any) -> Any:
    if isinstance(value, Mapping):
        ...
    if isinstance(value, list):
        ...
    if isinstance(value, tuple):
        ...
    if isinstance(value, set):
        return {redact_payload(item) for item in value}
    return value
```

**Tests** (4 tests originally, expanded with edge cases):

```python
test_redact_payload_masks_sensitive_keys()
test_redact_payload_handles_nested_lists()
test_redact_payload_handles_sets()
test_redact_payload_handles_plain_strings()
```

### Review fix: wire redaction into Event Center/system logs

The first implementation only added the helper. Review found that real system logs still wrote raw payloads.

Final behavior:

- `emit_system_log()` stores `payload_json=redact_payload(payload)`.
- `normalize_system_log()` redacts again before Event Center output, so existing rows written before this change are protected when displayed.
- `normalize_audit_log()` redacts audit details before Event Center output.

Additional tests:

```python
test_emit_system_log_redacts_sensitive_payload_before_storage()
test_normalize_system_log_redacts_existing_payloads()
test_normalize_audit_log_redacts_existing_details()
```

---

## Task 5: Add CrawlTaskRunner Boundary

**Files:**
- Create: `backend/app/domains/crawling/task_runner.py`
- Modify: `backend/app/domains/jobs/crawl_service.py`
- Modify: `backend/app/domains/crawling/scheduler_service.py`
- Test: `backend/tests/test_crawl_task_runner.py`

- [x] **Step 1: Write failing runner tests**

```python
async def test_runner_executes_single_job_config(monkeypatch)
async def test_runner_marks_failed_job_config(monkeypatch)
```

- [x] **Step 2: Run tests and verify they fail**

- [x] **Step 3: Implement runner**

`CrawlTaskRunner.run_job_config()` and `CrawlTaskRunner.run_all_jobs()`.

- [x] **Step 4: Route job background execution through runner**

In `crawl_single_config_background._run`: `CrawlTaskRunner().run_job_config(task, config_id=config_id)`.

- [x] **Step 5: Run runner and job tests**

- [x] **Step 6: Commit**

### Actual implementation

Identical to plan. Event Center emits were preserved in the caller. Additional tests for `run_all_jobs` and edge cases were added in the integration test file.

---

## Task 6: Inject Profile Roots Into Job Adapters

**Files:**
- Modify: `backend/app/platforms/boss_cloak_experimental.py`
- Modify: `backend/app/platforms/job51.py`
- Test: `backend/tests/test_boss_cloak_experimental.py`
- Test: `backend/tests/test_job_phase3_integration.py`

- [x] **Step 1: Write adapter profile-root tests**

```python
def test_51job_default_profile_uses_configured_profile_root(monkeypatch, tmp_path)
def test_boss_default_profile_uses_configured_profile_root(monkeypatch, tmp_path)
```

- [x] **Step 2: Run tests and verify they fail**

- [x] **Step 3: Update Boss adapter default profile**

- [x] **Step 4: Update 51job adapter default profile**

- [x] **Step 5: Run tests and lint**

- [x] **Step 6: Commit**

### Actual implementation

**Simplified from plan.** Since `build_profile_dir` no longer needs a `root` or `platform` argument:

```python
# Adapter __init__:
self.profile_dir = Path(profile_dir) if profile_dir else build_profile_dir("default")
```

No `from app.config import settings` import needed. Tests changed from monkeypatching `settings` to passing explicit `profile_dir`.

---

## Task 7: Wire Product Crawl Through CrawlTaskRunner

**Files:**
- Modify: `backend/app/domains/crawling/task_runner.py`
- Modify: `backend/app/domains/crawling/scheduler_service.py`
- Test: `backend/tests/test_crawl_task_runner.py`

- [x] **Step 1: Add product runner test**

`test_runner_executes_product_task(monkeypatch)` — mocks `get_active_products` and `crawl_one`.

- [x] **Step 2: Implement product runner method**

`CrawlTaskRunner.run_all_products()` — preserves old product behavior with up to 3 concurrent product crawls and per-product error capture.

- [x] **Step 3: Update product scheduler service**

`_run_crawl_task` now routes through `CrawlTaskRunner().run_all_products(task)`.

- [x] **Step 4: Run tests**

- [x] **Step 5: Commit**

### Actual implementation after review feedback

Initial Phase 1 implementation made `run_all_products()` sequential. Review and user discussion concluded this changed existing product crawl behavior too much for Phase 1.

Final behavior preserves the old product crawl semantics:

- Batch-level product concurrency remains `3`.
- Each product crawl still waits a randomized 2-3s after `_crawl_one(product_id)`.
- Exceptions from individual products are captured as per-product error details and do not abort the batch.
- Result details are returned in active-product order.

Additional test:

```python
async def test_runner_limits_product_concurrency_to_three(monkeypatch)
```

Notable: the mock target was changed from `app.domains.crawling.router._crawl_one` to `app.domains.crawling.service.crawl_one` because the `__init__.py` exports the `APIRouter` instance which shadows the module.

---

## Task 8: Documentation And Final Verification

- [x] Phase 1 tasks marked done in TODO file
- [x] `.env.example` updated with CDP settings
- [x] Integration tests: `test_integration_crawl_phase1.py` (28 tests)
- [x] E2E tests: `test_e2e_crawl_flow.py` (3 tests, requires `RUN_E2E=1`)
- [x] Code review follow-up: profile lease directory locking, product concurrency restoration, runtime log redaction wiring, stricter crawl-now integration tests, and diff whitespace cleanup
- [x] Targeted test suite after review fixes: 82 passed, 2 skipped
- [x] Frontend/backend E2E smoke after review fixes: login, Event Center redaction, product crawl task creation/status, and Event Center completion event verified on 2026-05-25
- [x] Documented in `doc/backend-architecture.md` section 7.6

### Settings removed during simplification

The following were planned but ultimately removed:

| Item | Planned | Final |
|------|---------|-------|
| `PRICE_MONITOR_HOME` env var | Configurable home root | Removed — always project-relative |
| `CRAWLER_PROFILE_ROOT` env var | Override profile root | Removed — always `profiles/{key}` |
| `price_monitor_home` field | Settings field | Removed |
| `crawler_profile_root` field | Settings field | Removed |
| `resolved_price_monitor_home` | Computed property | Removed |
| `resolved_crawler_profile_root` | Computed property | Removed |
| `default_price_monitor_home()` | Cross-platform default | Removed — `_project_root()` via `__file__` |
| `resolve_price_monitor_home()` | Env var / arg resolver | Removed |
| `VALID_PLATFORMS` | Validated set | Removed — no platform-based paths |
| `profiles/{platform}/{key}` | Platform subdirectory | Simplified to `profiles/{key}` |

The remaining env vars / settings (`CDP_ALLOW_NON_LOCAL`, `CDP_ENABLED`, `CDP_URL`) are unchanged.

---

## Self-Review

Spec coverage:

- Profile paths are covered in Task 1 (project-root-relative via `__file__`).
- Creation/execution boundary is covered in Task 5 and Task 7.
- Current FastAPI + APScheduler deployment is preserved by keeping execution in-process.
- CDP safety is covered in Task 3.
- Sensitive logging safety is covered in Task 4.
- Profile lease first slice is covered in Task 2.
- Integration/E2E test coverage added in a follow-up pass.
- Later phases are intentionally out of this implementation plan and remain in the linked TODO file.

Placeholder scan:

- This plan contains no open-ended implementation placeholders.
- Each code-changing task includes concrete files, code snippets, commands, and expected outcomes.

Type consistency:

- `CrawlTaskRunner` methods consistently accept `CrawlTask` and update `TaskStatus`.
- Profile helpers consistently use `profile_key` and `profile_dir`.
- CDP validation consistently uses `allow_non_local`.
