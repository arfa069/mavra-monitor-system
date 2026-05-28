"""Liepin platform adapter for job search crawling."""

from __future__ import annotations

import json
import logging
import re
import uuid
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse

from bs4 import BeautifulSoup
from curl_cffi.requests import Session as CffiSession

from app.platforms.base import BasePlatformAdapter

logger = logging.getLogger(__name__)

SEARCH_DOMAIN = "www.liepin.com"
API_DOMAIN = "api-c.liepin.com"
BASE_URL = f"https://{SEARCH_DOMAIN}"
API_BASE_URL = f"https://{API_DOMAIN}"
SEARCH_PAGE_PATH = "/zhaopin/"
SEARCH_API_PATH = "/api/com.liepin.searchfront4c.pc-search-job"
DETAIL_PAGE_URL_TEMPLATE = "https://www.liepin.com/job/{job_id}.shtml"
MAX_PAGES = 3


def classify_liepin_failure(*, status_code: int, text: str) -> str:
    lowered = (text or "").lower()
    if "xsrf" in lowered or "csrf" in lowered:
        return "xsrf"
    if status_code in {401, 403}:
        return "challenge"
    if any(marker in lowered for marker in ("captcha", "verify", "安全验证", "登录", "passport", "antibot")):
        return "challenge"
    if status_code >= 500:
        return "http_error"
    return "parse_error"


