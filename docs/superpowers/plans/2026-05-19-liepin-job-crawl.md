# Liepin Job Crawl Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Liepin as a stable third job-crawling platform with HTTP-first search, CDP fallback, detail enrichment, scheduling support, and real E2E verification.

**Architecture:** Extend the existing job platform pipeline instead of adding a parallel crawler. `LiepinAdapter` will normalize Liepin search/detail data into the existing `process_job_results()` contract, with a small shared CDP utility for temporary tabs and browser-context fetches. Detail enrichment remains platform-neutral: new jobs and existing jobs missing detail fields are queued for sequential rate-limited detail fetching.

**Tech Stack:** Python 3.11+, FastAPI, SQLAlchemy async, Pydantic, curl_cffi, raw Chrome DevTools Protocol over HTTP/WebSocket, pytest, ruff, React + TypeScript + Ant Design.

---

## Current Context and Guardrails

- The working tree may already contain unrelated quality-gate fixes. Before implementation, either commit those fixes separately or work in a clean worktree. Do not mix those changes into Liepin commits.
- Commands must use the repo's Windows command style from `AGENTS.md`, for example:
  - Backend tests: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest"`
  - Backend lint: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check ."`
  - Frontend lint: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run lint"`
  - Frontend build: `powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"`
- For every symbol edit, run GitNexus impact first. At minimum:
  - `npx gitnexus impact _create_adapter`
  - `npx gitnexus impact process_job_results`
  - `npx gitnexus impact JobSearchConfig`
  - `npx gitnexus impact JobSearchConfigResponse`
- Do not delete retained E2E configs such as `codex-e2e-liepin-kept-<time>` unless the user explicitly asks.
- Search failures should mark the crawl failed. Detail failures should not roll back saved search results.

## File Structure

Create:

- `backend/app/platforms/cdp_utils.py`  
  Shared low-level CDP helpers for opening temporary tabs, closing targets, reading targets, and evaluating browser-context fetches.

- `backend/app/platforms/liepin.py`  
  Liepin adapter with HTTP-first search/detail paths and CDP fallback paths.

- `backend/tests/test_liepin_adapter.py`  
  Adapter unit coverage for HTTP success, HTTP challenge fallback, CDP tab cleanup, transformation, and detail parsing.

- `backend/tests/test_liepin_pipeline.py`  
  Contract/pipeline coverage for platform routing, notification label, and detail enrichment queue behavior.

- `backend/alembic/versions/2026_05_19_add_liepin_job_platform.py`  
  Database constraint migration adding `liepin` to the job platform check.

Modify:

- `backend/app/models/job.py`  
  Update the platform constraint comment/check constraint to include `liepin`.

- `backend/app/schemas/job.py`  
  Extend `JobPlatform` literals to include `liepin`.

- `backend/app/platforms/__init__.py`  
  Export `LiepinAdapter`.

- `backend/app/services/job_crawl.py`  
  Add `liepin` to valid platforms and adapter factory. Extend detail queue so existing jobs missing `description` or `address` are enriched.

- `backend/app/services/notification.py`  
  Add `猎聘` label.

- `frontend/src/types/index.ts`  
  Extend job platform union types to include `liepin`.

- `frontend/src/components/JobList.tsx`  
  Display a `猎聘` platform tag.

- Any job config UI file that hardcodes platform options. Find with:
  `rg -n "51job|Boss|platform" frontend/src`

---

### Task 1: Discover Current Liepin Search and Detail Endpoints

**Files:**
- Create: `backend/scripts/probe_liepin_endpoints.py`
- Create: `docs/superpowers/specs/2026-05-19-liepin-endpoint-notes.md`

- [ ] **Step 1: Create the endpoint probe script**

Create `backend/scripts/probe_liepin_endpoints.py`:

```python
"""Probe Liepin network responses from the user's CDP browser.

Run while Edge/Chrome is listening on 127.0.0.1:9222. The script opens a
temporary Liepin search tab, records JSON fetch/XHR responses, prints candidate
search/detail payloads, and closes the tab.
"""

from __future__ import annotations

import asyncio
import json
import time
from dataclasses import dataclass
from urllib.parse import quote

import websockets

from app.platforms.cdp_utils import close_target, open_temporary_tab


SEARCH_URL = "https://www.liepin.com/zhaopin/?key=python&dqs=020&currentPage=0"


@dataclass
class Candidate:
    url: str
    status: int | None
    mime_type: str | None
    body_preview: str


def looks_like_job_payload(text: str) -> bool:
    lowered = text.lower()
    return any(
        marker in lowered
        for marker in (
            "job",
            "position",
            "salary",
            "company",
            "comp",
            "data",
        )
    )


async def main() -> None:
    ws_url, target_id = await open_temporary_tab(SEARCH_URL)
    if not ws_url or not target_id:
        raise SystemExit("CDP browser is not available at 127.0.0.1:9222")

    candidates: list[Candidate] = []
    request_urls: dict[str, str] = {}

    try:
        async with websockets.connect(ws_url, max_size=2**25) as ws:
            await ws.send(json.dumps({"id": 1, "method": "Network.enable"}))
            await ws.recv()
            await ws.send(json.dumps({"id": 2, "method": "Page.enable"}))
            await ws.recv()
            await ws.send(
                json.dumps({
                    "id": 3,
                    "method": "Page.navigate",
                    "params": {"url": SEARCH_URL},
                })
            )

            deadline = time.monotonic() + 30
            command_id = 10
            while time.monotonic() < deadline:
                raw = await asyncio.wait_for(ws.recv(), timeout=5)
                event = json.loads(raw)
                method = event.get("method")
                params = event.get("params", {})

                if method == "Network.requestWillBeSent":
                    request = params.get("request", {})
                    request_id = params.get("requestId")
                    url = request.get("url", "")
                    if request_id and "liepin.com" in url:
                        request_urls[request_id] = url

                if method == "Network.responseReceived":
                    response = params.get("response", {})
                    request_id = params.get("requestId")
                    url = response.get("url") or request_urls.get(request_id, "")
                    mime_type = response.get("mimeType")
                    if not request_id or "liepin.com" not in url:
                        continue
                    if "json" not in str(mime_type).lower() and "api" not in url.lower():
                        continue

                    command_id += 1
                    await ws.send(
                        json.dumps({
                            "id": command_id,
                            "method": "Network.getResponseBody",
                            "params": {"requestId": request_id},
                        })
                    )
                    body_raw = await asyncio.wait_for(ws.recv(), timeout=5)
                    body_result = json.loads(body_raw).get("result", {})
                    body = body_result.get("body", "")
                    if looks_like_job_payload(body):
                        candidates.append(
                            Candidate(
                                url=url,
                                status=response.get("status"),
                                mime_type=mime_type,
                                body_preview=body[:2000],
                            )
                        )

        print(json.dumps([candidate.__dict__ for candidate in candidates], ensure_ascii=False, indent=2))
    finally:
        await close_target(target_id)


if __name__ == "__main__":
    asyncio.run(main())
```

