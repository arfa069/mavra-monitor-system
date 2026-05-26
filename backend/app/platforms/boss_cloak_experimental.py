"""Experimental Boss adapter backed by CloakBrowser.

This adapter intentionally does not replace ``BossZhipinAdapter``. It uses a
real CloakBrowser profile to refresh Boss cookies, then performs slow,
single-threaded API requests through ``curl_cffi``.
"""

from __future__ import annotations

import asyncio
import json
import logging
import random
import time
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse

from curl_cffi.requests import Session as CffiSession

from app.core.crawler_paths import build_profile_dir
from app.platforms.base import BasePlatformAdapter

logger = logging.getLogger(__name__)

BASE_URL = "https://www.zhipin.com"
SEARCH_API_PATH = "/wapi/zpgeek/search/joblist.json"
DETAIL_API_PATH = "/wapi/zpgeek/job/detail.json"
DEFAULT_CITY = "101280100"  # Guangzhou
DEFAULT_QUERY = "python"
LIST_PAGE_SIZE = 30
DEFAULT_MAX_JOBS = 200
DEFAULT_MAX_PAGES = 20
ANTI_BOT_CODES = {36, 37, 38}


def classify_boss_failure(payload: dict) -> str | None:
    code = payload.get("code")
    if code in ANTI_BOT_CODES:
        return "anti_bot"
    return None


