# Smart Home Console Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `/smart-home` into a fuller Home Assistant control console with inline `fan` and `climate` controls, scene/script visibility, filtering, and global plus per-user display preferences.

**Architecture:** Keep the existing FastAPI smart-home domain and React feature route. Add Smart Home-specific preference persistence and merge effective display data server-side, then render the merged entity list through focused frontend components.

**Tech Stack:** FastAPI, SQLAlchemy async ORM, Alembic, Pydantic v2, pytest, React 18, TypeScript, Vite, Ant Design 6, Playwright.

---

## Reference Inputs

- Design spec: `docs/superpowers/specs/2026-06-06-smart-home-console-design.md`
- Existing backend domain: `backend/app/domains/smart_home/`
- Existing schemas: `backend/app/schemas/smart_home.py`
- Existing models: `backend/app/models/smart_home.py`
- Existing frontend feature: `frontend/src/features/smart-home/`
- Current route: `frontend/src/App.tsx`

## Required Pre-Work

- [ ] **Step 1: Refresh GitNexus before code edits**

Run:

```powershell
npx gitnexus analyze --force
```

Expected: GitNexus finishes indexing `mavra-monitor-system` without a stale-index warning.

- [ ] **Step 2: Run impact analysis before editing Smart Home symbols**

Run these before modifying the named symbols:

```text
gitnexus_impact(target="SmartHomeEntity", direction="upstream", file_path="backend/app/schemas/smart_home.py")
gitnexus_impact(target="list_entities", direction="upstream", file_path="backend/app/domains/smart_home/service.py")
gitnexus_impact(target="call_entity_service", direction="upstream", file_path="backend/app/domains/smart_home/service.py")
gitnexus_impact(target="SmartHomePage", direction="upstream", file_path="frontend/src/features/smart-home/SmartHomePage.tsx")
```

Expected: Report direct callers, affected processes, and risk before implementation. If any result is HIGH or CRITICAL, stop and report the risk before editing.

---

## File Structure

### Backend Files

- Modify: `backend/app/models/smart_home.py`
  - Add global entity preferences and area preferences.
  - Keep existing `SmartHomeEntityPreference` as the user-level entity preference table.
- Create: `backend/alembic/versions/2026_06_06_smart_home_preferences.py`
  - Add new tables for global entity preferences and area preferences.
- Modify: `backend/app/schemas/smart_home.py`
  - Add effective display fields, capability fields, preference request/response schemas.
- Modify: `backend/app/domains/smart_home/repository.py`
  - Add CRUD helpers for entity and area preferences.
- Modify: `backend/app/domains/smart_home/service.py`
  - Add capability extraction, preference merge logic, preference updates, and reset behavior.
- Modify: `backend/app/domains/smart_home/router.py`
  - Add preference routes and pass current user to entity listing.
- Modify: `backend/tests/test_smart_home_router.py`
  - Extend route tests for preference endpoints and permission behavior.
- Create: `backend/tests/test_smart_home_preferences.py`
  - Unit-test merge rules and capability extraction without calling real Home Assistant.

### Frontend Files

- Modify: `frontend/src/features/smart-home/types.ts`
  - Add effective display, capability, preference, and filter types.
- Modify: `frontend/src/features/smart-home/api/smartHome.ts`
  - Add preference API methods.
- Create: `frontend/src/features/smart-home/components/SmartHomeToolbar.tsx`
  - Search, filter, hidden toggle, sorting, reset.
- Create: `frontend/src/features/smart-home/components/SmartHomeEntityCard.tsx`
  - Type-specific controls and display settings entry point.
- Create: `frontend/src/features/smart-home/components/SmartHomeActionSection.tsx`
  - Dedicated scene/script section.
- Create: `frontend/src/features/smart-home/components/SmartHomePreferenceModal.tsx`
  - Entity and area preference editing.
- Modify: `frontend/src/features/smart-home/SmartHomePage.tsx`
  - Orchestrate data loading, filters, grouping, SSE, and modals.
- Create: `frontend/tests/e2e/smart-home.spec.ts`
  - Smoke-test route shell and key UI states when a backend is available.

---

## Task 1: Backend Models and Migration

**Files:**
- Modify: `backend/app/models/smart_home.py`
- Create: `backend/alembic/versions/2026_06_06_smart_home_preferences.py`

- [ ] **Step 1: Add model tests to document table intent**

Create `backend/tests/test_smart_home_preferences.py` with the imports and first structural test:

```python
from app.models.smart_home import (
    SmartHomeAreaPreference,
    SmartHomeEntityGlobalPreference,
    SmartHomeEntityPreference,
)


def test_smart_home_preference_models_use_expected_tables():
    assert SmartHomeEntityPreference.__tablename__ == "smart_home_entity_preferences"
    assert (
        SmartHomeEntityGlobalPreference.__tablename__
        == "smart_home_entity_global_preferences"
    )
    assert SmartHomeAreaPreference.__tablename__ == "smart_home_area_preferences"
```

- [ ] **Step 2: Run the new test and verify it fails**

Run:

```powershell
cd backend
pytest tests/test_smart_home_preferences.py::test_smart_home_preference_models_use_expected_tables -v
```

Expected: FAIL because `SmartHomeEntityGlobalPreference` and `SmartHomeAreaPreference` do not exist.

- [ ] **Step 3: Add model classes**

In `backend/app/models/smart_home.py`, keep `SmartHomeConfig` and `SmartHomeEntityPreference`, then add:

```python
class SmartHomeEntityGlobalPreference(Base, TimestampMixin):
    """Global display defaults for Home Assistant entities."""

    __tablename__ = "smart_home_entity_global_preferences"
    __table_args__ = (
        UniqueConstraint("entity_id", name="uq_smart_home_entity_global_pref_entity"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    entity_id = Column(String(255), nullable=False, index=True)
    alias = Column(String(255), nullable=True)
    hidden = Column(Boolean, nullable=True)
    sort_order = Column(Integer, nullable=True)
    area = Column(String(255), nullable=True)
    metadata_json = Column(JSONB, nullable=False, default=dict)


class SmartHomeAreaPreference(Base, TimestampMixin):
    """Display preferences for Home Assistant source areas."""

    __tablename__ = "smart_home_area_preferences"
    __table_args__ = (
        UniqueConstraint(
            "scope",
            "user_id",
            "source_area",
            name="uq_smart_home_area_pref_scope_user_area",
        ),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    scope = Column(String(20), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    source_area = Column(String(255), nullable=False, index=True)
    display_name = Column(String(255), nullable=True)
    hidden = Column(Boolean, nullable=True)
    sort_order = Column(Integer, nullable=True)
    metadata_json = Column(JSONB, nullable=False, default=dict)
```

Update `backend/app/models/__init__.py` to import and export both new classes.

- [ ] **Step 4: Add Alembic migration**

Create `backend/alembic/versions/2026_06_06_smart_home_preferences.py`:

