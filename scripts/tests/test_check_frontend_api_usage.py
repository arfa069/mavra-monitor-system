from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "check_frontend_api_usage.py"
SPEC = spec_from_file_location("check_frontend_api_usage", SCRIPT_PATH)
assert SPEC and SPEC.loader
MODULE = module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def _check(tmp_path: Path, relative_path: str, content: str) -> list[str]:
    source = tmp_path / Path(relative_path).name
    source.write_text(content, encoding="utf-8")
    return MODULE.check_file(source, Path(relative_path))


def test_rejects_unlisted_axios_import_under_shared_api(tmp_path):
    errors = _check(
        tmp_path,
        "shared/api/rogue.ts",
        'import axios from "axios";\nexport const rogue = axios.create();\n',
    )

    assert any("Forbidden axios import" in error for error in errors)


def test_rejects_aliased_shared_api_client_import(tmp_path):
    errors = _check(
        tmp_path,
        "features/jobs/api/rogue.ts",
        (
            'import client from "@/shared/api/client";\n'
            'export const rogue = () => client.post("/jobs");\n'
        ),
    )

    assert any("Forbidden shared API client import" in error for error in errors)


def test_rejects_type_escape_in_feature_api(tmp_path):
    errors = _check(
        tmp_path,
        "features/jobs/api/jobs.ts",
        "export const value = response as unknown as Promise<string>;\n",
    )

    assert any("Forbidden type escape" in error for error in errors)


def test_allows_exact_blob_export_adapter(tmp_path):
    errors = _check(
        tmp_path,
        "features/jobs/api/profileBackupExport.ts",
        (
            'import api from "@/shared/api/client";\n'
            'import type { AxiosResponse } from "axios";\n'
            "export const download = (): Promise<AxiosResponse<Blob>> => "
            'api.post("/export");\n'
        ),
    )

    assert errors == []
