"""Smart home persistence helpers."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.smart_home import SmartHomeConfig, SmartHomeEntityPreference


async def get_config(db: AsyncSession) -> SmartHomeConfig | None:
    result = await db.execute(select(SmartHomeConfig).order_by(SmartHomeConfig.id.asc()).limit(1))
    return result.scalar_one_or_none()


async def save_config(
    db: AsyncSession,
    *,
    base_url: str,
    encrypted_token: str,
    enabled: bool,
) -> SmartHomeConfig:
    config = await get_config(db)
    if config is None:
        config = SmartHomeConfig(base_url=base_url, encrypted_token=encrypted_token, enabled=enabled)
        db.add(config)
    else:
        config.base_url = base_url
        config.encrypted_token = encrypted_token
        config.enabled = enabled
    await db.commit()
    await db.refresh(config)
    return config


async def update_status(
    db: AsyncSession,
    *,
    config: SmartHomeConfig,
    status: str,
    error: str | None,
) -> SmartHomeConfig:
    config.last_status = status
    config.last_error = error
    await db.commit()
    await db.refresh(config)
    return config


async def list_preferences(db: AsyncSession, *, user_id: int) -> list[SmartHomeEntityPreference]:
    result = await db.execute(
        select(SmartHomeEntityPreference).where(SmartHomeEntityPreference.user_id == user_id)
    )
    return list(result.scalars().all())
