from __future__ import annotations

import asyncio
from types import SimpleNamespace

import pytest

from app.workers import crawler


def test_should_run_maintenance_respects_interval():
    should_run = getattr(crawler, "_should_run_maintenance", None)

    assert should_run is not None
    assert should_run(last_run_at=None, now=100.0, interval_seconds=60.0)
    assert not should_run(last_run_at=80.0, now=100.0, interval_seconds=60.0)
    assert should_run(last_run_at=39.0, now=100.0, interval_seconds=60.0)


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


@pytest.mark.asyncio
async def test_collect_finished_tasks_handles_successful_task():
    async def success():
        return {"status": "completed"}

    task = asyncio.create_task(success())
    await asyncio.sleep(0)  # let task finish
    active_tasks: set[asyncio.Task] = {task}

    results = await crawler._collect_finished_tasks(active_tasks)

    assert len(results) == 1
    assert results[0]["status"] == "completed"
    assert len(active_tasks) == 0  # task removed from set


@pytest.mark.asyncio
async def test_collect_finished_tasks_handles_failed_task_gracefully():
    async def fail():
        raise RuntimeError("task crashed")

    task = asyncio.create_task(fail())
    await asyncio.sleep(0)  # let task finish (with exception)
    active_tasks: set[asyncio.Task] = {task}

    # Should not raise — must handle task exceptions gracefully
    results = await crawler._collect_finished_tasks(active_tasks)

    assert len(results) == 0
    assert len(active_tasks) == 0  # failed task still removed


@pytest.mark.asyncio
async def test_collect_finished_tasks_handles_cancelled_task_gracefully():
    async def slow():
        await asyncio.sleep(10)

    task = asyncio.create_task(slow())
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass
    active_tasks: set[asyncio.Task] = {task}

    results = await crawler._collect_finished_tasks(active_tasks)

    assert len(results) == 0
    assert len(active_tasks) == 0