```python
"""Add smart home display preferences.

Revision ID: 2026_06_06_smart_home_preferences
Revises: 2026_06_03_add_smart_home
Create Date: 2026-06-06
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "2026_06_06_smart_home_preferences"
down_revision: str | None = "2026_06_03_add_smart_home"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "smart_home_entity_global_preferences",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("entity_id", sa.String(length=255), nullable=False),
        sa.Column("alias", sa.String(length=255), nullable=True),
        sa.Column("hidden", sa.Boolean(), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=True),
        sa.Column("area", sa.String(length=255), nullable=True),
        sa.Column(
            "metadata_json",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("entity_id", name="uq_smart_home_entity_global_pref_entity"),
    )
    op.create_index(
        "ix_smart_home_entity_global_preferences_entity_id",
        "smart_home_entity_global_preferences",
        ["entity_id"],
    )
    op.create_table(
        "smart_home_area_preferences",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("scope", sa.String(length=20), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("source_area", sa.String(length=255), nullable=False),
        sa.Column("display_name", sa.String(length=255), nullable=True),
        sa.Column("hidden", sa.Boolean(), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=True),
        sa.Column(
            "metadata_json",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "scope",
            "user_id",
            "source_area",
            name="uq_smart_home_area_pref_scope_user_area",
        ),
    )
    op.create_index("ix_smart_home_area_preferences_scope", "smart_home_area_preferences", ["scope"])
    op.create_index("ix_smart_home_area_preferences_user_id", "smart_home_area_preferences", ["user_id"])
    op.create_index("ix_smart_home_area_preferences_source_area", "smart_home_area_preferences", ["source_area"])


def downgrade() -> None:
    op.drop_index("ix_smart_home_area_preferences_source_area", table_name="smart_home_area_preferences")
    op.drop_index("ix_smart_home_area_preferences_user_id", table_name="smart_home_area_preferences")
    op.drop_index("ix_smart_home_area_preferences_scope", table_name="smart_home_area_preferences")
    op.drop_table("smart_home_area_preferences")
    op.drop_index(
        "ix_smart_home_entity_global_preferences_entity_id",
        table_name="smart_home_entity_global_preferences",
    )
    op.drop_table("smart_home_entity_global_preferences")
```

- [ ] **Step 5: Run model test**

Run:

```powershell
cd backend
pytest tests/test_smart_home_preferences.py::test_smart_home_preference_models_use_expected_tables -v
```

Expected: PASS.

- [ ] **Step 6: Commit task**

Run:

```powershell
git add backend/app/models/smart_home.py backend/app/models/__init__.py backend/alembic/versions/2026_06_06_smart_home_preferences.py backend/tests/test_smart_home_preferences.py
git commit -m "feat: add smart home preference models"
```

---

## Task 2: Backend Schemas, Capabilities, and Merge Logic

**Files:**
- Modify: `backend/app/schemas/smart_home.py`
- Modify: `backend/app/domains/smart_home/service.py`
- Modify: `backend/tests/test_smart_home_preferences.py`

- [ ] **Step 1: Write tests for capability extraction and preference merge**

Append to `backend/tests/test_smart_home_preferences.py`:

```python
from types import SimpleNamespace

from app.domains.smart_home.service import build_entity_capabilities, merge_entity_display
from app.schemas.smart_home import SmartHomeEntity


def test_build_entity_capabilities_for_fan_percentage():
    entity = SmartHomeEntity(
        entity_id="fan.office",
        domain="fan",
        name="Office Fan",
        state="on",
        attributes={"percentage": 40, "percentage_step": 10},
    )

    capabilities = build_entity_capabilities(entity)

    assert capabilities.can_turn_on is True
    assert capabilities.can_turn_off is True
    assert capabilities.can_set_percentage is True
    assert capabilities.percentage == 40
    assert capabilities.percentage_step == 10


def test_build_entity_capabilities_for_climate_temperature_and_modes():
    entity = SmartHomeEntity(
        entity_id="climate.bedroom",
        domain="climate",
        name="Bedroom AC",
        state="cool",
        attributes={
            "temperature": 24,
            "current_temperature": 25,
            "target_temp_step": 0.5,
            "min_temp": 16,
            "max_temp": 30,
            "hvac_modes": ["off", "cool", "heat", "auto"],
        },
    )

    capabilities = build_entity_capabilities(entity)

    assert capabilities.can_set_temperature is True
    assert capabilities.can_set_hvac_mode is True
    assert capabilities.temperature == 24
    assert capabilities.current_temperature == 25
    assert capabilities.hvac_modes == ["off", "cool", "heat", "auto"]


def test_merge_entity_display_prefers_user_then_global_then_source():
    entity = SmartHomeEntity(
        entity_id="switch.kitchen",
        domain="switch",
        name="Kitchen Switch",
        state="on",
        area="Kitchen",
        attributes={},
    )
    global_pref = SimpleNamespace(
        alias="Global Kitchen",
        hidden=True,
        sort_order=20,
        area="Global Area",
        metadata_json={},
    )
    user_pref = SimpleNamespace(
        alias="My Kitchen",
        hidden=None,
        sort_order=5,
        area=None,
        metadata_json={},
    )
    global_area = SimpleNamespace(display_name="Global Area Display", hidden=False, sort_order=30)
    user_area = SimpleNamespace(display_name="My Area", hidden=None, sort_order=10)

    effective = merge_entity_display(
        entity,
        global_pref=global_pref,
        user_pref=user_pref,
        global_area_pref=global_area,
        user_area_pref=user_area,
    )

    assert effective.effective_name == "My Kitchen"
    assert effective.effective_area == "My Area"
    assert effective.effective_hidden is True
    assert effective.effective_sort_order == 5
    assert effective.area_sort_order == 10
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```powershell
cd backend
pytest tests/test_smart_home_preferences.py -v
```

Expected: FAIL because schema and service helpers do not exist.

- [ ] **Step 3: Add schemas**

In `backend/app/schemas/smart_home.py`, add:

```python
class SmartHomeEntityCapabilities(BaseModel):
    can_turn_on: bool = False
    can_turn_off: bool = False
    can_toggle: bool = False
    can_set_percentage: bool = False
    can_set_temperature: bool = False
    can_set_hvac_mode: bool = False
    percentage: int | None = None
    percentage_step: int | None = None
    temperature: float | None = None
    current_temperature: float | None = None
    min_temp: float | None = None
    max_temp: float | None = None
    target_temp_step: float | None = None
    hvac_modes: list[str] = Field(default_factory=list)


class SmartHomeEffectiveEntity(SmartHomeEntity):
    effective_name: str
    effective_area: str | None = None
    effective_hidden: bool = False
    effective_sort_order: int = 0
    area_sort_order: int = 0
    supports: SmartHomeEntityCapabilities = Field(default_factory=SmartHomeEntityCapabilities)


class SmartHomeEntityListResponse(BaseModel):
    items: list[SmartHomeEffectiveEntity]
    total: int
    connected: bool
    last_error: str | None = None
```

Keep request and config schemas unchanged unless imports need adjustment.

- [ ] **Step 4: Add service helpers**

In `backend/app/domains/smart_home/service.py`, add helpers near `normalize_entity`:

```python
def _number(value: Any) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int | float):
        return float(value)
    return None


