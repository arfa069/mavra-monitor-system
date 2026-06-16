#!/usr/bin/env python3
"""Check Flutter code for generated-client API usage boundaries."""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
FRONTEND_LIB = PROJECT_ROOT / "frontend" / "lib"

TRANSPORT_OWNER_ALLOWLIST = {
    Path("core/api/api_client.dart"),
    Path("core/realtime/realtime_client.dart"),
    Path("core/files/file_service.dart"),
}

FEATURE_API_DIRS = {"api", "data", "repository", "repositories"}

RAW_DIO_RE = re.compile(r"\bDio\s*\(")
GENERATED_IMPORT_RE = re.compile(
    r"\bimport\s+['\"](?:[^'\"]*core/api/generated/[^'\"]*|"
    r"package:mavra_api/mavra_api\.dart)['\"]"
)


def _is_feature_api_boundary(relative_path: Path) -> bool:
    return (
        len(relative_path.parts) >= 3
        and relative_path.parts[0] == "features"
        and any(part in FEATURE_API_DIRS for part in relative_path.parts[2:-1])
    )


def _is_generated_client(relative_path: Path) -> bool:
    return len(relative_path.parts) >= 3 and relative_path.parts[:3] == (
        "core",
        "api",
        "generated",
    )


def check_file(file_path: Path, relative_path: Path) -> list[str]:
    errors: list[str] = []
    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as exc:
        return [f"Could not read {relative_path}: {exc}"]

    if relative_path not in TRANSPORT_OWNER_ALLOWLIST and not _is_generated_client(
        relative_path
    ):
        for i, line in enumerate(content.splitlines(), 1):
            if RAW_DIO_RE.search(line):
                errors.append(
                    f"Forbidden raw Dio instantiation in {relative_path}:{i} -> "
                    f"{line.strip()}"
                )

    if (
        _is_feature_api_boundary(relative_path)
        and not GENERATED_IMPORT_RE.search(content)
    ):
        errors.append(
            "Feature API code must import generated Dart API client in "
            f"{relative_path}"
        )

    return errors


def main() -> None:
    if not FRONTEND_LIB.exists():
        print(f"Directory {FRONTEND_LIB} does not exist; skipping Dart API usage check.")
        return

    errors: list[str] = []
    for root, _, files in os.walk(FRONTEND_LIB):
        for file in files:
            if not file.endswith(".dart"):
                continue
            file_path = Path(root) / file
            relative_path = file_path.relative_to(FRONTEND_LIB)
            errors.extend(check_file(file_path, relative_path))

    if errors:
        print("Dart API usage validation failed with the following errors:")
        for error in errors:
            print(f"  - {error}")
        print("\nUse generated Dart API clients or feature repositories that wrap them.")
        sys.exit(1)

    print("Dart API usage validation passed successfully.")


if __name__ == "__main__":
    main()
