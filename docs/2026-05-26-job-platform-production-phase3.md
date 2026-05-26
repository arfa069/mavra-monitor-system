# Job Platform Production Phase 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Boss, 51job, and Liepin job crawling production-ready with configurable profile keys, profile operations, profile-aware concurrency, consistent failure categories, JSONL logs, and Event Center coverage.

**Architecture:** Keep FastAPI/APScheduler in-process execution from Phase 2. Add `profile_key` to job configs, expose Profile Pool management APIs/UI, pass the leased profile directory into adapters, and group full job crawls by `(platform, profile_key)`. Platform adapters map native failures into a shared taxonomy while keeping 51job's current browser-backed production path and making Liepin HTTP-only.

**Tech Stack:** Python 3.11, FastAPI, async SQLAlchemy, Alembic, PostgreSQL, pytest, React, Vite, TypeScript, Ant Design, React Query.

---

## Source Inputs

- Design spec: `docs/superpowers/specs/2026-05-26-job-platform-production-phase3-design.md`
- Existing status tracker: `docs/2026-05-25-crawler-production-todo.md`
- Current Phase 2 foundation:
  - `backend/app/models/crawl_profile.py`
  - `backend/app/domains/crawling/profile_pool.py`
  - `backend/app/models/crawl_task.py`
  - `backend/app/domains/crawling/task_store.py`
  - `backend/app/domains/jobs/crawl_service.py`

## File Map

### Backend Data and Schemas

- Modify `backend/app/models/job.py`
  - Add `JobSearchConfig.profile_key`.
- Create `backend/alembic/versions/2026_05_26_add_job_config_profile_key.py`
  - Add and backfill `jobs_search_configs.profile_key`.
  - Ensure `crawl_profiles.default` exists.
- Modify `backend/app/schemas/job.py`
  - Add `profile_key` to create/update/response schemas.
- Create `backend/app/schemas/crawl_profile.py`
  - API shapes for profile list/create/update/release responses.

### Backend Profile Management

- Create `backend/app/domains/crawling/profile_service.py`
  - Validate keys, list/create/update profile rows, release stale leases.
- Create `backend/app/domains/crawling/profile_router.py`
  - `GET /crawl-profiles`
  - `POST /crawl-profiles`
  - `PATCH /crawl-profiles/{profile_key}`
  - `POST /crawl-profiles/{profile_key}/release-stale`
- Modify `backend/app/main.py`
  - Include the profile router in application routers.
- Modify `backend/app/domains/crawling/profile_pool.py`
  - Add service-friendly helpers to mark `available`, `disabled`, and `login_required`.

### Backend Job Execution

- Create `backend/app/domains/jobs/runtime.py`
  - `JobCrawlRuntimeContext` dataclass.
  - `JobFailureCategory` literals/constants.
- Modify `backend/app/domains/crawling/task_runner.py`
  - `run_job_config(task, config_id=101, runtime_context=context)`.
- Modify `backend/app/domains/jobs/crawl_service.py`
  - Load config `profile_key`.
  - Create adapters with runtime profile context.
  - Persist `crawl_tasks.profile_key` accurately.
  - Group full crawl by `(platform, profile_key)`.
  - Emit Event Center events with `failure_category`.

### Backend Platform Adapters

- Modify `backend/app/platforms/boss_cloak_experimental.py`
  - Accept runtime context fields.
  - Log anti-bot codes `36`, `37`, `38`.
  - Report `cookie_refresh_failed` after repeated refresh failures.
- Modify `backend/app/platforms/job51.py`
  - Accept runtime context fields.
  - Add JSONL events.
  - Add WAF fuse.
  - Add non-writing HTTP-only experiment function.
- Modify `backend/app/platforms/liepin.py`
  - Remove normal CDP fallback imports/calls.
  - Return classified HTTP/list/detail failures.
  - Add JSONL events.
- Create `backend/app/platforms/job_runtime_logging.py`
  - Shared JSONL writer envelope.

### Frontend

- Modify `frontend/src/features/jobs/types.ts`
  - Add `profile_key` and crawl profile types.
- Modify `frontend/src/features/jobs/api/jobs.ts`
  - Add profile API calls.
- Modify `frontend/src/features/jobs/hooks/useJobs.ts`
  - Add React Query hooks for profiles.
- Modify `frontend/src/features/jobs/components/JobConfigForm.tsx`
  - Add profile select.
- Modify `frontend/src/features/jobs/components/JobConfigList.tsx`
  - Show profile key tag.
- Create `frontend/src/features/jobs/components/ProfileManagement.tsx`
  - Profile table and safe actions.
- Modify `frontend/src/features/jobs/JobsPage.tsx`
  - Add `Profiles` tab.

### Tests

- Modify or add backend tests:
  - `backend/tests/test_job_config_profile_key.py`
  - `backend/tests/test_crawl_profile_api.py`
  - `backend/tests/test_job_crawl_profile_grouping.py`
  - `backend/tests/test_job_runtime_context.py`
  - `backend/tests/test_job_platform_logging_phase3.py`
  - Update `backend/tests/test_integration_crawl_phase2.py`
  - Update `backend/tests/test_job_crawl.py`
  - Update `backend/tests/test_job_phase3_integration.py`
- Modify or add frontend tests:
  - `frontend/tests/e2e/basic.spec.ts`
  - Add profile tab checks if the existing E2E style supports it.

---

## Task 1: Add `profile_key` to Job Configs

**Files:**
- Create: `backend/alembic/versions/2026_05_26_add_job_config_profile_key.py`
- Modify: `backend/app/models/job.py`
- Modify: `backend/app/schemas/job.py`
- Modify: `backend/app/domains/jobs/service.py`
- Modify: `backend/app/domains/jobs/repository.py`
- Test: `backend/tests/test_job_config_profile_key.py`

- [ ] **Step 1: Write failing schema/model tests**

Create `backend/tests/test_job_config_profile_key.py`:

```python
import pytest


def test_job_search_config_model_has_profile_key_column():
    from app.models.job import JobSearchConfig

    column = JobSearchConfig.__table__.columns["profile_key"]

    assert column.default.arg == "default"
    assert column.nullable is False
    assert column.type.length == 80


def test_job_config_create_defaults_profile_key():
    from app.schemas.job import JobSearchConfigCreate

    payload = JobSearchConfigCreate(name="Boss", platform="boss", url="https://www.zhipin.com/web/geek/job?query=python")

    assert payload.profile_key == "default"


def test_job_config_rejects_path_traversal_profile_key():
    from pydantic import ValidationError
    from app.schemas.job import JobSearchConfigCreate

    with pytest.raises(ValidationError):
        JobSearchConfigCreate(
            name="Bad",
            platform="boss",
            url="https://www.zhipin.com/web/geek/job?query=python",
            profile_key="../default",
        )
```

- [ ] **Step 2: Run the failing tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_config_profile_key.py -q"
```

Expected: fail because `profile_key` is missing from the model/schema.

- [ ] **Step 3: Add model and schema fields**

In `backend/app/models/job.py`, add this column to `JobSearchConfig` near `platform`:

```python
    profile_key = Column(
        String(80),
        nullable=False,
        default="default",
        comment="Crawler browser profile key under project profiles/{profile_key}",
    )
```

In `backend/app/schemas/job.py`, import the path validator and add a local validator:

```python
from app.core.crawler_paths import build_profile_dir


def _validate_profile_key_value(value: str | None) -> str:
    key = (value or "default").strip()
    build_profile_dir(key)
    return key
```

Add fields:

```python
    profile_key: str = Field(default="default", max_length=80)
```

to `JobSearchConfigCreate` and `JobSearchConfigResponse`, and:

```python
    profile_key: str | None = Field(default=None, max_length=80)
```

to `JobSearchConfigUpdate`.

Add validators to create/update:

```python
    @field_validator("profile_key")
    @classmethod
    def validate_profile_key(cls, v: str | None) -> str:
        return _validate_profile_key_value(v)
