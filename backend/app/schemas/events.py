"""Event-center schemas."""
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel


class EventCenterItem(BaseModel):
    """Unified event-center row."""

    id: str
    kind: Literal["audit", "system", "platform"]
    event_type: str
    category: str
    severity: str
    message: str
    occurred_at: datetime
    source: str
    status: str | None
    user_id: int | None
    entity_type: str | None
    entity_id: str | None
    trace_id: str | None
    payload: dict[str, Any] | None


class EventCenterListResponse(BaseModel):
    """Paginated event-center response."""

    items: list[EventCenterItem]
    total: int
    page: int
    page_size: int
