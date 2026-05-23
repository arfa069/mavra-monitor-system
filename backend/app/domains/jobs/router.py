"""Job search API router."""

import asyncio

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.audit import log_audit
from app.core.permissions import require_permission
from app.core.security import get_current_user
from app.core.system_log import emit_system_log_detached
from app.core.task_registry import TaskStatus, get_task
from app.database import get_db
from app.domains.jobs import service as job_service
from app.domains.jobs.crawl_service import (
    crawl_all_job_searches_background,
    crawl_single_config_background,
)
from app.domains.jobs.match_service import (
    _get_jobs_needing_analysis,
    analyze_resume_vs_jobs,
    run_match_analysis_task,
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
    MatchAnalyzeResponse,
    MatchResultListResponse,
    MatchResultResponse,
    UserResumeCreate,
    UserResumeResponse,
    UserResumeUpdate,
)

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
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    return await job_service.list_job_configs(db, user_id=current_user.id, active=active)




@router.post("/configs", response_model=JobSearchConfigResponse, status_code=201)

async def create_config(

    data: JobSearchConfigCreate,

    request: Request,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):
    """Create a new job search config."""
    config = await job_service.create_job_config(
        db, user_id=current_user.id, data=data
    )


    # Sync scheduler if cron is set

    if config.cron_expression:

        scheduler: JobConfigScheduler = getattr(request.app.state, "job_config_scheduler", None)

        if scheduler:

            import logging

            try:

                scheduler.add_job(config.id, config.cron_expression, config.cron_timezone or "Asia/Shanghai")

            except Exception as exc:

                logging.getLogger("app.domains.jobs").error("Failed to add job to scheduler: %s", exc)

                raise HTTPException(status_code=400, detail=f"Scheduler error: {str(exc)}")



    # Audit log

    ip_address = request.client.host if request.client else ""

    await log_audit(

        db=db,

        action="job_config.create",

        actor_user_id=current_user.id,

        target_type="job_config",

        target_id=config.id,

        details={"name": config.name},

        ip_address=ip_address,

        user_agent=request.headers.get("user-agent", "")[:512],

        commit=True,

    )



    return config





@router.get("/resumes", response_model=list[UserResumeResponse])

