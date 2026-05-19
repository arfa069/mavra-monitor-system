"""Harden job platform and job id constraints.

Revision ID: 2026_05_19_harden_job_platform
Revises: 2026_05_19_add_platform
Create Date: 2026-05-19
"""

from alembic import op

revision: str = "2026_05_19_harden_job_platform"
down_revision: str | None = "2026_05_19_add_platform"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_check_constraint(
        "ck_jobs_search_configs_platform",
        "jobs_search_configs",
        "platform IN ('boss', '51job')",
    )
    op.drop_constraint("jobs_job_id_key", "jobs", type_="unique")
    op.create_unique_constraint(
        "uq_jobs_config_job_id",
        "jobs",
        ["search_config_id", "job_id"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_jobs_config_job_id", "jobs", type_="unique")
    op.create_unique_constraint("jobs_job_id_key", "jobs", ["job_id"])
    op.drop_constraint(
        "ck_jobs_search_configs_platform",
        "jobs_search_configs",
        type_="check",
    )