class BossCloakExperimentalAdapter(BasePlatformAdapter):
    """Slow experimental Boss crawler using CloakBrowser profile cookies."""

    def __init__(
        self,
        *,
        profile_dir: str | Path | None = None,
        max_jobs: int = DEFAULT_MAX_JOBS,
        max_pages: int = DEFAULT_MAX_PAGES,
        headless: bool = True,
        list_delay_seconds: tuple[float, float] = (2.0, 5.0),
        detail_delay_seconds: tuple[float, float] = (2.0, 3.0),
        log_path: str | Path | None = None,
        log_enabled: bool = True,
        runtime_context=None,
    ):
        super().__init__()
        self.runtime_context = runtime_context
        self.profile_dir = Path(profile_dir) if profile_dir else build_profile_dir(
            "default",
        )
        from app.platforms.job_runtime_logging import JobRuntimeJsonlLogger
        self.runtime_logger = JobRuntimeJsonlLogger(
            platform="boss",
            context=runtime_context,
            log_path=log_path,
            enabled=log_enabled,
        )
        self._cookie_refresh_failures = 0

    def _profile_failure_category(self) -> str | None:
        if self._cookie_refresh_failures >= 2:
            return "cookie_refresh_failed"
        return None
        self.max_jobs = max_jobs
        self.max_pages = max_pages
        self.headless = headless
        self.list_delay_seconds = list_delay_seconds
        self.detail_delay_seconds = detail_delay_seconds
        self._session: CffiSession | None = None
        self._headers: dict[str, str] = {}
        self._search_page: str = ""
        self._cloak_context = None
        self._cloak_page = None
        self._log_enabled = log_enabled
        self._log_path = Path(log_path) if log_path else self._make_default_log_path()
        self._log_started_at = time.time()

    async def extract_price(self, page) -> dict[str, Any]:
        raise NotImplementedError

    async def extract_title(self, page) -> str:
        raise NotImplementedError

    def _get_session(self) -> CffiSession:
        if self._session is None:
            self._session = CffiSession()
        return self._session

    async def crawl(self, url: str) -> dict[str, Any]:
        """Crawl list results and details slowly in one serial pass."""
        return await asyncio.to_thread(self._crawl_sync, url)

    async def crawl_detail(self, security_id: str, lid: str = "") -> dict[str, Any]:
        """Fetch one detail record with the current Cloak/curl session."""
        return await asyncio.to_thread(self._crawl_detail_sync, security_id, lid)

    def _crawl_sync(self, url: str) -> dict[str, Any]:
        try:
            crawl_started = time.time()
            query, city = self._parse_search(url)
            self._search_page = self._build_search_page(query, city)
            self._log_event(
                "crawl_start",
                query=query,
                city=city,
                max_jobs=self.max_jobs,
                max_pages=self.max_pages,
                page_size=LIST_PAGE_SIZE,
                list_delay=self.list_delay_seconds,
                detail_delay=self.detail_delay_seconds,
                search_page=self._search_page,
            )
            self._start_browser()
            self._refresh_cookies("initial")

            jobs: list[dict[str, Any]] = []
            seen: set[str] = set()
            last_lid = ""

            for page_num in range(1, self.max_pages + 1):
                started = time.time()
                data = self._post_job_page(query, city, page_num)
                code = data.get("code")
                self._log_list_page(page_num, 1, data, time.time() - started)
                if code in ANTI_BOT_CODES:
                    logger.warning("Boss Cloak list code=%s, refreshing cookies", code)
                    self._refresh_cookies(f"code_{code}_page_{page_num}")
                    started = time.time()
                    data = self._post_job_page(query, city, page_num)
                    code = data.get("code")
                    self._log_list_page(page_num, 2, data, time.time() - started)

                if code != 0:
                    self._log_event(
                        "crawl_failed",
                        page=page_num,
                        code=code,
                        message=data.get("message"),
                        count=len(jobs),
                        duration_sec=round(time.time() - crawl_started, 2),
                    )
                    return {
                        "success": False,
                        "error": f"Boss list API code={code}: {data.get('message')}",
                        "jobs": jobs,
                        "count": len(jobs),
                    }

                zp_data = data.get("zpData") or {}
                raw_jobs = zp_data.get("jobList") or []
                last_lid = zp_data.get("lid") or last_lid
                page_jobs: list[dict[str, Any]] = []

                for raw_job in raw_jobs:
                    transformed = self._transform_job(raw_job, last_lid)
                    job_id = transformed.get("job_id")
                    if not job_id or job_id in seen:
                        continue
                    seen.add(job_id)
                    jobs.append(transformed)
                    page_jobs.append(transformed)
                    if len(jobs) >= self.max_jobs:
                        break

                self._log_event(
                    "jobs_added",
                    page=page_num,
                    added=len(page_jobs),
                    total=len(jobs),
                )
                self._crawl_details_sync(page_jobs)

                if len(jobs) >= self.max_jobs:
                    break
                if not zp_data.get("hasMore") or not raw_jobs:
                    break

                self._sleep(self.list_delay_seconds)

            self._log_event(
                "crawl_finish",
                success=True,
                count=len(jobs),
                details_success=sum(1 for job in jobs if job.get("description")),
                details_failed=sum(1 for job in jobs if job.get("detail_error")),
                duration_sec=round(time.time() - crawl_started, 2),
                log_path=str(self._log_path),
            )
            return {"success": True, "jobs": jobs, "count": len(jobs)}
        except Exception as exc:
            logger.exception("Boss Cloak experimental crawl failed")
            self._log_event(
                "crawl_exception",
                success=False,
                error=str(exc),
            )
            return {"success": False, "error": str(exc)}
        finally:
            self._close_browser_sync()

    def _crawl_details_sync(self, jobs: list[dict[str, Any]]) -> None:
        for index, job in enumerate(jobs, start=1):
            started = time.time()
            result = self._crawl_detail_sync(
                job.get("job_id", ""),
                job.get("lid", ""),
            )
            detail = result.get("detail") or {}
            if result.get("success"):
                job.update({
                    "description": detail.get("description", ""),
                    "address": detail.get("address", ""),
                    "company_stage": detail.get("company_stage", ""),
                    "company_scale": detail.get("company_scale", ""),
                    "company_industry": detail.get("company_industry", ""),
                })
            else:
                job["detail_error"] = result.get("error", "Detail fetch failed")

            self._log_event(
                "detail",
                index=index,
                job_id=(job.get("job_id") or "")[:12],
                title=job.get("title", ""),
                company=job.get("company", ""),
                success=bool(result.get("success")),
                error=result.get("error"),
                has_description=bool(detail.get("description")),
                has_address=bool(detail.get("address")),
                duration_sec=round(time.time() - started, 2),
            )
            if index < len(jobs):
                self._sleep(self.detail_delay_seconds)

    def _crawl_detail_sync(self, security_id: str, lid: str = "") -> dict[str, Any]:
        if not security_id:
            return {"success": False, "error": "Missing securityId"}
        if self._session is None:
            if not self._search_page:
                self._search_page = self._build_search_page(DEFAULT_QUERY, DEFAULT_CITY)
            self._start_browser()
            self._refresh_cookies("detail_initial")

        for attempt in range(2):
            result = self._get_detail_once(security_id, lid)
            if result.get("success"):
                return result
            error = result.get("error", "")
            if attempt == 0 and any(f"code={code}" in error for code in ANTI_BOT_CODES):
                self._refresh_cookies(f"detail_{security_id[:8]}")
                continue
            return result

        return {"success": False, "error": "Detail fetch failed"}

    def _get_detail_once(self, security_id: str, lid: str = "") -> dict[str, Any]:
        params = {"securityId": security_id, "_": str(int(time.time() * 1000))}
        if lid:
            params["lid"] = lid if ".search." in lid else f"{lid}.search.1"
        api_url = f"{BASE_URL}{DETAIL_API_PATH}?{urlencode(params)}"
        response = self._get_session().get(
            api_url,
            impersonate="chrome124",
            headers=self._headers,
        )
        if response.status_code != 200:
            return {"success": False, "error": f"HTTP {response.status_code}"}

        data = response.json()
        code = data.get("code")
        if code != 0:
            return {"success": False, "error": f"API code={code}"}

        zp_data = data.get("zpData") or {}
        job_info = zp_data.get("jobInfo") or {}
        brand_info = zp_data.get("brandComInfo") or {}
        return {
            "success": True,
            "detail": {
                "job_id": security_id,
                "title": job_info.get("jobName", ""),
                "salary": job_info.get("salaryDesc", ""),
                "location": job_info.get("locationName", ""),
                "address": job_info.get("address", ""),
                "experience": job_info.get("experienceName", ""),
                "education": job_info.get("degreeName", ""),
                "description": job_info.get("postDescription", ""),
                "company": brand_info.get("brandName", ""),
                "company_stage": brand_info.get("stageName", ""),
                "company_scale": brand_info.get("scaleName", ""),
                "company_industry": brand_info.get("industryName", ""),
            },
        }

    def _post_job_page(self, query: str, city: str, page_num: int) -> dict[str, Any]:
        body = {
            "page": str(page_num),
            "pageSize": str(LIST_PAGE_SIZE),
            "city": city,
            "expectInfo": "",
            "query": query,
            "multiSubway": "",
            "multiBusinessDistrict": "",
            "position": "",
            "jobType": "",
            "salary": "",
            "experience": "",
            "degree": "",
            "industry": "",
            "scale": "",
            "stage": "",
            "scene": "1",
            "encryptExpectId": "",
        }
        api_url = (
            f"{BASE_URL}{SEARCH_API_PATH}?"
            f"{urlencode({'_': str(int(time.time() * 1000))})}"
        )
        response = self._get_session().post(
            api_url,
            data=body,
            impersonate="chrome124",
            headers={
                **self._headers,
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )
        if response.status_code != 200:
            return {"code": -1, "message": f"HTTP {response.status_code}"}
        return response.json()

    def _start_browser(self) -> None:
        if self._cloak_context is not None:
            return
        from cloakbrowser import launch_persistent_context

        started = time.time()
        self._cloak_context = launch_persistent_context(
            str(self.profile_dir),
            headless=self.headless,
            locale="zh-CN",
            timezone="Asia/Shanghai",
            humanize=True,
            viewport={"width": 1440, "height": 1000},
        )
        self._cloak_page = self._cloak_context.new_page()
        self._log_event(
            "browser_started",
            profile_dir=str(self.profile_dir),
            headless=self.headless,
            duration_sec=round(time.time() - started, 2),
        )

    def _refresh_cookies(self, reason: str) -> None:
        logger.info("Refreshing Boss Cloak cookies: %s", reason)
        started = time.time()
        page = self._cloak_page
        context = self._cloak_context
        if page is None or context is None:
            raise RuntimeError("CloakBrowser is not started")

        if page.url == "about:blank":
            page.goto(self._search_page, wait_until="domcontentloaded", timeout=45000)
        else:
            page.reload(wait_until="domcontentloaded", timeout=45000)
        try:
            page.wait_for_load_state("domcontentloaded", timeout=10000)
        except Exception:
            logger.debug("Boss Cloak page still navigating after refresh")
        page.wait_for_timeout(1000)

        cookies = context.cookies([f"{BASE_URL}/", "https://zhipin.com/"])
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
            "X-Requested-With": "XMLHttpRequest",
        }
        self._log_event(
            "cookie_refresh",
            reason=reason,
            mode="reload",
            cookie_count=len(cookies),
            stoken_present=any(cookie.get("name") == "__zp_stoken__" for cookie in cookies),
            duration_sec=round(time.time() - started, 2),
        )

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
        raise last_error or RuntimeError("Failed to evaluate Cloak page")

    def _close_browser_sync(self) -> None:
        if self._cloak_context is not None:
            try:
                self._cloak_context.close()
                self._log_event("browser_closed")
            except Exception:
                logger.exception("Failed to close CloakBrowser context")
            self._cloak_context = None
            self._cloak_page = None

    def _sleep(self, delay_range: tuple[float, float]) -> None:
        seconds = random.uniform(*delay_range)
        self._log_event("sleep", sleep_sec=round(seconds, 2), delay_range=delay_range)
        time.sleep(seconds)

    def _log_list_page(
        self,
        page_num: int,
        attempt: int,
        data: dict[str, Any],
        duration: float,
    ) -> None:
        zp_data = data.get("zpData") or {}
        self._log_event(
            "list_page",
            page=page_num,
            attempt=attempt,
            code=data.get("code"),
            message=data.get("message"),
            job_count=len(zp_data.get("jobList") or []),
            has_more=zp_data.get("hasMore"),
            res_count=zp_data.get("resCount"),
            lid=zp_data.get("lid"),
            duration_sec=round(duration, 2),
        )

    def _log_event(self, event: str, **data: Any) -> None:
        if not self._log_enabled:
            return
        row = {
            "ts": datetime.now().isoformat(timespec="seconds"),
            "elapsed_sec": round(time.time() - self._log_started_at, 2),
            "event": event,
            **data,
        }
        try:
            self._log_path.parent.mkdir(parents=True, exist_ok=True)
            with self._log_path.open("a", encoding="utf-8") as file:
                file.write(json.dumps(row, ensure_ascii=False, default=str) + "\n")
        except Exception:
            logger.exception("Failed to write Boss Cloak adapter log")

    @staticmethod
    def _make_default_log_path() -> Path:
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return Path(__file__).resolve().parents[2] / "logs" / f"boss_cloak_adapter_{stamp}.jsonl"

    @staticmethod
    def _parse_search(url: str) -> tuple[str, str]:
        parsed = urlparse(url)
        params = parse_qs(parsed.query)
        query = (params.get("query") or [DEFAULT_QUERY])[0] or DEFAULT_QUERY
        city = (params.get("city") or [DEFAULT_CITY])[0] or DEFAULT_CITY
        return query, city

    @staticmethod
    def _build_search_page(query: str, city: str) -> str:
        return f"{BASE_URL}/web/geek/jobs?{urlencode({'query': query, 'city': city})}"

    @staticmethod
    def _transform_job(raw_job: dict[str, Any], lid: str) -> dict[str, Any]:
        security_id = raw_job.get("securityId") or ""
        encrypt_job_id = raw_job.get("encryptJobId") or ""
        return {
            "job_id": security_id,
            "encrypt_job_id": encrypt_job_id,
            "lid": raw_job.get("lid") or lid,
            "title": raw_job.get("jobName", ""),
            "company": raw_job.get("brandName", ""),
            "company_id": raw_job.get("encryptBrandId", ""),
            "salary": raw_job.get("salaryDesc", ""),
            "location": raw_job.get("cityName", "") or raw_job.get("areaDistrict", ""),
            "experience": raw_job.get("jobExperience", ""),
            "education": raw_job.get("jobDegree", ""),
            "url": (
                f"https://www.zhipin.com/job_detail/{encrypt_job_id}.html"
                if encrypt_job_id else ""
            ),
        }
