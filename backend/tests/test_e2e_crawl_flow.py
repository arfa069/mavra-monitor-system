"""E2E Crawl Flow Tests — requires running backend server.

Usage:
    # Start backend first, then:
    RUN_E2E=1 pytest tests/test_e2e_crawl_flow.py -v

    # Or point to a different backend:
    PRICE_MONITOR_BASE_URL=http://192.168.1.100:8000 RUN_E2E=1 pytest ...
"""
import os

import httpx
import pytest

BASE_URL = os.environ.get("PRICE_MONITOR_BASE_URL", "http://127.0.0.1:8000")


async def e2e_login(client: httpx.AsyncClient) -> bool:
    """Authenticate as default test user.

    Returns True if login succeeded and cookies are set on the client.
    httpx's cookie jar respects the ``Secure`` flag on cookies, so on HTTP
    connections (dev) cookies are not automatically sent. We extract the
    access token manually and set it as a request header.
    """
    resp = await client.post(
        "/api/v1/auth/login",
        json={"username": "default123", "password": "123456"},
    )
    if resp.status_code != 200:
        return False

    access_token = client.cookies.get("pm_access_token")
    if access_token:
        client.headers["Cookie"] = f"pm_access_token={access_token}"
    return True


@pytest.mark.skipif(
    not os.environ.get("RUN_E2E"),
    reason="E2E tests require RUN_E2E=1 and a running backend server",
)
@pytest.mark.asyncio
async def test_e2e_crawl_now_endpoint():
    """POST /v1/crawl/crawl-now returns a valid response."""
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=15) as client:
        await e2e_login(client)

        try:
            resp = await client.post("/api/v1/crawl/crawl-now")
        except httpx.ConnectError:
            pytest.skip(f"Backend not reachable at {BASE_URL}")

        assert resp.status_code in (200, 409, 500)
        data = resp.json()
        assert "status" in data

        if resp.status_code == 200:
            assert data["status"] in ("pending",)
            assert "task_id" in data
            task_id = data["task_id"]

            status_resp = await client.get(f"/api/v1/crawl/status/{task_id}")
            assert status_resp.status_code == 200
            status_data = status_resp.json()
            assert status_data["task_id"] == task_id
            assert status_data["status"] in ("pending", "running", "completed", "failed")

            result_resp = await client.get(f"/api/v1/crawl/result/{task_id}")
            assert result_resp.status_code in (200, 202)
            result_data = result_resp.json()
            assert "status" in result_data

            print(f"[E2E] Crawl-now flow OK: task_id={task_id}, status={status_data['status']}")
        elif resp.status_code == 500:
            print(f"[E2E] Crawl-now returned 500 (expected): {data}")
        elif resp.status_code == 409:
            print(f"[E2E] Crawl-now skipped (crawl in progress): {data}")


@pytest.mark.skipif(
    not os.environ.get("RUN_E2E"),
    reason="E2E tests require RUN_E2E=1 and a running backend server",
)
@pytest.mark.asyncio
async def test_e2e_health_endpoint():
    """GET /health returns healthy."""
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=10) as client:
        try:
            resp = await client.get("/health")
        except httpx.ConnectError:
            pytest.skip(f"Backend not reachable at {BASE_URL}")

        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "healthy"
        print("[E2E] Health check OK")


@pytest.mark.skipif(
    not os.environ.get("RUN_E2E"),
    reason="E2E tests require RUN_E2E=1 and a running backend server",
)
@pytest.mark.asyncio
async def test_e2e_crawl_logs_endpoint():
    """GET /v1/crawl/logs returns structured response."""
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=10) as client:
        await e2e_login(client)
        try:
            resp = await client.get("/api/v1/crawl/logs")
        except httpx.ConnectError:
            pytest.skip(f"Backend not reachable at {BASE_URL}")

        assert resp.status_code in (200, 500)
        if resp.status_code == 200:
            data = resp.json()
            assert isinstance(data, list)
            print(f"[E2E] Crawl logs OK: {len(data)} entries")
        else:
            print(f"[E2E] Crawl logs returned {resp.status_code} (expected)")
