"""Small raw-CDP helpers for browser-backed platform crawlers."""

from __future__ import annotations

import asyncio
import http.client
import json
import logging
from urllib.parse import quote

import websockets

logger = logging.getLogger(__name__)

CDP_HOST = "127.0.0.1"
CDP_PORT = 9222


async def list_targets() -> list[dict]:
    """Return all CDP targets from the local browser."""
    conn = None
    try:
        conn = http.client.HTTPConnection(CDP_HOST, CDP_PORT, timeout=3)
        conn.request("GET", "/json")
        response = conn.getresponse()
        return await asyncio.to_thread(json.loads, response.read())
    finally:
        if conn:
            conn.close()


async def open_temporary_tab(url: str) -> tuple[str | None, str | None]:
    """Open a temporary browser tab and return (websocket_url, target_id)."""
    conn = None
    try:
        conn = http.client.HTTPConnection(CDP_HOST, CDP_PORT, timeout=5)
        conn.request("PUT", f"/json/new?{quote(url, safe='')}")
        response = conn.getresponse()
        target = await asyncio.to_thread(json.loads, response.read())
        ws_url = target.get("webSocketDebuggerUrl")
        target_id = target.get("id")
        if ws_url and target_id:
            await asyncio.sleep(2)
            return ws_url, target_id
    except Exception as exc:
        logger.warning("Failed to open temporary CDP tab for %s: %s", url, exc)
    finally:
        if conn:
            conn.close()
    return None, None


async def close_target(target_id: str) -> None:
    """Close a CDP target by id."""
    conn = None
    try:
        conn = http.client.HTTPConnection(CDP_HOST, CDP_PORT, timeout=3)
        conn.request("GET", f"/json/close/{target_id}")
        conn.getresponse()
        await asyncio.sleep(0.5)
        if not await _target_exists(target_id):
            return

        browser_ws = await _browser_ws_url()
        if browser_ws:
            async with websockets.connect(browser_ws, max_size=2**25) as ws:
                await ws.send(await asyncio.to_thread(json.dumps, {
                    "id": 1,
                    "method": "Target.closeTarget",
                    "params": {"targetId": target_id},
                }))
                await asyncio.wait_for(ws.recv(), timeout=3)
    except Exception as exc:
        logger.warning("Failed to close CDP target %s: %s", target_id, exc)
    finally:
        if conn:
            conn.close()


async def _target_exists(target_id: str) -> bool:
    try:
        return any(target.get("id") == target_id for target in await list_targets())
    except Exception:
        return True


async def _browser_ws_url() -> str | None:
    conn = None
    try:
        conn = http.client.HTTPConnection(CDP_HOST, CDP_PORT, timeout=3)
        conn.request("GET", "/json/version")
        response = conn.getresponse()
        data = await asyncio.to_thread(json.loads, response.read())
        return data.get("webSocketDebuggerUrl")
    except Exception:
        return None
    finally:
        if conn:
            conn.close()


async def evaluate_json_fetch(ws_url: str, url: str, headers: dict[str, str] | None = None) -> dict:
    """Run fetch(url) inside a browser target and return status/content/json data."""
    safe_headers = headers or {}
    expression = f"""
    fetch({url!r}, {{headers: {json.dumps(safe_headers)}}})
      .then(async (response) => {{
        const text = await response.text();
        return JSON.stringify({{
          status: response.status,
          contentType: response.headers.get('content-type'),
          text
        }});
      }})
      .catch((error) => JSON.stringify({{error: error.toString()}}))
    """

    async with websockets.connect(ws_url, max_size=2**25) as ws:
        await ws.send(await asyncio.to_thread(json.dumps, {
            "id": 1,
            "method": "Runtime.evaluate",
            "params": {
                "expression": expression,
                "awaitPromise": True,
                "returnByValue": True,
            },
        }))
        raw = await asyncio.wait_for(ws.recv(), timeout=20)

    payload = await asyncio.to_thread(json.loads, raw)
    value = payload.get("result", {}).get("result", {}).get("value", "{}")
    result = await asyncio.to_thread(json.loads, value)
    text = result.get("text", "")
    try:
        result["json"] = await asyncio.to_thread(json.loads, text)
    except Exception:
        result["json"] = None
    return result
