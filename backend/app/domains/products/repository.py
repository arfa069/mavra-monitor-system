"""Product domain data access helpers."""

from datetime import UTC, datetime, timedelta
from inspect import isawaitable

from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.price_history import PriceHistory
from app.models.product import Product, ProductPlatformCron


async def create_product(
    db: AsyncSession,
    *,
    user_id: int,
    platform: str,
    url: str,
    title: str | None,
    active: bool,
) -> Product:
    product = Product(
        user_id=user_id,
        platform=platform,
        url=url,
        title=title,
        active=active,
    )
    added = db.add(product)
    if isawaitable(added):
        await added
    await db.commit()
    await db.refresh(product)
    return product


async def list_products(
    db: AsyncSession,
    *,
    user_id: int,
    platform: str | None,
    active: bool | None,
    keyword: str | None,
    page: int,
    size: int,
) -> tuple[list[Product], int]:
    base_query = select(Product).where(Product.user_id == user_id)

    if platform is not None:
        base_query = base_query.where(Product.platform == platform)
    if active is not None:
        base_query = base_query.where(Product.active == active)
    if keyword is not None:
        escaped = keyword.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        kw = f"%{escaped}%"
        base_query = base_query.where(
            (Product.title.ilike(kw, escape="\\"))
            | (Product.url.ilike(kw, escape="\\"))
        )

    count_result = await db.execute(select(func.count()).select_from(base_query.subquery()))
    total = count_result.scalar() or 0

    items_result = await db.execute(
        base_query.order_by(desc(Product.created_at), desc(Product.id))
        .offset((page - 1) * size)
        .limit(size)
    )
    return list(items_result.scalars().all()), total


async def get_product_by_id(
    db: AsyncSession, *, user_id: int, product_id: int
) -> Product | None:
    result = await db.execute(
        select(Product).where(Product.id == product_id, Product.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def list_product_cron_configs(
    db: AsyncSession, *, user_id: int
) -> list[ProductPlatformCron]:
    result = await db.execute(
        select(ProductPlatformCron).where(ProductPlatformCron.user_id == user_id)
    )
    return list(result.scalars().all())


async def get_product_cron_config(
    db: AsyncSession, *, user_id: int, platform: str
) -> ProductPlatformCron | None:
    result = await db.execute(
        select(ProductPlatformCron).where(
            ProductPlatformCron.platform == platform,
            ProductPlatformCron.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def create_product_cron_config(
    db: AsyncSession,
    *,
    user_id: int,
    platform: str,
    cron_expression: str | None,
    cron_timezone: str | None,
    profile_key: str,
) -> ProductPlatformCron:
    config = ProductPlatformCron(
        user_id=user_id,
        platform=platform,
        cron_expression=cron_expression,
        cron_timezone=cron_timezone or "Asia/Shanghai",
        profile_key=profile_key,
    )
    db.add(config)
    await db.commit()
    await db.refresh(config)
    return config


async def update_product_cron_config(
    db: AsyncSession,
    *,
    config: ProductPlatformCron,
    cron_expression: str | None,
    cron_timezone: str | None,
    profile_key: str,
) -> ProductPlatformCron:
    config.cron_expression = cron_expression
    config.cron_timezone = cron_timezone or "Asia/Shanghai"
    config.profile_key = profile_key
    await db.commit()
    await db.refresh(config)
    return config


async def delete_product_cron_config(
    db: AsyncSession, *, config: ProductPlatformCron
) -> None:
    await db.delete(config)
    await db.commit()


async def get_existing_urls(
    db: AsyncSession, *, user_id: int, urls: set[str]
) -> set[str]:
    if not urls:
        return set()
    result = await db.execute(
        select(Product.url).where(Product.url.in_(list(urls)), Product.user_id == user_id)
    )
    return set(result.scalars().all())


async def list_products_by_ids(
    db: AsyncSession, *, user_id: int, product_ids: list[int]
) -> dict[int, Product]:
    result = await db.execute(
        select(Product).where(Product.id.in_(product_ids), Product.user_id == user_id)
    )
    return {product.id: product for product in result.scalars().all()}


async def list_price_history(
    db: AsyncSession, *, product_id: int, days: int, limit: int
) -> list[PriceHistory]:
    cutoff = datetime.now(UTC) - timedelta(days=days)
    result = await db.execute(
        select(PriceHistory)
        .where(
            PriceHistory.product_id == product_id,
            PriceHistory.scraped_at >= cutoff,
        )
        .order_by(desc(PriceHistory.scraped_at))
        .limit(limit)
    )
    return list(result.scalars().all())
