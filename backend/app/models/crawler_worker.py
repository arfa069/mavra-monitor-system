"""Crawler worker registry model."""

from sqlalchemy import Column, DateTime, Index, Integer, String

from app.models.base import Base


class CrawlerWorkerRecord(Base):
    """Durable heartbeat and capability metadata for crawler worker processes."""

    __tablename__ = "crawler_workers"
    __table_args__ = (
        Index("ix_crawler_workers_status_heartbeat", "status", "last_heartbeat_at"),
        Index("ix_crawler_workers_kind_platform_status", "kind", "platform", "status"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    worker_id = Column(String(120), unique=True, index=True, nullable=False)
    kind = Column(String(20), nullable=False)
    platform = Column(String(40), nullable=True)
    hostname = Column(String(120), nullable=False)
    pid = Column(Integer, nullable=False)
    status = Column(String(20), nullable=False, default="online")
    started_at = Column(DateTime(timezone=True), nullable=False)
    last_heartbeat_at = Column(DateTime(timezone=True), nullable=False)
    stopped_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
