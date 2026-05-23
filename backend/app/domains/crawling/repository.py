"""Product crawling data access helpers."""

from datetime import datetime

from sqlalchemy import delete, desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.crawl_log import CrawlLog
from app.models.price_history import PriceHistory
from app.models.product import Product


async def get_product(db: AsyncSession, *, product_id: int) -> Product | None:
    result = await db.execute(select(Product).where(Product.id == product_id))
    return result.scalar_one_or_none()


async def commit(db: AsyncSession) -> None:
    await db.commit()


async def list_user_product_ids(db: AsyncSession, *, user_id: int) -> set[int]:
    result = await db.execute(select(Product.id).where(Product.user_id == user_id))
    return set(result.scalars().all())


async def list_crawl_logs(
    db: AsyncSession,
    *,
    product_ids: set[int],
    product_id: int | None,
    status: str | None,
    cutoff: datetime,
    limit: int,
) -> list[CrawlLog]:
    query = select(CrawlLog).where(CrawlLog.timestamp >= cutoff)

    if product_id is not None:
        query = query.where(CrawlLog.product_id == product_id)
    if status is not None:
        query = query.where(CrawlLog.status == status.upper())

    result = await db.execute(query.order_by(desc(CrawlLog.timestamp)).limit(limit))
    logs = result.scalars().all()
    return [log for log in logs if log.product_id in product_ids]


async def count_old_crawl_logs(
    db: AsyncSession, *, product_ids: list[int], cutoff: datetime
) -> int:
    result = await db.execute(
        select(CrawlLog.id).where(
            CrawlLog.timestamp < cutoff,
            CrawlLog.product_id.in_(product_ids),
        )
    )
    return len(list(result.scalars().all()))


async def count_old_price_history(
    db: AsyncSession, *, product_ids: list[int], cutoff: datetime
) -> int:
    result = await db.execute(
        select(PriceHistory.id).where(
            PriceHistory.scraped_at < cutoff,
            PriceHistory.product_id.in_(product_ids),
        )
    )
    return len(list(result.scalars().all()))


async def delete_old_data(
    db: AsyncSession, *, product_ids: list[int], cutoff: datetime
) -> None:
    await db.execute(
        delete(CrawlLog).where(
            CrawlLog.timestamp < cutoff,
            CrawlLog.product_id.in_(product_ids),
        )
    )
    await db.execute(
        delete(PriceHistory).where(
            PriceHistory.scraped_at < cutoff,
            PriceHistory.product_id.in_(product_ids),
        )
    )
    await db.commit()
