"""Seed DB-backed RBAC permission matrix.

Revision ID: 2026_05_21_seed_db_rbac
Revises: 2026_05_20_prod_cron_uq
Create Date: 2026-05-21
"""
from collections.abc import Sequence

from alembic import op

revision: str = "2026_05_21_seed_db_rbac"
down_revision: str | None = "2026_05_20_prod_cron_uq"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

ROLE_DESCRIPTIONS = {
    "user": "普通用户",
    "admin": "运营管理员",
    "super_admin": "系统管理员",
}

PERMISSION_DESCRIPTIONS = {
    "user:read": "查看用户列表和用户详情",
    "user:manage": "创建和编辑用户",
    "user:delete": "删除用户",
    "crawl:execute": "执行商品或职位爬取",
    "crawl:read_logs": "查看爬取日志",
    "schedule:read": "查看调度配置",
    "schedule:configure": "配置调度计划",
    "config:read": "查看系统配置",
    "config:write": "修改系统配置",
    "product:read": "跨用户查看商品资源",
    "product:write": "跨用户修改商品资源",
    "product:delete": "跨用户删除商品资源",
    "job:read": "跨用户查看职位资源",
    "job:write": "跨用户修改职位资源",
    "job:delete": "跨用户删除职位资源",
    "rbac:read": "查看角色权限矩阵",
    "rbac:manage": "修改角色权限矩阵",
}

ROLE_PERMISSIONS = {
    "user": {"crawl:execute", "crawl:read_logs", "schedule:read", "config:write"},
    "admin": {"user:read", "user:manage", "user:delete", "crawl:read_logs", "schedule:read", "config:read", "config:write"},
    "super_admin": set(PERMISSION_DESCRIPTIONS.keys()),
}


def upgrade() -> None:
    for role_name, description in ROLE_DESCRIPTIONS.items():
        op.execute(
            f"INSERT INTO users_roles (name, description) "
            f"VALUES ('{role_name}', '{description}') "
            f"ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description"
        )
    for permission_name, description in PERMISSION_DESCRIPTIONS.items():
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
