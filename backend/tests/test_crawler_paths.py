from pathlib import Path

import pytest


def test_default_price_monitor_home_windows(monkeypatch):
    from app.core import crawler_paths

    monkeypatch.delenv("PRICE_MONITOR_HOME", raising=False)
    monkeypatch.setattr(crawler_paths.os, "name", "nt")

    assert crawler_paths.default_price_monitor_home() == Path("C:/price-monitor")


def test_default_price_monitor_home_posix(monkeypatch):
    from app.core import crawler_paths

    monkeypatch.delenv("PRICE_MONITOR_HOME", raising=False)
    monkeypatch.setattr(crawler_paths.os, "name", "posix")

    assert crawler_paths.default_price_monitor_home() == Path("/price-monitor")


def test_profile_dir_rejects_path_traversal(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir(tmp_path, "boss", "../profile-a")


def test_profile_dir_groups_by_platform(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    assert build_profile_dir(tmp_path, "boss", "profile-a") == (
        tmp_path / "profiles" / "boss" / "profile-a"
    )


def test_resolve_price_monitor_home_uses_env_var(monkeypatch, tmp_path):
    from app.core.crawler_paths import resolve_price_monitor_home

    monkeypatch.setenv("PRICE_MONITOR_HOME", str(tmp_path))
    result = resolve_price_monitor_home()
    assert result == tmp_path.resolve()


def test_resolve_price_monitor_home_prefers_argument(monkeypatch, tmp_path):
    from app.core.crawler_paths import resolve_price_monitor_home

    monkeypatch.setenv("PRICE_MONITOR_HOME", "/ignored")
    result = resolve_price_monitor_home(str(tmp_path))
    assert result == tmp_path.resolve()


def test_build_profile_dir_rejects_unknown_platform(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid platform"):
        build_profile_dir(tmp_path, "unknown", "profile-a")


def test_build_profile_dir_rejects_empty_key(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir(tmp_path, "boss", "")


def test_build_profile_dir_rejects_dot_key(tmp_path):
    from app.core.crawler_paths import build_profile_dir

    with pytest.raises(ValueError, match="Invalid profile key"):
        build_profile_dir(tmp_path, "boss", ".")
