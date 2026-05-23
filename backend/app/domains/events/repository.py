"""Event-center data access helpers."""

from datetime import datetime

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

from app.models.audit_log import UserAuditLog
from app.models.system_log import SystemLog
from app.models.user import User
from app.schemas.events import EventCenterItem


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


async def list_events(
    db: AsyncSession,
    *,
    current_user: User,
    kind: str,
    event_type: str | None,
    category: str | None,
    severity: str | None,
    source: str | None,
    keyword: str | None,
    start_at: datetime | None,
    end_at: datetime | None,
    page: int,
    page_size: int,
) -> tuple[list[EventCenterItem], int]:
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
    return items, total


async def get_active_user(db: AsyncSession, *, user_id: int) -> User | None:
    result = await db.execute(
        select(User).where(
            User.id == user_id,
            User.deleted_at.is_(None),
        )
    )
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        return None
    return user
