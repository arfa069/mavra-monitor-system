import pytest
from sqlalchemy import delete

from app.core.task_registry import CrawlTask
from app.database import AsyncSessionLocal
from app.domains.crawling import task_runner
from app.domains.crawling.profile_pool import ensure_profile
from app.domains.products.service import create_product, create_product_cron_config
from app.models.crawl_profile import CrawlProfile
from app.models.product import Product, ProductPlatformCron
from app.schemas.product import ProductCreate, ProductPlatformCronCreate


async def _clean_tables():
    async with AsyncSessionLocal() as s:
        await s.execute(delete(ProductPlatformCron))
        await s.execute(delete(Product))
        await s.execute(delete(CrawlProfile).where(CrawlProfile.profile_key.not_like("default")))
        await s.commit()


@pytest.mark.asyncio
async def test_platform_crawl_task_records_profile_key(monkeypatch):
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        await create_product_cron_config(
            db,
            user_id=1,
            data=ProductPlatformCronCreate(
                platform="jd",
                cron_expression="0 9 * * *",
                cron_timezone="Asia/Shanghai",
            ),
        )
        product = await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(
                platform="jd",
                url="https://item.jd.com/100.html",
                title="Demo",
                active=True,
            ),
        )
        product_id = product.id

    seen = []

    async def fake_crawl_products_with_profile(*, product_ids, platform, profile_key, task_id):
        seen.append((platform, profile_key, product_ids, task_id))
        return [{"product_id": product_ids[0], "status": "success"}]

    monkeypatch.setattr(
        task_runner,
        "crawl_products_with_profile",
        fake_crawl_products_with_profile,
    )

    task = CrawlTask(task_id="task-1", source="cron", user_id=1)
    runner = task_runner.CrawlTaskRunner()
    result = await runner.run_products_by_platform(task, platform="jd")

    assert result["profile_key"] == "product-jd-default"
    assert seen == [("jd", "product-jd-default", [product_id], "task-1")]
    assert task.profile_key == "product-jd-default"


@pytest.mark.asyncio
async def test_all_products_group_by_platform_profile(monkeypatch):
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        await ensure_profile(db, profile_key="product-taobao-default", platform_hint="taobao")
        await create_product_cron_config(
            db,
            user_id=1,
            data=ProductPlatformCronCreate(platform="jd", profile_key="product-jd-default"),
        )
        await create_product_cron_config(
            db,
            user_id=1,
            data=ProductPlatformCronCreate(platform="taobao", profile_key="product-taobao-default"),
        )
        await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(
                platform="jd",
                url="https://item.jd.com/1.html",
                title="JD Product",
                active=True,
            ),
        )
        await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(
                platform="taobao",
                url="https://item.taobao.com/1.html",
                title="Taobao Product",
                active=True,
            ),
        )

    calls = []

    async def fake_lane(*, product_ids, platform, profile_key, task_id):
        calls.append((platform, profile_key))
        return []

    monkeypatch.setattr(task_runner, "crawl_products_with_profile", fake_lane)

    task = CrawlTask(task_id="task-all", source="manual", user_id=1)
    runner = task_runner.CrawlTaskRunner()
    await runner.run_all_products(task)

    assert ("jd", "product-jd-default") in calls
    assert ("taobao", "product-taobao-default") in calls
