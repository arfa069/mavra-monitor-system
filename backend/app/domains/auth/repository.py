"""Auth domain data access helpers."""

import hashlib
from inspect import isawaitable

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.login_log import LoginLog
from app.models.session import Session
from app.models.user import User


async def get_user_by_username(db: AsyncSession, *, username: str) -> User | None:
    result = await db.execute(select(User).where(User.username == username))
    return result.scalar_one_or_none()


async def get_user_by_email(db: AsyncSession, *, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_active_user_by_username(
    db: AsyncSession, *, username: str, exclude_user_id: int
) -> User | None:
    result = await db.execute(
        select(User).where(
            User.username == username,
            User.id != exclude_user_id,
            User.deleted_at.is_(None),
        )
    )
    return result.scalar_one_or_none()


async def get_active_user_by_email(
    db: AsyncSession, *, email: str, exclude_user_id: int
) -> User | None:
    result = await db.execute(
        select(User).where(
            User.email == email,
            User.id != exclude_user_id,
            User.deleted_at.is_(None),
        )
    )
    return result.scalar_one_or_none()


async def add_user(db: AsyncSession, *, user: User) -> User:
    added = db.add(user)
    if isawaitable(added):
        await added
    await db.commit()
    await db.refresh(user)
    return user


async def save_user(db: AsyncSession, *, user: User) -> User:
    await db.commit()
    await db.refresh(user)
    return user


async def add_login_log(
    db: AsyncSession, *, user_id: int, ip_address: str, user_agent: str
) -> None:
    added = db.add(
        LoginLog(
            user_id=user_id,
            ip_address=ip_address,
            user_agent=user_agent[:512],
        )
    )
    if isawaitable(added):
        await added
    await db.commit()


async def delete_session_for_token(
    db: AsyncSession, *, user_id: int, token: str
) -> bool:
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    result = await db.execute(
        select(Session).where(
            Session.user_id == user_id,
            Session.token_hash == token_hash,
        )
    )
    session = result.scalar_one_or_none()
    if session is None:
        return False

    deleted = db.delete(session)
    if isawaitable(deleted):
        await deleted
    await db.commit()
    return True


async def list_login_history(db: AsyncSession, *, user_id: int) -> list[LoginLog]:
    result = await db.execute(
        select(LoginLog)
        .where(LoginLog.user_id == user_id)
        .order_by(LoginLog.created_at.desc())
        .limit(50)
    )
    return list(result.scalars().all())
