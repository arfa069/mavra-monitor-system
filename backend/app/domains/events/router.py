"""Unified event-center API with paginated query and SSE streaming."""
from __future__ import annotations

import asyncio
import json
from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from fastapi.responses import StreamingResponse
from sqlalchemy import (
    String,
    and_,
    case,
    cast,
    false,
    func,
    literal,
    or_,
    select,
    union_all,
)
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.event_stream import event_stream_broker
from app.core.security import decode_access_token, get_current_user
from app.core.system_log import can_view_event
from app.database import get_db
from app.models.audit_log import UserAuditLog
from app.models.system_log import SystemLog
from app.models.user import User
from app.schemas.events import EventCenterItem, EventCenterListResponse

router = APIRouter(prefix="/events", tags=["events"])


def _audit_category_expr():
    return case(
        (UserAuditLog.action.like("auth.%"), literal("auth")),
        (UserAuditLog.action.like("user.%"), literal("user")),
        (UserAuditLog.action.like("product.%"), literal("product")),
        (UserAuditLog.action.like("schedule.%"), literal("schedule")),
        (UserAuditLog.action.like("job_config.%"), literal("job_config")),
        (UserAuditLog.action.like("permission.%"), literal("permission")),
        else_=literal("audit"),
    )


def _audit_severity_expr():
    return case(
        (UserAuditLog.action.like("%.delete"), literal("warning")),
        else_=literal("info"),
    )


def _build_event_union(
    current_user: User,
    *,
    kind: str,
    event_type: str | None,
    category: str | None,
    severity: str | None,
    source: str | None,
    keyword: str | None,
    start_at: datetime | None,
    end_at: datetime | None,
):
    audit_filter = literal(True)
    system_filter = literal(True)

    if not current_user.is_admin:
        audit_filter = and_(audit_filter, UserAuditLog.actor_user_id == current_user.id)
        system_filter = and_(
            system_filter,
            SystemLog.user_id == current_user.id,
            SystemLog.category != "platform",
        )

    if kind == "audit":
        system_filter = and_(system_filter, false())
    elif kind == "system":
        audit_filter = and_(audit_filter, false())
        system_filter = and_(system_filter, SystemLog.category != "platform")
    elif kind == "platform":
        audit_filter = and_(audit_filter, false())
        if current_user.is_admin:
            system_filter = and_(system_filter, SystemLog.category == "platform")
        else:
            system_filter = and_(system_filter, false())

    if start_at is not None:
        audit_filter = and_(audit_filter, UserAuditLog.created_at >= start_at)
        system_filter = and_(system_filter, SystemLog.occurred_at >= start_at)
    if end_at is not None:
        audit_filter = and_(audit_filter, UserAuditLog.created_at <= end_at)
        system_filter = and_(system_filter, SystemLog.occurred_at <= end_at)

    audit_select = select(
        (literal("audit:") + cast(UserAuditLog.id, String)).label("id"),
        literal("audit").label("kind"),
        UserAuditLog.action.label("event_type"),
        _audit_category_expr().label("category"),
        _audit_severity_expr().label("severity"),
        UserAuditLog.action.label("message"),
        UserAuditLog.created_at.label("occurred_at"),
        literal("audit").label("source"),
        literal("success").label("status"),
        UserAuditLog.actor_user_id.label("user_id"),
        UserAuditLog.target_type.label("entity_type"),
        cast(UserAuditLog.target_id, String).label("entity_id"),
        cast(literal(None), String).label("trace_id"),
        UserAuditLog.details.label("payload"),
    ).where(audit_filter)

    system_kind_expr = case(
        (SystemLog.category == "platform", literal("platform")),
        else_=literal("system"),
    )

    system_select = select(
        (literal("system:") + cast(SystemLog.id, String)).label("id"),
        system_kind_expr.label("kind"),
        SystemLog.event_type.label("event_type"),
        SystemLog.category.label("category"),
        SystemLog.severity.label("severity"),
        SystemLog.message.label("message"),
        SystemLog.occurred_at.label("occurred_at"),
        SystemLog.source.label("source"),
        SystemLog.status.label("status"),
        SystemLog.user_id.label("user_id"),
        SystemLog.entity_type.label("entity_type"),
        SystemLog.entity_id.label("entity_id"),
        SystemLog.trace_id.label("trace_id"),
        SystemLog.payload_json.label("payload"),
    ).where(system_filter)

    event_union = union_all(audit_select, system_select).subquery()

    outer_filter = literal(True)
    if event_type:
        outer_filter = and_(outer_filter, event_union.c.event_type == event_type)
    if category:
        outer_filter = and_(outer_filter, event_union.c.category == category)
    if severity:
        outer_filter = and_(outer_filter, event_union.c.severity == severity)
    if source:
        outer_filter = and_(outer_filter, event_union.c.source == source)
    if keyword:
        escaped = keyword.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        pattern = f"%{escaped}%"
        outer_filter = and_(
            outer_filter,
            or_(
                event_union.c.message.ilike(pattern, escape="\\"),
                event_union.c.event_type.ilike(pattern, escape="\\"),
                event_union.c.category.ilike(pattern, escape="\\"),
                event_union.c.source.ilike(pattern, escape="\\"),
            ),
        )

    return event_union, outer_filter


async def _get_stream_user(
    db: AsyncSession,
    token: str | None,
    authorization: str | None,
) -> User:
    raw_token = token
    if raw_token is None and authorization and authorization.lower().startswith("bearer "):
        raw_token = authorization[7:]
    if not raw_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：缺少 Token",
        )

    payload = decode_access_token(raw_token)
    if payload is None or payload.get("sub") is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：Token 无效或已过期",
        )

    result = await db.execute(
        select(User).where(
            User.id == int(payload["sub"]),
            User.deleted_at.is_(None),
        )
    )
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：Token 无效或已过期",
        )
    return user


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


def _json_default(value: Any) -> str:
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


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
    event_union, outer_filter = _build_event_union(
        current_user,
        kind=kind,
        event_type=event_type,
        category=category,
        severity=severity,
        source=source,
        keyword=keyword,
        start_at=start_at,
        end_at=end_at,
    )

    count_result = await db.execute(
        select(func.count()).select_from(event_union).where(outer_filter)
    )
    total = count_result.scalar_one_or_none() or 0

    rows_result = await db.execute(
        select(event_union)
        .where(outer_filter)
        .order_by(event_union.c.occurred_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    items = [EventCenterItem.model_validate(row) for row in rows_result.mappings().all()]

    return EventCenterListResponse(items=items, total=total, page=page, page_size=page_size)


@router.get("/stream")
async def stream_events(
    request: Request,
    token: str | None = Query(None),
    authorization: str | None = Header(None, alias="Authorization"),
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
    current_user = await _get_stream_user(db, token, authorization)
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
                payload = json.dumps(item, ensure_ascii=False, default=_json_default)
                yield f"data: {payload}\n\n"
        finally:
            await event_stream_broker.unsubscribe(queue)

    return StreamingResponse(event_generator(), media_type="text/event-stream")
