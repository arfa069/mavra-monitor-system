"""Add Liepin as a job platform.

Revision ID: 2026_05_19_add_liepin_job_platform
Revises: 2026_05_19_harden_job_platform
Create Date: 2026-05-19
"""

revision = "2026_05_19_add_liepin_job_platform"
down_revision = "2026_05_19_harden_job_platform"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # No-op: harden_job_platform already includes 'liepin' in the constraint
    # to handle existing data that predates the check constraint. This migration
    # is preserved only to maintain the revision chain for environments that
    # apply migrations sequentially.
    pass


def downgrade() -> None:
    # No-op: downgrade is handled by harden_job_platform.
    pass
