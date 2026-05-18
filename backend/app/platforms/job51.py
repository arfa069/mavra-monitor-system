"""51job (前程无忧) platform adapter for job search crawling.

Strategy: curl_cffi impersonates Chrome at TLS level. Cookies are read from
the CDP browser (if a 51job tab is open) or from disk cache, then used for
API calls. Falls back to Playwright for detail page rendering when needed.

NOTE: The search API endpoint and response format must be confirmed via
browser DevTools packet capture before the crawl() method is fully
functional. This skeleton provides the Cookie lifecycle and framework.
"""

import asyncio
import json
import logging
import random
import time
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse

import websockets
from curl_cffi.requests import Session as CffiSession

from app.platforms.base import BasePlatformAdapter

logger = logging.getLogger(__name__)

MAX_PAGES = 3
SEARCH_DOMAIN = "we.51job.com"
BASE_URL = f"https://{SEARCH_DOMAIN}"
# TODO: Confirm via browser DevTools packet capture
SEARCH_API_PATH = "/api/job/search-pc"
CDP_BASE = "http://127.0.0.1:9222"
COOKIE_FILE = Path(__file__).resolve().parent / ".51job_cookies.json"


class Job51Adapter(BasePlatformAdapter):
    """Adapter for 51job (前程无忧) job search crawling.

    Cookie lifecycle:
    1. Read cookies from CDP browser via raw WebSocket (if 51job tab open).
    2. Fall back to disk cache (.51job_cookies.json).
    3. If both fail, use Playwright to visit search page and extract cookies.
    4. CffiSession auto-updates cookies from API Set-Cookie headers.
    5. Persist cookies to disk after each successful crawl.
    """

    def __init__(self):
        super().__init__()
        self._session: CffiSession | None = None
        self._cookies_acquired_at: float = 0

    def _get_session(self) -> CffiSession:
        if self._session is None:
            self._session = CffiSession()
        return self._session

    # ── Public interface ──────────────────────────────────────────────

    async def extract_price(self, page) -> dict[str, Any]:
        raise NotImplementedError("Job adapter does not extract prices")

    async def extract_title(self, page) -> str:
        raise NotImplementedError("Job adapter does not extract titles")

    # ── Cookie acquisition via raw WebSocket CDP ───────────────────────

    @staticmethod
    async def _get_cookies_via_raw_cdp() -> dict[str, str]:
        """Read 51job cookies via raw WebSocket CDP — only 2 commands."""
        ws_url = await Job51Adapter._find_page_ws()
        if not ws_url:
            return {}

        try:
            async with websockets.connect(ws_url, max_size=2 ** 24) as ws:
                await ws.send(json.dumps({"id": 1, "method": "Network.enable"}))
                await asyncio.wait_for(ws.recv(), timeout=2)

                await ws.send(json.dumps({
                    "id": 2, "method": "Network.getCookies",
                    "params": {"urls": [f"https://{SEARCH_DOMAIN}/"]},
                }))
                raw = await asyncio.wait_for(ws.recv(), timeout=2)
                result = json.loads(raw)

            cookies = {}
            for c in result.get("result", {}).get("cookies", []):
                cookies[c["name"]] = c["value"]
            logger.debug("51job Raw CDP: %d cookies", len(cookies))
            return cookies

        except Exception as e:
            logger.warning("51job Raw CDP cookie read failed: %s", e)
            return {}

    @staticmethod
    async def _find_page_ws() -> str | None:
        """Find a 51job page's WebSocket CDP URL."""
        import http.client

        conn = None
        try:
            conn = http.client.HTTPConnection("127.0.0.1", 9222, timeout=3)
            conn.request("GET", "/json")
            resp = conn.getresponse()
            targets = json.loads(resp.read())
            conn.close()

            for t in targets:
                url = t.get("url", "")
                if "51job" in url and "socket" not in url:
                    return t["webSocketDebuggerUrl"]

            # Fall back to any open page
            for t in targets:
                if "webSocketDebuggerUrl" in t:
                    return t["webSocketDebuggerUrl"]
        except Exception:
            if conn:
                try:
                    conn.close()
                except Exception:
                    pass
        return None

    # ── Cookie persistence ─────────────────────────────────────────────

    @staticmethod
    def _load_cookies() -> dict[str, str]:
        try:
            if COOKIE_FILE.exists():
                return json.loads(COOKIE_FILE.read_text())
        except Exception:
            pass
        return {}

    @staticmethod
    def _save_cookies(cffi_session: CffiSession) -> None:
        try:
            COOKIE_FILE.write_text(json.dumps(
                cffi_session.cookies.get_dict()
            ))
        except Exception:
            pass

    # ── Cookie acquisition orchestrator ────────────────────────────────

    async def _acquire_cookies(self, session: CffiSession) -> bool:
        """Load cookies for 51job API calls.

        Priority: CDP → disk cache → homepage visit.
        """
        logger.info("51job _acquire_cookies: START")

        # 1. CDP
        cdp_cookies = await self._get_cookies_via_raw_cdp()
        if cdp_cookies:
            for k, v in cdp_cookies.items():
                session.cookies.set(k, v, domain=f".{SEARCH_DOMAIN}", path="/")
            logger.info("51job _acquire_cookies: using CDP cookies (%d)", len(cdp_cookies))
            self._cookies_acquired_at = time.time()
            return True

        # 2. Disk cache
        saved = self._load_cookies()
        if saved:
            for k, v in saved.items():
                session.cookies.set(k, v, domain=f".{SEARCH_DOMAIN}", path="/")
            logger.info("51job _acquire_cookies: using disk cache (%d)", len(saved))
            self._cookies_acquired_at = time.time()
            return True

        # 3. Visit homepage to seed cookies
        try:
            session.get(
                f"{BASE_URL}/",
                impersonate="chrome124",
                headers={"Referer": f"{BASE_URL}/"},
            )
            if session.cookies.get_dict():
                logger.info("51job _acquire_cookies: seeded from homepage")
                self._cookies_acquired_at = time.time()
                return True
        except Exception as e:
            logger.warning("51job homepage cookie seed failed: %s", e)

        logger.warning("51job _acquire_cookies: ALL FAILED")
        return False

    async def _ensure_cookies(self) -> bool:
        """Ensure the adapter has valid cookies."""
        if self._cookies_acquired_at and time.time() - self._cookies_acquired_at < 300:
            return True
        return await self._acquire_cookies(self._get_session())

    # ── Crawl ───────────────────────────────────────────────────────────

    async def crawl(self, url: str) -> dict[str, Any]:
        """Crawl 51job job search results via curl_cffi.

        Args:
            url: The 51job search URL
                 (e.g. https://we.51job.com/pc/search?keyword=python&searchType=2)

        Returns:
            {"success": True, "jobs": [...], "count": N}
            or {"success": False, "error": "..."}

        NOTE: The search API endpoint must be confirmed via browser DevTools.
              This implementation parses the URL parameters and attempts to
              call the backend API. If the API structure differs, this method
              needs to be updated based on actual packet capture results.
        """
        try:
            session = self._get_session()

            if not await self._ensure_cookies():
                logger.warning("51job crawl: proceeding without cookies")

            parsed = urlparse(url)
            params = parse_qs(parsed.query, keep_blank_values=True)

            all_jobs: list[dict] = []
            pages_fetched = 0

            for page_num in range(1, MAX_PAGES + 1):
                params["pageNum"] = [str(page_num)]
                params["pageSize"] = ["50"]
                query = urlencode(params, doseq=True)

                # TODO: Replace with confirmed API endpoint from packet capture
                api_url = f"{BASE_URL}{SEARCH_API_PATH}?{query}"

                resp = session.get(
                    api_url,
                    impersonate="chrome124",
                    headers={
                        "Referer": url,
                        "Accept": "application/json, text/plain, */*",
                        "Origin": BASE_URL,
                    },
                )

                if resp.status_code != 200:
                    logger.warning("51job API HTTP %d on page %d", resp.status_code, page_num)
                    break

                try:
                    data = resp.json()
                except Exception:
                    logger.warning("51job API returned non-JSON on page %d", page_num)
                    break

                # TODO: Adjust JSON path based on actual API response structure
                # Possible paths: data.resultbody.job.items, data.jobList, etc.
                status_code = data.get("status") or data.get("code")
                if status_code and str(status_code) != "1" and str(status_code) != "0":
                    logger.warning("51job API status=%s on page %d", status_code, page_num)
                    break

                # Try common response structures
                page_jobs = (
                    data.get("resultbody", {}).get("job", {}).get("items", [])
                    or data.get("engine_jds", [])
                    or data.get("jobList", [])
                    or data.get("data", {}).get("jobList", [])
                    or []
                )

                if page_jobs:
                    all_jobs.extend(page_jobs)
                    pages_fetched = page_num
                else:
                    break

                # Check for more pages
                has_more = (
                    data.get("resultbody", {}).get("job", {}).get("total_page", 0) > page_num
                    or len(page_jobs) >= 50
                )
                if not has_more:
                    break

                await asyncio.sleep(random.uniform(3.0, 6.0))

            if all_jobs:
                transformed = self._transform_jobs(all_jobs)
                logger.info(
                    "51job curl_cffi: %d jobs from %d page(s)",
                    len(transformed), pages_fetched,
                )
                self._save_cookies(session)
                return {"success": True, "jobs": transformed, "count": len(transformed)}

            return {"success": False, "error": "No job data from 51job search API"}

        except Exception as e:
            logger.exception("51job crawl failed")
            return {"success": False, "error": str(e)}

    async def crawl_detail(self, job_id: str) -> dict[str, Any]:
        """Fetch 51job job detail.

        Uses curl_cffi to call detail API if available, otherwise
        falls back to Playwright for page rendering.

        Args:
            job_id: The 51job internal job ID.

        Returns:
            {"success": True, "detail": {...}} or {"success": False, "error": "..."}
        """
        try:
            session = self._get_session()

            if not await self._ensure_cookies():
                logger.warning("51job detail: proceeding without cookies")

            # TODO: Confirm detail API endpoint via packet capture
            detail_url = f"{BASE_URL}/api/job/detail?jobId={job_id}"
            resp = session.get(
                detail_url,
                impersonate="chrome124",
                headers={
                    "Referer": f"{BASE_URL}/",
                    "Accept": "application/json, text/plain, */*",
                },
            )

            if resp.status_code != 200:
                return {"success": False, "error": f"HTTP {resp.status_code}"}

            try:
                data = resp.json()
            except Exception:
                return {"success": False, "error": "Non-JSON response from detail API"}

            # TODO: Adjust field paths based on actual API response
            job_info = data.get("data", {}) or data.get("jobDetail", {}) or {}

            self._save_cookies(session)

            return {
                "success": True,
                "detail": {
                    "job_id": job_id,
                    "title": job_info.get("jobName", ""),
                    "salary": job_info.get("provideSalaryString", ""),
                    "location": job_info.get("workAreaString", ""),
                    "address": job_info.get("workAddress", ""),
                    "experience": job_info.get("workYearString", ""),
                    "education": job_info.get("degreeString", ""),
                    "description": job_info.get("jobDescribe", ""),
                    "company": job_info.get("companyName", ""),
                    "company_stage": job_info.get("companyTypeString", ""),
                    "company_scale": job_info.get("companySizeString", ""),
                    "company_industry": job_info.get("companyIndString", ""),
                },
            }

        except Exception as e:
            logger.exception("51job detail crawl failed")
            return {"success": False, "error": str(e)}

    # ── Data transformation ────────────────────────────────────────────

    def _transform_jobs(self, raw_jobs: list[dict]) -> list[dict]:
        """Transform 51job raw data to unified format.

        NOTE: Field names must be adjusted based on actual API response
        after packet capture confirmation.
        """
        transformed = []
        for job in raw_jobs:
            # Try multiple possible field name patterns
            job_id = (
                job.get("jobId")
                or job.get("job_id")
                or job.get("jobid")
                or str(job.get("id", ""))
            )
            if not job_id:
                continue

            title = job.get("jobName") or job.get("job_name") or job.get("jname", "")
            company = job.get("companyName") or job.get("company_name") or job.get("cname", "")
            salary = job.get("provideSalaryString") or job.get("salary") or job.get("sal", "")
            location = job.get("workAreaString") or job.get("work_area") or job.get("workarea", "")
            experience = job.get("workYearString") or job.get("work_year") or job.get("attribute", {}).get("experience", "")
            education = job.get("degreeString") or job.get("degree") or job.get("attribute", {}).get("education", "")

            # Build detail URL
            detail_url = ""
            href = job.get("job_href") or job.get("jobHref") or job.get("detailUrl")
            if href:
                detail_url = href if href.startswith("http") else f"{BASE_URL}{href}"

            transformed.append({
                "job_id": str(job_id),
                "title": title,
                "company": company,
                "company_id": str(job.get("companyId") or job.get("company_id") or job.get("coid", "")),
                "salary": salary,
                "location": location,
                "experience": experience,
                "education": education,
                "url": detail_url,
            })
        return transformed
