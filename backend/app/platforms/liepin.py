"""Liepin platform adapter for job search crawling."""

from __future__ import annotations

import asyncio
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
        self._profile_cookies_loaded = False
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
            self._ensure_profile_cookies(self._session)
        return self._session

    def _ensure_profile_cookies(self, session: CffiSession) -> None:
        if self._profile_cookies_loaded:
            return
        self._profile_cookies_loaded = True
        if self.profile_dir is None:
            return
        try:
            loaded_count = self._load_profile_cookies(session)
        except Exception as exc:
            logger.debug("Liepin profile cookie load skipped: %s", exc)
            return
        if loaded_count:
            logger.info("Loaded Liepin profile cookies: count=%s", loaded_count)

    def _load_profile_cookies(self, session: CffiSession) -> int:
        if self.profile_dir is None:
            return 0
        local_state_path = self.profile_dir / "Local State"
        cookie_db_path = self.profile_dir / "Default" / "Network" / "Cookies"
        key = self._load_chromium_cookie_key(local_state_path)
        if not key:
            return 0
        loaded_count = 0
        for row in self._read_chromium_cookie_rows(cookie_db_path):
            value = self._decrypt_chromium_cookie_value(row["encrypted_value"], key)
            if not value:
                continue
            session.cookies.set(
                row["name"],
                value,
                domain=row["host_key"],
                path=row["path"] or "/",
            )
            loaded_count += 1
        return loaded_count

    @staticmethod
    def _read_chromium_cookie_rows(cookie_db_path: Path) -> list[dict[str, Any]]:
        if not cookie_db_path.exists():
            return []
        import sqlite3

        db_uri = f"file:{cookie_db_path.resolve().as_posix()}?mode=ro"
        with sqlite3.connect(db_uri, uri=True) as conn:
            rows = conn.execute(
                """
                SELECT host_key, path, name, encrypted_value
                FROM cookies
                WHERE host_key LIKE '%liepin%' OR host_key LIKE '%lietou%'
                """,
            ).fetchall()
        return [
            {
                "host_key": str(host_key),
                "path": str(path or "/"),
                "name": str(name),
                "encrypted_value": bytes(encrypted_value or b""),
            }
            for host_key, path, name, encrypted_value in rows
            if name and encrypted_value
        ]

    @staticmethod
    def _load_chromium_cookie_key(local_state_path: Path) -> bytes | None:
        if not local_state_path.exists():
            return None
        import base64

        local_state = json.loads(local_state_path.read_text(encoding="utf-8"))
        encrypted_key = local_state.get("os_crypt", {}).get("encrypted_key")
        if not encrypted_key:
            return None
        encrypted_key_bytes = base64.b64decode(encrypted_key)
        if encrypted_key_bytes.startswith(b"DPAPI"):
            encrypted_key_bytes = encrypted_key_bytes[5:]
        return LiepinAdapter._windows_dpapi_unprotect(encrypted_key_bytes)

    @staticmethod
    def _decrypt_chromium_cookie_value(encrypted_value: bytes, key: bytes) -> str:
        if not encrypted_value:
            return ""
        if encrypted_value.startswith((b"v10", b"v11", b"v20")):
            from cryptography.hazmat.primitives.ciphers.aead import AESGCM

            nonce = encrypted_value[3:15]
            ciphertext = encrypted_value[15:]
            plaintext = AESGCM(key).decrypt(nonce, ciphertext, None)
            return LiepinAdapter._decode_chromium_cookie_plaintext(plaintext)
        plaintext = LiepinAdapter._windows_dpapi_unprotect(encrypted_value)
        return LiepinAdapter._decode_chromium_cookie_plaintext(plaintext)

    @staticmethod
    def _decode_chromium_cookie_plaintext(plaintext: bytes) -> str:
        candidates = [plaintext]
        if len(plaintext) > 32:
            candidates.append(plaintext[32:])
        for candidate in candidates:
            try:
                return candidate.decode("utf-8")
            except UnicodeDecodeError:
                continue
        return ""

    @staticmethod
    def _windows_dpapi_unprotect(data: bytes) -> bytes:
        import ctypes
        from ctypes import wintypes

        if not hasattr(ctypes, "windll"):
            raise RuntimeError("Windows DPAPI is unavailable")

        class DataBlob(ctypes.Structure):
            _fields_ = [
                ("cbData", wintypes.DWORD),
                ("pbData", ctypes.POINTER(ctypes.c_char)),
            ]

        input_buffer = ctypes.create_string_buffer(data)
        input_blob = DataBlob(len(data), ctypes.cast(input_buffer, ctypes.POINTER(ctypes.c_char)))
        output_blob = DataBlob()
        if not ctypes.windll.crypt32.CryptUnprotectData(
            ctypes.byref(input_blob),
            None,
            None,
            None,
            None,
            0,
            ctypes.byref(output_blob),
        ):
            raise ctypes.WinError()
        try:
            return ctypes.string_at(output_blob.pbData, output_blob.cbData)
        finally:
            ctypes.windll.kernel32.LocalFree(output_blob.pbData)

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
        http_result = await asyncio.to_thread(self._crawl_search_http, keyword, city)
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
        failures: list[str] = []
        detail_urls = self._detail_urls(job_id)
        redirect_shell_count = 0
        for detail_url in detail_urls:
            try:
                response = self._get_session().get(
                    detail_url,
                    impersonate="chrome124",
                    headers={"Referer": f"{BASE_URL}/"},
                    timeout=20,
                )
                text = response.text or ""
                if response.status_code == 200:
                    if self._is_redirect_shell(text):
                        redirect_shell_count += 1
                        failures.append(f"{detail_url} status=200 category=detail_unavailable redirect_shell")
                        continue
                    detail = self._parse_detail_html(text)
                    if detail["description"] or detail["address"]:
                        if not detail["address"]:
                            detail["address"] = "无地址"
                        return {"success": True, "detail": detail}
                    category = classify_liepin_failure(status_code=response.status_code, text=text)
                    if category == "challenge":
                        self.runtime_logger.log("detail_challenge", status="blocked", failure_category=category, job_id=job_id)
                    failures.append(f"{detail_url} status=200 category={category} no_detail_content")
                else:
                    category = classify_liepin_failure(status_code=response.status_code, text=text)
                    if category:
                        failures.append(f"{detail_url} status={response.status_code} category={category}")
                        return {"success": False, "error": f"Liepin detail HTTP {response.status_code}: {category}", "failure_category": category}
                    failures.append(f"{detail_url} status={response.status_code} category=unknown")
            except Exception as exc:
                category = classify_liepin_failure(status_code=0, text=str(exc))
                failures.append(f"{detail_url} exception={type(exc).__name__} category={category}")
                logger.debug("Liepin detail HTTP failed for %s via %s: %s", job_id, detail_url, exc)

        failure_category = "detail_error"
        if redirect_shell_count == len(detail_urls):
            error = "Liepin detail URLs returned redirect shell with no detail content"
            failure_category = "detail_unavailable"
        else:
            error = "Liepin detail HTTP response contained no detail content"
        if failures:
            error = f"{error}; attempts: {'; '.join(failures)}"
        self.runtime_logger.log(
            "detail_failed",
            status="failed",
            message=error,
            failure_category=failure_category,
            job_id=job_id,
        )
        return {"success": False, "error": error, "failure_category": failure_category}

    @staticmethod
    def _detail_urls(job_id: str) -> list[str]:
        return [
            DETAIL_PAGE_URL_TEMPLATE.format(job_id=job_id),
            f"{BASE_URL}/a/{job_id}.shtml",
        ]

    @staticmethod
    def _is_redirect_shell(html: str) -> bool:
        return all(marker in html for marker in ("window.$CONFIG", "pcUrl", "wow.liepin.com"))

    @staticmethod
    def _parse_detail_html(html: str) -> dict[str, str]:
        soup = BeautifulSoup(html, "html.parser")
        json_ld_detail = LiepinAdapter._parse_jobposting_json_ld(soup)
        if json_ld_detail["description"] or json_ld_detail["address"]:
            return json_ld_detail
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

    @staticmethod
    def _parse_jobposting_json_ld(soup: BeautifulSoup) -> dict[str, str]:
        for script in soup.select('script[type="application/ld+json"]'):
            try:
                payload = json.loads(script.string or script.get_text("", strip=True) or "{}", strict=False)
            except json.JSONDecodeError:
                continue
            jobposting = LiepinAdapter._find_jobposting_payload(payload)
            if not isinstance(jobposting, dict):
                continue
            description = str(jobposting.get("description") or "").strip()
            address = LiepinAdapter._address_from_jobposting(jobposting)
            if description or address:
                return {"description": description, "address": address}
        return {"description": "", "address": ""}

    @staticmethod
    def _find_jobposting_payload(payload: Any) -> dict[str, Any] | None:
        if isinstance(payload, dict):
            payload_type = payload.get("@type")
            if payload_type == "JobPosting" or (isinstance(payload_type, list) and "JobPosting" in payload_type):
                return payload
            graph = payload.get("@graph")
            if isinstance(graph, list):
                for item in graph:
                    found = LiepinAdapter._find_jobposting_payload(item)
                    if found is not None:
                        return found
        elif isinstance(payload, list):
            for item in payload:
                found = LiepinAdapter._find_jobposting_payload(item)
                if found is not None:
                    return found
        return None

    @staticmethod
    def _address_from_jobposting(jobposting: dict[str, Any]) -> str:
        location = jobposting.get("jobLocation")
        if isinstance(location, list):
            location = next((item for item in location if isinstance(item, dict)), None)
        if not isinstance(location, dict):
            return ""
        address = location.get("address")
        if isinstance(address, str):
            return address.strip()
        if not isinstance(address, dict):
            return ""
        for key in ("streetAddress", "addressLocality", "addressRegion"):
            value = address.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
        return ""
