"""Profile directory helpers.

Profile directories are always rooted at the project root's ``profiles/``
directory, organized as ``profiles/{profile_key}``.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

PROFILE_ROOT_ENV = "PRICE_MONITOR_PROFILE_ROOT"


def _project_root() -> Path:
    """Project root directory (4 levels up from this file)."""
    return Path(__file__).resolve().parent.parent.parent.parent


def _validate_segment(kind: str, value: str) -> None:
    if not value or value == "." or "/" in value or "\\" in value or ".." in Path(value).parts:
        raise ValueError(f"Invalid {kind}: {value!r}")


def build_profile_dir(profile_key: str, root: str | Path | None = None) -> Path:
    """Build profile directory path under ``profiles/{profile_key}``.

    When *root* is ``None`` (default), resolves relative to the project root.
    Pass an explicit *root* (e.g. ``tmp_path`` in tests) to override.
    """
    _validate_segment("profile key", profile_key)
    if root is not None:
        base = Path(root).expanduser().resolve()
    elif env_root := os.getenv(PROFILE_ROOT_ENV):
        base = Path(env_root).expanduser().resolve()
    else:
        base = _project_root()
    return base / "profiles" / profile_key


def resolve_profile_key(obj: Any | None) -> str:
    """Return ``obj.profile_key`` if available, otherwise ``'default'``."""
    raw = getattr(obj, "profile_key", None) if obj is not None else None
    return raw or "default"
