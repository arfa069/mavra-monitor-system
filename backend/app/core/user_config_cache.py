"""User configuration cache with Redis TTL caching.

Avoids repeated DB queries for single-user system config (feishu_webhook_url, etc.).
Cache invalidation happens automatically on config updates via /config endpoints.
"""
from __future__ import annotations

import asyncio
import json
import logging
from typing import Any

import redis.asyncio as redis
from sqlalchemy import select

from app.core.redis_client import get_redis
from app.database import AsyncSessionLocal
from app.models.user import User

logger = logging.getLogger(__name__)

def get_cache_key(user_id: int) -> str:
    """Return the Redis cache key for a specific user ID."""
    return f"user:config:{user_id}"

CACHE_TTL_SECONDS = 300  # 5 minutes

_fetch_lock = asyncio.Lock()


async def get_cached_user_config(user_id: int, db=None) -> dict[str, Any] | None:
    """Return user config dict from cache, or fetch from DB and cache it.

    Args:
        user_id: The ID of the user whose configuration is retrieved.
        db: Optional existing async DB session. If None, a new session is created.

    Returns:
        Dict with user config fields, or None if user not found.
    """
    redis_client = await get_redis()
    cache_key = get_cache_key(user_id)

    # 1. Try cache
    try:
        cached = await redis_client.get(cache_key)
        if cached:
            return json.loads(cached)
    except (redis.RedisError, json.JSONDecodeError):
        logger.exception("Redis cache read failed, falling back to DB")

    # 2. Cache miss — acquire lock to prevent stampede
    async with _fetch_lock:
        # Double-check: another coroutine may have cached while we waited
        try:
            cached = await redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
        except (redis.RedisError, json.JSONDecodeError):
            pass  # proceed to DB fallback

        # 3. Still cache miss — fetch from DB
        if db is not None:
            return await _fetch_and_cache(user_id, db, redis_client)

        async with AsyncSessionLocal() as db:
            return await _fetch_and_cache(user_id, db, redis_client)


async def _fetch_and_cache(user_id: int, db, redis_client: redis.Redis) -> dict[str, Any] | None:
    """Query DB for user config and write to Redis."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None:
        return None

    config = {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "feishu_webhook_url": user.feishu_webhook_url or "",
        "data_retention_days": user.data_retention_days,
        "is_active": user.is_active,
    }

    cache_key = get_cache_key(user_id)
    try:
        await redis_client.setex(cache_key, CACHE_TTL_SECONDS, json.dumps(config))
    except (redis.RedisError, TypeError):
        logger.exception("Redis cache write failed")

    return config


async def invalidate_user_config_cache(user_id: int) -> None:
    """Clear the user config cache for a specific user ID. Call after any config update."""
    redis_client = await get_redis()
    cache_key = get_cache_key(user_id)
    try:
        await redis_client.delete(cache_key)
    except redis.RedisError:
        logger.exception("Redis cache invalidate failed")
