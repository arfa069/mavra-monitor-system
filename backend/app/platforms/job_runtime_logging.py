from __future__ import annotations

from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from app.core.json_utils import safe_json_dumps
from app.domains.jobs.runtime import JobCrawlRuntimeContext


def default_job_log_path(platform: str) -> Path:
    timestamp = datetime.now(UTC).strftime("%Y%m%d_%H%M%S")
    return Path(__file__).resolve().parent.parent.parent / "logs" / f"{platform}_job_adapter_{timestamp}.jsonl"


class JobRuntimeJsonlLogger:
    def __init__(
        self,
        *,
        platform: str,
        context: JobCrawlRuntimeContext | None,
        log_path: str | Path | None = None,
        enabled: bool = True,
    ) -> None:
        self.platform = platform
        self.context = context
        self.enabled = enabled
        self.log_path = Path(log_path) if log_path else default_job_log_path(platform)

    def log(self, event: str, *, status: str, message: str = "", **fields: Any) -> None:
        if not self.enabled:
            return
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        payload: dict[str, Any] = {
            "timestamp": datetime.now(UTC).isoformat(),
            "platform": self.platform,
            "profile_key": self.context.profile_key if self.context else None,
            "task_id": self.context.task_id if self.context else None,
            "config_id": self.context.config_id if self.context else None,
            "event": event,
            "status": status,
            "message": message,
        }
        payload.update(fields)
        with self.log_path.open("a", encoding="utf-8") as handle:
            handle.write(safe_json_dumps(payload, default=str) + "\n")
