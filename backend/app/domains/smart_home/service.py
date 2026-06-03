"""Smart home business logic."""
from __future__ import annotations

from datetime import datetime
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


class SmartHomeConfigMissingError(LookupError):
    pass


class SmartHomeUnsupportedEntityError(ValueError):
    pass


class SmartHomeUnsupportedServiceError(ValueError):
    pass


def _client(config: SmartHomeConfig) -> HomeAssistantClient:
    token = decrypt_token(config.encrypted_token, settings.smart_home_secret_key)
    return HomeAssistantClient(base_url=config.base_url, token=token)


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
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


async def get_config(db: AsyncSession) -> SmartHomeConfig:
    config = await repository.get_config(db)
    if config is None:
        raise SmartHomeConfigMissingError
    return config


async def save_config(db: AsyncSession, *, data: SmartHomeConfigUpdate) -> SmartHomeConfig:
    existing = await repository.get_config(db)
    if data.token is None and existing is None:
        raise SmartHomeConfigMissingError("Home Assistant token is required")
    encrypted_token = (
        encrypt_token(data.token, settings.smart_home_secret_key)
        if data.token is not None
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
    return SmartHomeConfigTestResponse(ok=True, message="Home Assistant connection succeeded", home_assistant_version=version)


async def list_entities(db: AsyncSession) -> SmartHomeEntityListResponse:
    config = await get_config(db)
    if not config.enabled:
        return SmartHomeEntityListResponse(items=[], total=0, connected=False, last_error="Smart home integration is disabled")
    try:
        states = await _client(config).get_states()
    except HomeAssistantError as exc:
        await repository.update_status(db, config=config, status="error", error=str(exc))
        return SmartHomeEntityListResponse(items=[], total=0, connected=False, last_error=str(exc))
    items = [entity for raw in states if (entity := normalize_entity(raw)) is not None]
    await repository.update_status(db, config=config, status="ok", error=None)
    return SmartHomeEntityListResponse(items=items, total=len(items), connected=True)


async def call_entity_service(db: AsyncSession, *, entity_id: str, service: str, service_data: dict[str, Any]) -> None:
    domain = entity_id.split(".", 1)[0] if "." in entity_id else ""
    if domain not in SUPPORTED_DOMAINS:
        raise SmartHomeUnsupportedEntityError
    if service not in ALLOWED_SERVICES[domain]:
        raise SmartHomeUnsupportedServiceError
    config = await get_config(db)
    payload = {"entity_id": entity_id, **service_data}
    await _client(config).call_service(domain, service, payload)
