"""Tests for legacy and v1 API route registration."""

from fastapi.testclient import TestClient

from app.main import app


def test_api_v1_and_legacy_routes_are_registered():
    """Business routes are exposed at legacy, /v1, and direct /api/v1 paths."""
    paths = {route.path for route in app.routes}

    expected_paths = {
        "/auth/login",
        "/v1/auth/login",
        "/api/v1/auth/login",
        "/products",
        "/v1/products",
        "/api/v1/products",
        "/products/crawl/crawl-now",
        "/v1/crawl/crawl-now",
        "/api/v1/crawl/crawl-now",
        "/events/stream",
        "/v1/events/stream",
        "/api/v1/events/stream",
        "/scheduler/status",
        "/v1/scheduler/status",
        "/api/v1/scheduler/status",
    }

    assert expected_paths <= paths


def test_api_v1_roots_are_registered():
    """Opening the API base URL should not produce a 404."""
    paths = {route.path for route in app.routes}

    assert {"/v1", "/api/v1"} <= paths


def test_api_v1_root_returns_service_info():
    client = TestClient(app)

    response = client.get("/v1")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
