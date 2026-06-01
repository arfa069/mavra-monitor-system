"""Crawler worker CLI.

Usage:
    python -m app.workers.crawler --kind job --platform boss
    python -m app.workers.crawler --kind product --platform jd
    python -m app.workers.crawler --kind all
"""

from __future__ import annotations

import argparse
import asyncio
import logging
import os
import signal
import socket
import sys
import uuid

# Import models to register all mappers before any DB operation
from app import models  # noqa: F401
from app.config import settings
from app.core.system_log import emit_system_log_detached
from app.database import AsyncSessionLocal, engine
from app.domains.crawling.profile_pool import recover_stale_profile_leases
from app.domains.crawling.task_store import (
    claim_next_pending_task,
    recover_stale_running_tasks,
)
from app.domains.crawling.worker_registry import (
    heartbeat_worker,
    mark_stale_workers_offline,
    mark_worker_stopping,
    register_worker,
)
from app.workers.executor import execute_claimed_task

logger = logging.getLogger(__name__)

_shutdown_event: asyncio.Event | None = None


def _signal_handler(signum: int, _frame) -> None:
    global _shutdown_event
    logger.info("Received signal %d, initiating graceful shutdown", signum)
    if _shutdown_event is not None:
        _shutdown_event.set()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--kind", choices=["job", "product", "analysis", "all"], default="all")
    parser.add_argument("--platform", action="append", default=[])
    parser.add_argument("--worker-id", default="")
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--concurrency", type=int, default=None)
    return parser.parse_args()


def _should_run_maintenance(
    *,
    last_run_at: float | None,
    now: float,
    interval_seconds: float,
) -> bool:
    return (
        last_run_at is None
        or interval_seconds <= 0
        or now - last_run_at >= interval_seconds
    )


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


async def _collect_finished_tasks(active_tasks: set[asyncio.Task]) -> list[dict]:
    finished = {task for task in active_tasks if task.done()}
    results: list[dict] = []
    for task in finished:
        active_tasks.discard(task)
        if task.cancelled():
            logger.debug("Task %s was cancelled", task)
            continue
        exc = task.exception()
        if exc:
            logger.error("Task %s failed: %s: %s", task, type(exc).__name__, exc)
            continue
        result = task.result()
        if isinstance(result, dict):
            results.append(result)
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


async def _recover_runtime_state() -> None:
    from app.domains.jobs.crawl_service import aggregate_waiting_job_parent_tasks

    async with AsyncSessionLocal() as db:
        await recover_stale_running_tasks(db, owner_reason="worker_stale_lease")
        await recover_stale_profile_leases(db)
        await mark_stale_workers_offline(
            db,
            stale_after_seconds=settings.crawler_worker_stale_after_seconds,
        )
    await aggregate_waiting_job_parent_tasks()


async def run_worker(args: argparse.Namespace) -> None:
    global _shutdown_event
    _shutdown_event = asyncio.Event()

    # Register signal handlers for graceful shutdown
    signal.signal(signal.SIGTERM, _signal_handler)
    if sys.platform != "win32":
        signal.signal(signal.SIGINT, _signal_handler)

    worker_id = args.worker_id or f"worker:{socket.gethostname()}:{os.getpid()}:{uuid.uuid4().hex[:8]}"
    kinds = {args.kind}
    platforms = set(args.platform) or None
    async with AsyncSessionLocal() as db:
        await register_worker(
            db,
            worker_id=worker_id,
            kind=args.kind,
            platform=",".join(args.platform) if args.platform else None,
            hostname=socket.gethostname(),
            pid=os.getpid(),
        )

    worker_concurrency = _resolve_worker_concurrency(args)
    logger.info(
        "Crawler worker %s started (kind=%s, platforms=%s, concurrency=%d)",
        worker_id, args.kind, args.platform, worker_concurrency,
    )
    await emit_system_log_detached(
        category="runtime",
        event_type="crawler_worker.started",
        source="crawler_worker",
        severity="info",
        status="running",
        message=f"Crawler worker {worker_id} started (kind={args.kind}, platforms={args.platform}, concurrency={worker_concurrency})",
        entity_type="crawler_worker",
        entity_id=worker_id,
        payload={
            "worker_id": worker_id,
            "kind": args.kind,
            "platforms": args.platform,
            "concurrency": worker_concurrency,
        },
    )

    active_tasks: set[asyncio.Task] = set()
    last_maintenance_at: float | None = None

    try:
        while not _shutdown_event.is_set():
            loop_time = asyncio.get_running_loop().time()
            if _should_run_maintenance(
                last_run_at=last_maintenance_at,
                now=loop_time,
                interval_seconds=settings.crawler_worker_maintenance_interval_seconds,
            ):
                await _recover_runtime_state()
                last_maintenance_at = loop_time

            async with AsyncSessionLocal() as db:
                hb = await heartbeat_worker(db, worker_id)
                if hb is None:
                    await emit_system_log_detached(
                        category="runtime",
                        event_type="crawler_worker.heartbeat_failed",
                        source="crawler_worker",
                        severity="warning",
                        status="warning",
                        message=f"Worker {worker_id} heartbeat returned None",
                        entity_type="crawler_worker",
                        entity_id=worker_id,
                        payload={"worker_id": worker_id},
                    )

            await _collect_finished_tasks(active_tasks)

            if args.once:
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
                    await _collect_finished_tasks(active_tasks)
                return

            await _claim_until_capacity(
                worker_id=worker_id,
                kinds=kinds,
                platforms=platforms,
                active_tasks=active_tasks,
                concurrency=worker_concurrency,
            )

            if len(active_tasks) >= worker_concurrency:
                done, _pending = await asyncio.wait(
                    active_tasks,
                    timeout=settings.crawler_worker_poll_interval_seconds,
                    return_when=asyncio.FIRST_COMPLETED,
                )
                await _collect_finished_tasks(active_tasks)
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
                await _collect_finished_tasks(active_tasks)
    finally:
        for task in active_tasks:
            if not task.done():
                task.cancel()
        if active_tasks:
            await asyncio.gather(*active_tasks, return_exceptions=True)
        async with AsyncSessionLocal() as db:
            await mark_worker_stopping(db, worker_id)
        await engine.dispose()
        await emit_system_log_detached(
            category="runtime",
            event_type="crawler_worker.stopped",
            source="crawler_worker",
            severity="info",
            status="stopped",
            message=f"Crawler worker {worker_id} stopped",
            entity_type="crawler_worker",
            entity_id=worker_id,
            payload={"worker_id": worker_id},
        )


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    asyncio.run(run_worker(_parse_args()))


if __name__ == "__main__":
    main()
