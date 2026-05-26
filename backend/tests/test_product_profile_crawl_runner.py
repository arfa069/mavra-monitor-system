import asyncio

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


@pytest.mark.asyncio
async def test_crawl_one_emits_page_timeout_event(monkeypatch):
    """Playwright timeout during crawl emits product_browser.page_timeout event."""
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        product = await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(
                platform="jd",
                url="https://item.jd.com/timeout.html",
                title="Timeout Demo",
                active=True,
            ),
        )

    from playwright.async_api import TimeoutError as PlaywrightTimeoutError

    emitted = []

    async def fake_emit(**kwargs):
        emitted.append(kwargs)

    monkeypatch.setattr(
        "app.core.system_log.emit_system_log_detached",
        fake_emit,
    )

    class FakeAdapter:
        platform_name = "jd"

        async def crawl_with_page(self, url, page):
            raise PlaywrightTimeoutError("page.goto: Timeout 30000ms exceeded")

    monkeypatch.setattr(
        "app.domains.crawling.service.PLATFORM_ADAPTERS",
        {"jd": FakeAdapter},
    )

    class FakeSession:
        profile_key = "product-jd-default"
        platform = "jd"
        _open_pages = set()

        async def new_page(self):
            return None

        async def close_page(self, page):
            pass

    from app.domains.crawling.service import crawl_one_with_session

    result = await crawl_one_with_session(
        product_id=product.id,
        session=FakeSession(),
    )

    assert result["status"] == "error"
    timeout_events = [e for e in emitted if e.get("event_type") == "product_browser.page_timeout"]
    assert len(timeout_events) == 1
    assert timeout_events[0]["entity_id"] == "product-jd-default"


@pytest.mark.asyncio
async def test_crawl_fallback_disabled_by_default(monkeypatch):
    """crawl() fallback is disabled when product_cdp_fallback_enabled is False."""
    monkeypatch.setattr("app.platforms.base.settings.product_cdp_fallback_enabled", False)

    from app.platforms.base import BasePlatformAdapter

    class DummyAdapter(BasePlatformAdapter):
        platform_name = "dummy"

        async def extract_price(self, page):
            return {"success": True, "price": "1.00"}

        async def extract_title(self, page):
            return "Demo"

    adapter = DummyAdapter()
    with pytest.raises(RuntimeError, match="fallback.*disabled"):
        await adapter.crawl("https://example.test/item")


@pytest.mark.asyncio
async def test_run_all_products_includes_lane_profile_keys(monkeypatch):
    """run_all_products result includes profile_key per product/lane."""
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(platform="jd", url="https://jd.com/1", active=True),
        )

    async def fake_lane(*, product_ids, platform, profile_key, task_id):
        return [{"product_id": product_ids[0], "status": "success", "profile_key": profile_key}]

    monkeypatch.setattr(task_runner, "crawl_products_with_profile", fake_lane)

    task = CrawlTask(task_id="task-lanes", source="manual", user_id=1)
    result = await task_runner.CrawlTaskRunner().run_all_products(task)

    assert result["status"] == "completed"
    assert len(result["details"]) == 1
    assert result["details"][0]["profile_key"] == "product-jd-default"


@pytest.mark.asyncio
async def test_run_all_products_runs_lanes_concurrently(monkeypatch):
    """Multiple profile lanes run concurrently, not serially."""
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        await ensure_profile(db, profile_key="product-taobao-default", platform_hint="taobao")
        await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(platform="jd", url="https://jd.com/1", active=True),
        )
        await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(platform="taobao", url="https://taobao.com/1", active=True),
        )

    active = 0
    max_active = 0

    async def fake_lane(*, product_ids, platform, profile_key, task_id):
        nonlocal active, max_active
        active += 1
        max_active = max(max_active, active)
        await asyncio.sleep(0.05)
        active -= 1
        return [{"product_id": pid, "status": "success"} for pid in product_ids]

    monkeypatch.setattr(task_runner, "crawl_products_with_profile", fake_lane)

    task = CrawlTask(task_id="task-concurrent", source="manual", user_id=1)
    result = await task_runner.CrawlTaskRunner().run_all_products(task)

    assert result["status"] == "completed"
    assert max_active == 2, f"Expected 2 concurrent lanes, got {max_active}"
