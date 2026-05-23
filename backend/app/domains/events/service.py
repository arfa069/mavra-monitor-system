"""Event-center business services."""

from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.domains.events import repository
from app.models.user import User
from app.schemas.events import EventCenterItem


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
    return await repository.list_events(
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
