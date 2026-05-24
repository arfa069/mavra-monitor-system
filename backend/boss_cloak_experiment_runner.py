"""Run Boss Cloak experimental crawls with local JSONL logging.

This script is intentionally separate from the production crawl pipeline. It
does not write to the database; it logs every list/detail/refresh step so the
anti-bot behavior and timing can be inspected after a real run.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import random
import time
from datetime import datetime
from pathlib import Path
from typing import Any

import app.platforms.boss_cloak_experimental as boss_cloak
from app.platforms.boss_cloak_experimental import (
    ANTI_BOT_CODES,
    BASE_URL,
    BossCloakExperimentalAdapter,
)


class JsonlLogger:
    def __init__(self, path: Path):
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.started = time.time()

    def write(self, event: str, **data: Any) -> None:
        row = {
            "ts": datetime.now().isoformat(timespec="seconds"),
            "elapsed_sec": round(time.time() - self.started, 2),
            "event": event,
            **data,
        }
        with self.path.open("a", encoding="utf-8") as file:
            file.write(json.dumps(row, ensure_ascii=False) + "\n")
        print(json.dumps(row, ensure_ascii=False), flush=True)


def parse_delay(value: str) -> tuple[float, float]:
    parts = value.split("-")
    if len(parts) != 2:
        raise argparse.ArgumentTypeError("delay must look like 5-7")
    low, high = float(parts[0]), float(parts[1])
    if low < 0 or high < low:
        raise argparse.ArgumentTypeError("delay range is invalid")
    return low, high


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--query", default="python")
    parser.add_argument("--city", default="101280100")
    parser.add_argument("--max-jobs", type=int, default=200)
    parser.add_argument("--max-pages", type=int, default=20)
    parser.add_argument("--page-size", type=int, default=15)
    parser.add_argument("--list-delay", type=parse_delay, default=(5.0, 7.0))
    parser.add_argument("--detail-delay", type=parse_delay, default=(2.0, 5.0))
    parser.add_argument("--headless", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--interleaved", action="store_true")
    parser.add_argument(
        "--refresh-mode",
        choices=("full", "light"),
        default="full",
        help="full is stable; light is experimental and may not clear detail anti-bot codes.",
    )
    parser.add_argument(
        "--log-path",
        type=Path,
        default=None,
        help="Defaults to backend/logs/boss_cloak_experiment_<timestamp>.jsonl",
    )
    return parser


def make_log_path() -> Path:
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return Path("logs") / f"boss_cloak_experiment_{stamp}.jsonl"


def summarize_job(raw_job: dict[str, Any], lid: str) -> dict[str, Any]:
    return {
        "job_id": raw_job.get("securityId"),
        "encrypt_job_id": raw_job.get("encryptJobId"),
        "lid": raw_job.get("lid") or lid,
        "title": raw_job.get("jobName", ""),
        "company": raw_job.get("brandName", ""),
        "salary": raw_job.get("salaryDesc", ""),
        "location": raw_job.get("cityName", "") or raw_job.get("areaDistrict", ""),
    }


class ExperimentRunner:
    def __init__(self, args: argparse.Namespace, logger: JsonlLogger):
        boss_cloak.LIST_PAGE_SIZE = args.page_size
        self.args = args
        self.log = logger
        self.adapter = BossCloakExperimentalAdapter(
            max_jobs=args.max_jobs,
            max_pages=args.max_pages,
            headless=args.headless,
            list_delay_seconds=args.list_delay,
            detail_delay_seconds=args.detail_delay,
        )
        self.jobs: list[dict[str, Any]] = []
        self.seen: set[str] = set()
        self.full_refresh = self.adapter._refresh_cookies

    def refresh(self, reason: str) -> None:
        if self.args.refresh_mode == "light" and reason != "initial":
            self.light_refresh(reason)
            return

        started = time.time()
        self.full_refresh(reason)
        self.log.write(
            "cookie_refresh",
            reason=reason,
            mode="full",
            duration_sec=round(time.time() - started, 2),
        )

    def light_refresh(self, reason: str) -> None:
        started = time.time()
        try:
            page = self.adapter._cloak_page
            context = self.adapter._cloak_context
            if page is None or context is None:
                raise RuntimeError("CloakBrowser is not started")

            page.evaluate(
                """async () => {
                    await fetch('/wapi/zpgeek/common/data/header.json?_=' + Date.now(), {
                        method: 'GET',
                        credentials: 'include',
                        headers: {
                            'accept': 'application/json, text/plain, */*',
                            'x-requested-with': 'XMLHttpRequest'
                        }
                    });
                }"""
            )
            page.wait_for_timeout(1200)
            cookies = context.cookies([f"{BASE_URL}/", "https://zhipin.com/"])
            session = self.adapter._get_session()
            for cookie in cookies:
                kwargs = {"path": cookie.get("path") or "/"}
                if cookie.get("domain"):
                    kwargs["domain"] = cookie["domain"]
                session.cookies.set(cookie["name"], cookie["value"], **kwargs)
            self.log.write(
                "cookie_refresh",
                reason=reason,
                mode="light",
                duration_sec=round(time.time() - started, 2),
            )
        except Exception as exc:
            self.log.write(
                "cookie_refresh_failed",
                reason=reason,
                mode="light",
                error=repr(exc),
                duration_sec=round(time.time() - started, 2),
            )
            started = time.time()
            self.full_refresh(f"{reason}_fallback")
            self.log.write(
                "cookie_refresh",
                reason=reason,
                mode="full_fallback",
                duration_sec=round(time.time() - started, 2),
            )

    def run(self) -> dict[str, Any]:
        self.adapter._search_page = self.adapter._build_search_page(
            self.args.query,
            self.args.city,
        )
        self.adapter._start_browser()
        self.refresh("initial")
        self.adapter._refresh_cookies = self.refresh
        try:
            if self.args.interleaved:
                self.run_interleaved()
            else:
                self.run_two_phase()
        finally:
            self.adapter._close_browser_sync()
        return self.summary()

    def run_two_phase(self) -> None:
        for page_num in range(1, self.args.max_pages + 1):
            raw_jobs, has_more = self.fetch_list_page(page_num)
            self.add_jobs(raw_jobs)
            if len(self.jobs) >= self.args.max_jobs or not has_more or not raw_jobs:
                break
            self.sleep("list_delay", self.args.list_delay)

        for job in self.jobs:
            self.fetch_detail(job)
            if job is not self.jobs[-1]:
                self.sleep("detail_delay", self.args.detail_delay)

    def run_interleaved(self) -> None:
        for page_num in range(1, self.args.max_pages + 1):
            raw_jobs, has_more = self.fetch_list_page(page_num)
            page_jobs = self.add_jobs(raw_jobs)
            for job in page_jobs:
                self.fetch_detail(job)
                if len(self.jobs) < self.args.max_jobs:
                    self.sleep("detail_delay", self.args.detail_delay)
            if len(self.jobs) >= self.args.max_jobs or not has_more or not raw_jobs:
                break
            self.sleep("list_delay", self.args.list_delay)

    def fetch_list_page(self, page_num: int) -> tuple[list[dict[str, Any]], bool]:
        data = self.post_list_page(page_num, attempt=1)
        if data.get("code") in ANTI_BOT_CODES:
            self.refresh(f"code_{data.get('code')}_page_{page_num}")
            data = self.post_list_page(page_num, attempt=2)
        if data.get("code") in ANTI_BOT_CODES and self.args.refresh_mode == "light":
            started = time.time()
            self.full_refresh(f"code_{data.get('code')}_page_{page_num}_full")
            self.log.write(
                "cookie_refresh",
                reason=f"code_{data.get('code')}_page_{page_num}",
                mode="full_after_light_failed",
                duration_sec=round(time.time() - started, 2),
            )
            data = self.post_list_page(page_num, attempt=3)

        zp_data = data.get("zpData") or {}
        return zp_data.get("jobList") or [], bool(zp_data.get("hasMore"))

    def post_list_page(self, page_num: int, attempt: int) -> dict[str, Any]:
        started = time.time()
        data = self.adapter._post_job_page(self.args.query, self.args.city, page_num)
        zp_data = data.get("zpData") or {}
        self.log.write(
            "list_page",
            page=page_num,
            attempt=attempt,
            code=data.get("code"),
            message=data.get("message"),
            job_count=len(zp_data.get("jobList") or []),
            has_more=zp_data.get("hasMore"),
            res_count=zp_data.get("resCount"),
            lid=zp_data.get("lid"),
            duration_sec=round(time.time() - started, 2),
        )
        return data

    def add_jobs(self, raw_jobs: list[dict[str, Any]]) -> list[dict[str, Any]]:
        added: list[dict[str, Any]] = []
        lid = ""
        if raw_jobs:
            lid = raw_jobs[0].get("lid") or ""
        for raw_job in raw_jobs:
            if len(self.jobs) >= self.args.max_jobs:
                break
            job = self.adapter._transform_job(raw_job, raw_job.get("lid") or lid)
            job_id = job.get("job_id")
            if not job_id or job_id in self.seen:
                continue
            self.seen.add(job_id)
            self.jobs.append(job)
            added.append(job)
        self.log.write("jobs_added", added=len(added), total=len(self.jobs))
        return added

    def fetch_detail(self, job: dict[str, Any]) -> None:
        started = time.time()
        result = self.adapter._crawl_detail_sync(job.get("job_id", ""), job.get("lid", ""))
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

        self.log.write(
            "detail",
            index=sum(1 for item in self.jobs if item.get("description") or item.get("detail_error")),
            job_id=(job.get("job_id") or "")[:10],
            title=job.get("title"),
            company=job.get("company"),
            success=bool(result.get("success")),
            error=result.get("error"),
            has_description=bool(detail.get("description")),
            has_address=bool(detail.get("address")),
            duration_sec=round(time.time() - started, 2),
        )

    def sleep(self, event: str, delay_range: tuple[float, float]) -> None:
        seconds = random.uniform(*delay_range)
        self.log.write(event, sleep_sec=round(seconds, 2))
        time.sleep(seconds)

    def summary(self) -> dict[str, Any]:
        return {
            "job_count": len(self.jobs),
            "details_success": sum(1 for job in self.jobs if job.get("description")),
            "details_failed": sum(1 for job in self.jobs if job.get("detail_error")),
            "with_address": sum(1 for job in self.jobs if job.get("address")),
            "sample_jobs": [
                summarize_job(
                    {
                        "securityId": job.get("job_id"),
                        "encryptJobId": job.get("encrypt_job_id"),
                        "jobName": job.get("title"),
                        "brandName": job.get("company"),
                        "salaryDesc": job.get("salary"),
                        "cityName": job.get("location"),
                    },
                    job.get("lid", ""),
                )
                for job in self.jobs[:10]
            ],
        }


async def main() -> None:
    args = build_parser().parse_args()
    log_path = args.log_path or make_log_path()
    logger = JsonlLogger(log_path)
    logger.write(
        "start",
        query=args.query,
        city=args.city,
        max_jobs=args.max_jobs,
        max_pages=args.max_pages,
        page_size=args.page_size,
        list_delay=args.list_delay,
        detail_delay=args.detail_delay,
        interleaved=args.interleaved,
        refresh_mode=args.refresh_mode,
        log_path=str(log_path),
    )
    runner = ExperimentRunner(args, logger)
    started = time.time()
    summary = await asyncio.to_thread(runner.run)
    logger.write(
        "finish",
        duration_sec=round(time.time() - started, 2),
        **summary,
    )
    print(f"\nLog written to: {log_path.resolve()}")


if __name__ == "__main__":
    asyncio.run(main())
