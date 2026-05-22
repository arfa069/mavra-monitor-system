"""Scheduling API router."""

from fastapi import APIRouter, Depends, Request
from fastapi.responses import JSONResponse

from app.core.security import require_role
from app.services.scheduler_job import JobConfigScheduler, ProductCronScheduler

router = APIRouter(tags=["scheduler"])


@router.get("/scheduler/status")
async def get_scheduler_status(
    request: Request,
    current_user=Depends(require_role("admin", "super_admin")),
):
    """Get APScheduler status and next run times for all cron jobs."""
    scheduler = getattr(request.app.state, "scheduler", None)

    if scheduler is None:
        return JSONResponse(
            status_code=503,
            content={"scheduler": "not_started"},
        )

    job_config_scheduler: JobConfigScheduler = getattr(
        request.app.state, "job_config_scheduler", None
    )
    product_cron_scheduler: ProductCronScheduler = getattr(
        request.app.state, "product_cron_scheduler", None
    )

    return JSONResponse(
        content={
            "scheduler": "running",
            "timezone": "Asia/Shanghai",
            "jobs": {
                "product_platforms": (
                    product_cron_scheduler.get_next_run_times()
                    if product_cron_scheduler
                    else {}
                ),
                "job_configs": (
                    job_config_scheduler.get_next_run_times()
                    if job_config_scheduler
                    else {}
                ),
            },
        }
    )
