"""Product domain business services."""

from inspect import isawaitable

from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.ext.asyncio import AsyncSession

from app.domains.crawling.profile_service import CrawlProfileNotFoundError, get_profile
from app.domains.products import repository
from app.models.price_history import PriceHistory
from app.models.product import Product, ProductPlatformCron
from app.schemas.product import (
    BatchOperationResult,
    ProductBatchCreate,
    ProductBatchDelete,
    ProductBatchUpdate,
    ProductCreate,
    ProductListResponse,
    ProductPlatformCronCreate,
    ProductPlatformCronUpdate,
    ProductPlatformProfileBindingResponse,
    ProductPlatformProfileBindingUpdate,
    ProductUpdate,
)
from app.utils.url import normalize_product_url

VALID_PRODUCT_PLATFORMS = ("taobao", "jd", "amazon")


class InvalidPlatformError(ValueError):
    """Raised when a platform is not supported for product operations."""


class ProductNotFoundError(LookupError):
    """Raised when a product cannot be found for the current user."""


class ProductCronConfigConflictError(ValueError):
    """Raised when a platform cron config already exists."""


class ProductCronConfigNotFoundError(LookupError):
    """Raised when a platform cron config cannot be found."""


class ProductProfileConfigError(ValueError):
    """Raised when a product platform profile binding is invalid."""


def _mark_batch_failed(results: list[BatchOperationResult], error: str) -> None:
    """Mark all successful batch results as failed with the given error."""
    for result in results:
        if result.success:
            result.success = False
            result.error = error


def detect_platform(url: str) -> str | None:
    url_lower = url.lower()
    if "jd.com" in url_lower or "item.jd" in url_lower:
        return "jd"
    if "taobao.com" in url_lower or "tmall.com" in url_lower:
        return "taobao"
    if "amazon." in url_lower:
        return "amazon"
    return None


async def create_product(
    db: AsyncSession, *, user_id: int, product_data: ProductCreate
) -> Product:
    return await repository.create_product(
        db,
        user_id=user_id,
        platform=product_data.platform,
        url=normalize_product_url(product_data.url, product_data.platform),
        title=product_data.title,
        active=product_data.active,
    )


async def list_products(
    db: AsyncSession,
    *,
    user_id: int,
    platform: str | None,
    active: bool | None,
    keyword: str | None,
    page: int,
    size: int,
) -> ProductListResponse:
    items, total = await repository.list_products(
        db,
        user_id=user_id,
        platform=platform,
        active=active,
        keyword=keyword,
        page=page,
        size=size,
    )
    total_pages = (total + size - 1) // size if total > 0 else 0
    return ProductListResponse(
        items=items,
        total=total,
        page=page,
        page_size=size,
        total_pages=total_pages,
        has_next=page < total_pages,
        has_prev=page > 1,
    )


async def get_product(db: AsyncSession, *, user_id: int, product_id: int) -> Product:
    product = await repository.get_product_by_id(
        db, user_id=user_id, product_id=product_id
    )
    if product is None:
        raise ProductNotFoundError
    return product


async def update_product(
    db: AsyncSession, *, user_id: int, product_id: int, product_data: ProductUpdate
) -> Product:
    product = await get_product(db, user_id=user_id, product_id=product_id)
    for field, value in product_data.model_dump(exclude_unset=True).items():
        setattr(product, field, value)

    await db.commit()
    await db.refresh(product)
    return product


async def delete_product(
    db: AsyncSession, *, user_id: int, product_id: int
) -> dict[str, str | None]:
    product = await get_product(db, user_id=user_id, product_id=product_id)
    product_info = {"title": product.title, "platform": product.platform}
    await db.delete(product)
    await db.commit()
    return product_info


async def list_product_cron_configs(
    db: AsyncSession, *, user_id: int
) -> list[ProductPlatformCron]:
    return await repository.list_product_cron_configs(db, user_id=user_id)


