from __future__ import annotations

from app.workers import crawler


def test_should_run_maintenance_respects_interval():
    should_run = getattr(crawler, "_should_run_maintenance", None)

    assert should_run is not None
    assert should_run(last_run_at=None, now=100.0, interval_seconds=60.0)
    assert not should_run(last_run_at=80.0, now=100.0, interval_seconds=60.0)
    assert should_run(last_run_at=39.0, now=100.0, interval_seconds=60.0)
