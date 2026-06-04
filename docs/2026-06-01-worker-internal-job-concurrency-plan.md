# Worker Internal Job Concurrency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow one crawler worker process to concurrently process Boss, 51job, and Liepin job crawl child tasks while preserving the existing durable task, lease, retry, and parent aggregation model.

**Architecture:** Keep the current `job_all -> job_platform_profile` parent/child task split. Add worker-level task concurrency so a single worker can claim and run multiple pending child tasks up to a configured limit. Keep profile leases exclusive, so true three-site concurrency requires separate profile keys per platform.

**Tech Stack:** Python 3.13, asyncio, FastAPI backend worker modules, SQLAlchemy async sessions, pytest-asyncio, existing GitNexus workflow.

---

## Implementation Notes

Current state:

- `backend/app/workers/crawler.py` has a single `active_task` and awaits it before claiming another task.
- `backend/app/domains/crawling/task_store.py` claims one pending task per DB transaction with `limit(1)`.
- `backend/app/domains/jobs/crawl_service.py` already splits `job_all` into `job_platform_profile` child tasks by `(platform, profile_key)`.
- `backend/app/domains/crawling/profile_pool.py` leases profiles by `profile_key`, so tasks sharing a profile key remain mutually exclusive.
- `backend/app/platforms/job51.py` already runs blocking crawl work through `asyncio.to_thread`.
- `backend/app/platforms/liepin.py` currently calls synchronous `_crawl_search_http()` directly from `async def crawl()`, which can block the worker event loop.

Default behavior must remain unchanged: one worker runs one task at a time unless concurrency is explicitly configured.

## File Structure

- Modify `backend/app/config.py`: add default worker concurrency setting.
- Modify `backend/app/workers/crawler.py`: add CLI argument, concurrency resolution helper, multi-active-task loop, and graceful shutdown for multiple tasks.
- Modify `backend/app/platforms/liepin.py`: move synchronous HTTP crawl to `asyncio.to_thread`.
- Modify `backend/tests/test_crawler_worker_loop.py`: add focused unit tests for concurrency helper and task claiming helper.
- Modify `backend/tests/test_liepin_adapter.py`: add test proving `LiepinAdapter.crawl()` uses `asyncio.to_thread`.
- Run existing worker/job tests to verify task claim, executor, and parent/child semantics are unchanged.

## Task 0: Pre-Change Impact Check

**Files:**

- Inspect: `backend/app/workers/crawler.py`
- Inspect: `backend/app/platforms/liepin.py`
- Inspect: `backend/app/domains/crawling/task_store.py`
- Inspect: `backend/app/domains/jobs/crawl_service.py`

- [ ] **Step 1: Refresh GitNexus if it reports staleness**

Run from repository root:

```powershell
npx gitnexus analyze
```

Expected: repository indexed successfully.

- [ ] **Step 2: Run GitNexus impact checks before symbol edits**

Use GitNexus impact analysis for these symbols before editing them:

```text
impact({ target: "run_worker", direction: "upstream", repo: "price-monitor" })
impact({ target: "LiepinAdapter.crawl", direction: "upstream", repo: "price-monitor" })
```

Expected: review any HIGH or CRITICAL impact before continuing. This feature intentionally touches worker runtime behavior, so worker tests must cover the change.

## Task 1: Add Worker Concurrency Configuration

**Files:**

- Modify: `backend/app/config.py`
- Modify: `backend/app/workers/crawler.py`
- Test: `backend/tests/test_crawler_worker_loop.py`

- [ ] **Step 1: Write failing tests for concurrency resolution**

Append these tests to `backend/tests/test_crawler_worker_loop.py`:

```python
from types import SimpleNamespace


def test_resolve_worker_concurrency_prefers_cli_value(monkeypatch):
    monkeypatch.setattr(crawler.settings, "crawler_worker_concurrency", 1)

    assert crawler._resolve_worker_concurrency(SimpleNamespace(concurrency=3)) == 3


def test_resolve_worker_concurrency_uses_settings_default(monkeypatch):
    monkeypatch.setattr(crawler.settings, "crawler_worker_concurrency", 2)

    assert crawler._resolve_worker_concurrency(SimpleNamespace(concurrency=None)) == 2


def test_resolve_worker_concurrency_clamps_to_one(monkeypatch):
    monkeypatch.setattr(crawler.settings, "crawler_worker_concurrency", 0)

    assert crawler._resolve_worker_concurrency(SimpleNamespace(concurrency=None)) == 1
    assert crawler._resolve_worker_concurrency(SimpleNamespace(concurrency=0)) == 1
    assert crawler._resolve_worker_concurrency(SimpleNamespace(concurrency=-5)) == 1
```

