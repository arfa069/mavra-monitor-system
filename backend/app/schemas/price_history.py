"""Price history schemas."""
from datetime import datetime
from decimal import Decimal

from app.schemas.base import BaseResponseSchema


class PriceHistoryResponse(BaseResponseSchema):
    """Schema for price history record."""
    id: int
    product_id: int
    price: Decimal
    currency: str
    scraped_at: datetime


class PriceHistorySummary(BaseResponseSchema):
    """Summary of price history for a product."""
    id: int
    price: Decimal
    currency: str
    scraped_at: datetime
