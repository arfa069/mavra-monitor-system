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
