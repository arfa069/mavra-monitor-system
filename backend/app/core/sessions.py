"""Session management helpers.

Existing `delete_*` helpers keep auto-commit for API compatibility.
`stage_*` helpers do NOT commit — callers must commit along with business mutations.
"""
from __future__ import annotations

import hashlib
from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings

# ── Legacy session helper (auto-commit, token-hash based) ───────────────────


async def create_session_with_token(
    user_id: int,
    token: str,
    device: str,
    ip_address: str,
    db: AsyncSession,
) -> type:
    """Create a new session for a user (legacy, token-hash based, auto-commit).

    .. deprecated::
        Use :func:`create_session` (refresh-token based, no auto-commit) instead.
        Kept for existing callers until refactored in Task 5/6.
    """
    from app.models.session import Session

    token_hash = hashlib.sha256(token.encode()).hexdigest()

    # Check max sessions (5)
    result = await db.execute(
        select(Session).where(
            Session.user_id == user_id,
            Session.token_hash.isnot(None)
        ).order_by(Session.created_at)
    )
    existing = result.scalars().all()
    if len(existing) >= 5:
        await db.delete(existing[0])

    session = Session(
        user_id=user_id,
        token_hash=token_hash,
        device=device,
        ip_address=ip_address,
    )
    db.add(session)
    await db.commit()
    return session


# ── New refresh-token-based session helpers ─────────────────────────────────


async def create_session(
    user_id: int,
    refresh_token: str,
    device: str,
    ip_address: str,
    db: AsyncSession,
):
    """Create a new session for a user using a refresh token.

    Hashes the refresh token via :func:`hash_token` before storage.
    Enforces a maximum of 5 active sessions per user (removes oldest when at limit).
    Sets ``refresh_expires_at`` to UTC now + ``refresh_token_expire_days`` (14 days).

    Does NOT commit — the caller controls the transaction boundary.
    """
    from app.core.tokens import hash_token
    from app.models.session import Session

    refresh_hash = hash_token(refresh_token)

    # Enforce max 5 sessions per user
    result = await db.execute(
        select(Session)
        .where(Session.user_id == user_id)
        .order_by(Session.created_at)
    )
    existing = result.scalars().all()
    if len(existing) >= 5:
        await db.delete(existing[0])

    session = Session(
        user_id=user_id,
        refresh_token_hash=refresh_hash,
        refresh_expires_at=datetime.now(UTC)
        + timedelta(days=settings.refresh_token_expire_days),
        device=device,
        ip_address=ip_address,
    )
    db.add(session)
    # Caller controls commit
    return session


async def get_session_by_refresh_token(
    refresh_token: str,
    db: AsyncSession,
):
    """Look up a session by hashed refresh token.

    Only returns sessions where ``refresh_expires_at`` is still in the future.
    Returns ``None`` if the token is expired, invalid, or the session was deleted.
    """
    from app.core.tokens import hash_token
    from app.models.session import Session

    token_hash = hash_token(refresh_token)
    result = await db.execute(
        select(Session).where(
            Session.refresh_token_hash == token_hash,
            Session.refresh_expires_at > datetime.now(UTC),
        )
    )
    return result.scalar_one_or_none()


async def rotate_session_refresh_token(
    session,
    new_refresh_token: str,
    db: AsyncSession,
) -> None:
    """Rotate a session's refresh token in-place.

    Updates ``refresh_token_hash`` to the hash of the new token, extends
    ``refresh_expires_at`` by ``refresh_token_expire_days``, and touches
    ``last_active_at``.

    Does NOT commit — the caller controls the transaction boundary.
    """
    from app.core.tokens import hash_token

    session.refresh_token_hash = hash_token(new_refresh_token)
    session.refresh_expires_at = datetime.now(UTC) + timedelta(
        days=settings.refresh_token_expire_days
    )
    session.last_active_at = datetime.now(UTC)


async def get_session_by_id(
    session_id: int,
    user_id: int,
    db: AsyncSession,
):
    """Look up a session by its primary key, scoped to ``user_id``.

    Returns ``None`` if the session does not exist or belongs to a different user.
    Used by access-token auth for ``sid``-based lookups.
    """
    from app.models.session import Session

    result = await db.execute(
        select(Session).where(
            Session.id == session_id,
            Session.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


# ── Existing helpers (unchanged signatures) ─────────────────────────────────


async def get_user_sessions(user_id: int, db: AsyncSession) -> list[type]:
    """Get all active sessions for a user."""
    from app.models.session import Session

    result = await db.execute(
        select(Session).where(Session.user_id == user_id)
    )
    return list(result.scalars().all())


async def delete_session(session_id: int, user_id: int, db: AsyncSession) -> bool:
    """Delete a specific session (auto-commit)."""
    from app.models.session import Session

    result = await db.execute(
        select(Session).where(
            Session.id == session_id,
            Session.user_id == user_id
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        return False
    await db.delete(session)
    await db.commit()
    return True


async def delete_other_sessions(current_session_id: int, user_id: int, db: AsyncSession) -> int:
    """Delete all sessions except the current one (auto-commit)."""
    from app.models.session import Session

    result = await db.execute(
        select(Session).where(
            Session.user_id == user_id,
            Session.id != current_session_id
        )
    )
    sessions = result.scalars().all()
    for s in sessions:
        await db.delete(s)
    await db.commit()
    return len(sessions)


async def get_session_by_token(token: str, user_id: int, db: AsyncSession) -> type | None:
    """Return the current token session for a user, or None."""
    from app.models.session import Session

    token_hash = hashlib.sha256(token.encode()).hexdigest()
    result = await db.execute(
        select(Session).where(
            Session.user_id == user_id,
            Session.token_hash == token_hash,
        )
    )
    return result.scalar_one_or_none()


async def stage_delete_user_sessions(user_id: int, db: AsyncSession) -> int:
    """Stage deletion of all sessions for user in the current transaction. Caller commits."""
    from app.models.session import Session

    result = await db.execute(
        select(Session).where(Session.user_id == user_id)
    )
    sessions = result.scalars().all()
    for s in sessions:
        await db.delete(s)
    return len(sessions)


async def stage_delete_other_sessions(current_session_id: int, user_id: int, db: AsyncSession) -> int:
    """Stage deletion of all sessions except current_session_id. Caller commits."""
    from app.models.session import Session

    result = await db.execute(
        select(Session).where(
            Session.user_id == user_id,
            Session.id != current_session_id
        )
    )
    sessions = result.scalars().all()
    for s in sessions:
        await db.delete(s)
    return len(sessions)
