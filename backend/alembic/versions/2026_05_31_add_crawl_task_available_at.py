"""add crawl task available_at

Revision ID: 20260531_task_available_at
Revises: 20260528_product_profile_bindings
Create Date: 2026-05-31 18:20:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260531_task_available_at"
down_revision: str | None = "20260528_product_profile_bindings"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "crawl_tasks",
        sa.Column("available_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_crawl_tasks_claim_ready",
        "crawl_tasks",
        ["status", "task_type", "platform", "available_at", "created_at", "id"],
    )


def downgrade() -> None:
    op.drop_index("ix_crawl_tasks_claim_ready", table_name="crawl_tasks")
    op.drop_column("crawl_tasks", "available_at")