async def create_product_cron_config(
    db: AsyncSession, *, user_id: int, data: ProductPlatformCronCreate
) -> ProductPlatformCron:
    if data.platform not in VALID_PRODUCT_PLATFORMS:
        raise InvalidPlatformError

    try:
        return await repository.create_product_cron_config(
            db,
            user_id=user_id,
            platform=data.platform,
            cron_expression=data.cron_expression,
            cron_timezone=data.cron_timezone,
            profile_key=None,
        )
    except IntegrityError:
        await db.rollback()
        raise ProductCronConfigConflictError


async def update_product_cron_config(
    db: AsyncSession,
    *,
    user_id: int,
    platform: str,
    data: ProductPlatformCronUpdate,
) -> ProductPlatformCron:
    if platform not in VALID_PRODUCT_PLATFORMS:
        raise InvalidPlatformError

    config = await repository.get_product_cron_config(
        db, user_id=user_id, platform=platform
    )
    if not config:
        raise ProductCronConfigNotFoundError

    return await repository.update_product_cron_config(
        db,
        config=config,
        cron_expression=data.cron_expression,
        cron_timezone=data.cron_timezone,
        profile_key=None,
    )


async def delete_product_cron_config(
    db: AsyncSession, *, user_id: int, platform: str
) -> ProductPlatformCron:
    if platform not in VALID_PRODUCT_PLATFORMS:
        raise InvalidPlatformError

    config = await repository.get_product_cron_config(
        db, user_id=user_id, platform=platform
    )
    if not config:
        raise ProductCronConfigNotFoundError

    return config


async def remove_product_cron_config(
    db: AsyncSession, *, config: ProductPlatformCron
) -> None:
    await repository.delete_product_cron_config(db, config=config)


async def list_product_profile_bindings(
    db: AsyncSession, *, user_id: int
) -> list[ProductPlatformProfileBindingResponse]:
    bindings = await repository.list_product_profile_bindings(db, user_id=user_id)
    binding_by_platform = {binding.platform: binding for binding in bindings}
    profiles = await repository.list_crawl_profiles_by_keys(
        db,
        profile_keys={binding.profile_key for binding in bindings},
    )

    response: list[ProductPlatformProfileBindingResponse] = []
    for platform in VALID_PRODUCT_PLATFORMS:
        binding = binding_by_platform.get(platform)
        if binding is None:
            response.append(ProductPlatformProfileBindingResponse(platform=platform))
            continue

        profile = profiles.get(binding.profile_key)
        response.append(
            ProductPlatformProfileBindingResponse(
                platform=platform,
                profile_key=binding.profile_key,
                profile_status=profile.status if profile else None,
                profile_last_error=profile.last_error if profile else None,
                created_at=binding.created_at,
                updated_at=binding.updated_at,
            )
        )
    return response


async def upsert_product_profile_binding(
    db: AsyncSession,
    *,
    user_id: int,
    platform: str,
    data: ProductPlatformProfileBindingUpdate,
) -> ProductPlatformProfileBindingResponse:
    if platform not in VALID_PRODUCT_PLATFORMS:
        raise InvalidPlatformError
    try:
        profile = await get_profile(db, data.profile_key)
    except CrawlProfileNotFoundError as exc:
        raise ProductProfileConfigError(f"Unknown crawl profile: {data.profile_key}") from exc

    binding = await repository.upsert_product_profile_binding(
        db,
        user_id=user_id,
        platform=platform,
        profile_key=profile.profile_key,
    )
    return ProductPlatformProfileBindingResponse(
        platform=binding.platform,
        profile_key=binding.profile_key,
        profile_status=profile.status,
        profile_last_error=profile.last_error,
        created_at=binding.created_at,
        updated_at=binding.updated_at,
    )


async def delete_product_profile_binding(
    db: AsyncSession, *, user_id: int, platform: str
) -> None:
    if platform not in VALID_PRODUCT_PLATFORMS:
        raise InvalidPlatformError
    binding = await repository.get_product_profile_binding(
        db,
        user_id=user_id,
        platform=platform,
    )
    if binding is not None:
        await repository.delete_product_profile_binding(db, binding=binding)


