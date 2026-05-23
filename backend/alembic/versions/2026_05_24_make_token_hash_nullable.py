"""Make token_hash column nullable for new sid-based auth.

The new cookie-auth flow identifies sessions by ``sid`` claim in the access
JWT rather than by hashing the raw token.  Sessions created by the new
``create_session()`` helper do not set ``token_hash``, so the column must
become nullable.

Revision ID: 2026_05_24_make_token_hash_nullable
Revises: 2026_05_24_add_refresh_token_to_sessions
Create Date: 2026-05-24
"""
from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "2026_05_24_make_token_hash_nullable"
down_revision: str | None = "2026_05_24_add_refresh_token_to_sessions"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.alter_column("users_sessions", "token_hash", nullable=False)
    op.alter_column("users_sessions", "token_hash", nullable=True)


def downgrade() -> None:
    # Reverting: first delete rows that would violate the NOT NULL constraint,
    # then make the column NOT NULL again.
    op.execute("DELETE FROM users_sessions WHERE token_hash IS NULL")
    op.alter_column("users_sessions", "token_hash", nullable=False)
