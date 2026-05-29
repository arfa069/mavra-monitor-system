import asyncio

import pytest
from sqlalchemy import delete, select

from app.core.task_registry import CrawlTask
from app.database import AsyncSessionLocal
from app.domains.crawling import task_runner
from app.domains.crawling.profile_pool import LOGIN_REQUIRED, ensure_profile
from app.domains.products.service import (
    create_product,
    upsert_product_profile_binding,
)
from app.models.crawl_log import CrawlLog
from app.models.crawl_profile import CrawlProfile
from app.models.product import (
    Product,
    ProductPlatformCron,
    ProductPlatformProfileBinding,
)
from app.schemas.product import (
    ProductCreate,
    ProductPlatformProfileBindingUpdate,
)
from tests.db_safety import require_test_database


async def _clean_tables():
    require_test_database()
    async with AsyncSessionLocal() as s:
        await s.execute(delete(CrawlLog))
        await s.execute(delete(ProductPlatformProfileBinding))
        await s.execute(delete(ProductPlatformCron))
        await s.execute(delete(Product))
        await s.execute(delete(CrawlProfile).where(CrawlProfile.profile_key.not_like("default")))
        await s.commit()


@pytest.mark.asyncio
async def test_log_lane_start_failure_writes_error_logs(monkeypatch):
    calls = []

    async def fake_save_crawl_log(product_id, platform, status, **kwargs):
        calls.append((product_id, platform, status, kwargs["error_message"]))

    from app.domains.crawling import service as crawling_service

    monkeypatch.setattr(crawling_service, "save_crawl_log", fake_save_crawl_log)

    await task_runner._log_lane_start_failure(
        product_ids=[1, 2],
        platform="taobao",
        reason="profile startup failed",
    )

    assert calls == [
        (1, "taobao", "ERROR", "profile startup failed"),
        (2, "taobao", "ERROR", "profile startup failed"),
    ]


