"""Request helper utilities."""

from __future__ import annotations

from fastapi import Request


def get_client_ip(request: Request) -> str:
    """Return the client IP address or an empty string."""
    return request.client.host if request.client else ""
