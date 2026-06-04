"""Smart home configuration models."""
from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB

from app.models.base import Base, TimestampMixin


class SmartHomeConfig(Base, TimestampMixin):
    """Home Assistant connection configuration."""

    __tablename__ = "smart_home_configs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    base_url = Column(String(500), nullable=False)
    encrypted_token = Column(Text, nullable=False)
    enabled = Column(Boolean, nullable=False, default=True)
    last_status = Column(String(50), nullable=True)
    last_error = Column(Text, nullable=True)


class SmartHomeEntityPreference(Base, TimestampMixin):
    """Local display preferences for Home Assistant entities."""

    __tablename__ = "smart_home_entity_preferences"
    __table_args__ = (
        UniqueConstraint("user_id", "entity_id", name="uq_smart_home_entity_pref_user_entity"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    entity_id = Column(String(255), nullable=False, index=True)
    alias = Column(String(255), nullable=True)
    hidden = Column(Boolean, nullable=False, default=False)
    sort_order = Column(Integer, nullable=False, default=0)
    area = Column(String(255), nullable=True)
    metadata_json = Column(JSONB, nullable=False, default=dict)
