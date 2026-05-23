"""Config domain data access helpers."""

from inspect import isawaitable

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


async def get_default_user(db: AsyncSession) -> User | None:
    result = await db.execute(select(User).where(User.username == "default"))
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
