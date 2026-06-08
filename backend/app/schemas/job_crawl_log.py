"""Job crawl log schemas."""
from datetime import datetime

from app.schemas.base import BaseResponseSchema


class JobCrawlLogResponse(BaseResponseSchema):
    """Schema for job crawl log record."""
    id: int
    search_config_id: int
    status: str
    new_jobs_count: int | None = None
    total_jobs_count: int | None = None
    error_message: str | None = None
    scraped_at: datetime
