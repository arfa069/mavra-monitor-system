"""FastAPI application entry point."""
import asyncio
import logging
import sys
from contextlib import asynccontextmanager

# Windows requires ProactorEventLoop for subprocess support (Playwright spawns browser drivers)
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

import redis.asyncio as redis
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.config import settings
from app.core.security import decode_access_token
from app.core.system_log import emit_system_log_detached
from app.database import engine
from app.domains.admin import admin_router
from app.domains.admin import router as admin_users_router
from app.domains.alerts import router as alerts_router
from app.domains.auth import router as auth_router
from app.domains.auth.wechat_router import router as wechat_router
from app.domains.config import router as config_router
from app.domains.crawling import router as crawl_router
from app.domains.crawling.profile_router import router as profile_router
from app.domains.dashboard import router as dashboard_router
from app.domains.events import router as events_router
from app.domains.jobs import router as jobs_router
from app.domains.products import router as products_router
from app.domains.scheduling import router as scheduling_router

logger = logging.getLogger(__name__)


def _is_event_center_path(path: str) -> bool:
    return path == "/events" or path.startswith((
        "/events/",
        "/v1/events",
        "/api/v1/events",
    ))


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
    yield
    # Shutdown: stop scheduler gracefully
    await _stop_scheduler(app)
    # Close database engine connections
    await engine.dispose()
    # Close Redis connection
    await app.state.redis_client.aclose()


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

    scheduler.start()
    logger.info("APScheduler started")
    await emit_system_log_detached(
        category="platform",
        event_type="scheduler.started",
        source="app.startup",
        severity="info",
        status="success",
        message="APScheduler started",
        entity_type="scheduler",
        entity_id="apscheduler",
    )


async def _stop_scheduler(app: FastAPI) -> None:
    """Gracefully shutdown APScheduler."""
    scheduler = getattr(app.state, "scheduler", None)
    if scheduler and scheduler.running:
        scheduler.shutdown(wait=True)
        logger.info("APScheduler shutdown complete")
        await emit_system_log_detached(
            category="platform",
            event_type="scheduler.stopped",
            source="app.shutdown",
            severity="info",
            status="success",
            message="APScheduler shutdown complete",
            entity_type="scheduler",
            entity_id="apscheduler",
        )


app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
    lifespan=lifespan,
)

# CORS middleware - restrict origins in production
_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_ALLOWED_ORIGINS,
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
    events_router,
    admin_users_router,
    admin_router,
    dashboard_router,
    scheduling_router,
    profile_router,
)


def _include_application_routers(prefix: str = "") -> None:
    for router in _APPLICATION_ROUTERS:
        app.include_router(router, prefix=prefix)


# Include legacy routes and v1 routes. The frontend dev proxy strips /api, so
# /api/v1/... in the browser reaches /v1/... on the backend.
_include_application_routers()
app.include_router(crawl_router, prefix="/products")
_include_application_routers(prefix="/v1")
app.include_router(crawl_router, prefix="/v1")
_include_application_routers(prefix="/api/v1")
app.include_router(crawl_router, prefix="/api/v1")


@app.get("/v1")
@app.get("/api/v1")
async def api_root():
    """Public API root for clients/probes that open the API base URL."""
    return {
        "name": settings.app_name,
        "status": "ok",
        "docs": "/docs",
        "prefixes": ["/v1", "/api/v1"],
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
            await emit_system_log_detached(
                category="platform",
                event_type="http.500",
                source=path,
                severity="error",
                status="error",
                message=f"{method} {path} raised an unhandled exception",
                user_id=user_id,
                entity_type="request",
                entity_id=path,
                payload={"method": method, "path": path, "error": str(exc)},
            )
        raise

    if not _is_event_center_path(path) and response.status_code in (401, 403):
        await emit_system_log_detached(
            category="platform",
            event_type=f"http.{response.status_code}",
            source=path,
            severity="warning",
            status="denied",
            message=f"{method} {path} was denied",
            user_id=user_id,
            entity_type="request",
            entity_id=path,
            payload={"method": method, "path": path, "status_code": response.status_code},
        )
    elif not _is_event_center_path(path) and response.status_code >= 500:
        await emit_system_log_detached(
            category="platform",
            event_type=f"http.{response.status_code}",
            source=path,
            severity="error",
            status="error",
            message=f"{method} {path} returned server error",
            user_id=user_id,
            entity_type="request",
            entity_id=path,
            payload={"method": method, "path": path, "status_code": response.status_code},
        )

    return response

@app.get("/health")
async def health_check():
    """Public health check. Returns only overall status to avoid leaking internals.

    Detailed component status is intentionally not exposed; admins should
    inspect logs / /scheduler/status (admin-gated) instead.
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
