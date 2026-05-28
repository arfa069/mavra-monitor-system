import pytest
from sqlalchemy import delete

from app.database import AsyncSessionLocal
from app.domains.crawling.profile_service import create_profile
from app.domains.products import service as product_service
from app.models.crawl_profile import CrawlProfile
from app.models.product import ProductPlatformCron, ProductPlatformProfileBinding
from app.schemas.product import (
    ProductPlatformCronCreate,
    ProductPlatformCronUpdate,
    ProductPlatformProfileBindingUpdate,
)
from tests.db_safety import require_test_database


async def _clean_tables():
    require_test_database()
    async with AsyncSessionLocal() as s:
        await s.execute(delete(ProductPlatformProfileBinding))
        await s.execute(delete(ProductPlatformCron))
        await s.execute(delete(CrawlProfile))
        await s.commit()


def test_product_platform_profile_binding_model_shape():
    columns = ProductPlatformProfileBinding.__table__.columns

    assert ProductPlatformProfileBinding.__tablename__ == "products_platform_profile_bindings"
    assert columns["user_id"].nullable is False
    assert columns["platform"].nullable is False
    assert columns["profile_key"].nullable is False


def test_product_cron_profile_key_is_legacy_nullable_column():
    columns = ProductPlatformCron.__table__.columns

    assert columns["profile_key"].nullable is True


@pytest.mark.asyncio
async def test_create_product_cron_config_does_not_bind_profile():
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        config = await product_service.create_product_cron_config(
            db,
            user_id=1,
            data=ProductPlatformCronCreate(
                platform="jd",
                cron_expression="0 9 * * *",
                cron_timezone="Asia/Shanghai",
            ),
        )

        assert config.profile_key is None


@pytest.mark.asyncio
async def test_create_product_cron_config_ignores_legacy_profile_key():
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        config = await product_service.create_product_cron_config(
            db,
            user_id=1,
            data=ProductPlatformCronCreate(
                platform="taobao",
                cron_expression="0 9 * * *",
                cron_timezone="Asia/Shanghai",
                profile_key="product-taobao-default",
            ),
        )

        assert config.profile_key is None


@pytest.mark.asyncio
async def test_update_product_cron_config_does_not_bind_profile():
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await create_profile(
            db,
            profile_key="product-jd-secondary",
            platform_hint="jd",
        )
        await product_service.create_product_cron_config(
            db,
            user_id=1,
            data=ProductPlatformCronCreate(
                platform="jd",
                cron_expression="0 9 * * *",
                cron_timezone="Asia/Shanghai",
            ),
        )

        updated = await product_service.update_product_cron_config(
            db,
            user_id=1,
            platform="jd",
            data=ProductPlatformCronUpdate(
                cron_expression="30 10 * * *",
                cron_timezone="Asia/Shanghai",
                profile_key="product-jd-secondary",
            ),
        )

        assert updated.profile_key is None


@pytest.mark.asyncio
async def test_upsert_product_platform_profile_binding_requires_existing_profile():
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        with pytest.raises(product_service.ProductProfileConfigError):
            await product_service.upsert_product_profile_binding(
                db,
                user_id=1,
                platform="jd",
                data=ProductPlatformProfileBindingUpdate(profile_key="missing-profile"),
            )


@pytest.mark.asyncio
async def test_upsert_and_list_product_platform_profile_binding():
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        await create_profile(db, profile_key="51job-jd", platform_hint="mixed")
        binding = await product_service.upsert_product_profile_binding(
            db,
            user_id=1,
            platform="jd",
            data=ProductPlatformProfileBindingUpdate(profile_key="51job-jd"),
        )

        bindings = await product_service.list_product_profile_bindings(db, user_id=1)

    assert binding.profile_key == "51job-jd"
    jd = next(item for item in bindings if item.platform == "jd")
    taobao = next(item for item in bindings if item.platform == "taobao")
    assert jd.profile_key == "51job-jd"
    assert jd.profile_status == "available"
    assert taobao.profile_key is None
