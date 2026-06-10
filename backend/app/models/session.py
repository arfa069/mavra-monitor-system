"""Session model for device tracking."""
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String

from app.models.base import Base, TimestampMixin
from app.utils.time import now_utc


class Session(Base, TimestampMixin):
    """Session model for tracking user login devices."""
    __tablename__ = "users_sessions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    token_hash = Column(String(64), unique=True, nullable=True, index=True)
    refresh_token_hash = Column(String(64), unique=True, nullable=True)
    refresh_expires_at = Column(DateTime(timezone=True), nullable=False, default=now_utc)
    device = Column(String(255))
    ip_address = Column(String(45))
    last_active_at = Column(DateTime(timezone=True), nullable=False, default=now_utc)
