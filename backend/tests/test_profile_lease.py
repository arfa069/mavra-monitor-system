from pathlib import Path

import pytest


@pytest.mark.asyncio
async def test_profile_lease_rejects_double_acquire(tmp_path):
    from app.core.profile_lease import InProcessProfileLeaseManager

    manager = InProcessProfileLeaseManager(root=tmp_path)
    lease = await manager.acquire("boss", "profile-a", owner="task-1")

    with pytest.raises(RuntimeError, match="already leased"):
        await manager.acquire("boss", "profile-a", owner="task-2")

    await manager.release(lease)


@pytest.mark.asyncio
async def test_profile_lease_releases_after_context(tmp_path):
    from app.core.profile_lease import InProcessProfileLeaseManager

    manager = InProcessProfileLeaseManager(root=tmp_path)

    async with manager.lease("boss", "profile-a", owner="task-1") as lease:
        assert lease.profile_dir == Path(tmp_path) / "profiles" / "profile-a"

    second = await manager.acquire("boss", "profile-a", owner="task-2")
    await manager.release(second)
