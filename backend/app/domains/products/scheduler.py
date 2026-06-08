"""Product crawl cron scheduler manager."""

import logging
import zoneinfo

from apscheduler.triggers.cron import CronTrigger

from app.core.scheduler import BaseScheduler

logger = logging.getLogger(__name__)


class ProductCronScheduler(BaseScheduler):
    """Manages per-platform APScheduler jobs for product crawl scheduling."""

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

        from app.domains.crawling.scheduler_service import crawl_products_by_platform

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

    async def _fetch_cron_configs(self):
        from sqlalchemy import select

        from app.database import AsyncSessionLocal
        from app.models.product import ProductPlatformCron

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(ProductPlatformCron).where(
                    ProductPlatformCron.cron_expression.isnot(None),
                )
            )
            return list(result.scalars().all())

    def _add_job_from_config(self, config) -> None:
        self.add_job(
            user_id=config.user_id,
            platform=config.platform,
            cron_expression=config.cron_expression,
            timezone=config.cron_timezone or "Asia/Shanghai",
        )

    def _config_label(self, config) -> str:
        return f"product platform cron config {config.user_id}:{config.platform}"

    def get_next_run_times(self, user_id: int | None = None) -> dict[str, dict]:
        """Return next run time info for registered platform jobs."""
        result: dict[str, dict] = {}
        for job in self._scheduler.get_jobs():
            if not job.id.startswith(self.JOB_ID_PREFIX):
                continue
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
