"""Dashboard domain business services."""

from sqlalchemy.ext.asyncio import AsyncSession

from app.domains.dashboard import repository


async def list_recent_alerts(db: AsyncSession, *, limit: int) -> list[dict]:
    alerts = await repository.list_recent_alerts(db, limit=limit)
    return [
        {
            "id": alert.id,
            "product_id": alert.product_id,
            "alert_type": alert.alert_type,
            "message": (
                f"Threshold: {alert.threshold_percent}%"
                if alert.threshold_percent is not None
                else alert.alert_type
            ),
            "active": alert.active,
            "created_at": alert.created_at.isoformat() if alert.created_at else None,
        }
        for alert in alerts
    ]
