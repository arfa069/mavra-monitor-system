import importlib.util
from pathlib import Path
from types import SimpleNamespace

import pytest


def load_experiment_module():
    script_path = Path(__file__).resolve().parents[2] / "scripts" / "firecrawl_jd_profile_experiment.py"
    spec = importlib.util.spec_from_file_location("firecrawl_jd_profile_experiment", script_path)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@pytest.mark.asyncio
async def test_check_login_profile_does_not_print_cookie_value(monkeypatch, capsys):
    module = load_experiment_module()

    monkeypatch.setenv("FIRECRAWL_API_KEY", "secret-key")

    async def fake_execute_code(*_args, **kwargs):
        assert "cookies:" not in kwargs["code"]
        return {
            "result": {
                "title": "JD",
                "url": "https://passport.jd.com/",
                "hasCookies": True,
                "text": "logged in",
            }
        }

    monkeypatch.setattr(module, "_execute_code", fake_execute_code)

    await module.check_login_profile(
        SimpleNamespace(
            api_url="https://api.test",
            timeout_seconds=10.0,
            session_id="session-1",
        )
    )

    output = capsys.readouterr().out
    assert "pt_key=" not in output
    assert "hasCookies" in output