- [ ] **Step 2: Run the probe and capture output**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; python scripts/probe_liepin_endpoints.py"
```

Expected:

- If CDP is available: JSON array of candidate Liepin API responses.
- If CDP is unavailable: `CDP browser is not available at 127.0.0.1:9222`.

- [ ] **Step 3: Write endpoint notes**

Create `docs/superpowers/specs/2026-05-19-liepin-endpoint-notes.md` with this exact structure and the captured values:

```markdown
# Liepin Endpoint Notes

Date: 2026-05-19

Discovery Status: Complete

## Search Endpoint

- Method: GET or POST as observed
- URL path: the observed Liepin search API path
- Required query/body fields:
  - keyword field and captured request value, for example `key = python`
  - city field and captured request value, for example `dqs = 020`
  - page field and captured request value, for example `currentPage = 0`
  - page size field and captured request value, when present
- Required headers:
  - Accept
  - Content-Type, if POST
  - Referer
  - X-* headers observed as required
- Response job list path: the dotted path to the array
- Response total path: the dotted path to total count, if present

## Detail Endpoint

- Method: GET or POST as observed
- URL path or detail page URL pattern
- Required fields:
  - job id field name
  - any company id or encrypted id field name
- Response description path or DOM selector
- Response address path or DOM selector

## Challenge Markers

- HTML/login markers observed:
  - `登录`
  - `passport`
- Verification/CAPTCHA markers observed:
  - `安全验证`
  - `验证码`
  - `captcha`
```

- [ ] **Step 4: Self-check endpoint notes**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; Select-String -Path docs/superpowers/specs/2026-05-19-liepin-endpoint-notes.md -Pattern 'Discovery Status: Complete'"
```

Expected: one match.

- [ ] **Step 5: Commit endpoint discovery artifact**

```powershell
git add -f docs/superpowers/specs/2026-05-19-liepin-endpoint-notes.md backend/scripts/probe_liepin_endpoints.py
git commit -m "docs: capture liepin endpoint discovery"
```

---

### Task 2: Add Shared CDP Utilities

**Files:**
- Create: `backend/app/platforms/cdp_utils.py`
- Test: `backend/tests/test_liepin_adapter.py`

- [ ] **Step 1: Write failing tests for CDP helpers**

Create `backend/tests/test_liepin_adapter.py` with:

```python
"""Tests for Liepin adapter and shared CDP helpers."""

from __future__ import annotations

import json
from unittest.mock import AsyncMock

import pytest


@pytest.mark.asyncio
async def test_open_temporary_tab_uses_cdp_new_endpoint(monkeypatch):
    import http.client

    from app.platforms.cdp_utils import open_temporary_tab

    requests: list[tuple[str, str]] = []

    class FakeResponse:
        def read(self) -> bytes:
            return json.dumps({
                "id": "target-liepin",
                "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/page/target-liepin",
            }).encode()

    class FakeConnection:
        def __init__(self, *_args, **_kwargs):
            pass

        def request(self, method: str, path: str) -> None:
            requests.append((method, path))

        def getresponse(self) -> FakeResponse:
            return FakeResponse()

        def close(self) -> None:
            pass

    monkeypatch.setattr(http.client, "HTTPConnection", FakeConnection)

    ws_url, target_id = await open_temporary_tab("https://www.liepin.com/zhaopin/?key=python")

    assert ws_url == "ws://127.0.0.1:9222/devtools/page/target-liepin"
    assert target_id == "target-liepin"
    assert requests[0][0] == "PUT"
    assert requests[0][1].startswith("/json/new?https%3A%2F%2Fwww.liepin.com")


@pytest.mark.asyncio
async def test_close_target_closes_requested_cdp_target(monkeypatch):
    import http.client

    from app.platforms.cdp_utils import close_target

    requests: list[tuple[str, str]] = []

    class FakeConnection:
        def __init__(self, *_args, **_kwargs):
            pass

        def request(self, method: str, path: str) -> None:
            requests.append((method, path))

        def getresponse(self):
            return object()

        def close(self) -> None:
            pass

    monkeypatch.setattr(http.client, "HTTPConnection", FakeConnection)

    await close_target("target-liepin")

    assert requests == [("GET", "/json/close/target-liepin")]
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_adapter.py::test_open_temporary_tab_uses_cdp_new_endpoint tests/test_liepin_adapter.py::test_close_target_closes_requested_cdp_target -q"
```

Expected: fail with `ModuleNotFoundError: No module named 'app.platforms.cdp_utils'`.

- [ ] **Step 3: Implement CDP helpers**

Create `backend/app/platforms/cdp_utils.py`:

```python
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
        return json.loads(response.read())
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
        target = json.loads(response.read())
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
    except Exception as exc:
        logger.warning("Failed to close CDP target %s: %s", target_id, exc)
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
        await ws.send(json.dumps({
            "id": 1,
            "method": "Runtime.evaluate",
            "params": {
                "expression": expression,
                "awaitPromise": True,
                "returnByValue": True,
            },
        }))
        raw = await asyncio.wait_for(ws.recv(), timeout=20)

    payload = json.loads(raw)
    value = payload.get("result", {}).get("result", {}).get("value", "{}")
    result = json.loads(value)
    text = result.get("text", "")
    try:
        result["json"] = json.loads(text)
    except Exception:
        result["json"] = None
    return result
```

