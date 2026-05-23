"""Product domain business services."""

from inspect import isawaitable
from urllib.parse import parse_qs, urlparse

from sqlalchemy.ext.asyncio import AsyncSession

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
    ProductUpdate,
)

VALID_PRODUCT_PLATFORMS = ("taobao", "jd", "amazon")


class InvalidPlatformError(ValueError):
    """Raised when a platform is not supported for product operations."""


class ProductNotFoundError(LookupError):
    """Raised when a product cannot be found for the current user."""


class ProductCronConfigConflictError(ValueError):
    """Raised when a platform cron config already exists."""


class ProductCronConfigNotFoundError(LookupError):
    """Raised when a platform cron config cannot be found."""


def normalize_tmall_url(url: str) -> str:
    """Extract id and skuId from Taobao/Tmall URL and rebuild full URL."""
    parsed = urlparse(url)
    params = parse_qs(parsed.query)

    item_id = params.get("id", [None])[0]
    sku_id = params.get("skuId", [None])[0]

    if not item_id:
        return url

    query_parts = [f"id={item_id}"]
    if sku_id:
        query_parts.append(f"skuId={sku_id}")

    return f"{parsed.scheme}://{parsed.netloc}{parsed.path}?{'&'.join(query_parts)}"


def normalize_product_url(url: str, platform: str) -> str:
    if platform == "taobao":
        return normalize_tmall_url(url)
    return url


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

    existing = await repository.get_product_cron_config(
        db, user_id=user_id, platform=data.platform
    )
    if existing:
        raise ProductCronConfigConflictError

    return await repository.create_product_cron_config(
        db,
        user_id=user_id,
        platform=data.platform,
        cron_expression=data.cron_expression,
        cron_timezone=data.cron_timezone,
    )


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
        except Exception as exc:
            results.append(BatchOperationResult(url=url, success=False, error=str(exc)))

    await db.commit()
    return results


async def batch_delete_products(
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
        except Exception as exc:
            results.append(BatchOperationResult(id=product_id, success=False, error=str(exc)))

    try:
        await db.commit()
    except Exception:
        for result_item in results:
            if result_item.success and result_item.id not in found_ids:
                result_item.success = False
                result_item.error = "批量操作失败"
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
        except Exception as exc:
            results.append(BatchOperationResult(id=product_id, success=False, error=str(exc)))

    try:
        await db.commit()
    except Exception as exc:
        for result_item in results:
            if result_item.success:
                result_item.success = False
                result_item.error = str(exc)
        return results

    return results


async def get_product_history(
    db: AsyncSession, *, user_id: int, product_id: int, days: int, limit: int
) -> list[PriceHistory]:
    await get_product(db, user_id=user_id, product_id=product_id)
    return await repository.list_price_history(
        db, product_id=product_id, days=days, limit=limit
    )
