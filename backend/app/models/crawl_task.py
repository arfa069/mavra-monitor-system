"""Persistent crawler task model."""

from sqlalchemy import Column, DateTime, ForeignKey, Index, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB

from app.models.base import Base


class CrawlTaskRecord(Base):
    """Durable task state for product and job crawls."""

    __tablename__ = "crawl_tasks"
    __table_args__ = (
        Index("ix_crawl_tasks_status_lease_until", "status", "lease_until"),
        Index("ix_crawl_tasks_parent_status", "parent_task_id", "status"),
        Index("ix_crawl_tasks_user_created", "user_id", "created_at"),
        Index("ix_crawl_tasks_entity", "entity_type", "entity_id"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    task_id = Column(String(64), unique=True, index=True, nullable=False)
    parent_task_id = Column(String(64), nullable=True, index=True)
    task_type = Column(String(40), nullable=False)
    platform = Column(String(40), nullable=True)
    profile_key = Column(String(80), nullable=True)
    source = Column(String(20), nullable=False)
    status = Column(String(20), nullable=False)

    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    entity_type = Column(String(50), nullable=True)
    entity_id = Column(String(100), nullable=True)

    total = Column(Integer, nullable=False, default=0)
    success = Column(Integer, nullable=False, default=0)
    errors = Column(Integer, nullable=False, default=0)
    reason = Column(Text, nullable=True)
    details_json = Column(JSONB, nullable=True)
    payload_json = Column(JSONB, nullable=True)

    locked_by = Column(String(120), nullable=True)
    lease_until = Column(DateTime(timezone=True), nullable=True)
    heartbeat_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
    started_at = Column(DateTime(timezone=True), nullable=True)
    finished_at = Column(DateTime(timezone=True), nullable=True)
