"""Product crawling business services."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import AsyncSessionLocal
from app.domains.crawling import repository

PLATFORM_ADAPTERS = {}


def _get_adapters():
    """Lazy-load adapters to avoid circular imports."""
    global PLATFORM_ADAPTERS
    if not PLATFORM_ADAPTERS:
        from app.platforms import AmazonAdapter, JDAdapter, TaobaoAdapter

        PLATFORM_ADAPTERS.update(
            {
                "taobao": TaobaoAdapter,
                "jd": JDAdapter,
                "amazon": AmazonAdapter,
            }
        )


async def crawl_one(product_id: int) -> dict:
    """Core crawl logic, run in the same event loop as the caller."""
    from app.services.crawl import (
        check_price_alerts,
        save_crawl_log,
        save_price_history,
    )

    _get_adapters()

    async with AsyncSessionLocal() as db:
        product = await repository.get_product(db, product_id=product_id)

        if not product or not product.active:
            return {"status": "skipped", "product_id": product_id}

        adapter_class = PLATFORM_ADAPTERS.get(product.platform)
        if not adapter_class:
            await save_crawl_log(
                product_id,
                product.platform,
                "ERROR",
                error_message=f"Unknown platform: {product.platform}",
            )
            return {"status": "error", "product_id": product_id}

        adapter = adapter_class()

        try:
            result_data = await adapter.crawl(product.url)

            if result_data.get("success"):
                price = Decimal(str(result_data["price"]))
                currency = result_data.get("currency", "CNY")
                scraped_at = datetime.now(UTC)

                await save_price_history(product_id, price, currency, scraped_at)
                await save_crawl_log(
                    product_id, product.platform, "SUCCESS", price=price, currency=currency
                )
                await check_price_alerts(product_id, price)

                new_title = result_data.get("title")
                if new_title and not product.title:
                    product.title = new_title
                    await repository.commit(db)

                return {"status": "success", "product_id": product_id, "price": float(price)}

            await save_crawl_log(
                product_id,
                product.platform,
                "ERROR",
                error_message=result_data.get("error", "Unknown error"),
            )
            return {"status": "error", "product_id": product_id}

        except Exception as e:
            platform_name = product.platform if product else "unknown"
            await save_crawl_log(product_id, platform_name, "ERROR", error_message=str(e))
            return {"status": "error", "product_id": product_id, "error": str(e)}


async def list_crawl_logs(
    db: AsyncSession,
    *,
    user_id: int,
    product_id: int | None,
    status: str | None,
    hours: int,
    limit: int,
):
    cutoff = datetime.now(UTC) - timedelta(hours=hours)
    product_ids = await repository.list_user_product_ids(db, user_id=user_id)
    return await repository.list_crawl_logs(
        db,
        product_ids=product_ids,
        product_id=product_id,
        status=status,
        cutoff=cutoff,
        limit=limit,
    )


async def cleanup_old_data(
    db: AsyncSession, *, user_id: int, retention_days: int
) -> dict:
    days = min(retention_days, settings.data_retention_days)
    cutoff = datetime.now(UTC) - timedelta(days=days)
    product_ids = list(await repository.list_user_product_ids(db, user_id=user_id))

    if not product_ids:
        return {
            "status": "completed",
            "deleted_crawl_logs": 0,
            "deleted_price_history": 0,
            "cutoff_date": cutoff.isoformat(),
            "retention_days": days,
        }

    deleted_logs = await repository.count_old_crawl_logs(
        db, product_ids=product_ids, cutoff=cutoff
    )
    deleted_prices = await repository.count_old_price_history(
        db, product_ids=product_ids, cutoff=cutoff
    )
    await repository.delete_old_data(db, product_ids=product_ids, cutoff=cutoff)

    return {
        "status": "completed",
        "deleted_crawl_logs": deleted_logs,
        "deleted_price_history": deleted_prices,
        "cutoff_date": cutoff.isoformat(),
        "retention_days": days,
    }
