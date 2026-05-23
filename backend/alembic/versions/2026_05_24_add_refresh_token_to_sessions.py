"""Add refresh_token_hash and refresh_expires_at to users_sessions.

Revision ID: 2026_05_24_add_refresh_token_to_sessions
Revises: 2026_05_22_add_rbac_updated_at
Create Date: 2026-05-24
"""
from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "2026_05_24_add_refresh_token_to_sessions"
down_revision: str | None = "2026_05_22_add_rbac_updated_at"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Add refresh_token_hash (nullable initially, with unique constraint)
    op.add_column(
        "users_sessions",
        sa.Column("refresh_token_hash", sa.String(64), nullable=True),
    )
    op.create_unique_constraint(
        "uq_users_sessions_refresh_token_hash",
        "users_sessions",
        ["refresh_token_hash"],
    )

    # Add refresh_expires_at (nullable temporarily for migration)
    op.add_column(
        "users_sessions",
        sa.Column("refresh_expires_at", sa.DateTime(timezone=True), nullable=True),
    )

    # Delete existing sessions that cannot provide valid refresh tokens
    op.execute("DELETE FROM users_sessions")

    # Make refresh_expires_at NOT NULL now that all legacy rows are cleared
    op.alter_column("users_sessions", "refresh_expires_at", nullable=False)


def downgrade() -> None:
    op.drop_constraint(
        "uq_users_sessions_refresh_token_hash",
        "users_sessions",
        type_="unique",
    )
    op.drop_column("users_sessions", "refresh_expires_at")
    op.drop_column("users_sessions", "refresh_token_hash")
