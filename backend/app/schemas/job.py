"""Pydantic schemas for job-related API endpoints."""

import zoneinfo
from datetime import datetime
from typing import Literal

from apscheduler.triggers.cron import CronTrigger
from pydantic import BaseModel, Field, field_validator

from app.core.crawler_paths import build_profile_dir

JobPlatform = Literal["boss", "51job", "liepin"]


def _validate_profile_key_value(value: str | None) -> str:
    key = (value or "default").strip()
    build_profile_dir(key)
    return key


class JobSearchConfigCreate(BaseModel):
    """Schema for creating a job search config."""

    name: str = Field(..., max_length=100)
    profile_key: str = Field(default="default", max_length=80)
    platform: JobPlatform = "boss"

    @field_validator("profile_key")
    @classmethod
    def validate_profile_key(cls, v: str | None) -> str:
        return _validate_profile_key_value(v)
    keyword: str | None = Field(default=None, max_length=200)
    city_code: str | None = Field(default=None, max_length=20)
    salary_min: int | None = Field(default=None, ge=0)
    salary_max: int | None = Field(default=None, ge=0)
    experience: str | None = Field(default=None, max_length=50)
    education: str | None = Field(default=None, max_length=50)
    url: str
    active: bool = True
    notify_on_new: bool = True
    deactivation_threshold: int = Field(default=3, ge=1)
    cron_expression: str | None = Field(default=None, max_length=100)
    cron_timezone: str | None = Field(default=None, max_length=50)
    enable_match_analysis: bool = False

    @field_validator("cron_expression")
    @classmethod
    def validate_cron(cls, v: str | None) -> str | None:
        if v is None:
            return v
        val = v.strip()
        if not val:
            return None
        try:
            CronTrigger.from_crontab(val)
        except Exception as exc:
            raise ValueError(f"Invalid cron expression: {exc}")
        return val

    @field_validator("cron_timezone")
    @classmethod
    def validate_timezone(cls, v: str | None) -> str | None:
        if not v:
            return v
        val = v.strip()
        if not val:
            return None
        try:
            zoneinfo.ZoneInfo(val)
        except Exception:
            raise ValueError(f"Invalid timezone: {v}")
        return val


class JobSearchConfigUpdate(BaseModel):
    """Schema for updating a job search config."""

    name: str | None = Field(default=None, max_length=100)
    profile_key: str | None = Field(default=None, max_length=80)
    platform: JobPlatform | None = None

    @field_validator("profile_key")
    @classmethod
    def validate_profile_key(cls, v: str | None) -> str | None:
        if v is None:
            return None
        return _validate_profile_key_value(v)
    keyword: str | None = Field(default=None, max_length=200)
    city_code: str | None = Field(default=None, max_length=20)
    salary_min: int | None = Field(default=None, ge=0)
    salary_max: int | None = Field(default=None, ge=0)
    experience: str | None = Field(default=None, max_length=50)
    education: str | None = Field(default=None, max_length=50)
    url: str | None = None
    active: bool | None = None
    notify_on_new: bool | None = None
    deactivation_threshold: int | None = Field(default=None, ge=1)
    cron_expression: str | None = Field(default=None, max_length=100)
    cron_timezone: str | None = Field(default=None, max_length=50)
    enable_match_analysis: bool | None = None

    @field_validator("cron_expression")
    @classmethod
    def validate_cron(cls, v: str | None) -> str | None:
        if v is None:
            return v
        val = v.strip()
        if not val:
            return None
        try:
            CronTrigger.from_crontab(val)
        except Exception as exc:
            raise ValueError(f"Invalid cron expression: {exc}")
        return val

    @field_validator("cron_timezone")
    @classmethod
    def validate_timezone(cls, v: str | None) -> str | None:
        if not v:
            return v
        val = v.strip()
        if not val:
            return None
        try:
            zoneinfo.ZoneInfo(val)
        except Exception:
            raise ValueError(f"Invalid timezone: {v}")
        return val


class JobSearchConfigResponse(BaseModel):
    """Schema for job search config response."""

    id: int
    user_id: int
    name: str
    profile_key: str
    platform: JobPlatform = "boss"
    keyword: str | None
    city_code: str | None
    salary_min: int | None
    salary_max: int | None
    experience: str | None
    education: str | None
    url: str
    active: bool
    notify_on_new: bool
    deactivation_threshold: int
    cron_expression: str | None
    cron_timezone: str | None
    enable_match_analysis: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class JobConfigCronUpdate(BaseModel):
    """Schema for updating only the cron settings of a job search config."""

    cron_expression: str | None = Field(default=None, max_length=100)
    cron_timezone: str | None = Field(default=None, max_length=50)


class JobResponse(BaseModel):
    """Schema for job response."""

    id: int
    job_id: str
    search_config_id: int
    platform: JobPlatform
    title: str | None
    company: str | None
    company_id: str | None
    salary: str | None
    salary_min: int | None
    salary_max: int | None
    location: str | None
    experience: str | None
    education: str | None
    description: str | None
    address: str | None
    url: str | None
    first_seen_at: datetime
    last_updated_at: datetime
    is_active: bool

    model_config = {"from_attributes": True}


class JobCrawlResult(BaseModel):
    """Schema for job crawl result."""

    new_count: int
    updated_count: int
    deactivated_count: int = 0


class JobListResponse(BaseModel):
    """Paginated job list response."""

    items: list[JobResponse]
    total: int
    page: int
    page_size: int
