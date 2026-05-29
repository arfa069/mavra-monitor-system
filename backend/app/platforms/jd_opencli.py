import asyncio
import json
import logging
import re
from dataclasses import dataclass
from typing import Any

from app.config import settings

logger = logging.getLogger(__name__)

# Extracts SKU from JD URL patterns like:
#   https://item.jd.com/100147630258.html
#   https://item.m.jd.com/product/100147630258.html
_SKU_RE = re.compile(r'[/.]jd\.com/(?:product/)?(\d+)')


@dataclass
class OpenCLIJdResult:
    success: bool
    price: str | None = None
    currency: str = "CNY"
    title: str | None = None
    shop: str | None = None
    is_login_page: bool = False
    has_security_challenge: bool = False
    looks_blocked: bool = False
    error: str | None = None


def extract_sku(url: str) -> str | None:
    m = _SKU_RE.search(url)
    return m.group(1) if m else None


async def crawl_jd_via_opencli(url: str) -> OpenCLIJdResult:
    if not settings.jd_opencli_enabled:
        return OpenCLIJdResult(
            success=False, error="jd_opencli_enabled is False"
        )

    sku = extract_sku(url)
    if not sku:
        return OpenCLIJdResult(
            success=False, error=f"Cannot extract SKU from JD URL: {url}"
        )

    cmd_str = f"{settings.jd_opencli_command} jd item {sku} -f json"
    logger.debug("Running OpenCLI: %s", cmd_str)

    try:
        proc = await asyncio.create_subprocess_shell(
            cmd_str,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await asyncio.wait_for(
            proc.communicate(),
            timeout=settings.jd_opencli_timeout_seconds,
        )
        if proc.returncode != 0:
            err_text = stderr.decode("utf-8", errors="replace").strip()
            logger.warning("OpenCLI exited %d: %s", proc.returncode, err_text)
            return OpenCLIJdResult(
                success=False,
                error=f"opencli exited {proc.returncode}: {err_text}",
            )

        raw = stdout.decode("utf-8", errors="replace").strip()
        if not raw:
            return OpenCLIJdResult(
                success=False, error="opencli returned empty output"
            )

        items: list[dict[str, Any]] = json.loads(raw)
        if not items:
            return OpenCLIJdResult(
                success=False, error="opencli returned empty item list"
            )

        item = items[0]
        page_state: dict[str, Any] = item.get("pageState", {})

        return OpenCLIJdResult(
            success=True,
            price=str(item.get("price", "")),
            currency="CNY",
            title=item.get("title"),
            shop=item.get("shop"),
            is_login_page=bool(page_state.get("isLoginPage", False)),
            has_security_challenge=bool(
                page_state.get("hasSecurityChallenge", False)
            ),
            looks_blocked=bool(page_state.get("looksBlocked", False)),
        )

    except TimeoutError:
        return OpenCLIJdResult(
            success=False, error="opencli timed out"
        )
    except json.JSONDecodeError as exc:
        return OpenCLIJdResult(
            success=False, error=f"opencli JSON parse error: {exc}"
        )
    except FileNotFoundError:
        return OpenCLIJdResult(
            success=False,
            error=f"opencli command not found: {settings.jd_opencli_command}",
        )
    except Exception as exc:
        logger.exception("OpenCLI JD crawl failed for %s", url)
        return OpenCLIJdResult(
            success=False, error=f"opencli error: {exc}"
        )
