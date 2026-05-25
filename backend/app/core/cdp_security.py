"""Safety checks for Chrome DevTools Protocol endpoints."""

from __future__ import annotations

import ipaddress
from urllib.parse import urlparse

LOCAL_HOSTNAMES = {"localhost"}


def validate_cdp_url(url: str, *, allow_non_local: bool = False) -> None:
    if not url:
        raise ValueError("CDP URL is empty")
    if allow_non_local:
        # When explicitly allowed, skip local-only validation.
        # Downstream (connect_over_cdp) will validate the URL format.
        return

    parsed = urlparse(url)
    host = parsed.hostname
    if not host:
        raise ValueError("CDP URL must include a host")
    if host in LOCAL_HOSTNAMES:
        return

    try:
        address = ipaddress.ip_address(host)
    except ValueError as exc:
        raise ValueError(f"CDP URL must be local, got host {host!r}") from exc

    if not address.is_loopback:
        raise ValueError(f"CDP URL must be local, got host {host!r}")
