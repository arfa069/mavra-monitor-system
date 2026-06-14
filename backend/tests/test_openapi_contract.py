"""OpenAPI contract regression tests."""

from fastapi.routing import APIRoute

from app.main import API_PREFIX, app

HTTP_METHODS = {"get", "post", "put", "patch", "delete"}


def _openapi_path(path: str) -> str:
    import re
    return re.sub(r"{([^:}]+):[^}]+}", r"{\1}", path)


def _operation(path: str, method: str) -> dict:
    return app.openapi()["paths"][_openapi_path(path)][method]


def _expected_operation_id(route: APIRoute) -> str:
    tag = str((route.tags or ["default"])[0]).replace("-", "_")
    return f"{tag}_{route.name}"


def test_operation_ids_are_stable_and_unique():
    routes = [
        route
        for route in app.routes
        if isinstance(route, APIRoute)
    ]
    expected = [_expected_operation_id(route) for route in routes]

    assert len(expected) == len(set(expected))
    for route in routes:
        method = next(iter(route.methods)).lower()
        assert _operation(route.path, method)["operationId"] == _expected_operation_id(
            route
        )


def test_business_openapi_paths_use_only_the_canonical_prefix():
    paths = set(app.openapi()["paths"])
    business_paths = {
        path
        for path in paths
        if path not in {"/health", "/health/detailed", "/blog-media/{file_name}"}
    }

    assert all(path == API_PREFIX or path.startswith(f"{API_PREFIX}/") for path in business_paths)
    assert not any(path.startswith("/v1/") for path in paths)


def test_special_response_media_types_are_declared():
    schema = app.openapi()

    for path in (
        "/api/v1/events/stream",
        "/api/v1/dashboard/events",
        "/api/v1/smart-home/entities/stream",
    ):
        content = schema["paths"][path]["get"]["responses"]["200"]["content"]
        assert set(content) == {"text/event-stream"}

    export_content = schema["paths"][
        "/api/v1/crawl-profiles/{profile_key}/export"
    ]["post"]["responses"]["200"]["content"]
    assert set(export_content) == {"application/octet-stream"}

    callback_responses = schema["paths"]["/api/v1/auth/wechat/callback"]["get"][
        "responses"
    ]
    assert "302" in callback_responses


SPECIAL_OPERATIONS = {
    ("get", "/api/v1/events/stream"),
    ("get", "/api/v1/dashboard/events"),
    ("get", "/api/v1/smart-home/entities/stream"),
    ("post", "/api/v1/crawl-profiles/{profile_key}/export"),
    ("get", "/api/v1/auth/wechat/callback"),
    ("get", "/blog-media/{file_name}"),
}


def test_json_success_responses_have_explicit_schemas():
    failures: list[str] = []

    for path, path_item in app.openapi()["paths"].items():
        for method, operation in path_item.items():
            if method not in HTTP_METHODS or (method, path) in SPECIAL_OPERATIONS:
                continue
            for status_code, response in operation.get("responses", {}).items():
                if not str(status_code).startswith("2"):
                    continue
                content = response.get("content", {})
                if not content:
                    continue
                schema = content.get("application/json", {}).get("schema")
                if schema == {} or schema is None:
                    failures.append(
                        f"{method.upper()} {path} {status_code} "
                        f"{operation.get('operationId')}"
                    )

    assert failures == []
