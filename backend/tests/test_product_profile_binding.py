import pytest
from sqlalchemy import delete

from app.database import AsyncSessionLocal
from app.domains.crawling.profile_service import create_profile
from app.domains.products import service as product_service
from app.domains.products.profile_binding import default_product_profile_key
from app.models.crawl_profile import CrawlProfile
from app.models.product import ProductPlatformCron
from app.schemas.product import ProductPlatformCronCreate, ProductPlatformCronUpdate


async def _clean_tables():
    async with AsyncSessionLocal() as s:
        await s.execute(delete(ProductPlatformCron))
        await s.execute(delete(CrawlProfile))
        await s.commit()


def test_default_product_profile_key_mapping():
    assert default_product_profile_key("jd") == "product-jd-default"
    assert default_product_profile_key("taobao") == "product-taobao-default"
    assert default_product_profile_key("amazon") == "product-amazon-default"


@pytest.mark.asyncio
async def test_create_product_cron_config_uses_default_profile():
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

        assert config.profile_key == "product-jd-default"


@pytest.mark.asyncio
async def test_create_product_cron_config_rejects_unknown_profile():
    await _clean_tables()
    async with AsyncSessionLocal() as db:
        with pytest.raises(product_service.ProductProfileConfigError) as exc:
            await product_service.create_product_cron_config(
                db,
                user_id=1,
                data=ProductPlatformCronCreate(
                    platform="jd",
                    cron_expression="0 9 * * *",
                    cron_timezone="Asia/Shanghai",
                    profile_key="missing-profile",
                ),
            )

        assert "missing-profile" in str(exc.value)


@pytest.mark.asyncio
async def test_update_product_cron_config_can_change_profile():
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

        assert updated.profile_key == "product-jd-secondary"
