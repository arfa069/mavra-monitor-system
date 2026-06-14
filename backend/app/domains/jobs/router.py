"""Job search API router."""

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.audit import log_audit_from_request
from app.core.permissions import require_permission
from app.core.security import get_current_user
from app.core.system_log import emit_system_log_detached
from app.database import get_db
from app.domains.jobs import service as job_service
from app.domains.jobs.crawl_service import (
    crawl_all_job_searches_background,
    crawl_single_config_background,
)
from app.domains.jobs.match_service import (
    enqueue_job_match_analysis,
)
from app.domains.jobs.scheduler import JobConfigScheduler
from app.models.job_match import MatchResult
from app.models.user import User
from app.schemas.job import (
    JobConfigCronUpdate,
    JobListResponse,
    JobResponse,
    JobSearchConfigCreate,
    JobSearchConfigResponse,
    JobSearchConfigUpdate,
)
from app.schemas.job_crawl_log import JobCrawlLogResponse
from app.schemas.job_match import (
    MatchAnalyzeRequest,
    MatchResultListResponse,
    MatchResultResponse,
    UserResumeCreate,
    UserResumeResponse,
    UserResumeUpdate,
)

from app.schemas.runtime_api import (
    MessageResponse,
    TaskQueuedResponse,
    TaskProgressResponse,
    TaskErrorResponse,
    MatchTaskQueuedResponse,
)
from app.schemas.scheduling import JobConfigSchedulesResponse

router = APIRouter(prefix="/jobs", tags=["jobs"])

def _serialize_match_result(item: MatchResult) -> MatchResultResponse:

    job = item.job

    return MatchResultResponse(

        id=item.id,

        user_id=item.user_id,

        resume_id=item.resume_id,

        job_id=item.job_id,

        match_score=item.match_score,

        match_reason=item.match_reason,

        apply_recommendation=item.apply_recommendation,

        llm_model_used=item.llm_model_used,

        created_at=item.created_at,

        updated_at=item.updated_at,

        job_title=job.title if job else None,

        job_company=job.company if job else None,

        job_salary=job.salary if job else None,

        job_location=job.location if job else None,

        job_url=job.url if job else None,

        job_description=job.description if job else None,

    )

# ── JobSearchConfig CRUD ──────────────────────────────────────────

@router.get("/configs", response_model=list[JobSearchConfigResponse])

