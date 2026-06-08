"""URL normalization utilities."""
from __future__ import annotations

from urllib.parse import parse_qs, urlparse


def normalize_tmall_url(url: str) -> str:
    """Extract id and skuId from Taobao/Tmall URL and rebuild full URL."""
    parsed = urlparse(url)
    params = parse_qs(parsed.query)

    item_id = params.get("id", [None])[0]
    sku_id = params.get("skuId", [None])[0]

    if not item_id:
        return url

    query_parts = [f"id={item_id}"]
    if sku_id:
        query_parts.append(f"skuId={sku_id}")

    return f"{parsed.scheme}://{parsed.netloc}{parsed.path}?{'&'.join(query_parts)}"


def normalize_product_url(url: str, platform: str) -> str:
    """Normalize a product URL based on its platform."""
    if platform == "taobao":
        return normalize_tmall_url(url)
    return url
