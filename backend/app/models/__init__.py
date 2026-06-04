"""Database models."""
from app.models.alert import Alert
from app.models.audit_log import UserAuditLog
from app.models.base import Base
from app.models.crawl_log import CrawlLog
from app.models.crawl_profile import CrawlProfile
from app.models.crawl_task import CrawlTaskRecord
from app.models.crawler_worker import CrawlerWorkerRecord
from app.models.job import Job, JobSearchConfig
from app.models.job_crawl_log import JobCrawlLog
from app.models.job_match import MatchResult, UserResume
from app.models.permission import Permission
from app.models.price_history import PriceHistory
from app.models.product import (
    Product,
    ProductPlatformCron,
    ProductPlatformProfileBinding,
)
from app.models.role import Role, role_permissions
from app.models.smart_home import SmartHomeConfig, SmartHomeEntityPreference
from app.models.system_log import SystemLog
from app.models.user import User

__all__ = [
    "Base",
    "User",
    "Product",
    "ProductPlatformCron",
    "ProductPlatformProfileBinding",
    "PriceHistory",
    "Alert",
    "CrawlLog",
    "Job",
    "JobSearchConfig",
    "JobCrawlLog",
    "UserResume",
    "MatchResult",
    "Role",
    "Permission",
    "role_permissions",
    "UserAuditLog",
    "SystemLog",
    "CrawlTaskRecord",
    "CrawlProfile",
    "CrawlerWorkerRecord",
    "SmartHomeConfig",
    "SmartHomeEntityPreference",
]
