"""Process-local Home Assistant state fanout for browser SSE clients."""
from __future__ import annotations

import asyncio
import contextlib
import logging
from typing import Any

from app.domains.smart_home.ha_client import HomeAssistantClient, HomeAssistantError

logger = logging.getLogger(__name__)


class SmartHomeStateBroker:
    def __init__(self) -> None:
        self._subscribers: set[asyncio.Queue] = set()
        self._lock = asyncio.Lock()
        self._task: asyncio.Task | None = None
        self._client_key: tuple[str, str] | None = None

    async def subscribe(self, client: HomeAssistantClient) -> asyncio.Queue:
        queue: asyncio.Queue = asyncio.Queue(maxsize=200)
        async with self._lock:
            self._subscribers.add(queue)
            client_key = (client.base_url, client.token)
            if self._task is None or self._task.done() or self._client_key != client_key:
                await self._stop_locked()
                self._client_key = client_key
                self._task = asyncio.create_task(self._run(client))
        return queue

    async def unsubscribe(self, queue: asyncio.Queue) -> None:
        async with self._lock:
            self._subscribers.discard(queue)
            if not self._subscribers:
                await self._stop_locked()

    async def _stop_locked(self) -> None:
        if self._task is not None:
            self._task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await self._task
        self._task = None
        self._client_key = None

    async def _run(self, client: HomeAssistantClient) -> None:
        delay = 1.0
        max_delay = 30.0
        while True:
            try:
                async for event in client.stream_state_changed():
                    await self._publish(event)
                    delay = 1.0
            except HomeAssistantError as exc:
                logger.warning("Smart home state stream error: %s", exc)
            except Exception:
                logger.exception("Smart home state stream unexpected error")
            await asyncio.sleep(delay)
            delay = min(delay * 2, max_delay)

    async def _publish(self, item: dict[str, Any]) -> None:
        async with self._lock:
            subscribers = list(self._subscribers)
        for queue in subscribers:
            if queue.full():
                with contextlib.suppress(asyncio.QueueEmpty):
                    queue.get_nowait()
            with contextlib.suppress(asyncio.QueueFull):
                queue.put_nowait(item)


smart_home_state_broker = SmartHomeStateBroker()
