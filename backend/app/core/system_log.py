"""System event-center helpers: visibility, normalization, and best-effort writes."""
from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.event_stream import event_stream_broker
from app.database import AsyncSessionLocal
from app.models.audit_log import UserAuditLog
from app.models.system_log import SystemLog
from app.models.user import User

logger = logging.getLogger(__name__)


def can_view_event(
    current_user: User,
    kind: str,
    event_user_id: int | None,
    category: str | None = None,
) -> bool:
    """Return whether the current user can view the given event."""
    effective_kind = "platform" if kind == "platform" or category == "platform" else kind
    if current_user.is_admin:
        return True
    if effective_kind == "platform":
        return False
    return event_user_id == current_user.id


def audit_action_category(action: str) -> str:
    """Map audit action names to event categories."""
    if "." in action:
        return action.split(".", 1)[0]
    return "audit"


def audit_action_severity(action: str) -> str:
    """Map audit action names to a coarse severity label."""
    if action.endswith(".delete"):
        return "warning"
    return "info"


def normalize_audit_log(log: UserAuditLog) -> dict[str, Any]:
    """Convert an audit-log row into unified event-center shape."""
    return {
        "id": f"audit:{log.id}",
        "kind": "audit",
        "event_type": log.action,
        "category": audit_action_category(log.action),
        "severity": audit_action_severity(log.action),
        "message": log.action,
        "occurred_at": log.created_at,
        "source": "audit",
        "status": "success",
        "user_id": log.actor_user_id,
        "entity_type": log.target_type,
        "entity_id": str(log.target_id) if log.target_id is not None else None,
        "trace_id": None,
        "payload": log.details,
    }


def normalize_system_log(log: SystemLog) -> dict[str, Any]:
    """Convert a system-log row into unified event-center shape."""
    return {
        "id": f"system:{log.id}",
        "kind": "platform" if log.category == "platform" else "system",
        "event_type": log.event_type,
        "category": log.category,
        "severity": log.severity,
        "message": log.message,
        "occurred_at": log.occurred_at,
        "source": log.source,
        "status": log.status,
        "user_id": log.user_id,
        "entity_type": log.entity_type,
        "entity_id": log.entity_id,
        "trace_id": log.trace_id,
        "payload": log.payload_json,
    }


async def emit_system_log(
    db: AsyncSession,
    *,
    category: str,
    event_type: str,
    source: str,
    message: str,
    severity: str = "info",
    status: str | None = None,
    user_id: int | None = None,
    entity_type: str | None = None,
    entity_id: str | int | None = None,
    trace_id: str | None = None,
    payload: dict[str, Any] | None = None,
    occurred_at: datetime | None = None,
    commit: bool = False,
) -> SystemLog | None:
    """Write a structured system log entry using best-effort semantics."""
    try:
        log_entry = SystemLog(
            occurred_at=occurred_at or datetime.now(UTC),
            category=category,
            event_type=event_type,
            severity=severity,
            source=source,
            status=status,
            message=message,
            user_id=user_id,
            entity_type=entity_type,
            entity_id=str(entity_id) if entity_id is not None else None,
            trace_id=trace_id,
            payload_json=payload,
        )
        db.add(log_entry)
        if commit:
            await db.commit()
            await event_stream_broker.publish(normalize_system_log(log_entry))
        return log_entry
    except Exception:
        logger.warning(
            "Failed to write system log",
            extra={
                "system_log_category": category,
                "system_log_event_type": event_type,
                "system_log_source": source,
            },
            exc_info=True,
        )
        if commit:
            try:
                await db.rollback()
            except Exception:
                logger.debug("Rollback after system-log failure also failed", exc_info=True)
        return None


async def emit_system_log_detached(
    *,
    category: str,
    event_type: str,
    source: str,
    message: str,
    severity: str = "info",
    status: str | None = None,
    user_id: int | None = None,
    entity_type: str | None = None,
    entity_id: str | int | None = None,
    trace_id: str | None = None,
    payload: dict[str, Any] | None = None,
    occurred_at: datetime | None = None,
) -> SystemLog | None:
    """Write a system log in its own transaction so business flow stays isolated."""
    async with AsyncSessionLocal() as db:
        return await emit_system_log(
            db=db,
            category=category,
            event_type=event_type,
            source=source,
            message=message,
            severity=severity,
            status=status,
            user_id=user_id,
            entity_type=entity_type,
            entity_id=entity_id,
            trace_id=trace_id,
            payload=payload,
            occurred_at=occurred_at,
            commit=True,
        )