- [ ] **Step 4: Run CDP helper tests**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_adapter.py::test_open_temporary_tab_uses_cdp_new_endpoint tests/test_liepin_adapter.py::test_close_target_closes_requested_cdp_target -q"
```

Expected: `2 passed`.

- [ ] **Step 5: Commit CDP helpers**

```powershell
git add backend/app/platforms/cdp_utils.py backend/tests/test_liepin_adapter.py
git commit -m "feat: add shared CDP helpers for job crawlers"
```

---

### Task 3: Add Liepin Platform Contract

**Files:**
- Modify: `backend/app/schemas/job.py`
- Modify: `backend/app/models/job.py`
- Create: `backend/alembic/versions/2026_05_19_add_liepin_job_platform.py`
- Modify: `backend/app/services/job_crawl.py`
- Modify: `backend/app/services/notification.py`
- Modify: `frontend/src/types/index.ts`
- Modify: `frontend/src/components/JobList.tsx`
- Test: `backend/tests/test_liepin_pipeline.py`

- [ ] **Step 1: Write failing backend contract tests**

Create `backend/tests/test_liepin_pipeline.py`:

```python
"""Liepin platform contract and pipeline tests."""

from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from pydantic import TypeAdapter


def test_job_platform_accepts_liepin():
    from app.schemas.job import JobPlatform

    adapter = TypeAdapter(JobPlatform)

    assert adapter.validate_python("liepin") == "liepin"


def test_create_adapter_supports_liepin(monkeypatch):
    from app.services import job_crawl

    class FakeLiepinAdapter:
        pass

    monkeypatch.setattr(
        "app.platforms.LiepinAdapter",
        FakeLiepinAdapter,
        raising=False,
    )

    adapter = job_crawl._create_adapter("liepin")

    assert isinstance(adapter, FakeLiepinAdapter)


@pytest.mark.asyncio
async def test_new_job_notification_uses_liepin_label(monkeypatch):
    from app.services import notification

    sent_messages: list[str] = []

    async def fake_send(_webhook_url: str, message: str) -> dict:
        sent_messages.append(message)
        return {"ok": True}

    monkeypatch.setattr(
        notification,
        "get_cached_user_config",
        AsyncMock(return_value={"feishu_webhook_url": "https://example.test/hook"}),
    )
    monkeypatch.setattr(notification, "send_feishu_notification", fake_send)

    config = SimpleNamespace(name="Liepin Python", platform="liepin")
    result = await notification.send_new_job_notification(config, 2, 20)

    assert result == {"ok": True}
    assert sent_messages
    assert "猎聘新职位提醒" in sent_messages[0]
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_pipeline.py -q"
```

Expected: fail because `liepin` is not in the platform schema/factory/notification labels.

- [ ] **Step 3: Extend backend platform contracts**

Apply these changes:

In `backend/app/schemas/job.py`:

```python
JobPlatform = Literal["boss", "51job", "liepin"]
```

In `backend/app/models/job.py`, update the check constraint:

```python
CheckConstraint(
    "platform IN ('boss', '51job', 'liepin')",
    name="ck_jobs_search_configs_platform",
),
```

In `backend/app/services/job_crawl.py`:

```python
VALID_JOB_PLATFORMS = {"boss", "51job", "liepin"}
```

and update `_create_adapter()`:

```python
def _create_adapter(platform: str) -> BasePlatformAdapter:
    """Create the appropriate adapter for the given job platform."""
    from app.platforms import BossZhipinAdapter, Job51Adapter, LiepinAdapter

    platform = _normalize_platform(platform)
    adapters: dict[str, type] = {
        "boss": BossZhipinAdapter,
        "51job": Job51Adapter,
        "liepin": LiepinAdapter,
    }
    return adapters[platform]()
```

In `backend/app/services/notification.py`, add:

```python
platform_names = {
    "boss": "Boss直聘",
    "51job": "前程无忧",
    "liepin": "猎聘",
}
```

Create the Alembic migration `backend/alembic/versions/2026_05_19_add_liepin_job_platform.py`:

```python
"""Add Liepin as a job platform.

Revision ID: 2026_05_19_add_liepin_job_platform
Revises: 2026_05_19_harden_job_platform
Create Date: 2026-05-19
"""

from alembic import op

revision = "2026_05_19_add_liepin_job_platform"
down_revision = "2026_05_19_harden_job_platform"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_constraint("ck_jobs_search_configs_platform", "job_search_configs", type_="check")
    op.create_check_constraint(
        "ck_jobs_search_configs_platform",
        "job_search_configs",
        "platform IN ('boss', '51job', 'liepin')",
    )


def downgrade() -> None:
    op.drop_constraint("ck_jobs_search_configs_platform", "job_search_configs", type_="check")
    op.create_check_constraint(
        "ck_jobs_search_configs_platform",
        "job_search_configs",
        "platform IN ('boss', '51job')",
    )
```

Before committing the migration, confirm that the current job-platform migration chain still ends at `2026_05_19_harden_job_platform`. Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; rg -n \"51job|platform IN\" alembic/versions"
```

- [ ] **Step 4: Add a temporary Liepin adapter stub**

Create `backend/app/platforms/liepin.py` so `_create_adapter("liepin")` can import:

```python
"""Liepin platform adapter for job search crawling."""

from __future__ import annotations

from typing import Any

from app.platforms.base import BasePlatformAdapter


class LiepinAdapter(BasePlatformAdapter):
    """Adapter for Liepin job search crawling."""

    async def extract_price(self, page) -> dict[str, Any]:
        raise NotImplementedError("Job adapter does not extract prices")

    async def extract_title(self, page) -> str:
        raise NotImplementedError("Job adapter does not extract titles")

    async def crawl(self, url: str) -> dict[str, Any]:
        return {"success": False, "error": "Liepin adapter is not implemented yet"}

    async def crawl_detail(self, job_id: str) -> dict[str, Any]:
        return {"success": False, "error": "Liepin detail crawl is not implemented yet"}
```

Update `backend/app/platforms/__init__.py`:

```python
from app.platforms.liepin import LiepinAdapter

__all__ = [
    "BasePlatformAdapter",
    "TaobaoAdapter",
    "JDAdapter",
    "AmazonAdapter",
    "BossZhipinAdapter",
    "Job51Adapter",
    "LiepinAdapter",
]
```

- [ ] **Step 5: Extend frontend platform types and labels**

In `frontend/src/types/index.ts`, replace each job platform union:

```ts
'boss' | '51job'
```

with:

```ts
'boss' | '51job' | 'liepin'
```

