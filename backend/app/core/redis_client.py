"""Shared Redis client (per event loop)."""

from __future__ import annotations

import asyncio

import redis.asyncio as redis

from app.config import settings

_redis_client: redis.Redis | None = None
_redis_loop: asyncio.AbstractEventLoop | None = None


async def get_redis() -> redis.Redis:
    """Get or create shared Redis client (connection reused per event loop)."""
    global _redis_client, _redis_loop
    current_loop = asyncio.get_running_loop()
    if _redis_client is None or _redis_loop is not current_loop:
        _redis_client = redis.from_url(settings.redis_url_with_password)
        _redis_loop = current_loop
    return _redis_client
