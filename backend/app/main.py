"""FastAPI application entry point."""
import logging
from contextlib import asynccontextmanager
from uuid import uuid4

import redis.asyncio as redis
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.config import settings
from app.core.openapi import generate_operation_id
from app.core.security import decode_access_token
from app.core.system_log import emit_system_log_detached
from app.database import engine
from app.domains.admin import admin_router
from app.domains.admin import router as admin_users_router
from app.domains.alerts import router as alerts_router
from app.domains.auth import router as auth_router
from app.domains.auth.wechat_router import router as wechat_router
from app.domains.blog import media_router as blog_media_router
from app.domains.blog import router as blog_router
from app.domains.config import router as config_router
from app.domains.crawling import router as crawl_router
from app.domains.crawling.profile_router import router as profile_router
from app.domains.dashboard import router as dashboard_router
from app.domains.events import router as events_router
from app.domains.jobs import router as jobs_router
from app.domains.products import router as products_router
from app.domains.scheduling import router as scheduling_router
from app.domains.smart_home import router as smart_home_router
from app.schemas.runtime_api import HealthResponse, ServiceInfoResponse

logger = logging.getLogger(__name__)


API_PREFIX = "/api/v1"


def _is_event_center_path(path: str) -> bool:
    event_prefix = f"{API_PREFIX}/events"
    return path == event_prefix or path.startswith(f"{event_prefix}/")


async def recover_crawler_runtime_state() -> None:
    """Mark stale running tasks as failed and release expired profile leases on startup."""
    from app.database import AsyncSessionLocal
    from app.domains.crawling.profile_pool import recover_stale_profile_leases
    from app.domains.crawling.task_store import recover_stale_running_tasks

    async with AsyncSessionLocal() as db:
        recovered_tasks = await recover_stale_running_tasks(
            db,
            owner_reason="worker_restarted",
        )
        recovered_profiles = await recover_stale_profile_leases(db)

    if recovered_tasks or recovered_profiles:
        logger.warning(
            "Recovered crawler runtime state: %d stale tasks, %d stale profile leases",
            recovered_tasks,
            recovered_profiles,
        )
        await emit_system_log_detached(
            category="runtime",
            event_type="crawler_runtime.recovered",
            source="crawler",
            severity="warning",
            status="completed",
            message="Recovered stale crawler runtime state",
            payload={"stale_tasks": recovered_tasks, "stale_profile_leases": recovered_profiles},
        )


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    # Startup
    app.state.redis_client = redis.from_url(settings.redis_url_with_password)
    await recover_crawler_runtime_state()
    await _start_scheduler(app)
    # Signal that all startup tasks completed successfully.
    # /health reads this flag directly — no DB/Redis round-trip on every probe.
    app.state.ready = True
    yield
    # Shutdown
    app.state.ready = False
    await _stop_scheduler(app)
    # Close database engine connections
    await engine.dispose()
    # Close Redis connection
    await app.state.redis_client.aclose()


async def _emit_scheduler_event(event_type: str, message: str) -> None:
    await emit_system_log_detached(
        category="platform",
        event_type=event_type,
        source="app.startup" if "started" in event_type else "app.shutdown",
        severity="info",
        status="success",
        message=message,
        entity_type="scheduler",
        entity_id="apscheduler",
    )


async def publish_due_blog_posts_job() -> int:
    """Publish scheduled blog posts whose publish time has arrived."""
    from app.database import AsyncSessionLocal
    from app.domains.blog.service import publish_due_posts

    async with AsyncSessionLocal() as db:
        published_count = await publish_due_posts(db)
    if published_count:
        logger.info("Published %d scheduled blog posts", published_count)
    return published_count


async def _emit_http_event(
    event_type: str,
    path: str,
    method: str,
    severity: str,
    status: str,
    message: str,
    user_id: int | None,
    status_code: int | None = None,
    **extra_payload: object,
) -> None:
    payload: dict[str, object] = {"method": method, "path": path}
    if status_code is not None:
        payload["status_code"] = status_code
    payload.update(extra_payload)
    await emit_system_log_detached(
        category="platform",
        event_type=event_type,
        source=path,
        severity=severity,
        status=status,
        message=message,
        user_id=user_id,
        entity_type="request",
        entity_id=path,
        payload=payload,
    )


