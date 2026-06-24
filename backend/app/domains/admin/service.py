"""Admin user management services."""

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_password_hash
from app.domains.admin import repository
from app.models.permission import Permission
from app.models.resource_permission import ResourcePermission
from app.models.role import Role
from app.models.user import User
from app.schemas.admin import (
    AdminUserUpdate,
    ResourcePermissionGrant,
    ResourcePermissionUpdate,
    RolePermissionUpdate,
    UserCreate,
)

StageDeleteSessions = Callable[[int, AsyncSession], Awaitable[None]]


class AdminUserError(Exception):
    """Base exception for admin user service errors."""


class UserNotFoundError(AdminUserError):
    """Raised when a requested user does not exist or is deleted."""


class UsernameConflictError(AdminUserError):
    """Raised when username is already used by an active user."""


class EmailConflictError(AdminUserError):
    """Raised when email is already used by an active user."""


class RoleBoundaryError(AdminUserError):
    """Raised when an admin attempts a forbidden role operation."""


class LastSuperAdminError(AdminUserError):
    """Raised when an operation would remove the final active super admin."""


class SelfDeleteError(AdminUserError):
    """Raised when a user tries to delete their own account."""


class AdminUserIntegrityError(AdminUserError):
    """Raised when persistence fails because of a uniqueness conflict."""

    def __init__(self, original: IntegrityError):
        self.original = original
        super().__init__(str(original))


class ResourcePermissionNotFoundError(AdminUserError):
    """Raised when a resource permission grant cannot be found."""


class ResourcePermissionConflictError(AdminUserError):
    """Raised when resource permission persistence hits a uniqueness conflict."""


class ResourcePermissionValidationError(AdminUserError):
    """Raised when resource permission input is invalid."""


class SubjectUserNotFoundError(AdminUserError):
    """Raised when a resource permission target user does not exist."""


class RoleNotFoundError(AdminUserError):
    """Raised when an RBAC role cannot be found."""


class UnknownPermissionError(AdminUserError):
    """Raised when an RBAC update references unknown permissions."""

    def __init__(self, missing: set[str]):
        self.missing = missing
        super().__init__(", ".join(sorted(missing)))


async def list_users(
    db: AsyncSession,
    *,
    search: str | None,
    role: str | None,
    page: int,
    page_size: int,
) -> tuple[list[User], int]:
    return await repository.list_users(
        db, search=search, role=role, page=page, page_size=page_size
    )


async def create_user(
    db: AsyncSession, *, user_data: UserCreate, actor: User
) -> User:
    if await repository.get_active_user_by_username(
        db, username=user_data.username
    ):
        raise UsernameConflictError
    if await repository.get_active_user_by_email(db, email=user_data.email):
        raise EmailConflictError
    if actor.role == "admin" and user_data.role == "super_admin":
        raise RoleBoundaryError

    return await repository.add_user(
        db,
        user=User(
            username=user_data.username,
            email=user_data.email,
            hashed_password=get_password_hash(user_data.password),
            role=user_data.role,
            is_active=True,
        ),
    )


async def get_user(db: AsyncSession, *, user_id: int) -> User:
    user = await repository.get_active_user(db, user_id=user_id)
    if not user:
        raise UserNotFoundError
    return user


async def get_user_for_update(
    db: AsyncSession,
    *,
    user_id: int,
    update_data: AdminUserUpdate,
) -> User:
    if update_data.is_active is True:
        user = await repository.get_user_by_id(db, user_id=user_id)
        if not user:
            raise UserNotFoundError
        return user
    return await get_user(db, user_id=user_id)


async def update_user(
    db: AsyncSession,
    *,
    user_id: int,
    update_data: AdminUserUpdate,
    actor: User,
    stage_delete_sessions: StageDeleteSessions,
) -> tuple[User, list[str]]:
    user = await get_user_for_update(db, user_id=user_id, update_data=update_data)

    if update_data.username is not None and update_data.username != user.username:
        if await repository.get_active_user_by_username(
            db, username=update_data.username, exclude_user_id=user_id
        ):
            raise UsernameConflictError

    if update_data.email is not None and update_data.email != user.email:
        if await repository.get_active_user_by_email(
            db, email=update_data.email, exclude_user_id=user_id
        ):
            raise EmailConflictError

    update_dict = update_data.model_dump(exclude_unset=True)

    if actor.role == "admin":
        if user.role == "super_admin":
            raise RoleBoundaryError("不能修改 super_admin 用户")
        if update_dict.get("role") == "super_admin":
            raise RoleBoundaryError("不能将用户提升为 super_admin")
        if actor.id == user_id and "role" in update_dict:
            raise RoleBoundaryError("不能修改自己的角色")

    if "is_active" in update_dict:
        if update_data.is_active is False:
            await _ensure_not_last_super_admin(db, user)
            user.is_active = False
            await stage_delete_sessions(user_id, db)
        elif update_data.is_active is True:
            user.deleted_at = None
            user.is_active = True
        del update_dict["is_active"]

    role_changed = (
        "role" in update_dict
        and update_dict["role"] is not None
        and update_dict["role"] != user.role
    )

    for field, value in update_dict.items():
        if value is not None:
            setattr(user, field, value)

    if role_changed:
        await stage_delete_sessions(user_id, db)

    try:
        await db.commit()
        await db.refresh(user)
    except IntegrityError as exc:
        await db.rollback()
        raise AdminUserIntegrityError(exc) from exc

    return user, list(update_dict.keys())


