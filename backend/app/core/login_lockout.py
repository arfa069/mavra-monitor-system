"""Redis-backed login attempt lockout."""
from __future__ import annotations

import asyncio

import redis.asyncio as redis

from app.config import settings

MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_DURATION_SECONDS = 900  # 15 minutes

_redis_client: redis.Redis | None = None
_redis_loop: asyncio.AbstractEventLoop | None = None


async def _get_redis() -> redis.Redis:
    """Get or create Redis client (connection reused per event loop)."""
    global _redis_client, _redis_loop
    current_loop = asyncio.get_running_loop()
    if _redis_client is None or _redis_loop is not current_loop:
        _redis_client = redis.from_url(settings.redis_url_with_password)
        _redis_loop = current_loop
    return _redis_client


async def is_account_locked(username: str) -> tuple[bool, int]:
    """Check if account is locked due to too many failed attempts.

    Returns:
        tuple of (is_locked, minutes_remaining)
    """
    redis_client = await _get_redis()
    key = f"login_attempts:{username}"
    count = await redis_client.get(key)
    if count is None:
        return False, 0

    count_int = int(count)
    if count_int >= MAX_LOGIN_ATTEMPTS:
        ttl = await redis_client.ttl(key)
        minutes_remaining = max(1, int(ttl / 60)) if ttl > 0 else 1
        return True, minutes_remaining

    return False, 0


async def record_failed_login(username: str) -> None:
    """Record a failed login attempt."""
    redis_client = await _get_redis()
    key = f"login_attempts:{username}"
    count = await redis_client.incr(key)
    if count == 1:
        await redis_client.expire(key, LOCKOUT_DURATION_SECONDS)


async def clear_login_attempts(username: str) -> None:
    """Clear failed login attempts after successful login."""
    redis_client = await _get_redis()
    await redis_client.delete(f"login_attempts:{username}")
