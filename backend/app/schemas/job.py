"""Pydantic schemas for job-related API endpoints."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator

from app.schemas.base import BaseResponseSchema
from app.schemas.crawl_profile import validate_profile_key_value
from app.schemas.validators import validate_cron_value, validate_timezone_value

JobPlatform = Literal["boss", "51job", "liepin"]


class _JobSearchConfigFields(BaseModel):
    """Shared fields for job search config create/update schemas."""

    name: str | None = None
    profile_key: str | None = None
    platform: JobPlatform | None = None
    keyword: str | None = None
    city_code: str | None = None
    salary_min: int | None = None
    salary_max: int | None = None
    experience: str | None = None
    education: str | None = None
    url: str | None = None
    active: bool | None = None
    notify_on_new: bool | None = None
    deactivation_threshold: int | None = None
    cron_expression: str | None = None
    cron_timezone: str | None = None
    enable_match_analysis: bool | None = None

    @field_validator("profile_key")
    @classmethod
    def validate_profile_key(cls, v: str | None) -> str | None:
        if v is None:
            return None
        return validate_profile_key_value(v)

    @field_validator("cron_expression")
    @classmethod
    def validate_cron(cls, v: str | None) -> str | None:
        return validate_cron_value(v)

    @field_validator("cron_timezone")
    @classmethod
    def validate_timezone(cls, v: str | None) -> str | None:
        return validate_timezone_value(v)


class JobSearchConfigCreate(_JobSearchConfigFields):
    """Schema for creating a job search config."""

    name: str = Field(..., max_length=100)
    profile_key: str = Field(default="default", max_length=80)
    platform: JobPlatform = "boss"
    url: str
    active: bool = True
    notify_on_new: bool = True
    deactivation_threshold: int = Field(default=3, ge=1)
    enable_match_analysis: bool = False


class JobSearchConfigUpdate(_JobSearchConfigFields):
    """Schema for updating a job search config."""


class JobSearchConfigResponse(BaseResponseSchema):
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


class JobConfigCronUpdate(BaseModel):
    """Schema for updating only the cron settings of a job search config."""

    cron_expression: str | None = Field(default=None, max_length=100)
    cron_timezone: str | None = Field(default=None, max_length=50)

    @field_validator("cron_expression")
    @classmethod
    def validate_cron(cls, v: str | None) -> str | None:
        return validate_cron_value(v)

    @field_validator("cron_timezone")
    @classmethod
    def validate_timezone(cls, v: str | None) -> str | None:
        return validate_timezone_value(v)


class JobResponse(BaseResponseSchema):
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
    apply_recommendation: str | None = None


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
