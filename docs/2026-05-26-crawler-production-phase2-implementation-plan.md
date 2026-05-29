# Crawler Production Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist crawler task state and browser profile leases so crawl status survives API restarts and profile usage can be coordinated across future workers.

**Architecture:** FastAPI and APScheduler still create and execute crawl work in the current API process. Crawl task records and profile lease records move into PostgreSQL through async SQLAlchemy, while the existing in-memory task registry remains for non-crawler async jobs such as match analysis. Job all-crawl becomes a parent task that creates one child execution task per platform, because each execution task must own at most one platform and one leased profile.

**Tech Stack:** Python 3.13, FastAPI, APScheduler, async SQLAlchemy, Alembic, PostgreSQL, pytest, ruff, Windows PowerShell.

---

## Scope Check

This plan covers **Phase 2 only** from [docs/2026-05-25-crawler-production-todo.md](2026-05-25-crawler-production-todo.md).

In scope:

- Add persistent `crawl_tasks` and `crawl_profiles` tables.
- Route product and job crawl task creation/status/result through `crawl_tasks`.
- Represent job all-crawl as a parent `job_all` task plus child `job_platform` tasks.
- Add a database-backed Profile Pool / Profile Lease implementation.
- Use profile leases in job crawl task execution so the same profile directory cannot be used by two job crawler tasks at the same time.
- Add stale running task/profile recovery at API startup.
- Keep current in-process execution through FastAPI/APScheduler.

Out of scope:

- Independent crawler worker process. That remains Phase 5.
- Platform-specific crawler strategy changes for Boss, 51job, Liepin, JD, Taobao, or Amazon. Those remain Phase 3 and Phase 4.
- Moving match analysis tasks from `app.core.task_registry`; `/jobs/tasks/{task_id}` keeps using the in-memory registry in this phase.
- Frontend redesign. Existing polling endpoints keep the same response shape, so UI changes should be limited to API type tolerance if a task id becomes longer.

## Current Behavior To Preserve

- `POST /api/v1/crawl/crawl-now` still returns immediately with `{status: "pending", task_id, message}`.
- `GET /api/v1/crawl/status/{task_id}` and `GET /api/v1/crawl/result/{task_id}` keep their current JSON shapes.
- `POST /api/v1/jobs/crawl-now` and `POST /api/v1/jobs/crawl-now/{config_id}` still return immediately with a task id.
- `GET /api/v1/jobs/crawl/status/{task_id}` and `GET /api/v1/jobs/crawl/result/{task_id}` keep their current JSON shapes.
- Product all-crawl still runs up to 3 products concurrently with the existing 2-3s randomized post-crawl interval.
- Product crawls do not use Profile Pool in Phase 2. Product profile ownership remains Phase 4.
- Job all-crawl still groups configs by platform, but persistence models it as one parent task and one child task per platform.
- Product and job scheduled crawls still execute inside APScheduler in the API process.
- Event Center logging remains best effort and uses existing redaction.

## Test Fixture Rules

Do not assume global `client`, `auth_headers`, or `db_session` fixtures exist. The current test suite mostly uses:

- `ASGITransport(app=app)` plus `AsyncClient` for API tests.
- `app.dependency_overrides[get_current_user]` for authenticated users.
- `app.dependency_overrides[get_db]` with an explicit session or mock session.
- Real database tests only when the test explicitly opens `AsyncSessionLocal`; tests that require local PostgreSQL should say so and should clean up rows they create.

New Phase 2 tests must either define their own local fixtures in `backend/tests/test_integration_crawl_phase2.py` or follow the explicit setup style used by `backend/tests/test_integration_crawl_phase1.py`.

## Data Model Decisions

`crawl_tasks.task_id` should use `uuid.uuid4().hex` instead of the old 8-character id. Existing frontend code treats task ids as strings, so this does not change the contract, and it reduces guessing risk now that tasks survive restarts.

`crawl_tasks.parent_task_id` links child execution tasks to a parent orchestration task. Product all-crawl and single job config crawls have no parent. Job all-crawl creates a `job_all` parent and one `job_platform` child per platform.

`crawl_tasks.details_json` and `crawl_tasks.payload_json` use PostgreSQL `JSONB`, matching `SystemLog.payload_json`.

`crawl_profiles.profile_key` is globally unique. A profile can contain login state for many platforms, but only one task may lease that profile at a time.

Profile lease storage uses the database in Phase 2. Redis locking is not introduced in this phase because task state, profile state, recovery, and Event Center debugging all benefit from a single durable source of truth. Redis can be added in Phase 5 if multiple independent crawler workers create measurable DB contention.

Profile acquisition must be atomic. The implementation must use row locking or a conditional update so two concurrent processes cannot both acquire the same profile. A plain `select -> check -> update` sequence is not acceptable.

Running task and profile leases must be renewed while work is active. Long crawls should update `heartbeat_at` and extend `lease_until` every 30-60 seconds so startup recovery does not steal an active profile.

## File Structure

- Create: `backend/app/models/crawl_task.py`
  - SQLAlchemy model for persistent crawl task records.
- Create: `backend/app/models/crawl_profile.py`
  - SQLAlchemy model for profile pool records and lease metadata.
- Modify: `backend/app/models/__init__.py`
  - Export `CrawlTaskRecord` and `CrawlProfile`.
- Create: `backend/alembic/versions/2026_05_26_add_crawl_tasks_and_profiles.py`
  - Creates `crawl_tasks` and `crawl_profiles` with indexes.
- Create: `backend/app/domains/crawling/task_store.py`
  - Persistent task CRUD, runtime task conversion, progress sync, stale task recovery.
- Create: `backend/app/domains/crawling/profile_pool.py`
  - DB-backed profile creation, acquire, release, stale lease recovery.
- Modify: `backend/app/domains/crawling/task_runner.py`
  - Add optional progress callback.
- Modify: `backend/app/domains/crawling/router.py`
  - Product crawl status/result endpoints read `crawl_tasks`.
- Modify: `backend/app/domains/crawling/scheduler_service.py`
  - Manual and scheduled product crawls create/update persistent crawl tasks.
- Modify: `backend/app/domains/jobs/crawl_service.py`
  - Manual and scheduled job crawls create/update persistent crawl tasks; all-crawl creates parent/child tasks.
- Modify: `backend/app/domains/jobs/router.py`
  - Job crawl status/result endpoints read `crawl_tasks`; match analysis endpoints stay on `task_registry`.
- Modify: `backend/app/main.py`
  - Run stale task/profile recovery during startup before APScheduler starts.
- Test: `backend/tests/test_crawl_task_store.py`
- Test: `backend/tests/test_profile_pool.py`
- Test: `backend/tests/test_crawl_task_runner.py`
- Test: `backend/tests/test_integration_crawl_phase2.py`
- Test: update `backend/tests/test_integration_crawl_phase1.py` and `backend/tests/test_phase_c_integration.py` where task ids or persistence assertions change.
- Update: `README.md`, `ARCHITECTURE.md`, `doc/backend-architecture.md`, and `docs/2026-05-25-crawler-production-todo.md` after implementation.

## Edge Cases

- API process restarts while a task is `running`: startup recovery marks expired rows as `failed` with reason `worker_restarted`.
- API process crashes while a profile is leased: startup recovery clears expired profile leases and emits a profile status event.
- A long task runs beyond the initial lease period: heartbeat renews task and profile leases before expiry.
- A task completes but Event Center logging fails: task status remains committed.
- A task fails while holding a profile lease: `finally` releases the profile lease.
- Two concurrent job tasks request the same `profile_key`: the second task fails fast with `profile_already_leased`.
- Two concurrent job tasks request different `profile_key` values: both may proceed if the global job lock permits their task type.
- Product tasks do not request a `profile_key` in Phase 2.
- A profile is `login_required`, `cooling_down`, or `disabled`: acquisition fails with a typed error and the task is marked failed with that reason.
- `crawl_tasks.details_json` may be large for product all-crawl. Store it as JSONB, keep existing endpoint output, and do not add list endpoints that dump all details.
- Existing 8-character task ids from memory before deployment are not recoverable after restart. This is acceptable because Phase 2 starts persistence from the new deployment forward.
- Match analysis task status must not be routed to `crawl_tasks`; it remains under `/jobs/tasks/{task_id}` and the in-memory registry.

