"""WebSocket connection manager – broadcasts task events to all live clients."""
from __future__ import annotations

import json
from typing import Any

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self._active: list[WebSocket] = []

    @property
    def count(self) -> int:
        return len(self._active)

    async def connect(self, ws: WebSocket) -> None:
        await ws.accept()
        self._active.append(ws)
        await self._broadcast({"type": "connected_count", "count": self.count})

    def disconnect(self, ws: WebSocket) -> None:
        self._active = [c for c in self._active if c is not ws]

    async def broadcast(self, event_type: str, data: Any) -> None:
        await self._broadcast({"type": event_type, "data": data})

    async def _broadcast(self, payload: dict) -> None:
        message = json.dumps(payload)
        dead: list[WebSocket] = []
        for ws in self._active:
            try:
                await ws.send_text(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(ws)
        if dead:
            count_msg = json.dumps({"type": "connected_count", "count": self.count})
            for ws in self._active:
                try:
                    await ws.send_text(count_msg)
                except Exception:
                    pass


manager = ConnectionManager()
