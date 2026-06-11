"""Auth domain business services."""

from sqlalchemy.ext.asyncio import AsyncSession

from app.domains.auth import repository
from app.models.login_log import LoginLog
from app.models.user import User
from app.schemas.auth import ProfileUpdate, UserRegister


class AuthServiceError(Exception):
    """Base exception for auth service errors."""


class UsernameConflictError(AuthServiceError):
    """Raised when username is already used."""


class EmailConflictError(AuthServiceError):
    """Raised when email is already used."""


class WeChatOpenidConflictError(AuthServiceError):
    """Raised when a WeChat openid is already bound."""


async def register_user(
    db: AsyncSession, *, user_data: UserRegister, password_hash: str
) -> User:
    if await repository.get_user_by_username(db, username=user_data.username):
        raise UsernameConflictError
    if await repository.get_user_by_email(db, email=user_data.email):
        raise EmailConflictError

    return await repository.add_user(
        db,
        user=User(
            username=user_data.username,
            email=user_data.email,
            hashed_password=password_hash,
            is_active=True,
        ),
    )


async def get_user_for_login(db: AsyncSession, *, username: str) -> User | None:
    return await repository.get_user_by_username(db, username=username)


async def get_user_for_wechat_login(
    db: AsyncSession, *, openid: str
) -> User | None:
    return await repository.get_active_user_by_wechat_openid(db, openid=openid)


async def bind_wechat_openid(
    db: AsyncSession, *, user: User, openid: str
) -> User:
    if await repository.get_active_user_by_wechat_openid(db, openid=openid):
        raise WeChatOpenidConflictError
    if await repository.get_wechat_openid_conflict(
        db, openid=openid, exclude_user_id=user.id
    ):
        raise WeChatOpenidConflictError

    from datetime import UTC, datetime

    user.wechat_openid = openid
    user.wechat_bind_at = datetime.now(UTC)
    await db.commit()
    return user


async def register_wechat_user(
    db: AsyncSession,
    *,
    username: str,
    email: str,
    password_hash: str,
    openid: str,
) -> User:
    if await repository.get_active_user_by_wechat_openid(db, openid=openid):
        raise WeChatOpenidConflictError
    if await repository.get_active_user_by_username_for_wechat(
        db, username=username
    ):
        raise UsernameConflictError
    if await repository.get_active_user_by_email_for_wechat(db, email=email):
        raise EmailConflictError

    from datetime import UTC, datetime

    return await repository.add_user(
        db,
        user=User(
            username=username,
            email=email,
            hashed_password=password_hash,
            is_active=True,
            wechat_openid=openid,
            wechat_bind_at=datetime.now(UTC),
        ),
    )


async def get_user_for_wechat_bind(
    db: AsyncSession, *, username: str
) -> User | None:
    return await repository.get_active_user_by_username_for_wechat(
        db, username=username
    )


async def add_login_log(
    db: AsyncSession, *, user_id: int, ip_address: str, user_agent: str
) -> None:
    await repository.add_login_log(
        db, user_id=user_id, ip_address=ip_address, user_agent=user_agent
    )


async def update_profile(
    db: AsyncSession, *, user: User, update_data: ProfileUpdate
) -> User:
    if update_data.username and update_data.username != user.username:
        existing = await repository.get_active_user_by_username(
            db,
            username=update_data.username,
            exclude_user_id=user.id,
        )
        if existing:
            raise UsernameConflictError

    if update_data.email and update_data.email != user.email:
        existing = await repository.get_active_user_by_email(
            db,
            email=update_data.email,
            exclude_user_id=user.id,
        )
        if existing:
            raise EmailConflictError

    if update_data.username:
        user.username = update_data.username
    if update_data.email:
        user.email = update_data.email

    return await repository.save_user(db, user=user)


async def list_login_history(
    db: AsyncSession, *, user_id: int
) -> list[LoginLog]:
    return await repository.list_login_history(db, user_id=user_id)
