"""Base Pydantic schema classes."""

from __future__ import annotations

from pydantic import BaseModel


class BaseResponseSchema(BaseModel):
    """Base schema for ORM-backed responses with ``from_attributes`` enabled."""

    model_config = {"from_attributes": True}
