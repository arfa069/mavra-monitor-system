"""Alert domain business services."""

from sqlalchemy.ext.asyncio import AsyncSession

from app.domains.alerts import repository
from app.models.alert import Alert
from app.schemas.alert import AlertCreate, AlertUpdate


class ProductNotFoundError(LookupError):
    """Raised when an alert target product is not owned by the current user."""


class AlertNotFoundError(LookupError):
    """Raised when an alert cannot be found for the current user."""


async def create_alert(
    db: AsyncSession, *, user_id: int, data: AlertCreate
) -> Alert:
    product = await repository.get_user_product(
        db, user_id=user_id, product_id=data.product_id
    )
    if product is None:
        raise ProductNotFoundError

    return await repository.create_alert(
        db,
        product_id=data.product_id,
        threshold_percent=data.threshold_percent,
        active=data.active,
    )


async def list_alerts(
    db: AsyncSession,
    *,
    user_id: int,
    product_id: int | None,
    active: bool | None,
) -> list[Alert]:
    return await repository.list_alerts(
        db, user_id=user_id, product_id=product_id, active=active
    )


async def get_alert(db: AsyncSession, *, user_id: int, alert_id: int) -> Alert:
    alert = await repository.get_alert(db, user_id=user_id, alert_id=alert_id)
    if alert is None:
        raise AlertNotFoundError
    return alert


async def update_alert(
    db: AsyncSession, *, user_id: int, alert_id: int, data: AlertUpdate
) -> Alert:
    alert = await get_alert(db, user_id=user_id, alert_id=alert_id)
    return await repository.update_alert(
        db, alert=alert, data=data.model_dump(exclude_unset=True)
    )


async def delete_alert(db: AsyncSession, *, user_id: int, alert_id: int) -> None:
    alert = await get_alert(db, user_id=user_id, alert_id=alert_id)
    await repository.delete_alert(db, alert=alert)