---

## Task 1: Add Persistent Crawl Models And Migration

**Files:**

- Create: `backend/app/models/crawl_task.py`
- Create: `backend/app/models/crawl_profile.py`
- Modify: `backend/app/models/__init__.py`
- Create: `backend/alembic/versions/2026_05_26_add_crawl_tasks_and_profiles.py`
- Test: `backend/tests/test_crawl_task_store.py`
- Test: `backend/tests/test_profile_pool.py`

- [ ] **Step 1: Write model shape tests**

Create `backend/tests/test_crawl_task_store.py` with the first model-level assertions:

```python
from datetime import UTC, datetime


def test_crawl_task_model_table_name_and_required_columns():
    from app.models.crawl_task import CrawlTaskRecord

    columns = CrawlTaskRecord.__table__.columns

    assert CrawlTaskRecord.__tablename__ == "crawl_tasks"
    assert columns["task_id"].nullable is False
    assert "parent_task_id" in columns
    assert "profile_key" in columns
    assert columns["task_type"].nullable is False
    assert columns["status"].nullable is False
    assert columns["created_at"].nullable is False


def test_crawl_task_defaults_are_explicit():
    from app.models.crawl_task import CrawlTaskRecord

    now = datetime.now(UTC)
    task = CrawlTaskRecord(
        task_id="task-1",
        task_type="product_all",
        source="manual",
        status="pending",
        created_at=now,
        updated_at=now,
    )

    assert task.total == 0
    assert task.success == 0
    assert task.errors == 0
```

Create `backend/tests/test_profile_pool.py` with the first profile model assertion:

```python
def test_crawl_profile_model_table_name_and_required_columns():
    from app.models.crawl_profile import CrawlProfile

    columns = CrawlProfile.__table__.columns

    assert CrawlProfile.__tablename__ == "crawl_profiles"
    assert columns["profile_key"].nullable is False
    assert columns["profile_dir"].nullable is False
    assert columns["status"].nullable is False
```

- [ ] **Step 2: Run model tests to verify failure**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_task_store.py tests/test_profile_pool.py -q"
```

Expected: fails with `ModuleNotFoundError: No module named 'app.models.crawl_task'` and `No module named 'app.models.crawl_profile'`.

- [ ] **Step 3: Add model files**

Create `backend/app/models/crawl_task.py`:

```python
"""Persistent crawler task model."""

from sqlalchemy import Column, DateTime, ForeignKey, Index, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB

from app.models.base import Base


