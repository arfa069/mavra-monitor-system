"""Session management helpers.

Existing `delete_*` helpers keep auto-commit for API compatibility.
`stage_*` helpers do NOT commit — callers must commit along with business mutations.
"""
from __future__ import annotations

import hashlib

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


async def create_session(
    user_id: int,
    token: str,
    device: str,
    ip_address: str,
    db: AsyncSession,
) -> type:
    """Create a new session for a user."""
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
