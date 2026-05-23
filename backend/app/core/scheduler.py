"""Shared scheduler helpers."""

import logging

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
