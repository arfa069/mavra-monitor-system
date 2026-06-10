"""Smart home API schemas."""
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, HttpUrl

SmartHomeDomain = Literal["light", "switch", "fan", "cover", "climate", "scene", "script"]


class SmartHomeConfigResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    base_url: str
    enabled: bool
    last_status: str | None = None
    last_error: str | None = None
    created_at: datetime
    updated_at: datetime
    token_configured: bool = True


class SmartHomeConfigUpdate(BaseModel):
    base_url: HttpUrl
    token: str | None = Field(default=None, min_length=1, max_length=4096)
    enabled: bool = True


class SmartHomeConfigTestRequest(BaseModel):
    base_url: HttpUrl | None = None
    token: str | None = Field(default=None, min_length=1, max_length=4096)


class SmartHomeConfigTestResponse(BaseModel):
    ok: bool
    message: str
    home_assistant_version: str | None = None


class SmartHomeEntity(BaseModel):
    entity_id: str
    domain: SmartHomeDomain
    name: str
    state: str
    area: str | None = None
    attributes: dict[str, Any] = Field(default_factory=dict)
    last_changed: datetime | None = None
    last_updated: datetime | None = None
    available: bool = True


class SmartHomeEntityListResponse(BaseModel):
    items: list[SmartHomeEntity]
    total: int
    connected: bool
    last_error: str | None = None


class SmartHomeSummaryResponse(BaseModel):
    configured: bool
    connected: bool
    active_count: int
    unavailable_count: int


class SmartHomeServiceRequest(BaseModel):
    service: str = Field(min_length=1, max_length=100)
    service_data: dict[str, Any] = Field(default_factory=dict)


class SmartHomeServiceResponse(BaseModel):
    ok: bool
    entity_id: str
    service: str
    message: str
