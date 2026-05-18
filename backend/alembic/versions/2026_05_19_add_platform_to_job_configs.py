"""Add platform column to jobs_search_configs.

Revision ID: 2026_05_19_add_platform
Revises: 2026_05_18_add_system_logs
Create Date: 2026-05-19
"""

import sqlalchemy as sa

from alembic import op

revision: str = "2026_05_19_add_platform"
down_revision: str | None = "2026_05_18_add_system_logs"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "jobs_search_configs",
        sa.Column(
            "platform",
            sa.String(length=20),
            nullable=False,
            server_default="boss",
            comment="Job platform: boss, 51job",
        ),
    )


def downgrade() -> None:
    op.drop_column("jobs_search_configs", "platform")
