"""OpenAPI naming helpers."""

import re

from fastapi.routing import APIRoute


def _operation_token(value: str) -> str:
    token = re.sub(r"[^0-9A-Za-z_]+", "_", value).strip("_").lower()
    return token or "default"


def generate_operation_id(route: APIRoute) -> str:
    """Return a stable ID independent from the mounted URL prefix."""
    tag = _operation_token(str((route.tags or ["default"])[0]))
    return f"{tag}_{_operation_token(route.name)}"
