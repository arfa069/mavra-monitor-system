"""Alerts API router."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.database import get_db
from app.domains.alerts import service as alert_service
from app.models.user import User
from app.schemas.alert import AlertCreate, AlertResponse, AlertUpdate

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.post("", response_model=AlertResponse, status_code=status.HTTP_201_CREATED)
async def create_alert(
    alert_data: AlertCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new price alert."""
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    try:
        return await alert_service.create_alert(
            db, user_id=current_user.id, data=alert_data
        )
    except alert_service.ProductNotFoundError:
        raise HTTPException(status_code=404, detail="Product not found")


@router.get("", response_model=list[AlertResponse])
async def list_alerts(
    product_id: int | None = None,
    active: bool | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all alerts."""
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    return await alert_service.list_alerts(
        db, user_id=current_user.id, product_id=product_id, active=active
    )


@router.get("/{alert_id}", response_model=AlertResponse)
async def get_alert(
    alert_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get alert details."""
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    try:
        return await alert_service.get_alert(
            db, user_id=current_user.id, alert_id=alert_id
        )
    except alert_service.AlertNotFoundError:
        raise HTTPException(status_code=404, detail="Alert not found")


@router.patch("/{alert_id}", response_model=AlertResponse)
async def update_alert(
    alert_id: int,
    alert_data: AlertUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update an alert."""
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    try:
        return await alert_service.update_alert(
            db, user_id=current_user.id, alert_id=alert_id, data=alert_data
        )
    except alert_service.AlertNotFoundError:
        raise HTTPException(status_code=404, detail="Alert not found")


@router.delete("/{alert_id}")
async def delete_alert(
    alert_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete an alert."""
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    try:
        await alert_service.delete_alert(
            db, user_id=current_user.id, alert_id=alert_id
        )
    except alert_service.AlertNotFoundError:
        raise HTTPException(status_code=404, detail="Alert not found")
    return {"message": "Alert deleted"}
