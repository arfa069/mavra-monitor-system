"""add crawler workers

Revision ID: 20260527_crawler_workers
Revises: 20260526_product_cron_profile
Create Date: 2026-05-27 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260527_crawler_workers"
down_revision: str | None = "20260526_product_cron_profile"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "crawler_workers",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("worker_id", sa.String(length=120), nullable=False),
        sa.Column("kind", sa.String(length=20), nullable=False),
        sa.Column("platform", sa.String(length=40), nullable=True),
        sa.Column("hostname", sa.String(length=120), nullable=False),
        sa.Column("pid", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_heartbeat_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("stopped_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("worker_id"),
    )
    op.create_index("ix_crawler_workers_worker_id", "crawler_workers", ["worker_id"])
    op.create_index(
        "ix_crawler_workers_status_heartbeat",
        "crawler_workers",
        ["status", "last_heartbeat_at"],
    )
    op.create_index(
        "ix_crawler_workers_kind_platform_status",
        "crawler_workers",
        ["kind", "platform", "status"],
    )
    op.create_index(
        "ix_crawl_tasks_claim_filter",
        "crawl_tasks",
        ["status", "task_type", "platform", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_crawl_tasks_claim_filter", table_name="crawl_tasks")
    op.drop_index("ix_crawler_workers_kind_platform_status", table_name="crawler_workers")
    op.drop_index("ix_crawler_workers_status_heartbeat", table_name="crawler_workers")
    op.drop_index("ix_crawler_workers_worker_id", table_name="crawler_workers")
    op.drop_table("crawler_workers")
