"""Unified event-center API with paginated query and SSE streaming."""
from __future__ import annotations

import asyncio
from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.event_stream import event_stream_broker
from app.core.json_utils import json_default, safe_json_dumps
from app.core.security import get_current_user
from app.core.system_log import can_view_event
from app.database import get_db
from app.domains.events import service as event_service
from app.models.user import User
from app.schemas.events import EventCenterListResponse

router = APIRouter(prefix="/events", tags=["events"])


def _item_matches_filters(
    item: dict[str, Any],
    *,
    kind: str,
    event_type: str | None,
    category: str | None,
    severity: str | None,
    source: str | None,
    keyword: str | None,
    start_at: datetime | None,
    end_at: datetime | None,
) -> bool:
    item_kind = item.get("kind")
    if kind != "all" and item_kind != kind:
        return False
    if event_type and item.get("event_type") != event_type:
        return False
    if category and item.get("category") != category:
        return False
    if severity and item.get("severity") != severity:
        return False
    if source and item.get("source") != source:
        return False
    if start_at and item.get("occurred_at") and item["occurred_at"] < start_at:
        return False
    if end_at and item.get("occurred_at") and item["occurred_at"] > end_at:
        return False
    if keyword:
        haystack = " ".join(
            str(item.get(field, "") or "")
            for field in ("message", "event_type", "category", "source")
        ).lower()
        if keyword.lower() not in haystack:
            return False
    return True


@router.get("", response_model=EventCenterListResponse)
async def list_events(
    kind: str = Query("all", pattern="^(all|audit|system|platform)$"),
    event_type: str | None = Query(None),
    category: str | None = Query(None),
    severity: str | None = Query(None),
    source: str | None = Query(None),
    keyword: str | None = Query(None),
    start_at: datetime | None = Query(None),
    end_at: datetime | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return a unified paginated event-center list."""
    items, total = await event_service.list_events(
        db,
        current_user=current_user,
        kind=kind,
        event_type=event_type,
        category=category,
        severity=severity,
        source=source,
        keyword=keyword,
        start_at=start_at,
        end_at=end_at,
        page=page,
        page_size=page_size,
    )

    return EventCenterListResponse(items=items, total=total, page=page, page_size=page_size)


@router.get(
    "/stream",
    response_class=StreamingResponse,
    responses={
        200: {
            "description": "Server-sent event stream",
            "content": {"text/event-stream": {"schema": {"type": "string"}}},
        }
    },
)
async def stream_events(
    request: Request,
    current_user: User = Depends(get_current_user),
    kind: str = Query("all", pattern="^(all|audit|system|platform)$"),
    event_type: str | None = Query(None),
    category: str | None = Query(None),
    severity: str | None = Query(None),
    source: str | None = Query(None),
    keyword: str | None = Query(None),
    start_at: datetime | None = Query(None),
    end_at: datetime | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    """Stream event-center updates over SSE."""
    queue = await event_stream_broker.subscribe()

    async def event_generator():
        try:
            yield ": connected\n\n"
            while True:
                if await request.is_disconnected():
                    break
                try:
                    item = await asyncio.wait_for(queue.get(), timeout=15)
                except TimeoutError:
                    yield ": keep-alive\n\n"
                    continue

                if not can_view_event(
                    current_user=current_user,
                    kind=item.get("kind", "system"),
                    event_user_id=item.get("user_id"),
                    category=item.get("category"),
                ):
                    continue
                if not _item_matches_filters(
                    item,
                    kind=kind,
                    event_type=event_type,
                    category=category,
                    severity=severity,
                    source=source,
                    keyword=keyword,
                    start_at=start_at,
                    end_at=end_at,
                ):
                    continue
                payload = safe_json_dumps(item, default=json_default)
                yield f"data: {payload}\n\n"
        finally:
            await event_stream_broker.unsubscribe(queue)

    return StreamingResponse(event_generator(), media_type="text/event-stream")
