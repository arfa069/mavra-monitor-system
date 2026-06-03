import httpx
import pytest

from app.domains.smart_home.ha_client import HomeAssistantClient, HomeAssistantError


@pytest.mark.asyncio
async def test_ping_returns_version():
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.headers["Authorization"] == "Bearer token"
        assert request.url.path == "/api/"
        return httpx.Response(200, json={"message": "API running.", "version": "2026.6.0"})

    client = HomeAssistantClient(
        base_url="http://ha.local:8123",
        token="token",
        transport=httpx.MockTransport(handler),
    )

    assert await client.ping() == "2026.6.0"


@pytest.mark.asyncio
async def test_get_states_returns_json():
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/api/states"
        return httpx.Response(200, json=[{"entity_id": "switch.kitchen", "state": "on", "attributes": {}}])

    client = HomeAssistantClient(
        base_url="http://ha.local:8123",
        token="token",
        transport=httpx.MockTransport(handler),
    )

    assert await client.get_states() == [{"entity_id": "switch.kitchen", "state": "on", "attributes": {}}]


@pytest.mark.asyncio
async def test_call_service_posts_entity_id():
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/api/services/switch/turn_off"
        assert request.method == "POST"
        assert request.read() == b'{"entity_id":"switch.kitchen"}'
        return httpx.Response(200, json=[])

    client = HomeAssistantClient(
        base_url="http://ha.local:8123",
        token="token",
        transport=httpx.MockTransport(handler),
    )

    await client.call_service("switch", "turn_off", {"entity_id": "switch.kitchen"})


@pytest.mark.asyncio
async def test_http_error_maps_to_home_assistant_error():
    client = HomeAssistantClient(
        base_url="http://ha.local:8123",
        token="token",
        transport=httpx.MockTransport(lambda request: httpx.Response(401, json={"message": "Unauthorized"})),
    )

    with pytest.raises(HomeAssistantError, match="401"):
        await client.ping()
