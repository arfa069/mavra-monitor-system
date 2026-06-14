"""Repair smart home preference migration lineage.

Revision ID: 2026_06_06_smart_home_preferences
Revises: 2026_06_03_add_smart_home
Create Date: 2026-06-06
"""

from collections.abc import Sequence

revision: str = "2026_06_06_smart_home_preferences"
down_revision: str | None = "2026_06_03_add_smart_home"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Schema already landed in the prior smart-home revision."""


def downgrade() -> None:
    """No-op lineage repair revision."""
