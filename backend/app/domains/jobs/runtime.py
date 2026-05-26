from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal


JobFailureCategory = Literal[
    "profile_unavailable",
    "profile_leased",
    "profile_login_required",
    "anti_bot",
    "waf",
    "challenge",
    "xsrf",
    "empty_result",
    "http_error",
    "parse_error",
    "detail_error",
    "cookie_refresh_failed",
    "timeout",
    "unknown",
]


@dataclass(frozen=True)
class JobCrawlRuntimeContext:
    platform: str
    profile_key: str
    profile_dir: Path
    task_id: str | None
    config_id: int | None
    run_id: str
    log_context: dict[str, object] = field(default_factory=dict)