async def list_configs(

    active: bool | None = None,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    """List all job search configs."""
    return await job_service.list_job_configs(db, user_id=current_user.id, active=active)

@router.post("/configs", response_model=JobSearchConfigResponse, status_code=201)

async def create_config(

    data: JobSearchConfigCreate,

    request: Request,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):
    """Create a new job search config."""
    try:
        config = await job_service.create_job_config(
            db, user_id=current_user.id, data=data
        )
    except job_service.JobProfileNotFoundError as exc:
        raise HTTPException(status_code=400, detail="Profile not found") from exc

    # Sync scheduler if cron is set

    if config.cron_expression:

        scheduler: JobConfigScheduler = getattr(request.app.state, "job_config_scheduler", None)

        if scheduler:

            import logging

            try:

                scheduler.add_job(config.id, config.cron_expression, config.cron_timezone or "Asia/Shanghai")

            except Exception as exc:

                logging.getLogger("app.domains.jobs").error("Failed to add job to scheduler: %s", exc)

                raise HTTPException(status_code=400, detail="Scheduler error") from exc

    await log_audit_from_request(
        request,
        db,
        action="job_config.create",
        actor_user_id=current_user.id,
        target_type="job_config",
        target_id=config.id,
        details={"name": config.name},
        commit=True,
    )

    return config

@router.get("/resumes", response_model=list[UserResumeResponse])

async def list_resumes(

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    return await job_service.list_user_resumes(db, user_id=current_user.id)

@router.post("/resumes", response_model=UserResumeResponse, status_code=201)

async def create_resume(

    data: UserResumeCreate,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    return await job_service.create_user_resume(
        db, user_id=current_user.id, data=data
    )

@router.patch("/resumes/{resume_id}", response_model=UserResumeResponse)

async def update_resume(

    resume_id: int,

    data: UserResumeUpdate,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    try:
        return await job_service.update_user_resume(
            db, user_id=current_user.id, resume_id=resume_id, data=data
        )
    except job_service.UserResumeNotFoundError:
        raise HTTPException(status_code=404, detail="Resume not found")

@router.delete("/resumes/{resume_id}", response_model=MessageResponse)
async def delete_resume(

    resume_id: int,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    try:
        await job_service.delete_user_resume(
            db, user_id=current_user.id, resume_id=resume_id
        )
    except job_service.UserResumeNotFoundError:
        raise HTTPException(status_code=404, detail="Resume not found")

    return {"message": "Resume deleted"}

@router.get("/match-results", response_model=MatchResultListResponse)

async def list_match_results(

    resume_id: int | None = None,

    job_id: int | None = None,

    min_score: int | None = Query(default=None, ge=0, le=100),

    recommendation: str | None = Query(default=None),

    page: int = Query(default=1, ge=1),

    page_size: int = Query(default=20, ge=1, le=100),

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    items, total = await job_service.list_match_results(
        db,
        user_id=current_user.id,
        resume_id=resume_id,
        job_id=job_id,
        min_score=min_score,
        recommendation=recommendation,
        page=page,
        page_size=page_size,
    )

    return MatchResultListResponse(

        items=[_serialize_match_result(item) for item in items],

        total=total,

        page=page,

        page_size=page_size,

    )

@router.post("/match-results/analyze", response_model=MatchTaskQueuedResponse)
async def trigger_match_analysis(
    data: MatchAnalyzeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Enqueue match analysis as a durable task.

    This endpoint no longer executes LLM analysis inline.
    It creates a crawl_tasks record and returns a task_id for polling.
    """

    try:
        await job_service.validate_resume_owner(
            db, user_id=current_user.id, resume_id=data.resume_id
        )
    except job_service.UserResumeNotFoundError:
        raise HTTPException(status_code=404, detail="Resume not found")

    job_ids = data.job_ids
    if job_ids is None:
        job_ids = await job_service.list_user_job_ids(db, user_id=current_user.id)

    result = await enqueue_job_match_analysis(
        db,
        resume_id=data.resume_id,
        job_ids=job_ids,
        user_id=current_user.id,
        source="manual",
    )

    if result["status"] == "completed":
        return JSONResponse(content={
            "status": "completed",
            "task_id": None,
            "total": 0,
            "reason": "all_up_to_date",
        })

    await emit_system_log_detached(
        category="runtime",
        event_type="job_match_analysis.enqueued",
        source="jobs",
        severity="info",
        status="pending",
        message=f"Match analysis enqueued for resume {data.resume_id}",
        user_id=current_user.id,
        entity_type="resume",
        entity_id=str(data.resume_id),
        payload={
            "task_id": result["task_id"],
            "resume_id": data.resume_id,
            "job_count": result["total"],
            "source": "manual",
        },
    )

    return JSONResponse(content={
        "status": "pending",
        "task_id": result["task_id"],
        "total": result["total"],
    })

@router.post("/match-results/analyze-async", response_model=MatchTaskQueuedResponse)
async def trigger_match_analysis_async(
    data: MatchAnalyzeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Trigger async match analysis, returning task_id for polling.

    Creates a durable crawl_tasks record. Poll GET /jobs/tasks/{task_id} for status.
    """

    try:
        await job_service.validate_resume_owner(
            db, user_id=current_user.id, resume_id=data.resume_id
        )
    except job_service.UserResumeNotFoundError:
        raise HTTPException(status_code=404, detail="Resume not found")

    job_ids = data.job_ids
    if job_ids is None:
        job_ids = await job_service.list_user_job_ids(db, user_id=current_user.id)

    result = await enqueue_job_match_analysis(
        db,
        resume_id=data.resume_id,
        job_ids=job_ids,
        user_id=current_user.id,
        source="manual",
    )

    if result["status"] == "completed":
        return JSONResponse(content={
            "status": "completed",
            "task_id": None,
            "total": 0,
            "reason": "all_up_to_date",
        })

    await emit_system_log_detached(
        category="runtime",
        event_type="job_match_analysis.enqueued",
        source="jobs",
        severity="info",
        status="pending",
        message=f"Match analysis enqueued for resume {data.resume_id}",
        user_id=current_user.id,
        entity_type="resume",
        entity_id=str(data.resume_id),
        payload={
            "task_id": result["task_id"],
            "resume_id": data.resume_id,
            "job_count": result["total"],
            "source": "manual",
        },
    )

    return JSONResponse(content={
        "status": "pending",
        "task_id": result["task_id"],
        "total": result["total"],
    })

@router.get(
    "/tasks/{task_id}",
    response_model=TaskProgressResponse,
    responses={404: {"model": TaskErrorResponse}},
)
async def get_match_analysis_task_status(
    task_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get status of a match analysis task from the durable crawl_tasks store.

    Returns task progress (total/success/errors) and final results when completed.
    """
    from app.domains.crawling.task_store import get_crawl_task_record

    record = await get_crawl_task_record(db, task_id, user_id=current_user.id)
    if not record or record.task_type != "job_match_analysis":
        return JSONResponse(
            content={"status": "error", "reason": "task_not_found"},
            status_code=404,
        )

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
    })

@router.get("/configs/{config_id}", response_model=JobSearchConfigResponse)

async def get_config(

    config_id: int,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    """Get a single config."""
    try:
        return await job_service.get_job_config(
            db, user_id=current_user.id, config_id=config_id
        )
    except job_service.JobConfigNotFoundError:
        raise HTTPException(status_code=404, detail="Config not found")

@router.patch("/configs/{config_id}", response_model=JobSearchConfigResponse)

async def update_config(

    config_id: int,

    data: JobSearchConfigUpdate,

    request: Request,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):
    """Update a config."""
    try:
        config, update_data = await job_service.update_job_config(
            db, actor=current_user, config_id=config_id, data=data
        )
    except job_service.JobConfigNotFoundError:
        raise HTTPException(status_code=404, detail="Config not found")
    except job_service.JobProfileNotFoundError as exc:
        raise HTTPException(status_code=400, detail="Profile not found") from exc
    except job_service.JobConfigCronPermissionError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="权限不足：仅 super_admin 可修改定时配置",
        )

    # Sync scheduler if cron changed

    if "cron_expression" in update_data:

        scheduler: JobConfigScheduler = getattr(request.app.state, "job_config_scheduler", None)

        if scheduler:

            import logging

            try:

                if config.cron_expression:

                    scheduler.add_job(config.id, config.cron_expression, config.cron_timezone or "Asia/Shanghai")

                else:

                    scheduler.remove_job(config.id)

            except Exception as exc:

                logging.getLogger("app.domains.jobs").error("Failed to sync scheduler: %s", exc)

                raise HTTPException(status_code=400, detail="Scheduler error") from exc

    await log_audit_from_request(
        request,
        db,
        action="job_config.update",
        actor_user_id=current_user.id,
        target_type="job_config",
        target_id=config_id,
        details={"name": config.name, "updated_fields": list(update_data.keys())},
        commit=True,
    )

    return config

@router.delete("/configs/{config_id}", response_model=MessageResponse)
async def delete_config(

    config_id: int,

    request: Request,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):
    """Delete a config (cascades to jobs)."""
    try:
        config, config_info = await job_service.delete_job_config(
            db, user_id=current_user.id, config_id=config_id
        )
    except job_service.JobConfigNotFoundError:
        raise HTTPException(status_code=404, detail="Config not found")

    # Remove scheduler job before deletion

    scheduler: JobConfigScheduler = getattr(request.app.state, "job_config_scheduler", None)

    if scheduler:
        scheduler.remove_job(config_id)

    await log_audit_from_request(
        request,
        db,
        action="job_config.delete",
        actor_user_id=current_user.id,
        target_type="job_config",
        target_id=config_id,
        details=config_info,
        commit=True,
    )

    return {"message": "Config deleted"}

# ── Job Listing ──────────────────────────────────────────────────

@router.get("", response_model=JobListResponse)

async def list_jobs(

    search_config_id: int | None = None,

    keyword: str | None = None,

    company: str | None = None,

    salary_min: int | None = None,

    salary_max: int | None = None,

    location: str | None = None,

    is_active: bool | None = None,

    sort_by: str = Query(default="first_seen_at"),

    sort_order: str = Query(default="desc"),

    page: int = Query(default=1, ge=1),

    page_size: int = Query(default=20, ge=1, le=100),

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    """List jobs with filtering and pagination."""

    items, total, rec_map = await job_service.list_jobs(
        db,
        user_id=current_user.id,
        search_config_id=search_config_id,
        keyword=keyword,
        company=company,
        salary_min=salary_min,
        salary_max=salary_max,
        location=location,
        is_active=is_active,
        sort_by=sort_by,
        sort_order=sort_order,
        page=page,
        page_size=page_size,
    )

    resp_items = []
    for job in items:
        job_resp = JobResponse.model_validate(job)
        job_resp.apply_recommendation = rec_map.get(job.id)
        resp_items.append(job_resp)

    return JobListResponse(

        items=resp_items,

        total=total,

        page=page,

        page_size=page_size,

    )

# ── Job Crawl Logs ──────────────────────────────────────────────

@router.get("/crawl-logs", response_model=list[JobCrawlLogResponse])

async def get_job_crawl_logs(

    search_config_id: int | None = Query(None, description="Filter by search config ID"),

    status: str | None = Query(None, pattern="^(SUCCESS|ERROR)$"),

    hours: int = Query(168, ge=1, le=720),

    limit: int = Query(100, ge=1, le=1000),

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),
):
    """Get job crawl logs for current user's search configs."""
    return await job_service.list_job_crawl_logs(
        db,
        user_id=current_user.id,
        search_config_id=search_config_id,
        status=status,
        hours=hours,
        limit=limit,
    )

@router.get("/{job_id_str}", response_model=JobResponse)

async def get_job(

    job_id_str: str,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    """Get a single job by boss job_id."""

    try:
        return await job_service.get_job(
            db, user_id=current_user.id, job_id=job_id_str
        )
    except job_service.JobNotFoundError:
        raise HTTPException(status_code=404, detail="Job not found")

# ── Crawl Triggers ───────────────────────────────────────────────

@router.post("/crawl-now", response_model=TaskQueuedResponse)
async def crawl_now(

    current_user: User = Depends(require_permission("crawl:execute")),

):

    """Trigger crawling all active job search configs (async)."""

    task = await crawl_all_job_searches_background(user_id=current_user.id)

    return JSONResponse(content={

        "status": "pending",

        "task_id": task.task_id,

        "message": f"爬取任务已启动，通过 /jobs/crawl/status/{task.task_id} 查询进度",

    })

@router.post("/crawl-now/{config_id}", response_model=TaskQueuedResponse)
async def crawl_single(

    config_id: int,

    current_user: User = Depends(require_permission("crawl:execute")),

    db: AsyncSession = Depends(get_db),

):

    """Trigger crawling a single config (async)."""

    # 验证 config 归属
    try:
        await job_service.get_job_config(
            db, user_id=current_user.id, config_id=config_id
        )
    except job_service.JobConfigNotFoundError:
        raise HTTPException(status_code=404, detail="配置不存在或无权访问")

    task = await crawl_single_config_background(config_id, user_id=current_user.id)

    return JSONResponse(content={

        "status": "pending",

        "task_id": task.task_id,

        "message": f"爬取任务已启动，通过 /jobs/crawl/status/{task.task_id} 查询进度",

    })

@router.get(
    "/crawl/status/{task_id}",
    response_model=TaskProgressResponse,
    responses={404: {"model": TaskErrorResponse}},
)
async def get_job_crawl_status(task_id: str, db: AsyncSession = Depends(get_db)):
    """Get the status of a job crawl task from persistent store."""
    from app.domains.crawling.task_store import get_crawl_task_record
    record = await get_crawl_task_record(db, task_id)
    if not record:
        return JSONResponse(
            content={"status": "error", "reason": "task_not_found"},
            status_code=404,
        )
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
    "/crawl/result/{task_id}",
    response_model=TaskProgressResponse,
    responses={
        202: {"model": TaskProgressResponse},
        404: {"model": TaskErrorResponse},
        500: {"model": TaskErrorResponse},
    },
)
async def get_job_crawl_result(task_id: str, db: AsyncSession = Depends(get_db)):
    """Get the final result of a completed job crawl task."""
    from app.domains.crawling.task_store import get_crawl_task_record
    record = await get_crawl_task_record(db, task_id)
    if not record:
        return JSONResponse(
            content={"status": "error", "reason": "task_not_found"},
            status_code=404,
        )
    if record.status in ("pending", "running"):
        return JSONResponse(
            content={
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
            },
            status_code=202,
        )
    if record.status == "failed":
        return JSONResponse(
            content={
                "status": "error",
                "task_id": record.task_id,
                "reason": record.reason,
                "worker_id": record.locked_by,
                "started_at": record.started_at.isoformat() if record.started_at else None,
                "finished_at": record.finished_at.isoformat() if record.finished_at else None,
                "details": record.details_json,
            },
            status_code=500,
        )
    return JSONResponse(content={
        "status": "completed",
        "task_id": record.task_id,
        "total": record.total,
        "success": record.success,
        "errors": record.errors,
        "reason": record.reason,
        "details": record.details_json,
        "worker_id": record.locked_by,
        "started_at": record.started_at.isoformat() if record.started_at else None,
        "finished_at": record.finished_at.isoformat() if record.finished_at else None,
    })

# ── Job Crawl Logs ──────────────────────────────────────────────

# ── Per-Config Cron Management ──────────────────────────────

@router.patch("/configs/{config_id}/cron", response_model=JobSearchConfigResponse)

async def update_config_cron(

    config_id: int,

    data: JobConfigCronUpdate,

    request: Request,

    current_user: User = Depends(require_permission("schedule:configure")),

    db: AsyncSession = Depends(get_db),

):

    """Update only the cron settings for a job search config.

    Null cron_expression disables scheduled crawling for this config.
    """
    try:
        config = await job_service.update_job_config_cron(
            db, user_id=current_user.id, config_id=config_id, data=data
        )
    except job_service.JobConfigNotFoundError:
        raise HTTPException(status_code=404, detail="Config not found")

    # Sync scheduler

    scheduler: JobConfigScheduler = getattr(request.app.state, "job_config_scheduler", None)

    if scheduler:

        import logging

        try:

            if config.cron_expression:

                scheduler.add_job(config.id, config.cron_expression, config.cron_timezone)

            else:

                scheduler.remove_job(config.id)

        except Exception as exc:

            logging.getLogger("app.domains.jobs").error("Failed to sync scheduler: %s", exc)

            raise HTTPException(status_code=400, detail="Scheduler error") from exc

    await log_audit_from_request(
        request,
        db,
        action="schedule.update",
        actor_user_id=current_user.id,
        target_type="job_config",
        target_id=config.id,
        details={"config_name": config.name, "cron_expression": data.cron_expression},
        commit=True,
    )

    return config

@router.get("/scheduler/job-configs", response_model=JobConfigSchedulesResponse)
async def get_job_config_schedules(

    request: Request,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    """Get next run times for all per-config job crawl schedules."""

    # 获取当前用户的 config_ids
    user_config_ids = await job_service.list_job_config_ids(
        db, user_id=current_user.id
    )

    scheduler: JobConfigScheduler = getattr(request.app.state, "job_config_scheduler", None)

    if not scheduler:

        return {"configs": []}

    schedules = scheduler.get_next_run_times()

    # 只返回当前用户拥有的配置

    return {"configs": [

        {"config_id": cid, **info} for cid, info in schedules.items() if cid in user_config_ids

    ]}