- [ ] **Step 2: Run tests and confirm they fail**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
pytest tests/test_crawler_worker_loop.py -v
```

Expected: failure because `_resolve_worker_concurrency` does not exist.

- [ ] **Step 3: Add the setting**

In `backend/app/config.py`, inside `Settings` under the crawler worker settings block, add:

```python
    crawler_worker_concurrency: int = 1
```

- [ ] **Step 4: Add CLI argument and resolver helper**

In `backend/app/workers/crawler.py`, update `_parse_args()`:

```python
    parser.add_argument("--concurrency", type=int, default=None)
```

Add this helper near `_should_run_maintenance()`:

```python
def _resolve_worker_concurrency(args: argparse.Namespace) -> int:
    configured = (
        args.concurrency
        if getattr(args, "concurrency", None) is not None
        else settings.crawler_worker_concurrency
    )
    try:
        return max(1, int(configured))
    except (TypeError, ValueError):
        logger.warning("Invalid crawler worker concurrency %r; using 1", configured)
        return 1
```

- [ ] **Step 5: Verify tests pass**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
pytest tests/test_crawler_worker_loop.py -v
```

Expected: all tests in `test_crawler_worker_loop.py` pass.

## Task 2: Claim Multiple Tasks Per Worker Process

**Files:**

- Modify: `backend/app/workers/crawler.py`
- Test: `backend/tests/test_crawler_worker_loop.py`

- [ ] **Step 1: Write failing tests for the claim helper**

Append these tests to `backend/tests/test_crawler_worker_loop.py`:

```python
import asyncio
from types import SimpleNamespace

import pytest


class _FakeSession:
    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb):
        return False


@pytest.mark.asyncio
async def test_claim_until_capacity_claims_up_to_concurrency(monkeypatch):
    claimed_records = [
        SimpleNamespace(task_id="task-1"),
        SimpleNamespace(task_id="task-2"),
        SimpleNamespace(task_id="task-3"),
        SimpleNamespace(task_id="task-4"),
    ]
    executed = []

    async def fake_claim_next_pending_task(*_args, **_kwargs):
        return claimed_records.pop(0) if claimed_records else None

    async def fake_execute_claimed_task(record, *, worker_id):
        executed.append((record.task_id, worker_id))
        await asyncio.sleep(0)
        return {"status": "completed"}

    monkeypatch.setattr(crawler, "AsyncSessionLocal", lambda: _FakeSession())
    monkeypatch.setattr(crawler, "claim_next_pending_task", fake_claim_next_pending_task)
    monkeypatch.setattr(crawler, "execute_claimed_task", fake_execute_claimed_task)

    active_tasks: set[asyncio.Task] = set()

    claimed_count = await crawler._claim_until_capacity(
        worker_id="worker-test",
        kinds={"job"},
        platforms=None,
        active_tasks=active_tasks,
        concurrency=3,
    )

    assert claimed_count == 3
    assert len(active_tasks) == 3

    done, _pending = await asyncio.wait(active_tasks)
    assert len(done) == 3
    assert executed == [
        ("task-1", "worker-test"),
        ("task-2", "worker-test"),
        ("task-3", "worker-test"),
    ]


@pytest.mark.asyncio
async def test_claim_until_capacity_respects_existing_active_tasks(monkeypatch):
    claimed_records = [SimpleNamespace(task_id="task-1"), SimpleNamespace(task_id="task-2")]

    async def fake_claim_next_pending_task(*_args, **_kwargs):
        return claimed_records.pop(0) if claimed_records else None

    async def fake_execute_claimed_task(record, *, worker_id):
        await asyncio.sleep(0)
        return {"status": "completed", "task_id": record.task_id, "worker_id": worker_id}

    monkeypatch.setattr(crawler, "AsyncSessionLocal", lambda: _FakeSession())
    monkeypatch.setattr(crawler, "claim_next_pending_task", fake_claim_next_pending_task)
    monkeypatch.setattr(crawler, "execute_claimed_task", fake_execute_claimed_task)

    existing_task = asyncio.create_task(asyncio.sleep(0.01))
    active_tasks: set[asyncio.Task] = {existing_task}

    claimed_count = await crawler._claim_until_capacity(
        worker_id="worker-test",
        kinds={"job"},
        platforms=None,
        active_tasks=active_tasks,
        concurrency=2,
    )

    assert claimed_count == 1
    assert len(active_tasks) == 2

    await asyncio.gather(*active_tasks)
```

- [ ] **Step 2: Run tests and confirm they fail**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
pytest tests/test_crawler_worker_loop.py -v
```

Expected: failure because `_claim_until_capacity` does not exist.

- [ ] **Step 3: Add task collection helpers**

In `backend/app/workers/crawler.py`, add:

```python
async def _collect_finished_tasks(active_tasks: set[asyncio.Task]) -> list[dict]:
    finished = {task for task in active_tasks if task.done()}
    results: list[dict] = []
    for task in finished:
        active_tasks.discard(task)
        results.append(await task)
    return results


