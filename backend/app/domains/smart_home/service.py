"""Smart home business logic."""
from __future__ import annotations

import asyncio
from dataclasses import dataclass
from datetime import UTC, datetime
from time import monotonic
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.domains.smart_home import repository
from app.domains.smart_home.crypto import decrypt_token, encrypt_token
from app.domains.smart_home.ha_client import HomeAssistantClient, HomeAssistantError
from app.models.smart_home import SmartHomeConfig
from app.schemas.smart_home import (
    SmartHomeConfigTestResponse,
    SmartHomeConfigUpdate,
    SmartHomeEntity,
    SmartHomeEntityListResponse,
    SmartHomeSummaryResponse,
)

SUPPORTED_DOMAINS = {"light", "switch", "fan", "cover", "climate", "scene", "script"}
ALLOWED_SERVICES = {
    "light": {"turn_on", "turn_off", "toggle"},
    "switch": {"turn_on", "turn_off", "toggle"},
    "fan": {"turn_on", "turn_off", "toggle", "set_percentage"},
    "cover": {"open_cover", "close_cover", "stop_cover"},
    "climate": {"set_temperature", "set_hvac_mode"},
    "scene": {"turn_on"},
    "script": {"turn_on"},
}
ENTITY_SNAPSHOT_CACHE_TTL_SECONDS = 10.0


@dataclass
class _EntitySnapshotCache:
    key: tuple[str, str, bool] | None = None
    response: SmartHomeEntityListResponse | None = None
    expires_at: float = 0.0


_entity_snapshot_cache = _EntitySnapshotCache()
_entity_snapshot_lock = asyncio.Lock()


class SmartHomeConfigMissingError(LookupError):
    pass


class SmartHomeUnsupportedEntityError(ValueError):
    pass


class SmartHomeUnsupportedServiceError(ValueError):
    pass


def _client(config: SmartHomeConfig) -> HomeAssistantClient:
    token = decrypt_token(config.encrypted_token, settings.smart_home_secret_key)
    return HomeAssistantClient(base_url=config.base_url, token=token)


def _snapshot_cache_key(config: SmartHomeConfig) -> tuple[str, str, bool]:
    return (config.base_url, config.encrypted_token, config.enabled)


def _clone_entity_response(
    response: SmartHomeEntityListResponse,
) -> SmartHomeEntityListResponse:
    return SmartHomeEntityListResponse.model_validate(response.model_dump())


def _get_cached_entity_response(
    config: SmartHomeConfig,
) -> SmartHomeEntityListResponse | None:
    if _entity_snapshot_cache.key != _snapshot_cache_key(config):
        return None
    if _entity_snapshot_cache.response is None:
        return None
    if monotonic() >= _entity_snapshot_cache.expires_at:
        return None
    return _clone_entity_response(_entity_snapshot_cache.response)


def _store_cached_entity_response(
    config: SmartHomeConfig, response: SmartHomeEntityListResponse
) -> None:
    _entity_snapshot_cache.key = _snapshot_cache_key(config)
    _entity_snapshot_cache.response = _clone_entity_response(response)
    _entity_snapshot_cache.expires_at = (
        monotonic() + ENTITY_SNAPSHOT_CACHE_TTL_SECONDS
    )


def normalize_entity(raw: dict[str, Any]) -> SmartHomeEntity | None:
    entity_id = str(raw.get("entity_id", ""))
    domain = entity_id.split(".", 1)[0] if "." in entity_id else ""
    if domain not in SUPPORTED_DOMAINS:
        return None
    attributes = raw.get("attributes") if isinstance(raw.get("attributes"), dict) else {}
    name = attributes.get("friendly_name") or entity_id
    return SmartHomeEntity(
        entity_id=entity_id,
        domain=domain,
        name=name,
        state=str(raw.get("state", "unknown")),
        area=attributes.get("area") or attributes.get("area_id"),
        attributes=attributes,
        last_changed=_parse_dt(raw.get("last_changed")),
        last_updated=_parse_dt(raw.get("last_updated")),
        available=raw.get("state") not in {"unavailable", "unknown"},
    )


