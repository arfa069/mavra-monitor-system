"""Structured system log model for runtime and platform events."""
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func

from app.models.base import Base, TimestampMixin


class SystemLog(Base, TimestampMixin):
    """Structured event log for runtime and platform events."""

    __tablename__ = "system_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    occurred_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )
    category = Column(String(50), nullable=False, index=True)
    event_type = Column(String(100), nullable=False, index=True)
    severity = Column(String(20), nullable=False, default="info", index=True)
    source = Column(String(100), nullable=False, index=True)
    status = Column(String(30), nullable=True, index=True)
    message = Column(Text, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    entity_type = Column(String(50), nullable=True)
    entity_id = Column(String(255), nullable=True)
    trace_id = Column(String(100), nullable=True, index=True)
    payload_json = Column(JSONB, nullable=True)
