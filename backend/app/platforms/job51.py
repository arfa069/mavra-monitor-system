"""51job (前程无忧) platform adapter for job search crawling.

Search crawling runs inside a CloakBrowser persistent profile. Each crawl opens
or reloads a real we.51job.com search page, executes the search-pc API fetch in
that browser context so WAF cookies and browser state are preserved, then closes
the CloakBrowser context. Cookie helpers remain for detail-page fallback paths.
"""

import asyncio
import json
import logging
import random
import time
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse

from curl_cffi.requests import Session as CffiSession

from app.core.crawler_paths import build_profile_dir
from app.platforms.base import BasePlatformAdapter

logger = logging.getLogger(__name__)

MAX_PAGES = 3
SEARCH_DOMAIN = "we.51job.com"
BASE_URL = f"https://{SEARCH_DOMAIN}"
# TODO: Confirm via browser DevTools packet capture
SEARCH_API_PATH = "/api/job/search-pc"
API_PROPERTY_HEADER = json.dumps({"partner": "", "webId": "2", "clientType": "pc"}, separators=(",", ":"))


class Job51Adapter(BasePlatformAdapter):
    """Adapter for 51job (前程无忧) job search crawling.

    Search results are fetched through a CloakBrowser profile page. The cookie
    lifecycle is shared by search and detail fallback requests.
    """

    def __init__(
        self,
        *,
        profile_dir: str | Path | None = None,
        headless: bool = True,
        max_pages: int = MAX_PAGES,
    ):
        super().__init__()
        self.profile_dir = Path(profile_dir) if profile_dir else build_profile_dir(
            "51job",
            "default",
        )
        self.headless = headless
        self.max_pages = max_pages
        self._session: CffiSession | None = None
        self._cookies_acquired_at: float = 0
        self._headers: dict[str, str] = {}
        self._search_page = BASE_URL
        self._cloak_context = None
        self._cloak_page = None

    def _get_session(self) -> CffiSession:
        if self._session is None:
            self._session = CffiSession()
        return self._session

    # ── Public interface ──────────────────────────────────────────────

    async def extract_price(self, page) -> dict[str, Any]:
        raise NotImplementedError("Job adapter does not extract prices")

    async def extract_title(self, page) -> str:
        raise NotImplementedError("Job adapter does not extract titles")

    # ── CloakBrowser lifecycle ────────────────────────────────────────

    def _start_browser(self) -> None:
        if self._cloak_context is not None:
            return
        from cloakbrowser import launch_persistent_context

        self._cloak_context = launch_persistent_context(
            str(self.profile_dir),
            headless=self.headless,
            locale="zh-CN",
            timezone="Asia/Shanghai",
            humanize=True,
            viewport={"width": 1440, "height": 1000},
        )
        self._cloak_page = self._cloak_context.new_page()

    def _close_browser_sync(self) -> None:
        if self._cloak_context is None:
            return
        try:
            self._cloak_context.close()
        except Exception:
            logger.exception("Failed to close 51job CloakBrowser context")
        finally:
            self._cloak_context = None
            self._cloak_page = None

    def _refresh_cookies_sync(self, reason: str) -> bool:
        logger.info("Refreshing 51job CloakBrowser cookies: %s", reason)
        page = self._cloak_page
        context = self._cloak_context
        if page is None or context is None:
            raise RuntimeError("CloakBrowser is not started")

        if not page.url.startswith(BASE_URL):
            page.goto(self._search_page, wait_until="domcontentloaded", timeout=45000)
        else:
            page.reload(wait_until="domcontentloaded", timeout=45000)
        try:
            page.wait_for_load_state("domcontentloaded", timeout=10000)
        except Exception:
            logger.debug("51job Cloak page still navigating after refresh")
        page.wait_for_timeout(1000)

        cookies = context.cookies([f"{BASE_URL}/", "https://51job.com/"])
        session = self._get_session()
        for cookie in cookies:
            kwargs = {"path": cookie.get("path") or "/"}
            if cookie.get("domain"):
                kwargs["domain"] = cookie["domain"]
            session.cookies.set(cookie["name"], cookie["value"], **kwargs)

        user_agent = self._evaluate_page_value("() => navigator.userAgent")
        language = self._evaluate_page_value("() => navigator.language")
        self._headers = {
            "Referer": self._search_page,
            "User-Agent": user_agent,
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": f"{language},zh-CN;q=0.9,zh;q=0.8,en;q=0.7",
            "property": API_PROPERTY_HEADER,
        }
        self._cookies_acquired_at = time.time()
        logger.info("51job Cloak cookie refresh: %d cookies", len(cookies))
        return bool(cookies)

    def _evaluate_page_value(self, expression: str) -> str:
        page = self._cloak_page
        if page is None:
            return ""
        last_error: Exception | None = None
        for _ in range(3):
            try:
                value = page.evaluate(expression)
                return str(value or "")
            except Exception as exc:
                last_error = exc
                if "Execution context was destroyed" not in str(exc):
                    raise
                page.wait_for_timeout(1000)
        raise last_error or RuntimeError("Failed to evaluate 51job Cloak page")

    # ── Cookie acquisition orchestrator ────────────────────────────────

    async def _acquire_cookies(self, session: CffiSession) -> bool:
        """Load cookies for 51job API calls.

        Priority: in-memory/session → CloakBrowser refresh → anonymous
        homepage visit. Cookies are intentionally not copied to a JSON file.
        """
        logger.info("51job _acquire_cookies: START")

        if session.cookies.get_dict():
            self._cookies_acquired_at = time.time()
            return True

        try:
            return await asyncio.to_thread(self._refresh_cookies_for_detail_sync)
        except Exception as e:
            logger.warning("51job Cloak cookie refresh failed: %s", e)

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

    def _refresh_cookies_for_detail_sync(self) -> bool:
        self._start_browser()
        if not self._search_page:
            self._search_page = BASE_URL
        try:
            return self._refresh_cookies_sync("detail_cookie_acquire")
        finally:
            self._close_browser_sync()

    async def _ensure_cookies(self) -> bool:
        """Ensure the adapter has valid cookies."""
        if self._cookies_acquired_at and time.time() - self._cookies_acquired_at < 300:
            return True
        return await self._acquire_cookies(self._get_session())

    # ── Crawl via CloakBrowser ─────────────────────────────────────────

    async def crawl(self, url: str) -> dict[str, Any]:
        """Crawl 51job search results using CloakBrowser page fetch.

        Since 51job uses strong Aliyun WAF, using curl_cffi often triggers
        a block if the TLS fingerprint or headers don't match exactly.
        Executing fetch via a CloakBrowser profile preserves browser state
        without relying on Chrome remote debugging / CDP mode.
        """
        return await asyncio.to_thread(self._crawl_sync, url)

    def _crawl_sync(self, url: str) -> dict[str, Any]:
        """Synchronous crawl body run in a worker thread."""
        try:
            keyword, job_area = self._parse_search(url)
            self._search_page = self._build_search_page(keyword, job_area)
            self._start_browser()
            self._refresh_cookies_sync("crawl_start")

            all_jobs: list[dict] = []
            pages_fetched = 0

            for page_num in range(1, self.max_pages + 1):
                data = self._fetch_search_page_sync(keyword, job_area, page_num)

                page_jobs = self._extract_page_jobs(data)
                if page_jobs:
                    all_jobs.extend(page_jobs)
                    pages_fetched = page_num
                else:
                    break

                if not self._has_more_pages(data, page_jobs, page_num):
                    break

                time.sleep(random.uniform(2.0, 4.0))

            if all_jobs:
                transformed = self._transform_jobs(all_jobs)
                logger.info("51job Cloak fetch: %d jobs from %d page(s)", len(transformed), pages_fetched)
                return {"success": True, "jobs": transformed, "count": len(transformed)}

            return {"success": False, "error": "No job data from 51job search API via CloakBrowser"}

        except Exception as e:
            logger.exception("51job crawl failed")
            return {"success": False, "error": str(e)}
        finally:
            self._close_browser_sync()

    def _fetch_search_page_sync(self, keyword: str, job_area: str, page_num: int) -> dict[str, Any]:
        """Fetch one search result page in the active CloakBrowser page."""
        page = self._cloak_page
        if page is None:
            raise RuntimeError("CloakBrowser is not started")

        api_url = f"{BASE_URL}{SEARCH_API_PATH}?{urlencode(self._build_api_params(keyword, job_area, page_num))}"
        js_code = """
        async ({ apiUrl, propertyHeader }) => {
            const response = await fetch(apiUrl, {
                headers: {
                    "Accept": "application/json, text/plain, */*",
                    "property": propertyHeader
                },
                credentials: "include"
            });
            return {
                ok: response.ok,
                status: response.status,
                contentType: response.headers.get("content-type") || "",
                body: await response.text()
            };
        }
        """
        result = page.evaluate(js_code, {"apiUrl": api_url, "propertyHeader": API_PROPERTY_HEADER})
        status = result.get("status")
        if not result.get("ok"):
            raise RuntimeError(f"51job search API HTTP {status}")

        body = result.get("body") or "{}"
        try:
            return json.loads(body)
        except json.JSONDecodeError as exc:
            logger.warning("51job search API returned non-JSON content-type=%s", result.get("contentType"))
            raise RuntimeError("51job search API returned non-JSON response") from exc

    @staticmethod
    def _parse_search(url: str) -> tuple[str, str]:
        parsed = urlparse(url)
        params = parse_qs(parsed.query, keep_blank_values=True)
        keyword = params.get("keyword", [""])[0]
        job_area = params.get("jobArea", ["000000"])[0]
        return keyword, job_area

    @staticmethod
    def _build_search_page(keyword: str, job_area: str) -> str:
        return (
            f"{BASE_URL}/pc/search?"
            f"{urlencode({'keyword': keyword, 'searchType': '2', 'jobArea': job_area})}"
        )

    @staticmethod
    def _build_api_params(keyword: str, job_area: str, page_num: int) -> dict[str, str]:
        import uuid

        return {
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

    @staticmethod
    def _extract_page_jobs(data: dict[str, Any]) -> list[dict[str, Any]]:
        return (
            data.get("resultbody", {}).get("job", {}).get("items", [])
            or data.get("engine_jds", [])
            or data.get("jobList", [])
            or data.get("data", {}).get("jobList", [])
            or []
        )

    @staticmethod
    def _has_more_pages(data: dict[str, Any], page_jobs: list[dict[str, Any]], page_num: int) -> bool:
        return (
            data.get("resultbody", {}).get("job", {}).get("total_page", 0) > page_num
            or len(page_jobs) >= 50
        )

    async def crawl_detail(self, job_id: str, detail_url: str = "") -> dict[str, Any]:
        """Fetch 51job job detail using HTML parsing.

        Args:
            job_id: The 51job internal job ID.
            detail_url: Optional full detail URL captured from search results.

        Returns:
            {"success": True, "detail": {...}} or {"success": False, "error": "..."}
        """
        return await asyncio.to_thread(self._crawl_detail_sync, job_id, detail_url)

    def _crawl_detail_sync(self, job_id: str, detail_url: str = "") -> dict[str, Any]:
        """Fetch one 51job detail page, falling back to CloakBrowser on WAF."""
        try:
            session = self._get_session()

            if not self._ensure_cookies_sync():
                logger.warning("51job detail: proceeding without cookies")

            detail_url = detail_url or f"https://jobs.51job.com/all/{job_id}.html"

            resp = session.get(
                detail_url,
                impersonate="chrome124",
                timeout=30,
                headers={
                    "Referer": f"{BASE_URL}/",
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
                },
            )

            if resp.status_code != 200:
                return self._crawl_detail_via_cloak_sync(job_id, detail_url, f"HTTP {resp.status_code}")

            parsed = self._parse_detail_html(job_id, resp.text)
            if parsed.get("blocked"):
                return self._crawl_detail_via_cloak_sync(job_id, detail_url, "Blocked by Aliyun WAF")

            return {"success": True, "detail": parsed["detail"]}

        except Exception as e:
            logger.exception("51job detail crawl failed")
            return {"success": False, "error": str(e)}

    def _ensure_cookies_sync(self) -> bool:
        if self._cookies_acquired_at and time.time() - self._cookies_acquired_at < 300:
            return True

        session = self._get_session()
        if session.cookies.get_dict():
            self._cookies_acquired_at = time.time()
            return True

        return self._refresh_cookies_for_detail_sync()

    def _crawl_detail_via_cloak_sync(self, job_id: str, detail_url: str, reason: str) -> dict[str, Any]:
        logger.info("51job detail falling back to CloakBrowser: %s", reason)
        self._start_browser()
        try:
            page = self._cloak_page
            if page is None:
                raise RuntimeError("CloakBrowser is not started")
            page.goto(detail_url, wait_until="domcontentloaded", timeout=45000)
            try:
                page.wait_for_load_state("domcontentloaded", timeout=10000)
            except Exception:
                logger.debug("51job detail page still navigating")
            page.wait_for_timeout(1000)

            context = self._cloak_context
            if context is not None:
                session = self._get_session()
                for cookie in context.cookies([detail_url, f"{BASE_URL}/"]):
                    kwargs = {"path": cookie.get("path") or "/"}
                    if cookie.get("domain"):
                        kwargs["domain"] = cookie["domain"]
                    session.cookies.set(cookie["name"], cookie["value"], **kwargs)

            parsed = self._parse_detail_html(job_id, page.content())
            if parsed.get("blocked"):
                return {"success": False, "error": "Blocked by Aliyun WAF"}
            return {"success": True, "detail": parsed["detail"]}
        finally:
            self._close_browser_sync()

    @staticmethod
    def _parse_detail_html(job_id: str, html: str) -> dict[str, Any]:
        import re

        from bs4 import BeautifulSoup

        soup = BeautifulSoup(html, "html.parser")
        if soup.find("meta", attrs={"name": "aliyun_waf_aa"}):
            return {"blocked": True}

        job_msg_div = soup.select_one("div.job_msg") or soup.select_one("div.bmsg.job_msg.inbox")
        description = job_msg_div.get_text(strip=True, separator="\n") if job_msg_div else ""
        description = re.sub(r"分享\s*微信\s*邮件.*$", "", description, flags=re.DOTALL).strip()

        address_div = soup.find("span", class_="label", string=re.compile(r"上班地址："))
        address = ""
        if address_div and address_div.parent:
            address = address_div.parent.get_text(strip=True).replace("上班地址：", "")

        return {
            "blocked": False,
            "detail": {
                "job_id": job_id,
                "description": description,
                "address": address,
            },
        }

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
