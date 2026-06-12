"""Tests for the single canonical business API prefix."""

import pytest
from fastapi.testclient import TestClient

from app.main import app


def test_only_canonical_business_routes_are_registered():
    paths = {route.path for route in app.routes}

    canonical = {
        "/api/v1/auth/login",
        "/api/v1/products",
        "/api/v1/crawl/crawl-now",
        "/api/v1/events/stream",
        "/api/v1/scheduler/status",
        "/api/v1/auth/wechat/callback",
    }
    removed = {
        "/auth/login",
        "/products",
        "/products/crawl/crawl-now",
        "/events/stream",
        "/v1/auth/login",
        "/v1/products",
        "/v1/crawl/crawl-now",
        "/v1/events/stream",
    }

    assert canonical <= paths
    assert paths.isdisjoint(removed)


def test_canonical_api_root_returns_one_prefix():
    response = TestClient(app).get("/api/v1")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["prefixes"] == ["/api/v1"]


@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("POST", "/auth/login"),
        ("GET", "/products"),
        ("POST", "/products/crawl/crawl-now"),
        ("POST", "/v1/auth/login"),
        ("GET", "/v1/products"),
        ("POST", "/v1/crawl/crawl-now"),
    ],
)
def test_removed_business_aliases_return_404_without_redirect(method, path):
    response = TestClient(app).request(method, path, follow_redirects=False)

    assert response.status_code == 404
    assert "location" not in response.headers
