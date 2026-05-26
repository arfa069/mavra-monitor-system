"""add profile key to job search configs

Revision ID: 20260526_job_profile_key
Revises: 20260526_crawl_tasks_profiles
Create Date: 2026-05-26 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260526_job_profile_key"
down_revision: Union[str, None] = "20260526_crawl_tasks_profiles"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "jobs_search_configs",
        sa.Column(
            "profile_key",
            sa.String(length=80),
            nullable=False,
            server_default="default",
        ),
    )
    op.execute(
        """
        INSERT INTO crawl_profiles (
            profile_key,
            profile_dir,
            status,
            created_at,
            updated_at
        )
        VALUES (
            'default',
            'profiles/default',
            'available',
            NOW(),
            NOW()
        )
        ON CONFLICT (profile_key) DO NOTHING
        """
    )
    op.alter_column("jobs_search_configs", "profile_key", server_default=None)


def downgrade() -> None:
    op.drop_column("jobs_search_configs", "profile_key")
