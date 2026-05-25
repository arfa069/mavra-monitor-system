"""Cross-platform path helpers for crawler runtime data.

Profile directories are always rooted at the project root's ``profiles/``
directory, organized as ``profiles/{platform}/{profile_key}``.
"""

from __future__ import annotations

from pathlib import Path

VALID_PLATFORMS = {
    "boss",
    "51job",
    "liepin",
    "jd",
    "taobao",
    "amazon",
}


def _project_root() -> Path:
    """Project root directory (4 levels up from this file)."""
    return Path(__file__).resolve().parent.parent.parent.parent


def _validate_segment(kind: str, value: str) -> None:
    if not value or value == "." or "/" in value or "\\" in value or ".." in Path(value).parts:
        raise ValueError(f"Invalid {kind}: {value!r}")


def build_profile_dir(platform: str, profile_key: str, root: str | Path | None = None) -> Path:
    """Build profile directory path.

    When *root* is ``None`` (default), resolves relative to the project root.
    Pass an explicit *root* (e.g. ``tmp_path`` in tests) to override.
    """
    if platform not in VALID_PLATFORMS:
        raise ValueError(f"Invalid platform: {platform!r}")
    _validate_segment("profile key", profile_key)
    base = Path(root).expanduser().resolve() if root is not None else _project_root()
    return base / "profiles" / platform / profile_key