async def delete_user(
    db: AsyncSession,
    *,
    user_id: int,
    actor: User,
    stage_delete_sessions: StageDeleteSessions,
) -> User:
    if actor.id == user_id:
        raise SelfDeleteError

    user = await get_user(db, user_id=user_id)

    if actor.role == "admin" and user.role == "super_admin":
        raise RoleBoundaryError

    await _ensure_not_last_super_admin(db, user)

    user.deleted_at = datetime.now(UTC)
    user.is_active = False
    await stage_delete_sessions(user_id, db)
    await db.commit()
    return user


async def _ensure_not_last_super_admin(db: AsyncSession, user: User) -> None:
    if user.role != "super_admin":
        return
    active_super_count = await repository.count_active_super_admins(db)
    if active_super_count <= 1:
        raise LastSuperAdminError


async def list_audit_logs(
    db: AsyncSession,
    *,
    actor_user_id: int | None,
    action: str | None,
    page: int,
    page_size: int,
):
    return await repository.list_audit_logs(
        db,
        actor_user_id=actor_user_id,
        action=action,
        page=page,
        page_size=page_size,
    )


async def grant_resource_permissions(
    db: AsyncSession, *, grant: ResourcePermissionGrant, actor: User
) -> int:
    subject_user = await repository.get_active_user(db, user_id=grant.subject_id)
    if not subject_user:
        raise SubjectUserNotFoundError

    granted_count = 0
    for resource_id in grant.resource_ids:
        await repository.add_resource_permission(
            db,
            permission=ResourcePermission(
                subject_id=grant.subject_id,
                subject_type="user",
                resource_type=grant.resource_type,
                resource_id=resource_id,
                permission=grant.permission,
                granted_by=actor.id,
            ),
        )
        granted_count += 1

    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise ResourcePermissionConflictError from exc
    return granted_count


async def list_resource_permissions(
    db: AsyncSession,
    *,
    user_id: int | None,
    resource_type: str | None,
    page: int,
    page_size: int,
) -> tuple[list[ResourcePermission], int]:
    return await repository.list_resource_permissions(
        db,
        user_id=user_id,
        resource_type=resource_type,
        page=page,
        page_size=page_size,
    )


async def revoke_resource_permission(
    db: AsyncSession, *, permission_id: int
) -> dict[str, int | str]:
    permission = await repository.get_resource_permission(db, permission_id=permission_id)
    if not permission:
        raise ResourcePermissionNotFoundError

    details = {
        "subject_id": permission.subject_id,
        "resource_type": permission.resource_type,
        "resource_id": permission.resource_id,
        "permission": permission.permission,
    }
    await db.delete(permission)
    await db.commit()
    return details


async def update_resource_permission(
    db: AsyncSession,
    *,
    permission_id: int,
    update_data: ResourcePermissionUpdate,
) -> tuple[ResourcePermission, list[str]]:
    permission = await repository.get_resource_permission(db, permission_id=permission_id)
    if not permission:
        raise ResourcePermissionNotFoundError

    update_dict = update_data.model_dump(exclude_unset=True)
    if "resource_id" in update_dict and update_dict["resource_id"] == "":
        raise ResourcePermissionValidationError

    for field, value in update_dict.items():
        if value is not None:
            setattr(permission, field, value)

    try:
        await db.commit()
        await db.refresh(permission)
    except IntegrityError as exc:
        await db.rollback()
        raise ResourcePermissionConflictError from exc

    return permission, list(update_dict.keys())


async def get_role_permission_matrix(
    db: AsyncSession,
) -> tuple[list[Role], list[Permission]]:
    roles = await repository.list_roles_with_permissions(db)
    permissions = await repository.list_permissions(db)
    return roles, permissions


async def update_role_permissions(
    db: AsyncSession, *, role_name: str, update_data: RolePermissionUpdate
) -> tuple[Role, list[Permission]]:
    role = await repository.get_role_with_permissions(db, role_name=role_name)
    if not role:
        raise RoleNotFoundError

    if update_data.permissions:
        permissions = await repository.list_permissions_by_names(
            db, names=update_data.permissions
        )
        found_names = {permission.name for permission in permissions}
        missing = set(update_data.permissions) - found_names
        if missing:
            raise UnknownPermissionError(missing)
        role.permissions = list(permissions)
    else:
        role.permissions = []
        permissions = []

    await db.commit()
    return role, permissions
