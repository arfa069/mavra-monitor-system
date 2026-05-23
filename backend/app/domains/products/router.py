"""Products API router."""

import logging

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.audit import log_audit
from app.core.permissions import require_permission
from app.core.security import get_current_user
from app.database import get_db
from app.domains.products import service
from app.models.user import User
from app.schemas.price_history import PriceHistoryResponse
from app.schemas.product import (
    BatchOperationResult,
    ProductBatchCreate,
    ProductBatchDelete,
    ProductBatchUpdate,
    ProductCreate,
    ProductListResponse,
    ProductPlatformCronCreate,
    ProductPlatformCronResponse,
    ProductPlatformCronUpdate,
    ProductResponse,
    ProductUpdate,
)
from app.services.scheduler_job import ProductCronScheduler

router = APIRouter(prefix="/products", tags=["products"])
logger = logging.getLogger("app.routers.products")


def _require_user(current_user: User | None) -> User:
    if not current_user:
        raise HTTPException(status_code=401, detail="请先登录")
    return current_user


def _scheduler(request: Request) -> ProductCronScheduler | None:
    return getattr(request.app.state, "product_cron_scheduler", None)


def _scheduler_error(exc: Exception) -> HTTPException:
    return HTTPException(status_code=400, detail=f"Scheduler error: {str(exc)}")


def _not_found_response(exc: service.ProductNotFoundError) -> HTTPException:
    return HTTPException(status_code=404, detail="Product not found")


def _invalid_platform_response(exc: service.InvalidPlatformError) -> HTTPException:
    return HTTPException(status_code=400, detail="Invalid platform")