class CrawlTaskRecord(Base):
    """Durable task state for product and job crawls."""

    __tablename__ = "crawl_tasks"
    __table_args__ = (
        Index("ix_crawl_tasks_status_lease_until", "status", "lease_until"),
        Index("ix_crawl_tasks_parent_status", "parent_task_id", "status"),
        Index("ix_crawl_tasks_user_created", "user_id", "created_at"),
        Index("ix_crawl_tasks_entity", "entity_type", "entity_id"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    task_id = Column(String(64), unique=True, index=True, nullable=False)
    parent_task_id = Column(String(64), nullable=True, index=True)
    task_type = Column(String(40), nullable=False)
    platform = Column(String(40), nullable=True)
    profile_key = Column(String(80), nullable=True)
    source = Column(String(20), nullable=False)
    status = Column(String(20), nullable=False)

    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    entity_type = Column(String(50), nullable=True)
    entity_id = Column(String(100), nullable=True)

    total = Column(Integer, nullable=False, default=0)
    success = Column(Integer, nullable=False, default=0)
    errors = Column(Integer, nullable=False, default=0)
    reason = Column(Text, nullable=True)
    details_json = Column(JSONB, nullable=True)
    payload_json = Column(JSONB, nullable=True)

    locked_by = Column(String(120), nullable=True)
    lease_until = Column(DateTime(timezone=True), nullable=True)
    heartbeat_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
    started_at = Column(DateTime(timezone=True), nullable=True)
    finished_at = Column(DateTime(timezone=True), nullable=True)
```

Create `backend/app/models/crawl_profile.py`:

```python
"""Crawler browser profile pool model."""

from sqlalchemy import Column, DateTime, Index, Integer, String, Text

from app.models.base import Base


class CrawlProfile(Base):
    """Durable browser profile metadata and lease state."""

    __tablename__ = "crawl_profiles"
    __table_args__ = (
        Index("ix_crawl_profiles_status_lease_until", "status", "lease_until"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    profile_key = Column(String(80), unique=True, index=True, nullable=False)
    profile_dir = Column(String(500), nullable=False)
    status = Column(String(30), nullable=False, default="available")
    platform_hint = Column(String(40), nullable=True)

    lease_owner = Column(String(120), nullable=True)
    lease_task_id = Column(String(64), nullable=True)
    lease_until = Column(DateTime(timezone=True), nullable=True)

    last_used_at = Column(DateTime(timezone=True), nullable=True)
    last_error = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
```

- [ ] **Step 4: Export models**

Update `backend/app/models/__init__.py`:

```python
from app.models.crawl_profile import CrawlProfile
from app.models.crawl_task import CrawlTaskRecord
```

Add both names to `__all__`:

```python
"CrawlTaskRecord",
"CrawlProfile",
```

- [ ] **Step 5: Add Alembic migration**

Create `backend/alembic/versions/2026_05_26_add_crawl_tasks_and_profiles.py`:

```python
"""add crawl tasks and crawl profiles

Revision ID: 20260526_crawl_tasks_profiles
Revises: 2026_05_24_make_token_hash_nullable
Create Date: 2026-05-26 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "20260526_crawl_tasks_profiles"
down_revision: Union[str, None] = "2026_05_24_make_token_hash_nullable"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "crawl_tasks",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("task_id", sa.String(length=64), nullable=False),
        sa.Column("parent_task_id", sa.String(length=64), nullable=True),
        sa.Column("task_type", sa.String(length=40), nullable=False),
        sa.Column("platform", sa.String(length=40), nullable=True),
        sa.Column("profile_key", sa.String(length=80), nullable=True),
        sa.Column("source", sa.String(length=20), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("entity_type", sa.String(length=50), nullable=True),
        sa.Column("entity_id", sa.String(length=100), nullable=True),
        sa.Column("total", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("success", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("errors", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("details_json", postgresql.JSONB(), nullable=True),
        sa.Column("payload_json", postgresql.JSONB(), nullable=True),
        sa.Column("locked_by", sa.String(length=120), nullable=True),
        sa.Column("lease_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("heartbeat_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("finished_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("task_id"),
    )
    op.create_index("ix_crawl_tasks_task_id", "crawl_tasks", ["task_id"], unique=True)
    op.create_index("ix_crawl_tasks_status_lease_until", "crawl_tasks", ["status", "lease_until"])
    op.create_index("ix_crawl_tasks_parent_status", "crawl_tasks", ["parent_task_id", "status"])
    op.create_index("ix_crawl_tasks_user_created", "crawl_tasks", ["user_id", "created_at"])
    op.create_index("ix_crawl_tasks_entity", "crawl_tasks", ["entity_type", "entity_id"])

    op.create_table(
        "crawl_profiles",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("profile_key", sa.String(length=80), nullable=False),
        sa.Column("profile_dir", sa.String(length=500), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="available"),
        sa.Column("platform_hint", sa.String(length=40), nullable=True),
        sa.Column("lease_owner", sa.String(length=120), nullable=True),
        sa.Column("lease_task_id", sa.String(length=64), nullable=True),
        sa.Column("lease_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("profile_key"),
    )
    op.create_index("ix_crawl_profiles_profile_key", "crawl_profiles", ["profile_key"], unique=True)
    op.create_index("ix_crawl_profiles_status_lease_until", "crawl_profiles", ["status", "lease_until"])


def downgrade() -> None:
    op.drop_index("ix_crawl_profiles_status_lease_until", table_name="crawl_profiles")
    op.drop_index("ix_crawl_profiles_profile_key", table_name="crawl_profiles")
    op.drop_table("crawl_profiles")
    op.drop_index("ix_crawl_tasks_entity", table_name="crawl_tasks")
    op.drop_index("ix_crawl_tasks_user_created", table_name="crawl_tasks")
    op.drop_index("ix_crawl_tasks_parent_status", table_name="crawl_tasks")
    op.drop_index("ix_crawl_tasks_status_lease_until", table_name="crawl_tasks")
    op.drop_index("ix_crawl_tasks_task_id", table_name="crawl_tasks")
    op.drop_table("crawl_tasks")
```

Before implementation, verify the actual Alembic head:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; alembic heads"
```

If the current head is not `2026_05_24_make_token_hash_nullable`, set `down_revision` to the real single head. If multiple heads exist, create a merge revision first and make this migration depend on the merge head.

- [ ] **Step 6: Run model tests and migration**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_task_store.py tests/test_profile_pool.py -q"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; alembic upgrade head"
```

Expected: model tests pass; migration creates both tables.

- [ ] **Step 7: Commit**

```powershell
git add backend/app/models/crawl_task.py backend/app/models/crawl_profile.py backend/app/models/__init__.py backend/alembic/versions/2026_05_26_add_crawl_tasks_and_profiles.py backend/tests/test_crawl_task_store.py backend/tests/test_profile_pool.py
git commit -m "feat: add persistent crawler task models"
```

---

## Task 2: Add Persistent Crawl Task Store

**Files:**

- Create: `backend/app/domains/crawling/task_store.py`
- Test: `backend/tests/test_crawl_task_store.py`

- [ ] **Step 1: Write failing task store tests**

Append to `backend/tests/test_crawl_task_store.py`:

```python
import pytest
from sqlalchemy import delete

from app.database import AsyncSessionLocal


@pytest.fixture
async def crawl_db_session():
    async with AsyncSessionLocal() as session:
        yield session
        from app.models.crawl_task import CrawlTaskRecord

        await session.execute(delete(CrawlTaskRecord))
        await session.commit()


@pytest.mark.asyncio
async def test_create_persistent_crawl_task(crawl_db_session):
    from app.domains.crawling.task_store import create_crawl_task_record

    record = await create_crawl_task_record(
        crawl_db_session,
        source="manual",
        task_type="product_all",
        user_id=1,
        entity_type="crawl_task",
        entity_id=None,
    )

    assert len(record.task_id) == 32
    assert record.status == "pending"
    assert record.source == "manual"
    assert record.task_type == "product_all"


@pytest.mark.asyncio
async def test_runtime_task_round_trip(crawl_db_session):
    from app.core.task_registry import TaskStatus
    from app.domains.crawling.task_store import (
        create_crawl_task_record,
        runtime_task_from_record,
        sync_record_from_runtime_task,
    )

    record = await create_crawl_task_record(
        crawl_db_session,
        source="manual",
        task_type="job_config",
        user_id=1,
        entity_type="job_config",
        entity_id="8",
    )
    runtime_task = runtime_task_from_record(record)
    runtime_task.status = TaskStatus.COMPLETED
    runtime_task.total = 3
    runtime_task.success = 2
    runtime_task.errors = 1
    runtime_task.details = [{"status": "success"}]

    await sync_record_from_runtime_task(crawl_db_session, record, runtime_task)

    assert record.status == "completed"
    assert record.total == 3
    assert record.details_json == [{"status": "success"}]


@pytest.mark.asyncio
async def test_recover_stale_running_tasks_marks_failed(crawl_db_session):
    from datetime import UTC, datetime, timedelta

    from app.domains.crawling.task_store import (
        create_crawl_task_record,
        mark_task_running,
        recover_stale_running_tasks,
    )

    record = await create_crawl_task_record(
        crawl_db_session,
        source="cron",
        task_type="product_all",
        user_id=1,
        entity_type="crawl_task",
        entity_id=None,
    )
    await mark_task_running(
        crawl_db_session,
        record,
        owner="test-worker",
        lease_seconds=1,
        now=datetime.now(UTC) - timedelta(seconds=10),
    )

    recovered = await recover_stale_running_tasks(crawl_db_session, owner_reason="test_restart")

    assert recovered == 1
    assert record.status == "failed"
    assert record.reason == "test_restart"
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_task_store.py -q"
```

Expected: fails because `task_store.py` does not exist.

- [ ] **Step 3: Implement task store**

Create `backend/app/domains/crawling/task_store.py`:

```python
"""Persistent crawl task store."""

from __future__ import annotations

import socket
import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.task_registry import CrawlTask, TaskStatus
from app.models.crawl_task import CrawlTaskRecord

DEFAULT_TASK_LEASE_SECONDS = 60 * 60


def _now() -> datetime:
    return datetime.now(UTC)


def _owner() -> str:
    return f"api:{socket.gethostname()}"


async def create_crawl_task_record(
    db: AsyncSession,
    *,
    source: str,
    task_type: str,
    user_id: int | None,
    entity_type: str | None,
    entity_id: str | None,
    platform: str | None = None,
    profile_key: str | None = None,
    parent_task_id: str | None = None,
    payload: dict | None = None,
) -> CrawlTaskRecord:
    now = _now()
    record = CrawlTaskRecord(
        task_id=uuid.uuid4().hex,
        parent_task_id=parent_task_id,
        task_type=task_type,
        platform=platform,
        profile_key=profile_key,
        source=source,
        status=TaskStatus.PENDING.value,
        user_id=user_id,
        entity_type=entity_type,
        entity_id=entity_id,
        total=0,
        success=0,
        errors=0,
        payload_json=payload,
        created_at=now,
        updated_at=now,
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return record


async def renew_task_lease(
    db: AsyncSession,
    record: CrawlTaskRecord,
    *,
    lease_seconds: int = DEFAULT_TASK_LEASE_SECONDS,
    now: datetime | None = None,
) -> CrawlTaskRecord:
    current = now or _now()
    record.heartbeat_at = current
    record.lease_until = current + timedelta(seconds=lease_seconds)
    record.updated_at = current
    await db.commit()
    await db.refresh(record)
    return record


async def get_crawl_task_record(
    db: AsyncSession,
    task_id: str,
    *,
    user_id: int | None = None,
) -> CrawlTaskRecord | None:
    stmt = select(CrawlTaskRecord).where(CrawlTaskRecord.task_id == task_id)
    if user_id is not None:
        stmt = stmt.where(CrawlTaskRecord.user_id == user_id)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


def runtime_task_from_record(record: CrawlTaskRecord) -> CrawlTask:
    task = CrawlTask(
        task_id=record.task_id,
        status=TaskStatus(record.status),
        source=record.source,
        user_id=record.user_id,
        entity_type=record.entity_type,
        entity_id=record.entity_id,
    )
    task.total = record.total or 0
    task.success = record.success or 0
    task.errors = record.errors or 0
    task.reason = record.reason
    task.details = record.details_json or []
    return task


async def sync_record_from_runtime_task(
    db: AsyncSession,
    record: CrawlTaskRecord,
    task: CrawlTask,
) -> CrawlTaskRecord:
    now = _now()
    status = task.status.value if isinstance(task.status, TaskStatus) else str(task.status)
    record.status = status
    record.total = task.total
    record.success = task.success
    record.errors = task.errors
    record.reason = task.reason
    record.details_json = task.details
    record.heartbeat_at = now if status == TaskStatus.RUNNING.value else record.heartbeat_at
    record.updated_at = now
    if status == TaskStatus.RUNNING.value and record.started_at is None:
        record.started_at = now
    if status in {TaskStatus.COMPLETED.value, TaskStatus.FAILED.value}:
        record.finished_at = now
        record.locked_by = None
        record.lease_until = None
    await db.commit()
    await db.refresh(record)
    return record


async def mark_task_running(
    db: AsyncSession,
    record: CrawlTaskRecord,
    *,
    owner: str | None = None,
    lease_seconds: int = DEFAULT_TASK_LEASE_SECONDS,
    now: datetime | None = None,
) -> CrawlTaskRecord:
    current = now or _now()
    record.status = TaskStatus.RUNNING.value
    record.locked_by = owner or _owner()
    record.lease_until = current + timedelta(seconds=lease_seconds)
    record.heartbeat_at = current
    record.started_at = record.started_at or current
    record.updated_at = current
    await db.commit()
    await db.refresh(record)
    return record


async def recover_stale_running_tasks(
    db: AsyncSession,
    *,
    owner_reason: str = "worker_restarted",
    now: datetime | None = None,
) -> int:
    current = now or _now()
    result = await db.execute(
        select(CrawlTaskRecord).where(
            CrawlTaskRecord.status == TaskStatus.RUNNING.value,
            CrawlTaskRecord.lease_until.is_not(None),
            CrawlTaskRecord.lease_until < current,
        )
    )
    records = result.scalars().all()
    for record in records:
        record.status = TaskStatus.FAILED.value
        record.reason = owner_reason
        record.locked_by = None
        record.lease_until = None
        record.finished_at = current
        record.updated_at = current
    await db.commit()
    return len(records)
```

- [ ] **Step 4: Run task store tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_task_store.py -q"
```

Expected: task store tests pass.

- [ ] **Step 5: Commit**

```powershell
git add backend/app/domains/crawling/task_store.py backend/tests/test_crawl_task_store.py
git commit -m "feat: add persistent crawl task store"
```

---

## Task 3: Add DB-Backed Profile Pool

**Files:**

- Create: `backend/app/domains/crawling/profile_pool.py`
- Test: `backend/tests/test_profile_pool.py`

- [ ] **Step 1: Write failing profile pool tests**

Append to `backend/tests/test_profile_pool.py`:

```python
import pytest
from sqlalchemy import delete

from app.database import AsyncSessionLocal


@pytest.fixture
async def profile_db_session():
    async with AsyncSessionLocal() as session:
        yield session
        from app.models.crawl_profile import CrawlProfile

        await session.execute(delete(CrawlProfile))
        await session.commit()


@pytest.mark.asyncio
async def test_profile_pool_acquires_and_releases_profile(profile_db_session, tmp_path):
    from app.domains.crawling.profile_pool import DatabaseProfilePool

    pool = DatabaseProfilePool(root=tmp_path)

    lease = await pool.acquire(
        profile_db_session,
        platform="boss",
        profile_key="default",
        owner="task-1",
        task_id="task-1",
    )

    assert lease.profile_key == "default"
    assert lease.profile_dir == tmp_path / "profiles" / "default"

    await pool.release(profile_db_session, lease)
    second = await pool.acquire(
        profile_db_session,
        platform="51job",
        profile_key="default",
        owner="task-2",
        task_id="task-2",
    )

    assert second.profile_key == "default"


@pytest.mark.asyncio
async def test_profile_pool_rejects_same_profile_across_platforms(profile_db_session, tmp_path):
    from app.domains.crawling.profile_pool import DatabaseProfilePool, ProfileAlreadyLeasedError

    pool = DatabaseProfilePool(root=tmp_path)
    await pool.acquire(
        profile_db_session,
        platform="boss",
        profile_key="default",
        owner="task-1",
        task_id="task-1",
    )

    with pytest.raises(ProfileAlreadyLeasedError):
        await pool.acquire(
            profile_db_session,
            platform="51job",
            profile_key="default",
            owner="task-2",
            task_id="task-2",
        )


@pytest.mark.asyncio
async def test_profile_pool_allows_different_profiles(profile_db_session, tmp_path):
    from app.domains.crawling.profile_pool import DatabaseProfilePool

    pool = DatabaseProfilePool(root=tmp_path)
    first = await pool.acquire(
        profile_db_session,
        platform="boss",
        profile_key="profile-a",
        owner="task-1",
        task_id="task-1",
    )
    second = await pool.acquire(
        profile_db_session,
        platform="boss",
        profile_key="profile-b",
        owner="task-2",
        task_id="task-2",
    )

    assert first.profile_dir != second.profile_dir


@pytest.mark.asyncio
async def test_profile_pool_rejects_login_required_profile(profile_db_session, tmp_path):
    from app.domains.crawling.profile_pool import (
        DatabaseProfilePool,
        ProfileUnavailableError,
        ensure_profile,
    )

    profile = await ensure_profile(profile_db_session, profile_key="default", root=tmp_path)
    profile.status = "login_required"
    await profile_db_session.commit()

    pool = DatabaseProfilePool(root=tmp_path)
    with pytest.raises(ProfileUnavailableError):
        await pool.acquire(
            profile_db_session,
            platform="boss",
            profile_key="default",
            owner="task-1",
            task_id="task-1",
        )
```

- [ ] **Step 2: Run profile pool tests to verify failure**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_profile_pool.py -q"
```

Expected: fails because `DatabaseProfilePool` does not exist.

- [ ] **Step 3: Implement profile pool**

The acquire path must be atomic. Use `SELECT ... FOR UPDATE` on the `crawl_profiles` row after it exists, and handle the first-create unique constraint race by retrying the locked read. Do not call the standalone `ensure_profile()` helper from `acquire()`, because it commits before the lease decision and creates a race window.

Create `backend/app/domains/crawling/profile_pool.py`:

```python
"""Database-backed crawler profile pool."""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.crawler_paths import build_profile_dir
from app.core.profile_lease import ProfileLease
from app.models.crawl_profile import CrawlProfile

AVAILABLE = "available"
LEASED = "leased"
LOGIN_REQUIRED = "login_required"
COOLING_DOWN = "cooling_down"
DISABLED = "disabled"
BLOCKING_STATUSES = {LOGIN_REQUIRED, COOLING_DOWN, DISABLED}
DEFAULT_PROFILE_LEASE_SECONDS = 60 * 60


class ProfileAlreadyLeasedError(RuntimeError):
    """Raised when a profile directory is currently leased."""


class ProfileUnavailableError(RuntimeError):
    """Raised when a profile is not eligible for use."""


def _now() -> datetime:
    return datetime.now(UTC)


async def ensure_profile(
    db: AsyncSession,
    *,
    profile_key: str,
    root: str | Path | None = None,
    platform_hint: str | None = None,
) -> CrawlProfile:
    profile_dir = build_profile_dir(profile_key, root=root)
    result = await db.execute(
        select(CrawlProfile).where(CrawlProfile.profile_key == profile_key)
    )
    profile = result.scalar_one_or_none()
    current = _now()
    if profile is None:
        profile = CrawlProfile(
            profile_key=profile_key,
            profile_dir=str(profile_dir),
            status=AVAILABLE,
            platform_hint=platform_hint,
            created_at=current,
            updated_at=current,
        )
        db.add(profile)
    else:
        profile.profile_dir = str(profile_dir)
        if platform_hint and not profile.platform_hint:
            profile.platform_hint = platform_hint
        profile.updated_at = current
    await db.commit()
    await db.refresh(profile)
    return profile


async def _get_or_create_profile_for_update(
    db: AsyncSession,
    *,
    profile_key: str,
    root: str | Path | None,
    platform_hint: str | None,
) -> CrawlProfile:
    profile_dir = build_profile_dir(profile_key, root=root)
    current = _now()
    result = await db.execute(
        select(CrawlProfile)
        .where(CrawlProfile.profile_key == profile_key)
        .with_for_update()
    )
    profile = result.scalar_one_or_none()
    if profile is not None:
        profile.profile_dir = str(profile_dir)
        if platform_hint and not profile.platform_hint:
            profile.platform_hint = platform_hint
        profile.updated_at = current
        return profile

    profile = CrawlProfile(
        profile_key=profile_key,
        profile_dir=str(profile_dir),
        status=AVAILABLE,
        platform_hint=platform_hint,
        created_at=current,
        updated_at=current,
    )
    db.add(profile)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        result = await db.execute(
            select(CrawlProfile)
            .where(CrawlProfile.profile_key == profile_key)
            .with_for_update()
        )
        profile = result.scalar_one()
    return profile


class DatabaseProfilePool:
    def __init__(self, *, root: str | Path | None = None):
        self.root = root

    async def acquire(
        self,
        db: AsyncSession,
        *,
        platform: str,
        profile_key: str,
        owner: str,
        task_id: str,
        lease_seconds: int = DEFAULT_PROFILE_LEASE_SECONDS,
    ) -> ProfileLease:
        profile = await _get_or_create_profile_for_update(
            db,
            profile_key=profile_key,
            root=self.root,
            platform_hint=platform,
        )
        current = _now()
        if profile.status in BLOCKING_STATUSES:
            raise ProfileUnavailableError(
                f"Profile {profile_key!r} is {profile.status}"
            )
        if profile.lease_until and profile.lease_until > current:
            raise ProfileAlreadyLeasedError(
                f"Profile {profile_key!r} is leased by {profile.lease_owner}"
            )

        profile_dir = build_profile_dir(profile_key, root=self.root)
        profile_dir.mkdir(parents=True, exist_ok=True)
        profile.status = LEASED
        profile.lease_owner = owner
        profile.lease_task_id = task_id
        profile.lease_until = current + timedelta(seconds=lease_seconds)
        profile.last_used_at = current
        profile.updated_at = current
        await db.commit()
        await db.refresh(profile)

        return ProfileLease(
            platform=platform,
            profile_key=profile_key,
            profile_dir=profile_dir,
            owner=owner,
        )

    async def release(self, db: AsyncSession, lease: ProfileLease) -> None:
        result = await db.execute(
            select(CrawlProfile)
            .where(CrawlProfile.profile_key == lease.profile_key)
            .with_for_update()
        )
        profile = result.scalar_one_or_none()
        if profile is None:
            return
        profile.status = AVAILABLE
        profile.lease_owner = None
        profile.lease_task_id = None
        profile.lease_until = None
        profile.updated_at = _now()
        await db.commit()

    async def renew(
        self,
        db: AsyncSession,
        lease: ProfileLease,
        *,
        lease_seconds: int = DEFAULT_PROFILE_LEASE_SECONDS,
    ) -> None:
        result = await db.execute(
            select(CrawlProfile)
            .where(CrawlProfile.profile_key == lease.profile_key)
            .with_for_update()
        )
        profile = result.scalar_one_or_none()
        if profile is None:
            return
        current = _now()
        profile.lease_until = current + timedelta(seconds=lease_seconds)
        profile.updated_at = current
        await db.commit()

    @asynccontextmanager
    async def lease(
        self,
        db: AsyncSession,
        *,
        platform: str,
        profile_key: str,
        owner: str,
        task_id: str,
    ) -> AsyncIterator[ProfileLease]:
        acquired = await self.acquire(
            db,
            platform=platform,
            profile_key=profile_key,
            owner=owner,
            task_id=task_id,
        )
        try:
            yield acquired
        finally:
            await self.release(db, acquired)


async def recover_stale_profile_leases(
    db: AsyncSession,
    *,
    now: datetime | None = None,
) -> int:
    current = now or _now()
    result = await db.execute(
        select(CrawlProfile).where(
            CrawlProfile.lease_until.is_not(None),
            CrawlProfile.lease_until < current,
        )
    )
    profiles = result.scalars().all()
    for profile in profiles:
        profile.status = AVAILABLE
        profile.lease_owner = None
        profile.lease_task_id = None
        profile.lease_until = None
        profile.updated_at = current
    await db.commit()
    return len(profiles)
```

- [ ] **Step 4: Run profile pool tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_profile_pool.py -q"
```

Expected: profile pool tests pass.

- [ ] **Step 5: Commit**

```powershell
git add backend/app/domains/crawling/profile_pool.py backend/tests/test_profile_pool.py
git commit -m "feat: add database profile pool"
```

---

## Task 4: Add Runner Progress Callback And Profile Lease Hook

**Files:**

- Modify: `backend/app/domains/crawling/task_runner.py`
- Test: `backend/tests/test_crawl_task_runner.py`

- [ ] **Step 1: Write failing runner callback tests**

Append to `backend/tests/test_crawl_task_runner.py`:

```python
@pytest.mark.asyncio
async def test_runner_reports_product_progress(monkeypatch):
    from app.core.task_registry import CrawlTask
    from app.domains.crawling.task_runner import CrawlTaskRunner

    class Product:
        id = 1

    async def fake_get_active_products(user_id=None):
        return [Product()]

    async def fake_crawl_product(product_id, semaphore):
        return {"status": "success", "product_id": product_id}

    progress = []

    async def on_progress(task):
        progress.append((task.status.value, task.total, task.success, task.errors))

    monkeypatch.setattr(
        "app.domains.crawling.service.get_active_products",
        fake_get_active_products,
    )
    monkeypatch.setattr(
        "app.domains.crawling.task_runner._crawl_product_with_semaphore",
        fake_crawl_product,
    )

    task = CrawlTask(task_id="task-1")
    await CrawlTaskRunner(progress_callback=on_progress).run_all_products(task)

    assert ("running", 0, 0, 0) in progress
    assert ("running", 1, 0, 0) in progress
    assert progress[-1] == ("completed", 1, 1, 0)
```

- [ ] **Step 2: Run runner tests to verify failure**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_task_runner.py -q"
```

Expected: fails because `CrawlTaskRunner.__init__` does not accept `progress_callback`.

- [ ] **Step 3: Implement callback support**

Modify `backend/app/domains/crawling/task_runner.py`:

```python
from collections.abc import Awaitable, Callable

ProgressCallback = Callable[[CrawlTask], Awaitable[None]]
```

Add an initializer and helper:

```python
class CrawlTaskRunner:
    def __init__(self, *, progress_callback: ProgressCallback | None = None):
        self._progress_callback = progress_callback

    async def _notify_progress(self, task: CrawlTask) -> None:
        if self._progress_callback is not None:
            await self._progress_callback(task)
```

After each status or count update in `run_job_config`, `run_all_jobs`, and `run_all_products`, call:

```python
await self._notify_progress(task)
```

Required locations:

- Immediately after `task.status = TaskStatus.RUNNING`.
- In product crawl after `task.total = len(products)`.
- Immediately after final `task.status`, `success`, `errors`, `details`, or `reason` are set.

- [ ] **Step 4: Run runner tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_task_runner.py -q"
```

Expected: runner tests pass.

- [ ] **Step 5: Commit**

```powershell
git add backend/app/domains/crawling/task_runner.py backend/tests/test_crawl_task_runner.py
git commit -m "feat: report crawl task runner progress"
```

---

## Task 5: Persist Product Crawl Tasks

**Files:**

- Modify: `backend/app/domains/crawling/scheduler_service.py`
- Modify: `backend/app/domains/crawling/router.py`
- Test: `backend/tests/test_integration_crawl_phase2.py`
- Test: update `backend/tests/test_phase_c_integration.py`

- [ ] **Step 1: Write failing product persistence tests**

Create `backend/tests/test_integration_crawl_phase2.py`:

```python
from unittest.mock import MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_current_user
from app.database import get_db
from app.main import app


def create_mock_user(user_id=1, username="testuser", role="user"):
    user = MagicMock()
    user.id = user_id
    user.username = username
    user.email = f"{username}@example.com"
    user.role = role
    user.deleted_at = None
    return user


@pytest.fixture(autouse=True)
def cleanup_overrides():
    yield
    app.dependency_overrides.clear()


@pytest.fixture
async def phase2_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.fixture
async def crawl_db_session():
    from sqlalchemy import delete

    from app.database import AsyncSessionLocal
    from app.models.crawl_profile import CrawlProfile
    from app.models.crawl_task import CrawlTaskRecord

    async with AsyncSessionLocal() as session:
        yield session
        await session.execute(delete(CrawlProfile))
        await session.execute(delete(CrawlTaskRecord))
        await session.commit()


def install_auth_and_db_overrides(db_session):
    async def _mock_get_current_user(token=None, db=None):
        return create_mock_user()

    async def _mock_get_db():
        yield db_session

    app.dependency_overrides[get_current_user] = _mock_get_current_user
    app.dependency_overrides[get_db] = _mock_get_db


@pytest.mark.asyncio
async def test_product_crawl_now_persists_task(phase2_client, crawl_db_session, monkeypatch):
    install_auth_and_db_overrides(crawl_db_session)

    async def fake_run_crawl_in_lock(task, crawl_lock, *, record_id=None):
        task.status = "completed"

    monkeypatch.setattr(
        "app.domains.crawling.scheduler_service._run_crawl_in_lock",
        fake_run_crawl_in_lock,
    )

    response = await phase2_client.post("/api/v1/crawl/crawl-now")

    assert response.status_code == 200
    task_id = response.json()["task_id"]

    from app.domains.crawling.task_store import get_crawl_task_record

    record = await get_crawl_task_record(crawl_db_session, task_id)
    assert record is not None
    assert record.task_type == "product_all"
    assert record.source == "manual"


@pytest.mark.asyncio
async def test_product_status_reads_persistent_task(phase2_client, crawl_db_session):
    from app.domains.crawling.task_store import create_crawl_task_record

    record = await create_crawl_task_record(
        crawl_db_session,
        source="manual",
        task_type="product_all",
        user_id=1,
        entity_type="crawl_task",
        entity_id=None,
    )
    record.status = "completed"
    record.total = 2
    record.success = 1
    record.errors = 1
    await crawl_db_session.commit()

    response = await phase2_client.get(f"/api/v1/crawl/status/{record.task_id}")

    assert response.status_code == 200
    assert response.json()["status"] == "completed"
    assert response.json()["total"] == 2
```

- [ ] **Step 2: Run product integration tests to verify failure**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_integration_crawl_phase2.py -q"
```

Expected: fails because product routes still read the in-memory registry.

- [ ] **Step 3: Update product crawl creation**

Modify `backend/app/domains/crawling/scheduler_service.py`:

- Import `AsyncSessionLocal`.
- Keep the existing global `crawl_lock`.
- In `crawl_all_products`, open a DB session and call `create_crawl_task_record`.
- Convert the record to a runtime `CrawlTask`.
- Schedule `_run_crawl_in_lock(task, crawl_lock, record_id=record.id)`.
- Do not assign or acquire a profile for product tasks in Phase 2. Product browser/profile ownership remains Phase 4.

The core creation block should be:

```python
from app.database import AsyncSessionLocal
from app.domains.crawling.task_store import (
    create_crawl_task_record,
    runtime_task_from_record,
)

async with AsyncSessionLocal() as db:
    record = await create_crawl_task_record(
        db,
        source=source,
        task_type="product_all",
        platform=None,
        profile_key=None,
        user_id=user_id,
        entity_type="crawl_task",
        entity_id=None,
    )
    task = runtime_task_from_record(record)
```

Change `_run_crawl_in_lock` signature:

```python
async def _run_crawl_in_lock(
    task: CrawlTask,
    crawl_lock: asyncio.Semaphore,
    *,
    record_id: int | None = None,
) -> None:
```

Inside `_run_crawl_task`, when `record_id` is present, create a progress callback:

```python
async def _persist_progress(progress_task: CrawlTask) -> None:
    if record_id is None:
        return
    async with AsyncSessionLocal() as db:
        record = await db.get(CrawlTaskRecord, record_id)
        if record is not None:
            await sync_record_from_runtime_task(db, record, progress_task)
```

Use:

```python
result = await CrawlTaskRunner(progress_callback=_persist_progress).run_all_products(task)
```

- [ ] **Step 4: Update product status/result routes**

Modify `backend/app/domains/crawling/router.py`:

```python
from app.database import get_db
from app.domains.crawling.task_store import get_crawl_task_record
```

Change status endpoint to accept `db`:

```python
@router.get("/status/{task_id}")
async def get_crawl_status(task_id: str, db: AsyncSession = Depends(get_db)):
    record = await get_crawl_task_record(db, task_id)
    if not record:
        return JSONResponse(content={"status": "error", "reason": "task_not_found"}, status_code=404)
    return JSONResponse(content={
        "task_id": record.task_id,
        "status": record.status,
        "total": record.total,
        "success": record.success,
        "errors": record.errors,
        "reason": record.reason,
    })
```

Change result endpoint to read `record.status` and `record.details_json`.

- [ ] **Step 5: Persist product platform cron tasks**

Modify `crawl_products_by_platform` so scheduled platform crawls create a task record:

```python
record = await create_crawl_task_record(
    db,
    source="cron",
    task_type="product_platform",
    platform=platform,
    profile_key=None,
    user_id=user_id,
    entity_type="product_platform",
    entity_id=platform,
)
```

Use the same runtime task + progress callback pattern. This scheduled task does not need a frontend polling caller, but it must appear in `crawl_tasks` and Event Center payloads should include `task_id`.

- [ ] **Step 6: Run product tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_integration_crawl_phase2.py tests/test_phase_c_integration.py -q"
```

Expected: product crawl tests pass, with status/result now backed by DB.

- [ ] **Step 7: Commit**

```powershell
git add backend/app/domains/crawling/scheduler_service.py backend/app/domains/crawling/router.py backend/tests/test_integration_crawl_phase2.py backend/tests/test_phase_c_integration.py
git commit -m "feat: persist product crawl tasks"
```

---

## Task 6: Persist Job Crawl Tasks

**Files:**

- Modify: `backend/app/domains/jobs/crawl_service.py`
- Modify: `backend/app/domains/jobs/router.py`
- Test: `backend/tests/test_integration_crawl_phase2.py`
- Test: update `backend/tests/test_integration_crawl_phase1.py`

- [ ] **Step 1: Write failing job persistence tests**

Append to `backend/tests/test_integration_crawl_phase2.py`:

```python
@pytest.mark.asyncio
async def test_job_single_crawl_persists_task(phase2_client, crawl_db_session, monkeypatch):
    install_auth_and_db_overrides(crawl_db_session)

    async def fake_runner(task, *, config_id):
        task.status = "completed"
        task.total = 1
        task.success = 1
        task.errors = 0
        return {"status": "success", "new_count": 1, "updated_count": 0, "deactivated_count": 0}

    monkeypatch.setattr(
        "app.domains.crawling.task_runner.CrawlTaskRunner.run_job_config",
        fake_runner,
    )

    response = await phase2_client.post("/api/v1/jobs/crawl-now/1")

    assert response.status_code == 200
    task_id = response.json()["task_id"]

    from app.domains.crawling.task_store import get_crawl_task_record

    record = await get_crawl_task_record(crawl_db_session, task_id)
    assert record is not None
    assert record.task_type == "job_config"
    assert record.entity_id == "1"


@pytest.mark.asyncio
async def test_job_crawl_status_reads_persistent_task(phase2_client, crawl_db_session):
    from app.domains.crawling.task_store import create_crawl_task_record

    record = await create_crawl_task_record(
        crawl_db_session,
        source="manual",
        task_type="job_config",
        platform="boss",
        user_id=1,
        entity_type="job_config",
        entity_id="1",
    )
    record.status = "failed"
    record.reason = "profile_already_leased"
    await crawl_db_session.commit()

    response = await phase2_client.get(f"/api/v1/jobs/crawl/status/{record.task_id}")

    assert response.status_code == 200
    assert response.json()["status"] == "failed"
```

- [ ] **Step 2: Run job persistence tests to verify failure**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_integration_crawl_phase2.py -q"
```

Expected: job-specific tests fail because job routes still use `get_task`.

- [ ] **Step 3: Update manual single-config job task creation**

Modify `crawl_single_config_background` and `crawl_all_job_searches_background` in `backend/app/domains/jobs/crawl_service.py`:

- Create a `crawl_tasks` row using `create_crawl_task_record`.
- Convert it with `runtime_task_from_record`.
- Pass a `progress_callback` to `CrawlTaskRunner`.
- Keep Event Center payloads but use the persistent `task_id`.

The single-config creation block should be:

```python
async with AsyncSessionLocal() as db:
    record = await create_crawl_task_record(
        db,
        source="manual",
        task_type="job_config",
        platform=None,
        profile_key="default",
        user_id=user_id,
        entity_type="job_config",
        entity_id=str(config_id),
        payload={"config_id": config_id},
    )
    task = runtime_task_from_record(record)
```

The progress callback should be:

```python
async def _persist_progress(progress_task: CrawlTask) -> None:
    async with AsyncSessionLocal() as db:
        record = await db.get(CrawlTaskRecord, record_id)
        if record is not None:
            await sync_record_from_runtime_task(db, record, progress_task)
```

- [ ] **Step 4: Update scheduled single-config job task creation**

Modify `crawl_scheduled_config`:

- Create a persistent task row with `source="cron"`, `task_type="job_config"`, `entity_type="job_config"`, `entity_id=str(config_id)`.
- Execute through `CrawlTaskRunner(progress_callback=...)` instead of directly calling `crawl_single_config(config_id)`.
- Event Center payloads include `task_id`.

- [ ] **Step 5: Represent job all-crawl as parent and platform child tasks**

Modify `crawl_all_job_searches_background` so it creates one parent task:

```python
parent_record = await create_crawl_task_record(
    db,
    source="manual",
    task_type="job_all",
    platform=None,
    profile_key=None,
    user_id=user_id,
    entity_type="job_crawl",
    entity_id=None,
)
```

During execution, load active configs, group by platform, and create one child task per platform:

```python
child_record = await create_crawl_task_record(
    db,
    source="manual",
    task_type="job_platform",
    platform=platform,
    profile_key="default",
    parent_task_id=parent_record.task_id,
    user_id=user_id,
    entity_type="job_platform",
    entity_id=platform,
    payload={"parent_task_id": parent_record.task_id, "platform": platform},
)
```

Each child task leases a profile and runs only that platform's configs. The parent task never leases a profile directly; it only aggregates child task counts and final status.

Parent status rule:

- `pending` until first child starts.
- `running` while any child is running.
- `completed` when all children completed and none failed.
- `failed` when all children finished and at least one failed.
- `total/success/errors` are sums from child task rows.

- [ ] **Step 6: Update job crawl status/result routes**

Modify only `/jobs/crawl/status/{task_id}` and `/jobs/crawl/result/{task_id}` in `backend/app/domains/jobs/router.py` to read from `crawl_tasks`.

Do not change `/jobs/tasks/{task_id}` because it is for match analysis and still uses `task_registry`.

Status route body:

```python
record = await get_crawl_task_record(db, task_id)
if not record:
    return JSONResponse(content={"status": "error", "reason": "task_not_found"}, status_code=404)
return JSONResponse(content={
    "task_id": record.task_id,
    "status": record.status,
    "total": record.total,
    "success": record.success,
    "errors": record.errors,
})
```

- [ ] **Step 7: Run job tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_integration_crawl_phase2.py tests/test_integration_crawl_phase1.py tests/test_job_crawl.py -q"
```

Expected: manual and scheduled job crawl tests pass, and match analysis task tests are unchanged.

- [ ] **Step 8: Commit**

```powershell
git add backend/app/domains/jobs/crawl_service.py backend/app/domains/jobs/router.py backend/tests/test_integration_crawl_phase2.py backend/tests/test_integration_crawl_phase1.py
git commit -m "feat: persist job crawl tasks"
```

---

## Task 7: Wire Profile Pool Into Job Crawl Execution

**Files:**

- Modify: `backend/app/domains/crawling/task_runner.py`
- Modify: `backend/app/domains/jobs/crawl_service.py`
- Test: `backend/tests/test_integration_crawl_phase2.py`
- Test: `backend/tests/test_profile_pool.py`

- [ ] **Step 1: Write failing profile lease integration tests**

Append to `backend/tests/test_integration_crawl_phase2.py`:

```python
@pytest.mark.asyncio
async def test_two_job_tasks_cannot_use_same_profile(crawl_db_session, tmp_path):
    from app.domains.crawling.profile_pool import DatabaseProfilePool, ProfileAlreadyLeasedError

    pool = DatabaseProfilePool(root=tmp_path)
    first = await pool.acquire(
        crawl_db_session,
        platform="boss",
        profile_key="default",
        owner="task-1",
        task_id="task-1",
    )

    with pytest.raises(ProfileAlreadyLeasedError):
        await pool.acquire(
            crawl_db_session,
            platform="51job",
            profile_key="default",
            owner="task-2",
            task_id="task-2",
        )

    await pool.release(crawl_db_session, first)
```

- [ ] **Step 2: Add task execution profile selection rule**

For Phase 2, job crawls use `profile_key="default"` unless the caller passes a different key. Do not introduce UI for profile assignment yet. Product crawls do not use Profile Pool in this phase.

Add optional fields to task payload:

```python
payload={"config_id": config_id, "profile_key": "default"}
```

Product tasks use:

```python
payload={"profile_key": None}
```

- [ ] **Step 3: Acquire and release profile around job runner execution**

In job background execution wrappers, before calling `CrawlTaskRunner`, use:

```python
from app.domains.crawling.profile_pool import (
    DatabaseProfilePool,
    ProfileAlreadyLeasedError,
    ProfileUnavailableError,
)

pool = DatabaseProfilePool()
try:
    async with AsyncSessionLocal() as lease_db:
        async with pool.lease(
            lease_db,
            platform=platform,
            profile_key=profile_key,
            owner=task.task_id,
            task_id=task.task_id,
        ) as lease:
            result = await CrawlTaskRunner(progress_callback=_persist_progress).run_job_config(task, config_id=config_id)
except (ProfileAlreadyLeasedError, ProfileUnavailableError) as exc:
    task.status = TaskStatus.FAILED
    task.reason = str(exc)
    await _persist_progress(task)
```

For job single-config tasks, resolve `platform` by loading the `JobSearchConfig` before acquiring the profile. For job all-crawl, each `job_platform` child task resolves and leases its own profile before crawling that platform. The `job_all` parent task does not lease a profile.

- [ ] **Step 4: Renew task and profile leases while jobs run**

Add a heartbeat helper used by job execution wrappers:

```python
async def _renew_leases(record_id: int, lease: ProfileLease) -> None:
    async with AsyncSessionLocal() as db:
        record = await db.get(CrawlTaskRecord, record_id)
        if record is not None:
            await renew_task_lease(db, record)
    async with AsyncSessionLocal() as db:
        await DatabaseProfilePool().renew(db, lease)
```

Call this helper from the runner `progress_callback` and at least once every 30-60 seconds for long platform crawls. The implementation can start with progress-triggered renewal plus a small async heartbeat task that is cancelled in `finally`.

- [ ] **Step 5: Emit profile status events**

When profile acquire fails, emit:

```python
await emit_system_log_detached(
    category="runtime",
    event_type="crawler_profile.lease_failed",
    source="crawler",
    severity="warning",
    status="failed",
    message=f"Profile {profile_key} lease failed",
    user_id=task.user_id,
    entity_type="crawl_profile",
    entity_id=profile_key,
    payload={"task_id": task.task_id, "profile_key": profile_key, "reason": task.reason},
)
```

When a stale lease is recovered in Task 8, use `crawler_profile.recovered`.

- [ ] **Step 6: Run profile integration tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_profile_pool.py tests/test_integration_crawl_phase2.py -q"
```

Expected: same profile conflict fails fast and releases cleanly after task completion.

- [ ] **Step 7: Commit**

```powershell
git add backend/app/domains/crawling/task_runner.py backend/app/domains/jobs/crawl_service.py backend/tests/test_integration_crawl_phase2.py backend/tests/test_profile_pool.py
git commit -m "feat: lease crawler profiles from database"
```

---

## Task 8: Add Startup Recovery For Stale Tasks And Leases

**Files:**

- Modify: `backend/app/main.py`
- Test: `backend/tests/test_integration_crawl_phase2.py`

- [ ] **Step 1: Write failing recovery test**

Append to `backend/tests/test_integration_crawl_phase2.py`:

```python
@pytest.mark.asyncio
async def test_startup_recovery_marks_stale_tasks_and_releases_profiles(crawl_db_session, tmp_path):
    from datetime import UTC, datetime, timedelta

    from app.domains.crawling.profile_pool import DatabaseProfilePool
    from app.domains.crawling.task_store import (
        create_crawl_task_record,
        mark_task_running,
        recover_stale_running_tasks,
    )
    from app.domains.crawling.profile_pool import recover_stale_profile_leases

    stale_time = datetime.now(UTC) - timedelta(hours=2)
    record = await create_crawl_task_record(
        crawl_db_session,
        source="manual",
        task_type="job_config",
        user_id=1,
        entity_type="job_config",
        entity_id="1",
    )
    await mark_task_running(crawl_db_session, record, owner="old-api", lease_seconds=1, now=stale_time)

    pool = DatabaseProfilePool(root=tmp_path)
    await pool.acquire(
        crawl_db_session,
        platform="boss",
        profile_key="default",
        owner="old-api",
        task_id=record.task_id,
        lease_seconds=1,
    )

    recovered_tasks = await recover_stale_running_tasks(crawl_db_session, owner_reason="worker_restarted")
    recovered_profiles = await recover_stale_profile_leases(crawl_db_session)

    assert recovered_tasks == 1
    assert recovered_profiles == 1
```

- [ ] **Step 2: Add startup recovery function**

In `backend/app/main.py`, add:

```python
async def recover_crawler_runtime_state() -> None:
    from app.database import AsyncSessionLocal
    from app.domains.crawling.profile_pool import recover_stale_profile_leases
    from app.domains.crawling.task_store import recover_stale_running_tasks

    async with AsyncSessionLocal() as db:
        recovered_tasks = await recover_stale_running_tasks(
            db,
            owner_reason="worker_restarted",
        )
        recovered_profiles = await recover_stale_profile_leases(db)

    if recovered_tasks or recovered_profiles:
        logger.warning(
            "Recovered crawler runtime state: %d stale tasks, %d stale profile leases",
            recovered_tasks,
            recovered_profiles,
        )
```

Call it during lifespan startup before starting APScheduler:

```python
await recover_crawler_runtime_state()
```

- [ ] **Step 3: Emit recovery Event Center logs**

After recovery, when either count is non-zero, call `emit_system_log_detached`:

```python
await emit_system_log_detached(
    category="runtime",
    event_type="crawler_runtime.recovered",
    source="crawler",
    severity="warning",
    status="completed",
    message="Recovered stale crawler runtime state",
    payload={"stale_tasks": recovered_tasks, "stale_profile_leases": recovered_profiles},
)
```

- [ ] **Step 4: Run recovery tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_integration_crawl_phase2.py -q"
```

Expected: recovery tests pass.

- [ ] **Step 5: Commit**

```powershell
git add backend/app/main.py backend/tests/test_integration_crawl_phase2.py
git commit -m "feat: recover stale crawler runtime state"
```

---

## Task 9: Frontend/API Compatibility Check

**Files:**

- Modify only if needed: `frontend/src/features/products/api/crawl.ts`
- Modify only if needed: `frontend/src/features/jobs/api/jobs.ts`
- Test: existing frontend build

- [ ] **Step 1: Check task id typing**

Read:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; rg -n 'task_id|taskId|CrawlStatus|JobCrawlStatus' frontend/src/features -g '*.ts' -g '*.tsx'"
```

Expected: task ids are typed as `string`, so 32-character ids require no UI change.

- [ ] **Step 2: Preserve response shapes**

Compare backend JSON output against existing TypeScript types:

Product status still returns:

```ts
{
  task_id: string;
  status: string;
  total: number;
  success: number;
  errors: number;
  reason?: string | null;
}
```

Job status still returns:

```ts
{
  task_id: string;
  status: string;
  total: number;
  success: number;
  errors: number;
}
```

If no mismatch exists, do not modify frontend files.

- [ ] **Step 3: Run frontend build**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"
```

Expected: build passes. Existing chunk-size warnings are acceptable if they already exist before this phase.

- [ ] **Step 4: Commit only if frontend files changed**

If no frontend files changed, skip this commit. If types need adjustment:

```powershell
git add frontend/src/features/products/api/crawl.ts frontend/src/features/jobs/api/jobs.ts
git commit -m "fix: keep crawl task api types compatible"
```

---

## Task 10: Documentation And TODO Sync

**Files:**

- Modify: `README.md`
- Modify: `ARCHITECTURE.md`
- Modify: `doc/backend-architecture.md`
- Modify: `docs/2026-05-25-crawler-production-todo.md`

- [ ] **Step 1: Update architecture docs**

Document these final Phase 2 facts:

- `crawl_tasks` stores product/job crawl status and results.
- `task_registry` remains for match analysis.
- Job all-crawl is a parent task with per-platform child execution tasks.
- `crawl_profiles` stores profile pool metadata and lease state.
- Profile concurrency rule: one profile may store many platform login states, but one task owns it at a time.
- Product crawls are persisted but do not use Profile Pool until Phase 4.
- Startup recovery marks stale running tasks failed and releases expired profile leases.
- Heartbeat renewal prevents active long-running tasks from being recovered as stale.
- FastAPI/APScheduler still execute tasks in process; independent worker remains Phase 5.

- [ ] **Step 2: Update TODO**

In `docs/2026-05-25-crawler-production-todo.md`, after implementation:

- Mark Phase 2 row `done`.
- Mark Phase 2 task rows `done`.
- Keep Phase 3-5 as `todo`.

- [ ] **Step 3: Run docs consistency scan**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; rg -n 'in-memory task registry|Profile Pool|crawl_tasks|crawl_profiles|independent worker|Phase 2' README.md ARCHITECTURE.md doc/backend-architecture.md docs/2026-05-25-crawler-production-todo.md"
```

Expected: docs consistently describe persistent crawl tasks for crawler flows and in-memory registry only for match analysis.

- [ ] **Step 4: Commit**

```powershell
git add README.md ARCHITECTURE.md doc/backend-architecture.md docs/2026-05-25-crawler-production-todo.md
git commit -m "docs: document crawler phase2 persistence"
```

---

## Task 11: Full Verification And Real E2E

**Files:**

- No code changes expected.

- [ ] **Step 1: Run backend lint**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app tests"
```

Expected: all checks pass. If unrelated historical lint failures appear outside touched files, document them and run targeted ruff on touched files.

- [ ] **Step 2: Run backend tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_task_store.py tests/test_profile_pool.py tests/test_crawl_task_runner.py tests/test_integration_crawl_phase1.py tests/test_integration_crawl_phase2.py tests/test_phase_c_integration.py tests/test_event_center.py tests/test_job_crawl.py -q"
```

Expected: all selected tests pass, with existing skipped tests unchanged.

- [ ] **Step 3: Run migration on local DB**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; alembic upgrade head"
```

Expected: local database has `crawl_tasks` and `crawl_profiles`.

- [ ] **Step 4: Restart real local services**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"
```

Expected:

- Backend responds at `http://127.0.0.1:8000/health`.
- Frontend responds at `http://127.0.0.1:3000`.

- [ ] **Step 5: Browser E2E**

Use the browser against `http://127.0.0.1:3000`:

1. Log in with `default123` / `123456`.
2. Trigger product full crawl from the Products page.
3. Refresh the browser page while the task is pending/running.
4. Confirm status polling still finds the task by `task_id`.
5. Trigger one job config crawl from the Jobs page.
6. Confirm job crawl status/result endpoints still work after page refresh.
7. Open Event Center and confirm crawl started/completed/failed events include task ids and do not expose cookie/token/webhook fields.

Expected: task status survives frontend refresh because status comes from DB. If real product crawl fails because Edge CDP is not running at `127.0.0.1:9222`, the task may end as failed, but the failure must be persisted and visible through status/result endpoints and Event Center.

- [ ] **Step 6: Restart recovery E2E**

Create or force a stale row:

```sql
UPDATE crawl_tasks
SET status = 'running',
    lease_until = NOW() - INTERVAL '5 minutes',
    reason = NULL
WHERE task_id = '<task_id>';
```

Restart backend. Confirm:

- The task becomes `failed`.
- `reason` is `worker_restarted`.
- Any expired profile lease is cleared.
- Event Center has `crawler_runtime.recovered`.

- [ ] **Step 7: GitNexus detect changes**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; npx gitnexus analyze"
```

Then run GitNexus detect changes for the final diff. Review any HIGH/CRITICAL impact before committing the final rollup if individual task commits were not used.

- [ ] **Step 8: Final commit if needed**

If all tasks used individual commits, no rollup commit is needed. If implementation was done as one working-tree batch:

```powershell
git status --short
git diff --check
git add backend/app backend/tests backend/alembic README.md ARCHITECTURE.md doc/backend-architecture.md docs/2026-05-25-crawler-production-todo.md
git commit -m "feat: persist crawler tasks and profile leases"
```

---

## Self-Review

- Spec coverage: This plan covers `crawl_tasks`, `crawl_profiles`, manual trigger persistence, APScheduler persistence, runner progress persistence, DB profile lease, heartbeat renewal, frontend polling compatibility, stale running recovery, tests, docs, and real E2E.
- Scope control: Independent crawler worker is explicitly excluded and remains Phase 5.
- Match analysis safety: `/jobs/tasks/{task_id}` stays on the in-memory registry, avoiding accidental migration of non-crawler tasks.
- Profile rule consistency: Every profile lease is keyed by `profile_key/profile_dir`, not platform. Same profile across platforms conflicts; different profiles can run concurrently.
- Job all-crawl consistency: `job_all` is a parent task; `job_platform` child tasks each run exactly one platform and lease at most one profile.
- Product scope consistency: product crawl tasks are persisted in Phase 2 but do not use Profile Pool until Phase 4.
- Edge behavior: Restart, profile conflict, profile unavailable, Event Center failure, and CDP absence during real E2E all have expected outcomes.
