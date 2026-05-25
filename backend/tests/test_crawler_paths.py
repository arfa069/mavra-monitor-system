from pathlib import Path

import pytest


def test_build_profile_dir_defaults_to_project_root():
    """Without explicit root, resolves relative to project root."""
    from app.core import crawler_paths

    result = crawler_paths.build_profile_dir("boss", "default")
    expected_root = Path(crawler_paths.__file__).resolve().parent.parent.parent.parent
    assert result == expected_root / "profiles" / "boss" / "default"


def test_build_profile_dir_accepts_explicit_root(tmp_path):
    """Explicit root overrides the default project root."""
    from app.core.crawler_paths import build_profile_dir

    assert build_profile_dir("boss", "profile-a", root=tmp_path) == (
        tmp_path / "profiles" / "boss" / "profile-a"
    )


def test_build_profile_dir_rejects_path_traversal(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir("boss", "../profile-a", root=tmp_path)


def test_build_profile_dir_rejects_unknown_platform(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid platform"):
        build_profile_dir("unknown", "profile-a", root=tmp_path)


def test_build_profile_dir_rejects_empty_key(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir("boss", "", root=tmp_path)


def test_build_profile_dir_rejects_dot_key(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir("boss", ".", root=tmp_path)
