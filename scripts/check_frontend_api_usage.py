#!/usr/bin/env python3
"""Check frontend codebase for disallowed direct api/axios usage."""

import os
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
FRONTEND_SRC = PROJECT_ROOT / "frontend" / "src"

# Allow list for files using api.get/post/put/patch/delete
API_CALL_ALLOWLIST = {
    Path("shared/api/client.ts"),
    Path("shared/api/mutator.ts"),
    Path("features/jobs/api/profileBackup.ts"),
}

# Allow list for files importing from 'axios'
AXIOS_IMPORT_ALLOWLIST = {
    Path("shared/api/client.ts"),
    Path("shared/api/mutator.ts"),
    Path("features/jobs/api/profileBackup.ts"),
}

# Regex to check for direct api calls
API_CALL_RE = re.compile(r"\bapi\.(get|post|put|patch|delete)\s*\(")

# Regex to check for imports from 'axios'
AXIOS_IMPORT_RE = re.compile(r'\bimport\s+.*\s+from\s+["\']axios["\']')


def check_file(file_path: Path, relative_path: Path) -> list[str]:
    errors = []
    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as e:
        return [f"Could not read {relative_path}: {e}"]

    # Check for direct api calls
    if relative_path not in API_CALL_ALLOWLIST:
        for i, line in enumerate(content.splitlines(), 1):
            if API_CALL_RE.search(line):
                errors.append(
                    f"Forbidden direct api call in {relative_path}:{i} -> {line.strip()}"
                )

    # Check for axios imports
    # Note: we check if the relative path starts with 'shared/api/' as well
    is_shared_api = relative_path.parts[:2] == ("shared", "api")
    if not is_shared_api and relative_path not in AXIOS_IMPORT_ALLOWLIST:
        for i, line in enumerate(content.splitlines(), 1):
            if AXIOS_IMPORT_RE.search(line):
                errors.append(
                    f"Forbidden axios import in {relative_path}:{i} -> {line.strip()}"
                )

    return errors


def main() -> None:
    errors = []
    if not FRONTEND_SRC.exists():
        print(f"Directory {FRONTEND_SRC} does not exist.")
        sys.exit(1)

    for root, _, files in os.walk(FRONTEND_SRC):
        for file in files:
            if not file.endswith((".ts", ".tsx")):
                continue
            file_path = Path(root) / file
            relative_path = file_path.relative_to(FRONTEND_SRC)
            errors.extend(check_file(file_path, relative_path))

    if errors:
        print("API usage validation failed with the following errors:")
        for error in errors:
            print(f"  - {error}")
        print("\nPlease use the generated Orval hooks instead of direct API calls.")
        sys.exit(1)

    print("API usage validation passed successfully.")


if __name__ == "__main__":
    main()
