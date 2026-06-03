"""Add smart home Home Assistant integration.

Revision ID: 2026_06_03_add_smart_home
Revises: 20260531_task_available_at
Create Date: 2026-06-03
"""
from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "2026_06_03_add_smart_home"
down_revision: str | None = "20260531_task_available_at"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

PERMISSIONS = {
    "smart_home:read": "查看智能家居设备状态",
    "smart_home:control": "控制智能家居设备",
    "smart_home:configure": "配置 Home Assistant 连接",
}

ROLE_PERMISSIONS = {
    "user": {"smart_home:read", "smart_home:control"},
    "admin": {"smart_home:read", "smart_home:control", "smart_home:configure"},
    "super_admin": set(PERMISSIONS.keys()),
}


def upgrade() -> None:
    op.create_table(
        "smart_home_configs",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("base_url", sa.String(length=500), nullable=False),
        sa.Column("encrypted_token", sa.Text(), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("last_status", sa.String(length=50), nullable=True),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "smart_home_entity_preferences",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("entity_id", sa.String(length=255), nullable=False),
        sa.Column("alias", sa.String(length=255), nullable=True),
        sa.Column("hidden", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("area", sa.String(length=255), nullable=True),
        sa.Column("metadata_json", postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "entity_id", name="uq_smart_home_entity_pref_user_entity"),
    )
    op.create_index("ix_smart_home_entity_preferences_user_id", "smart_home_entity_preferences", ["user_id"])
    op.create_index("ix_smart_home_entity_preferences_entity_id", "smart_home_entity_preferences", ["entity_id"])

    for permission_name, description in PERMISSIONS.items():
        op.execute(
            f"INSERT INTO users_permissions (name, description) "
            f"VALUES ('{permission_name}', '{description}') "
            f"ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description"
        )
    for role_name, permission_names in ROLE_PERMISSIONS.items():
        for permission_name in sorted(permission_names):
            op.execute(
                f"INSERT INTO users_roles_permissions (role_id, permission_id) "
                f"SELECT r.id, p.id FROM users_roles r, users_permissions p "
                f"WHERE r.name = '{role_name}' AND p.name = '{permission_name}' "
                f"ON CONFLICT DO NOTHING"
            )


def downgrade() -> None:
    for role_name, permission_names in ROLE_PERMISSIONS.items():
        for permission_name in sorted(permission_names):
            op.execute(
                f"DELETE FROM users_roles_permissions "
                f"WHERE role_id = (SELECT id FROM users_roles WHERE name = '{role_name}') "
                f"AND permission_id = (SELECT id FROM users_permissions WHERE name = '{permission_name}')"
            )
    for permission_name in PERMISSIONS:
        op.execute(f"DELETE FROM users_permissions WHERE name = '{permission_name}'")
    op.drop_index("ix_smart_home_entity_preferences_entity_id", table_name="smart_home_entity_preferences")
    op.drop_index("ix_smart_home_entity_preferences_user_id", table_name="smart_home_entity_preferences")
    op.drop_table("smart_home_entity_preferences")
    op.drop_table("smart_home_configs")
