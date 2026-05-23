"""Crawl API router."""

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import require_permission
from app.core.security import get_current_user
from app.database import get_db
from app.domains.crawling import service as crawling_service
from app.models.user import User
from app.schemas.crawl_log import CrawlLogResponse

router = APIRouter(prefix="/crawl", tags=["products-crawl"])


async def _crawl_one(product_id: int) -> dict:
    """Compatibility wrapper used by scheduler_service."""
    return await crawling_service.crawl_one(product_id)


@router.get("/logs", response_model=list[CrawlLogResponse])
async def get_crawl_logs(
    product_id: int | None = None,
    status: str | None = None,
    hours: int = Query(default=168, ge=1, le=720),
    limit: int = Query(default=100, ge=1, le=1000),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get recent crawl logs."""
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    return await crawling_service.list_crawl_logs(
        db,
        user_id=current_user.id,
        product_id=product_id,
        status=status,
        hours=hours,
        limit=limit,
    )


@router.post("/crawl-now")
async def crawl_now(
    current_user: User = Depends(require_permission("crawl:execute")),
):
    """Start crawling all active products immediately.

    Returns immediately with a task_id. Poll /products/crawl/status/{task_id} for progress.
    """
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    from app.services.scheduler_service import crawl_all_products

    result = await crawl_all_products(
        source="manual",
        background=True,
        user_id=current_user.id,
    )

    if result["status"] == "skipped":
        return JSONResponse(content={"status": "skipped", "reason": result["reason"]}, status_code=409)
    if result["status"] == "error":
        return JSONResponse(content={"status": "error", "reason": result["reason"]}, status_code=500)

    return JSONResponse(content={
        "status": "pending",
        "task_id": result["task_id"],
        "message": "爬取任务已启动，请通过 /products/crawl/status/{task_id} 查询进度",
    })


@router.get("/status/{task_id}")
async def get_crawl_status(task_id: str):
    """Get the status of a crawl task."""
    from app.services.scheduler_service import get_task

    task = get_task(task_id)
    if not task:
        return JSONResponse(content={"status": "error", "reason": "task_not_found"}, status_code=404)

    return JSONResponse(content={
        "task_id": task.task_id,
        "status": task.status.value,
        "total": task.total,
        "success": task.success,
        "errors": task.errors,
        "reason": task.reason,
    })


@router.get("/result/{task_id}")
async def get_crawl_result(task_id: str):
    """Get the final result of a completed crawl task."""
    from app.services.scheduler_service import TaskStatus, get_task

    task = get_task(task_id)
    if not task:
        return JSONResponse(content={"status": "error", "reason": "task_not_found"}, status_code=404)

    if task.status == TaskStatus.PENDING or task.status == TaskStatus.RUNNING:
        return JSONResponse(content={
            "status": task.status.value,
            "task_id": task.task_id,
            "total": task.total,
            "success": task.success,
            "errors": task.errors,
        }, status_code=202)

    if task.status == TaskStatus.FAILED:
        return JSONResponse(content={
            "status": "error",
            "task_id": task.task_id,
            "reason": task.reason,
        }, status_code=500)

    # Completed
    return JSONResponse(content={
        "status": "completed",
        "task_id": task.task_id,
        "total": task.total,
        "success": task.success,
        "errors": task.errors,
        "details": task.details,
    })


@router.post("/cleanup")
async def cleanup_old_data(
    retention_days: int = Query(default=365, ge=1, le=3650),
    current_user: User = Depends(require_permission("crawl:execute")),
    db: AsyncSession = Depends(get_db),
):
    """Delete price history and crawl logs older than retention period."""
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    result = await crawling_service.cleanup_old_data(
        db, user_id=current_user.id, retention_days=retention_days
    )
    return JSONResponse(content=result)
