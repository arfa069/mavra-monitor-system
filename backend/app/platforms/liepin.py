"""Liepin platform adapter for job search crawling."""

from __future__ import annotations

import asyncio
import json
import logging
import time
import uuid
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse

import websockets
from bs4 import BeautifulSoup
from curl_cffi.requests import Session as CffiSession

from app.platforms.base import BasePlatformAdapter
from app.platforms.cdp_utils import (
    close_target,
    evaluate_json_fetch,
    open_temporary_tab,
)

logger = logging.getLogger(__name__)

SEARCH_DOMAIN = "www.liepin.com"
BASE_URL = f"https://{SEARCH_DOMAIN}"
SEARCH_PAGE_PATH = "/zhaopin/"
SEARCH_API_PATH = "/api/com.liepin.searchfront4c.pc-search-job"
DETAIL_PAGE_URL_TEMPLATE = "https://www.liepin.com/job/{job_id}.shtml"
MAX_PAGES = 3

_EXTRACT_JOBS_JS = """
(() => {
    const cards = document.querySelectorAll('.job-card-pc-container');
    const jobs = [];
    cards.forEach(card => {
        const jobInfo = card.querySelector('[data-nick="job-detail-job-info"]');
        const compInfo = card.querySelector('[data-nick="job-detail-company-info"]');
        if (!jobInfo) return;

        const href = jobInfo.href || '';
        const match = href.match(/\\/job\\/(\\d+)\\.shtml/);
        const jobId = match ? match[1] : '';
        if (!jobId) return;

        const text = jobInfo.textContent.trim();
        const titleMatch = text.match(/^(.*?)【/);
        const title = titleMatch ? titleMatch[1].trim() : text;

        const locMatch = text.match(/【(.*?)】/);
        const location = locMatch ? locMatch[1].trim() : '';

        let remainder = text.replace(title, '').replace(locMatch ? locMatch[0] : '');
        remainder = remainder.replace(/^急聘/, '');

        const salaryMatch = remainder.match(/(\\d+[kK](?:·\\d+薪)?|薪资面议|\\d+-\\d+[kK])/);
        const salary = salaryMatch ? salaryMatch[1] : '';

        const afterSalary = remainder.replace(salary, '').trim();
        const expMatch = afterSalary.match(/(\\d+-\\d+年|\\d+年以上|应届生|实习生|经验不限|(?:\\d+年(?:以上)?))/);
        const experience = expMatch ? expMatch[1] : '';

        const eduMatch = afterSalary.match(/(统招本科|本科|硕士|大专|博士|学历不限)/);
        const education = eduMatch ? eduMatch[1] : '';

        const companyText = compInfo ? compInfo.textContent.trim() : '';
        const companyMatch = companyText.match(/^(.*?)(?:机械[/]设备|基金[/]证券[/]期货|互联网|软件|电子|通信|专业服务|整车制造|基金[/]证券|制造|科技|技术|网络|信息|智能|生物|医药|医疗|金融|投资|咨询|教育|文化|传媒|广告|贸易|物流|零售|餐饮|酒店|旅游|房地产|建筑|建材|能源|化工|环保|农业|渔业|林业|矿业|公共事业|政府|非营利机构|其他行业|$)/);
        const company = companyMatch ? companyMatch[1].trim() : companyText;

        jobs.push({
            job_id: jobId,
            title,
            company,
            salary,
            location,
            experience,
            education,
            url: href.split('?')[0] || `https://www.liepin.com/job/${jobId}.shtml`
        });
    });
    return JSON.stringify({jobs});
})()
"""


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
                    logger.info("Liepin browser API fetch failed, falling back to DOM: %s", result["error"])
                    break
                data = result.get("json")
                if not isinstance(data, dict):
                    logger.info("Liepin browser API fetch returned non-JSON, falling back to DOM")
                    break
                jobs = self._transform_jobs(data)
                if not jobs:
                    break
                all_jobs.extend(jobs)
                if len(jobs) < 40:
                    break
            if not all_jobs:
                all_jobs = await self._extract_jobs_from_dom(ws_url)
            if not all_jobs:
                return {"success": False, "error": "No job data from Liepin search API"}
            return {"success": True, "jobs": all_jobs, "count": len(all_jobs)}
        finally:
            await close_target(target_id)

    @staticmethod
    def _normalize_job(job: dict[str, Any]) -> dict[str, Any]:
        return {
            "job_id": str(job.get("job_id", "")),
            "title": job.get("title", ""),
            "company": job.get("company", ""),
            "company_id": "",
            "salary": job.get("salary", ""),
            "location": job.get("location", ""),
            "experience": job.get("experience", ""),
            "education": job.get("education", ""),
            "url": job.get("url", ""),
            "description": "",
            "address": "",
        }

    async def _extract_jobs_from_dom(self, ws_url: str) -> list[dict[str, Any]]:
        for attempt in range(4):
            if attempt:
                await asyncio.sleep(5)

            async with websockets.connect(ws_url, max_size=2**25) as ws:
                await ws.send(json.dumps({
                    "id": 1,
                    "method": "Runtime.evaluate",
                    "params": {
                        "expression": _EXTRACT_JOBS_JS,
                        "returnByValue": True,
                    },
                }))
                raw = await asyncio.wait_for(ws.recv(), timeout=20)

            payload = json.loads(raw)
            value = payload.get("result", {}).get("result", {}).get("value", "{}")
            result = json.loads(value)
            jobs = [self._normalize_job(job) for job in result.get("jobs", [])]
            if jobs:
                return jobs
        return []

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

    async def crawl_detail(self, job_id: str) -> dict[str, Any]:
        detail_url = DETAIL_PAGE_URL_TEMPLATE.format(job_id=job_id)
        # Try HTTP first
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
                if self._looks_challenged(text):
                    logger.debug("Liepin detail HTTP returned challenge for %s", job_id)
        except Exception as exc:
            logger.debug("Liepin detail HTTP failed for %s: %s", job_id, exc)

        return {"success": False, "error": "Liepin detail HTTP response contained no detail content"}

    async def _crawl_detail_via_cdp(self, job_id: str) -> dict[str, Any]:
        detail_url = DETAIL_PAGE_URL_TEMPLATE.format(job_id=job_id)
        ws_url, target_id = await open_temporary_tab(detail_url)
        if not ws_url or not target_id:
            return {"success": False, "error": "请启动已开启远程调试端口的浏览器，以便自动打开猎聘详情页"}

        try:
            await asyncio.sleep(5)

            extract_js = """
            (() => {
                const desc = document.querySelector('.job-intro-container, .job-description, [class*="job-intro"], [class*="description"]');
                let addr = '';
                const labels = document.querySelectorAll('.label-box, .label');
                labels.forEach(el => {
                    if (el.textContent.includes('职位地址') || el.textContent.includes('工作地址')) {
                        addr = el.textContent.replace(/职位地址[：:]/, '').replace(/工作地址[：:]/, '').trim();
                    }
                });
                return JSON.stringify({
                    description: desc ? desc.innerText.trim() : '',
                    address: addr
                });
            })()
            """

            async with websockets.connect(ws_url, max_size=2**25) as ws:
                await ws.send(json.dumps({
                    "id": 1,
                    "method": "Runtime.evaluate",
                    "params": {"expression": extract_js, "returnByValue": True},
                }))
                raw = await asyncio.wait_for(ws.recv(), timeout=20)

            payload = json.loads(raw)
            value = payload.get("result", {}).get("result", {}).get("value", "{}")
            detail = json.loads(value)

            if not detail.get("description") and not detail.get("address"):
                return {"success": False, "error": "No Liepin detail content found"}
            return {"success": True, "detail": detail}
        finally:
            await close_target(target_id)

    @staticmethod
    def _looks_challenged(text: str) -> bool:
        lowered = text.lower()
        return any(
            marker in lowered
            for marker in ("captcha", "verify", "安全验证", "登录", "passport", "antibot")
        )

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
