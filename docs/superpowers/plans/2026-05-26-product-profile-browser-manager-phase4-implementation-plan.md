# Product Profile Browser Manager Phase 4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make JD, Taobao/Tmall, and Amazon product crawling use managed platform-level browser profiles through a shared BrowserManager while keeping existing API behavior compatible.

**Architecture:** Product platform cron config owns the product profile binding through `products_platform_crons.profile_key`. FastAPI/APScheduler remains the executor in Phase 4, but product crawl execution changes from adapter-owned browser lifecycle to BrowserManager-owned persistent Playwright contexts leased from the existing profile pool. Product adapters keep extraction logic and expose a page-based entry point; the old `crawl(url)` path remains as compatibility fallback.

**Tech Stack:** Python 3.11+, FastAPI, SQLAlchemy async, Alembic, PostgreSQL, Playwright async API, pytest, React, Vite, TypeScript, Ant Design.

---

## Scope Boundaries

This plan implements the approved Phase 4 design only.

In scope:

- Product platform profile binding for `jd`, `taobao`, and `amazon`.
- BrowserManager for product persistent browser sessions.
- Profile-first product crawl execution inside the current FastAPI/APScheduler process.
- Schedule page UI for product platform profile selection, status, stale lease release, and profile creation.
- Event Center coverage for profile/browser lifecycle failures.
- Compatibility paths for old CDP/JD cookie behavior, gated away from production default.

Out of scope:

- No `python -m app.workers.crawler`.
- No independent crawler worker process.
- No per-product profile selection.
- No raw cookie file storage requirement.
- No forced Amazon HTTP fast path.
- No removal of existing CDP compatibility code.

## File Structure

Create:

- `backend/alembic/versions/2026_05_26_add_product_cron_profile_key.py` - migration adding `profile_key` to product platform cron configs and backfilling default profiles.
- `backend/app/domains/products/profile_binding.py` - product platform profile defaults, validation, and profile creation helpers.
- `backend/app/domains/crawling/browser_manager.py` - persistent context lifecycle, session object, lease integration, and browser events.
- `backend/tests/test_product_profile_binding.py` - backend tests for config profile binding and validation.
- `backend/tests/test_browser_manager.py` - unit tests for BrowserManager lease, status, and failure behavior.
- `backend/tests/test_product_profile_crawl_runner.py` - tests for product crawl grouping and task `profile_key`.
- `frontend/src/features/schedule/components/ProductProfileCell.tsx` - focused product profile status/select/create control used by the schedule table.
- `frontend/tests/e2e/product-profile-schedule.spec.ts` - UI smoke coverage for product profile binding controls.

Modify:

- `backend/app/models/product.py` - add `ProductPlatformCron.profile_key`.
- `backend/app/schemas/product.py` - include `profile_key` in create/update/response schemas.
- `backend/app/domains/products/repository.py` - persist profile binding.
- `backend/app/domains/products/service.py` - default profile resolution and validation.
- `backend/app/domains/products/router.py` - keep response shape compatible while accepting `profile_key`.
- `backend/app/domains/crawling/task_runner.py` - group product crawls by platform profile and run one BrowserManager session per profile lane.
- `backend/app/domains/crawling/service.py` - add page/session product crawl path while preserving `crawl_one(product_id)`.
- `backend/app/domains/crawling/scheduler_service.py` - persist task `profile_key`, use profile-first runner for product crawl tasks, and keep cleanup behavior compatible.
- `backend/app/platforms/base.py` - add `crawl_with_page(url, page)` and make `crawl(url)` delegate to it after creating a page.
- `backend/app/platforms/jd.py` - gate `JD_COOKIE` injection behind an explicit fallback setting and add login-required classification hooks.
- `backend/app/core/config.py` - add product fallback settings with production-safe defaults.
- `frontend/src/features/products/api/products.ts` - add product cron `profile_key` types and payloads.
- `frontend/src/features/schedule/ScheduleConfigPage.tsx` - render product profile controls and save profile binding with cron config.
- `frontend/src/features/jobs/components/ProfileManagement.tsx` - include product platforms in `platform_hint` options.
- `docs/2026-05-25-crawler-production-todo.md` - mark Phase 4 tasks as in progress/done after implementation.

## Default Profile Contract

Use this exact mapping everywhere:

```python
PRODUCT_PLATFORM_DEFAULT_PROFILE_KEYS = {
    "jd": "product-jd-default",
    "taobao": "product-taobao-default",
    "amazon": "product-amazon-default",
}
```

One profile can contain login state for multiple sites, but one profile directory can only be leased by one crawl task at a time. Product crawl execution must never open two Playwright persistent contexts for the same `profile_key`.

---

### Task 1: Add Product Platform Profile Binding

**Files:**

- Create: `backend/alembic/versions/2026_05_26_add_product_cron_profile_key.py`
- Create: `backend/app/domains/products/profile_binding.py`
- Create: `backend/tests/test_product_profile_binding.py`
- Modify: `backend/app/models/product.py`
- Modify: `backend/app/schemas/product.py`
- Modify: `backend/app/domains/products/repository.py`
- Modify: `backend/app/domains/products/service.py`
- Modify: `backend/app/domains/products/router.py`

- [ ] **Step 1: Write failing schema/service tests**

Create `backend/tests/test_product_profile_binding.py`:

```python
import pytest

from app.domains.crawling.profile_service import create_profile
from app.domains.products import service as product_service
from app.domains.products.profile_binding import default_product_profile_key
from app.schemas.product import ProductPlatformCronCreate, ProductPlatformCronUpdate


pytestmark = pytest.mark.asyncio


def test_default_product_profile_key_mapping():
    assert default_product_profile_key("jd") == "product-jd-default"
    assert default_product_profile_key("taobao") == "product-taobao-default"
    assert default_product_profile_key("amazon") == "product-amazon-default"


async def test_create_product_cron_config_uses_default_profile(async_session):
    config = await product_service.create_product_cron_config(
        async_session,
        user_id=1,
        data=ProductPlatformCronCreate(
            platform="jd",
            cron_expression="0 9 * * *",
            cron_timezone="Asia/Shanghai",
        ),
    )

    assert config.profile_key == "product-jd-default"


async def test_create_product_cron_config_rejects_unknown_profile(async_session):
    with pytest.raises(product_service.ProductProfileConfigError) as exc:
        await product_service.create_product_cron_config(
            async_session,
            user_id=1,
            data=ProductPlatformCronCreate(
                platform="jd",
                cron_expression="0 9 * * *",
                cron_timezone="Asia/Shanghai",
                profile_key="missing-profile",
            ),
        )

    assert "missing-profile" in str(exc.value)


async def test_update_product_cron_config_can_change_profile(async_session):
    await create_profile(
        async_session,
        profile_key="product-jd-secondary",
        platform_hint="jd",
    )
    await product_service.create_product_cron_config(
        async_session,
        user_id=1,
        data=ProductPlatformCronCreate(
            platform="jd",
            cron_expression="0 9 * * *",
            cron_timezone="Asia/Shanghai",
        ),
    )

    updated = await product_service.update_product_cron_config(
        async_session,
        user_id=1,
        platform="jd",
        data=ProductPlatformCronUpdate(
            cron_expression="30 10 * * *",
            cron_timezone="Asia/Shanghai",
            profile_key="product-jd-secondary",
        ),
    )

    assert updated.profile_key == "product-jd-secondary"
```