In `frontend/src/components/JobList.tsx`, add `liepin` to the platform render map:

```tsx
const platformLabels: Record<Job['platform'], { label: string; color: string }> = {
  boss: { label: 'Boss直聘', color: 'blue' },
  '51job': { label: '前程无忧', color: 'green' },
  liepin: { label: '猎聘', color: 'orange' },
}
```

Use the existing local pattern if the file currently defines labels inline.

- [ ] **Step 6: Run contract tests and frontend build**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_pipeline.py tests/test_job_phase3_integration.py tests/test_schemas.py -q"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"
```

Expected: backend tests pass and frontend build passes.

- [ ] **Step 7: Commit platform contract**

```powershell
git add backend/app/schemas/job.py backend/app/models/job.py backend/alembic/versions/2026_05_19_add_liepin_job_platform.py backend/app/services/job_crawl.py backend/app/services/notification.py backend/app/platforms/liepin.py backend/app/platforms/__init__.py backend/tests/test_liepin_pipeline.py frontend/src/types/index.ts frontend/src/components/JobList.tsx
git commit -m "feat: add liepin job platform contract"
```

---

### Task 4: Implement Liepin Search HTTP Path

**Files:**
- Modify: `backend/app/platforms/liepin.py`
- Test: `backend/tests/test_liepin_adapter.py`

- [ ] **Step 1: Add failing tests for HTTP search success and transformation**

Append to `backend/tests/test_liepin_adapter.py`:

```python
def test_liepin_transform_jobs_normalizes_search_items():
    from app.platforms.liepin import LiepinAdapter

    payload = {
        "data": {
            "data": {
                "jobCardList": [
                    {
                        "job": {
                            "jobId": "123",
                            "title": "Python Engineer",
                            "salary": "20-40k",
                            "dq": "上海",
                            "requireWorkYears": "3-5年",
                            "requireEduLevel": "本科",
                            "link": "https://www.liepin.com/job/123.shtml",
                        },
                        "comp": {
                            "compId": "c1",
                            "compName": "Example Co",
                        },
                    }
                ]
            }
        }
    }

    jobs = LiepinAdapter._transform_jobs(payload)

    assert jobs == [
        {
            "job_id": "123",
            "title": "Python Engineer",
            "company": "Example Co",
            "company_id": "c1",
            "salary": "20-40k",
            "location": "上海",
            "experience": "3-5年",
            "education": "本科",
            "url": "https://www.liepin.com/job/123.shtml",
            "description": "",
            "address": "",
        }
    ]


@pytest.mark.asyncio
async def test_liepin_crawl_uses_http_json_success(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "application/json"}
        text = '{"data":{"data":{"jobCardList":[]}}}'

        def json(self):
            return {
                "data": {
                    "data": {
                        "jobCardList": [
                            {
                                "job": {
                                    "jobId": "123",
                                    "title": "Python Engineer",
                                    "salary": "20-40k",
                                    "dq": "上海",
                                    "requireWorkYears": "3-5年",
                                    "requireEduLevel": "本科",
                                    "link": "https://www.liepin.com/job/123.shtml",
                                },
                                "comp": {"compId": "c1", "compName": "Example Co"},
                            }
                        ]
                    }
                }
            }

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())
    monkeypatch.setattr(adapter, "_crawl_via_cdp", AsyncMock())

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is True
    assert result["count"] == 1
    assert result["jobs"][0]["job_id"] == "123"
    adapter._crawl_via_cdp.assert_not_called()
```

- [ ] **Step 2: Run tests and verify they fail**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_adapter.py::test_liepin_transform_jobs_normalizes_search_items tests/test_liepin_adapter.py::test_liepin_crawl_uses_http_json_success -q"
```

Expected: fail because `LiepinAdapter._transform_jobs` and HTTP search are not implemented.

- [ ] **Step 3: Implement HTTP search in `LiepinAdapter`**

Use the endpoint notes from Task 1 to set these constants at the top of `backend/app/platforms/liepin.py`:

```python
SEARCH_DOMAIN = "www.liepin.com"
BASE_URL = f"https://{SEARCH_DOMAIN}"
SEARCH_PAGE_PATH = "/zhaopin/"
SEARCH_API_PATH = "/api/com.liepin.searchfront4c.pc-search-job"
DETAIL_PAGE_URL_TEMPLATE = "https://www.liepin.com/job/{job_id}.shtml"
```

If endpoint discovery found a different API path, use the discovered path and keep the same constant names.

Replace the stub body with:

