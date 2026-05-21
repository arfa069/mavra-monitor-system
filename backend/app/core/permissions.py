"""Permission-based access control using FastAPI dependencies.

This module provides fine-grained permission checks beyond simple role-based
access. Permissions are checked via FastAPI Depends() to ensure consistent
security across all routers.
"""
from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.database import get_db
from app.models.permission import Permission
from app.models.role import Role, role_permissions
from app.models.user import User

# Static permission matrix (kept for reference / fallback)
PERMISSIONS = {
    "user:read": {"admin", "super_admin"},
    "user:manage": {"admin", "super_admin"},
    "user:delete": {"admin", "super_admin"},
    "crawl:execute": {"user", "super_admin"},
    "crawl:read_logs": {"user", "admin", "super_admin"},
    "schedule:read": {"user", "admin", "super_admin"},
    "schedule:configure": {"super_admin"},
    "config:read": {"admin", "super_admin"},
    "config:write": {"user", "admin", "super_admin"},
    "product:read": {"super_admin"},
    "product:write": {"super_admin"},
    "product:delete": {"super_admin"},
    "job:read": {"super_admin"},
    "job:write": {"super_admin"},
    "job:delete": {"super_admin"},
    "rbac:read": {"super_admin"},
    "rbac:manage": {"super_admin"},
}


async def permission_exists(db: AsyncSession, permission: str) -> bool:
    """Check if a permission name exists in the database."""
    result = await db.execute(
        select(Permission.id).where(Permission.name == permission).limit(1)
    )
    return result.scalar_one_or_none() is not None


async def role_has_permission(db: AsyncSession, role_name: str, permission: str) -> bool:
    """Check if a role has a specific permission in the database."""
    result = await db.execute(
        select(Permission.id)
        .select_from(Role)
        .join(role_permissions, role_permissions.c.role_id == Role.id)
        .join(Permission, Permission.id == role_permissions.c.permission_id)
        .where(Role.name == role_name, Permission.name == permission)
        .limit(1)
    )
    return result.scalar_one_or_none() is not None


async def get_role_permissions(db: AsyncSession, role_name: str) -> list[str]:
    """Get all permission names for a given role, sorted alphabetically."""
    result = await db.execute(
        select(Permission.name)
        .select_from(Role)
        .join(role_permissions, role_permissions.c.role_id == Role.id)
        .join(Permission, Permission.id == role_permissions.c.permission_id)
        .where(Role.name == role_name)
        .order_by(Permission.name)
    )
    return list(result.scalars().all())


def require_permission(permission: str):
    """Return a FastAPI dependency that checks if the user has the given permission.

    Usage:
        @router.post("/crawl-now", dependencies=[Depends(require_permission("crawl:execute"))])
    """
    async def checker(
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ) -> User:
        if await role_has_permission(db, current_user.role, permission):
            return current_user
        if not await permission_exists(db, permission):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"未知权限: {permission}",
            )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="权限不足",
        )
    return checker
