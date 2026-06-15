"""Regenerate API artifacts and fail when tracked output changes."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
FRONTEND_ROOT = PROJECT_ROOT / "frontend"
DART_GENERATOR_SCRIPT = PROJECT_ROOT / "scripts" / "generate_dart_client.ps1"
DART_GENERATOR_CONFIG = FRONTEND_ROOT / "openapi-generator-config.yaml"
OPENAPI_TOOLS_CONFIG = FRONTEND_ROOT / "openapitools.json"
FLUTTER_PUBSPEC = FRONTEND_ROOT / "pubspec.yaml"
DART_GENERATED_ROOT = FRONTEND_ROOT / "lib" / "core" / "api" / "generated"


def run(command: list[str], *, cwd: Path) -> None:
    subprocess.run(command, cwd=cwd, check=True)


def verify_dart_generator_pins() -> None:
    if not DART_GENERATOR_SCRIPT.exists():
        raise SystemExit(f"Missing Dart generator script: {DART_GENERATOR_SCRIPT}")
    if not DART_GENERATOR_CONFIG.exists():
        raise SystemExit(f"Missing Dart generator config: {DART_GENERATOR_CONFIG}")
    if not OPENAPI_TOOLS_CONFIG.exists():
        raise SystemExit(f"Missing OpenAPI tools config: {OPENAPI_TOOLS_CONFIG}")

    with OPENAPI_TOOLS_CONFIG.open(encoding="utf-8") as fh:
        tools = json.load(fh)
    version = tools.get("generator-cli", {}).get("version")
    if version != "7.23.0":
        raise SystemExit(f"Expected OpenAPI generator 7.23.0, found {version!r}")


def verify_dart_generated_client_if_present() -> None:
    verify_dart_generator_pins()
    if not FLUTTER_PUBSPEC.exists():
        print("Flutter scaffold not present; Dart client generation check deferred.")
        return
    if not DART_GENERATED_ROOT.exists():
        raise SystemExit(f"Missing generated Dart client: {DART_GENERATED_ROOT}")

    powershell = "powershell.exe" if os.name == "nt" else "pwsh"
    run(
        [
            powershell,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(DART_GENERATOR_SCRIPT),
            "-Check",
        ],
        cwd=PROJECT_ROOT,
    )


def main() -> None:
    npm = "npm.cmd" if os.name == "nt" else "npm"

    run([sys.executable, "scripts/export_openapi.py"], cwd=PROJECT_ROOT)
    run([npm, "run", "api:generate"], cwd=FRONTEND_ROOT)
    run(
        [
            "git",
            "diff",
            "--exit-code",
            "--",
            "frontend/openapi.json",
            "frontend/src/shared/api/generated",
        ],
        cwd=PROJECT_ROOT,
    )
    verify_dart_generated_client_if_present()


if __name__ == "__main__":
    main()
