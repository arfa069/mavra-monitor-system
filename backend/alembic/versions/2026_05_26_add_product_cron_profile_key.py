"""add product cron profile key

Revision ID: 20260526_product_cron_profile
Revises: 20260526_job_profile_key
Create Date: 2026-05-26 00:00:00.000000
"""

from typing import Sequence, Union
from pathlib import Path

from alembic import op
import sqlalchemy as sa


revision: str = "20260526_product_cron_profile"
down_revision: Union[str, None] = "20260526_job_profile_key"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


DEFAULT_KEYS = {
    "jd": "product-jd-default",
    "taobao": "product-taobao-default",
    "amazon": "product-amazon-default",
}
PROJECT_ROOT = Path(__file__).resolve().parents[3]


def upgrade() -> None:
    op.add_column(
        "products_platform_crons",
        sa.Column("profile_key", sa.String(length=80), nullable=True),
    )

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
                SET profile_key = :profile_key
                WHERE platform = :platform AND profile_key IS NULL
                """
            ),
            {"profile_key": profile_key, "platform": platform},
        )

    op.alter_column("products_platform_crons", "profile_key", nullable=False)
    op.create_index(
        "ix_products_platform_crons_profile_key",
        "products_platform_crons",
        ["profile_key"],
    )
    op.create_foreign_key(
        "fk_products_platform_crons_profile_key_crawl_profiles",
        "products_platform_crons",
        "crawl_profiles",
        ["profile_key"],
        ["profile_key"],
        ondelete="RESTRICT",
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_products_platform_crons_profile_key_crawl_profiles",
        "products_platform_crons",
        type_="foreignkey",
    )
    op.drop_index(
        "ix_products_platform_crons_profile_key",
        table_name="products_platform_crons",
    )
    op.drop_column("products_platform_crons", "profile_key")
