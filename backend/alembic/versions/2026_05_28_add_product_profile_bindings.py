"""add product platform profile bindings

Revision ID: 20260528_product_profile_bindings
Revises: 20260527_crawl_task_attempt_count
Create Date: 2026-05-28 00:00:00.000000
"""

from collections.abc import Sequence
from pathlib import Path

import sqlalchemy as sa

from alembic import op

revision: str = "20260528_product_profile_bindings"
down_revision: str | None = "20260527_crawl_task_attempt_count"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


DEFAULT_KEYS = {
    "jd": "product-jd-default",
    "taobao": "product-taobao-default",
    "amazon": "product-amazon-default",
}
PROJECT_ROOT = Path(__file__).resolve().parents[3]


def upgrade() -> None:
    op.alter_column(
        "products_platform_crons",
        "profile_key",
        existing_type=sa.String(length=80),
        nullable=True,
    )
    op.create_table(
        "products_platform_profile_bindings",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("platform", sa.String(length=20), nullable=False),
        sa.Column("profile_key", sa.String(length=80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["profile_key"],
            ["crawl_profiles.profile_key"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "user_id",
            "platform",
            name="uq_products_platform_profile_bindings_user_platform",
        ),
    )
    op.create_index(
        "ix_products_platform_profile_bindings_profile_key",
        "products_platform_profile_bindings",
        ["profile_key"],
    )

    conn = op.get_bind()
    conn.execute(
        sa.text(
            """
            INSERT INTO products_platform_profile_bindings (
                user_id, platform, profile_key, created_at, updated_at
            )
            SELECT DISTINCT ON (user_id, platform)
                user_id, platform, profile_key, NOW(), NOW()
            FROM products_platform_crons
            WHERE profile_key IS NOT NULL
            ORDER BY user_id, platform, updated_at DESC, id DESC
            ON CONFLICT (user_id, platform) DO NOTHING
            """
        )
    )
    conn.execute(sa.text("UPDATE products_platform_crons SET profile_key = NULL"))


def downgrade() -> None:
    conn = op.get_bind()
    for platform, profile_key in DEFAULT_KEYS.items():
        conn.execute(
            sa.text(
                """
                INSERT INTO crawl_profiles (
                    profile_key, profile_dir, status, platform_hint,
                    lease_owner, lease_task_id, lease_until,
                    last_used_at, last_error, created_at, updated_at
                )
                VALUES (
                    :profile_key, :profile_dir, 'available', :platform,
                    NULL, NULL, NULL,
                    NULL, NULL, NOW(), NOW()
                )
                ON CONFLICT (profile_key) DO NOTHING
                """
            ),
            {
                "profile_key": profile_key,
                "profile_dir": str(PROJECT_ROOT / "profiles" / profile_key),
                "platform": platform,
            },
        )
        conn.execute(
            sa.text(
                """
                UPDATE products_platform_crons
                SET profile_key = COALESCE(
                    (
                        SELECT profile_key
                        FROM products_platform_profile_bindings
                        WHERE products_platform_profile_bindings.user_id = products_platform_crons.user_id
                          AND products_platform_profile_bindings.platform = products_platform_crons.platform
                        LIMIT 1
                    ),
                    :profile_key
                )
                WHERE platform = :platform
                """
            ),
            {"profile_key": profile_key, "platform": platform},
        )

    op.drop_index(
        "ix_products_platform_profile_bindings_profile_key",
        table_name="products_platform_profile_bindings",
    )
    op.drop_table("products_platform_profile_bindings")
    op.alter_column(
        "products_platform_crons",
        "profile_key",
        existing_type=sa.String(length=80),
        nullable=False,
    )