- [ ] **Step 2: Run the failing tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_product_profile_binding.py -q"
```

Expected: FAIL because `profile_binding.py`, `profile_key`, and `ProductProfileConfigError` do not exist.

- [ ] **Step 3: Add migration**

Create `backend/alembic/versions/2026_05_26_add_product_cron_profile_key.py`:

```python
"""add product cron profile key

Revision ID: 20260526_product_cron_profile
Revises: 20260526_job_profile_key
Create Date: 2026-05-26 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260526_product_cron_profile"
down_revision: Union[str, None] = "20260526_job_profile_key"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


DEFAULT_KEYS = {
    "jd": "product-jd-default",
    "taobao": "product-taobao-default",
    "amazon": "product-amazon-default",
}


def upgrade() -> None:
    op.add_column(
        "products_platform_crons",
        sa.Column("profile_key", sa.String(length=80), nullable=True),
    )

    conn = op.get_bind()
    for platform, profile_key in DEFAULT_KEYS.items():
        conn.execute(
            sa.text(
                """
                INSERT INTO crawl_profiles (
                    profile_key, profile_dir, status, platform_hint,
                    lease_owner, lease_task_id, lease_until,
                    last_used_at, last_error, created_at, updated_at
                )
                VALUES (
                    :profile_key, :profile_dir, 'available', :platform,
                    NULL, NULL, NULL,
                    NULL, NULL, NOW(), NOW()
                )
                ON CONFLICT (profile_key) DO NOTHING
                """
            ),
            {
                "profile_key": profile_key,
                "profile_dir": f"profiles/{profile_key}",
                "platform": platform,
            },
        )
        conn.execute(
            sa.text(
                """
                UPDATE products_platform_crons
                SET profile_key = :profile_key
                WHERE platform = :platform AND profile_key IS NULL
                """
            ),
            {"profile_key": profile_key, "platform": platform},
        )

    op.alter_column("products_platform_crons", "profile_key", nullable=False)
    op.create_index(
        "ix_products_platform_crons_profile_key",
        "products_platform_crons",
        ["profile_key"],
    )
    op.create_foreign_key(
        "fk_products_platform_crons_profile_key_crawl_profiles",
        "products_platform_crons",
        "crawl_profiles",
        ["profile_key"],
        ["profile_key"],
        ondelete="RESTRICT",
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_products_platform_crons_profile_key_crawl_profiles",
        "products_platform_crons",
        type_="foreignkey",
    )
    op.drop_index(
        "ix_products_platform_crons_profile_key",
        table_name="products_platform_crons",
    )
    op.drop_column("products_platform_crons", "profile_key")
```

- [ ] **Step 4: Add model and schema fields**

In `backend/app/models/product.py`, add the column to `ProductPlatformCron`:

```python
profile_key = Column(String(80), ForeignKey("crawl_profiles.profile_key"), nullable=False)
```

Ensure imports include:

```python
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String, Text, UniqueConstraint
```

In `backend/app/schemas/product.py`, update product cron schemas:

```python
class ProductPlatformCronResponse(BaseModel):
    id: int
    user_id: int
    platform: str
    cron_expression: str | None
    cron_timezone: str
    profile_key: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProductPlatformCronCreate(BaseModel):
    platform: str
    cron_expression: str | None = None
    cron_timezone: str | None = None
    profile_key: str | None = None


class ProductPlatformCronUpdate(BaseModel):
    cron_expression: str | None = None
    cron_timezone: str | None = None
    profile_key: str | None = None
```

- [ ] **Step 5: Add profile binding helper**

Create `backend/app/domains/products/profile_binding.py`:

```python
from sqlalchemy.ext.asyncio import AsyncSession

from app.domains.crawling.profile_pool import ensure_profile
from app.domains.crawling.profile_service import CrawlProfileNotFoundError, get_profile
from app.models.crawl_profile import CrawlProfile


PRODUCT_PLATFORM_DEFAULT_PROFILE_KEYS: dict[str, str] = {
    "jd": "product-jd-default",
    "taobao": "product-taobao-default",
    "amazon": "product-amazon-default",
}


def default_product_profile_key(platform: str) -> str:
    try:
        return PRODUCT_PLATFORM_DEFAULT_PROFILE_KEYS[platform]
    except KeyError as exc:
        raise ValueError(f"Unsupported product platform: {platform}") from exc


async def resolve_product_profile(
    db: AsyncSession,
    *,
    platform: str,
    profile_key: str | None,
) -> CrawlProfile:
    if profile_key is None:
        return await ensure_profile(
            db,
            profile_key=default_product_profile_key(platform),
            platform_hint=platform,
        )

    try:
        return await get_profile(db, profile_key)
    except CrawlProfileNotFoundError as exc:
        raise ValueError(f"Unknown crawl profile: {profile_key}") from exc
```

- [ ] **Step 6: Persist and validate profile_key in product service/repository**

Modify `backend/app/domains/products/repository.py`:

```python
async def create_product_cron_config(
    db: AsyncSession,
    *,
    user_id: int,
    platform: str,
    cron_expression: str | None,
    cron_timezone: str | None,
    profile_key: str,
) -> ProductPlatformCron:
    config = ProductPlatformCron(
        user_id=user_id,
        platform=platform,
        cron_expression=cron_expression,
        cron_timezone=cron_timezone or "Asia/Shanghai",
        profile_key=profile_key,
    )
    db.add(config)
    await db.commit()
    await db.refresh(config)
    return config


async def update_product_cron_config(
    db: AsyncSession,
    *,
    config: ProductPlatformCron,
    cron_expression: str | None,
    cron_timezone: str | None,
    profile_key: str,
) -> ProductPlatformCron:
    config.cron_expression = cron_expression
    config.cron_timezone = cron_timezone or "Asia/Shanghai"
    config.profile_key = profile_key
    await db.commit()
    await db.refresh(config)
    return config
```

Modify `backend/app/domains/products/service.py`:

```python
from app.domains.products.profile_binding import resolve_product_profile


class ProductProfileConfigError(ValueError):
    """Raised when a product platform profile binding is invalid."""


async def _resolve_profile_key(
    db: AsyncSession,
    *,
    platform: str,
    profile_key: str | None,
) -> str:
    try:
        profile = await resolve_product_profile(
            db,
            platform=platform,
            profile_key=profile_key,
        )
    except ValueError as exc:
        raise ProductProfileConfigError(str(exc)) from exc
    return profile.profile_key
```

Use `_resolve_profile_key()` inside `create_product_cron_config()` and `update_product_cron_config()` before repository calls:

```python
resolved_profile_key = await _resolve_profile_key(
    db,
    platform=data.platform,
    profile_key=data.profile_key,
)
return await repository.create_product_cron_config(
    db,
    user_id=user_id,
    platform=data.platform,
    cron_expression=data.cron_expression,
    cron_timezone=data.cron_timezone,
    profile_key=resolved_profile_key,
)
```

For update:

```python
resolved_profile_key = await _resolve_profile_key(
    db,
    platform=platform,
    profile_key=data.profile_key or config.profile_key,
)
return await repository.update_product_cron_config(
    db,
    config=config,
    cron_expression=data.cron_expression,
    cron_timezone=data.cron_timezone,
    profile_key=resolved_profile_key,
)
```

- [ ] **Step 7: Return 400 for invalid profile bindings**

In `backend/app/domains/products/router.py`, catch `ProductProfileConfigError` in create/update endpoints:

```python
except product_service.ProductProfileConfigError as exc:
    raise HTTPException(status_code=400, detail=str(exc)) from exc
```

- [ ] **Step 8: Run migration and tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; alembic upgrade head"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_product_profile_binding.py -q"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app/models/product.py app/domains/products tests/test_product_profile_binding.py"
```

Expected: migration succeeds, tests PASS, ruff PASS.

- [ ] **Step 9: Commit Task 1**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git add backend/alembic/versions/2026_05_26_add_product_cron_profile_key.py backend/app/models/product.py backend/app/schemas/product.py backend/app/domains/products/profile_binding.py backend/app/domains/products/repository.py backend/app/domains/products/service.py backend/app/domains/products/router.py backend/tests/test_product_profile_binding.py"
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git commit -m 'feat: bind product cron configs to crawl profiles'"
```

---

### Task 2: Implement BrowserManager

**Files:**

- Create: `backend/app/domains/crawling/browser_manager.py`
- Create: `backend/tests/test_browser_manager.py`
- Modify: `backend/app/domains/crawling/profile_pool.py` only if the existing acquire/release API needs a small wrapper-compatible return value.

- [ ] **Step 1: Write failing BrowserManager tests**

Create `backend/tests/test_browser_manager.py` with fake Playwright objects:

```python
from contextlib import asynccontextmanager

import pytest

from app.domains.crawling.browser_manager import (
    BrowserManager,
    BrowserProfileUnavailableError,
)
from app.domains.crawling.profile_pool import LOGIN_REQUIRED, ensure_profile


pytestmark = pytest.mark.asyncio


class FakePage:
    def __init__(self):
        self.closed = False

    async def close(self):
        self.closed = True


class FakeContext:
    def __init__(self):
        self.closed = False
        self.pages = []

    async def new_page(self):
        page = FakePage()
        self.pages.append(page)
        return page

    async def close(self):
        self.closed = True


class FakeChromium:
    def __init__(self, context):
        self.context = context
        self.launch_args = None

    async def launch_persistent_context(self, user_data_dir, **kwargs):
        self.launch_args = {"user_data_dir": str(user_data_dir), **kwargs}
        return self.context


class FakePlaywright:
    def __init__(self, context):
        self.chromium = FakeChromium(context)


@asynccontextmanager
async def fake_playwright_factory(context):
    yield FakePlaywright(context)


async def test_browser_manager_acquires_and_releases_profile(async_session):
    await ensure_profile(async_session, profile_key="product-jd-default", platform_hint="jd")
    fake_context = FakeContext()
    manager = BrowserManager(
        db_factory=lambda: async_session,
        playwright_factory=lambda: fake_playwright_factory(fake_context),
    )

    async with manager.acquire(
        platform="jd",
        profile_key="product-jd-default",
        owner="test-owner",
        task_id="task-1",
    ) as session:
        page = await session.new_page()
        await session.close_page(page)
        assert page.closed is True
        assert session.profile_key == "product-jd-default"

    assert fake_context.closed is True


async def test_browser_manager_refuses_login_required_before_launch(async_session):
    profile = await ensure_profile(
        async_session,
        profile_key="product-jd-default",
        platform_hint="jd",
    )
    profile.status = LOGIN_REQUIRED
    await async_session.commit()
    fake_context = FakeContext()
    manager = BrowserManager(
        db_factory=lambda: async_session,
        playwright_factory=lambda: fake_playwright_factory(fake_context),
    )

    with pytest.raises(BrowserProfileUnavailableError) as exc:
        async with manager.acquire(
            platform="jd",
            profile_key="product-jd-default",
            owner="test-owner",
            task_id="task-1",
        ):
            pass

    assert "login_required" in str(exc.value)
    assert fake_context.closed is False


async def test_browser_manager_records_startup_failure(async_session):
    await ensure_profile(async_session, profile_key="product-jd-default", platform_hint="jd")

    class BrokenChromium:
        async def launch_persistent_context(self, user_data_dir, **kwargs):
            raise RuntimeError("browser failed to start")

    class BrokenPlaywright:
        chromium = BrokenChromium()

    @asynccontextmanager
    async def broken_factory():
        yield BrokenPlaywright()

    manager = BrowserManager(
        db_factory=lambda: async_session,
        playwright_factory=broken_factory,
    )

    with pytest.raises(RuntimeError, match="browser failed to start"):
        async with manager.acquire(
            platform="jd",
            profile_key="product-jd-default",
            owner="test-owner",
            task_id="task-1",
        ):
            pass

    await async_session.refresh(
        await ensure_profile(async_session, profile_key="product-jd-default", platform_hint="jd")
    )
```

After implementing, replace the final refresh block with a direct query assertion:

```python
profile = await get_profile(async_session, "product-jd-default")
assert "browser failed to start" in profile.last_error
```

- [ ] **Step 2: Run failing tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_browser_manager.py -q"
```

Expected: FAIL because `browser_manager.py` does not exist.

- [ ] **Step 3: Implement BrowserManager and BrowserSession**

Create `backend/app/domains/crawling/browser_manager.py`:

```python
from __future__ import annotations

from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import AsyncIterator, Callable
from uuid import uuid4

from playwright.async_api import BrowserContext, Page, async_playwright
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.crawler_paths import build_profile_dir
from app.core.database import async_session_maker
from app.core.system_log import emit_system_log_detached
from app.domains.crawling.profile_pool import (
    AVAILABLE,
    COOLING_DOWN,
    DISABLED,
    LOGIN_REQUIRED,
    DatabaseProfilePool,
)
from app.domains.crawling.profile_service import get_profile


BLOCKED_PROFILE_STATUSES = {LOGIN_REQUIRED, DISABLED, COOLING_DOWN}


class BrowserProfileUnavailableError(RuntimeError):
    """Raised when a profile cannot be leased or used."""


class BrowserPageLimitError(RuntimeError):
    """Raised when a session tries to open more pages than allowed."""


@dataclass
class BrowserSession:
    profile_key: str
    profile_dir: Path
    platform: str
    context: BrowserContext
    max_pages: int = 1
    _open_pages: set[Page] = field(default_factory=set)

    async def new_page(self) -> Page:
        if len(self._open_pages) >= self.max_pages:
            raise BrowserPageLimitError(
                f"profile {self.profile_key} reached max_pages={self.max_pages}"
            )
        page = await self.context.new_page()
        self._open_pages.add(page)
        return page

    async def close_page(self, page: Page) -> None:
        try:
            await page.close()
        finally:
            self._open_pages.discard(page)

    async def close(self) -> None:
        for page in list(self._open_pages):
            await self.close_page(page)
        await self.context.close()


class BrowserManager:
    def __init__(
        self,
        *,
        db_factory: async_sessionmaker[AsyncSession] | Callable[[], AsyncSession] = async_session_maker,
        playwright_factory=async_playwright,
        max_pages: int = 1,
    ) -> None:
        self._db_factory = db_factory
        self._playwright_factory = playwright_factory
        self._max_pages = max_pages

    @asynccontextmanager
    async def _db(self) -> AsyncIterator[AsyncSession]:
        session_or_cm = self._db_factory()
        if hasattr(session_or_cm, "__aenter__"):
            async with session_or_cm as session:
                yield session
        else:
            yield session_or_cm

    async def _mark_profile_error(self, profile_key: str, error: str) -> None:
        async with self._db() as db:
            profile = await get_profile(db, profile_key)
            profile.last_error = error[:2000]
            profile.updated_at = datetime.now(UTC)
            await db.commit()

    async def _assert_profile_usable(self, db: AsyncSession, profile_key: str) -> None:
        profile = await get_profile(db, profile_key)
        if profile.status in BLOCKED_PROFILE_STATUSES:
            await emit_system_log_detached(
                category="runtime",
                event_type=f"product_profile.{profile.status}",
                source="crawler",
                severity="warning",
                status="failed",
                message=f"Product profile {profile_key} is {profile.status}",
                entity_type="crawl_profile",
                entity_id=profile_key,
                payload={"profile_key": profile_key, "status": profile.status},
            )
            raise BrowserProfileUnavailableError(
                f"profile {profile_key} is {profile.status}"
            )

    @asynccontextmanager
    async def acquire(
        self,
        *,
        platform: str,
        profile_key: str,
        owner: str,
        task_id: str | None = None,
    ) -> AsyncIterator[BrowserSession]:
        task_id = task_id or str(uuid4())
        profile_dir = build_profile_dir(profile_key)
        context: BrowserContext | None = None
        pool: DatabaseProfilePool | None = None
        async with self._db() as db:
            await self._assert_profile_usable(db, profile_key)
            pool = DatabaseProfilePool(db)
            lease = await pool.acquire(
                profile_key=profile_key,
                owner=owner,
                task_id=task_id,
            )
            if lease is None:
                await emit_system_log_detached(
                    category="runtime",
                    event_type="product_profile.leased",
                    source="crawler",
                    severity="warning",
                    status="failed",
                    message=f"Product profile {profile_key} is already leased",
                    entity_type="crawl_profile",
                    entity_id=profile_key,
                    payload={"profile_key": profile_key, "task_id": task_id},
                )
                raise BrowserProfileUnavailableError(
                    f"profile {profile_key} is already leased"
                )

        try:
            async with self._playwright_factory() as playwright:
                try:
                    context = await playwright.chromium.launch_persistent_context(
                        str(profile_dir),
                        headless=True,
                        args=["--disable-blink-features=AutomationControlled"],
                    )
                except Exception as exc:
                    await self._mark_profile_error(profile_key, str(exc))
                    await emit_system_log_detached(
                        category="runtime",
                        event_type="product_browser.start_failed",
                        source="crawler",
                        severity="error",
                        status="failed",
                        message=f"Product browser failed for {profile_key}: {exc}",
                        entity_type="crawl_profile",
                        entity_id=profile_key,
                        payload={"profile_key": profile_key, "platform": platform},
                    )
                    raise

                await emit_system_log_detached(
                    category="runtime",
                    event_type="product_browser.session_started",
                    source="crawler",
                    severity="info",
                    status="success",
                    message=f"Product browser session started for {profile_key}",
                    entity_type="crawl_profile",
                    entity_id=profile_key,
                    payload={"profile_key": profile_key, "platform": platform},
                )
                session = BrowserSession(
                    profile_key=profile_key,
                    profile_dir=profile_dir,
                    platform=platform,
                    context=context,
                    max_pages=self._max_pages,
                )
                yield session
                await session.close()
        finally:
            if context is not None:
                await emit_system_log_detached(
                    category="runtime",
                    event_type="product_browser.session_closed",
                    source="crawler",
                    severity="info",
                    status="success",
                    message=f"Product browser session closed for {profile_key}",
                    entity_type="crawl_profile",
                    entity_id=profile_key,
                    payload={"profile_key": profile_key, "platform": platform},
                )
            async with self._db() as db:
                await DatabaseProfilePool(db).release(
                    profile_key=profile_key,
                    owner=owner,
                    task_id=task_id,
                )
```

If `DatabaseProfilePool.acquire()` or `.release()` signatures differ, adapt BrowserManager to the existing method names instead of changing pool semantics broadly. Keep acquire-before-launch and release-in-finally unchanged.

- [ ] **Step 4: Complete tests and assertions**

In `backend/tests/test_browser_manager.py`, import `get_profile`:

```python
from app.domains.crawling.profile_service import get_profile
```

Use this final assertion in startup failure test:

```python
profile = await get_profile(async_session, "product-jd-default")
assert "browser failed to start" in profile.last_error
```

- [ ] **Step 5: Run BrowserManager tests and lint**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_browser_manager.py -q"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app/domains/crawling/browser_manager.py tests/test_browser_manager.py"
```

Expected: PASS.

- [ ] **Step 6: Commit Task 2**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git add backend/app/domains/crawling/browser_manager.py backend/tests/test_browser_manager.py"
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git commit -m 'feat: add product browser manager'"
```

---

### Task 3: Add Page-Based Product Adapter Boundary

**Files:**

- Create: `backend/tests/test_product_adapter_browser_boundary.py`
- Modify: `backend/app/platforms/base.py`
- Modify: `backend/app/platforms/jd.py`
- Modify: `backend/app/core/config.py`

- [ ] **Step 1: Write failing adapter boundary tests**

Create `backend/tests/test_product_adapter_browser_boundary.py`:

```python
import pytest

from app.platforms.base import BasePlatformAdapter
from app.platforms.jd import JDAdapter


pytestmark = pytest.mark.asyncio


class FakePage:
    def __init__(self):
        self.goto_calls = []

    async def goto(self, url, wait_until="domcontentloaded", timeout=60000):
        self.goto_calls.append((url, wait_until, timeout))

    async def wait_for_load_state(self, state, timeout=30000):
        return None

    async def wait_for_timeout(self, timeout):
        return None


class FakeAdapter(BasePlatformAdapter):
    platform_name = "fake"

    async def extract_price(self, page):
        return {"price": "12.34", "title": "Demo"}


async def test_crawl_with_page_reuses_existing_page():
    page = FakePage()
    adapter = FakeAdapter()

    result = await adapter.crawl_with_page("https://example.test/item", page)

    assert result["price"] == "12.34"
    assert page.goto_calls == [("https://example.test/item", "domcontentloaded", 60000)]


def test_jd_cookie_injection_disabled_by_default(settings):
    settings.jd_cookie = "pt_key=abc;pt_pin=demo;"
    settings.jd_cookie_fallback_enabled = False

    adapter = JDAdapter()

    assert adapter._should_inject_cookie_fallback() is False
```

- [ ] **Step 2: Run failing tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_product_adapter_browser_boundary.py -q"
```

Expected: FAIL because `crawl_with_page()` and `_should_inject_cookie_fallback()` do not exist.

- [ ] **Step 3: Refactor BasePlatformAdapter**

In `backend/app/platforms/base.py`, extract page-based crawling:

```python
async def crawl_with_page(self, url: str, page: Page) -> dict[str, Any]:
    try:
        await page.goto(url, wait_until="domcontentloaded", timeout=60000)
        await page.wait_for_load_state("networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        return await self.extract_price(page)
    except Exception as exc:
        logger.exception("%s crawl failed for %s", self.platform_name, url)
        raise PlatformCrawlError(
            platform=self.platform_name,
            url=url,
            reason=str(exc),
        ) from exc


async def crawl(self, url: str) -> dict[str, Any]:
    browser = await self._init_browser()
    page = await browser.new_page()
    try:
        return await self.crawl_with_page(url, page)
    finally:
        await page.close()
```

Keep existing `_get_shared_browser()` and `_close_shared_browser()` so old product paths and emergency fallback still work.

- [ ] **Step 4: Gate JD cookie fallback**

In `backend/app/core/config.py`, add:

```python
jd_cookie_fallback_enabled: bool = False
product_cdp_fallback_enabled: bool = False
```

In `backend/app/platforms/jd.py`, add:

```python
def _should_inject_cookie_fallback(self) -> bool:
    return bool(settings.jd_cookie and settings.jd_cookie_fallback_enabled)
```

Then replace direct `settings.jd_cookie` fallback checks with:

```python
if self._should_inject_cookie_fallback():
    await self._inject_cookie_string(context, settings.jd_cookie)
```

Do not change the default production path to CDP. CDP remains available only when code explicitly calls the old fallback path and `product_cdp_fallback_enabled` is enabled.

- [ ] **Step 5: Run adapter boundary tests and focused product adapter tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_product_adapter_browser_boundary.py -q"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app/platforms/base.py app/platforms/jd.py app/core/config.py tests/test_product_adapter_browser_boundary.py"
```

Expected: PASS.

- [ ] **Step 6: Commit Task 3**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git add backend/app/platforms/base.py backend/app/platforms/jd.py backend/app/core/config.py backend/tests/test_product_adapter_browser_boundary.py"
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git commit -m 'feat: support page-based product adapters'"
```

---

### Task 4: Integrate BrowserManager Into Product Crawl Execution

**Files:**

- Create: `backend/tests/test_product_profile_crawl_runner.py`
- Modify: `backend/app/domains/crawling/service.py`
- Modify: `backend/app/domains/crawling/task_runner.py`
- Modify: `backend/app/domains/crawling/scheduler_service.py`

- [ ] **Step 1: Write failing runner tests**

Create `backend/tests/test_product_profile_crawl_runner.py`:

```python
import pytest

from app.domains.crawling import task_runner
from app.domains.crawling.profile_pool import ensure_profile
from app.domains.products.service import create_product, create_product_cron_config
from app.schemas.product import ProductCreate, ProductPlatformCronCreate


pytestmark = pytest.mark.asyncio


async def test_platform_crawl_task_records_profile_key(async_session, monkeypatch):
    await ensure_profile(async_session, profile_key="product-jd-default", platform_hint="jd")
    await create_product_cron_config(
        async_session,
        user_id=1,
        data=ProductPlatformCronCreate(
            platform="jd",
            cron_expression="0 9 * * *",
            cron_timezone="Asia/Shanghai",
        ),
    )
    product = await create_product(
        async_session,
        user_id=1,
        data=ProductCreate(
            platform="jd",
            url="https://item.jd.com/100.html",
            title="Demo",
            active=True,
        ),
    )

    seen = []

    async def fake_crawl_products_with_profile(db, *, products, platform, profile_key, task_id):
        seen.append((platform, profile_key, [item.id for item in products], task_id))
        return [{"product_id": product.id, "success": True}]

    monkeypatch.setattr(
        task_runner,
        "crawl_products_with_profile",
        fake_crawl_products_with_profile,
    )

    result = await task_runner.run_products_by_platform(
        async_session,
        user_id=1,
        platform="jd",
        task_id="task-1",
    )

    assert result["profile_key"] == "product-jd-default"
    assert seen == [("jd", "product-jd-default", [product.id], "task-1")]


async def test_all_products_group_by_platform_profile(async_session, monkeypatch):
    await ensure_profile(async_session, profile_key="product-jd-default", platform_hint="jd")
    await ensure_profile(async_session, profile_key="product-taobao-default", platform_hint="taobao")
    await create_product_cron_config(
        async_session,
        user_id=1,
        data=ProductPlatformCronCreate(platform="jd", profile_key="product-jd-default"),
    )
    await create_product_cron_config(
        async_session,
        user_id=1,
        data=ProductPlatformCronCreate(platform="taobao", profile_key="product-taobao-default"),
    )

    calls = []

    async def fake_lane(db, *, products, platform, profile_key, task_id):
        calls.append((platform, profile_key))
        return []

    monkeypatch.setattr(task_runner, "crawl_products_with_profile", fake_lane)

    await task_runner.run_all_products(async_session, user_id=1, task_id="task-all")

    assert ("jd", "product-jd-default") in calls
    assert ("taobao", "product-taobao-default") in calls
```

Adjust imports if the existing `create_product()` service signature differs; keep the behavior assertions unchanged.

- [ ] **Step 2: Run failing runner tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_product_profile_crawl_runner.py -q"
```

Expected: FAIL because profile-aware runner functions do not exist.

- [ ] **Step 3: Add service function for page/session product crawl**

In `backend/app/domains/crawling/service.py`, add:

```python
async def crawl_one_with_session(
    db: AsyncSession,
    *,
    product: Product,
    session: BrowserSession,
) -> dict[str, Any]:
    adapter_class = PLATFORM_ADAPTERS[product.platform]
    adapter = adapter_class()
    page = await session.new_page()
    try:
        result = await adapter.crawl_with_page(product.url, page)
        return await _persist_product_crawl_result(
            db,
            product=product,
            result=result,
        )
    finally:
        await session.close_page(page)
```

If current `crawl_one(product_id)` contains persistence inline, first extract that persistence block into:

```python
async def _persist_product_crawl_result(
    db: AsyncSession,
    *,
    product: Product,
    result: dict[str, Any],
) -> dict[str, Any]:
    ...
```

Then make old `crawl_one(product_id)` call the same helper after `adapter.crawl(product.url)`. This keeps fallback compatibility and avoids duplicated price-history behavior.

- [ ] **Step 4: Add profile lane execution**

In `backend/app/domains/crawling/task_runner.py`, add:

```python
async def crawl_products_with_profile(
    db: AsyncSession,
    *,
    products: list[Product],
    platform: str,
    profile_key: str,
    task_id: str,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    manager = BrowserManager()
    async with manager.acquire(
        platform=platform,
        profile_key=profile_key,
        owner="product-crawler",
        task_id=task_id,
    ) as session:
        for product in products:
            try:
                result = await crawling_service.crawl_one_with_session(
                    db,
                    product=product,
                    session=session,
                )
                results.append(result)
            except Exception as exc:
                results.append(
                    {
                        "product_id": product.id,
                        "success": False,
                        "reason": str(exc),
                    }
                )
            await asyncio.sleep(random.uniform(PRODUCT_CRAWL_MIN_INTERVAL, PRODUCT_CRAWL_MAX_INTERVAL))
    return results
```

Add grouping helper:

```python
async def _product_profile_groups(
    db: AsyncSession,
    *,
    user_id: int,
    platform: str | None = None,
) -> dict[tuple[str, str], list[Product]]:
    products = await crawling_service.get_active_products(
        db,
        user_id=user_id,
        platform=platform,
    )
    groups: dict[tuple[str, str], list[Product]] = {}
    for product in products:
        config = await product_repository.get_product_cron_config(
            db,
            user_id=user_id,
            platform=product.platform,
        )
        profile_key = (
            config.profile_key
            if config is not None
            else default_product_profile_key(product.platform)
        )
        groups.setdefault((product.platform, profile_key), []).append(product)
    return groups
```

Use this rule:

- Same `profile_key`: serial products in one BrowserManager session.
- Different `profile_key`: may run concurrently through separate lanes.
- If BrowserManager raises `BrowserProfileUnavailableError`, fail that lane quickly and do not wait indefinitely.

- [ ] **Step 5: Persist task profile_key in scheduler service**

In `backend/app/domains/crawling/scheduler_service.py`, when creating a platform product crawl task:

```python
config = await product_repository.get_product_cron_config(
    db,
    user_id=user_id,
    platform=platform,
)
profile_key = config.profile_key if config else default_product_profile_key(platform)
task = await create_crawl_task(
    db,
    task_type="product_platform",
    user_id=user_id,
    platform=platform,
    profile_key=profile_key,
    status="running",
)
```

For manual all-product crawl, store `profile_key=None` on the parent task and include per-lane profile keys in task payload/result. If the existing task model only supports a single `profile_key`, keep `None` for all-platform parent tasks and create clear result entries:

```python
{
    "platform": platform,
    "profile_key": profile_key,
    "total": len(products),
    "success": success_count,
    "failed": failed_count,
}
```

- [ ] **Step 6: Run runner tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_product_profile_crawl_runner.py -q"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app/domains/crawling/service.py app/domains/crawling/task_runner.py app/domains/crawling/scheduler_service.py tests/test_product_profile_crawl_runner.py"
```

Expected: PASS.

- [ ] **Step 7: Commit Task 4**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git add backend/app/domains/crawling/service.py backend/app/domains/crawling/task_runner.py backend/app/domains/crawling/scheduler_service.py backend/tests/test_product_profile_crawl_runner.py"
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git commit -m 'feat: run product crawls through profile sessions'"
```

---

### Task 5: Add Profile Failure Classification and Events

**Files:**

- Modify: `backend/app/domains/crawling/browser_manager.py`
- Modify: `backend/app/domains/crawling/service.py`
- Modify: `backend/app/platforms/jd.py`
- Modify: `backend/app/platforms/taobao.py`
- Modify: `backend/app/platforms/amazon.py`
- Test: `backend/tests/test_browser_manager.py`
- Test: `backend/tests/test_product_profile_crawl_runner.py`

- [ ] **Step 1: Add failing tests for blocked statuses and login failure**

Extend `backend/tests/test_browser_manager.py`:

```python
@pytest.mark.parametrize("status", ["login_required", "disabled", "cooling_down"])
async def test_browser_manager_blocked_statuses_fail_before_launch(async_session, status):
    profile = await ensure_profile(async_session, profile_key="product-jd-default", platform_hint="jd")
    profile.status = status
    await async_session.commit()
    fake_context = FakeContext()
    manager = BrowserManager(
        db_factory=lambda: async_session,
        playwright_factory=lambda: fake_playwright_factory(fake_context),
    )

    with pytest.raises(BrowserProfileUnavailableError):
        async with manager.acquire(
            platform="jd",
            profile_key="product-jd-default",
            owner="test-owner",
            task_id="task-1",
        ):
            pass

    assert fake_context.pages == []
```

Extend adapter boundary tests with JD login wall detection:

```python
def test_jd_login_required_reason_is_profile_specific():
    adapter = JDAdapter()

    assert adapter.classify_failure("https://passport.jd.com/login.aspx", "") == "login_required"
    assert adapter.classify_failure("https://item.jd.com/100.html", "请登录后查看") == "login_required"
```

- [ ] **Step 2: Run failing tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_browser_manager.py tests/test_product_adapter_browser_boundary.py -q"
```

Expected: FAIL where classification is missing or blocked statuses are not handled before browser launch.

- [ ] **Step 3: Implement classification hooks**

In `backend/app/platforms/base.py`, add:

```python
def classify_failure(self, url: str, content: str) -> str | None:
    return None
```

In `backend/app/platforms/jd.py`, add:

```python
def classify_failure(self, url: str, content: str) -> str | None:
    lowered = content.lower()
    if "passport.jd.com" in url or "请登录" in content or "login" in lowered:
        return "login_required"
    return None
```

In `backend/app/platforms/taobao.py`, add:

```python
def classify_failure(self, url: str, content: str) -> str | None:
    if "login.taobao.com" in url or "登录" in content:
        return "login_required"
    if "验证码" in content or "滑块" in content:
        return "anti_bot"
    return None
```

In `backend/app/platforms/amazon.py`, add:

```python
def classify_failure(self, url: str, content: str) -> str | None:
    lowered = content.lower()
    if "/ap/signin" in url or "sign in" in lowered:
        return "login_required"
    if "captcha" in lowered or "enter the characters you see below" in lowered:
        return "anti_bot"
    return None
```

- [ ] **Step 4: Mark profile login_required from product crawl failures**

In `backend/app/domains/crawling/service.py`, when `crawl_one_with_session()` catches a platform failure:

```python
except PlatformCrawlError as exc:
    reason = getattr(exc, "reason", str(exc))
    if reason == "login_required":
        await profile_service.update_profile(
            db,
            profile_key=session.profile_key,
            status=LOGIN_REQUIRED,
            platform_hint=session.platform,
            last_error=f"{product.platform} login required for {product.url}",
        )
        await emit_system_log_detached(
            category="runtime",
            event_type="product_profile.login_required",
            source="crawler",
            severity="warning",
            status="failed",
            message=f"Product profile {session.profile_key} requires login",
            entity_type="crawl_profile",
            entity_id=session.profile_key,
            payload={"profile_key": session.profile_key, "platform": product.platform},
        )
    raise
```

If `PlatformCrawlError.reason` currently contains arbitrary strings, add a `failure_type: str | None = None` field and keep `reason` backward compatible.

- [ ] **Step 5: Emit page timeout event**

In `BrowserSession.close_page()` or the crawl wrapper, when a Playwright timeout is caught:

```python
await emit_system_log_detached(
    category="runtime",
    event_type="product_browser.page_timeout",
    source="crawler",
    severity="warning",
    status="failed",
    message=f"Product page timed out for {self.profile_key}",
    entity_type="crawl_profile",
    entity_id=self.profile_key,
    payload={"profile_key": self.profile_key, "platform": self.platform},
)
```

Do not include cookies, request headers, webhook URLs, or local security identifiers in payloads.

- [ ] **Step 6: Run tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_browser_manager.py tests/test_product_adapter_browser_boundary.py tests/test_product_profile_crawl_runner.py -q"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app/domains/crawling app/platforms tests/test_browser_manager.py tests/test_product_adapter_browser_boundary.py tests/test_product_profile_crawl_runner.py"
```

Expected: PASS.

- [ ] **Step 7: Commit Task 5**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git add backend/app/domains/crawling/browser_manager.py backend/app/domains/crawling/service.py backend/app/platforms/base.py backend/app/platforms/jd.py backend/app/platforms/taobao.py backend/app/platforms/amazon.py backend/tests/test_browser_manager.py backend/tests/test_product_adapter_browser_boundary.py backend/tests/test_product_profile_crawl_runner.py"
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git commit -m 'feat: classify product profile crawl failures'"
```

---

### Task 6: Add Product Profile Controls to Schedule UI

**Files:**

- Create: `frontend/src/features/schedule/components/ProductProfileCell.tsx`
- Create: `frontend/tests/e2e/product-profile-schedule.spec.ts`
- Modify: `frontend/src/features/products/api/products.ts`
- Modify: `frontend/src/features/schedule/ScheduleConfigPage.tsx`
- Modify: `frontend/src/features/schedule/types.ts`
- Modify: `frontend/src/features/jobs/components/ProfileManagement.tsx`

- [ ] **Step 1: Update frontend API types**

In `frontend/src/features/products/api/products.ts`, update cron types:

```ts
export interface ProductPlatformCronConfig {
  id: number
  user_id: number
  platform: ProductPlatform
  cron_expression: string | null
  cron_timezone: string
  profile_key: string
  created_at: string
  updated_at: string
}

export interface ProductPlatformCronPayload {
  platform?: ProductPlatform
  cron_expression?: string | null
  cron_timezone?: string | null
  profile_key?: string | null
}
```

Use `profile_key` in create/update request bodies.

- [ ] **Step 2: Add product platform profile cell component**

Create `frontend/src/features/schedule/components/ProductProfileCell.tsx`:

```tsx
import { Button, Select, Space, Tag, Tooltip, Typography } from 'antd'
import { Lock, RotateCcw, Plus } from 'lucide-react'
import type { CrawlProfile } from '@/features/jobs/types'

type Props = {
  value: string
  profiles: CrawlProfile[]
  onChange: (profileKey: string) => void
  onCreate: () => void
  onReleaseStale: (profileKey: string) => void
}

const STATUS_COLOR: Record<string, string> = {
  available: 'green',
  leased: 'blue',
  login_required: 'orange',
  cooling_down: 'gold',
  disabled: 'red',
}

export function ProductProfileCell({
  value,
  profiles,
  onChange,
  onCreate,
  onReleaseStale,
}: Props) {
  const profile = profiles.find((item) => item.profile_key === value)
  const options = profiles.map((item) => ({
    label: item.profile_key,
    value: item.profile_key,
  }))

  return (
    <Space direction="vertical" size={4} style={{ width: '100%' }}>
      <Space.Compact style={{ width: '100%' }}>
        <Select
          value={value}
          options={options}
          onChange={onChange}
          showSearch
          style={{ minWidth: 220, flex: 1 }}
          popupMatchSelectWidth={false}
        />
        <Tooltip title="Create profile">
          <Button icon={<Plus size={16} />} onClick={onCreate} />
        </Tooltip>
        <Tooltip title="Release stale lease">
          <Button
            icon={<RotateCcw size={16} />}
            onClick={() => onReleaseStale(value)}
            disabled={!profile?.lease_until}
          />
        </Tooltip>
      </Space.Compact>
      <Space size={6} wrap>
        <Tag color={STATUS_COLOR[profile?.status ?? ''] ?? 'default'}>
          {profile?.status ?? 'missing'}
        </Tag>
        {profile?.lease_until ? <Lock size={14} /> : null}
        {profile?.last_error ? (
          <Typography.Text type="danger" ellipsis style={{ maxWidth: 260 }}>
            {profile.last_error}
          </Typography.Text>
        ) : null}
      </Space>
    </Space>
  )
}
```

- [ ] **Step 3: Extend profile platform hints**

In `frontend/src/features/jobs/components/ProfileManagement.tsx`, add product platform options while keeping existing job options:

```ts
const PLATFORM_HINT_OPTIONS = [
  { label: 'Boss', value: 'boss' },
  { label: '51job', value: '51job' },
  { label: 'Liepin', value: 'liepin' },
  { label: 'JD', value: 'jd' },
  { label: 'Taobao', value: 'taobao' },
  { label: 'Amazon', value: 'amazon' },
]
```

- [ ] **Step 4: Wire ScheduleConfigPage to profiles**

In `frontend/src/features/schedule/ScheduleConfigPage.tsx`, load profiles:

```tsx
const [profiles, setProfiles] = useState<CrawlProfile[]>([])

const loadProfiles = useCallback(async () => {
  const data = await jobsApi.getProfiles()
  setProfiles(data)
}, [])

useEffect(() => {
  void loadProfiles()
}, [loadProfiles])
```

When rendering product cron rows, add a `Profile` column using `ProductProfileCell`:

```tsx
{
  title: 'Profile',
  dataIndex: 'profile_key',
  key: 'profile_key',
  render: (_: string, record: ProductPlatformCronConfig) => (
    <ProductProfileCell
      value={record.profile_key}
      profiles={profiles}
      onChange={(profileKey) => updateDraft(record.platform, { profile_key: profileKey })}
      onCreate={() => openCreateProfileModal(record.platform)}
      onReleaseStale={async (profileKey) => {
        await jobsApi.releaseStaleProfile(profileKey)
        await loadProfiles()
      }}
    />
  ),
}
```

When saving product cron config, include profile key:

```tsx
await productsApi.updateCronConfig(platform, {
  cron_expression: draft.cron_expression,
  cron_timezone: draft.cron_timezone,
  profile_key: draft.profile_key,
})
```

Create profile from Schedule page with platform default key:

```tsx
const DEFAULT_PRODUCT_PROFILE_KEYS: Record<ProductPlatform, string> = {
  jd: 'product-jd-default',
  taobao: 'product-taobao-default',
  amazon: 'product-amazon-default',
}

await jobsApi.createProfile({
  profile_key: DEFAULT_PRODUCT_PROFILE_KEYS[platform],
  platform_hint: platform,
})
```

If the profile already exists, show a non-blocking message and refresh profiles.

- [ ] **Step 5: Add UI smoke test**

Create `frontend/tests/e2e/product-profile-schedule.spec.ts`:

```ts
import { test, expect } from '@playwright/test'

test('schedule page exposes product profile binding controls', async ({ page }) => {
  await page.goto('http://127.0.0.1:3000')
  await page.getByPlaceholder('Username').fill('default123')
  await page.getByPlaceholder('Password').fill('123456')
  await page.getByRole('button', { name: /login/i }).click()

  await page.getByRole('link', { name: /schedule/i }).click()

  await expect(page.getByText('product-jd-default')).toBeVisible()
  await expect(page.getByText('product-taobao-default')).toBeVisible()
  await expect(page.getByText('product-amazon-default')).toBeVisible()
})
```

Adjust selectors to the existing login labels if the current app uses Chinese text. Keep the assertion on the three default profile keys.

- [ ] **Step 6: Run frontend build and focused e2e**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"
powershell.exe -Command "cd C:/Users/arfac/price-monitor; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npx playwright test tests/e2e/product-profile-schedule.spec.ts --project=chromium"
```

Expected: build PASS, e2e PASS against local frontend `3000` and backend `8000`.

- [ ] **Step 7: Commit Task 6**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git add frontend/src/features/products/api/products.ts frontend/src/features/schedule/ScheduleConfigPage.tsx frontend/src/features/schedule/types.ts frontend/src/features/schedule/components/ProductProfileCell.tsx frontend/src/features/jobs/components/ProfileManagement.tsx frontend/tests/e2e/product-profile-schedule.spec.ts"
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git commit -m 'feat: manage product crawl profiles in schedule UI'"
```

---

### Task 7: Real Environment Integration and Regression Verification

**Files:**

- Modify: `docs/2026-05-25-crawler-production-todo.md`
- Optional modify: `README.md` only if it already contains crawler profile operation notes.

- [ ] **Step 1: Update todo document**

In `docs/2026-05-25-crawler-production-todo.md`, add or update Phase 4 entries:

```markdown
## Phase 4: Product Profile Browser Manager

- [x] Product platform cron configs store `profile_key`.
- [x] BrowserManager owns product persistent context lifecycle.
- [x] JD/Taobao/Amazon product crawls use profile-first execution.
- [x] Schedule page supports product platform profile binding.
- [x] Event Center records product browser/profile lifecycle events.
- [ ] Real environment JD profile crawl verified after login state is prepared.
```

- [ ] **Step 2: Run backend regression**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check ."
```

Expected: PASS.

- [ ] **Step 3: Run frontend regression**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"
```

Expected: PASS.

- [ ] **Step 4: Run real frontend/backend smoke test**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"
```

Then verify in browser:

- Log in with `default123` / `123456`.
- Open Schedule page.
- Confirm product platform rows show `product-jd-default`, `product-taobao-default`, and `product-amazon-default`.
- Create missing default profiles from the Schedule page if they are absent.
- Save JD cron config with `profile_key=product-jd-default`.
- Open Profile tab and confirm `profile_dir` points to `profiles/product-jd-default`.

- [ ] **Step 5: Run real JD product profile crawl**

Prepare login state manually in the persistent profile directory:

- Open a local browser using `profiles/product-jd-default`.
- Log into JD once.
- Close that browser so BrowserManager can lease the profile.

Trigger a JD product crawl from the UI or API. Verify:

```sql
SELECT id, task_type, platform, profile_key, status, error_message
FROM crawl_tasks
WHERE platform = 'jd'
ORDER BY created_at DESC
LIMIT 5;

SELECT profile_key, status, lease_owner, lease_task_id, lease_until, last_error
FROM crawl_profiles
WHERE profile_key = 'product-jd-default';

SELECT event_type, status, message, payload
FROM system_logs
WHERE event_type LIKE 'product_%'
ORDER BY created_at DESC
LIMIT 20;
```

Expected:

- JD product task uses `profile_key='product-jd-default'`.
- Profile lease is released after task completion.
- Price history or crawl log records are created for reachable products.
- Event Center contains `product_browser.session_started` and `product_browser.session_closed`.
- If login state is not prepared, task fails with profile-specific `login_required`, not a generic extraction failure.

- [ ] **Step 6: Commit Task 7**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git add docs/2026-05-25-crawler-production-todo.md README.md"
powershell.exe -Command "cd C:/Users/arfac/price-monitor; git commit -m 'docs: record product profile browser manager verification'"
```

If `README.md` was not changed, stage only the todo file.

---

## Final Verification Gate

Before merging Phase 4, run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; alembic upgrade head"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check ."
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"
```

Then run the real environment flow from Task 7.

Run GitNexus change detection before final commit or merge:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; npx gitnexus analyze"
```

Then use `gitnexus_detect_changes(scope="all")` and confirm changed symbols are limited to product profile binding, BrowserManager, product crawl execution, product adapters, and Schedule/Profile UI.

## Edge Cases Covered

- Missing default profile: service creates metadata through `ensure_profile()` and the crawl fails as `login_required` if login state is not usable.
- Unknown explicit profile: product cron create/update returns HTTP 400.
- Active profile lease: BrowserManager fails fast with `product_profile.leased`; it does not wait indefinitely.
- `login_required`, `disabled`, and `cooling_down`: BrowserManager refuses before browser launch.
- Startup failure: BrowserManager records `crawl_profiles.last_error`, releases lease, and emits `product_browser.start_failed`.
- Page timeout: page is closed, event is emitted, and lane policy decides whether to continue.
- Same profile used by several products: one session, serial pages.
- Different profiles used by different product platforms: separate lanes may run concurrently.
- Existing `crawl(url)` fallback: preserved for development/emergency paths.
- `JD_COOKIE`: disabled by default and only used when explicit fallback setting is enabled.
- Product rows: unchanged; no per-product `profile_key`.

## Self-Review Notes

Spec coverage:

- Platform-level product profiles: Task 1 and Task 4.
- BrowserManager lifecycle and profile lease: Task 2.
- Adapter page boundary: Task 3.
- JD/Taobao/Amazon profile-first behavior and fallback gating: Task 3, Task 4, Task 5.
- Schedule/Profile UI: Task 6.
- Event Center observability: Task 2 and Task 5.
- Real environment verification: Task 7.

Placeholder scan:

- No `TBD`, unresolved `TODO`, or open-ended "add validation" instructions remain.
- Where current code signatures may differ, the expected behavior is pinned by tests before implementation.

Type consistency:

- `profile_key` is consistently snake_case across database, Pydantic schemas, API payloads, frontend types, and task records.
- `BrowserManager.acquire()` and `BrowserSession.new_page()/close_page()/close()` match the approved spec.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | not run | Optional; Phase 4 scope was already narrowed during brainstorming |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | not run | Not run for plan-stage review |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | issues_open | 5 issues, 0 critical production gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | not run | Recommended before implementing Schedule page UI |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | not run | Not required for this backend-heavy plan |

- **UNRESOLVED:** 5 plan amendments recommended before implementation.
- **VERDICT:** ENG REVIEW HAS OPEN ISSUES - adjust the plan before executing Phase 4.
