"""Config domain business services."""

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_password_hash
from app.domains.config import repository
from app.models.user import User
from app.schemas.user import UserConfigCreate, UserConfigUpdate


async def get_or_create_default_user(db: AsyncSession) -> User:
    user = await repository.get_default_user(db)
    if user is not None:
        return user

    return await repository.add_user(
        db,
        user=User(
            username="default",
            email="default@localhost",
            hashed_password=get_password_hash("default"),
            is_active=True,
            feishu_webhook_url="",
            data_retention_days=365,
        ),
    )


async def create_or_update_config(
    db: AsyncSession, *, data: UserConfigCreate
) -> User:
    user = await get_or_create_default_user(db)
    user.feishu_webhook_url = data.feishu_webhook_url
    user.data_retention_days = data.data_retention_days
    return await repository.save_user(db, user=user)


async def update_config_partial(
    db: AsyncSession, *, data: UserConfigUpdate
) -> User:
    user = await get_or_create_default_user(db)
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    return await repository.save_user(db, user=user)
