"""Scheduler status response schemas."""

from pydantic import BaseModel, Field


class ScheduleInfo(BaseModel):
    cron_expression: str | None = None
    next_run_at: str | None = None


class JobConfigScheduleInfo(ScheduleInfo):
    config_id: int


class ProductCronSchedulesResponse(BaseModel):
    platforms: dict[str, ScheduleInfo] = Field(default_factory=dict)


class JobConfigSchedulesResponse(BaseModel):
    configs: list[JobConfigScheduleInfo] = Field(default_factory=list)


class SchedulerJobsResponse(BaseModel):
    product_platforms: dict[str, ScheduleInfo] = Field(default_factory=dict)
    job_configs: dict[str, ScheduleInfo] = Field(default_factory=dict)


class SchedulerStatusResponse(BaseModel):
    scheduler: str
    timezone: str | None = None
    jobs: SchedulerJobsResponse | None = None
