"""Crawl API router."""

from fastapi import APIRouter, Depends, Query
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import require_permission
from app.core.security import get_current_user
from app.database import get_db
from app.domains.crawling import service as crawling_service
from app.models.user import User
from app.schemas.crawl_log import CrawlLogResponse
from app.schemas.runtime_api import (
    CleanupResultResponse,
    CrawlerWorkerResponse,
    TaskErrorResponse,
    TaskProgressResponse,
    TaskQueuedResponse,
)

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
    return await crawling_service.list_crawl_logs(
        db,
        user_id=current_user.id,
        product_id=product_id,
        status=status,
        hours=hours,
        limit=limit,
    )


@router.post(
    "/crawl-now",
    response_model=TaskQueuedResponse,
    responses={
        409: {"model": TaskQueuedResponse},
        500: {"model": TaskQueuedResponse},
    },
)
async def crawl_now(
    current_user: User = Depends(require_permission("crawl:execute")),
):
    """Start crawling all active products immediately.

    Returns immediately with a task_id. Poll /products/crawl/status/{task_id} for progress.
    """
    from app.domains.crawling.scheduler_service import crawl_all_products

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


@router.get(
    "/status/{task_id}",
    response_model=TaskProgressResponse,
    responses={404: {"model": TaskErrorResponse}},
)
async def get_crawl_status(task_id: str, db: AsyncSession = Depends(get_db)):
    """Get the status of a crawl task from persistent store."""
    from app.domains.crawling.task_store import get_crawl_task_record

    record = await get_crawl_task_record(db, task_id)
    if not record:
        return JSONResponse(content={"status": "error", "reason": "task_not_found"}, status_code=404)

    return JSONResponse(content={
        "task_id": record.task_id,
        "status": record.status,
        "total": record.total,
        "success": record.success,
        "errors": record.errors,
        "reason": record.reason,
        "worker_id": record.locked_by,
        "heartbeat_at": record.heartbeat_at.isoformat() if record.heartbeat_at else None,
        "lease_until": record.lease_until.isoformat() if record.lease_until else None,
        "started_at": record.started_at.isoformat() if record.started_at else None,
        "finished_at": record.finished_at.isoformat() if record.finished_at else None,
        "details": record.details_json,
    })


@router.get(
    "/result/{task_id}",
    response_model=TaskProgressResponse,
    responses={
        202: {"model": TaskProgressResponse},
        404: {"model": TaskErrorResponse},
        500: {"model": TaskErrorResponse},
    },
)
async def get_crawl_result(task_id: str, db: AsyncSession = Depends(get_db)):
    """Get the final result of a completed crawl task from persistent store."""
    from app.domains.crawling.task_store import get_crawl_task_record

    record = await get_crawl_task_record(db, task_id)
    if not record:
        return JSONResponse(content={"status": "error", "reason": "task_not_found"}, status_code=404)

    if record.status in ("pending", "running"):
        return JSONResponse(content={
            "status": record.status,
            "task_id": record.task_id,
            "total": record.total,
            "success": record.success,
            "errors": record.errors,
            "worker_id": record.locked_by,
            "heartbeat_at": record.heartbeat_at.isoformat() if record.heartbeat_at else None,
            "lease_until": record.lease_until.isoformat() if record.lease_until else None,
            "started_at": record.started_at.isoformat() if record.started_at else None,
            "finished_at": record.finished_at.isoformat() if record.finished_at else None,
            "details": record.details_json,
        }, status_code=202)

    if record.status == "failed":
        return JSONResponse(content={
            "status": "error",
            "task_id": record.task_id,
            "reason": record.reason,
            "worker_id": record.locked_by,
            "started_at": record.started_at.isoformat() if record.started_at else None,
            "finished_at": record.finished_at.isoformat() if record.finished_at else None,
            "details": record.details_json,
        }, status_code=500)

    # Completed
    return JSONResponse(content={
        "status": "completed",
        "task_id": record.task_id,
        "total": record.total,
        "success": record.success,
        "errors": record.errors,
        "details": record.details_json,
        "worker_id": record.locked_by,
        "started_at": record.started_at.isoformat() if record.started_at else None,
        "finished_at": record.finished_at.isoformat() if record.finished_at else None,
    })


@router.get("/workers", response_model=list[CrawlerWorkerResponse])
async def list_crawler_workers(
    current_user: User = Depends(require_permission("crawl:execute")),
    db: AsyncSession = Depends(get_db),
):
    """List all registered crawler workers."""
    from sqlalchemy import select

    from app.models.crawler_worker import CrawlerWorkerRecord

    result = await db.execute(
        select(CrawlerWorkerRecord).order_by(CrawlerWorkerRecord.last_heartbeat_at.desc())
    )
    workers = result.scalars().all()
    return [
        {
            "worker_id": worker.worker_id,
            "kind": worker.kind,
            "platform": worker.platform,
            "hostname": worker.hostname,
            "pid": worker.pid,
            "status": worker.status,
            "started_at": worker.started_at.isoformat() if worker.started_at else None,
            "last_heartbeat_at": worker.last_heartbeat_at.isoformat() if worker.last_heartbeat_at else None,
            "stopped_at": worker.stopped_at.isoformat() if worker.stopped_at else None,
        }
        for worker in workers
    ]


@router.post("/cleanup", response_model=CleanupResultResponse)
async def cleanup_old_data(
    retention_days: int = Query(default=365, ge=1, le=3650),
    current_user: User = Depends(require_permission("crawl:execute")),
    db: AsyncSession = Depends(get_db),
):
    """Delete price history and crawl logs older than retention period."""
    result = await crawling_service.cleanup_old_data(
        db, user_id=current_user.id, retention_days=retention_days
    )
    return JSONResponse(content=result)
