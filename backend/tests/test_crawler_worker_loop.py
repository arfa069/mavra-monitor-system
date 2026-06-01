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
