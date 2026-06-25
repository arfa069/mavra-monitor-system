import re
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "start_server.ps1"


def _script() -> str:
    return SCRIPT_PATH.read_text(encoding="utf-8")


def test_default_flutter_frontend_uses_web_server_on_3000():
    script = _script()

    assert "flutter run -d web-server" in script
    assert "--web-hostname 127.0.0.1" in script
    assert "--web-port 3000" in script
    assert (
        "--dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1"
        in script
    )


def test_default_launcher_includes_worker_and_blog_frontend():
    script = _script()

    assert "-m app.workers.crawler --kind all --concurrency $CrawlerConcurrency" in script
    assert "npm run dev -- --port 3001" in script


def test_launcher_declares_current_control_switches():
    script = _script()

    for switch_name in [
        "BackendOnly",
        "NoCrawlerWorker",
        "NoBlogFrontend",
        "ChromeDev",
        "StaticFrontend",
        "FlutterDev",
    ]:
        assert re.search(rf"\[switch\]\${switch_name}\b", script)


def test_static_frontend_is_the_only_mode_that_requires_build_output():
    script = _script()
    lines = script.splitlines()
    error_line_index = next(
        index
        for index, line in enumerate(lines)
        if "Flutter Web build not found" in line
    )
    guard_line = lines[error_line_index - 1]

    assert "$StaticFrontend" in guard_line
    assert "$FlutterDev" not in guard_line
    assert "$ChromeDev" not in guard_line
