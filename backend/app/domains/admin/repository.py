"""Admin domain data access helpers."""

from inspect import isawaitable

from sqlalchemy import and_, func, or_, select, true
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.audit_log import UserAuditLog
from app.models.permission import Permission
from app.models.resource_permission import ResourcePermission
from app.models.role import Role
from app.models.user import User


async def list_users(
    db: AsyncSession,
    *,
    search: str | None,
    role: str | None,
    page: int,
    page_size: int,
) -> tuple[list[User], int]:
    base_filter = User.deleted_at.is_(None)

    if search:
        base_filter = and_(
            base_filter,
            or_(
                User.username.ilike(f"%{search}%"),
                User.email.ilike(f"%{search}%"),
            ),
        )

    if role:
        base_filter = and_(base_filter, User.role == role)

    count_result = await db.execute(select(func.count(User.id)).where(base_filter))
    total = count_result.scalar_one_or_none() or 0

    list_result = await db.execute(
        select(User)
        .where(base_filter)
        .order_by(User.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return list(list_result.scalars().all()), total


async def get_active_user(db: AsyncSession, *, user_id: int) -> User | None:
    result = await db.execute(
        select(User).where(and_(User.id == user_id, User.deleted_at.is_(None)))
    )
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, *, user_id: int) -> User | None:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def get_active_user_by_username(
    db: AsyncSession, *, username: str, exclude_user_id: int | None = None
) -> User | None:
    query = select(User).where(
        and_(User.username == username, User.deleted_at.is_(None))
    )
    if exclude_user_id is not None:
        query = query.where(User.id != exclude_user_id)
    result = await db.execute(query)
    return result.scalar_one_or_none()


async def get_active_user_by_email(
    db: AsyncSession, *, email: str, exclude_user_id: int | None = None
) -> User | None:
    query = select(User).where(and_(User.email == email, User.deleted_at.is_(None)))
    if exclude_user_id is not None:
        query = query.where(User.id != exclude_user_id)
    result = await db.execute(query)
    return result.scalar_one_or_none()


async def count_active_super_admins(db: AsyncSession) -> int:
    result = await db.execute(
        select(func.count(User.id)).where(
            User.role == "super_admin",
            User.is_active.is_(True),
            User.deleted_at.is_(None),
        )
    )
    return result.scalar_one_or_none() or 0


async def add_user(db: AsyncSession, *, user: User) -> User:
    added = db.add(user)
    if isawaitable(added):
        await added
    await db.commit()
    await db.refresh(user)
    return user


async def list_audit_logs(
    db: AsyncSession,
    *,
    actor_user_id: int | None,
    action: str | None,
    page: int,
    page_size: int,
) -> tuple[list[UserAuditLog], int]:
    base_filter = true()
    if actor_user_id is not None:
        base_filter = and_(base_filter, UserAuditLog.actor_user_id == actor_user_id)
    if action is not None:
        base_filter = and_(base_filter, UserAuditLog.action == action)

    count_result = await db.execute(select(func.count(UserAuditLog.id)).where(base_filter))
    total = count_result.scalar_one_or_none() or 0

    list_result = await db.execute(
        select(UserAuditLog)
        .where(base_filter)
        .order_by(UserAuditLog.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return list(list_result.scalars().all()), total


async def add_resource_permission(
    db: AsyncSession, *, permission: ResourcePermission
) -> None:
    added = db.add(permission)
    if isawaitable(added):
        await added


async def list_resource_permissions(
    db: AsyncSession,
    *,
    user_id: int | None,
    resource_type: str | None,
    page: int,
    page_size: int,
) -> tuple[list[ResourcePermission], int]:
    base_filter = true()
    if user_id is not None:
        base_filter = and_(base_filter, ResourcePermission.subject_id == user_id)
    if resource_type is not None:
        base_filter = and_(base_filter, ResourcePermission.resource_type == resource_type)

    total_result = await db.execute(
        select(func.count(ResourcePermission.id)).where(base_filter)
    )
    total = total_result.scalar_one_or_none() or 0

    result = await db.execute(
        select(ResourcePermission)
        .where(base_filter)
        .order_by(ResourcePermission.created_at.desc(), ResourcePermission.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return list(result.scalars().all()), total


async def get_resource_permission(
    db: AsyncSession, *, permission_id: int
) -> ResourcePermission | None:
    result = await db.execute(
        select(ResourcePermission).where(ResourcePermission.id == permission_id)
    )
    return result.scalar_one_or_none()


async def list_roles_with_permissions(db: AsyncSession) -> list[Role]:
    result = await db.execute(
        select(Role).options(selectinload(Role.permissions)).order_by(Role.name)
    )
    return list(result.scalars().all())


async def list_permissions(db: AsyncSession) -> list[Permission]:
    result = await db.execute(select(Permission).order_by(Permission.name))
    return list(result.scalars().all())


async def get_role_with_permissions(db: AsyncSession, *, role_name: str) -> Role | None:
    result = await db.execute(
        select(Role)
        .where(Role.name == role_name)
        .options(selectinload(Role.permissions))
    )
    return result.scalar_one_or_none()


async def list_permissions_by_names(
    db: AsyncSession, *, names: list[str]
) -> list[Permission]:
    result = await db.execute(select(Permission).where(Permission.name.in_(names)))
    return list(result.scalars().all())
