"""Dashboard domain business services."""

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.domains.dashboard import repository
from app.models.user import User


async def get_stream_user(db: AsyncSession, *, token: str) -> User:
    payload = decode_access_token(token)
    if payload is None or payload.get("sub") is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing token",
        )

    user = await repository.get_active_user(db, user_id=int(payload["sub"]))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
        )
    return user


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
