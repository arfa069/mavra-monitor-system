"""Manual Firecrawl JD profile experiment.

Run from backend:
  uv run --extra dev python ../scripts/firecrawl_jd_profile_experiment.py start-login
  uv run --extra dev python ../scripts/firecrawl_jd_profile_experiment.py finish-login --session-id <id>
  uv run --extra dev python ../scripts/firecrawl_jd_profile_experiment.py scrape --product-url https://item.jd.com/100012043978.html
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import os
from pathlib import Path
from typing import Any

import httpx

from app.config import settings
from app.platforms.firecrawl_product import crawl_product_via_firecrawl

DEFAULT_API_URL = "https://api.firecrawl.dev"
DEFAULT_PROFILE = "mavra-jd-manual"
DEFAULT_LOGIN_URL = "https://passport.jd.com/new/login.aspx"


def _headers(api_key: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {api_key}"}


def _require_api_key() -> str:
    api_key = os.environ.get("FIRECRAWL_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("Set FIRECRAWL_API_KEY before running this script.")
    return api_key


async def _post_json(
    client: httpx.AsyncClient,
    url: str,
    *,
    api_key: str,
    payload: dict[str, Any],
) -> dict[str, Any]:
    response = await client.post(url, headers=_headers(api_key), json=payload)
    if response.status_code >= 400:
        raise SystemExit(f"Firecrawl request failed: {response.status_code} {response.text[:500]}")
    data = response.json()
    if not isinstance(data, dict):
        raise SystemExit("Firecrawl returned a non-object response.")
    return data


def _scrape_id(response: dict[str, Any]) -> str:
    data = response.get("data")
    if isinstance(data, dict):
        metadata = data.get("metadata")
        if isinstance(metadata, dict) and metadata.get("scrapeId"):
            return str(metadata["scrapeId"])
    raise SystemExit("Firecrawl response did not include data.metadata.scrapeId.")


def _session_id(response: dict[str, Any]) -> str:
    data = response.get("data")
    if isinstance(data, dict):
        for key in ("id", "sessionId"):
            if data.get(key):
                return str(data[key])
    for key in ("id", "sessionId"):
        if response.get(key):
            return str(response[key])
    raise SystemExit("Firecrawl response did not include a browser session ID.")


def _interactive_url(response: dict[str, Any]) -> str:
    for key in ("interactiveLiveViewUrl", "liveViewUrl"):
        if response.get(key):
            return str(response[key])
    data = response.get("data")
    if isinstance(data, dict):
        for key in ("interactiveLiveViewUrl", "liveViewUrl"):
            if data.get(key):
                return str(data[key])
    raise SystemExit("Firecrawl interact response did not include an interactive live view URL.")


async def _execute_code(
    client: httpx.AsyncClient,
    *,
    api_url: str,
    api_key: str,
    session_id: str,
    code: str,
    timeout: int = 10,
) -> dict[str, Any]:
    return await _post_json(
        client,
        f"{api_url}/v2/interact/{session_id}/execute",
        api_key=api_key,
        payload={
            "code": code,
            "language": "node",
            "timeout": timeout,
        },
    )


def _ensure_execute_ok(response: dict[str, Any]) -> None:
    if response.get("success") is False or response.get("exitCode") not in (None, 0):
        error = response.get("error") or response.get("stderr") or "Firecrawl execute failed."
        raise SystemExit(str(error)[:800])


def _result_value(response: dict[str, Any]) -> Any:
    for key in ("result", "output"):
        if key in response:
            return response[key]
    data = response.get("data")
    if isinstance(data, dict):
        for key in ("result", "output"):
            if key in data:
                return data[key]
    return None


async def start_login_profile(args: argparse.Namespace) -> str:
    api_key = _require_api_key()
    api_url = args.api_url.rstrip("/")
    async with httpx.AsyncClient(timeout=args.timeout_seconds) as client:
        create_response = await _post_json(
            client,
            f"{api_url}/v2/interact",
            api_key=api_key,
            payload={
                "streamWebView": True,
                "profile": {"name": args.profile, "saveChanges": True},
            },
        )
        session_id = _session_id(create_response)
        try:
            live_url = _interactive_url(create_response)
        except SystemExit:
            live_url = ""
        await _execute_code(
            client,
            api_url=api_url,
            api_key=api_key,
            session_id=session_id,
            code=f"await page.goto({args.login_url!r}, {{waitUntil: 'domcontentloaded'}}); await page.title()",
        )
        if args.screenshot:
            screenshot_response = await _execute_code(
                client,
                api_url=api_url,
                api_key=api_key,
                session_id=session_id,
                code='(await page.screenshot()).toString("base64")',
            )
            _ensure_execute_ok(screenshot_response)
            screenshot_data = _result_value(screenshot_response)
            if not isinstance(screenshot_data, str):
                raise SystemExit("Firecrawl screenshot response did not include base64 image data.")
            screenshot_path = Path(args.screenshot)
            screenshot_path.write_bytes(base64.b64decode(screenshot_data))
            print(f"Screenshot: {screenshot_path}")
        print(f"Profile: {args.profile}")
        print(f"Session ID: {session_id}")
        if live_url:
            print(f"Interactive login URL: {live_url}")
        print("After logging in, run finish-login with the session ID to save profile changes.")
        return session_id


async def check_login_profile(args: argparse.Namespace) -> None:
    api_key = _require_api_key()
    api_url = args.api_url.rstrip("/")
    async with httpx.AsyncClient(timeout=args.timeout_seconds) as client:
        response = await _execute_code(
            client,
            api_url=api_url,
            api_key=api_key,
            session_id=args.session_id,
            code="""
