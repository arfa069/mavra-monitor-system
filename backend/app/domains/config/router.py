"""Config API router."""
import logging

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import require_permission
from app.database import get_db
from app.domains.config import service as config_service
from app.models.user import User
from app.schemas.user import (
    UserConfigCreate,
    UserConfigDefaults,
    UserConfigResponse,
    UserConfigUpdate,
)
from app.services.user_config_cache import invalidate_user_config_cache

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/config", tags=["config"])

_DEFAULT_CONFIG = UserConfigDefaults()


async def get_or_create_default_user(db: AsyncSession) -> User:
    """Get the default user or create one if not exists."""
    return await config_service.get_or_create_default_user(db)


@router.post("", response_model=UserConfigResponse)
async def create_or_update_config(
    config_data: UserConfigCreate,
    current_user: User = Depends(require_permission("config:write")),
    db: AsyncSession = Depends(get_db),
):
    """Create or update user configuration."""
    user = await config_service.create_or_update_config(db, data=config_data)
    await invalidate_user_config_cache()

    return user


@router.get("", response_model=UserConfigResponse)
async def get_config(
    current_user: User = Depends(require_permission("config:read")),
    db: AsyncSession = Depends(get_db),
):
    """Get current user configuration, or return defaults if not set."""
    return await config_service.get_or_create_default_user(db)


@router.patch("", response_model=UserConfigResponse)
async def update_config_partial(
    config_data: UserConfigUpdate,
    current_user: User = Depends(require_permission("config:write")),
    db: AsyncSession = Depends(get_db),
):
    """Partial update user configuration (create if not exists)."""
    user = await config_service.update_config_partial(db, data=config_data)
    await invalidate_user_config_cache()

    return user