async def batch_create_products(
    db: AsyncSession, *, user_id: int, batch: ProductBatchCreate
) -> list[BatchOperationResult]:
    results: list[BatchOperationResult] = []
    seen_urls: set[str] = set()
    deduped_items = []

    for item in batch.items:
        url = item.url.strip()
        if url in seen_urls:
            results.append(BatchOperationResult(url=url, success=False, error="重复的 URL"))
            continue
        seen_urls.add(url)
        deduped_items.append(item)

    existing_urls = await repository.get_existing_urls(db, user_id=user_id, urls=seen_urls)

    for item in deduped_items:
        url = item.url.strip()
        if url in existing_urls:
            results.append(BatchOperationResult(url=url, success=False, error="该 URL 已存在"))
            continue
        if not (url.startswith("http://") or url.startswith("https://")):
            results.append(
                BatchOperationResult(url=url, success=False, error="URL 格式不正确")
            )
            continue

        platform = item.platform if item.platform else detect_platform(url)
        if not platform:
            results.append(BatchOperationResult(url=url, success=False, error="无法识别平台"))
            continue

        try:
            normalized_url = normalize_product_url(url, platform)
            product = Product(
                user_id=user_id,
                platform=platform,
                url=normalized_url,
                title=item.title,
                active=True,
            )
            added = db.add(product)
            if isawaitable(added):
                await added
            await db.flush()
            results.append(
                BatchOperationResult(id=product.id, url=normalized_url, success=True)
            )
        except (IntegrityError, OperationalError, ValueError) as exc:
            results.append(BatchOperationResult(url=url, success=False, error=str(exc)))

    try:
        await db.commit()
    except (IntegrityError, OperationalError) as exc:
        _mark_batch_failed(results, f"批量创建失败: {exc}")
        raise
    return results


async def batch_delete_products (
    db: AsyncSession, *, user_id: int, payload: ProductBatchDelete
) -> list[BatchOperationResult]:
    results: list[BatchOperationResult] = []
    product_map = await repository.list_products_by_ids(
        db, user_id=user_id, product_ids=payload.ids
    )
    found_ids = set(product_map.keys())

    for product_id in payload.ids:
        if product_id not in found_ids:
            results.append(
                BatchOperationResult(id=product_id, success=False, error="商品不存在")
            )
            continue
        try:
            await db.delete(product_map[product_id])
            results.append(BatchOperationResult(id=product_id, success=True))
        except (IntegrityError, OperationalError) as exc:
            results.append(BatchOperationResult(id=product_id, success=False, error=str(exc)))

    try:
        await db.commit()
    except (IntegrityError, OperationalError) as exc:
        _mark_batch_failed(results, f"批量删除失败: {exc}")
        raise

    return results


async def batch_update_products(
    db: AsyncSession, *, user_id: int, payload: ProductBatchUpdate
) -> list[BatchOperationResult]:
    results: list[BatchOperationResult] = []
    product_map = await repository.list_products_by_ids(
        db, user_id=user_id, product_ids=payload.ids
    )
    found_ids = set(product_map.keys())

    for product_id in payload.ids:
        if product_id not in found_ids:
            results.append(
                BatchOperationResult(id=product_id, success=False, error="商品不存在")
            )
            continue
        try:
            if payload.active is not None:
                product_map[product_id].active = payload.active
            results.append(BatchOperationResult(id=product_id, success=True))
        except (IntegrityError, OperationalError, ValueError) as exc:
            results.append(BatchOperationResult(id=product_id, success=False, error=str(exc)))

    try:
        await db.commit()
    except (IntegrityError, OperationalError) as exc:
        _mark_batch_failed(results, f"批量更新失败: {exc}")
        raise

    return results


async def get_product_history(
    db: AsyncSession, *, user_id: int, product_id: int, days: int, limit: int
) -> list[PriceHistory]:
    await get_product(db, user_id=user_id, product_id=product_id)
    return await repository.list_price_history(
        db, product_id=product_id, days=days, limit=limit
    )