```python
"""Liepin platform adapter for job search crawling."""

from __future__ import annotations

import json
import logging
import time
import uuid
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse

from curl_cffi.requests import Session as CffiSession

from app.platforms.base import BasePlatformAdapter
from app.platforms.cdp_utils import close_target, evaluate_json_fetch, open_temporary_tab

logger = logging.getLogger(__name__)

SEARCH_DOMAIN = "www.liepin.com"
BASE_URL = f"https://{SEARCH_DOMAIN}"
SEARCH_PAGE_PATH = "/zhaopin/"
SEARCH_API_PATH = "/api/com.liepin.searchfront4c.pc-search-job"
DETAIL_PAGE_URL_TEMPLATE = "https://www.liepin.com/job/{job_id}.shtml"
MAX_PAGES = 3


class LiepinAdapter(BasePlatformAdapter):
    """Adapter for Liepin job search crawling."""

    def __init__(self):
        super().__init__()
        self._session: CffiSession | None = None

    def _get_session(self) -> CffiSession:
        if self._session is None:
            self._session = CffiSession()
        return self._session

    async def extract_price(self, page) -> dict[str, Any]:
        raise NotImplementedError("Job adapter does not extract prices")

    async def extract_title(self, page) -> str:
        raise NotImplementedError("Job adapter does not extract titles")

    async def crawl(self, url: str) -> dict[str, Any]:
        parsed = urlparse(url)
        query = parse_qs(parsed.query)
        keyword = query.get("key", query.get("keyword", ["python"]))[0]
        city = query.get("dqs", query.get("city", [""]))[0]

        http_result = self._crawl_search_http(keyword, city)
        if http_result.get("success"):
            return http_result

        logger.info("Liepin HTTP search failed, falling back to CDP: %s", http_result.get("error"))
        return await self._crawl_via_cdp(keyword, city)

    def _crawl_search_http(self, keyword: str, city: str) -> dict[str, Any]:
        try:
            response = self._get_session().get(
                self._build_search_api_url(keyword, city, 0),
                impersonate="chrome124",
                headers=self._headers(keyword, city),
                timeout=20,
            )
            data = self._parse_json_response(response)
            jobs = self._transform_jobs(data)
            if not jobs:
                return {"success": False, "error": "Liepin HTTP response contained no jobs"}
            return {"success": True, "jobs": jobs, "count": len(jobs)}
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    def _build_search_api_url(self, keyword: str, city: str, page: int) -> str:
        params = {
            "key": keyword,
            "dqs": city,
            "currentPage": str(page),
            "pageSize": "40",
            "requestId": uuid.uuid4().hex,
            "timestamp": str(int(time.time())),
        }
        return f"{BASE_URL}{SEARCH_API_PATH}?{urlencode(params)}"

    def _build_search_page_url(self, keyword: str, city: str) -> str:
        params = {"key": keyword, "dqs": city, "currentPage": "0"}
        return f"{BASE_URL}{SEARCH_PAGE_PATH}?{urlencode(params)}"

    def _headers(self, keyword: str, city: str) -> dict[str, str]:
        return {
            "Accept": "application/json, text/plain, */*",
            "Referer": self._build_search_page_url(keyword, city),
        }

    def _parse_json_response(self, response) -> dict[str, Any]:
        content_type = response.headers.get("content-type", "")
        text = response.text or ""
        if response.status_code != 200:
            raise ValueError(f"HTTP {response.status_code}")
        if "html" in content_type.lower() or text.lstrip().lower().startswith(("<html", "<!doctype html")):
            raise ValueError("Liepin returned HTML instead of JSON")
        if self._looks_challenged(text):
            raise ValueError("Liepin returned a challenge or login response")
        return response.json()

    @staticmethod
    def _looks_challenged(text: str) -> bool:
        lowered = text.lower()
        return any(
            marker in lowered
            for marker in ("captcha", "verify", "安全验证", "登录", "passport", "antibot")
        )

    @staticmethod
    def _job_items(data: dict[str, Any]) -> list[dict[str, Any]]:
        candidates = [
            data.get("data", {}).get("data", {}).get("jobCardList"),
            data.get("data", {}).get("jobCardList"),
            data.get("jobCardList"),
            data.get("data", {}).get("list"),
        ]
        for candidate in candidates:
            if isinstance(candidate, list):
                return candidate
        return []

    @classmethod
    def _transform_jobs(cls, data: dict[str, Any]) -> list[dict[str, Any]]:
        jobs: list[dict[str, Any]] = []
        for item in cls._job_items(data):
            job = item.get("job", item)
            company = item.get("comp", item.get("company", {}))
            job_id = str(job.get("jobId") or job.get("id") or job.get("jobIdEnc") or "")
            if not job_id:
                continue
            jobs.append({
                "job_id": job_id,
                "title": job.get("title") or job.get("jobTitle") or "",
                "company": company.get("compName") or company.get("name") or "",
                "company_id": str(company.get("compId") or company.get("id") or ""),
                "salary": job.get("salary") or job.get("salaryText") or "",
                "location": job.get("dq") or job.get("city") or job.get("location") or "",
                "experience": job.get("requireWorkYears") or job.get("experience") or "",
                "education": job.get("requireEduLevel") or job.get("education") or "",
                "url": job.get("link") or job.get("url") or DETAIL_PAGE_URL_TEMPLATE.format(job_id=job_id),
                "description": job.get("description") or job.get("jobDesc") or "",
                "address": job.get("address") or "",
            })
        return jobs
```

Keep `_crawl_via_cdp()` as an `async` method returning a clear error until Task 5:

```python
    async def _crawl_via_cdp(self, keyword: str, city: str) -> dict[str, Any]:
        return {"success": False, "error": "Liepin CDP fallback is not implemented yet"}
```

- [ ] **Step 4: Run HTTP search tests**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_adapter.py::test_liepin_transform_jobs_normalizes_search_items tests/test_liepin_adapter.py::test_liepin_crawl_uses_http_json_success -q"
```

Expected: `2 passed`.

- [ ] **Step 5: Commit HTTP search path**

```powershell
git add backend/app/platforms/liepin.py backend/tests/test_liepin_adapter.py
git commit -m "feat: add liepin HTTP search parser"
```

---

### Task 5: Add Liepin CDP Search Fallback

**Files:**
- Modify: `backend/app/platforms/liepin.py`
- Test: `backend/tests/test_liepin_adapter.py`

- [ ] **Step 1: Write failing fallback tests**

Append:

```python
@pytest.mark.asyncio
async def test_liepin_crawl_falls_back_to_cdp_when_http_returns_html(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "text/html"}
        text = "<html>安全验证</html>"

        def json(self):
            raise ValueError("not json")

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())
    monkeypatch.setattr(
        adapter,
        "_crawl_via_cdp",
        AsyncMock(return_value={"success": True, "jobs": [{"job_id": "cdp"}], "count": 1}),
    )

    result = await adapter.crawl("https://www.liepin.com/zhaopin/?key=python&dqs=020")

    assert result["success"] is True
    assert result["jobs"][0]["job_id"] == "cdp"
    adapter._crawl_via_cdp.assert_awaited_once_with("python", "020")


@pytest.mark.asyncio
async def test_liepin_cdp_fallback_closes_temporary_tab(monkeypatch):
    from app.platforms import liepin
    from app.platforms.liepin import LiepinAdapter

    monkeypatch.setattr(
        liepin,
        "open_temporary_tab",
        AsyncMock(return_value=("ws://target", "target-liepin")),
    )
    monkeypatch.setattr(
        liepin,
        "evaluate_json_fetch",
        AsyncMock(return_value={
            "status": 200,
            "contentType": "application/json",
            "json": {
                "data": {
                    "data": {
                        "jobCardList": [
                            {
                                "job": {"jobId": "123", "title": "Python"},
                                "comp": {"compName": "Example"},
                            }
                        ]
                    }
                }
            },
        }),
    )
    close_target = AsyncMock()
    monkeypatch.setattr(liepin, "close_target", close_target)

    result = await LiepinAdapter()._crawl_via_cdp("python", "020")

    assert result["success"] is True
    assert result["count"] == 1
    close_target.assert_awaited_once_with("target-liepin")