def _parse_dt(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=UTC)
        return dt
    except ValueError:
        return None


async def get_config(db: AsyncSession) -> SmartHomeConfig:
    config = await repository.get_config(db)
    if config is None:
        raise SmartHomeConfigMissingError
    return config


async def save_config(db: AsyncSession, *, data: SmartHomeConfigUpdate) -> SmartHomeConfig:
    existing = await repository.get_config(db)
    if not data.token and existing is None:
        raise SmartHomeConfigMissingError("Home Assistant token is required")
    encrypted_token = (
        encrypt_token(data.token, settings.smart_home_secret_key)
        if data.token
        else existing.encrypted_token
    )
    return await repository.save_config(
        db,
        base_url=str(data.base_url).rstrip("/"),
        encrypted_token=encrypted_token,
        enabled=data.enabled,
    )


async def test_config(db: AsyncSession, *, base_url: str | None, token: str | None) -> SmartHomeConfigTestResponse:
    if base_url and token:
        client = HomeAssistantClient(base_url=base_url, token=token)
    else:
        config = await get_config(db)
        client = _client(config)
    try:
        version = await client.ping()
    except HomeAssistantError as exc:
        return SmartHomeConfigTestResponse(ok=False, message=str(exc))
    finally:
        await client.aclose()
    return SmartHomeConfigTestResponse(ok=True, message="Home Assistant connection succeeded", home_assistant_version=version)


async def list_entities(db: AsyncSession) -> SmartHomeEntityListResponse:
    config = await get_config(db)
    if not config.enabled:
        return SmartHomeEntityListResponse(items=[], total=0, connected=False, last_error="Smart home integration is disabled")
    cached = _get_cached_entity_response(config)
    if cached is not None:
        return cached

    async with _entity_snapshot_lock:
        cached = _get_cached_entity_response(config)
        if cached is not None:
            return cached

        client = _client(config)
        try:
            states = await client.get_states()
            items = [entity for raw in states if (entity := normalize_entity(raw)) is not None]
            response = SmartHomeEntityListResponse(items=items, total=len(items), connected=True)
            _store_cached_entity_response(config, response)
            await repository.update_status(db, config=config, status="ok", error=None)
            return response
        except HomeAssistantError as exc:
            await repository.update_status(db, config=config, status="error", error=str(exc))
            return SmartHomeEntityListResponse(items=[], total=0, connected=False, last_error=str(exc))
        finally:
            await client.aclose()


async def get_summary(db: AsyncSession) -> SmartHomeSummaryResponse:
    config = await repository.get_config(db)
    configured = bool(config and config.enabled and config.encrypted_token)
    if not configured or config is None:
        return SmartHomeSummaryResponse(
            configured=False,
            connected=False,
            active_count=0,
            unavailable_count=0,
        )

    cached = _get_cached_entity_response(config)
    if cached is not None:
        active_count = sum(1 for entity in cached.items if entity.available)
        unavailable_count = len(cached.items) - active_count
        return SmartHomeSummaryResponse(
            configured=True,
            connected=bool(cached.connected),
            active_count=active_count,
            unavailable_count=unavailable_count,
        )

    return SmartHomeSummaryResponse(
        configured=True,
        connected=config.last_status in {"ok", "connected"},
        active_count=0,
        unavailable_count=0,
    )


async def call_entity_service(db: AsyncSession, *, entity_id: str, service: str, service_data: dict[str, Any]) -> None:
    domain = entity_id.split(".", 1)[0] if "." in entity_id else ""
    if domain not in SUPPORTED_DOMAINS:
        raise SmartHomeUnsupportedEntityError
    if service not in ALLOWED_SERVICES[domain]:
        raise SmartHomeUnsupportedServiceError
    config = await get_config(db)
    client = _client(config)
    try:
        payload = {**service_data, "entity_id": entity_id}
        await client.call_service(domain, service, payload)
    finally:
        await client.aclose()