```

For update, use:

```python
    @field_validator("profile_key")
    @classmethod
    def validate_profile_key(cls, v: str | None) -> str | None:
        if v is None:
            return None
        return _validate_profile_key_value(v)
```

- [ ] **Step 4: Add Alembic migration**

Create `backend/alembic/versions/2026_05_26_add_job_config_profile_key.py`:

```python
"""add profile key to job search configs

Revision ID: 20260526_job_profile_key
Revises: 20260526_crawl_tasks_profiles
Create Date: 2026-05-26 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260526_job_profile_key"
down_revision: Union[str, None] = "20260526_crawl_tasks_profiles"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "jobs_search_configs",
        sa.Column(
            "profile_key",
            sa.String(length=80),
            nullable=False,
            server_default="default",
        ),
    )
    op.execute(
        """
        INSERT INTO crawl_profiles (
            profile_key,
            profile_dir,
            status,
            created_at,
            updated_at
        )
        VALUES (
            'default',
            'profiles/default',
            'available',
            NOW(),
            NOW()
        )
        ON CONFLICT (profile_key) DO NOTHING
        """
    )
    op.alter_column("jobs_search_configs", "profile_key", server_default=None)


def downgrade() -> None:
    op.drop_column("jobs_search_configs", "profile_key")
```

`profiles/default` is a safe migration placeholder. `DatabaseProfilePool.acquire()` and `ensure_profile()` rewrite `crawl_profiles.profile_dir` to the current project root path when the profile is used or managed.

- [ ] **Step 5: Require existing profile in job config service**

In `backend/app/domains/jobs/service.py`, add:

```python
from sqlalchemy import select
from app.models.crawl_profile import CrawlProfile


class JobProfileNotFoundError(LookupError):
    """Raised when a job config references an unknown crawl profile."""


async def _ensure_profile_exists(db: AsyncSession, profile_key: str) -> None:
    result = await db.execute(
        select(CrawlProfile.profile_key).where(CrawlProfile.profile_key == profile_key)
    )
    if result.scalar_one_or_none() is None:
        raise JobProfileNotFoundError(profile_key)
```

Call it in `create_job_config` before repository create:

```python
    profile_key = data.profile_key or "default"
    await _ensure_profile_exists(db, profile_key)
```

Call it in `update_job_config` only when `profile_key` is in `update_data`:

```python
    if "profile_key" in update_data:
        await _ensure_profile_exists(db, update_data["profile_key"])
```

In `backend/app/domains/jobs/router.py`, catch it in create/update and return 400:

```python
    except job_service.JobProfileNotFoundError as exc:
        raise HTTPException(status_code=400, detail=f"Profile not found: {exc}") from exc
```

- [ ] **Step 6: Run tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_config_profile_key.py -q"
```

Expected: pass.

- [ ] **Step 7: Commit Task 1**

```powershell
git add backend/alembic/versions/2026_05_26_add_job_config_profile_key.py backend/app/models/job.py backend/app/schemas/job.py backend/app/domains/jobs/service.py backend/app/domains/jobs/router.py backend/tests/test_job_config_profile_key.py
git commit -m "Add profile key to job configs"
```

---

## Task 2: Add Profile Management Backend API

**Files:**
- Create: `backend/app/schemas/crawl_profile.py`
- Create: `backend/app/domains/crawling/profile_service.py`
- Create: `backend/app/domains/crawling/profile_router.py`
- Modify: `backend/app/domains/crawling/profile_pool.py`
- Modify: `backend/app/main.py`
- Test: `backend/tests/test_crawl_profile_api.py`

- [ ] **Step 1: Write failing API tests**

Create `backend/tests/test_crawl_profile_api.py`:

```python
from datetime import UTC, datetime, timedelta

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import delete, select

from app.main import app
from app.database import AsyncSessionLocal
from app.models.crawl_profile import CrawlProfile


@pytest.fixture(autouse=True)
async def clean_profiles():
    async with AsyncSessionLocal() as db:
        await db.execute(delete(CrawlProfile))
        await db.commit()
    yield


@pytest.mark.asyncio
async def test_create_and_list_profile(auth_headers):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        create_response = await client.post(
            "/v1/crawl-profiles",
            json={"profile_key": "job-a", "platform_hint": "boss"},
            headers=auth_headers,
        )
        assert create_response.status_code == 201
        assert create_response.json()["profile_key"] == "job-a"

        list_response = await client.get("/v1/crawl-profiles", headers=auth_headers)
        assert list_response.status_code == 200
        assert [item["profile_key"] for item in list_response.json()] == ["job-a"]


@pytest.mark.asyncio
async def test_create_profile_rejects_path_traversal(auth_headers):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/v1/crawl-profiles",
            json={"profile_key": "../bad"},
            headers=auth_headers,
        )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_release_stale_profile_rejects_active_lease(auth_headers):
    current = datetime.now(UTC)
    async with AsyncSessionLocal() as db:
        db.add(
            CrawlProfile(
                profile_key="job-a",
                profile_dir="profiles/job-a",
                status="leased",
                lease_owner="task-1",
                lease_task_id="task-1",
                lease_until=current + timedelta(minutes=5),
                created_at=current,
                updated_at=current,
            )
        )
        await db.commit()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/v1/crawl-profiles/job-a/release-stale",
            headers=auth_headers,
        )

    assert response.status_code == 409
```

- [ ] **Step 2: Run the failing API tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_profile_api.py -q"
```

Expected: fail because `/v1/crawl-profiles` routes do not exist.

- [ ] **Step 3: Add schemas**

Create `backend/app/schemas/crawl_profile.py`:

```python
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator

from app.core.crawler_paths import build_profile_dir


ProfileStatus = Literal["available", "leased", "login_required", "cooling_down", "disabled"]


def validate_profile_key_value(value: str) -> str:
    key = value.strip()
    build_profile_dir(key)
    return key


class CrawlProfileCreate(BaseModel):
    profile_key: str = Field(min_length=1, max_length=80)
    platform_hint: str | None = Field(default=None, max_length=40)

    @field_validator("profile_key")
    @classmethod
    def validate_profile_key(cls, value: str) -> str:
        return validate_profile_key_value(value)


class CrawlProfileUpdate(BaseModel):
    status: Literal["available", "login_required", "disabled"] | None = None
    platform_hint: str | None = Field(default=None, max_length=40)
    last_error: str | None = None


class CrawlProfileResponse(BaseModel):
    profile_key: str
    profile_dir: str
    status: ProfileStatus
    platform_hint: str | None
    lease_owner: str | None
    lease_task_id: str | None
    lease_until: datetime | None
    last_used_at: datetime | None
    last_error: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
```

- [ ] **Step 4: Add profile service**

Create `backend/app/domains/crawling/profile_service.py`:

```python
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.crawler_paths import build_profile_dir
from app.core.system_log import emit_system_log_detached
from app.domains.crawling.profile_pool import AVAILABLE, DISABLED, LOGIN_REQUIRED, ensure_profile
from app.models.crawl_profile import CrawlProfile


class CrawlProfileNotFoundError(LookupError):
    """Raised when a crawl profile does not exist."""


class CrawlProfileLeaseActiveError(RuntimeError):
    """Raised when a non-expired lease is still active."""


async def list_profiles(db: AsyncSession) -> list[CrawlProfile]:
    result = await db.execute(select(CrawlProfile).order_by(CrawlProfile.profile_key))
    return list(result.scalars().all())


async def create_profile(db: AsyncSession, *, profile_key: str, platform_hint: str | None) -> CrawlProfile:
    profile = await ensure_profile(db, profile_key=profile_key, platform_hint=platform_hint)
    await emit_system_log_detached(
        category="runtime",
        event_type="crawl_profile.created",
        source="crawler",
        severity="info",
        status="success",
        message=f"Crawl profile {profile_key} created",
        entity_type="crawl_profile",
        entity_id=profile_key,
        payload={"profile_key": profile_key, "platform_hint": platform_hint},
    )
    return profile


async def get_profile(db: AsyncSession, profile_key: str) -> CrawlProfile:
    build_profile_dir(profile_key)
    result = await db.execute(select(CrawlProfile).where(CrawlProfile.profile_key == profile_key))
    profile = result.scalar_one_or_none()
    if profile is None:
        raise CrawlProfileNotFoundError(profile_key)
    return profile


async def update_profile(
    db: AsyncSession,
    *,
    profile_key: str,
    status: str | None,
    platform_hint: str | None,
    last_error: str | None,
) -> CrawlProfile:
    profile = await get_profile(db, profile_key)
    current = datetime.now(UTC)
    if status is not None:
        if status == AVAILABLE:
            profile.lease_owner = None
            profile.lease_task_id = None
            profile.lease_until = None
        profile.status = status
    if platform_hint is not None:
        profile.platform_hint = platform_hint
    if last_error is not None:
        profile.last_error = last_error
    profile.updated_at = current
    await db.commit()
    await db.refresh(profile)
    await emit_system_log_detached(
        category="runtime",
        event_type="crawl_profile.updated",
        source="crawler",
        severity="warning" if status in {LOGIN_REQUIRED, DISABLED} else "info",
        status="success",
        message=f"Crawl profile {profile_key} updated",
        entity_type="crawl_profile",
        entity_id=profile_key,
        payload={"profile_key": profile_key, "status": profile.status},
    )
    return profile


async def release_stale_profile(db: AsyncSession, *, profile_key: str) -> CrawlProfile:
    profile = await get_profile(db, profile_key)
    current = datetime.now(UTC)
    if profile.lease_until is not None and profile.lease_until > current:
        raise CrawlProfileLeaseActiveError(profile_key)
    profile.status = AVAILABLE
    profile.lease_owner = None
    profile.lease_task_id = None
    profile.lease_until = None
    profile.updated_at = current
    await db.commit()
    await db.refresh(profile)
    await emit_system_log_detached(
        category="runtime",
        event_type="crawl_profile.stale_lease_released",
        source="crawler",
        severity="warning",
        status="success",
        message=f"Stale lease released for crawl profile {profile_key}",
        entity_type="crawl_profile",
        entity_id=profile_key,
        payload={"profile_key": profile_key},
    )
    return profile
```

- [ ] **Step 5: Add router and include it**

Create `backend/app/domains/crawling/profile_router.py`:

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.database import get_db
from app.domains.crawling import profile_service
from app.models.user import User
from app.schemas.crawl_profile import CrawlProfileCreate, CrawlProfileResponse, CrawlProfileUpdate

router = APIRouter(prefix="/crawl-profiles", tags=["crawl-profiles"])


@router.get("", response_model=list[CrawlProfileResponse])
async def list_profiles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await profile_service.list_profiles(db)


@router.post("", response_model=CrawlProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_profile(
    data: CrawlProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await profile_service.create_profile(
        db,
        profile_key=data.profile_key,
        platform_hint=data.platform_hint,
    )


@router.patch("/{profile_key}", response_model=CrawlProfileResponse)
async def update_profile(
    profile_key: str,
    data: CrawlProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await profile_service.update_profile(
            db,
            profile_key=profile_key,
            status=data.status,
            platform_hint=data.platform_hint,
            last_error=data.last_error,
        )
    except profile_service.CrawlProfileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Profile not found") from exc


@router.post("/{profile_key}/release-stale", response_model=CrawlProfileResponse)
async def release_stale_profile(
    profile_key: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await profile_service.release_stale_profile(db, profile_key=profile_key)
    except profile_service.CrawlProfileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Profile not found") from exc
    except profile_service.CrawlProfileLeaseActiveError as exc:
        raise HTTPException(status_code=409, detail="Profile lease is still active") from exc
```

In `backend/app/main.py`, import and include:

```python
from app.domains.crawling import profile_router
```

Add `profile_router.router` to `_APPLICATION_ROUTERS`.

- [ ] **Step 6: Run API tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_profile_api.py -q"
```

Expected: pass.

- [ ] **Step 7: Commit Task 2**

```powershell
git add backend/app/schemas/crawl_profile.py backend/app/domains/crawling/profile_service.py backend/app/domains/crawling/profile_router.py backend/app/main.py backend/tests/test_crawl_profile_api.py
git commit -m "Add crawl profile management API"
```

---

## Task 3: Pass Lease Runtime Context Into Job Adapters

**Files:**
- Create: `backend/app/domains/jobs/runtime.py`
- Modify: `backend/app/domains/jobs/crawl_service.py`
- Modify: `backend/app/domains/crawling/task_runner.py`
- Test: `backend/tests/test_job_runtime_context.py`

- [ ] **Step 1: Write failing runtime context tests**

Create `backend/tests/test_job_runtime_context.py`:

```python
from pathlib import Path
from types import SimpleNamespace

import pytest


def test_create_adapter_uses_runtime_profile_dir(monkeypatch, tmp_path):
    from app.domains.jobs import crawl_service
    from app.domains.jobs.runtime import JobCrawlRuntimeContext

    captured = {}

    class FakeBoss:
        def __init__(self, **kwargs):
            captured.update(kwargs)

    monkeypatch.setattr(
        "app.platforms.BossCloakExperimentalAdapter",
        FakeBoss,
    )

    context = JobCrawlRuntimeContext(
        platform="boss",
        profile_key="job-a",
        profile_dir=tmp_path / "profiles" / "job-a",
        task_id="task-1",
        config_id=101,
        run_id="run-1",
    )

    crawl_service._create_adapter("boss", runtime_context=context)

    assert captured["profile_dir"] == tmp_path / "profiles" / "job-a"
    assert captured["runtime_context"] == context


@pytest.mark.asyncio
async def test_task_runner_forwards_runtime_context(monkeypatch):
    from app.domains.crawling.task_runner import CrawlTaskRunner
    from app.domains.jobs.runtime import JobCrawlRuntimeContext

    calls = []

    async def fake_crawl_single_config(config_id, **kwargs):
        calls.append((config_id, kwargs))
        return {"status": "success", "new_count": 0, "updated_count": 0, "deactivated_count": 0}

    monkeypatch.setattr("app.domains.jobs.crawl_service.crawl_single_config", fake_crawl_single_config)

    task = SimpleNamespace(status=None, total=0, success=0, errors=0, reason=None)
    context = JobCrawlRuntimeContext(
        platform="boss",
        profile_key="job-a",
        profile_dir=Path("profiles/job-a"),
        task_id="task-1",
        config_id=101,
        run_id="run-1",
    )

    await CrawlTaskRunner().run_job_config(task, config_id=101, runtime_context=context)

    assert calls[0][1]["runtime_context"] == context
```

- [ ] **Step 2: Run failing tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_runtime_context.py -q"
```

Expected: fail because runtime context support does not exist.

- [ ] **Step 3: Add runtime dataclass and categories**

Create `backend/app/domains/jobs/runtime.py`:

```python
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal


JobFailureCategory = Literal[
    "profile_unavailable",
    "profile_leased",
    "profile_login_required",
    "anti_bot",
    "waf",
    "challenge",
    "xsrf",
    "empty_result",
    "http_error",
    "parse_error",
    "detail_error",
    "cookie_refresh_failed",
    "timeout",
    "unknown",
]


@dataclass(frozen=True)
class JobCrawlRuntimeContext:
    platform: str
    profile_key: str
    profile_dir: Path
    task_id: str | None
    config_id: int | None
    run_id: str
    log_context: dict[str, object] = field(default_factory=dict)
```

- [ ] **Step 4: Update adapter factory**

Change `_create_adapter` in `backend/app/domains/jobs/crawl_service.py` to:

```python
def _create_adapter(
    platform: str,
    *,
    runtime_context: JobCrawlRuntimeContext | None = None,
) -> BasePlatformAdapter:
    """Create the adapter for the given job platform."""
    from app.platforms import (
        BossCloakExperimentalAdapter,
        Job51Adapter,
        LiepinAdapter,
    )

    platform = _normalize_platform(platform)
    adapters: dict[str, type] = {
        "boss": BossCloakExperimentalAdapter,
        "51job": Job51Adapter,
        "liepin": LiepinAdapter,
    }
    kwargs = {}
    if runtime_context is not None:
        kwargs["profile_dir"] = runtime_context.profile_dir
        kwargs["runtime_context"] = runtime_context
    return adapters[platform](**kwargs)
```

Add imports under `TYPE_CHECKING` or normal import:

```python
from app.domains.jobs.runtime import JobCrawlRuntimeContext
```

- [ ] **Step 5: Update task runner and crawl function signatures**

In `backend/app/domains/crawling/task_runner.py`, change:

```python
    async def run_job_config(
        self,
        task: CrawlTask,
        *,
        config_id: int,
        runtime_context=None,
    ) -> dict:
```

and call:

```python
        result = await crawl_single_config(config_id, runtime_context=runtime_context)
```

In `backend/app/domains/jobs/crawl_service.py`, add `runtime_context` to `crawl_single_config` parameters and pass it into `_create_adapter`.

- [ ] **Step 6: Run tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_runtime_context.py -q"
```

Expected: pass.

- [ ] **Step 7: Commit Task 3**

```powershell
git add backend/app/domains/jobs/runtime.py backend/app/domains/jobs/crawl_service.py backend/app/domains/crawling/task_runner.py backend/tests/test_job_runtime_context.py
git commit -m "Pass job crawl runtime context to adapters"
```

---

## Task 4: Use Config `profile_key` for Single and Scheduled Crawls

**Files:**
- Modify: `backend/app/domains/jobs/crawl_service.py`
- Modify: `backend/tests/test_integration_crawl_phase2.py`
- Modify: `backend/tests/test_job_crawl.py`

- [ ] **Step 1: Update failing tests for non-default profile key**

In `backend/tests/test_integration_crawl_phase2.py`, update the scheduled crawl profile test to create a config with `profile_key="job-a"` and assert:

```python
assert lease_calls[0]["profile_key"] == "job-a"
assert lease_calls[0]["platform"] == "boss"
```

In `backend/tests/test_job_crawl.py`, add:

```python
@pytest.mark.asyncio
async def test_manual_job_crawl_uses_config_profile_key(monkeypatch, tmp_path):
    from app.domains.jobs.crawl_service import crawl_single_config_background

    lease_calls = []

    async def fake_lease(self, db, *, platform, profile_key, owner, task_id):
        lease_calls.append({"platform": platform, "profile_key": profile_key})
        class LeaseContext:
            async def __aenter__(self_inner):
                from app.core.profile_lease import ProfileLease
                return ProfileLease(
                    platform=platform,
                    profile_key=profile_key,
                    profile_dir=tmp_path / "profiles" / profile_key,
                    owner=owner,
                    task_id=task_id,
                )
            async def __aexit__(self_inner, exc_type, exc, tb):
                return None
        return LeaseContext()

    monkeypatch.setattr("app.domains.crawling.profile_pool.DatabaseProfilePool.lease", fake_lease)
    monkeypatch.setattr(
        "app.domains.crawling.task_runner.CrawlTaskRunner.run_job_config",
        AsyncMock(return_value={"status": "success", "new_count": 0, "updated_count": 0, "deactivated_count": 0}),
    )

    task = await crawl_single_config_background(1, user_id=1)
    await asyncio.sleep(0.1)

    assert task.task_id
    assert lease_calls[0]["profile_key"] == "job-a"
```

Adapt the config fixture in this test file so config id `1` has `profile_key="job-a"`.

- [ ] **Step 2: Run failing targeted tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_integration_crawl_phase2.py::test_scheduled_job_crawl_uses_profile_pool tests/test_job_crawl.py -q"
```

Expected: fail because current code still passes `"default"`.

- [ ] **Step 3: Add config profile resolution helper**

In `backend/app/domains/jobs/crawl_service.py`, add:

```python
def _config_profile_key(config: JobSearchConfig | None) -> str:
    raw = getattr(config, "profile_key", None) if config is not None else None
    return raw or "default"
```

Use it wherever single/scheduled config tasks create task records and acquire profile leases:

```python
profile_key = _config_profile_key(config)
```

Then pass `profile_key=profile_key` into:

- `create_crawl_task_record`
- task `payload`
- `pool.lease(lease_db, platform=config_platform, profile_key=profile_key, owner=task.task_id, task_id=task.task_id)`
- `JobCrawlRuntimeContext`

- [ ] **Step 4: Build runtime context inside lease**

Inside each single/scheduled lease block:

```python
runtime_context = JobCrawlRuntimeContext(
    platform=config_platform,
    profile_key=lease.profile_key,
    profile_dir=lease.profile_dir,
    task_id=task.task_id,
    config_id=config_id,
    run_id=task.task_id,
    log_context={"source": task.source, "profile_key": lease.profile_key},
)
```

Pass it to:

```python
result = await CrawlTaskRunner(
    progress_callback=_persist_cron_progress
).run_job_config(
    task,
    config_id=config_id,
    runtime_context=runtime_context,
)
```

- [ ] **Step 5: Run targeted tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_integration_crawl_phase2.py::test_scheduled_job_crawl_uses_profile_pool tests/test_job_crawl.py -q"
```

Expected: pass.

- [ ] **Step 6: Commit Task 4**

```powershell
git add backend/app/domains/jobs/crawl_service.py backend/tests/test_integration_crawl_phase2.py backend/tests/test_job_crawl.py
git commit -m "Use job config profile key for single crawls"
```

---

## Task 5: Group Full Job Crawl by `(platform, profile_key)`

**Files:**
- Modify: `backend/app/domains/jobs/crawl_service.py`
- Test: `backend/tests/test_job_crawl_profile_grouping.py`

- [ ] **Step 1: Write grouping tests**

Create `backend/tests/test_job_crawl_profile_grouping.py`:

```python
from types import SimpleNamespace

import pytest


def test_group_job_configs_by_platform_and_profile():
    from app.domains.jobs.crawl_service import _group_job_configs_for_profile_leases

    configs = [
        SimpleNamespace(id=1, platform="boss", profile_key="job-a"),
        SimpleNamespace(id=2, platform="boss", profile_key="job-b"),
        SimpleNamespace(id=3, platform="51job", profile_key="job-a"),
        SimpleNamespace(id=4, platform="liepin", profile_key=None),
    ]

    groups = _group_job_configs_for_profile_leases(configs)

    assert list(groups.keys()) == [
        ("boss", "job-a"),
        ("boss", "job-b"),
        ("51job", "job-a"),
        ("liepin", "default"),
    ]
    assert [config.id for config in groups[("boss", "job-a")]] == [1]


@pytest.mark.asyncio
async def test_full_crawl_child_task_records_profile_key(monkeypatch):
    from app.domains.jobs import crawl_service

    metadata = crawl_service._job_group_task_metadata("boss", "job-a", "parent-1")

    assert metadata == {
        "task_type": "job_platform_profile",
        "platform": "boss",
        "profile_key": "job-a",
        "entity_type": "job_platform_profile",
        "entity_id": "boss:job-a",
        "payload": {
            "parent_task_id": "parent-1",
            "platform": "boss",
            "profile_key": "job-a",
        },
    }
```

- [ ] **Step 2: Run failing tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_crawl_profile_grouping.py -q"
```

Expected: fail because grouping helper does not exist.

- [ ] **Step 3: Add grouping helper**

In `backend/app/domains/jobs/crawl_service.py`, add:

```python
def _group_job_configs_for_profile_leases(
    configs: list[JobSearchConfig],
) -> dict[tuple[str, str], list[JobSearchConfig]]:
    grouped: dict[tuple[str, str], list[JobSearchConfig]] = {}
    for config in configs:
        platform = _normalize_platform(getattr(config, "platform", "boss"))
        profile_key = _config_profile_key(config)
        grouped.setdefault((platform, profile_key), []).append(config)
    return grouped


def _job_group_task_metadata(platform: str, profile_key: str, parent_task_id: str) -> dict:
    return {
        "task_type": "job_platform_profile",
        "platform": platform,
        "profile_key": profile_key,
        "entity_type": "job_platform_profile",
        "entity_id": f"{platform}:{profile_key}",
        "payload": {
            "parent_task_id": parent_task_id,
            "platform": platform,
            "profile_key": profile_key,
        },
    }
```

- [ ] **Step 4: Replace full crawl platform grouping**

In `crawl_all_job_searches_background`, replace `by_platform` with:

```python
groups = _group_job_configs_for_profile_leases(configs)
```

For each group, create child task:

```python
child_record = await create_crawl_task_record(
    db,
    source="manual",
    task_type="job_platform_profile",
    platform=platform,
    profile_key=profile_key,
    parent_task_id=parent_task.task_id,
    user_id=user_id,
    entity_type="job_platform_profile",
    entity_id=f"{platform}:{profile_key}",
    payload={
        "parent_task_id": parent_task.task_id,
        "platform": platform,
        "profile_key": profile_key,
    },
)
```

Lease with:

```python
async with pool.lease(
    lease_db,
    platform=platform,
    profile_key=profile_key,
    owner=child_task.task_id,
    task_id=child_task.task_id,
) as lease:
```

Build one runtime context per config inside the group so `config_id` is accurate:

```python
runtime_context = JobCrawlRuntimeContext(
    platform=platform,
    profile_key=lease.profile_key,
    profile_dir=lease.profile_dir,
    task_id=child_task.task_id,
    config_id=config.id,
    run_id=child_task.task_id,
    log_context={"parent_task_id": parent_task.task_id},
)
```

- [ ] **Step 5: Run grouping tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_crawl_profile_grouping.py tests/test_job_crawl.py -q"
```

Expected: pass.

- [ ] **Step 6: Commit Task 5**

```powershell
git add backend/app/domains/jobs/crawl_service.py backend/tests/test_job_crawl_profile_grouping.py backend/tests/test_job_crawl.py
git commit -m "Group full job crawls by platform and profile"
```

---

## Task 6: Add Shared JSONL Runtime Logging

**Files:**
- Create: `backend/app/platforms/job_runtime_logging.py`
- Modify: `backend/app/platforms/boss_cloak_experimental.py`
- Modify: `backend/app/platforms/job51.py`
- Modify: `backend/app/platforms/liepin.py`
- Test: `backend/tests/test_job_platform_logging_phase3.py`

- [ ] **Step 1: Write logging tests**

Create `backend/tests/test_job_platform_logging_phase3.py`:

```python
import json
from pathlib import Path


def test_job_jsonl_logger_writes_common_envelope(tmp_path):
    from app.domains.jobs.runtime import JobCrawlRuntimeContext
    from app.platforms.job_runtime_logging import JobRuntimeJsonlLogger

    context = JobCrawlRuntimeContext(
        platform="boss",
        profile_key="job-a",
        profile_dir=tmp_path / "profiles" / "job-a",
        task_id="task-1",
        config_id=101,
        run_id="run-1",
    )
    log_path = tmp_path / "job-runtime.jsonl"
    logger = JobRuntimeJsonlLogger(platform="boss", context=context, log_path=log_path)

    logger.log("crawl_start", status="running", message="started", count=3)

    payload = json.loads(log_path.read_text(encoding="utf-8").strip())
    assert payload["platform"] == "boss"
    assert payload["profile_key"] == "job-a"
    assert payload["task_id"] == "task-1"
    assert payload["config_id"] == 101
    assert payload["event"] == "crawl_start"
    assert payload["status"] == "running"
    assert payload["count"] == 3
```

- [ ] **Step 2: Run failing tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_platform_logging_phase3.py -q"
```

Expected: fail because shared logger does not exist.

- [ ] **Step 3: Add shared logger**

Create `backend/app/platforms/job_runtime_logging.py`:

```python
from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from app.domains.jobs.runtime import JobCrawlRuntimeContext


def default_job_log_path(platform: str) -> Path:
    timestamp = datetime.now(UTC).strftime("%Y%m%d_%H%M%S")
    return Path(__file__).resolve().parent.parent.parent / "logs" / f"{platform}_job_adapter_{timestamp}.jsonl"


class JobRuntimeJsonlLogger:
    def __init__(
        self,
        *,
        platform: str,
        context: JobCrawlRuntimeContext | None,
        log_path: str | Path | None = None,
        enabled: bool = True,
    ) -> None:
        self.platform = platform
        self.context = context
        self.enabled = enabled
        self.log_path = Path(log_path) if log_path else default_job_log_path(platform)

    def log(self, event: str, *, status: str, message: str = "", **fields: Any) -> None:
        if not self.enabled:
            return
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        payload: dict[str, Any] = {
            "timestamp": datetime.now(UTC).isoformat(),
            "platform": self.platform,
            "profile_key": self.context.profile_key if self.context else None,
            "task_id": self.context.task_id if self.context else None,
            "config_id": self.context.config_id if self.context else None,
            "event": event,
            "status": status,
            "message": message,
        }
        payload.update(fields)
        with self.log_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(payload, ensure_ascii=False, default=str) + "\n")
```

- [ ] **Step 4: Wire adapters to accept runtime context**

In each adapter `__init__`, add:

```python
        runtime_context=None,
```

and:

```python
        self.runtime_context = runtime_context
        self.runtime_logger = JobRuntimeJsonlLogger(
            platform="boss",
            context=runtime_context,
            log_path=log_path,
            enabled=log_enabled,
        )
```

Use the real platform string in each file: `"boss"`, `"51job"`, or `"liepin"`.

- [ ] **Step 5: Run logging tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_platform_logging_phase3.py -q"
```

Expected: pass.

- [ ] **Step 6: Commit Task 6**

```powershell
git add backend/app/platforms/job_runtime_logging.py backend/app/platforms/boss_cloak_experimental.py backend/app/platforms/job51.py backend/app/platforms/liepin.py backend/tests/test_job_platform_logging_phase3.py
git commit -m "Add shared job crawler JSONL logging"
```

---

## Task 7: Implement Boss Failure Classification and Profile Status Events

**Files:**
- Modify: `backend/app/platforms/boss_cloak_experimental.py`
- Modify: `backend/app/domains/jobs/crawl_service.py`
- Modify: `backend/app/domains/crawling/profile_service.py`
- Test: `backend/tests/test_boss_cloak_experimental.py`

- [ ] **Step 1: Add Boss classification tests**

In `backend/tests/test_boss_cloak_experimental.py`, add:

```python
def test_boss_anti_bot_codes_are_classified():
    from app.platforms.boss_cloak_experimental import classify_boss_failure

    assert classify_boss_failure({"code": 36}) == "anti_bot"
    assert classify_boss_failure({"code": 37}) == "anti_bot"
    assert classify_boss_failure({"code": 38}) == "anti_bot"
    assert classify_boss_failure({"code": 0}) is None


def test_boss_cookie_refresh_failure_returns_category(monkeypatch):
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    adapter = BossCloakExperimentalAdapter(profile_dir="profile")
    adapter._cookie_refresh_failures = 2

    assert adapter._profile_failure_category() == "cookie_refresh_failed"
```

- [ ] **Step 2: Run failing Boss tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_boss_cloak_experimental.py -q"
```

Expected: fail because helpers are missing.

- [ ] **Step 3: Add Boss helpers**

In `backend/app/platforms/boss_cloak_experimental.py`, add:

```python
BOSS_ANTI_BOT_CODES = {36, 37, 38}


def classify_boss_failure(payload: dict) -> str | None:
    code = payload.get("code")
    if code in BOSS_ANTI_BOT_CODES:
        return "anti_bot"
    return None
```

In `BossCloakExperimentalAdapter.__init__`, add:

```python
        self._cookie_refresh_failures = 0
```

Add:

```python
    def _profile_failure_category(self) -> str | None:
        if self._cookie_refresh_failures >= 2:
            return "cookie_refresh_failed"
        return None
```

- [ ] **Step 4: Emit logs and return categories**

Where Boss detects code `36`, `37`, or `38`, log:

```python
self.runtime_logger.log(
    "anti_bot",
    status="retrying",
    failure_category="anti_bot",
    message=f"Boss anti-bot code {code}; refreshing cookies",
    code=code,
)
```

When refresh fails twice, return:

```python
return {
    "success": False,
    "error": "Boss cookie refresh failed repeatedly",
    "failure_category": "cookie_refresh_failed",
    "profile_status": "login_required",
}
```

- [ ] **Step 5: Mark profile login required in crawl service**

In `crawl_single_config`, after adapter returns an error:

```python
failure_category = result.get("failure_category")
if result.get("profile_status") == "login_required" and runtime_context is not None:
    async with AsyncSessionLocal() as db:
        from app.domains.crawling.profile_service import update_profile
        await update_profile(
            db,
            profile_key=runtime_context.profile_key,
            status="login_required",
            platform_hint=platform,
            last_error=result.get("error") or failure_category,
        )
```

Include `failure_category` in the returned error dict and JobCrawlLog message.

- [ ] **Step 6: Run Boss tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_boss_cloak_experimental.py tests/test_job_runtime_context.py -q"
```

Expected: pass.

- [ ] **Step 7: Commit Task 7**

```powershell
git add backend/app/platforms/boss_cloak_experimental.py backend/app/domains/jobs/crawl_service.py backend/app/domains/crawling/profile_service.py backend/tests/test_boss_cloak_experimental.py
git commit -m "Classify Boss anti bot profile failures"
```

---

## Task 8: Add 51job JSONL Logging, WAF Fuse, and HTTP Experiment

**Files:**
- Modify: `backend/app/platforms/job51.py`
- Modify: `backend/app/domains/jobs/router.py`
- Test: `backend/tests/test_job_phase3_integration.py`

- [ ] **Step 1: Add 51job tests**

In `backend/tests/test_job_phase3_integration.py`, add:

```python
def test_51job_waf_fuse_stops_after_limit(monkeypatch):
    from app.platforms.job51 import Job51Adapter

    adapter = Job51Adapter(profile_dir="profile", max_pages=5)
    adapter._waf_hits = 2

    assert adapter._should_stop_for_waf() is True


def test_51job_classifies_html_waf_response():
    from app.platforms.job51 import classify_51job_response

    category = classify_51job_response(
        {"ok": True, "status": 200, "contentType": "text/html", "body": "<html>安全验证</html>"}
    )

    assert category == "waf"


def test_51job_http_experiment_returns_metrics(monkeypatch):
    from app.platforms.job51 import Job51Adapter

    adapter = Job51Adapter(profile_dir="profile", max_pages=1)
    monkeypatch.setattr(
        adapter,
        "_http_experiment_fetch",
        lambda url: {"success": False, "failure_category": "waf", "elapsed_ms": 25},
    )

    result = adapter.run_http_experiment(["https://we.51job.com/pc/search?keyword=python"])

    assert result["total"] == 1
    assert result["success_rate"] == 0.0
    assert result["waf_hit_rate"] == 1.0
```

- [ ] **Step 2: Run failing 51job tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_phase3_integration.py -q"
```

Expected: fail because 51job helpers and experiment do not exist.

- [ ] **Step 3: Add 51job classification and fuse**

In `backend/app/platforms/job51.py`, add:

```python
WAF_MARKERS = ("安全验证", "captcha", "verify", "waf", "滑块")
WAF_FUSE_LIMIT = 2


def classify_51job_response(response: dict) -> str | None:
    body = str(response.get("body") or "")
    content_type = str(response.get("contentType") or "").lower()
    lowered = body.lower()
    if "json" not in content_type:
        if any(marker in lowered for marker in WAF_MARKERS):
            return "waf"
        return "parse_error"
    return None
```

In `Job51Adapter.__init__`, add:

```python
        self._waf_hits = 0
```

Add:

```python
    def _should_stop_for_waf(self) -> bool:
        return self._waf_hits >= WAF_FUSE_LIMIT
```

In search page fetch handling, when classification is `"waf"`:

```python
self._waf_hits += 1
self.runtime_logger.log(
    "waf",
    status="blocked",
    failure_category="waf",
    message="51job WAF response detected",
    waf_hits=self._waf_hits,
)
if self._should_stop_for_waf():
    return {"success": False, "error": "51job WAF fuse tripped", "failure_category": "waf"}
```

- [ ] **Step 4: Add HTTP experiment method**

In `Job51Adapter`, add:

```python
    def _http_experiment_fetch(self, url: str) -> dict:
        start = time.perf_counter()
        try:
            response = self._get_session().get(url, impersonate="chrome124", timeout=20)
            elapsed_ms = int((time.perf_counter() - start) * 1000)
            category = classify_51job_response(
                {
                    "ok": response.ok,
                    "status": response.status_code,
                    "contentType": response.headers.get("content-type", ""),
                    "body": response.text,
                }
            )
            return {
                "success": response.ok and category is None,
                "failure_category": category,
                "elapsed_ms": elapsed_ms,
            }
        except Exception as exc:
            elapsed_ms = int((time.perf_counter() - start) * 1000)
            return {"success": False, "failure_category": "http_error", "elapsed_ms": elapsed_ms, "error": str(exc)}

    def run_http_experiment(self, urls: list[str]) -> dict:
        results = [self._http_experiment_fetch(url) for url in urls]
        total = len(results)
        success = sum(1 for item in results if item.get("success"))
        waf = sum(1 for item in results if item.get("failure_category") == "waf")
        elapsed = sum(int(item.get("elapsed_ms") or 0) for item in results)
        return {
            "total": total,
            "success": success,
            "success_rate": success / total if total else 0.0,
            "waf_hit_rate": waf / total if total else 0.0,
            "elapsed_ms": elapsed,
            "results": results,
        }
```

Add `import time`.

- [ ] **Step 5: Add diagnostic endpoint**

In `backend/app/domains/jobs/router.py`, add a super-admin protected endpoint:

```python
@router.post("/diagnostics/51job-http-experiment")
async def run_51job_http_experiment(
    urls: list[str],
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "super_admin":
        raise HTTPException(status_code=403, detail="super_admin required")
    from app.platforms.job51 import Job51Adapter

    adapter = Job51Adapter()
    return adapter.run_http_experiment(urls)
```

- [ ] **Step 6: Run 51job tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_phase3_integration.py -q"
```

Expected: pass.

- [ ] **Step 7: Commit Task 8**

```powershell
git add backend/app/platforms/job51.py backend/app/domains/jobs/router.py backend/tests/test_job_phase3_integration.py
git commit -m "Add 51job WAF fuse and HTTP experiment"
```

---

## Task 9: Make Liepin HTTP-Only and Classify Failures

**Files:**
- Modify: `backend/app/platforms/liepin.py`
- Test: `backend/tests/test_liepin_http_only_phase3.py`

- [ ] **Step 1: Write Liepin tests**

Create `backend/tests/test_liepin_http_only_phase3.py`:

```python
def test_liepin_has_no_cdp_fallback_methods():
    import app.platforms.liepin as liepin

    assert not hasattr(liepin.LiepinAdapter, "_crawl_via_cdp")
    assert not hasattr(liepin.LiepinAdapter, "_crawl_detail_via_cdp")


def test_liepin_classifies_challenge_html():
    from app.platforms.liepin import classify_liepin_failure

    assert classify_liepin_failure(status_code=200, text="<html>安全验证 passport</html>") == "challenge"


def test_liepin_classifies_xsrf_response():
    from app.platforms.liepin import classify_liepin_failure

    assert classify_liepin_failure(status_code=403, text="XSRF token invalid") == "xsrf"
```

- [ ] **Step 2: Run failing Liepin tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_http_only_phase3.py -q"
```

Expected: fail because CDP fallback methods still exist and classification helper is missing.

- [ ] **Step 3: Remove CDP fallback path**

In `backend/app/platforms/liepin.py`:

- Remove imports of `websockets`, `open_temporary_tab`, and `close_target` if they are only used by Liepin CDP fallback.
- Remove `_crawl_via_cdp`.
- Remove `_crawl_detail_via_cdp`.
- In `crawl`, return the HTTP result directly instead of falling back to CDP.
- In `crawl_detail`, return HTTP failure directly with `failure_category="detail_error"` or more specific category.

- [ ] **Step 4: Add classification helper**

Add:

```python
def classify_liepin_failure(*, status_code: int, text: str) -> str:
    lowered = (text or "").lower()
    if "xsrf" in lowered or "csrf" in lowered:
        return "xsrf"
    if status_code in {401, 403}:
        return "challenge"
    if any(marker in lowered for marker in ("captcha", "verify", "安全验证", "登录", "passport", "antibot")):
        return "challenge"
    if status_code >= 500:
        return "http_error"
    return "parse_error"
```

Use this helper inside `_parse_json_response`, `_crawl_search_http`, and `crawl_detail` error returns.

- [ ] **Step 5: Add JSONL log events**

Emit:

```python
self.runtime_logger.log("crawl_start", status="running", message="Liepin HTTP crawl started")
self.runtime_logger.log("list_page", status="success", count=len(jobs), message="Liepin list page parsed")
self.runtime_logger.log("crawl_failed", status="failed", failure_category=category, message=error_message)
self.runtime_logger.log("crawl_finish", status="success", count=len(jobs), message="Liepin HTTP crawl finished")
```

- [ ] **Step 6: Run Liepin tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_http_only_phase3.py -q"
```

Expected: pass.

- [ ] **Step 7: Commit Task 9**

```powershell
git add backend/app/platforms/liepin.py backend/tests/test_liepin_http_only_phase3.py
git commit -m "Make Liepin job crawling HTTP only"
```

---

## Task 10: Add Frontend Profile Management and Config Selection

**Files:**
- Modify: `frontend/src/features/jobs/types.ts`
- Modify: `frontend/src/features/jobs/api/jobs.ts`
- Modify: `frontend/src/features/jobs/hooks/useJobs.ts`
- Modify: `frontend/src/features/jobs/components/JobConfigForm.tsx`
- Modify: `frontend/src/features/jobs/components/JobConfigList.tsx`
- Create: `frontend/src/features/jobs/components/ProfileManagement.tsx`
- Modify: `frontend/src/features/jobs/JobsPage.tsx`
- Test: `frontend/tests/e2e/basic.spec.ts`

- [ ] **Step 1: Add frontend types and API**

In `frontend/src/features/jobs/types.ts`, add:

```ts
export type CrawlProfileStatus =
  | "available"
  | "leased"
  | "login_required"
  | "cooling_down"
  | "disabled";

export interface CrawlProfile {
  profile_key: string;
  profile_dir: string;
  status: CrawlProfileStatus;
  platform_hint: string | null;
  lease_owner: string | null;
  lease_task_id: string | null;
  lease_until: string | null;
  last_used_at: string | null;
  last_error: string | null;
  created_at: string;
  updated_at: string;
}

export interface CrawlProfileCreate {
  profile_key: string;
  platform_hint?: string | null;
}

export interface CrawlProfileUpdate {
  status?: "available" | "login_required" | "disabled" | null;
  platform_hint?: string | null;
  last_error?: string | null;
}
```

Add `profile_key: string` to `JobSearchConfig`, `JobSearchConfigCreate`, and `JobSearchConfigUpdate`.

In `frontend/src/features/jobs/api/jobs.ts`, import the new types and add:

```ts
  getProfiles: () => api.get<CrawlProfile[]>("/v1/crawl-profiles"),

  createProfile: (data: CrawlProfileCreate) =>
    api.post<CrawlProfile>("/v1/crawl-profiles", data),

  updateProfile: (profileKey: string, data: CrawlProfileUpdate) =>
    api.patch<CrawlProfile>(`/v1/crawl-profiles/${profileKey}`, data),

  releaseStaleProfile: (profileKey: string) =>
    api.post<CrawlProfile>(`/v1/crawl-profiles/${profileKey}/release-stale`),
```

- [ ] **Step 2: Add hooks**

In `frontend/src/features/jobs/hooks/useJobs.ts`, add:

```ts
export function useCrawlProfiles() {
  return useQuery({
    queryKey: ["crawl-profiles"],
    queryFn: () => jobsApi.getProfiles().then((res) => res.data),
  });
}

export function useCreateCrawlProfile() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: jobsApi.createProfile,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["crawl-profiles"] }),
  });
}

export function useUpdateCrawlProfile() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ profileKey, data }: { profileKey: string; data: CrawlProfileUpdate }) =>
      jobsApi.updateProfile(profileKey, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["crawl-profiles"] }),
  });
}

export function useReleaseStaleCrawlProfile() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: jobsApi.releaseStaleProfile,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["crawl-profiles"] }),
  });
}
```

- [ ] **Step 3: Add profile select to job config form**

Change `JobConfigFormProps` in `frontend/src/features/jobs/components/JobConfigForm.tsx`:

```ts
  profiles?: CrawlProfile[];
```

Set default:

```ts
      profile_key: "default",
```

Add form item after platform:

```tsx
        <Form.Item
          name="profile_key"
          label="Profile"
          rules={[{ required: true, message: "Please select profile" }]}
        >
          <Select
            showSearch
            optionFilterProp="label"
            options={(profiles || []).map((profile) => ({
              value: profile.profile_key,
              label: `${profile.profile_key} (${profile.status})`,
              disabled: profile.status === "disabled",
            }))}
          />
        </Form.Item>
```

- [ ] **Step 4: Show profile tag in config cards**

In `JobConfigList.tsx`, add:

```tsx
                      <Tag color="geekblue">
                        Profile: {config.profile_key || "default"}
                      </Tag>
```

Pass `profiles` into both `JobConfigForm` instances.

- [ ] **Step 5: Add ProfileManagement component**

Create `frontend/src/features/jobs/components/ProfileManagement.tsx`:

```tsx
import { useState } from "react";
import { App, Button, Form, Input, Modal, Select, Space, Table, Tag } from "antd";
import type { ColumnsType } from "antd/es/table";
import type { CrawlProfile } from "../types";

interface ProfileManagementProps {
  profiles?: CrawlProfile[];
  loading?: boolean;
  onCreate: (profileKey: string, platformHint?: string | null) => Promise<void>;
  onUpdateStatus: (profileKey: string, status: "available" | "login_required" | "disabled") => Promise<void>;
  onReleaseStale: (profileKey: string) => Promise<void>;
}

export default function ProfileManagement({
  profiles,
  loading,
  onCreate,
  onUpdateStatus,
  onReleaseStale,
}: ProfileManagementProps) {
  const message = App.useApp().message;
  const [open, setOpen] = useState(false);
  const [form] = Form.useForm<{ profile_key: string; platform_hint?: string }>();

  const columns: ColumnsType<CrawlProfile> = [
    { title: "Profile", dataIndex: "profile_key", width: 140 },
    {
      title: "Status",
      dataIndex: "status",
      width: 130,
      render: (value: CrawlProfile["status"]) => {
        const color = value === "available" ? "success" : value === "leased" ? "processing" : value === "disabled" ? "default" : "warning";
        return <Tag color={color}>{value}</Tag>;
      },
    },
    { title: "Platform", dataIndex: "platform_hint", width: 120, render: (value) => value || "-" },
    { title: "Task", dataIndex: "lease_task_id", width: 180, render: (value) => value || "-" },
    { title: "Lease Until", dataIndex: "lease_until", width: 180, render: (value) => value ? new Date(value).toLocaleString() : "-" },
    { title: "Last Error", dataIndex: "last_error", render: (value) => value || "-" },
    {
      title: "Actions",
      width: 280,
      render: (_, record) => (
        <Space wrap>
          <Button size="small" onClick={() => onUpdateStatus(record.profile_key, "available")}>Available</Button>
          <Button size="small" onClick={() => onUpdateStatus(record.profile_key, "login_required")}>Login Required</Button>
          <Button size="small" danger onClick={() => onUpdateStatus(record.profile_key, "disabled")}>Disable</Button>
          <Button size="small" onClick={() => onReleaseStale(record.profile_key)}>Release Stale</Button>
        </Space>
      ),
    },
  ];

  const handleCreate = async () => {
    const values = await form.validateFields();
    await onCreate(values.profile_key, values.platform_hint || null);
    form.resetFields();
    setOpen(false);
    message.success("Profile created");
  };

  return (
    <>
      <Space style={{ width: "100%", justifyContent: "space-between", marginBottom: 12 }}>
        <span />
        <Button onClick={() => setOpen(true)}>Create Profile</Button>
      </Space>
      <Table<CrawlProfile>
        rowKey="profile_key"
        columns={columns}
        dataSource={profiles || []}
        loading={loading}
        size="small"
      />
      <Modal title="Create Profile" open={open} onOk={handleCreate} onCancel={() => setOpen(false)}>
        <Form form={form} layout="vertical">
          <Form.Item name="profile_key" label="Profile Key" rules={[{ required: true }]}>
            <Input placeholder="job-a" autoComplete="off" />
          </Form.Item>
          <Form.Item name="platform_hint" label="Platform Hint">
            <Select allowClear options={[
              { value: "boss", label: "Boss" },
              { value: "51job", label: "51job" },
              { value: "liepin", label: "Liepin" },
            ]} />
          </Form.Item>
        </Form>
      </Modal>
    </>
  );
}
```

- [ ] **Step 6: Add Jobs page Profiles tab**

In `JobsPage.tsx`, import profile hooks and component. Create handlers:

```ts
const { data: profiles, isLoading: profilesLoading } = useCrawlProfiles();
const createProfile = useCreateCrawlProfile();
const updateProfile = useUpdateCrawlProfile();
const releaseStaleProfile = useReleaseStaleCrawlProfile();

const handleCreateProfile = async (profileKey: string, platformHint?: string | null) => {
  await createProfile.mutateAsync({ profile_key: profileKey, platform_hint: platformHint });
};

const handleUpdateProfileStatus = async (
  profileKey: string,
  status: "available" | "login_required" | "disabled",
) => {
  await updateProfile.mutateAsync({ profileKey, data: { status } });
};
```

Pass `profiles={profiles}` into `JobConfigList`.

Add tab:

```tsx
{
  key: "profiles",
  label: "Profiles",
  children: (
    <Card size="small" title="Crawler Profiles">
      <ProfileManagement
        profiles={profiles}
        loading={profilesLoading}
        onCreate={handleCreateProfile}
        onUpdateStatus={handleUpdateProfileStatus}
        onReleaseStale={(profileKey) => releaseStaleProfile.mutateAsync(profileKey)}
      />
    </Card>
  ),
}
```

- [ ] **Step 7: Run frontend checks**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run lint"
```

Expected: pass.

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"
```

Expected: pass.

- [ ] **Step 8: Commit Task 10**

```powershell
git add frontend/src/features/jobs/types.ts frontend/src/features/jobs/api/jobs.ts frontend/src/features/jobs/hooks/useJobs.ts frontend/src/features/jobs/components/JobConfigForm.tsx frontend/src/features/jobs/components/JobConfigList.tsx frontend/src/features/jobs/components/ProfileManagement.tsx frontend/src/features/jobs/JobsPage.tsx
git commit -m "Add job crawler profile management UI"
```

---

## Task 11: End-to-End Verification and Documentation

**Files:**
- Modify: `docs/2026-05-25-crawler-production-todo.md`
- Test: backend and frontend suites

- [ ] **Step 1: Run database migration**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; alembic upgrade head"
```

Expected: migration succeeds and `jobs_search_configs.profile_key` exists.

- [ ] **Step 2: Run backend targeted tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_job_config_profile_key.py tests/test_crawl_profile_api.py tests/test_job_runtime_context.py tests/test_job_crawl_profile_grouping.py tests/test_job_platform_logging_phase3.py tests/test_boss_cloak_experimental.py tests/test_job_phase3_integration.py tests/test_liepin_http_only_phase3.py -q"
```

Expected: all selected tests pass.

- [ ] **Step 3: Run backend full suite**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest -q"
```

Expected: full backend suite passes.

- [ ] **Step 4: Run backend lint**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check ."
```

Expected: no ruff errors.

- [ ] **Step 5: Run frontend checks**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run lint"
```

Expected: pass.

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"
```

Expected: pass.

- [ ] **Step 6: Run local front/back integration**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"
```

Expected:

- Frontend is available at `http://127.0.0.1:3000`.
- Backend is available at `http://127.0.0.1:8000`.

Browser verification:

- Log in with `default123` / `123456`.
- Open Jobs page.
- Open Profiles tab.
- Create `job-a` and `job-b`.
- Create or edit two Boss configs and assign different profile keys.
- Trigger full job crawl.
- Confirm task records show child groups by `(platform, profile_key)`.
- Confirm Event Center includes crawl start/completion/failure and profile status events.
- Confirm JSONL files exist under `backend/logs`.

- [ ] **Step 7: Run real environment crawler checks**

With real profile login state prepared in `/profiles/{profile_key}`:

- Boss: run two Boss configs with different profile keys and confirm both groups can run in the same all-crawl.
- Boss: force or observe anti-bot code handling and confirm `failure_category` is `anti_bot` or `cookie_refresh_failed`.
- 51job: run one config through the default CloakBrowser path and confirm JSONL events.
- 51job: run the HTTP experiment endpoint and record success rate, WAF hit rate, and elapsed time.
- Liepin: run one config and confirm no CDP tab opens during list or detail crawl.

- [ ] **Step 8: Update status tracker**

In `docs/2026-05-25-crawler-production-todo.md`, mark Phase 3 tasks done only after the targeted and real environment checks pass.

- [ ] **Step 9: Run GitNexus change detection before final commit**

Run GitNexus staged/all-scope detect changes before committing final polish:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; npx gitnexus analyze"
```

Then run `gitnexus_detect_changes(scope="all")` through the MCP tool and review affected processes.

- [ ] **Step 10: Commit verification docs**

```powershell
git add docs/2026-05-25-crawler-production-todo.md
git commit -m "Document phase 3 crawler production verification"
```

---

## Self-Review

### Spec Coverage

- `profile_key` on job configs: Task 1.
- Existing profile required before assignment: Task 1 and Task 2.
- Profile management API/UI: Task 2 and Task 10.
- Adapter runtime profile injection: Task 3 and Task 4.
- Manual/scheduled task `profile_key`: Task 4.
- Full crawl grouped by `(platform, profile_key)`: Task 5.
- JSONL common envelope: Task 6.
- Boss anti-bot and login-required profile status: Task 7.
- 51job JSONL, WAF fuse, HTTP-only experiment: Task 8.
- Liepin HTTP-only and failure classification: Task 9.
- Event Center coverage: Task 2, Task 7, Task 8, Task 11.
- Security boundaries for profile keys and no profile content exposure: Task 1, Task 2, Task 10.
- Real environment front/back integration: Task 11.

### Type Consistency

- `profile_key` is snake_case in backend models, schemas, API payloads, and frontend API types because existing frontend job types already mirror backend response names.
- `JobCrawlRuntimeContext.profile_dir` is a `Path`; adapters already accept `str | Path`.
- Profile statuses match `available`, `leased`, `login_required`, `cooling_down`, and `disabled`.
- Failure categories match the design spec names.

### Execution Notes

- Keep commits task-sized. Do not combine platform adapter changes with frontend UI changes.
- Run targeted tests after each task. Run full backend and frontend checks only after Task 10.
- Preserve existing user-local changes in `AGENTS.md` and `CLAUDE.md`.
- Do not change product crawler profile behavior in this phase.
