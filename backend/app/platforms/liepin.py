"""Liepin platform adapter for job search crawling."""

from __future__ import annotations

import asyncio
import json
import logging
from typing import Any
from urllib.parse import parse_qs, urlparse

import websockets
from bs4 import BeautifulSoup
from curl_cffi.requests import Session as CffiSession

from app.platforms.base import BasePlatformAdapter
from app.platforms.cdp_utils import close_target, open_temporary_tab

logger = logging.getLogger(__name__)

BASE_URL = "https://www.liepin.com"
DETAIL_PAGE_URL_TEMPLATE = "https://www.liepin.com/job/{job_id}.shtml"

# JavaScript expression to extract jobs from rendered Liepin search page DOM
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

        let remainder = text.replace(title, '').replace(locMatch ? locMatch[0] : '', '');
        remainder = remainder.replace(/^急聘/, '');

        const salaryMatch = remainder.match(/(\\d+[kK](?:·\\d+薪)?|薪资面议|\\d+-\\d+[kK])/);
        const salary = salaryMatch ? salaryMatch[1] : '';

        let afterSalary = remainder.replace(salary, '').trim();
        const expMatch = afterSalary.match(/(\\d+-\\d+年|\\d+年以上|应届生|实习生|经验不限|(?:\\d+年(?:以上)?))/);
        const experience = expMatch ? expMatch[1] : '';

        const eduMatch = afterSalary.match(/(统招本科|本科|硕士|大专|博士|学历不限)/);
        const education = eduMatch ? eduMatch[1] : '';

        const companyText = compInfo ? compInfo.textContent.trim() : '';
        // Extract company name: first part before known industry keywords
        const companyMatch = companyText.match(/^(.*?)(?:机械[/]设备|基金[/]证券[/]期货|互联网|软件|电子|通信|专业服务|整车制造|基金[/]证券|制造|科技|技术|网络|信息|智能|生物|医药|医疗|金融|投资|咨询|教育|文化|传媒|广告|贸易|物流|零售|餐饮|酒店|旅游|房地产|建筑|建材|能源|化工|环保|农业|渔业|林业|矿业|公共事业|政府|非营利机构|其他行业|$)/);
        const company = companyMatch ? companyMatch[1].trim() : companyText;

        jobs.push({
            job_id: jobId,
            title: title,
            company: company,
            salary: salary,
            location: location,
            experience: experience,
            education: education,
            url: href.split('?')[0] || DETAIL_PAGE_URL_TEMPLATE.replace('{job_id}', jobId)
        });
    });
    return JSON.stringify({count: jobs.length, jobs: jobs});
})()
"""


class LiepinAdapter(BasePlatformAdapter):
    """Adapter for Liepin job search crawling via CDP DOM extraction."""

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

        search_page_url = f"{BASE_URL}/zhaopin/?key={keyword}&dqs={city}&currentPage=0"
        ws_url, target_id = await open_temporary_tab(search_page_url)
        if not ws_url or not target_id:
            return {
                "success": False,
                "error": "请启动已开启远程调试端口的浏览器，以便自动打开猎聘搜索页",
            }

        try:
            # Wait for JavaScript to render job cards
            await asyncio.sleep(10)

            async with websockets.connect(ws_url, max_size=2**25) as ws:
                await ws.send(json.dumps({
                    "id": 1,
                    "method": "Runtime.evaluate",
                    "params": {"expression": _EXTRACT_JOBS_JS, "returnByValue": True},
                }))
                raw = await asyncio.wait_for(ws.recv(), timeout=20)

            payload = json.loads(raw)
            value = payload.get("result", {}).get("result", {}).get("value", "{}")
            result = json.loads(value)
            jobs = result.get("jobs", [])

            if not jobs:
                return {"success": False, "error": "猎聘页面未找到职位数据"}

            normalized = [self._normalize_job(j) for j in jobs]
            return {"success": True, "jobs": normalized, "count": len(normalized)}
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
            if response.status_code == 200 and not self._looks_challenged(text):
                detail = self._parse_detail_html(text)
                if detail["description"] or detail["address"]:
                    return {"success": True, "detail": detail}
        except Exception as exc:
            logger.debug("Liepin detail HTTP failed for %s: %s", job_id, exc)

        # Fallback to CDP
        return await self._crawl_detail_via_cdp(job_id)

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
