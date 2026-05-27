"""add crawl task attempt count

Revision ID: 20260527_crawl_task_attempt_count
Revises: 20260527_crawler_workers
Create Date: 2026-05-27 02:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260527_crawl_task_attempt_count"
down_revision: str | None = "20260527_crawler_workers"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "crawl_tasks",
        sa.Column("attempt_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.create_index(
        "ix_crawl_tasks_attempt_count",
        "crawl_tasks",
        ["status", "attempt_count"],
    )


def downgrade() -> None:
    op.drop_index("ix_crawl_tasks_attempt_count", table_name="crawl_tasks")
    op.drop_column("crawl_tasks", "attempt_count")
