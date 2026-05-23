"""In-memory crawl task registry."""

import asyncio
import uuid
from dataclasses import dataclass, field
from enum import Enum
from typing import Literal


class TaskStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass
class CrawlTask:
    """Represents a crawl task with its status and results."""

    task_id: str
    status: TaskStatus = TaskStatus.PENDING
    source: str = "manual"
    total: int = 0
    success: int = 0
    errors: int = 0
    details: list = field(default_factory=list)
    reason: str | None = None
    user_id: int | None = None
    entity_type: str | None = None
    entity_id: str | None = None
    created_at: float = field(default_factory=lambda: asyncio.get_event_loop().time())


_crawl_tasks: dict[str, CrawlTask] = {}


def _gc_expired_tasks() -> None:
    """Evict completed/failed tasks older than 24 hours to prevent memory leaks."""
    try:
        loop = asyncio.get_running_loop()
        now = loop.time()
    except RuntimeError:
        return

    expired_ids = []
    for tid, task in _crawl_tasks.items():
        if task.status in (TaskStatus.COMPLETED, TaskStatus.FAILED):
            if now - task.created_at > 86400:
                expired_ids.append(tid)

    for tid in expired_ids:
        _crawl_tasks.pop(tid, None)

    if len(_crawl_tasks) > 1000:
        finished_tasks = sorted(
            [
                task
                for task in _crawl_tasks.values()
                if task.status in (TaskStatus.COMPLETED, TaskStatus.FAILED)
            ],
            key=lambda task: task.created_at,
        )
        to_evict = len(_crawl_tasks) - 1000
        for index in range(min(to_evict, len(finished_tasks))):
            _crawl_tasks.pop(finished_tasks[index].task_id, None)


def get_task(task_id: str) -> CrawlTask | None:
    """Get task by ID."""
    return _crawl_tasks.get(task_id)


def create_task(
    source: Literal["cron", "manual"],
    *,
    user_id: int | None = None,
    entity_type: str | None = None,
    entity_id: str | None = None,
) -> CrawlTask:
    """Create a new crawl task and return its info."""
    _gc_expired_tasks()
    task_id = str(uuid.uuid4())[:8]
    task = CrawlTask(
        task_id=task_id,
        source=source,
        user_id=user_id,
        entity_type=entity_type,
        entity_id=entity_id,
    )
    _crawl_tasks[task_id] = task
    return task
