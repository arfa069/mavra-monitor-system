"""Crawl log schemas."""
from datetime import datetime
from decimal import Decimal

from app.schemas.base import BaseResponseSchema


class CrawlLogResponse(BaseResponseSchema):
    """Schema for crawl log response."""
    id: int
    product_id: int | None
    platform: str | None
    status: str | None
    price: Decimal | None
    currency: str | None
    timestamp: datetime
    error_message: str | None