async def _start_scheduler(app: FastAPI) -> None:
    """Initialize APScheduler with AsyncIOScheduler and register cron job from DB config."""

    from apscheduler.schedulers.asyncio import AsyncIOScheduler

    scheduler = AsyncIOScheduler(timezone="UTC", job_defaults={"coalesce": True, "max_instances": 1})
    app.state.scheduler = scheduler

    # 职位爬取使用 per-config 独立 cron 调度
    from app.domains.jobs.scheduler import JobConfigScheduler
    from app.domains.products.scheduler import ProductCronScheduler
    job_config_scheduler = JobConfigScheduler(scheduler)
    app.state.job_config_scheduler = job_config_scheduler
    await job_config_scheduler.sync_all()

    # 商品爬取使用 per-platform 独立 cron 调度
    product_cron_scheduler = ProductCronScheduler(scheduler)
    app.state.product_cron_scheduler = product_cron_scheduler
    await product_cron_scheduler.sync_all()

    scheduler.add_job(
        publish_due_blog_posts_job,
        "interval",
        minutes=1,
        id="blog_publish_due_posts",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )

    scheduler.start()
    logger.info("APScheduler started")
    await _emit_scheduler_event("scheduler.started", "APScheduler started")


async def _stop_scheduler(app: FastAPI) -> None:
    """Gracefully shutdown APScheduler."""
    scheduler = getattr(app.state, "scheduler", None)
    if scheduler and scheduler.running:
        scheduler.shutdown(wait=True)
        logger.info("APScheduler shutdown complete")
        await _emit_scheduler_event("scheduler.stopped", "APScheduler shutdown complete")


app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
    lifespan=lifespan,
    generate_unique_id_function=generate_operation_id,
)

# CORS middleware - restrict origins in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

_APPLICATION_ROUTERS = (
    config_router,
    products_router,
    alerts_router,
    jobs_router,
    auth_router,
    wechat_router,
    blog_router,
    events_router,
    admin_users_router,
    admin_router,
    dashboard_router,
    scheduling_router,
    profile_router,
    smart_home_router,
)


def _include_application_routers() -> None:
    for router in _APPLICATION_ROUTERS:
        app.include_router(router, prefix=API_PREFIX)


_include_application_routers()
app.include_router(crawl_router, prefix=API_PREFIX)
app.include_router(blog_media_router)


def _trace_id_for_request(request: Request) -> str:
    return (
        request.headers.get("x-request-id")
        or request.headers.get("x-correlation-id")
        or uuid4().hex
    )


def _help_url(code: str) -> str:
    return f"/docs/errors/{code}"


def _http_error_code(status_code: int) -> str:
    if status_code == 401:
        return "session_expired"
    if status_code == 403:
        return "forbidden"
    if status_code == 404:
        return "not_found"
    if status_code >= 500:
        return "server_error"
    return f"http_{status_code}"


def _string_detail(detail: object, fallback: str) -> str:
    if isinstance(detail, str) and detail:
        return detail
    return fallback


def _error_envelope(
    *,
    request: Request,
    code: str,
    message: str,
    details: dict | None = None,
    detail: object | None = None,
) -> dict:
    payload = {
        "code": code,
        "message": message,
        "details": details or {},
        "trace_id": _trace_id_for_request(request),
        "help_url": _help_url(code),
    }
    if detail is not None:
        payload["detail"] = detail
    return payload


def _validation_details(exc: RequestValidationError) -> dict:
    fields = []
    for error in exc.errors():
        path = ".".join(str(part) for part in error.get("loc", ()))
        fields.append(
            {
                "path": path,
                "message": error.get("msg", "Invalid value"),
                "type": error.get("type", "validation_error"),
            }
        )
    return {"fields": fields}


