"""Regenerate API artifacts and fail when tracked output changes."""

from __future__ import annotations

import os
import sys
import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
FRONTEND_ROOT = PROJECT_ROOT / "frontend"


def run(command: list[str], *, cwd: Path) -> None:
    subprocess.run(command, cwd=cwd, check=True)


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


if __name__ == "__main__":
    main()
