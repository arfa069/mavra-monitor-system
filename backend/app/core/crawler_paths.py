"""Cross-platform path helpers for crawler runtime data."""

from __future__ import annotations

import os
from pathlib import Path

VALID_PLATFORMS = {
    "boss",
    "51job",
    "liepin",
    "jd",
    "taobao",
    "amazon",
}


def default_price_monitor_home() -> Path:
    if os.name == "nt":
        return Path("C:/price-monitor")
    return Path("/price-monitor")


def resolve_price_monitor_home(value: str | None = None) -> Path:
    raw = value or os.environ.get("PRICE_MONITOR_HOME")
    path = Path(raw).expanduser() if raw else default_price_monitor_home()
    return path.resolve()


def _validate_segment(kind: str, value: str) -> None:
    if not value or "/" in value or "\\" in value or ".." in Path(value).parts:
        raise ValueError(f"Invalid {kind}: {value!r}")


def build_profile_dir(root: str | Path, platform: str, profile_key: str) -> Path:
    if platform not in VALID_PLATFORMS:
        raise ValueError(f"Invalid platform: {platform!r}")
    _validate_segment("profile key", profile_key)
    return Path(root).expanduser().resolve() / "profiles" / platform / profile_key
