"""Add updated_at to users_roles and users_permissions.

Revision ID: 2026_05_22_add_rbac_updated_at
Revises: 2026_05_21_seed_db_rbac
Create Date: 2026-05-22
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "2026_05_22_add_rbac_updated_at"
down_revision: str | None = "2026_05_21_seed_db_rbac"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "users_roles",
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.execute("UPDATE users_roles SET updated_at = created_at")
    op.alter_column("users_roles", "updated_at", nullable=False)

    op.add_column(
        "users_permissions",
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.execute("UPDATE users_permissions SET updated_at = created_at")
    op.alter_column("users_permissions", "updated_at", nullable=False)


def downgrade() -> None:
    op.drop_column("users_permissions", "updated_at")
    op.drop_column("users_roles", "updated_at")
