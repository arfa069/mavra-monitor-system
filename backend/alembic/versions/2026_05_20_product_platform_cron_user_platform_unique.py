"""Product platform cron: drop UNIQUE(platform), add (user_id, platform).

Revision ID: 2026_05_20_product_platform_cron_user_platform_unique
Revises: 2026_05_19_add_liepin_job_platform
Create Date: 2026-05-20
"""
from alembic import op

revision = "2026_05_20_prod_cron_uq"
down_revision = "2026_05_19_liepin_platform"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Drop old UNIQUE(platform) constraint
    # PostgreSQL auto-names unnamed UniqueConstraints as {table}_{column}_key
    op.drop_constraint(
        "products_platform_crons_platform_key",
        "products_platform_crons",
        type_="unique",
    )
    # Create (user_id, platform) composite unique constraint
    op.create_unique_constraint(
        "uq_products_platform_crons_user_platform",
        "products_platform_crons",
        ["user_id", "platform"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_products_platform_crons_user_platform",
        "products_platform_crons",
        type_="unique",
    )
    op.create_unique_constraint(
        "products_platform_crons_platform_key",
        "products_platform_crons",
        ["platform"],
    )
