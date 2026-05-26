from sqlalchemy.ext.asyncio import AsyncSession

from app.domains.crawling.profile_pool import ensure_profile
from app.domains.crawling.profile_service import CrawlProfileNotFoundError, get_profile
from app.models.crawl_profile import CrawlProfile

PRODUCT_PLATFORM_DEFAULT_PROFILE_KEYS: dict[str, str] = {
    "jd": "product-jd-default",
    "taobao": "product-taobao-default",
    "amazon": "product-amazon-default",
}


def default_product_profile_key(platform: str) -> str:
    try:
        return PRODUCT_PLATFORM_DEFAULT_PROFILE_KEYS[platform]
    except KeyError as exc:
        raise ValueError(f"Unsupported product platform: {platform}") from exc


async def resolve_product_profile(
    db: AsyncSession,
    *,
    platform: str,
    profile_key: str | None,
) -> CrawlProfile:
    if profile_key is None:
        return await ensure_profile(
            db,
            profile_key=default_product_profile_key(platform),
            platform_hint=platform,
        )

    try:
        return await get_profile(db, profile_key)
    except CrawlProfileNotFoundError as exc:
        raise ValueError(f"Unknown crawl profile: {profile_key}") from exc