```

- [ ] **Step 2: Run fallback tests and verify they fail**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_adapter.py::test_liepin_crawl_falls_back_to_cdp_when_http_returns_html tests/test_liepin_adapter.py::test_liepin_cdp_fallback_closes_temporary_tab -q"
```

Expected: the first may pass if Task 4 fallback call already exists; the second fails because `_crawl_via_cdp` is still a stub.

- [ ] **Step 3: Implement `_crawl_via_cdp`**

In `backend/app/platforms/liepin.py`:

```python
    async def _crawl_via_cdp(self, keyword: str, city: str) -> dict[str, Any]:
        search_page_url = self._build_search_page_url(keyword, city)
        ws_url, target_id = await open_temporary_tab(search_page_url)
        if not ws_url or not target_id:
            return {
                "success": False,
                "error": "请启动已开启远程调试端口的浏览器，以便自动打开猎聘搜索页",
            }

        all_jobs: list[dict[str, Any]] = []
        try:
            for page in range(MAX_PAGES):
                api_url = self._build_search_api_url(keyword, city, page)
                result = await evaluate_json_fetch(ws_url, api_url, self._headers(keyword, city))
                if result.get("error"):
                    return {"success": False, "error": result["error"]}
                data = result.get("json")
                if not isinstance(data, dict):
                    return {"success": False, "error": "猎聘浏览器请求未返回 JSON 数据"}
                jobs = self._transform_jobs(data)
                if not jobs:
                    break
                all_jobs.extend(jobs)
                if len(jobs) < 40:
                    break
            if not all_jobs:
                return {"success": False, "error": "No job data from Liepin search API"}
            return {"success": True, "jobs": all_jobs, "count": len(all_jobs)}
        finally:
            await close_target(target_id)
```

- [ ] **Step 4: Run fallback tests**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_adapter.py::test_liepin_crawl_falls_back_to_cdp_when_http_returns_html tests/test_liepin_adapter.py::test_liepin_cdp_fallback_closes_temporary_tab -q"
```

Expected: `2 passed`.

- [ ] **Step 5: Commit CDP fallback**

```powershell
git add backend/app/platforms/liepin.py backend/tests/test_liepin_adapter.py
git commit -m "feat: add liepin CDP search fallback"
```

---

### Task 6: Implement Liepin Detail Fetching

**Files:**
- Modify: `backend/app/platforms/liepin.py`
- Test: `backend/tests/test_liepin_adapter.py`

- [ ] **Step 1: Write failing detail tests**

Append:

```python
@pytest.mark.asyncio
async def test_liepin_crawl_detail_parses_html_description_and_address(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    html = """
    <html>
      <body>
        <section class="job-intro-container">负责 Python 服务开发</section>
        <span class="work-address">上海市浦东新区</span>
      </body>
    </html>
    """

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "text/html"}
        text = html

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())

    result = await adapter.crawl_detail("123")

    assert result["success"] is True
    assert result["detail"]["description"] == "负责 Python 服务开发"
    assert result["detail"]["address"] == "上海市浦东新区"


@pytest.mark.asyncio
async def test_liepin_crawl_detail_falls_back_to_cdp_on_challenge(monkeypatch):
    from app.platforms.liepin import LiepinAdapter

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "text/html"}
        text = "<html>安全验证</html>"

    class FakeSession:
        def get(self, *_args, **_kwargs):
            return FakeResponse()

    adapter = LiepinAdapter()
    monkeypatch.setattr(adapter, "_get_session", lambda: FakeSession())
    monkeypatch.setattr(
        adapter,
        "_crawl_detail_via_cdp",
        AsyncMock(return_value={"success": True, "detail": {"description": "CDP desc", "address": "CDP addr"}}),
    )

    result = await adapter.crawl_detail("123")

    assert result["success"] is True
    assert result["detail"]["description"] == "CDP desc"
    adapter._crawl_detail_via_cdp.assert_awaited_once_with("123")
```

- [ ] **Step 2: Run detail tests and verify they fail**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_adapter.py::test_liepin_crawl_detail_parses_html_description_and_address tests/test_liepin_adapter.py::test_liepin_crawl_detail_falls_back_to_cdp_on_challenge -q"
```

Expected: fail because `crawl_detail` is still stubbed.

- [ ] **Step 3: Implement detail parsing and fallback**

In `backend/app/platforms/liepin.py`, add imports:

```python
from bs4 import BeautifulSoup
```

Add methods:

```python
    async def crawl_detail(self, job_id: str) -> dict[str, Any]:
        try:
            response = self._get_session().get(
                DETAIL_PAGE_URL_TEMPLATE.format(job_id=job_id),
                impersonate="chrome124",
                headers={"Referer": f"{BASE_URL}/"},
                timeout=20,
            )
            text = response.text or ""
            if response.status_code != 200:
                return await self._crawl_detail_via_cdp(job_id)
            if self._looks_challenged(text):
                return await self._crawl_detail_via_cdp(job_id)
            detail = self._parse_detail_html(text)
            if not detail["description"] and not detail["address"]:
                return await self._crawl_detail_via_cdp(job_id)
            return {"success": True, "detail": detail}
        except Exception as exc:
            logger.warning("Liepin detail HTTP failed for %s: %s", job_id, exc)
            return await self._crawl_detail_via_cdp(job_id)

    async def _crawl_detail_via_cdp(self, job_id: str) -> dict[str, Any]:
        detail_url = DETAIL_PAGE_URL_TEMPLATE.format(job_id=job_id)
        ws_url, target_id = await open_temporary_tab(detail_url)
        if not ws_url or not target_id:
            return {"success": False, "error": "请启动已开启远程调试端口的浏览器，以便自动打开猎聘详情页"}
        try:
            result = await evaluate_json_fetch(
                ws_url,
                detail_url,
                {"Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
            )
            html = result.get("text") or ""
            detail = self._parse_detail_html(html)
            if not detail["description"] and not detail["address"]:
                return {"success": False, "error": "No Liepin detail content found"}
            return {"success": True, "detail": detail}
        finally:
            await close_target(target_id)

    @staticmethod
    def _parse_detail_html(html: str) -> dict[str, str]:
        soup = BeautifulSoup(html, "html.parser")
        description_node = (
            soup.select_one(".job-intro-container")
            or soup.select_one(".job-description")
            or soup.select_one("[class*='job-intro']")
            or soup.select_one("[class*='description']")
        )
        address_node = (
            soup.select_one(".work-address")
            or soup.select_one("[class*='address']")
            or soup.select_one("[class*='location']")
        )
        return {
            "description": description_node.get_text("\n", strip=True) if description_node else "",
            "address": address_node.get_text(" ", strip=True) if address_node else "",
        }
```

