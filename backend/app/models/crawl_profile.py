"""Crawler browser profile pool model."""

from sqlalchemy import Column, DateTime, Index, Integer, String, Text

from app.models.base import Base


class CrawlProfile(Base):
    """Durable browser profile metadata and lease state."""

    __tablename__ = "crawl_profiles"
    __table_args__ = (
        Index("ix_crawl_profiles_status_lease_until", "status", "lease_until"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    profile_key = Column(String(80), unique=True, index=True, nullable=False)
    profile_dir = Column(String(500), nullable=False)
    status = Column(String(30), nullable=False, default="available")
    platform_hint = Column(String(40), nullable=True)

    lease_owner = Column(String(120), nullable=True)
    lease_task_id = Column(String(64), nullable=True)
    lease_until = Column(DateTime(timezone=True), nullable=True)

    last_used_at = Column(DateTime(timezone=True), nullable=True)
    last_error = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