await page.evaluate(() => ({
  title: document.title,
  url: location.href,
  hasCookies: document.cookie.length > 0,
  text: document.body ? document.body.innerText.slice(0, 500) : ''
}))
""",
        )
    _ensure_execute_ok(response)
    print(_result_value(response))


async def screenshot_session(args: argparse.Namespace) -> None:
    api_key = _require_api_key()
    api_url = args.api_url.rstrip("/")
    async with httpx.AsyncClient(timeout=args.timeout_seconds) as client:
        response = await _execute_code(
            client,
            api_url=api_url,
            api_key=api_key,
            session_id=args.session_id,
            code='(await page.screenshot()).toString("base64")',
        )
    _ensure_execute_ok(response)
    screenshot_data = _result_value(response)
    if not isinstance(screenshot_data, str):
        raise SystemExit("Firecrawl screenshot response did not include base64 image data.")
    screenshot_path = Path(args.output)
    screenshot_path.write_bytes(base64.b64decode(screenshot_data))
    print(f"Screenshot: {screenshot_path}")


async def navigate_session(args: argparse.Namespace) -> None:
    api_key = _require_api_key()
    api_url = args.api_url.rstrip("/")
    async with httpx.AsyncClient(timeout=args.timeout_seconds) as client:
        response = await _execute_code(
            client,
            api_url=api_url,
            api_key=api_key,
            session_id=args.session_id,
            code=f"await page.goto({args.url!r}, {{waitUntil: 'domcontentloaded'}}); ({{title: await page.title(), url: page.url()}})",
        )
    _ensure_execute_ok(response)
    print(_result_value(response))




async def finish_login_profile(args: argparse.Namespace) -> None:
    api_key = _require_api_key()
    api_url = args.api_url.rstrip("/")
    session_id = args.session_id or args.scrape_id
    if not session_id:
        raise SystemExit("Provide --session-id.")
    async with httpx.AsyncClient(timeout=args.timeout_seconds) as client:
        stop_response = await client.delete(
            f"{api_url}/v2/interact/{session_id}",
            headers=_headers(api_key),
        )
    if stop_response.status_code >= 400:
        raise SystemExit(f"Firecrawl stop interact failed: {stop_response.status_code} {stop_response.text[:500]}")
    print("Profile save requested.")


async def login_profile(args: argparse.Namespace) -> str:
    session_id = await start_login_profile(args)
    input("Scan/login in the live view, then press Enter here to save the profile...")
    args.session_id = session_id
    await finish_login_profile(args)
    return args.profile


async def scrape_product(args: argparse.Namespace) -> None:
    api_key = _require_api_key()
    settings.firecrawl_api_key = api_key
    settings.firecrawl_api_url = args.api_url.rstrip("/")
    settings.firecrawl_timeout_seconds = args.timeout_seconds
    settings.firecrawl_wait_for_ms = args.wait_for_ms
    settings.firecrawl_profile_name = args.profile
    result = await crawl_product_via_firecrawl(args.product_url, "jd")
    print(
        {
            "success": result.success,
            "price": result.price,
            "currency": result.currency,
            "title": result.title,
            "error": result.error,
            "profile": args.profile,
        }
    )


async def run(args: argparse.Namespace) -> None:
    if args.command == "start-login":
        await start_login_profile(args)
    elif args.command == "finish-login":
        await finish_login_profile(args)
    elif args.command == "screenshot":
        await screenshot_session(args)
    elif args.command == "check-login":
        await check_login_profile(args)
    elif args.command == "navigate":
        await navigate_session(args)
    elif args.command in {"login", "login-and-scrape"}:
        await login_profile(args)
    if args.command in {"scrape", "login-and-scrape"}:
        await scrape_product(args)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Experiment with Firecrawl JD login profile scraping.")
    parser.add_argument("--api-url", default=os.environ.get("FIRECRAWL_API_URL", DEFAULT_API_URL))
    parser.add_argument("--profile", default=os.environ.get("FIRECRAWL_PROFILE_NAME", DEFAULT_PROFILE))
    parser.add_argument("--timeout-seconds", type=float, default=60.0)
    parser.add_argument("--wait-for-ms", type=int, default=2000)
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("login", "start-login", "scrape", "login-and-scrape"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument("--login-url", default=DEFAULT_LOGIN_URL)
        subparser.add_argument("--product-url", default="https://item.jd.com/100012043978.html")
        if command in {"login", "start-login", "login-and-scrape"}:
            subparser.add_argument("--screenshot")
    finish_parser = subparsers.add_parser("finish-login")
    finish_parser.add_argument("--session-id")
    finish_parser.add_argument("--scrape-id", help=argparse.SUPPRESS)
    screenshot_parser = subparsers.add_parser("screenshot")
    screenshot_parser.add_argument("--session-id", required=True)
    screenshot_parser.add_argument("--output", required=True)
    check_parser = subparsers.add_parser("check-login")
    check_parser.add_argument("--session-id", required=True)
    navigate_parser = subparsers.add_parser("navigate")
    navigate_parser.add_argument("--session-id", required=True)
    navigate_parser.add_argument("--url", required=True)
    return parser


def main() -> None:
    asyncio.run(run(build_parser().parse_args()))


if __name__ == "__main__":
    main()
