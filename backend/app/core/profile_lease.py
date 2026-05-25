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
    """In-process profile lease manager.

    Acquiring a lease also creates the profile directory as a side effect,
    ensuring the directory is ready when the caller uses the profile.
    """
    def __init__(self, *, root: str | Path):
        self.root = Path(root)
        self._leased: set[Path] = set()
        self._lock = asyncio.Lock()

    async def acquire(self, platform: str, profile_key: str, *, owner: str) -> ProfileLease:
        profile_dir = build_profile_dir(profile_key, root=self.root)
        async with self._lock:
            if profile_dir in self._leased:
                raise RuntimeError(
                    f"Profile {profile_key!r} is already leased at {profile_dir}"
                )
            profile_dir.mkdir(parents=True, exist_ok=True)
            self._leased.add(profile_dir)
            return ProfileLease(
                platform=platform,
                profile_key=profile_key,
                profile_dir=profile_dir,
                owner=owner,
            )

    async def release(self, lease: ProfileLease) -> None:
        async with self._lock:
            self._leased.discard(lease.profile_dir)

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
