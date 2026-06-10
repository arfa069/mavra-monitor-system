from types import SimpleNamespace

import pytest

from app.domains.smart_home import service


@pytest.fixture(autouse=True)
def clear_entity_snapshot_cache():
    service._entity_snapshot_cache.key = None
    service._entity_snapshot_cache.response = None
    service._entity_snapshot_cache.expires_at = 0.0
    yield
    service._entity_snapshot_cache.key = None
    service._entity_snapshot_cache.response = None
    service._entity_snapshot_cache.expires_at = 0.0


@pytest.mark.asyncio
async def test_list_entities_reuses_recent_snapshot(monkeypatch):
    calls = {"get_states": 0, "update_status": 0}
    config = SimpleNamespace(
        base_url="http://homeassistant.local:8123",
        encrypted_token="encrypted",
        enabled=True,
    )

    async def get_config(db):
        return config

    async def update_status(db, *, config, status, error):
        calls["update_status"] += 1
        return config

    class FakeClient:
        async def get_states(self):
            calls["get_states"] += 1
            return [
                {
                    "entity_id": "switch.kitchen",
                    "attributes": {"friendly_name": "Kitchen Switch"},
                    "state": "on",
                }
            ]

        async def aclose(self):
            return None

    monkeypatch.setattr("app.domains.smart_home.repository.get_config", get_config)
    monkeypatch.setattr(
        "app.domains.smart_home.repository.update_status", update_status
    )
    monkeypatch.setattr(
        "app.domains.smart_home.service._client", lambda current: FakeClient()
    )

    first = await service.list_entities(SimpleNamespace())
    second = await service.list_entities(SimpleNamespace())

    assert first.total == 1
    assert second.total == 1
    assert calls["get_states"] == 1
    assert calls["update_status"] == 1


@pytest.mark.asyncio
async def test_get_summary_uses_cached_snapshot_counts(monkeypatch):
    config = SimpleNamespace(
        base_url="http://homeassistant.local:8123",
        encrypted_token="encrypted",
        enabled=True,
        last_status="ok",
        last_error=None,
    )

    async def get_config(db):
        return config

    monkeypatch.setattr("app.domains.smart_home.repository.get_config", get_config)

    service._store_cached_entity_response(
        config,
        service.SmartHomeEntityListResponse(
            items=[
                service.SmartHomeEntity(
                    entity_id="light.living_room",
                    domain="light",
                    name="Living Room",
                    state="on",
                    attributes={},
                    available=True,
                ),
                service.SmartHomeEntity(
                    entity_id="switch.kitchen",
                    domain="switch",
                    name="Kitchen Switch",
                    state="unavailable",
                    attributes={},
                    available=False,
                ),
            ],
            total=2,
            connected=True,
        ),
    )

    summary = await service.get_summary(SimpleNamespace())

    assert summary.configured is True
    assert summary.connected is True
    assert summary.active_count == 1
    assert summary.unavailable_count == 1


@pytest.mark.asyncio
async def test_get_summary_falls_back_to_config_status_without_snapshot(monkeypatch):
    config = SimpleNamespace(
        base_url="http://homeassistant.local:8123",
        encrypted_token="encrypted",
        enabled=True,
        last_status="connected",
        last_error=None,
    )

    async def get_config(db):
        return config

    monkeypatch.setattr("app.domains.smart_home.repository.get_config", get_config)

    summary = await service.get_summary(SimpleNamespace())

    assert summary.configured is True
    assert summary.connected is True
    assert summary.active_count == 0
    assert summary.unavailable_count == 0


@pytest.mark.asyncio
async def test_get_summary_returns_unconfigured_when_smart_home_missing(monkeypatch):
    async def get_config(db):
        return None

    monkeypatch.setattr("app.domains.smart_home.repository.get_config", get_config)

    summary = await service.get_summary(SimpleNamespace())

    assert summary.configured is False
    assert summary.connected is False
    assert summary.active_count == 0
    assert summary.unavailable_count == 0
