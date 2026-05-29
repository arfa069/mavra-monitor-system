"""Platform adapters package."""
from app.platforms.base import BasePlatformAdapter
from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter
from app.platforms.job51 import Job51Adapter
from app.platforms.liepin import LiepinAdapter

__all__ = [
    "BasePlatformAdapter",
    "BossCloakExperimentalAdapter",
    "Job51Adapter",
    "LiepinAdapter",
]
