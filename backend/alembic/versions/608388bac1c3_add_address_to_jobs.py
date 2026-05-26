"""add address to jobs

Revision ID: 608388bac1c3
Revises: c10890a48692
Create Date: 2026-04-29 02:00:00.000000

"""
from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = '608388bac1c3'
down_revision: str | None = 'c10890a48692'
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column('jobs', sa.Column('address', sa.String(length=500), nullable=True))


def downgrade() -> None:
    op.drop_column('jobs', 'address')
