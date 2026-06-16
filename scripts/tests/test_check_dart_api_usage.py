from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "check_dart_api_usage.py"
SPEC = spec_from_file_location("check_dart_api_usage", SCRIPT_PATH)
assert SPEC and SPEC.loader
MODULE = module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def _check(tmp_path: Path, relative_path: str, content: str) -> list[str]:
    source = tmp_path / Path(relative_path).name
    source.write_text(content, encoding="utf-8")
    return MODULE.check_file(source, Path(relative_path))


def test_rejects_raw_dio_instantiation_in_feature_code(tmp_path):
    errors = _check(
        tmp_path,
        "features/jobs/api/jobs_api.dart",
        (
            "import 'package:dio/dio.dart';\n"
            "final client = Dio();\n"
            "Future<void> load() => client.get('/api/v1/jobs');\n"
        ),
    )

    assert any("Forbidden raw Dio" in error for error in errors)


def test_requires_generated_client_import_for_feature_api_code(tmp_path):
    errors = _check(
        tmp_path,
        "features/jobs/repositories/jobs_repository.dart",
        "class JobsRepository { Future<void> load() async {} }\n",
    )

    assert any("must import generated Dart API client" in error for error in errors)


def test_allows_feature_repository_that_wraps_generated_client(tmp_path):
    errors = _check(
        tmp_path,
        "features/jobs/repositories/jobs_repository.dart",
        (
            "import '../../../core/api/generated/api.dart';\n"
            "class JobsRepository { Future<void> load() async {} }\n"
        ),
    )

    assert errors == []


def test_allows_feature_data_importing_generated_package(tmp_path):
    errors = _check(
        tmp_path,
        "features/jobs/data/jobs_api.dart",
        (
            "import 'package:mavra_api/mavra_api.dart' as generated;\n"
            "class JobsApi { generated.MavraApi? api; }\n"
        ),
    )

    assert errors == []


def test_allows_generated_client_to_instantiate_dio(tmp_path):
    errors = _check(
        tmp_path,
        "core/api/generated/lib/src/api.dart",
        "import 'package:dio/dio.dart';\nfinal dio = Dio();\n",
    )

    assert errors == []


def test_allows_feature_screen_importing_repository(tmp_path):
    errors = _check(
        tmp_path,
        "features/jobs/jobs_page.dart",
        (
            "import 'repositories/jobs_repository.dart';\n"
            "class JobsPage { JobsRepository? repository; }\n"
        ),
    )

    assert errors == []


def test_allows_core_transport_owner_to_instantiate_dio(tmp_path):
    errors = _check(
        tmp_path,
        "core/api/api_client.dart",
        "import 'package:dio/dio.dart';\nfinal dio = Dio();\n",
    )

    assert errors == []