If endpoint discovery shows a JSON detail API, implement the HTTP detail method against that API and keep `_parse_detail_html()` as fallback. Tests above must still pass.

- [ ] **Step 4: Run detail tests**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_adapter.py::test_liepin_crawl_detail_parses_html_description_and_address tests/test_liepin_adapter.py::test_liepin_crawl_detail_falls_back_to_cdp_on_challenge -q"
```

Expected: `2 passed`.

- [ ] **Step 5: Commit detail fetching**

```powershell
git add backend/app/platforms/liepin.py backend/tests/test_liepin_adapter.py
git commit -m "feat: add liepin detail enrichment"
```

---

### Task 7: Extend Detail Queue for Existing Jobs Missing Details

**Files:**
- Modify: `backend/app/services/job_crawl.py`
- Test: `backend/tests/test_liepin_pipeline.py`

- [ ] **Step 1: Write failing pipeline test**

Append to `backend/tests/test_liepin_pipeline.py`:

```python
@pytest.mark.asyncio
async def test_existing_job_missing_detail_is_enriched(monkeypatch):
    from unittest.mock import MagicMock

    from app.services.job_crawl import process_job_results

    mock_config = MagicMock()
    mock_config.id = 1
    mock_config.notify_on_new = False
    mock_config.deactivation_threshold = 3
    mock_config.enable_match_analysis = False

    existing_job = MagicMock()
    existing_job.id = 99
    existing_job.job_id = "liepin-1"
    existing_job.search_config_id = 1
    existing_job.is_active = True
    existing_job.consecutive_miss_count = 0
    existing_job.description = ""
    existing_job.address = ""

    active_result = MagicMock()
    active_result.scalars.return_value.all.return_value = [existing_job]
    existing_result = MagicMock()
    existing_result.scalars.return_value.all.return_value = [existing_job]

    mock_db = MagicMock()
    mock_db.get = AsyncMock(return_value=mock_config)
    mock_db.execute = AsyncMock(side_effect=[active_result, existing_result])
    mock_db.add = MagicMock()
    mock_db.commit = AsyncMock()

    update_detail = AsyncMock(return_value={"success": True, "detail": {"description": "D", "address": "A"}})
    monkeypatch.setattr("app.services.job_crawl.update_job_detail", update_detail)
    monkeypatch.setattr("app.services.job_crawl.asyncio.sleep", AsyncMock())

    class FakeSession:
        async def __aenter__(self):
            return mock_db

        async def __aexit__(self, *_args):
            return None

    monkeypatch.setattr("app.services.job_crawl.AsyncSessionLocal", lambda: FakeSession())

    result = await process_job_results(
        1,
        [{"job_id": "liepin-1", "title": "Python", "description": "", "address": ""}],
        1,
        platform="liepin",
    )

    assert result["updated_count"] == 1
    update_detail.assert_awaited_once_with(99, adapter=None, platform="liepin")
```

- [ ] **Step 2: Run test and verify it fails**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_pipeline.py::test_existing_job_missing_detail_is_enriched -q"
```

Expected: fail because existing jobs missing details are not queued.

- [ ] **Step 3: Extend `process_job_results()` detail queue**

In `backend/app/services/job_crawl.py`:

1. Add a list near the existing counters:

```python
detail_job_ids: list[int] = []
```

2. When updating existing jobs, append the internal id if detail fields remain missing after the update:

```python
            if not job_obj.description or not job_obj.address:
                detail_job_ids.append(job_obj.id)
```

3. When inserting new jobs, append their ids after flush if the platform policy requires detail enrichment. Keep the already optimized behavior for rows where search results contain both fields:

```python
            inserted_rows = result.all()
            new_job_ids = [row[0] for row in inserted_rows]
            detail_job_ids.extend(
                row[0]
                for row in inserted_rows
                if len(row) < 2 or row[1] in newly_inserted_job_ids_needing_detail
            )
```

4. Run the detail loop over `detail_job_ids`, not only `new_job_ids`.

5. Keep notification and match analysis based on `new_job_ids`, not `detail_job_ids`.

- [ ] **Step 4: Run pipeline tests**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_pipeline.py tests/test_job_crawl.py -q"
```

Expected: all pass.

- [ ] **Step 5: Commit detail queue extension**

```powershell
git add backend/app/services/job_crawl.py backend/tests/test_liepin_pipeline.py backend/tests/test_job_crawl.py
git commit -m "feat: enrich existing jobs missing details"
```

---

### Task 8: Real Liepin E2E Verification

**Files:**
- No source files expected.
- May create retained config in local database.

- [ ] **Step 1: Run backend and frontend if not already running**

Run:

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"
```

Expected:

- Backend responds at `http://127.0.0.1:8000/health`.
- Frontend responds at `http://127.0.0.1:3000`.

- [ ] **Step 2: Confirm CDP browser availability**

Run:

```powershell
powershell.exe -Command "Invoke-RestMethod -Uri http://127.0.0.1:9222/json/version -TimeoutSec 3 | ConvertTo-Json -Compress"
```

Expected: JSON containing `webSocketDebuggerUrl`.

- [ ] **Step 3: Create retained Liepin test config**

Use the default test user credentials from `AGENTS.md`:

```powershell
$login = Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8000/auth/login -ContentType 'application/json' -Body '{"username":"default123","password":"123456"}'
$headers = @{ Authorization = "Bearer $($login.access_token)" }
$body = @{
  name = "codex-e2e-liepin-kept-$(Get-Date -Format HHmmss)"
  platform = "liepin"
  keyword = "python"
  city_code = "020"
  url = "https://www.liepin.com/zhaopin/?key=python&dqs=020&currentPage=0"
  active = $false
  notify_on_new = $false
  deactivation_threshold = 3
  enable_match_analysis = $false
} | ConvertTo-Json
$createdConfig = Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8000/jobs/configs -Headers $headers -ContentType 'application/json' -Body $body
$createdConfig | ConvertTo-Json -Depth 6
```

