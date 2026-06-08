"""In-memory SSE event broker for event-center subscriptions."""
from __future__ import annotations

import asyncio


class EventStreamBroker:
    """Simple in-process broker for streaming structured event-center items."""

    def __init__(self) -> None:
        self._subscribers: set[asyncio.Queue] = set()
        self._lock = asyncio.Lock()

    async def subscribe(self) -> asyncio.Queue:
        """Register a new subscriber queue."""
        queue: asyncio.Queue = asyncio.Queue(maxsize=200)
        async with self._lock:
            self._subscribers.add(queue)
        return queue

    async def unsubscribe(self, queue: asyncio.Queue) -> None:
        """Remove a subscriber queue."""
        async with self._lock:
            self._subscribers.discard(queue)

    async def publish(self, item: dict) -> None:
        """Publish one event-center item to all current subscribers."""
        async with self._lock:
            subscribers = list(self._subscribers)

        dead: list[asyncio.Queue] = []
        for queue in subscribers:
            if queue.full():
                try:
                    queue.get_nowait()
                except asyncio.QueueEmpty:
                    pass
            try:
                queue.put_nowait(item)
            except asyncio.QueueFull:
                # Consumer is not keeping up — remove to prevent memory leak
                dead.append(queue)
        if dead:
            async with self._lock:
                for q in dead:
                    self._subscribers.discard(q)


event_stream_broker = EventStreamBroker()
