from pathlib import Path

import pytest


def test_build_profile_dir_defaults_to_project_root():
    """Without explicit root, resolves relative to project root."""
    from app.core import crawler_paths
    # Restore original _project_root in case it was patched by conftest
    import app.core.crawler_paths as cp
    def _original_root():
        return Path(cp.__file__).resolve().parent.parent.parent.parent
    cp._project_root = _original_root

    result = crawler_paths.build_profile_dir("default")
    expected_root = Path(crawler_paths.__file__).resolve().parent.parent.parent.parent
    assert result == expected_root / "profiles" / "default"


def test_build_profile_dir_accepts_explicit_root(tmp_path):
    """Explicit root overrides the default project root."""
    from app.core.crawler_paths import build_profile_dir

    assert build_profile_dir("profile-a", root=tmp_path) == (
        tmp_path / "profiles" / "profile-a"
    )


def test_build_profile_dir_rejects_path_traversal(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir("../profile-a", root=tmp_path)


def test_build_profile_dir_rejects_empty_key(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir("", root=tmp_path)


def test_build_profile_dir_rejects_dot_key(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir(".", root=tmp_path)
