"""Dashboard domain data access helpers."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import contains_eager

from app.models.alert import Alert
from app.models.product import Product
from app.models.user import User


async def get_active_user(db: AsyncSession, *, user_id: int) -> User | None:
    result = await db.execute(
        select(User).where(User.id == user_id, User.deleted_at.is_(None))
    )
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        return None
    return user


async def list_recent_alerts(
    db: AsyncSession,
    *,
    limit: int,
    include_product_context: bool = False,
) -> list[Alert]:
    query = select(Alert).order_by(Alert.created_at.desc()).limit(limit)

    if include_product_context:
        query = (
            select(Alert)
            .outerjoin(Product, Alert.product_id == Product.id)
            .options(contains_eager(Alert.product))
            .order_by(Alert.created_at.desc())
            .limit(limit)
        )

    result = await db.execute(query)
    return list(result.scalars().all())
