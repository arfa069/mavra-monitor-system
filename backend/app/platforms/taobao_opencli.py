import asyncio
import json
import logging
import re
from dataclasses import dataclass
from typing import Any

from app.config import settings

logger = logging.getLogger(__name__)

# Extracts item ID from Taobao/Tmall URLs:
#   https://item.taobao.com/item.htm?id=904308303683
#   https://detail.tmall.com/item.htm?id=904308303683&skuId=...
_ID_RE = re.compile(r'[?&]id=(\d+)')


@dataclass
class OpenCLITaobaoResult:
    success: bool
    price: str | None = None
    currency: str = "CNY"
    title: str | None = None
    error: str | None = None


def extract_item_id(url: str) -> str | None:
    m = _ID_RE.search(url)
    return m.group(1) if m else None


async def crawl_taobao_via_opencli(url: str) -> OpenCLITaobaoResult:
    item_id = extract_item_id(url)
    if not item_id:
        return OpenCLITaobaoResult(
            success=False, error=f"Cannot extract item ID from Taobao URL: {url}"
        )

    cmd_str = f"{settings.taobao_opencli_command} taobao detail {item_id} -f json"
    logger.debug("Running OpenCLI: %s", cmd_str)

    try:
        proc = await asyncio.create_subprocess_shell(
            cmd_str,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await asyncio.wait_for(
            proc.communicate(),
            timeout=settings.taobao_opencli_timeout_seconds,
        )
        if proc.returncode != 0:
            err_text = stderr.decode("utf-8", errors="replace").strip()
            logger.warning("OpenCLI taobao exited %d: %s", proc.returncode, err_text)
            return OpenCLITaobaoResult(
                success=False,
                error=f"opencli exited {proc.returncode}: {err_text}",
            )

        raw = stdout.decode("utf-8", errors="replace").strip()
        if not raw:
            return OpenCLITaobaoResult(
                success=False, error="opencli returned empty output"
            )

        items: list[dict[str, Any]] = json.loads(raw)
        if not items:
            return OpenCLITaobaoResult(
                success=False, error="opencli returned empty item list"
            )

        # Parse field/value pairs into a dict
        fields: dict[str, str] = {}
        for entry in items:
            fields[entry.get("field", "")] = entry.get("value", "")

        price_raw = fields.get("价格", "")
        price = price_raw.lstrip("¥￥").strip() if price_raw else ""

        title = fields.get("商品名称", "")

        return OpenCLITaobaoResult(
            success=True,
            price=price,
            currency="CNY",
            title=title,
        )

    except TimeoutError:
        return OpenCLITaobaoResult(
            success=False, error="opencli timed out"
        )
    except json.JSONDecodeError as exc:
        return OpenCLITaobaoResult(
            success=False, error=f"opencli JSON parse error: {exc}"
        )
    except FileNotFoundError:
        return OpenCLITaobaoResult(
            success=False,
            error=f"opencli command not found: {settings.taobao_opencli_command}",
        )
    except Exception as exc:
        logger.exception("OpenCLI Taobao crawl failed for %s", url)
        return OpenCLITaobaoResult(
            success=False, error=f"opencli error: {exc}"
        )
