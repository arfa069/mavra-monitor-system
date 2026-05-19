"""51job (前程无忧) platform adapter for job search crawling.

Search crawling runs inside a real browser page via CDP. Each crawl opens a
temporary we.51job.com search tab, executes the search-pc API fetch in that
browser context so WAF cookies and browser state are preserved, then closes the
temporary tab. Cookie helpers remain for detail-page fallback paths.
"""

import asyncio
import json
import logging
import random
import time
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, quote, urlencode, urlparse

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

    Search results are fetched through a temporary CDP browser tab. The cookie
    lifecycle is only used by detail fallback requests.
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

            # Prefer we.51job.com for search APIs to avoid CORS
            for t in targets:
                url = t.get("url", "")
                if "we.51job.com" in url and "socket" not in url:
                    return t["webSocketDebuggerUrl"]

            logger.info("No 51job CDP page found")
        except Exception:
            if conn:
                try:
                    conn.close()
                except Exception:
                    pass
        return None

    @staticmethod
    async def _open_search_page_ws(keyword: str, job_area: str) -> tuple[str | None, str | None]:
        """Open a temporary 51job search tab and return its CDP URL and target id."""
        import http.client

        search_url = (
            f"{BASE_URL}/pc/search?"
            f"{urlencode({'keyword': keyword, 'searchType': '2', 'jobArea': job_area})}"
        )
        conn = None
        try:
            conn = http.client.HTTPConnection("127.0.0.1", 9222, timeout=5)
            conn.request("PUT", f"/json/new?{quote(search_url, safe='')}")
            resp = conn.getresponse()
            target = json.loads(resp.read())
            conn.close()

            ws_url = target.get("webSocketDebuggerUrl")
            target_id = target.get("id")
            if ws_url and target_id:
                logger.info("Opened temporary 51job CDP page: %s", target_id)
                await asyncio.sleep(2)
                return ws_url, target_id
        except Exception as e:
            logger.warning("Failed to open temporary 51job CDP page: %s", e)
            if conn:
                try:
                    conn.close()
                except Exception:
                    pass
        return None, None

    @staticmethod
    async def _close_page(target_id: str) -> None:
        """Close a CDP target by id."""
        import http.client

        conn = None
        try:
            conn = http.client.HTTPConnection("127.0.0.1", 9222, timeout=3)
            conn.request("GET", f"/json/close/{target_id}")
            conn.getresponse()
            conn.close()
            logger.info("Closed temporary 51job CDP page: %s", target_id)
        except Exception as e:
            logger.warning("Failed to close temporary 51job CDP page %s: %s", target_id, e)
            if conn:
                try:
                    conn.close()
                except Exception:
                    pass

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

    # ── Crawl via CDP ───────────────────────────────────────────────────

    async def crawl(self, url: str) -> dict[str, Any]:
        """Crawl 51job search results using CDP to execute fetch in-browser.

        Since 51job uses strong Aliyun WAF, using curl_cffi often triggers
        a block if the TLS fingerprint or headers don't match exactly.
        Executing fetch via the existing browser tab guarantees success.
        """
        try:
            parsed = urlparse(url)
            params = parse_qs(parsed.query, keep_blank_values=True)
            keyword = params.get("keyword", [""])[0]
            job_area = params.get("jobArea", ["000000"])[0]

            ws_url, temporary_target_id = await self._open_search_page_ws(keyword, job_area)
            if not ws_url:
                return {"success": False, "error": "请启动已开启远程调试端口的浏览器，以便自动打开前程无忧搜索页"}

            # If the user only has the detail page open, fetching the search API will fail due to CORS.
            # We can't perfectly check ws_url's actual URL here without another CDP call,
            # but if it fails with TypeError, we will return a helpful error.

            all_jobs: list[dict] = []
            pages_fetched = 0

            import time
            import uuid

            try:
                async with websockets.connect(ws_url, max_size=2 ** 24) as ws:
                    for page_num in range(1, MAX_PAGES + 1):
                        api_params = {
                            "api_key": "51job",
                            "timestamp": str(int(time.time())),
                            "keyword": keyword,
                            "searchType": "2",
                            "function": "",
                            "industry": "",
                            "jobArea": job_area,
                            "jobArea2": "",
                            "landmark": "",
                            "metro": "",
                            "salary": "",
                            "workYear": "",
                            "degree": "",
                            "companyType": "",
                            "companySize": "",
                            "jobType": "",
                            "issueDate": "",
                            "sortType": "0",
                            "pageNum": str(page_num),
                            "requestId": uuid.uuid4().hex,
                            "pageSize": "50",
                            "source": "1",
                            "accountId": "",
                            "pageCode": "sou|sou|soulb",
                            "scene": "7",
                        }
                        query = urlencode(api_params)
                        api_url = f"{BASE_URL}{SEARCH_API_PATH}?{query}"

                        # Execute fetch inside the browser tab
                        js_code = f"""
                        new Promise((resolve, reject) => {{
                            fetch('{api_url}', {{
                                headers: {{
                                    "Accept": "application/json, text/plain, */*",
                                    "property": '{{\"partner\":\"\",\"webId\":\"2\",\"clientType\":\"pc\"}}'
                                }}
                            }})
                            .then(r => r.json())
                            .then(d => resolve(JSON.stringify(d)))
                            .catch(e => resolve(JSON.stringify({{error: e.toString()}})));
                        }})
                        """

                        await ws.send(json.dumps({
                            "id": page_num,
                            "method": "Runtime.evaluate",
                            "params": {
                                "expression": js_code,
                                "awaitPromise": True,
                                "returnByValue": True
                            }
                        }))

                        raw_resp = await asyncio.wait_for(ws.recv(), timeout=10)
                        result_payload = json.loads(raw_resp)

                        if "error" in result_payload:
                            logger.warning("CDP Error: %s", result_payload["error"])
                            break

                        # Extract stringified JSON from CDP response
                        try:
                            value_str = result_payload.get("result", {}).get("result", {}).get("value", "{}")
                            data = json.loads(value_str)
                        except Exception as e:
                            logger.warning("Failed to parse CDP fetch result: %s", e)
                            break

                        if data.get("error"):
                            err_msg = data['error']
                            if "Failed to fetch" in err_msg:
                                logger.warning("CORS Error: Please ensure you are on we.51job.com")
                                return {"success": False, "error": "请确保浏览器停留在前程无忧搜索页 (we.51job.com)，不要停留在详情页，否则会因跨域被拦截。"}
                            logger.warning("Browser fetch failed: %s", err_msg)
                            break

                        # Common response structures
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

                        await asyncio.sleep(random.uniform(2.0, 4.0))
            finally:
                if temporary_target_id:
                    await self._close_page(temporary_target_id)

            if all_jobs:
                transformed = self._transform_jobs(all_jobs)
                logger.info("51job CDP fetch: %d jobs from %d page(s)", len(transformed), pages_fetched)
                return {"success": True, "jobs": transformed, "count": len(transformed)}

            return {"success": False, "error": "No job data from 51job search API via CDP"}

        except Exception as e:
            logger.exception("51job crawl failed")
            return {"success": False, "error": str(e)}

    async def crawl_detail(self, job_id: str) -> dict[str, Any]:
        """Fetch 51job job detail using HTML parsing.

        Args:
            job_id: The 51job internal job ID.

        Returns:
            {"success": True, "detail": {...}} or {"success": False, "error": "..."}
        """
        try:
            session = self._get_session()

            if not await self._ensure_cookies():
                logger.warning("51job detail: proceeding without cookies")

            # detail URL format: https://jobs.51job.com/{location}/{job_id}.html
            # But the backend doesn't know location. However, 51job supports a generic detail URL:
            # We can use the generic detail page or search for the exact URL.
            # Actually, the database already stores the full URL in job.url.
            # In our pipeline, `update_job_detail` calls `crawl_detail` with `job.job_id`.
            # If we don't have the full URL, we can use a proxy search API or Playwright.
            # Wait, 51job supports https://jobs.51job.com/all/{job_id}.html
            detail_url = f"https://jobs.51job.com/all/{job_id}.html"

            resp = session.get(
                detail_url,
                impersonate="chrome124",
                headers={
                    "Referer": f"{BASE_URL}/",
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
                },
            )

            if resp.status_code != 200:
                return {"success": False, "error": f"HTTP {resp.status_code}"}

            import re

            from bs4 import BeautifulSoup

            soup = BeautifulSoup(resp.text, "html.parser")

            # WAF Check
            if soup.find("meta", attrs={"name": "aliyun_waf_aa"}):
                return {"success": False, "error": "Blocked by Aliyun WAF"}

            # Extract data based on DOM
            # Description
            job_msg_div = soup.select_one("div.job_msg") or soup.select_one("div.bmsg.job_msg.inbox")
            description = job_msg_div.get_text(strip=True, separator="\n") if job_msg_div else ""

            # Remove trailing extra text like "分享 微信 邮件"
            description = re.sub(r'分享\s*微信\s*邮件.*$', '', description, flags=re.DOTALL).strip()

            # Address
            address_div = soup.find("span", class_="label", string=re.compile(r"上班地址："))
            address = ""
            if address_div and address_div.parent:
                address = address_div.parent.get_text(strip=True).replace("上班地址：", "")

            self._save_cookies(session)

            return {
                "success": True,
                "detail": {
                    "job_id": job_id,
                    "description": description,
                    "address": address,
                },
            }

        except Exception as e:
            logger.exception("51job detail crawl failed")
            return {"success": False, "error": str(e)}

    # ── Data transformation ────────────────────────────────────────────

    def _transform_jobs(self, raw_jobs: list[dict]) -> list[dict]:
        """Transform 51job raw data to unified format."""
        transformed = []
        for job in raw_jobs:
            job_id = job.get("jobId")
            if not job_id:
                continue

            title = job.get("jobName", "")
            company = job.get("fullCompanyName") or job.get("companyName", "")
            salary = job.get("provideSalaryString", "")
            location = job.get("jobAreaString") or job.get("workAreaString", "")
            experience = job.get("workYearString", "")
            education = job.get("degreeString", "")
            description = job.get("jobDescribe", "")
            address = job.get("workAddress", "")

            # Build detail URL
            detail_url = ""
            href = job.get("jobHref", "")
            if href:
                detail_url = href if href.startswith("http") else f"https://we.51job.com{href}"

            transformed.append({
                "job_id": str(job_id),
                "title": title,
                "company": company,
                "company_id": str(job.get("encCoId") or job.get("coId") or company),
                "salary": salary,
                "location": location,
                "experience": experience,
                "education": education,
                "description": description,
                "address": address,
                "url": detail_url,
            })
        return transformed
