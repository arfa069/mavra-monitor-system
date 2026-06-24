"""Add crawl profile management permission.

Revision ID: 2026_06_24_crawl_profile_manage
Revises: 2026_06_10_add_blog
Create Date: 2026-06-24
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "2026_06_24_crawl_profile_manage"
down_revision: str | None = "2026_06_10_add_blog"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

PERMISSION_NAME = "crawl_profile:manage"
PERMISSION_DESCRIPTION = "Manage shared crawl browser profiles"
ROLE_NAMES = ("admin", "super_admin")


def upgrade() -> None:
    bind = op.get_bind()
    bind.execute(
        sa.text(
            """
            INSERT INTO users_permissions (name, description, created_at, updated_at)
            VALUES (:name, :description, now(), now())
            ON CONFLICT (name) DO UPDATE
            SET description = EXCLUDED.description,
                updated_at = now()
            """
        ),
        {"name": PERMISSION_NAME, "description": PERMISSION_DESCRIPTION},
    )
    for role_name in ROLE_NAMES:
        bind.execute(
            sa.text(
                """
                INSERT INTO users_roles_permissions (role_id, permission_id)
                SELECT r.id, p.id
                FROM users_roles r, users_permissions p
                WHERE r.name = :role_name AND p.name = :permission_name
                ON CONFLICT DO NOTHING
                """
            ),
            {"role_name": role_name, "permission_name": PERMISSION_NAME},
        )


def downgrade() -> None:
    bind = op.get_bind()
    for role_name in ROLE_NAMES:
        bind.execute(
            sa.text(
                """
                DELETE FROM users_roles_permissions
                WHERE role_id = (SELECT id FROM users_roles WHERE name = :role_name)
                  AND permission_id = (
                      SELECT id FROM users_permissions WHERE name = :permission_name
                  )
                """
            ),
            {"role_name": role_name, "permission_name": PERMISSION_NAME},
        )
    bind.execute(
        sa.text("DELETE FROM users_permissions WHERE name = :permission_name"),
        {"permission_name": PERMISSION_NAME},
    )
