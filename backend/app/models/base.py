"""Base model with common fields."""
from sqlalchemy import Column, DateTime
from sqlalchemy.orm import declarative_base

from app.utils.time import now_utc

Base = declarative_base()


class TimestampMixin:
    """Mixin for created_at and updated_at timestamps."""
    created_at = Column(DateTime(timezone=True), nullable=False, default=now_utc)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=now_utc, onupdate=now_utc)