async def _claim_until_capacity(
    *,
    worker_id: str,
    kinds: set[str],
    platforms: set[str] | None,
    active_tasks: set[asyncio.Task],
    concurrency: int,
) -> int:
    claimed_count = 0
    while len(active_tasks) < concurrency:
        async with AsyncSessionLocal() as db:
            record = await claim_next_pending_task(
                db,
                worker_id=worker_id,
                kinds=kinds,
                platforms=platforms,
                lease_seconds=settings.crawler_task_lease_seconds,
            )
        if record is None:
            break
        active_tasks.add(asyncio.create_task(
            execute_claimed_task(record, worker_id=worker_id)
        ))
        claimed_count += 1
    return claimed_count
```

- [ ] **Step 4: Replace single active task loop**

In `run_worker()`, replace `active_task: asyncio.Task | None = None` with:

```python
    worker_concurrency = _resolve_worker_concurrency(args)
    active_tasks: set[asyncio.Task] = set()
    last_maintenance_at: float | None = None
```

Update the startup log payload to include concurrency:

```python
        payload={
            "worker_id": worker_id,
            "kind": args.kind,
            "platforms": args.platform,
            "concurrency": worker_concurrency,
        },
```

Replace the core claim/execute section of the loop with this behavior:

```python
            await _collect_finished_tasks(active_tasks)

            if not args.once:
                await _claim_until_capacity(
                    worker_id=worker_id,
                    kinds=kinds,
                    platforms=platforms,
                    active_tasks=active_tasks,
                    concurrency=worker_concurrency,
                )
            else:
                if not active_tasks:
                    claimed_count = await _claim_until_capacity(
                        worker_id=worker_id,
                        kinds=kinds,
                        platforms=platforms,
                        active_tasks=active_tasks,
                        concurrency=1,
                    )
                    if claimed_count == 0:
                        return
                if active_tasks:
                    done, _pending = await asyncio.wait(active_tasks)
                    active_tasks.difference_update(done)
                return

            if len(active_tasks) >= worker_concurrency:
                done, _pending = await asyncio.wait(
                    active_tasks,
                    timeout=settings.crawler_worker_poll_interval_seconds,
                    return_when=asyncio.FIRST_COMPLETED,
                )
                active_tasks.difference_update(done)
                for task in done:
                    await task
                continue

            if not active_tasks:
                try:
                    await asyncio.wait_for(
                        _shutdown_event.wait(),
                        timeout=settings.crawler_worker_poll_interval_seconds,
                    )
                except TimeoutError:
                    pass
            else:
                done, _pending = await asyncio.wait(
                    active_tasks,
                    timeout=settings.crawler_worker_poll_interval_seconds,
                    return_when=asyncio.FIRST_COMPLETED,
                )
                active_tasks.difference_update(done)
                for task in done:
                    await task
```

The final implementation can be cleaner than this block, but it must preserve these decisions:

- claim repeatedly until `len(active_tasks) == worker_concurrency` or no task is available;
- never change `claim_next_pending_task(... limit(1))`;
- `--once` always claims at most one task and exits after it finishes;
- a failed child task must not cancel other active child tasks;
- profile-busy requeue remains handled by `execute_claimed_task()`.

- [ ] **Step 5: Update shutdown handling**

Replace the `finally` block that cancels one `active_task` with:

```python
        for task in active_tasks:
            if not task.done():
                task.cancel()
        if active_tasks:
            await asyncio.gather(*active_tasks, return_exceptions=True)
```

Keep the existing `mark_worker_stopping()`, `engine.dispose()`, and stopped event emission after this cancellation block.

- [ ] **Step 6: Verify focused worker loop tests**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
pytest tests/test_crawler_worker_loop.py -v
```

Expected: all worker loop tests pass.

## Task 3: Move Liepin Blocking Search Into a Thread

**Files:**

- Modify: `backend/app/platforms/liepin.py`
- Test: `backend/tests/test_liepin_adapter.py`

- [ ] **Step 1: Write failing test for threaded Liepin crawl**

Append this test to `backend/tests/test_liepin_adapter.py`:

```python
@pytest.mark.asyncio
async def test_liepin_crawl_runs_search_http_in_worker_thread(monkeypatch):
    from app.platforms import liepin as liepin_module
    from app.platforms.liepin import LiepinAdapter

    captured: dict[str, object] = {}

    async def fake_to_thread(func, *args):
        captured["func_name"] = func.__name__
        captured["args"] = args
        return {"success": True, "count": 0, "jobs": []}

    monkeypatch.setattr(liepin_module.asyncio, "to_thread", fake_to_thread)

    result = await LiepinAdapter().crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is True
    assert captured == {
        "func_name": "_crawl_search_http",
        "args": ("python", "020"),
    }
```

