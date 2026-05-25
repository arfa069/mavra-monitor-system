"""Job search cron scheduler manager."""

import logging
import zoneinfo

from apscheduler.triggers.cron import CronTrigger

from app.core.scheduler import BaseScheduler

logger = logging.getLogger(__name__)


class JobConfigScheduler(BaseScheduler):
    """Manages per-config APScheduler jobs for job search crawl scheduling."""

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

        from app.domains.jobs.crawl_service import crawl_scheduled_config

        self._scheduler.add_job(
            crawl_scheduled_config,
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
