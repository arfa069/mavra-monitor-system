"""Alert domain data access helpers."""

from inspect import isawaitable

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.alert import Alert
from app.models.product import Product


async def get_user_product(
    db: AsyncSession, *, user_id: int, product_id: int
) -> Product | None:
    result = await db.execute(
        select(Product).where(Product.id == product_id, Product.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def create_alert(
    db: AsyncSession,
    *,
    product_id: int,
    threshold_percent,
    active: bool,
) -> Alert:
    alert = Alert(
        product_id=product_id,
        alert_type="price_drop",
        threshold_percent=threshold_percent,
        active=active,
    )
    added = db.add(alert)
    if isawaitable(added):
        await added
    await db.commit()
    await db.refresh(alert)
    return alert


async def list_alerts(
    db: AsyncSession,
    *,
    user_id: int,
    product_id: int | None,
    active: bool | None,
) -> list[Alert]:
    query = select(Alert).join(Product).where(Product.user_id == user_id)

    if product_id is not None:
        query = query.where(Alert.product_id == product_id)
    if active is not None:
        query = query.where(Alert.active == active)

    result = await db.execute(query.order_by(desc(Alert.created_at)))
    return list(result.scalars().all())


async def get_alert(db: AsyncSession, *, user_id: int, alert_id: int) -> Alert | None:
    result = await db.execute(
        select(Alert)
        .join(Product)
        .where(Alert.id == alert_id, Product.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def update_alert(db: AsyncSession, *, alert: Alert, data: dict) -> Alert:
    for field, value in data.items():
        setattr(alert, field, value)
    await db.commit()
    await db.refresh(alert)
    return alert


async def delete_alert(db: AsyncSession, *, alert: Alert) -> None:
    await db.delete(alert)
    await db.commit()
