"""Shared scheduler helpers."""

from __future__ import annotations

import logging
from typing import Any

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

    async def sync_all(self) -> None:
        """Sync scheduler state with DB cron configs on startup."""
        configs = await self._fetch_cron_configs()
        synced_count = 0
        for config in configs:
            try:
                self._add_job_from_config(config)
                synced_count += 1
            except Exception as e:
                logger.error(
                    "Skipping registration of %s due to startup sync error: %s",
                    self._config_label(config),
                    e,
                    exc_info=True,
                )
        logger.info(
            "%s synced: %d/%d jobs registered",
            self.__class__.__name__,
            synced_count,
            len(configs),
        )

    async def _fetch_cron_configs(self) -> list[Any]:
        raise NotImplementedError

    def _add_job_from_config(self, config: Any) -> None:
        raise NotImplementedError

    def _config_label(self, config: Any) -> str:
        return str(getattr(config, "id", config))
