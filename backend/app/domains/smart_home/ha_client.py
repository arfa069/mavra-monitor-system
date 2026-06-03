"""Home Assistant API client."""
from __future__ import annotations

import json
from collections.abc import AsyncIterator
from typing import Any

import httpx
import websockets


class HomeAssistantError(RuntimeError):
    """Raised when Home Assistant cannot fulfill a request."""


class HomeAssistantClient:
    def __init__(
        self,
        *,
        base_url: str,
        token: str,
        timeout: float = 10.0,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.timeout = timeout
        self.transport = transport

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
        }

    async def _request(self, method: str, path: str, **kwargs: Any) -> Any:
        async with httpx.AsyncClient(
            base_url=self.base_url,
            headers=self._headers(),
            timeout=self.timeout,
            transport=self.transport,
        ) as client:
            try:
                response = await client.request(method, path, **kwargs)
                response.raise_for_status()
            except httpx.HTTPStatusError as exc:
                raise HomeAssistantError(
                    f"Home Assistant returned {exc.response.status_code}: {exc.response.text[:200]}"
                ) from exc
            except httpx.HTTPError as exc:
                raise HomeAssistantError(f"Home Assistant request failed: {exc}") from exc
            return response.json()

    async def ping(self) -> str | None:
        payload = await self._request("GET", "/api/")
        return payload.get("version") if isinstance(payload, dict) else None

    async def get_states(self) -> list[dict[str, Any]]:
        payload = await self._request("GET", "/api/states")
        if not isinstance(payload, list):
            raise HomeAssistantError("Home Assistant states response was not a list")
        return payload

    async def call_service(self, domain: str, service: str, data: dict[str, Any]) -> Any:
        return await self._request("POST", f"/api/services/{domain}/{service}", json=data)

    async def stream_state_changed(self) -> AsyncIterator[dict[str, Any]]:
        ws_base = self.base_url.replace("https://", "wss://").replace("http://", "ws://")
        url = f"{ws_base}/api/websocket"
        async with websockets.connect(url, open_timeout=self.timeout) as ws:
            auth_required = json.loads(await ws.recv())
            if auth_required.get("type") != "auth_required":
                raise HomeAssistantError("Home Assistant WebSocket did not request auth")
            await ws.send(json.dumps({"type": "auth", "access_token": self.token}))
            auth_ok = json.loads(await ws.recv())
            if auth_ok.get("type") != "auth_ok":
                raise HomeAssistantError("Home Assistant WebSocket auth failed")
            await ws.send(json.dumps({"id": 1, "type": "subscribe_events", "event_type": "state_changed"}))
            subscribed = json.loads(await ws.recv())
            if not subscribed.get("success"):
                raise HomeAssistantError("Home Assistant WebSocket subscription failed")
            while True:
                message = json.loads(await ws.recv())
                if message.get("type") == "event":
                    yield message["event"]
