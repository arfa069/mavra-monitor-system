"""Shared schema mixins and validators."""
from pydantic import model_validator


class IsActiveFromDeletedAtMixin:
    """Pydantic mixin that derives is_active from deleted_at ORM attribute."""

    @model_validator(mode="before")
    @classmethod
    def derive_is_active(cls, data):
        """is_active is a compatibility projection of deleted_at."""
        if hasattr(data, 'deleted_at'):
            try:
                data.is_active = data.deleted_at is None
            except Exception:
                pass
        return data
