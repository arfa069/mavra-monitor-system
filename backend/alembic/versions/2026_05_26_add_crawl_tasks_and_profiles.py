"""add crawl tasks and crawl profiles

Revision ID: 20260526_crawl_tasks_profiles
Revises: 2026_05_24_make_token_hash_nullable
Create Date: 2026-05-26 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "20260526_crawl_tasks_profiles"
down_revision: str | None = "2026_05_24_make_token_hash_nullable"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "crawl_tasks",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("task_id", sa.String(length=64), nullable=False),
        sa.Column("parent_task_id", sa.String(length=64), nullable=True),
        sa.Column("task_type", sa.String(length=40), nullable=False),
        sa.Column("platform", sa.String(length=40), nullable=True),
        sa.Column("profile_key", sa.String(length=80), nullable=True),
        sa.Column("source", sa.String(length=20), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("entity_type", sa.String(length=50), nullable=True),
        sa.Column("entity_id", sa.String(length=100), nullable=True),
        sa.Column("total", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("success", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("errors", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("details_json", postgresql.JSONB(), nullable=True),
        sa.Column("payload_json", postgresql.JSONB(), nullable=True),
        sa.Column("locked_by", sa.String(length=120), nullable=True),
        sa.Column("lease_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("heartbeat_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("finished_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("task_id"),
    )
    op.create_index("ix_crawl_tasks_task_id", "crawl_tasks", ["task_id"], unique=True)
    op.create_index("ix_crawl_tasks_status_lease_until", "crawl_tasks", ["status", "lease_until"])
    op.create_index("ix_crawl_tasks_parent_status", "crawl_tasks", ["parent_task_id", "status"])
    op.create_index("ix_crawl_tasks_user_created", "crawl_tasks", ["user_id", "created_at"])
    op.create_index("ix_crawl_tasks_entity", "crawl_tasks", ["entity_type", "entity_id"])

    op.create_table(
        "crawl_profiles",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("profile_key", sa.String(length=80), nullable=False),
        sa.Column("profile_dir", sa.String(length=500), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="available"),
        sa.Column("platform_hint", sa.String(length=40), nullable=True),
        sa.Column("lease_owner", sa.String(length=120), nullable=True),
        sa.Column("lease_task_id", sa.String(length=64), nullable=True),
        sa.Column("lease_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("profile_key"),
    )
    op.create_index("ix_crawl_profiles_profile_key", "crawl_profiles", ["profile_key"], unique=True)
    op.create_index("ix_crawl_profiles_status_lease_until", "crawl_profiles", ["status", "lease_until"])


def downgrade() -> None:
    op.drop_index("ix_crawl_profiles_status_lease_until", table_name="crawl_profiles")
    op.drop_index("ix_crawl_profiles_profile_key", table_name="crawl_profiles")
    op.drop_table("crawl_profiles")
    op.drop_index("ix_crawl_tasks_entity", table_name="crawl_tasks")
    op.drop_index("ix_crawl_tasks_user_created", table_name="crawl_tasks")
    op.drop_index("ix_crawl_tasks_parent_status", table_name="crawl_tasks")
    op.drop_index("ix_crawl_tasks_status_lease_until", table_name="crawl_tasks")
    op.drop_index("ix_crawl_tasks_task_id", table_name="crawl_tasks")
    op.drop_table("crawl_tasks")
