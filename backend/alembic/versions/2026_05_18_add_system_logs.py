"""Add system_logs table for unified event center.

Revision ID: 2026_05_18_add_system_logs
Revises: 2026_05_17_rname_crawl_logs
Create Date: 2026-05-18
"""

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "2026_05_18_add_system_logs"
down_revision: str | None = "2026_05_17_rname_crawl_logs"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "system_logs",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("NOW()")),
        sa.Column("category", sa.String(length=50), nullable=False),
        sa.Column("event_type", sa.String(length=100), nullable=False),
        sa.Column("severity", sa.String(length=20), nullable=False, server_default="info"),
        sa.Column("source", sa.String(length=100), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=True),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("entity_type", sa.String(length=50), nullable=True),
        sa.Column("entity_id", sa.String(length=255), nullable=True),
        sa.Column("trace_id", sa.String(length=100), nullable=True),
        sa.Column("payload_json", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_system_logs_occurred_at", "system_logs", ["occurred_at"])
    op.create_index("ix_system_logs_category", "system_logs", ["category"])
    op.create_index("ix_system_logs_event_type", "system_logs", ["event_type"])
    op.create_index("ix_system_logs_severity", "system_logs", ["severity"])
    op.create_index("ix_system_logs_source", "system_logs", ["source"])
    op.create_index("ix_system_logs_status", "system_logs", ["status"])
    op.create_index("ix_system_logs_trace_id", "system_logs", ["trace_id"])
    op.create_index("ix_system_logs_user_id", "system_logs", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_system_logs_user_id", table_name="system_logs")
    op.drop_index("ix_system_logs_trace_id", table_name="system_logs")
    op.drop_index("ix_system_logs_status", table_name="system_logs")
    op.drop_index("ix_system_logs_source", table_name="system_logs")
    op.drop_index("ix_system_logs_severity", table_name="system_logs")
    op.drop_index("ix_system_logs_event_type", table_name="system_logs")
    op.drop_index("ix_system_logs_category", table_name="system_logs")
    op.drop_index("ix_system_logs_occurred_at", table_name="system_logs")
    op.drop_table("system_logs")
