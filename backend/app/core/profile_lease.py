"""Profile lease primitives for crawler browser profiles."""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from dataclasses import dataclass
from pathlib import Path

from app.core.crawler_paths import build_profile_dir


@dataclass(frozen=True)
class ProfileLease:
    platform: str
    profile_key: str
    profile_dir: Path
    owner: str


class InProcessProfileLeaseManager:
    def __init__(self, *, root: str | Path):
        self.root = Path(root)
        self._leased: set[tuple[str, str]] = set()
        self._lock = asyncio.Lock()

    async def acquire(self, platform: str, profile_key: str, *, owner: str) -> ProfileLease:
        key = (platform, profile_key)
        async with self._lock:
            if key in self._leased:
                raise RuntimeError(f"Profile {platform}/{profile_key} is already leased")
            profile_dir = build_profile_dir(self.root, platform, profile_key)
            profile_dir.mkdir(parents=True, exist_ok=True)
            self._leased.add(key)
            return ProfileLease(
                platform=platform,
                profile_key=profile_key,
                profile_dir=profile_dir,
                owner=owner,
            )

    async def release(self, lease: ProfileLease) -> None:
        async with self._lock:
            self._leased.discard((lease.platform, lease.profile_key))

    @asynccontextmanager
    async def lease(
        self,
        platform: str,
        profile_key: str,
        *,
        owner: str,
    ) -> AsyncIterator[ProfileLease]:
        acquired = await self.acquire(platform, profile_key, owner=owner)
        try:
            yield acquired
        finally:
            await self.release(acquired)
