"""Product crawling business services."""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import AsyncSessionLocal
from app.domains.crawling import repository
from app.domains.crawling.browser_manager import BrowserSession
from app.integrations.feishu import send_feishu_notification
from app.models.alert import Alert
from app.models.crawl_log import CrawlLog
from app.models.price_history import PriceHistory
from app.models.product import Product
from app.models.user import User

# Deferred import to avoid circular dependency
_browser_manager = None

PLATFORM_ADAPTERS = {}
logger = logging.getLogger(__name__)


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


async def _emit_page_timeout_event(session: BrowserSession) -> None:
    from app.core.system_log import emit_system_log_detached

    await emit_system_log_detached(
        category="runtime",
        event_type="product_browser.page_timeout",
        source="crawler",
        severity="warning",
        status="failed",
        message=f"Product page timed out for {session.profile_key}",
        entity_type="crawl_profile",
        entity_id=session.profile_key,
        payload={"profile_key": session.profile_key, "platform": session.platform},
    )


async def _persist_product_crawl_result(
    db: AsyncSession,
    *,
    product: Product,
    result_data: dict,
) -> dict:
    """Persist crawl result to price history and crawl log."""
    if result_data.get("success"):
        price = Decimal(str(result_data["price"]))
        currency = result_data.get("currency", "CNY")
        scraped_at = datetime.now(UTC)

        await save_price_history(product_id=product.id, price=price, currency=currency, scraped_at=scraped_at)
        await save_crawl_log(
            product.id, product.platform, "SUCCESS", price=price, currency=currency
        )
        await check_price_alerts(product.id, price)

        new_title = result_data.get("title")
        if new_title and not product.title:
            product.title = new_title
            await repository.commit(db)

        return {"status": "success", "product_id": product.id, "price": float(price)}

    error_msg = result_data.get("error", "Unknown error")
    await save_crawl_log(
        product.id, product.platform, "ERROR", error_message=error_msg
    )
    return {"status": "error", "product_id": product.id}


async def crawl_one_with_session(
    *,
    product_id: int,
    session: BrowserSession,
) -> dict:
    """Crawl a single product using a BrowserManager session."""
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
        page = await session.new_page()
        try:
            result_data = await adapter.crawl_with_page(product.url, page)
            if not result_data.get("success"):
                error_message = str(result_data.get("error", ""))
                if "timeout" in error_message.lower():
                    await _emit_page_timeout_event(session)
                # Check for login wall / anti-bot before closing page
                try:
                    page_url = page.url
                    page_content = await page.content()
                    failure_type = adapter.classify_failure(page_url, page_content)
                    if failure_type == "login_required":
                        from app.core.system_log import emit_system_log_detached
                        from app.domains.crawling.profile_pool import LOGIN_REQUIRED
                        from app.domains.crawling.profile_service import update_profile

                        await update_profile(
                            db,
                            profile_key=session.profile_key,
                            status=LOGIN_REQUIRED,
                            platform_hint=session.platform,
                            last_error=f"{product.platform} login required for {product.url}",
                        )
                        await emit_system_log_detached(
                            category="runtime",
                            event_type="product_profile.login_required",
                            source="crawler",
                            severity="warning",
                            status="failed",
                            message=f"Product profile {session.profile_key} requires login",
                            entity_type="crawl_profile",
                            entity_id=session.profile_key,
                            payload={"profile_key": session.profile_key, "platform": product.platform},
                        )
                except Exception:
                    pass
            return await _persist_product_crawl_result(db, product=product, result_data=result_data)
        except Exception as e:
            from playwright.async_api import TimeoutError as PlaywrightTimeoutError
            if isinstance(e, PlaywrightTimeoutError):
                await _emit_page_timeout_event(session)
            await save_crawl_log(product_id, product.platform, "ERROR", error_message=str(e))
            return {"status": "error", "product_id": product_id, "error": str(e)}
        finally:
            await session.close_page(page)


async def crawl_one(product_id: int) -> dict:
    """Core crawl logic, run in the same event loop as the caller."""
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
            return await _persist_product_crawl_result(db, product=product, result_data=result_data)
        except Exception as e:
            platform_name = product.platform if product else "unknown"
            await save_crawl_log(product_id, platform_name, "ERROR", error_message=str(e))
            return {"status": "error", "product_id": product_id, "error": str(e)}


async def get_active_products(
    user_id: int | None = None,
    platform: str | None = None,
) -> list[Product]:
    """Fetch active products from database, optionally filtered."""
    stmt = select(Product).where(Product.active)
    if user_id is not None:
        stmt = stmt.where(Product.user_id == user_id)
    if platform is not None:
        stmt = stmt.where(Product.platform == platform)
    async with AsyncSessionLocal() as db:
        result = await db.execute(stmt)
        return list(result.scalars().all())


async def save_price_history(
    product_id: int,
    price: Decimal,
    currency: str,
    scraped_at: datetime,
) -> None:
    """Save price to history."""
    async with AsyncSessionLocal() as db:
        history = PriceHistory(
            product_id=product_id,
            price=price,
            currency=currency,
            scraped_at=scraped_at,
        )
        db.add(history)
        await db.commit()


async def save_crawl_log(
    product_id: int,
    platform: str,
    status: str,
    price: Decimal | None = None,
    currency: str | None = None,
    error_message: str | None = None,
) -> None:
    """Save crawl log entry."""
    async with AsyncSessionLocal() as db:
        log = CrawlLog(
            product_id=product_id,
            platform=platform,
            status=status,
            price=price,
            currency=currency,
            timestamp=datetime.now(UTC),
            error_message=error_message,
        )
        db.add(log)
        await db.commit()


async def check_price_alerts(product_id: int, current_price: Decimal) -> None:
    """Check and trigger price drop alerts."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Alert).where(Alert.product_id == product_id, Alert.active)
        )
        alerts = result.scalars().all()

        if not alerts:
            return

        product_user_result = await db.execute(
            select(Product, User)
            .join(User, User.id == Product.user_id)
            .where(Product.id == product_id)
        )
        row = product_user_result.one_or_none()

        if not row:
            return

        product, user = row

        if not user or not user.feishu_webhook_url:
            return

        latest_result = await db.execute(
            select(PriceHistory)
            .where(PriceHistory.product_id == product_id)
            .order_by(PriceHistory.scraped_at.desc())
            .limit(2)
        )
        price_records = list(latest_result.scalars().all())

        if len(price_records) < 2:
            return

        previous_price = price_records[1].price
        new_price = current_price

        for alert in alerts:
            if alert.threshold_percent is None:
                continue

            if previous_price > 0:
                drop_percent = ((previous_price - new_price) / previous_price) * 100

                if drop_percent >= alert.threshold_percent:
                    if (
                        alert.last_notified_price is not None
                        and alert.last_notified_price <= new_price
                    ):
                        continue

                    message = (
                        f"Price Drop Alert: {product.title or product.url}\n"
                        f"Platform: {product.platform}\n"
                        f"Old Price: {previous_price} {price_records[1].currency}\n"
                        f"New Price: {new_price} {price_records[1].currency}\n"
                        f"Drop: {drop_percent:.2f}%\n"
                        f"Link: {product.url}"
                    )

                    try:
                        await send_feishu_notification(
                            user.feishu_webhook_url,
                            message,
                        )

                        alert.last_notified_at = datetime.now(UTC)
                        alert.last_notified_price = new_price
                        await db.commit()
                    except Exception:
                        logger.exception(
                            "Failed to send price drop notification for product %s",
                            product_id,
                        )


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