- [ ] **Step 2: Run test and confirm it fails**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
pytest tests/test_liepin_adapter.py::test_liepin_crawl_runs_search_http_in_worker_thread -v
```

Expected: failure because `app.platforms.liepin` does not import `asyncio` or does not call `asyncio.to_thread`.

- [ ] **Step 3: Update Liepin adapter**

In `backend/app/platforms/liepin.py`, add the import:

```python
import asyncio
```

In `LiepinAdapter.crawl()`, replace:

```python
        http_result = self._crawl_search_http(keyword, city)
```

with:

```python
        http_result = await asyncio.to_thread(self._crawl_search_http, keyword, city)
```

- [ ] **Step 4: Verify Liepin tests**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
pytest tests/test_liepin_adapter.py -v
```

Expected: all Liepin adapter tests pass or existing skipped CDP fallback tests remain skipped.

## Task 4: Validate Job Parent/Child Concurrency Semantics

**Files:**

- Modify only if needed: `backend/tests/test_crawler_worker_executor.py`
- Modify only if needed: `backend/tests/test_job_crawl_profile_grouping.py`
- No production change expected in `backend/app/domains/jobs/crawl_service.py`

- [ ] **Step 1: Re-run existing grouping tests**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
pytest tests/test_job_crawl_profile_grouping.py -v
```

Expected:

- configs group by `(platform, profile_key)`;
- same profile key remains a serial lane in the grouping helper;
- different profile keys can become separate child tasks.

- [ ] **Step 2: Re-run executor tests**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
pytest tests/test_crawler_worker_executor.py -v
```

Expected:

- `job_all` still returns `waiting_for_children`;
- parent lease is released while children run;
- `job_platform_profile` profile-busy behavior still requeues through `execute_claimed_task()`;
- job match analysis dispatch remains unaffected.

- [ ] **Step 3: Add no production changes to job split logic unless tests expose a regression**

If existing tests pass, leave `enqueue_job_all_children()` and `execute_job_platform_profile_task()` unchanged. The concurrency change belongs in the worker scheduler, not inside `job_all`.

## Task 5: Full Verification

**Files:**

- Verify: worker, task, job grouping, Liepin adapter tests.
- Inspect: Git diff and GitNexus changed-flow report.

- [ ] **Step 1: Run focused regression suite**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
pytest tests/test_crawl_task_claiming.py tests/test_crawler_worker_executor.py tests/test_crawl_task_runner.py tests/test_crawler_worker_loop.py tests/test_job_crawl_profile_grouping.py tests/test_liepin_adapter.py -v
```

Expected: all non-skipped tests pass.

- [ ] **Step 2: Run lint if backend lint is part of the current branch gate**

Run:

```powershell
cd C:/Users/arfac/price-monitor/backend
ruff check .
```

Expected: no lint errors introduced by this change.

- [ ] **Step 3: Run GitNexus detect changes before commit**

Run GitNexus change detection:

```text
detect_changes({ repo: "price-monitor", scope: "all" })
```

Expected: affected flows are limited to crawler worker runtime, Liepin adapter crawl, and their tests. Any HIGH or CRITICAL impact must be reviewed before commit.

- [ ] **Step 4: Manual runtime smoke command**

After tests pass, run one local worker in one-shot mode to verify CLI parsing:

```powershell
cd C:/Users/arfac/price-monitor/backend
python -m app.workers.crawler --kind job --concurrency 3 --once
```

Expected:

- worker starts without argument parsing errors;
- if no pending task exists, worker exits cleanly;
- if one pending task exists, worker processes exactly one task because `--once` overrides concurrency to one claim.

## Operational Guidance

To run one worker that can process the three job websites concurrently:

```powershell
cd C:/Users/arfac/price-monitor/backend
python -m app.workers.crawler --kind job --concurrency 3
```

Required profile setup for real three-site concurrency:

- Boss config uses a Boss-specific profile key, for example `boss-default`.
- 51job config uses a 51job-specific profile key, for example `51job-default`.
- Liepin config uses a Liepin-specific profile key, for example `liepin-default`.

If all three platforms use `default`, the profile lease system will correctly prevent concurrent browser/profile usage. In that case the worker may claim tasks concurrently, but tasks sharing the same profile key will defer or requeue through existing profile-busy handling.

## Commit Plan

Commit after tests pass:

```powershell
git add backend/app/config.py backend/app/workers/crawler.py backend/app/platforms/liepin.py backend/tests/test_crawler_worker_loop.py backend/tests/test_liepin_adapter.py docs/2026-06-01-worker-internal-job-concurrency-plan.md
git commit -m "feat: add worker internal job crawl concurrency"
```

Do not commit if focused worker, executor, grouping, or Liepin tests fail.
