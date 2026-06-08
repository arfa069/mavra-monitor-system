"""Shared LLM provider utilities."""

from __future__ import annotations

import json
import re


def extract_json(content: str) -> dict:
    """Extract the first JSON object from a text string."""
    match = re.search(r"\{.*\}", content, flags=re.S)
    if not match:
        raise ValueError("No JSON payload found in LLM response")
    return json.loads(match.group(0))
