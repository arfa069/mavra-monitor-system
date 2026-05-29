"""Platform adapters package."""
from app.platforms.base import BasePlatformAdapter
from app.platforms.boss import BossZhipinAdapter
from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter
from app.platforms.jd import JDAdapter
from app.platforms.job51 import Job51Adapter
from app.platforms.liepin import LiepinAdapter
from app.platforms.taobao import TaobaoAdapter

__all__ = [
    "BasePlatformAdapter",
    "TaobaoAdapter",
    "JDAdapter",
    "BossZhipinAdapter",
    "BossCloakExperimentalAdapter",
    "Job51Adapter",
    "LiepinAdapter",
]
