"""JobConfigScheduler: per-config cron management for job search crawl."""

import logging
import zoneinfo

from apscheduler.triggers.cron import CronTrigger

logger = logging.getLogger(__name__)


class BaseScheduler:
    """Abstract base class containing common scheduler operations."""

    def __init__(self, scheduler) -> None:
        self._scheduler = scheduler

    def _remove_job_by_id(self, job_id: str) -> None:
        """Remove a job by its ID if it exists."""
        if self._scheduler.get_job(job_id):
            self._scheduler.remove_job(job_id)
            logger.info("Removed cron job %s", job_id)


class JobConfigScheduler(BaseScheduler):
    """Manages per-config APScheduler jobs for job search crawl scheduling.

    Each JobSearchConfig can have its own cron expression. This manager
    encapsulates the add/remove/sync lifecycle, using job IDs in the
    format ``job_config_cron_{config_id}``.
    """

    JOB_ID_PREFIX = "job_config_cron_"

    def add_job(
        self,
        config_id: int,
        cron_expression: str,
        timezone: str = "Asia/Shanghai",
    ) -> None:
        """Register or replace a cron job for the given config."""
        if not cron_expression or not cron_expression.strip():
            self.remove_job(config_id)
            return

        job_id = self._job_id(config_id)
        tz = zoneinfo.ZoneInfo(timezone)

        from app.services.job_crawl import crawl_single_config

        self._scheduler.add_job(
            crawl_single_config,
            trigger=CronTrigger.from_crontab(cron_expression, timezone=tz),
            id=job_id,
            name=f"JobConfig crawl #{config_id}",
            replace_existing=True,
            max_instances=1,
            kwargs={
                "config_id": config_id,
                "cron_expression": cron_expression,
            },
        )
        logger.info(
            "Registered cron job %s with schedule '%s' (tz=%s)",
            job_id, cron_expression, timezone,
        )

    def remove_job(self, config_id: int) -> None:
        """Remove the cron job for a config (if it exists)."""
        self._remove_job_by_id(self._job_id(config_id))

    async def sync_all(self) -> None:
        """Sync scheduler state with the database on startup."""
        from sqlalchemy import select

        from app.database import AsyncSessionLocal
        from app.models.job import JobSearchConfig

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(JobSearchConfig).where(
                    JobSearchConfig.cron_expression.isnot(None),
                )
            )
            configs = result.scalars().all()

        synced_count = 0
        for config in configs:
            try:
                self.add_job(
                    config_id=config.id,
                    cron_expression=config.cron_expression,
                    timezone=config.cron_timezone or "Asia/Shanghai",
                )
                synced_count += 1
            except Exception as e:
                logger.error(
                    "Skipping registration of job config #%d due to startup sync error: %s",
                    config.id, e, exc_info=True
                )

        logger.info("JobConfigScheduler synced: %d/%d config jobs registered", synced_count, len(configs))

    def get_next_run_times(self) -> dict[int, dict]:
        """Return next run time info for all registered config jobs."""
        result: dict[int, dict] = {}
        for job in self._scheduler.get_jobs():
            if not job.id.startswith(self.JOB_ID_PREFIX):
                continue
            config_id = int(job.id[len(self.JOB_ID_PREFIX):])
            cron_expr = job.kwargs.get("cron_expression") or str(job.trigger)
            result[config_id] = {
                "cron_expression": cron_expr,
                "next_run_at": job.next_run_time.isoformat() if job.next_run_time else None,
            }
        return result

    def _job_id(self, config_id: int) -> str:
        return f"{self.JOB_ID_PREFIX}{config_id}"


class ProductCronScheduler(BaseScheduler):
    """Manages per-platform APScheduler jobs for product crawl scheduling.

    Each platform (taobao, jd, amazon) can have its own cron expression.
    Job IDs follow the format ``product_cron_{user_id}:{platform}`` to
    support multi-user isolation.
    """

    JOB_ID_PREFIX = "product_cron_"

    def add_job(
        self,
        user_id: int,
        platform: str,
        cron_expression: str,
        timezone: str = "Asia/Shanghai",
    ) -> None:
        """Register or replace a cron job for the given user + platform."""
        if not cron_expression or not cron_expression.strip():
            self.remove_job(user_id=user_id, platform=platform)
            return

        job_id = self._job_id(user_id, platform)
        tz = zoneinfo.ZoneInfo(timezone)

        from app.services.scheduler_service import crawl_products_by_platform

        self._scheduler.add_job(
            crawl_products_by_platform,
            trigger=CronTrigger.from_crontab(cron_expression, timezone=tz),
            id=job_id,
            name=f"Product crawl user={user_id} {platform}",
            replace_existing=True,
            max_instances=1,
            kwargs={
                "user_id": user_id,
                "platform": platform,
                "cron_expression": cron_expression,
            },
        )
        logger.info(
            "Registered cron job %s with schedule '%s' (tz=%s)",
            job_id, cron_expression, timezone,
        )

    def remove_job(self, user_id: int, platform: str) -> None:
        """Remove the cron job for a user+platform (if it exists)."""
        self._remove_job_by_id(self._job_id(user_id, platform))

    async def sync_all(self) -> None:
        """Register cron jobs for all existing product platform cron configs."""
        from sqlalchemy import select

        from app.database import AsyncSessionLocal
        from app.models.product import ProductPlatformCron

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(ProductPlatformCron).where(
                    ProductPlatformCron.cron_expression.isnot(None),
                )
            )
            configs = result.scalars().all()

        synced_count = 0
        for config in configs:
            try:
                self.add_job(
                    user_id=config.user_id,
                    platform=config.platform,
                    cron_expression=config.cron_expression,
                    timezone=config.cron_timezone or "Asia/Shanghai",
                )
                synced_count += 1
            except Exception as e:
                logger.error(
                    "Skipping registration of product platform cron config %d:%s due to startup sync error: %s",
                    config.user_id, config.platform, e, exc_info=True
                )

        logger.info("ProductCronScheduler synced: %d/%d platform jobs registered", synced_count, len(configs))

    def get_next_run_times(self, user_id: int | None = None) -> dict[str, dict]:
        """Return next run time info for registered platform jobs.

        Args:
            user_id: If provided, only return jobs for this user.
                     The dict keys will be platform names (no user_id prefix).
                     Without user_id, keys remain user_id:platform to avoid collisions.
        """
        result: dict[str, dict] = {}
        for job in self._scheduler.get_jobs():
            if not job.id.startswith(self.JOB_ID_PREFIX):
                continue
            # job id format: product_cron_{user_id}:{platform}
            suffix = job.id[len(self.JOB_ID_PREFIX):]
            job_user_id, separator, platform = suffix.partition(":")
            if not separator:
                continue
            if user_id is not None and job_user_id != str(user_id):
                continue
            key = platform if user_id is not None else suffix
            cron_expr = job.kwargs.get("cron_expression") or str(job.trigger)
            result[key] = {
                "cron_expression": cron_expr,
                "next_run_at": job.next_run_time.isoformat() if job.next_run_time else None,
            }
        return result

    def _job_id(self, user_id: int, platform: str) -> str:
        return f"{self.JOB_ID_PREFIX}{user_id}:{platform}"
