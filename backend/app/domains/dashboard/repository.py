"""Dashboard domain data access helpers."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.alert import Alert
from app.models.user import User


async def get_active_user(db: AsyncSession, *, user_id: int) -> User | None:
    result = await db.execute(
        select(User).where(User.id == user_id, User.deleted_at.is_(None))
    )
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        return None
    return user


async def list_recent_alerts(db: AsyncSession, *, limit: int) -> list[Alert]:
    result = await db.execute(
        select(Alert).order_by(Alert.created_at.desc()).limit(limit)
    )
    return list(result.scalars().all())
