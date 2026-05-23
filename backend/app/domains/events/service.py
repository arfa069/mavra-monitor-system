"""Event-center business services."""

from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
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


async def get_stream_user(
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

    user = await repository.get_active_user(db, user_id=int(payload["sub"]))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证失败：Token 无效或已过期",
        )
    return user