@router.post("", response_model=ProductResponse)
async def create_product(
    product_data: ProductCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Add a new product to track."""
    user = _require_user(current_user)
    return await service.create_product(db, user_id=user.id, product_data=product_data)


@router.get("", response_model=ProductListResponse)
async def list_products(
    platform: str | None = None,
    active: bool | None = None,
    keyword: str | None = Query(default=None, max_length=200),
    page: int = Query(default=1, ge=1),
    size: int = Query(default=15, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List tracked products with pagination."""
    user = _require_user(current_user)
    return await service.list_products(
        db,
        user_id=user.id,
        platform=platform,
        active=active,
        keyword=keyword,
        page=page,
        size=size,
    )


@router.get("/cron-configs", response_model=list[ProductPlatformCronResponse])
async def list_product_cron_configs(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all per-platform cron configs for product crawling."""
    user = _require_user(current_user)
    return await service.list_product_cron_configs(db, user_id=user.id)


@router.post(
    "/cron-configs", response_model=ProductPlatformCronResponse, status_code=201
)
async def create_product_cron_config(
    data: ProductPlatformCronCreate,
    request: Request,
    current_user: User = Depends(require_permission("schedule:configure")),
    db: AsyncSession = Depends(get_db),
):
    """Create a new per-platform cron config for product crawling."""
    try:
        config = await service.create_product_cron_config(
            db, user_id=current_user.id, data=data
        )
    except service.InvalidPlatformError as exc:
        raise _invalid_platform_response(exc) from exc
    except service.ProductCronConfigConflictError as exc:
        raise HTTPException(
            status_code=409, detail="Platform cron config already exists"
        ) from exc

    scheduler = _scheduler(request)
    if scheduler and config.cron_expression:
        try:
            scheduler.add_job(
                current_user.id,
                config.platform,
                config.cron_expression,
                config.cron_timezone,
            )
        except Exception as exc:
            logger.error("Failed to add job to scheduler: %s", exc)
            raise _scheduler_error(exc) from exc

    await _log_product_cron_audit(
        db=db,
        request=request,
        action="schedule.create",
        actor_user_id=current_user.id,
        target_id=config.id,
        details={"platform": data.platform, "cron_expression": data.cron_expression},
    )
    return config


@router.delete("/cron-configs/{platform}")
async def delete_product_cron_config(
    platform: str,
    request: Request,
    current_user: User = Depends(require_permission("schedule:configure")),
    db: AsyncSession = Depends(get_db),
):
    """Delete a per-platform cron config for product crawling."""
    try:
        config = await service.delete_product_cron_config(
            db, user_id=current_user.id, platform=platform
        )
    except service.InvalidPlatformError as exc:
        raise _invalid_platform_response(exc) from exc
    except service.ProductCronConfigNotFoundError as exc:
        raise HTTPException(
            status_code=404, detail="Platform cron config not found"
        ) from exc

    scheduler = _scheduler(request)
    if scheduler:
        try:
            scheduler.remove_job(current_user.id, platform)
        except Exception as exc:
            logger.error("Failed to remove job from scheduler: %s", exc)
            raise _scheduler_error(exc) from exc

    await service.remove_product_cron_config(db, config=config)

    await _log_product_cron_audit(
        db=db,
        request=request,
        action="schedule.delete",
        actor_user_id=current_user.id,
        target_id=config.id,
        details={"platform": platform},
    )
    return {"message": "Platform cron config deleted"}


@router.patch("/cron-configs/{platform}", response_model=ProductPlatformCronResponse)
async def update_product_cron_config(
    platform: str,
    data: ProductPlatformCronUpdate,
    request: Request,
    current_user: User = Depends(require_permission("schedule:configure")),
    db: AsyncSession = Depends(get_db),
):
    """Update cron expression for a product platform."""
    try:
        config = await service.update_product_cron_config(
            db,
            user_id=current_user.id,
            platform=platform,
            data=data,
        )
    except service.InvalidPlatformError as exc:
        raise _invalid_platform_response(exc) from exc
    except service.ProductCronConfigNotFoundError as exc:
        raise HTTPException(
            status_code=404, detail="Platform cron config not found"
        ) from exc

    scheduler = _scheduler(request)
    if scheduler:
        try:
            if config.cron_expression:
                scheduler.add_job(
                    current_user.id,
                    config.platform,
                    config.cron_expression,
                    config.cron_timezone,
                )
            else:
                scheduler.remove_job(current_user.id, config.platform)
        except Exception as exc:
            logger.error("Failed to sync scheduler: %s", exc)
            raise _scheduler_error(exc) from exc

    await _log_product_cron_audit(
        db=db,
        request=request,
        action="schedule.update",
        actor_user_id=current_user.id,
        target_id=config.id,
        details={"platform": platform, "cron_expression": data.cron_expression},
    )
    return config


@router.get("/cron-schedules")
async def get_product_cron_schedules(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    """Get next run times for the current user's per-platform product crawl schedules."""
    user = _require_user(current_user)
    scheduler = _scheduler(request)
    if not scheduler:
        return {"platforms": {}}
    return {"platforms": scheduler.get_next_run_times(user_id=user.id)}


@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get product details."""
    user = _require_user(current_user)
    try:
        return await service.get_product(db, user_id=user.id, product_id=product_id)
    except service.ProductNotFoundError as exc:
        raise _not_found_response(exc) from exc


@router.patch("/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: int,
    product_data: ProductUpdate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update a product."""
    try:
        product = await service.update_product(
            db,
            user_id=current_user.id,
            product_id=product_id,
            product_data=product_data,
        )
    except service.ProductNotFoundError as exc:
        raise _not_found_response(exc) from exc

    await _log_product_audit(
        db=db,
        request=request,
        action="product.update",
        actor_user_id=current_user.id,
        target_id=product_id,
        details={"title": product.title, "platform": product.platform},
    )
    return product


@router.delete("/{product_id}")
async def delete_product(
    product_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a product and its related data."""
    try:
        product_info = await service.delete_product(
            db, user_id=current_user.id, product_id=product_id
        )
    except service.ProductNotFoundError as exc:
        raise _not_found_response(exc) from exc

    await _log_product_audit(
        db=db,
        request=request,
        action="product.delete",
        actor_user_id=current_user.id,
        target_id=product_id,
        details=product_info,
    )
    return {"message": "Product deleted"}


@router.post("/batch-create", response_model=list[BatchOperationResult])
async def batch_create_products(
    batch: ProductBatchCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Batch create products from URLs."""
    user = _require_user(current_user)
    return await service.batch_create_products(db, user_id=user.id, batch=batch)


@router.post("/batch-delete", response_model=list[BatchOperationResult])
async def batch_delete_products(
    payload: ProductBatchDelete,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Batch delete products by IDs."""
    user = _require_user(current_user)
    return await service.batch_delete_products(db, user_id=user.id, payload=payload)


@router.post("/batch-update", response_model=list[BatchOperationResult])
async def batch_update_products(
    payload: ProductBatchUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Batch update products (active status)."""
    user = _require_user(current_user)
    return await service.batch_update_products(db, user_id=user.id, payload=payload)


@router.get("/{product_id}/history", response_model=list[PriceHistoryResponse])
async def get_product_history(
    product_id: int,
    days: int = Query(default=30, ge=1, le=365),
    limit: int = Query(default=100, ge=1, le=1000),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get price history for a product."""
    user = _require_user(current_user)
    try:
        return await service.get_product_history(
            db,
            user_id=user.id,
            product_id=product_id,
            days=days,
            limit=limit,
        )
    except service.ProductNotFoundError as exc:
        raise _not_found_response(exc) from exc


async def _log_product_audit(
    *,
    db: AsyncSession,
    request: Request,
    action: str,
    actor_user_id: int,
    target_id: int,
    details: dict[str, str | None],
) -> None:
    ip_address = request.client.host if request.client else ""
    await log_audit(
        db=db,
        action=action,
        actor_user_id=actor_user_id,
        target_type="product",
        target_id=target_id,
        details=details,
        ip_address=ip_address,
        user_agent=request.headers.get("user-agent", "")[:512],
        commit=True,
    )


async def _log_product_cron_audit(
    *,
    db: AsyncSession,
    request: Request,
    action: str,
    actor_user_id: int,
    target_id: int,
    details: dict[str, str | None],
) -> None:
    ip_address = request.client.host if request.client else ""
    await log_audit(
        db=db,
        action=action,
        actor_user_id=actor_user_id,
        target_type="product_cron_config",
        target_id=target_id,
        details=details,
        ip_address=ip_address,
        user_agent=request.headers.get("user-agent", "")[:512],
        commit=True,
    )