def build_entity_capabilities(entity: SmartHomeEntity) -> SmartHomeEntityCapabilities:
    attributes = entity.attributes
    caps = SmartHomeEntityCapabilities()
    if entity.domain in {"light", "switch", "fan"}:
        caps.can_turn_on = True
        caps.can_turn_off = True
        caps.can_toggle = True
    if entity.domain == "fan":
        percentage = _number(attributes.get("percentage"))
        percentage_step = _number(attributes.get("percentage_step"))
        caps.can_set_percentage = percentage is not None or percentage_step is not None
        caps.percentage = int(percentage) if percentage is not None else None
        caps.percentage_step = int(percentage_step) if percentage_step is not None else None
    if entity.domain == "cover":
        caps.can_turn_on = False
        caps.can_turn_off = False
    if entity.domain == "climate":
        temperature = _number(attributes.get("temperature"))
        current_temperature = _number(attributes.get("current_temperature"))
        min_temp = _number(attributes.get("min_temp"))
        max_temp = _number(attributes.get("max_temp"))
        target_temp_step = _number(attributes.get("target_temp_step"))
        hvac_modes = attributes.get("hvac_modes")
        caps.temperature = temperature
        caps.current_temperature = current_temperature
        caps.min_temp = min_temp
        caps.max_temp = max_temp
        caps.target_temp_step = target_temp_step
        caps.hvac_modes = [str(mode) for mode in hvac_modes] if isinstance(hvac_modes, list) else []
        caps.can_set_temperature = temperature is not None
        caps.can_set_hvac_mode = bool(caps.hvac_modes)
    return caps


def _first_non_none(*values: Any) -> Any:
    for value in values:
        if value is not None:
            return value
    return None


def merge_entity_display(
    entity: SmartHomeEntity,
    *,
    global_pref: Any | None,
    user_pref: Any | None,
    global_area_pref: Any | None,
    user_area_pref: Any | None,
) -> SmartHomeEffectiveEntity:
    display_area = _first_non_none(
        getattr(user_pref, "area", None),
        getattr(global_pref, "area", None),
        entity.area,
    )
    effective_area = _first_non_none(
        getattr(user_area_pref, "display_name", None),
        getattr(global_area_pref, "display_name", None),
        display_area,
    )
    return SmartHomeEffectiveEntity(
        **entity.model_dump(),
        effective_name=_first_non_none(
            getattr(user_pref, "alias", None),
            getattr(global_pref, "alias", None),
            entity.name,
        ),
        effective_area=effective_area,
        effective_hidden=bool(
            _first_non_none(
                getattr(user_pref, "hidden", None),
                getattr(global_pref, "hidden", None),
                getattr(user_area_pref, "hidden", None),
                getattr(global_area_pref, "hidden", None),
                False,
            )
        ),
        effective_sort_order=int(
            _first_non_none(
                getattr(user_pref, "sort_order", None),
                getattr(global_pref, "sort_order", None),
                0,
            )
        ),
        area_sort_order=int(
            _first_non_none(
                getattr(user_area_pref, "sort_order", None),
                getattr(global_area_pref, "sort_order", None),
                0,
            )
        ),
        supports=build_entity_capabilities(entity),
    )
```

Update imports to include `SmartHomeEffectiveEntity` and `SmartHomeEntityCapabilities`.

- [ ] **Step 5: Run tests**

Run:

```powershell
cd backend
pytest tests/test_smart_home_preferences.py -v
```

Expected: PASS.

- [ ] **Step 6: Commit task**

Run:

```powershell
git add backend/app/schemas/smart_home.py backend/app/domains/smart_home/service.py backend/tests/test_smart_home_preferences.py
git commit -m "feat: add smart home effective entity model"
```

---

## Task 3: Preference Repository, Service, and Routes

**Files:**
- Modify: `backend/app/domains/smart_home/repository.py`
- Modify: `backend/app/domains/smart_home/service.py`
- Modify: `backend/app/domains/smart_home/router.py`
- Modify: `backend/app/schemas/smart_home.py`
- Modify: `backend/tests/test_smart_home_router.py`
- Modify: `backend/tests/test_smart_home_preferences.py`

- [ ] **Step 1: Add request/response schemas**

In `backend/app/schemas/smart_home.py`, add:

```python
SmartHomePreferenceScope = Literal["me", "global"]


class SmartHomeEntityPreferenceUpdate(BaseModel):
    alias: str | None = Field(default=None, max_length=255)
    hidden: bool | None = None
    sort_order: int | None = None
    area: str | None = Field(default=None, max_length=255)
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class SmartHomeAreaPreferenceUpdate(BaseModel):
    display_name: str | None = Field(default=None, max_length=255)
    hidden: bool | None = None
    sort_order: int | None = None
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class SmartHomePreferenceResponse(BaseModel):
    scope: SmartHomePreferenceScope
    entity_id: str | None = None
    source_area: str | None = None
    alias: str | None = None
    display_name: str | None = None
    hidden: bool | None = None
    sort_order: int | None = None
    area: str | None = None
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class SmartHomePreferencesResponse(BaseModel):
    entity_preferences: list[SmartHomePreferenceResponse]
    area_preferences: list[SmartHomePreferenceResponse]
