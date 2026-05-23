"""Dashboard API router with SSE and trend endpoints."""
from __future__ import annotations

import asyncio
import json
from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_cookie, require_role
from app.database import get_db
from app.domains.dashboard import service as dashboard_domain_service
from app.domains.dashboard.dashboard_service import DashboardService
from app.models.user import User
from app.schemas.dashboard import DashboardKPIResponse, TrendResponse

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


# In-memory store for last pushed KPI values per user
_last_kpi_values: dict[int, dict[str, Any]] = {}


def _json_default(value: Any) -> str:
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


@router.get("/kpi", response_model=DashboardKPIResponse)
async def get_dashboard_kpi(
    current_user: User = Depends(require_role("user", "admin", "super_admin")),
    db: AsyncSession = Depends(get_db),
):
    """Get current dashboard KPI data."""
    service = DashboardService(db)
    user_kpi = await service.calculate_user_kpi(current_user.id)

    system_kpi = None
    if current_user.role in ("admin", "super_admin"):
        system_kpi = await service.calculate_system_kpi()

    return DashboardKPIResponse(user=user_kpi, system=system_kpi)


@router.get("/events")
async def stream_dashboard_events(
    request: Request,
    current_user: User = Depends(get_current_user_cookie),
    db: AsyncSession = Depends(get_db),
):
    """Stream dashboard KPI updates over SSE."""
    user_id = current_user.id
    is_admin = current_user.role in ("admin", "super_admin")

    async def event_generator():
        try:
            service = DashboardService(db)

            # Push initial data immediately on connection
            user_kpi = await service.calculate_user_kpi(user_id)

            initial_payload = {
                "event": "kpi_update",
                "data": user_kpi.model_dump(),
            }

            if is_admin:
                system_kpi = await service.calculate_system_kpi()
                initial_payload["system"] = system_kpi.model_dump()

            _last_kpi_values[user_id] = user_kpi.model_dump()
            payload_json = json.dumps(
                initial_payload, ensure_ascii=False, default=_json_default
            )
            yield f"data: {payload_json}\n\n"

            while True:
                if await request.is_disconnected():
                    break

                user_kpi = await service.calculate_user_kpi(user_id)

                event_payload = {
                    "event": "kpi_update",
                    "data": user_kpi.model_dump(),
                }

                if is_admin:
                    system_kpi = await service.calculate_system_kpi()
                    event_payload["system"] = system_kpi.model_dump()

                # Check if values changed since last push
                current_values = user_kpi.model_dump()
                last_values = _last_kpi_values.get(user_id)

                if last_values != current_values:
                    _last_kpi_values[user_id] = current_values
                    payload_json = json.dumps(
                        event_payload, ensure_ascii=False, default=_json_default
                    )
                    yield f"data: {payload_json}\n\n"

                # Wait before next check (30 seconds)
                await asyncio.sleep(30)
        except asyncio.CancelledError:
            pass

    return StreamingResponse(
        event_generator(), media_type="text/event-stream"
    )


@router.get("/trends", response_model=TrendResponse)
async def get_trend_data(
    type: str = Query(
        ...,
        pattern="^(price|jobs|platform_products|platform_jobs|salary|system_health|platform_success)$",
    ),
    days: int = Query(7, ge=1, le=90),
    current_user: User = Depends(require_role("user", "admin", "super_admin")),
    db: AsyncSession = Depends(get_db),
):
    """Get trend chart data for dashboard."""
    service = DashboardService(db)

    if type == "price":
        return await service.get_price_trends(current_user.id, days)
    elif type == "jobs":
        return await service.get_job_trends(current_user.id, days)
    elif type == "platform_products":
        return await service.get_platform_distribution(
            current_user.id, "products"
        )
    elif type == "platform_jobs":
        return await service.get_platform_distribution(current_user.id, "jobs")
    elif type == "salary":
        return await service.get_salary_distribution(current_user.id)
    elif type == "system_health":
        if current_user.role not in ("admin", "super_admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required",
            )
        return await service.get_system_health_trends(days)
    elif type == "platform_success":
        if current_user.role not in ("admin", "super_admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required",
            )
        return await service.get_platform_success_rates()

    raise HTTPException(status_code=400, detail=f"Unknown trend type: {type}")


@router.get("/alerts/recent")
async def get_recent_alerts(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(require_role("admin", "super_admin")),
    db: AsyncSession = Depends(get_db),
):
    """Get recent alerts (admin only)."""
    return await dashboard_domain_service.list_recent_alerts(db, limit=limit)
