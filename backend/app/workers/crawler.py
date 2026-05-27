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
    parser.add_argument("--kind", choices=["job", "product", "all"], default="all")
    parser.add_argument("--platform", action="append", default=[])
    parser.add_argument("--worker-id", default="")
    parser.add_argument("--once", action="store_true")
    return parser.parse_args()


async def _recover_runtime_state() -> None:
    async with AsyncSessionLocal() as db:
        await recover_stale_running_tasks(db, owner_reason="worker_stale_lease")
        await recover_stale_profile_leases(db)
        await mark_stale_workers_offline(
            db,
            stale_after_seconds=settings.crawler_worker_stale_after_seconds,
        )


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

    await emit_system_log_detached(
        category="runtime",
        event_type="crawler_worker.started",
        source="crawler_worker",
        severity="info",
        status="running",
        message=f"Crawler worker {worker_id} started (kind={args.kind}, platforms={args.platform})",
        entity_type="crawler_worker",
        entity_id=worker_id,
        payload={"worker_id": worker_id, "kind": args.kind, "platforms": args.platform},
    )

    active_task: asyncio.Task | None = None

    try:
        while not _shutdown_event.is_set():
            await _recover_runtime_state()
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
                record = await claim_next_pending_task(
                    db,
                    worker_id=worker_id,
                    kinds=kinds,
                    platforms=platforms,
                    lease_seconds=settings.crawler_task_lease_seconds,
                )
            if record is None:
                if args.once:
                    return
                try:
                    await asyncio.wait_for(
                        _shutdown_event.wait(),
                        timeout=settings.crawler_worker_poll_interval_seconds,
                    )
                except TimeoutError:
                    pass
                continue
            active_task = asyncio.create_task(
                execute_claimed_task(record, worker_id=worker_id)
            )
            result = await active_task
            active_task = None
            if result.get("status") == "deferred":
                try:
                    await asyncio.wait_for(
                        _shutdown_event.wait(),
                        timeout=settings.crawler_worker_poll_interval_seconds,
                    )
                except TimeoutError:
                    pass
            if args.once:
                return
    finally:
        if active_task is not None and not active_task.done():
            active_task.cancel()
            try:
                await active_task
            except asyncio.CancelledError:
                pass
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