```

- [ ] **Step 2: Add router tests**

Append to `backend/tests/test_smart_home_router.py`:

```python
@pytest.mark.asyncio
async def test_update_my_entity_preference_uses_current_user(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    async def allow_permission(db, role_name, permission):
        return True

    async def save_user_entity_preference(db, user_id, entity_id, data):
        assert user_id == 1
        assert entity_id == "fan.office"
        assert data.alias == "Desk Fan"
        return {
            "scope": "me",
            "entity_id": entity_id,
            "alias": data.alias,
            "hidden": data.hidden,
            "sort_order": data.sort_order,
            "area": data.area,
            "metadata_json": data.metadata_json,
        }

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    monkeypatch.setattr(
        "app.domains.smart_home.service.save_user_entity_preference",
        save_user_entity_preference,
    )

    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.put(
                "/v1/smart-home/preferences/me/entities/fan.office",
                json={"alias": "Desk Fan", "hidden": False, "sort_order": 4, "area": "Office"},
            )
    finally:
        _clear_overrides()

    assert response.status_code == 200
    assert response.json()["alias"] == "Desk Fan"


@pytest.mark.asyncio
async def test_update_global_entity_preference_requires_configure(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    async def deny_configure(db, role_name, permission):
        return permission != "smart_home:configure"

    async def permission_exists(db, permission):
        return True

    monkeypatch.setattr("app.core.permissions.role_has_permission", deny_configure)
    monkeypatch.setattr("app.core.permissions.permission_exists", permission_exists)

    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.put(
                "/v1/smart-home/preferences/global/entities/fan.office",
                json={"alias": "Global Fan"},
            )
    finally:
        _clear_overrides()

    assert response.status_code == 403
```

- [ ] **Step 3: Run route tests and verify failure**

Run:

```powershell
cd backend
pytest tests/test_smart_home_router.py::test_update_my_entity_preference_uses_current_user tests/test_smart_home_router.py::test_update_global_entity_preference_requires_configure -v
```

Expected: FAIL with 404 or missing service helpers.

- [ ] **Step 4: Add repository helpers**

In `backend/app/domains/smart_home/repository.py`, add helpers:

```python
async def list_global_entity_preferences(db: AsyncSession) -> list[SmartHomeEntityGlobalPreference]:
    result = await db.execute(select(SmartHomeEntityGlobalPreference))
    return list(result.scalars().all())


async def list_area_preferences(db: AsyncSession, *, user_id: int | None = None) -> list[SmartHomeAreaPreference]:
    stmt = select(SmartHomeAreaPreference)
    if user_id is None:
        stmt = stmt.where(SmartHomeAreaPreference.scope == "global")
    else:
        stmt = stmt.where(SmartHomeAreaPreference.scope == "me", SmartHomeAreaPreference.user_id == user_id)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def upsert_user_entity_preference(
    db: AsyncSession,
    *,
    user_id: int,
    entity_id: str,
    alias: str | None,
    hidden: bool | None,
    sort_order: int | None,
    area: str | None,
    metadata_json: dict[str, Any],
) -> SmartHomeEntityPreference:
    result = await db.execute(
        select(SmartHomeEntityPreference).where(
            SmartHomeEntityPreference.user_id == user_id,
            SmartHomeEntityPreference.entity_id == entity_id,
        )
    )
    pref = result.scalar_one_or_none()
    if pref is None:
        pref = SmartHomeEntityPreference(user_id=user_id, entity_id=entity_id)
        db.add(pref)
    pref.alias = alias
    pref.hidden = hidden
    pref.sort_order = sort_order
    pref.area = area
    pref.metadata_json = metadata_json
    await db.commit()
    await db.refresh(pref)
    return pref


async def upsert_global_entity_preference(
    db: AsyncSession,
    *,
    entity_id: str,
    alias: str | None,
    hidden: bool | None,
    sort_order: int | None,
    area: str | None,
    metadata_json: dict[str, Any],
) -> SmartHomeEntityGlobalPreference:
    result = await db.execute(
        select(SmartHomeEntityGlobalPreference).where(
            SmartHomeEntityGlobalPreference.entity_id == entity_id,
        )
    )
    pref = result.scalar_one_or_none()
    if pref is None:
        pref = SmartHomeEntityGlobalPreference(entity_id=entity_id)
        db.add(pref)
    pref.alias = alias
    pref.hidden = hidden
    pref.sort_order = sort_order
    pref.area = area
    pref.metadata_json = metadata_json
    await db.commit()
    await db.refresh(pref)
    return pref


async def upsert_area_preference(
    db: AsyncSession,
    *,
    scope: str,
    user_id: int | None,
    source_area: str,
    display_name: str | None,
    hidden: bool | None,
    sort_order: int | None,
    metadata_json: dict[str, Any],
) -> SmartHomeAreaPreference:
    result = await db.execute(
        select(SmartHomeAreaPreference).where(
            SmartHomeAreaPreference.scope == scope,
            SmartHomeAreaPreference.user_id.is_(user_id)
            if user_id is None
            else SmartHomeAreaPreference.user_id == user_id,
            SmartHomeAreaPreference.source_area == source_area,
        )
    )
    pref = result.scalar_one_or_none()
    if pref is None:
        pref = SmartHomeAreaPreference(
            scope=scope,
            user_id=user_id,
            source_area=source_area,
        )
        db.add(pref)
    pref.display_name = display_name
    pref.hidden = hidden
    pref.sort_order = sort_order
    pref.metadata_json = metadata_json
    await db.commit()
    await db.refresh(pref)
    return pref


async def delete_user_preferences(db: AsyncSession, *, user_id: int) -> None:
    await db.execute(
        delete(SmartHomeEntityPreference).where(
            SmartHomeEntityPreference.user_id == user_id
        )
    )
    await db.execute(
        delete(SmartHomeAreaPreference).where(
            SmartHomeAreaPreference.scope == "me",
            SmartHomeAreaPreference.user_id == user_id,
        )
    )
    await db.commit()
```

Update repository imports to include `Any`, `delete`, `SmartHomeEntityGlobalPreference`, and `SmartHomeAreaPreference`.

- [ ] **Step 5: Add service preference helpers**

In `backend/app/domains/smart_home/service.py`, add:

```python
def preference_response_from_entity(scope: str, pref: Any) -> SmartHomePreferenceResponse:
    return SmartHomePreferenceResponse(
        scope=scope,
        entity_id=pref.entity_id,
        alias=pref.alias,
        hidden=pref.hidden,
        sort_order=pref.sort_order,
        area=pref.area,
        metadata_json=pref.metadata_json or {},
    )


async def save_user_entity_preference(
    db: AsyncSession,
    *,
    user_id: int,
    entity_id: str,
    data: SmartHomeEntityPreferenceUpdate,
) -> SmartHomePreferenceResponse:
    pref = await repository.upsert_user_entity_preference(
        db,
        user_id=user_id,
        entity_id=entity_id,
        alias=data.alias,
        hidden=data.hidden,
        sort_order=data.sort_order,
        area=data.area,
        metadata_json=data.metadata_json,
    )
    return preference_response_from_entity("me", pref)


async def save_global_entity_preference(
    db: AsyncSession,
    *,
    entity_id: str,
    data: SmartHomeEntityPreferenceUpdate,
) -> SmartHomePreferenceResponse:
    pref = await repository.upsert_global_entity_preference(
        db,
        entity_id=entity_id,
        alias=data.alias,
        hidden=data.hidden,
        sort_order=data.sort_order,
        area=data.area,
        metadata_json=data.metadata_json,
    )
    return preference_response_from_entity("global", pref)


def preference_response_from_area(scope: str, pref: Any) -> SmartHomePreferenceResponse:
    return SmartHomePreferenceResponse(
        scope=scope,
        source_area=pref.source_area,
        display_name=pref.display_name,
        hidden=pref.hidden,
        sort_order=pref.sort_order,
        metadata_json=pref.metadata_json or {},
    )


async def save_user_area_preference(
    db: AsyncSession,
    *,
    user_id: int,
    source_area: str,
    data: SmartHomeAreaPreferenceUpdate,
) -> SmartHomePreferenceResponse:
    pref = await repository.upsert_area_preference(
        db,
        scope="me",
        user_id=user_id,
        source_area=source_area,
        display_name=data.display_name,
        hidden=data.hidden,
        sort_order=data.sort_order,
        metadata_json=data.metadata_json,
    )
    return preference_response_from_area("me", pref)


async def save_global_area_preference(
    db: AsyncSession,
    *,
    source_area: str,
    data: SmartHomeAreaPreferenceUpdate,
) -> SmartHomePreferenceResponse:
    pref = await repository.upsert_area_preference(
        db,
        scope="global",
        user_id=None,
        source_area=source_area,
        display_name=data.display_name,
        hidden=data.hidden,
        sort_order=data.sort_order,
        metadata_json=data.metadata_json,
    )
    return preference_response_from_area("global", pref)


async def list_preferences(db: AsyncSession, *, user_id: int) -> SmartHomePreferencesResponse:
    global_entities = await repository.list_global_entity_preferences(db)
    user_entities = await repository.list_preferences(db, user_id=user_id)
    global_areas = await repository.list_area_preferences(db)
    user_areas = await repository.list_area_preferences(db, user_id=user_id)
    return SmartHomePreferencesResponse(
        entity_preferences=[
            *(preference_response_from_entity("global", pref) for pref in global_entities),
            *(preference_response_from_entity("me", pref) for pref in user_entities),
        ],
        area_preferences=[
            *(preference_response_from_area("global", pref) for pref in global_areas),
            *(preference_response_from_area("me", pref) for pref in user_areas),
        ],
    )


async def reset_user_preferences(db: AsyncSession, *, user_id: int) -> dict[str, str | bool]:
    await repository.delete_user_preferences(db, user_id=user_id)
    return {"ok": True, "message": "Smart home display preferences reset"}
```

Update service imports to include `SmartHomeAreaPreferenceUpdate`, `SmartHomeEntityPreferenceUpdate`, `SmartHomePreferenceResponse`, and `SmartHomePreferencesResponse`.

- [ ] **Step 6: Add router endpoints**

In `backend/app/domains/smart_home/router.py`, add routes:

```python
@router.get("/preferences", response_model=SmartHomePreferencesResponse)
async def get_preferences(
    current_user: User = Depends(require_permission("smart_home:read")),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_preferences(db, user_id=current_user.id)


@router.put("/preferences/me/entities/{entity_id}", response_model=SmartHomePreferenceResponse)
async def update_my_entity_preference(
    entity_id: str,
    data: SmartHomeEntityPreferenceUpdate,
    current_user: User = Depends(require_permission("smart_home:read")),
    db: AsyncSession = Depends(get_db),
):
    return await service.save_user_entity_preference(
        db,
        user_id=current_user.id,
        entity_id=entity_id,
        data=data,
    )


@router.put("/preferences/global/entities/{entity_id}", response_model=SmartHomePreferenceResponse)
async def update_global_entity_preference(
    entity_id: str,
    data: SmartHomeEntityPreferenceUpdate,
    current_user: User = Depends(require_permission("smart_home:configure")),
    db: AsyncSession = Depends(get_db),
):
    return await service.save_global_entity_preference(db, entity_id=entity_id, data=data)


@router.put("/preferences/me/areas/{source_area}", response_model=SmartHomePreferenceResponse)
async def update_my_area_preference(
    source_area: str,
    data: SmartHomeAreaPreferenceUpdate,
    current_user: User = Depends(require_permission("smart_home:read")),
    db: AsyncSession = Depends(get_db),
):
    return await service.save_user_area_preference(
        db,
        user_id=current_user.id,
        source_area=source_area,
        data=data,
    )


@router.put("/preferences/global/areas/{source_area}", response_model=SmartHomePreferenceResponse)
async def update_global_area_preference(
    source_area: str,
    data: SmartHomeAreaPreferenceUpdate,
    current_user: User = Depends(require_permission("smart_home:configure")),
    db: AsyncSession = Depends(get_db),
):
    return await service.save_global_area_preference(
        db,
        source_area=source_area,
        data=data,
    )


@router.post("/preferences/me/reset")
async def reset_my_preferences(
    current_user: User = Depends(require_permission("smart_home:read")),
    db: AsyncSession = Depends(get_db),
):
    return await service.reset_user_preferences(db, user_id=current_user.id)
```

Update router imports to include `SmartHomeAreaPreferenceUpdate`, `SmartHomeEntityPreferenceUpdate`, `SmartHomePreferenceResponse`, and `SmartHomePreferencesResponse`.

- [ ] **Step 7: Run route tests**

Run:

```powershell
cd backend
pytest tests/test_smart_home_router.py tests/test_smart_home_preferences.py -v
```

Expected: PASS.

- [ ] **Step 8: Commit task**

Run:

```powershell
git add backend/app/schemas/smart_home.py backend/app/domains/smart_home/repository.py backend/app/domains/smart_home/service.py backend/app/domains/smart_home/router.py backend/tests/test_smart_home_router.py backend/tests/test_smart_home_preferences.py
git commit -m "feat: add smart home preference api"
```

---

## Task 4: Merge Preferences Into Entity Listing

**Files:**
- Modify: `backend/app/domains/smart_home/service.py`
- Modify: `backend/app/domains/smart_home/router.py`
- Modify: `backend/tests/test_smart_home_router.py`
- Modify: `backend/tests/test_smart_home_preferences.py`

- [ ] **Step 1: Add service test for list merge**

Add a test that monkeypatches repository and HA client behavior:

```python
@pytest.mark.asyncio
async def test_list_entities_returns_effective_display_data(monkeypatch):
    from app.domains.smart_home import service

    config = SimpleNamespace(
        base_url="http://ha.local:8123",
        encrypted_token="encrypted",
        enabled=True,
    )

    async def get_config(db):
        return config

    async def list_preferences(db, user_id):
        return [
            SimpleNamespace(user_id=user_id, entity_id="switch.kitchen", alias="My Switch", hidden=False, sort_order=2, area="Kitchen", metadata_json={})
        ]

    async def list_global_entity_preferences(db):
        return []

    async def list_area_preferences(db, user_id=None):
        return []

    class FakeClient:
        async def get_states(self):
            return [{"entity_id": "switch.kitchen", "state": "on", "attributes": {"friendly_name": "Kitchen"}}]

        async def aclose(self):
            return None

    monkeypatch.setattr(service.repository, "get_config", get_config)
    monkeypatch.setattr(service.repository, "list_preferences", list_preferences)
    monkeypatch.setattr(service.repository, "list_global_entity_preferences", list_global_entity_preferences)
    monkeypatch.setattr(service.repository, "list_area_preferences", list_area_preferences)
    monkeypatch.setattr(service, "_client", lambda config: FakeClient())

    response = await service.list_entities(SimpleNamespace(), user_id=1)

    assert response.items[0].effective_name == "My Switch"
    assert response.items[0].effective_sort_order == 2
```

- [ ] **Step 2: Run test and verify failure**

Run:

```powershell
cd backend
pytest tests/test_smart_home_preferences.py::test_list_entities_returns_effective_display_data -v
```

Expected: FAIL because `list_entities` does not accept `user_id` and does not merge preferences.

- [ ] **Step 3: Update service listing**

Change signature:

```python
async def list_entities(db: AsyncSession, *, user_id: int) -> SmartHomeEntityListResponse:
```

Inside successful HA response path:

```python
global_entity_prefs = {
    pref.entity_id: pref for pref in await repository.list_global_entity_preferences(db)
}
user_entity_prefs = {
    pref.entity_id: pref for pref in await repository.list_preferences(db, user_id=user_id)
}
global_area_prefs = {
    pref.source_area: pref for pref in await repository.list_area_preferences(db)
}
user_area_prefs = {
    pref.source_area: pref for pref in await repository.list_area_preferences(db, user_id=user_id)
}
items = []
for raw in states:
    entity = normalize_entity(raw)
    if entity is None:
        continue
    source_area = (
        getattr(user_entity_prefs.get(entity.entity_id), "area", None)
        or getattr(global_entity_prefs.get(entity.entity_id), "area", None)
        or entity.area
    )
    items.append(
        merge_entity_display(
            entity,
            global_pref=global_entity_prefs.get(entity.entity_id),
            user_pref=user_entity_prefs.get(entity.entity_id),
            global_area_pref=global_area_prefs.get(source_area),
            user_area_pref=user_area_prefs.get(source_area),
        )
    )
items.sort(key=lambda item: (item.area_sort_order, item.effective_area or item.domain, item.effective_sort_order, item.effective_name))
```

- [ ] **Step 4: Update router call**

In `list_entities` route:

```python
return await service.list_entities(db, user_id=current_user.id)
```

- [ ] **Step 5: Update existing tests that monkeypatch list_entities**

Change fake function signatures in `backend/tests/test_smart_home_router.py`:

```python
async def list_entities(db, user_id):
    ...
```

- [ ] **Step 6: Run smart home backend tests**

Run:

```powershell
cd backend
pytest tests/test_smart_home_router.py tests/test_smart_home_preferences.py tests/test_smart_home_ha_client.py tests/test_smart_home_crypto.py -v
```

Expected: PASS.

- [ ] **Step 7: Commit task**

Run:

```powershell
git add backend/app/domains/smart_home/service.py backend/app/domains/smart_home/router.py backend/tests/test_smart_home_router.py backend/tests/test_smart_home_preferences.py
git commit -m "feat: merge smart home preferences into entities"
```

---

## Task 5: Frontend Types and API Client

**Files:**
- Modify: `frontend/src/features/smart-home/types.ts`
- Modify: `frontend/src/features/smart-home/api/smartHome.ts`

- [ ] **Step 1: Update frontend types**

Replace entity-related types in `frontend/src/features/smart-home/types.ts` with:

```ts
export interface SmartHomeEntityCapabilities {
  can_turn_on: boolean;
  can_turn_off: boolean;
  can_toggle: boolean;
  can_set_percentage: boolean;
  can_set_temperature: boolean;
  can_set_hvac_mode: boolean;
  percentage: number | null;
  percentage_step: number | null;
  temperature: number | null;
  current_temperature: number | null;
  min_temp: number | null;
  max_temp: number | null;
  target_temp_step: number | null;
  hvac_modes: string[];
}

export interface SmartHomeEntity {
  entity_id: string;
  domain: SmartHomeDomain;
  name: string;
  state: string;
  area: string | null;
  effective_name: string;
  effective_area: string | null;
  effective_hidden: boolean;
  effective_sort_order: number;
  area_sort_order: number;
  supports: SmartHomeEntityCapabilities;
  attributes: Record<string, unknown>;
  last_changed: string | null;
  last_updated: string | null;
  available: boolean;
}

export type SmartHomePreferenceScope = "me" | "global";

export interface SmartHomeEntityPreferenceUpdate {
  alias?: string | null;
  hidden?: boolean | null;
  sort_order?: number | null;
  area?: string | null;
  metadata_json?: Record<string, unknown>;
}

export interface SmartHomeAreaPreferenceUpdate {
  display_name?: string | null;
  hidden?: boolean | null;
  sort_order?: number | null;
  metadata_json?: Record<string, unknown>;
}

export interface SmartHomePreferenceResponse {
  scope: SmartHomePreferenceScope;
  entity_id: string | null;
  source_area: string | null;
  alias: string | null;
  display_name: string | null;
  hidden: boolean | null;
  sort_order: number | null;
  area: string | null;
  metadata_json: Record<string, unknown>;
}

export interface SmartHomePreferencesResponse {
  entity_preferences: SmartHomePreferenceResponse[];
  area_preferences: SmartHomePreferenceResponse[];
}
```

- [ ] **Step 2: Update API client**

In `frontend/src/features/smart-home/api/smartHome.ts`, add:

```ts
  getPreferences: () =>
    api.get<SmartHomePreferencesResponse>("/v1/smart-home/preferences"),
  updateMyEntityPreference: (
    entityId: string,
    data: SmartHomeEntityPreferenceUpdate,
  ) =>
    api.put<SmartHomePreferenceResponse>(
      `/v1/smart-home/preferences/me/entities/${encodeURIComponent(entityId)}`,
      data,
    ),
  updateGlobalEntityPreference: (
    entityId: string,
    data: SmartHomeEntityPreferenceUpdate,
  ) =>
    api.put<SmartHomePreferenceResponse>(
      `/v1/smart-home/preferences/global/entities/${encodeURIComponent(entityId)}`,
      data,
    ),
  updateMyAreaPreference: (
    sourceArea: string,
    data: SmartHomeAreaPreferenceUpdate,
  ) =>
    api.put<SmartHomePreferenceResponse>(
      `/v1/smart-home/preferences/me/areas/${encodeURIComponent(sourceArea)}`,
      data,
    ),
  updateGlobalAreaPreference: (
    sourceArea: string,
    data: SmartHomeAreaPreferenceUpdate,
  ) =>
    api.put<SmartHomePreferenceResponse>(
      `/v1/smart-home/preferences/global/areas/${encodeURIComponent(sourceArea)}`,
      data,
    ),
  resetMyPreferences: () =>
    api.post<{ ok: boolean; message: string }>(
      "/v1/smart-home/preferences/me/reset",
    ),
```

Update imports to include the new types.

- [ ] **Step 3: Build frontend**

Run:

```powershell
cd frontend
npm run build
```

Expected: PASS.

- [ ] **Step 4: Commit task**

Run:

```powershell
git add frontend/src/features/smart-home/types.ts frontend/src/features/smart-home/api/smartHome.ts
git commit -m "feat: add smart home preference client types"
```

---

## Task 6: Frontend Component Split and Controls

**Files:**
- Create: `frontend/src/features/smart-home/components/SmartHomeToolbar.tsx`
- Create: `frontend/src/features/smart-home/components/SmartHomeActionSection.tsx`
- Create: `frontend/src/features/smart-home/components/SmartHomeEntityCard.tsx`
- Create: `frontend/src/features/smart-home/components/SmartHomePreferenceModal.tsx`
- Modify: `frontend/src/features/smart-home/SmartHomePage.tsx`

- [ ] **Step 1: Create toolbar component**

Create `SmartHomeToolbar.tsx`:

```tsx
import { Input, Select, Space, Switch } from "antd";
import type { SmartHomeDomain, SmartHomeEntity } from "../types";

export type SmartHomeSortMode = "area" | "name" | "updated";

interface SmartHomeToolbarProps {
  entities: SmartHomeEntity[];
  search: string;
  domain: SmartHomeDomain | "all";
  area: string;
  showHidden: boolean;
  sortMode: SmartHomeSortMode;
  onSearchChange: (value: string) => void;
  onDomainChange: (value: SmartHomeDomain | "all") => void;
  onAreaChange: (value: string) => void;
  onShowHiddenChange: (value: boolean) => void;
  onSortModeChange: (value: SmartHomeSortMode) => void;
}

const DOMAINS: Array<SmartHomeDomain | "all"> = [
  "all",
  "light",
  "switch",
  "fan",
  "cover",
  "climate",
  "scene",
  "script",
];

export default function SmartHomeToolbar({
  entities,
  search,
  domain,
  area,
  showHidden,
  sortMode,
  onSearchChange,
  onDomainChange,
  onAreaChange,
  onShowHiddenChange,
  onSortModeChange,
}: SmartHomeToolbarProps) {
  const areaOptions = Array.from(
    new Set(entities.map((entity) => entity.effective_area || entity.domain)),
  ).sort();

  return (
    <Space wrap style={{ marginBottom: 20 }}>
      <Input.Search
        allowClear
        placeholder="Search devices"
        value={search}
        onChange={(event) => onSearchChange(event.target.value)}
        style={{ width: 240 }}
      />
      <Select
        value={domain}
        onChange={onDomainChange}
        style={{ width: 150 }}
        options={DOMAINS.map((item) => ({ value: item, label: item }))}
      />
      <Select
        allowClear
        placeholder="Area"
        value={area || undefined}
        onChange={(value) => onAreaChange(value || "")}
        style={{ width: 180 }}
        options={areaOptions.map((item) => ({ value: item, label: item }))}
      />
      <Select
        value={sortMode}
        onChange={onSortModeChange}
        style={{ width: 150 }}
        options={[
          { value: "area", label: "Area first" },
          { value: "name", label: "Name" },
          { value: "updated", label: "Updated" },
        ]}
      />
      <Switch checked={showHidden} onChange={onShowHiddenChange} />
      <span>Show hidden</span>
    </Space>
  );
}
```

- [ ] **Step 2: Create action section component**

Create `SmartHomeActionSection.tsx`:

```tsx
import { Button, Card, Empty, Row, Col, Space, Tag, Typography } from "antd";
import { PoweroffOutlined } from "@ant-design/icons";
import type { SmartHomeEntity } from "../types";

const { Text, Title } = Typography;

interface SmartHomeActionSectionProps {
  scenes: SmartHomeEntity[];
  scripts: SmartHomeEntity[];
  onRun: (entity: SmartHomeEntity) => void;
}

function ActionCard({
  entity,
  onRun,
}: {
  entity: SmartHomeEntity;
  onRun: (entity: SmartHomeEntity) => void;
}) {
  return (
    <Col key={entity.entity_id} xs={24} sm={12} lg={8} xl={6}>
      <Card>
        <Space direction="vertical" style={{ width: "100%" }}>
          <Space style={{ justifyContent: "space-between", width: "100%" }}>
            <Text strong>{entity.effective_name}</Text>
            <Tag>{entity.domain}</Tag>
          </Space>
          <Text type="secondary">{entity.entity_id}</Text>
          <Button
            icon={<PoweroffOutlined />}
            disabled={!entity.available}
            onClick={() => onRun(entity)}
          >
            {entity.domain === "scene" ? "Run scene" : "Run script"}
          </Button>
        </Space>
      </Card>
    </Col>
  );
}

export default function SmartHomeActionSection({
  scenes,
  scripts,
  onRun,
}: SmartHomeActionSectionProps) {
  const actions = [...scenes, ...scripts];

  return (
    <section style={{ marginBottom: 24 }}>
      <Title level={4}>Scenes and scripts</Title>
      {actions.length === 0 ? (
        <Empty description="Home Assistant did not return scene or script entities" />
      ) : (
        <Row gutter={[16, 16]}>
          {actions.map((entity) => (
            <ActionCard key={entity.entity_id} entity={entity} onRun={onRun} />
          ))}
        </Row>
      )}
    </section>
  );
}
```

- [ ] **Step 3: Create entity card component**

Create `SmartHomeEntityCard.tsx` with:

```tsx
import { Button, Card, InputNumber, Select, Slider, Space, Switch, Tag, Typography } from "antd";
import { PoweroffOutlined, SettingOutlined } from "@ant-design/icons";
import type { SmartHomeEntity } from "../types";

const { Text } = Typography;

interface SmartHomeEntityCardProps {
  entity: SmartHomeEntity;
  onCallService: (entity: SmartHomeEntity, service: string, serviceData?: Record<string, unknown>) => void;
  onEdit: (entity: SmartHomeEntity) => void;
}

export default function SmartHomeEntityCard({ entity, onCallService, onEdit }: SmartHomeEntityCardProps) {
  const toggleService = entity.state === "on" ? "turn_off" : "turn_on";

  return (
    <Card>
      <Space direction="vertical" style={{ width: "100%" }}>
        <Space style={{ justifyContent: "space-between", width: "100%" }}>
          <Text strong>{entity.effective_name}</Text>
          <Tag>{entity.state}</Tag>
        </Space>
        <Text type="secondary">{entity.entity_id}</Text>
        {["light", "switch", "fan"].includes(entity.domain) && (
          <Switch
            checked={entity.state === "on"}
            disabled={!entity.available}
            onChange={() => onCallService(entity, toggleService)}
          />
        )}
        {entity.domain === "fan" && entity.supports.can_set_percentage && (
          <Slider
            min={0}
            max={100}
            step={entity.supports.percentage_step || 1}
            value={entity.supports.percentage || 0}
            onAfterChange={(value) =>
              onCallService(entity, "set_percentage", { percentage: value })
            }
          />
        )}
        {entity.domain === "climate" && entity.supports.can_set_temperature && (
          <InputNumber
            min={entity.supports.min_temp ?? undefined}
            max={entity.supports.max_temp ?? undefined}
            step={entity.supports.target_temp_step || 1}
            value={entity.supports.temperature ?? undefined}
            onChange={(value) => {
              if (typeof value === "number") {
                onCallService(entity, "set_temperature", { temperature: value });
              }
            }}
          />
        )}
        {entity.domain === "climate" && entity.supports.can_set_hvac_mode && (
          <Select
            value={entity.state}
            onChange={(value) => onCallService(entity, "set_hvac_mode", { hvac_mode: value })}
            options={entity.supports.hvac_modes.map((mode) => ({ value: mode, label: mode }))}
          />
        )}
        {entity.domain === "cover" && (
          <Space>
            <Button onClick={() => onCallService(entity, "open_cover")}>Open</Button>
            <Button onClick={() => onCallService(entity, "stop_cover")}>Stop</Button>
            <Button onClick={() => onCallService(entity, "close_cover")}>Close</Button>
          </Space>
        )}
        <Button icon={<SettingOutlined />} onClick={() => onEdit(entity)}>
          Display
        </Button>
      </Space>
    </Card>
  );
}
```

Remove unused imports after integrating.

- [ ] **Step 4: Create preference modal**

Create `SmartHomePreferenceModal.tsx`:

```tsx
import { Form, Input, InputNumber, Modal, Select, Switch } from "antd";
import { useEffect } from "react";
import type {
  SmartHomeAreaPreferenceUpdate,
  SmartHomeEntity,
  SmartHomeEntityPreferenceUpdate,
  SmartHomePreferenceScope,
} from "../types";

type PreferenceTarget =
  | { kind: "entity"; entity: SmartHomeEntity }
  | { kind: "area"; sourceArea: string; displayName: string };

type PreferenceValues = {
  scope: SmartHomePreferenceScope;
  alias?: string;
  display_name?: string;
  hidden?: boolean;
  sort_order?: number;
  area?: string;
};

interface SmartHomePreferenceModalProps {
  open: boolean;
  target: PreferenceTarget | null;
  canEditGlobal: boolean;
  areaOptions: string[];
  onCancel: () => void;
  onSubmit: (
    target: PreferenceTarget,
    scope: SmartHomePreferenceScope,
    data: SmartHomeEntityPreferenceUpdate | SmartHomeAreaPreferenceUpdate,
  ) => Promise<void>;
}

export default function SmartHomePreferenceModal({
  open,
  target,
  canEditGlobal,
  areaOptions,
  onCancel,
  onSubmit,
}: SmartHomePreferenceModalProps) {
  const [form] = Form.useForm<PreferenceValues>();

  useEffect(() => {
    if (!target) return;
    form.setFieldsValue({
      scope: "me",
      alias: target.kind === "entity" ? target.entity.effective_name : undefined,
      display_name: target.kind === "area" ? target.displayName : undefined,
      hidden: target.kind === "entity" ? target.entity.effective_hidden : false,
      sort_order:
        target.kind === "entity"
          ? target.entity.effective_sort_order
          : target.kind === "area"
            ? 0
            : undefined,
      area: target.kind === "entity" ? target.entity.effective_area || undefined : undefined,
    });
  }, [form, target]);

  const save = async () => {
    if (!target) return;
    const values = await form.validateFields();
    if (target.kind === "entity") {
      await onSubmit(target, values.scope, {
        alias: values.alias || null,
        hidden: values.hidden ?? null,
        sort_order: values.sort_order ?? null,
        area: values.area || null,
        metadata_json: {},
      });
      return;
    }
    await onSubmit(target, values.scope, {
      display_name: values.display_name || null,
      hidden: values.hidden ?? null,
      sort_order: values.sort_order ?? null,
      metadata_json: {},
    });
  };

  return (
    <Modal
      title={target?.kind === "area" ? "Area display settings" : "Device display settings"}
      open={open}
      onOk={save}
      onCancel={onCancel}
    >
      <Form form={form} layout="vertical" initialValues={{ scope: "me" }}>
        <Form.Item name="scope" label="Scope">
          <Select
            options={[
              { value: "me", label: "Only me" },
              ...(canEditGlobal ? [{ value: "global", label: "Global default" }] : []),
            ]}
          />
        </Form.Item>
        {target?.kind === "entity" ? (
          <>
            <Form.Item name="alias" label="Alias">
              <Input />
            </Form.Item>
            <Form.Item name="area" label="Display area">
              <Select
                allowClear
                options={areaOptions.map((area) => ({ value: area, label: area }))}
              />
            </Form.Item>
          </>
        ) : (
          <Form.Item name="display_name" label="Display name">
            <Input />
          </Form.Item>
        )}
        <Form.Item name="sort_order" label="Sort order">
          <InputNumber style={{ width: "100%" }} />
        </Form.Item>
        <Form.Item name="hidden" label="Hidden" valuePropName="checked">
          <Switch />
        </Form.Item>
      </Form>
    </Modal>
  );
}
```

- [ ] **Step 5: Update SmartHomePage orchestration**

Update `SmartHomePage.tsx` to:

1. load entities
2. keep toolbar state
3. split `scene` and `script` entities from device entities
4. filter by search/domain/area/hidden
5. group by `effective_area || domain`
6. call preference APIs from the modal
7. reload entities after saves
8. keep SSE updates by replacing raw entity entries with effective fields preserved when possible

- [ ] **Step 6: Build frontend**

Run:

```powershell
cd frontend
npm run build
```

Expected: PASS.

- [ ] **Step 7: Commit task**

Run:

```powershell
git add frontend/src/features/smart-home
git commit -m "feat: enhance smart home console ui"
```

---

## Task 7: E2E Smoke Coverage and Verification

**Files:**
- Create: `frontend/tests/e2e/smart-home.spec.ts`
- Modify only if the manual checklist already has a Smart Home section: `backend/tests/manual_verification_checklist.md`

- [ ] **Step 1: Add Playwright smoke test**

Create `frontend/tests/e2e/smart-home.spec.ts`:

```ts
import { expect, test } from "@playwright/test";

const BASE_URL = process.env.E2E_BASE_URL || "http://localhost:5173";

async function setAuthToken(page: import("@playwright/test").Page) {
  await page.addInitScript((token) => {
    localStorage.setItem("auth_token", token);
    localStorage.setItem(
      "auth_user",
      JSON.stringify({
        id: 1,
        username: "e2e",
        email: "e2e@example.com",
        role: "super_admin",
        is_active: true,
      }),
    );
  }, process.env.E2E_TEST_LOGIN!);
}

test.describe("Smart Home page", () => {
  test.skip(
    !process.env.E2E_TEST_LOGIN,
    "Requires E2E_TEST_LOGIN env var with auth token",
  );

  test("shows the smart home console shell", async ({ page }) => {
    await setAuthToken(page);
    await page.goto(`${BASE_URL}/smart-home`);
    await expect(page.getByRole("heading", { name: "Smart Home" })).toBeVisible();
    await expect(page.getByPlaceholder("Search devices")).toBeVisible();
    await expect(page.getByRole("button", { name: "Refresh" })).toBeVisible();
  });
});
```

- [ ] **Step 2: Run backend focused tests**

Run:

```powershell
cd backend
pytest tests/test_smart_home_router.py tests/test_smart_home_preferences.py tests/test_smart_home_ha_client.py tests/test_smart_home_crypto.py -v
```

Expected: PASS.

- [ ] **Step 3: Run backend lint**

Run:

```powershell
cd backend
ruff check app/domains/smart_home app/schemas/smart_home.py app/models/smart_home.py tests/test_smart_home_router.py tests/test_smart_home_preferences.py
```

Expected: PASS.

- [ ] **Step 4: Run frontend lint and build**

Run:

```powershell
cd frontend
npm run lint
npm run build
```

Expected: PASS.

- [ ] **Step 5: Manual QA with local Home Assistant data**

Start the app with the existing project launcher:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start_server.ps1
```

Open:

```text
http://localhost:3000/smart-home
```

Verify:

1. Switch and light cards still toggle.
2. Fan cards show percentage controls when the entity exposes percentage attributes.
3. Climate cards show temperature and HVAC mode controls when attributes are present.
4. Scene and script section either lists actions or clearly says none were returned by Home Assistant.
5. Search and filters reduce the visible list correctly.
6. Hidden items disappear unless `Show hidden` is enabled.
7. Personal alias and area edits affect the current user.
8. Global alias and area edits apply when no personal override exists.
9. Reset current-user overrides restores global or Home Assistant values.

- [ ] **Step 6: Run GitNexus detect changes before final commit**

Run:

```text
gitnexus_detect_changes(scope="all", repo="mavra-monitor-system")
```

Expected: Changed symbols and affected flows match Smart Home backend/frontend work only.

- [ ] **Step 7: Commit task**

Run:

```powershell
git add frontend/tests/e2e/smart-home.spec.ts
git commit -m "test: add smart home console verification"
```

If `backend/tests/manual_verification_checklist.md` was updated during manual QA documentation, include it in the same `git add` command.

---

## Final Quality Gate

- [ ] `pytest` focused Smart Home tests pass.
- [ ] `ruff check` focused Smart Home backend files passes.
- [ ] `npm run lint` passes.
- [ ] `npm run build` passes.
- [ ] Manual Smart Home browser QA is complete or blocked with a concrete reason.
- [ ] `gitnexus_detect_changes()` has been run before the final delivery commit.

## Execution Notes

1. Do not run real Home Assistant or crawl-like tests unless the user explicitly wants live verification.
2. Do not hardcode Home Assistant tokens or secrets.
3. Keep `SMART_HOME_SECRET_KEY` handling server-side.
4. Keep frontend display fields driven by backend capability flags.
5. Prefer small commits after each task so review can stop or roll forward cleanly.