Expected: JSON config with `platform: "liepin"` and an `id`.

- [ ] **Step 4: Trigger crawl-now and wait for completion**

```powershell
$configId = $createdConfig.id
$trigger = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/jobs/crawl-now/$configId" -Headers $headers
$taskId = $trigger.task_id
for ($i = 0; $i -lt 90; $i++) {
  Start-Sleep -Seconds 2
  $status = Invoke-RestMethod -Uri "http://127.0.0.1:8000/jobs/crawl/status/$taskId" -Headers $headers
  if ($status.status -in @("completed", "success", "error")) { break }
}
$status | ConvertTo-Json -Depth 6
```

Expected: status eventually reaches `completed` or `success`. If it reaches `error`, inspect the latest crawl log and fix adapter parsing or challenge handling before continuing.

- [ ] **Step 5: Verify crawl log and jobs**

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:8000/jobs/crawl-logs?search_config_id=$configId&limit=1&hours=24" -Headers $headers | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri "http://127.0.0.1:8000/jobs?search_config_id=$configId&page=1&page_size=5" -Headers $headers | ConvertTo-Json -Depth 8
```

Expected:

- Latest crawl log has `status: "SUCCESS"`.
- Jobs response has `total > 0`.
- Returned jobs have `platform: "liepin"`.
- At least one returned job has non-empty `description` or `address`.

- [ ] **Step 6: Verify temporary tabs are closed**

```powershell
@'
import http.client, json
conn = http.client.HTTPConnection("127.0.0.1", 9222, timeout=3)
conn.request("GET", "/json")
targets = json.loads(conn.getresponse().read())
conn.close()
liepin = [{"id": t.get("id"), "url": t.get("url")} for t in targets if "liepin.com" in t.get("url", "")]
print(json.dumps({"liepinTargetCount": len(liepin), "liepinTargets": liepin}, ensure_ascii=False, indent=2))
'@ | python -
```

Expected: no new crawl-created Liepin tabs remain. If the user already had Liepin tabs open before the crawl, those may remain.

- [ ] **Step 7: Commit E2E stabilization fixes if any**

If adapter changes were required during E2E:

```powershell
git add backend/app/platforms/liepin.py backend/tests/test_liepin_adapter.py backend/tests/test_liepin_pipeline.py
git commit -m "fix: stabilize liepin live crawl"
```

If no changes were required, do not create an empty commit.

---

### Task 9: Final Verification and Ship Commit

**Files:**
- All touched files.

- [ ] **Step 1: Run targeted backend tests**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_liepin_adapter.py tests/test_liepin_pipeline.py tests/test_job_crawl.py tests/test_job_phase3_integration.py tests/test_jobs_api.py tests/test_schemas.py -q"
```

Expected: all pass.

- [ ] **Step 2: Run full backend tests**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest"
```

Expected: pass. If failures are unrelated repo debt, record exact failing tests and run targeted tests for touched areas.

- [ ] **Step 3: Run backend lint**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app/platforms/liepin.py app/platforms/cdp_utils.py app/services/job_crawl.py app/schemas/job.py app/models/job.py app/services/notification.py tests/test_liepin_adapter.py tests/test_liepin_pipeline.py"
```

Expected: `All checks passed!`.

- [ ] **Step 4: Run frontend gates**

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run lint"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/frontend; npm run build"
```

Expected:

- lint exits 0.
- build exits 0. Vite chunk-size warnings are acceptable if unchanged.

- [ ] **Step 5: Run GitNexus detect changes**

```powershell
npx gitnexus detect-changes
```

Expected: impacted flows are limited to job crawling/platform routing/frontend platform display. If risk is HIGH or CRITICAL, list the affected flows in the final handoff.

- [ ] **Step 6: Confirm runtime artifacts are not staged**

Run:

```powershell
git status --short
```

If any cookie/runtime files are modified, restore them before commit:

```powershell
$content = git show HEAD:backend/app/platforms/.boss_cookies.json
[System.IO.File]::WriteAllText((Resolve-Path 'backend/app/platforms/.boss_cookies.json'), $content, [System.Text.UTF8Encoding]::new($false))
```

Do not stage `.51job_cookies.json`, `.boss_cookies.json`, screenshots, or browser output.

- [ ] **Step 7: Final commit**

```powershell
git add backend/app/platforms/cdp_utils.py backend/app/platforms/liepin.py backend/app/platforms/__init__.py backend/app/models/job.py backend/app/schemas/job.py backend/app/services/job_crawl.py backend/app/services/notification.py backend/alembic/versions/2026_05_19_add_liepin_job_platform.py backend/tests/test_liepin_adapter.py backend/tests/test_liepin_pipeline.py frontend/src/types/index.ts frontend/src/components/JobList.tsx
git commit -m "feat: add liepin job crawling"
```

Commit body should include:

```text
Adds Liepin as a job platform with HTTP-first search, CDP fallback, temporary tab cleanup, normalized search result persistence, and detail enrichment for new or incomplete jobs.

Includes platform contract updates, frontend platform display, adapter tests, pipeline tests, and live E2E verification using a retained codex-e2e-liepin config.
```

---

## Self-Review Checklist

- Spec coverage:
  - Platform key and UI display: Task 3.
  - HTTP-first search: Task 4.
  - CDP fallback and temporary tab cleanup: Tasks 2 and 5.
  - Optional logged-in browser reuse: Task 5 via browser-context fetch.
  - Search plus detail persistence: Tasks 4, 6, and 7.
  - Detail failure isolation and熔断 behavior: Tasks 7 and 9 verification; implement within the existing detail loop.
  - Scheduling: Task 3 adapter routing through `crawl_single_config()`.
  - Real E2E: Task 8.
- Red-flag scan:
  - Liepin's live endpoint path and JSON shape are discovery-dependent; Task 1 creates a required discovery artifact and Task 4 names the constants to update from that artifact.
- Type consistency:
  - Platform key is consistently `liepin`.
  - Adapter class is consistently `LiepinAdapter`.
  - CDP helper names are consistently `open_temporary_tab`, `close_target`, and `evaluate_json_fetch`.