async def list_resumes(

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")

    return await job_service.list_user_resumes(db, user_id=current_user.id)





@router.post("/resumes", response_model=UserResumeResponse, status_code=201)

async def create_resume(

    data: UserResumeCreate,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")

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

    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")

    try:
        return await job_service.update_user_resume(
            db, user_id=current_user.id, resume_id=resume_id, data=data
        )
    except job_service.UserResumeNotFoundError:
        raise HTTPException(status_code=404, detail="Resume not found")





@router.delete("/resumes/{resume_id}")

async def delete_resume(

    resume_id: int,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")

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

    page: int = Query(default=1, ge=1),

    page_size: int = Query(default=20, ge=1, le=100),

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")

    items, total = await job_service.list_match_results(
        db,
        user_id=current_user.id,
        resume_id=resume_id,
        job_id=job_id,
        min_score=min_score,
        page=page,
        page_size=page_size,
    )



    return MatchResultListResponse(

        items=[_serialize_match_result(item) for item in items],

        total=total,

        page=page,

        page_size=page_size,

    )





@router.post("/match-results/analyze", response_model=MatchAnalyzeResponse)

async def trigger_match_analysis(

    data: MatchAnalyzeRequest,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")

    try:
        await job_service.validate_resume_owner(
            db, user_id=current_user.id, resume_id=data.resume_id
        )
    except job_service.UserResumeNotFoundError:
        raise HTTPException(status_code=404, detail="Resume not found")



    await emit_system_log_detached(

        category="runtime",

        event_type="match_analysis.started",

        source="jobs",

        severity="info",

        status="running",

        message=f"Match analysis for resume {data.resume_id} started",

        user_id=current_user.id,

        entity_type="resume",

        entity_id=str(data.resume_id),

        payload={"job_ids": data.job_ids},

    )

    result = await analyze_resume_vs_jobs(data.resume_id, data.job_ids)

    await emit_system_log_detached(

        category="runtime",

        event_type="match_analysis.completed",

        source="jobs",

        severity="info",

        status="completed",

        message=f"Match analysis for resume {data.resume_id} completed",

        user_id=current_user.id,

        entity_type="resume",

        entity_id=str(data.resume_id),

        payload={

            "processed": result["processed"],

            "created": result["created"],

            "updated": result["updated"],

            "skipped": result["skipped"],

        },

    )

    return MatchAnalyzeResponse(

        processed=result["processed"],

        created=result["created"],

        updated=result["updated"],

        skipped=result["skipped"],

        items=[_serialize_match_result(item) for item in result["items"]],

    )





@router.post("/match-results/analyze-async")

async def trigger_match_analysis_async(

    data: MatchAnalyzeRequest,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    """Trigger async match analysis, returning task_id for polling.



    The analysis runs in background, updating task progress.

    Poll GET /jobs/tasks/{task_id} for status.

    """



    from app.core.task_registry import create_task



    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")

    try:
        await job_service.validate_resume_owner(
            db, user_id=current_user.id, resume_id=data.resume_id
        )
    except job_service.UserResumeNotFoundError:
        raise HTTPException(status_code=404, detail="Resume not found")



    # Build job_ids list

    job_ids = data.job_ids

    if job_ids is None:

        # Get all active jobs for user
        job_ids = await job_service.list_user_job_ids(db, user_id=current_user.id)



    # Check which jobs actually need analysis

    jobs_to_analyze = await _get_jobs_needing_analysis(db, data.resume_id, job_ids)

    if not jobs_to_analyze:

        return JSONResponse(content={

            "status": "completed",

            "task_id": None,

            "total": 0,

            "reason": "all_up_to_date",

            "message": "所有职位已是最新，无需分析",

        })



    # Create background task with actual count

    task = create_task(

        source="manual",

        user_id=current_user.id,

        entity_type="resume",

        entity_id=str(data.resume_id),

    )

    task.total = len(jobs_to_analyze)



    # Start analysis in background (pass job ids that need analysis)

    asyncio.create_task(

        run_match_analysis_task(task, data.resume_id, [j.id for j in jobs_to_analyze])

    )



    return JSONResponse(content={

        "status": "pending",

        "task_id": task.task_id,

        "total": len(jobs_to_analyze),

        "message": f"分析任务已启动，通过 GET /jobs/tasks/{task.task_id} 查询进度",

    })





@router.get("/tasks/{task_id}")

async def get_match_analysis_task_status(task_id: str):

    """Get status of a match analysis task.



    Returns task progress (total/success/errors) and final results when completed.

    """

    from app.core.task_registry import get_task



    task = get_task(task_id)

    if not task:

        return JSONResponse(

            content={"status": "error", "reason": "task_not_found"},

            status_code=404,

        )



    response = {

        "task_id": task.task_id,

        "status": task.status.value,

        "total": task.total,

        "success": task.success,

        "errors": task.errors,

        "reason": task.reason,

    }



    # Include details when completed

    if task.status.value == "completed":

        response["details"] = task.details



    return JSONResponse(content=response)





@router.get("/configs/{config_id}", response_model=JobSearchConfigResponse)

async def get_config(

    config_id: int,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    """Get a single config."""
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
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

                raise HTTPException(status_code=400, detail=f"Scheduler error: {str(exc)}")



    # Audit log

    ip_address = request.client.host if request.client else ""

    await log_audit(

        db=db,

        action="job_config.update",

        actor_user_id=current_user.id,

        target_type="job_config",

        target_id=config_id,

        details={"name": config.name, "updated_fields": list(update_data.keys())},

        ip_address=ip_address,

        user_agent=request.headers.get("user-agent", "")[:512],

        commit=True,

    )



    return config





@router.delete("/configs/{config_id}")

async def delete_config(

    config_id: int,

    request: Request,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):
    """Delete a config (cascades to jobs)."""
    try:
        config = await job_service.get_job_config(
            db, user_id=current_user.id, config_id=config_id
        )
    except job_service.JobConfigNotFoundError:
        raise HTTPException(status_code=404, detail="Config not found")

    config_info = {"name": config.name}


    # Remove scheduler job before deletion

    scheduler: JobConfigScheduler = getattr(request.app.state, "job_config_scheduler", None)

    if scheduler:
        scheduler.remove_job(config_id)

    await job_service.remove_job_config(db, config=config)


    # Audit log

    ip_address = request.client.host if request.client else ""

    await log_audit(

        db=db,

        action="job_config.delete",

        actor_user_id=current_user.id,

        target_type="job_config",

        target_id=config_id,

        details=config_info,

        ip_address=ip_address,

        user_agent=request.headers.get("user-agent", "")[:512],

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

    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")

    items, total = await job_service.list_jobs(
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



    return JobListResponse(

        items=items,

        total=total,

        page=page,

        page_size=page_size,

    )







# ── Job Crawl Logs ──────────────────────────────────────────────





@router.get("/crawl-logs", response_model=list[JobCrawlLogResponse])

async def get_job_crawl_logs(

    search_config_id: int | None = Query(None, description="Filter by search config ID"),

    status: str | None = Query(None, regex="^(SUCCESS|ERROR)$"),

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

    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")

    try:
        return await job_service.get_job(
            db, user_id=current_user.id, job_id=job_id_str
        )
    except job_service.JobNotFoundError:
        raise HTTPException(status_code=404, detail="Job not found")





# ── Crawl Triggers ───────────────────────────────────────────────



@router.post("/crawl-now")

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





@router.post("/crawl-now/{config_id}")

async def crawl_single(

    config_id: int,

    current_user: User = Depends(require_permission("crawl:execute")),

    db: AsyncSession = Depends(get_db),

):

    """Trigger crawling a single config (async)."""

    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")

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





@router.get("/crawl/status/{task_id}")

async def get_job_crawl_status(task_id: str):

    """Get the status of a job crawl task."""

    task = get_task(task_id)

    if not task:

        return JSONResponse(

            content={"status": "error", "reason": "task_not_found"},

            status_code=404,

        )

    return JSONResponse(content={

        "task_id": task.task_id,

        "status": task.status.value,

        "total": task.total,

        "success": task.success,

        "errors": task.errors,

    })





@router.get("/crawl/result/{task_id}")

async def get_job_crawl_result(task_id: str):

    """Get the final result of a completed job crawl task."""

    task = get_task(task_id)

    if not task:

        return JSONResponse(

            content={"status": "error", "reason": "task_not_found"},

            status_code=404,

        )

    if task.status in (TaskStatus.PENDING, TaskStatus.RUNNING):

        return JSONResponse(

            content={"status": task.status.value, "task_id": task.task_id},

            status_code=202,

        )

    if task.status == TaskStatus.FAILED:

        return JSONResponse(

            content={"status": "error", "task_id": task.task_id, "reason": task.reason},

            status_code=500,

        )

    return JSONResponse(content={

        "status": "completed",

        "task_id": task.task_id,

        "total": task.total,

        "success": task.success,

        "errors": task.errors,

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

            raise HTTPException(status_code=400, detail=f"Scheduler error: {str(exc)}")



    # Audit log

    ip_address = request.client.host if request.client else ""

    await log_audit(

        db=db,

        action="schedule.update",

        actor_user_id=current_user.id,

        target_type="job_config",

        target_id=config.id,

        details={"config_name": config.name, "cron_expression": data.cron_expression},

        ip_address=ip_address,

        user_agent=request.headers.get("user-agent", "")[:512],

        commit=True,

    )



    return config





@router.get("/scheduler/job-configs")

async def get_job_config_schedules(

    request: Request,

    current_user: User = Depends(get_current_user),

    db: AsyncSession = Depends(get_db),

):

    """Get next run times for all per-config job crawl schedules."""

    if not current_user:

        raise HTTPException(status_code=401, detail="请先登录")



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