@app.exception_handler(RequestValidationError)
async def request_validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    code = "validation_error"
    details = _validation_details(exc)
    return JSONResponse(
        status_code=422,
        content=_error_envelope(
            request=request,
            code=code,
            message="请求参数有误，请检查表单字段。",
            details=details,
            detail=exc.errors(),
        ),
    )


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(
    request: Request,
    exc: StarletteHTTPException,
) -> JSONResponse:
    code = _http_error_code(exc.status_code)
    if exc.status_code == 401:
        message = "登录状态已过期；如果刷新会话失败，请重新登录。"
    elif exc.status_code == 404:
        message = "请求的资源不存在。"
    elif exc.status_code >= 500:
        message = _string_detail(exc.detail, "服务暂时不可用，请稍后重试。")
    else:
        message = _string_detail(exc.detail, "请求无法完成。")
    return JSONResponse(
        status_code=exc.status_code,
        headers=getattr(exc, "headers", None),
        content=_error_envelope(
            request=request,
            code=code,
            message=message,
            detail=exc.detail,
        ),
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    code = "internal_error"
    logger.exception("Unhandled API exception for %s", request.url.path)
    return JSONResponse(
        status_code=500,
        content=_error_envelope(
            request=request,
            code=code,
            message="服务暂时不可用，请稍后重试。",
            detail="Internal Server Error",
        ),
    )


@app.get(API_PREFIX, response_model=ServiceInfoResponse)
async def api_root():
    return {
        "name": settings.app_name,
        "status": "ok",
        "docs": "/docs",
        "prefixes": [API_PREFIX],
    }


def _extract_token_user_id(request: Request) -> int | None:
    """Best-effort decode of bearer token for platform logging."""
    token: str | None = None
    auth_header = request.headers.get("authorization")
    if auth_header and auth_header.lower().startswith("bearer "):
        token = auth_header[7:]
    elif request.query_params.get("token"):
        token = request.query_params.get("token")
    if not token:
        return None
    payload = decode_access_token(token)
    if payload is None or payload.get("sub") is None:
        return None
    try:
        return int(payload["sub"])
    except (TypeError, ValueError):
        return None


@app.middleware("http")
async def platform_event_logging_middleware(request: Request, call_next):
    """Capture platform-level denied/error responses as structured events."""
    user_id = _extract_token_user_id(request)
    path = request.url.path
    method = request.method

    try:
        response = await call_next(request)
    except Exception as exc:
        if not _is_event_center_path(path):
            await _emit_http_event(
                "http.500",
                path,
                method,
                "error",
                "error",
                f"{method} {path} raised an unhandled exception",
                user_id,
                error=str(exc),
            )
        raise

    if not _is_event_center_path(path) and response.status_code in (401, 403):
        await _emit_http_event(
            f"http.{response.status_code}",
            path,
            method,
            "warning",
            "denied",
            f"{method} {path} was denied",
            user_id,
            status_code=response.status_code,
        )
    elif not _is_event_center_path(path) and response.status_code >= 500:
        await _emit_http_event(
            f"http.{response.status_code}",
            path,
            method,
            "error",
            "error",
            f"{method} {path} returned server error",
            user_id,
            status_code=response.status_code,
        )

    return response

@app.get(
    "/health",
    response_model=HealthResponse,
    responses={503: {"model": HealthResponse}},
)
async def health_check():
    """Lightweight liveness probe — reads an in-memory flag set during startup.

    This endpoint is intended for load-balancer / k8s liveness checks and must
    respond in <5ms. It does NOT perform DB or Redis round-trips.

    For a full DB+Redis readiness check use GET /health/detailed (admin-only).
    """
    ready = getattr(app.state, "ready", False)
    if not ready:
        from fastapi import Response
        return Response(content='{"status":"starting"}', status_code=503, media_type="application/json")
    return {"status": "healthy"}


@app.get("/health/detailed", response_model=HealthResponse)
async def health_check_detailed():
    """Deep readiness probe — verifies DB and Redis connectivity.

    Intended for internal monitoring / admin dashboards only.
    Not exposed via the public load-balancer path.
    """
    healthy = True

    # Database check
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception:
        healthy = False

    # Redis check
    try:
        redis_client = getattr(app.state, "redis_client", None)
        if redis_client is None:
            healthy = False
        else:
            await redis_client.ping()
    except Exception:
        healthy = False

    return {"status": "healthy" if healthy else "unhealthy"}


if __name__ == "__main__":
    import uvicorn
    # Do NOT use reload=True on Windows — it breaks Playwright subprocess creation
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000)