@pytest.mark.asyncio
async def test_platform_crawl_task_records_profile_key(monkeypatch):
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="51job-jd", platform_hint="mixed")
        await upsert_product_profile_binding(
            db,
            user_id=1,
            platform="jd",
            data=ProductPlatformProfileBindingUpdate(profile_key="51job-jd"),
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

    assert result["profile_key"] == "51job-jd"
    assert seen == [("jd", "51job-jd", [product_id], "task-1")]
    assert task.profile_key == "51job-jd"


@pytest.mark.asyncio
async def test_platform_crawl_task_fails_when_profile_not_configured():
    await _clean_tables()
    async with AsyncSessionLocal() as db:
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

    task = CrawlTask(task_id="task-missing-profile", source="manual", user_id=1)
    result = await task_runner.CrawlTaskRunner().run_products_by_platform(task, platform="jd")

    assert result["status"] == "error"
    assert result["reason"] == "platform_profile_not_configured"
    assert task.status == "failed"
    assert task.errors == 1
    assert task.details == [
        {
            "product_id": product.id,
            "status": "error",
            "reason": "platform_profile_not_configured",
            "profile_key": None,
        }
    ]

    async with AsyncSessionLocal() as db:
        logs = (
            await db.execute(select(CrawlLog).where(CrawlLog.product_id == product.id))
        ).scalars().all()

    assert len(logs) == 1
    assert logs[0].status == "ERROR"
    assert logs[0].error_message == "platform_profile_not_configured"


@pytest.mark.asyncio
async def test_platform_crawl_task_fails_when_profile_lane_cannot_start(monkeypatch):
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        await upsert_product_profile_binding(
            db,
            user_id=1,
            platform="jd",
            data=ProductPlatformProfileBindingUpdate(profile_key="product-jd-default"),
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

    async def failing_lane(*, product_ids, platform, profile_key, task_id):
        raise RuntimeError("profile product-jd-default is already leased")

    progress = []

    async def record_progress(task):
        progress.append((task.status, task.reason, task.errors))

    monkeypatch.setattr(task_runner, "crawl_products_with_profile", failing_lane)

    task = CrawlTask(task_id="task-1", source="cron", user_id=1)
    result = await task_runner.CrawlTaskRunner(
        progress_callback=record_progress
    ).run_products_by_platform(task, platform="jd")

    assert result["status"] == "error"
    assert task.status == "failed"
    assert task.errors == 1
    assert task.details == [
        {
            "product_id": product.id,
            "status": "error",
            "reason": "profile product-jd-default is already leased",
            "profile_key": "product-jd-default",
        }
    ]
    assert progress[-1] == ("failed", "profile product-jd-default is already leased", 1)

    async with AsyncSessionLocal() as db:
        logs = (
            await db.execute(
                select(CrawlLog).where(CrawlLog.product_id == product.id)
            )
        ).scalars().all()

    assert len(logs) == 1
    assert logs[0].status == "ERROR"
    assert logs[0].error_message == "profile product-jd-default is already leased"


@pytest.mark.asyncio
async def test_all_products_group_by_platform_profile(monkeypatch):
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        await ensure_profile(db, profile_key="product-taobao-default", platform_hint="taobao")
        await upsert_product_profile_binding(
            db,
            user_id=1,
            platform="jd",
            data=ProductPlatformProfileBindingUpdate(profile_key="product-jd-default"),
        )
        await upsert_product_profile_binding(
            db,
            user_id=1,
            platform="taobao",
            data=ProductPlatformProfileBindingUpdate(profile_key="product-taobao-default"),
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
async def test_crawl_one_emits_page_timeout_event_for_timeout_result(monkeypatch):
    """Adapter timeout result, not only timeout exception, emits page timeout event."""
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        product = await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(
                platform="jd",
                url="https://item.jd.com/timeout-result.html",
                title="Timeout Result Demo",
                active=True,
            ),
        )

    emitted = []

    async def fake_emit(**kwargs):
        emitted.append(kwargs)

    monkeypatch.setattr("app.core.system_log.emit_system_log_detached", fake_emit)

    class FakePage:
        url = "https://item.jd.com/timeout-result.html"

        async def content(self):
            return ""

    class FakeAdapter:
        platform_name = "jd"

        async def crawl_with_page(self, url, page):
            return {
                "success": False,
                "error": "Page load timeout: page.goto timed out",
            }

        def classify_failure(self, url, content):
            return None

    monkeypatch.setattr(
        "app.domains.crawling.service.PLATFORM_ADAPTERS",
        {"jd": FakeAdapter},
    )

    class FakeSession:
        profile_key = "product-jd-default"
        platform = "jd"

        async def new_page(self):
            return FakePage()

        async def close_page(self, page):
            pass

    from app.domains.crawling.service import crawl_one_with_session

    result = await crawl_one_with_session(product_id=product.id, session=FakeSession())

    assert result["status"] == "error"
    timeout_events = [e for e in emitted if e.get("event_type") == "product_browser.page_timeout"]
    assert len(timeout_events) == 1
    assert timeout_events[0]["entity_id"] == "product-jd-default"


@pytest.mark.asyncio
async def test_crawl_one_marks_profile_login_required_for_anti_bot(monkeypatch):
    """Anti-bot pages should stop repeated product crawls until the profile is fixed."""
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        product = await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(
                platform="jd",
                url="https://item.jd.com/anti-bot.html",
                title="Anti Bot Demo",
                active=True,
            ),
        )

    emitted = []

    async def fake_emit(**kwargs):
        emitted.append(kwargs)

    monkeypatch.setattr("app.core.system_log.emit_system_log_detached", fake_emit)

    class FakePage:
        url = "https://pc-frequent-pro.pf.jd.com/?from=pc_item&reason=403"

        async def content(self):
            return "安全验证"

    class FakeAdapter:
        async def crawl_with_page(self, url, page):
            return {"success": False, "error": "All chained strategies failed"}

        def classify_failure(self, url, content):
            return "anti_bot"

    monkeypatch.setattr(
        "app.domains.crawling.service.PLATFORM_ADAPTERS",
        {"jd": FakeAdapter},
    )

    class FakeSession:
        profile_key = "product-jd-default"
        platform = "jd"

        async def new_page(self):
            return FakePage()

        async def close_page(self, page):
            pass

    from app.domains.crawling.service import crawl_one_with_session

    result = await crawl_one_with_session(product_id=product.id, session=FakeSession())

    assert result["status"] == "error"
    async with AsyncSessionLocal() as db:
        profile = (
            await db.execute(
                select(CrawlProfile).where(
                    CrawlProfile.profile_key == "product-jd-default"
                )
            )
        ).scalar_one()
        log = (
            await db.execute(select(CrawlLog).where(CrawlLog.product_id == product.id))
        ).scalar_one()

    assert profile.status == LOGIN_REQUIRED
    assert "anti-bot verification required" in profile.last_error
    assert "anti-bot verification required" in log.error_message
    anti_bot_events = [
        event for event in emitted if event.get("event_type") == "product_profile.anti_bot"
    ]
    assert len(anti_bot_events) == 1


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
        await upsert_product_profile_binding(
            db,
            user_id=1,
            platform="jd",
            data=ProductPlatformProfileBindingUpdate(profile_key="product-jd-default"),
        )
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
async def test_run_all_products_logs_lane_start_failures(monkeypatch):
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        await upsert_product_profile_binding(
            db,
            user_id=1,
            platform="jd",
            data=ProductPlatformProfileBindingUpdate(profile_key="product-jd-default"),
        )
        product = await create_product(
            db,
            user_id=1,
            product_data=ProductCreate(platform="jd", url="https://jd.com/1", active=True),
        )

    async def failing_lane(*, product_ids, platform, profile_key, task_id):
        raise RuntimeError("profile startup failed")

    monkeypatch.setattr(task_runner, "crawl_products_with_profile", failing_lane)

    task = CrawlTask(task_id="task-lane-failure", source="manual", user_id=1)
    result = await task_runner.CrawlTaskRunner().run_all_products(task)

    assert result["status"] == "error"
    assert result["errors"] == 1
    async with AsyncSessionLocal() as db:
        logs = (
            await db.execute(
                select(CrawlLog).where(CrawlLog.product_id == product.id)
            )
        ).scalars().all()

    assert len(logs) == 1
    assert logs[0].status == "ERROR"
    assert logs[0].error_message == "profile startup failed"


@pytest.mark.asyncio
async def test_run_all_products_runs_lanes_concurrently(monkeypatch):
    """Multiple profile lanes run concurrently, not serially."""
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await ensure_profile(db, profile_key="product-jd-default", platform_hint="jd")
        await ensure_profile(db, profile_key="product-taobao-default", platform_hint="taobao")
        await upsert_product_profile_binding(
            db,
            user_id=1,
            platform="jd",
            data=ProductPlatformProfileBindingUpdate(profile_key="product-jd-default"),
        )
        await upsert_product_profile_binding(
            db,
            user_id=1,
            platform="taobao",
            data=ProductPlatformProfileBindingUpdate(profile_key="product-taobao-default"),
        )
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


@pytest.mark.asyncio
async def test_sync_crawl_all_products_uses_profile_first_runner(monkeypatch):
    """Synchronous crawl-all path delegates to the same persistent task runner."""
    from app.core.task_registry import TaskStatus
    from app.domains.crawling import scheduler_service

    class DummyDb:
        pass

    class DummySessionFactory:
        async def __aenter__(self):
            return DummyDb()

        async def __aexit__(self, exc_type, exc, tb):
            return None

    class DummyRecord:
        id = 123

    created_records = []

    async def fake_create_record(db, **kwargs):
        created_records.append(kwargs)
        return DummyRecord()

    def fake_runtime_task_from_record(record):
        return CrawlTask(task_id="sync-task", source="manual", user_id=1)

    calls = []

    async def fake_run_crawl_task(task, *, record_id=None):
        calls.append((task.task_id, record_id))
        task.status = TaskStatus.COMPLETED
        task.total = 1
        task.success = 1
        task.errors = 0
        task.details = [{"product_id": 1, "status": "success", "profile_key": "product-jd-default"}]

    monkeypatch.setattr(
        scheduler_service,
        "_scheduler_state",
        {"crawl_lock": asyncio.Semaphore(1)},
    )
    monkeypatch.setattr(scheduler_service, "AsyncSessionLocal", DummySessionFactory)
    monkeypatch.setattr(scheduler_service, "create_crawl_task_record", fake_create_record)
    monkeypatch.setattr(scheduler_service, "runtime_task_from_record", fake_runtime_task_from_record)
    monkeypatch.setattr(scheduler_service, "_run_crawl_task", fake_run_crawl_task)

    result = await scheduler_service.crawl_all_products(
        source="manual",
        background=False,
        user_id=1,
    )

    assert calls == [("sync-task", 123)]
    assert created_records[0]["task_type"] == "product_all"
    assert result["status"] == "completed"
    assert result["details"][0]["profile_key"] == "product-jd-default"
