"""Add Liepin as a job platform.

Revision ID: 2026_05_19_add_liepin_job_platform
Revises: 2026_05_19_harden_job_platform
Create Date: 2026-05-19
"""

from alembic import op

revision = "2026_05_19_add_liepin_job_platform"
down_revision = "2026_05_19_harden_job_platform"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_constraint("ck_jobs_search_configs_platform", "jobs_search_configs", type_="check")
    op.create_check_constraint(
        "ck_jobs_search_configs_platform",
        "jobs_search_configs",
        "platform IN ('boss', '51job', 'liepin')",
    )


def downgrade() -> None:
    op.drop_constraint("ck_jobs_search_configs_platform", "jobs_search_configs", type_="check")
    op.create_check_constraint(
        "ck_jobs_search_configs_platform",
        "jobs_search_configs",
        "platform IN ('boss', '51job')",
    )