class LiepinAdapter(BasePlatformAdapter):
    """Adapter for Liepin job search crawling."""

    def __init__(
        self,
        *,
        profile_dir: str | Path | None = None,
        runtime_context=None,
        log_path=None,
        log_enabled=True,
    ):
        super().__init__()
        self.runtime_context = runtime_context
        self.profile_dir = Path(profile_dir) if profile_dir is not None else None
        self._session: CffiSession | None = None
        from app.platforms.job_runtime_logging import JobRuntimeJsonlLogger
        self.runtime_logger = JobRuntimeJsonlLogger(
            platform="liepin",
            context=runtime_context,
            log_path=log_path,
            enabled=log_enabled,
        )

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

        self.runtime_logger.log("crawl_start", status="running", message="Liepin HTTP crawl started")
        http_result = self._crawl_search_http(keyword, city)
        if http_result.get("success"):
            self.runtime_logger.log("crawl_finish", status="success", count=http_result.get("count", 0), message="Liepin HTTP crawl finished")
            return http_result

        failure_category = http_result.get("failure_category", "unknown")
        self.runtime_logger.log("crawl_failed", status="failed", failure_category=failure_category, message=http_result.get("error"))
        return http_result

    def _crawl_search_http(self, keyword: str, city: str) -> dict[str, Any]:
        try:
            session = self._get_session()
            search_page_url = self._build_search_page_url(keyword, city)
            session.get(
                search_page_url,
                impersonate="chrome124",
                headers=self._search_page_headers(),
                timeout=20,
            )
            response = session.post(
                self._build_search_api_url(keyword, city, 0),
                impersonate="chrome124",
                headers=self._headers(keyword, city, search_page_url),
                json=self._search_payload(keyword, city, 0),
                timeout=20,
            )
            data = self._parse_json_response(response)
            jobs = self._transform_jobs(data)
            if not jobs:
                return {"success": False, "error": "Liepin HTTP response contained no jobs", "failure_category": "empty_result"}
            self.runtime_logger.log("list_page", status="success", count=len(jobs), message="Liepin list page parsed")
            return {"success": True, "jobs": jobs, "count": len(jobs)}
        except Exception as exc:
            category = classify_liepin_failure(status_code=getattr(exc, "status_code", 0), text=str(exc))
            return {"success": False, "error": str(exc), "failure_category": category}

    def _build_search_api_url(self, _keyword: str, _city: str, _page: int) -> str:
        return f"{API_BASE_URL}{SEARCH_API_PATH}"

    def _build_search_page_url(self, keyword: str, city: str) -> str:
        params = {"key": keyword, "dqs": city, "currentPage": "0"}
        return f"{BASE_URL}{SEARCH_PAGE_PATH}?{urlencode(params)}"

    @staticmethod
    def _search_page_headers() -> dict[str, str]:
        return {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
        }

    def _headers(self, keyword: str, city: str, search_page_url: str | None = None) -> dict[str, str]:
        session = self._get_session()
        xsrf_token = session.cookies.get("XSRF-TOKEN") if hasattr(session, "cookies") else None
        headers = {
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
            "Content-Type": "application/json;charset=UTF-8",
            "Origin": BASE_URL,
            "Referer": f"{BASE_URL}/",
            "X-Requested-With": "XMLHttpRequest",
            "X-Client-Type": "web",
            "X-Fscp-Version": "1.1",
            "X-Fscp-Std-Info": json.dumps({"client_id": "40108"}, separators=(",", ":")),
            "X-Fscp-Bi-Stat": json.dumps(
                {"location": search_page_url or self._build_search_page_url(keyword, city)},
                ensure_ascii=False,
                separators=(",", ":"),
            ),
            "X-Fscp-Trace-Id": uuid.uuid4().hex,
        }
        if xsrf_token:
            headers["X-XSRF-TOKEN"] = xsrf_token
        return headers

    @staticmethod
    def _search_payload(keyword: str, city: str, page: int) -> dict[str, Any]:
        return {
            "data": {
                "mainSearchPcConditionForm": {
                    "city": city,
                    "dq": city,
                    "pubTime": "",
                    "currentPage": str(page),
                    "pageSize": 40,
                    "key": keyword,
                    "suggestTag": "",
                    "workYearCode": "",
                    "compId": "",
                    "compName": "",
                    "compTag": "",
                    "industry": "",
                    "salaryCode": "",
                    "jobKind": "",
                    "compScale": "",
                    "compKind": "",
                    "compStage": "",
                    "eduLevel": "",
                    "salaryLow": "",
                    "salaryHigh": "",
                },
                "passThroughForm": {
                    "scene": "init",
                    "skId": "",
                    "fkId": "",
                    "ckId": uuid.uuid4().hex,
                    "suggest": None,
                },
            }
        }

    def _parse_json_response(self, response) -> dict[str, Any]:
        content_type = response.headers.get("content-type", "")
        text = response.text or ""
        if response.status_code != 200:
            category = classify_liepin_failure(status_code=response.status_code, text=text)
            raise ValueError(f"HTTP {response.status_code}: {category}")
        if "html" in content_type.lower() or text.lstrip().lower().startswith(("<html", "<!doctype html")):
            category = classify_liepin_failure(status_code=response.status_code, text=text)
            raise ValueError(f"Liepin returned HTML instead of JSON: {category}")
        category = classify_liepin_failure(status_code=response.status_code, text=text)
        if category == "challenge":
            raise ValueError("Liepin returned a challenge or login response")
        return response.json()

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
            link = job.get("link") or job.get("url") or ""
            job_id = cls._job_id_from_link(link) or str(job.get("jobId") or job.get("id") or job.get("jobIdEnc") or "")
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
                "url": link or DETAIL_PAGE_URL_TEMPLATE.format(job_id=job_id),
                "description": job.get("description") or job.get("jobDesc") or "",
                "address": job.get("address") or "",
            })
        return jobs

    @staticmethod
    def _job_id_from_link(link: str) -> str:
        match = re.search(r"/job/(\d+)\.shtml", link)
        return match.group(1) if match else ""

    async def crawl_detail(self, job_id: str) -> dict[str, Any]:
        for detail_url in self._detail_urls(job_id):
            try:
                response = self._get_session().get(
                    detail_url,
                    impersonate="chrome124",
                    headers={"Referer": f"{BASE_URL}/"},
                    timeout=20,
                )
                text = response.text or ""
                if response.status_code == 200:
                    detail = self._parse_detail_html(text)
                    if detail["description"] or detail["address"]:
                        if not detail["address"]:
                            detail["address"] = "无地址"
                        return {"success": True, "detail": detail}
                    category = classify_liepin_failure(status_code=response.status_code, text=text)
                    if category == "challenge":
                        self.runtime_logger.log("detail_challenge", status="blocked", failure_category=category, job_id=job_id)
                else:
                    category = classify_liepin_failure(status_code=response.status_code, text=text)
                    if category:
                        return {"success": False, "error": f"Liepin detail HTTP {response.status_code}: {category}", "failure_category": category}
            except Exception as exc:
                category = classify_liepin_failure(status_code=0, text=str(exc))
                logger.debug("Liepin detail HTTP failed for %s via %s: %s", job_id, detail_url, exc)

        return {"success": False, "error": "Liepin detail HTTP response contained no detail content", "failure_category": "detail_error"}

    @staticmethod
    def _detail_urls(job_id: str) -> list[str]:
        return [
            DETAIL_PAGE_URL_TEMPLATE.format(job_id=job_id),
            f"{BASE_URL}/a/{job_id}.shtml",
        ]

    @staticmethod
    def _parse_detail_html(html: str) -> dict[str, str]:
        soup = BeautifulSoup(html, "html.parser")
        description_node = (
            soup.select_one(".job-intro-container")
            or soup.select_one(".job-description")
            or soup.select_one("[class*='job-intro']")
            or soup.select_one("[class*='description']")
        )
        address = ""
        for label in soup.select(".label-box, .label"):
            text = label.get_text(" ", strip=True)
            if "职位地址" in text or "工作地址" in text:
                address = text.replace("职位地址", "").replace("工作地址", "").replace(":", "").replace("：", "").strip()
                break
        return {
            "description": description_node.get_text("\n", strip=True) if description_node else "",
            "address": address,
        }
