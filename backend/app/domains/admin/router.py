"""Admin API routes for user management."""
import logging

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.audit import log_audit_from_request
from app.core.permissions import require_permission
from app.core.security import stage_delete_user_sessions
from app.database import get_db
from app.domains.admin import service
from app.models.user import User
from app.schemas.admin import (
    AdminUserListResponse,
    AdminUserResponse,
    AdminUserUpdate,
    AuditLogListResponse,
    AuditLogResponse,
    PermissionResponse,
    ResourcePermissionGrant,
    ResourcePermissionGrantResponse,
    ResourcePermissionListResponse,
    ResourcePermissionResponse,
    ResourcePermissionUpdate,
    RolePermissionMatrixResponse,
    RolePermissionResponse,
    RolePermissionUpdate,
    RolePermissionUpdateResponse,
    UserCreate,
)
from app.schemas.auth import MessageResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin/users", tags=["admin"])

# Second router for non-user-specific admin endpoints
admin_router = APIRouter(prefix="/admin", tags=["admin"])


def _admin_user_error_response(exc: service.AdminUserError) -> HTTPException:
    if isinstance(exc, service.UserNotFoundError):
        return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    if isinstance(exc, service.UsernameConflictError):
        return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="用户名已存在")
    if isinstance(exc, service.EmailConflictError):
        return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="邮箱已被使用")
    if isinstance(exc, service.LastSuperAdminError):
        return HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="不能删除最后一个活跃的 super_admin",
        )
    if isinstance(exc, service.SelfDeleteError):
        return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="不能删除自己的账号")
    if isinstance(exc, service.RoleBoundaryError):
        detail = str(exc) or "权限不足：不能删除 super_admin 用户"
        if "不能修改 super_admin 用户" in detail:
            detail = "权限不足：不能修改 super_admin 用户"
        elif "不能将用户提升为 super_admin" in detail:
            detail = "权限不足：不能将用户提升为 super_admin"
        elif "不能修改自己的角色" in detail:
            detail = "权限不足：不能修改自己的角色"
        elif not str(exc):
            detail = "权限不足：不能删除 super_admin 用户"
        return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=detail)
    if isinstance(exc, service.AdminUserIntegrityError):
        error_msg = str(exc.original.orig).lower()
        if "username" in error_msg:
            return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="用户名已存在")
        if "email" in error_msg:
            return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="邮箱已被使用")
        return HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="数据冲突，请检查用户名或邮箱是否已被使用",
        )
    return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="请求处理失败")


@router.get("", response_model=AdminUserListResponse)
async def list_users(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    search: str | None = Query(None, description="搜索用户名或邮箱"),
    role: str | None = Query(None, description="按角色过滤"),
    current_user: User = Depends(require_permission("user:read")),
    db: AsyncSession = Depends(get_db),
):
    """Get paginated list of users (non-deleted only)."""
    users, total = await service.list_users(
        db,
        search=search,
        role=role,
        page=page,
        page_size=page_size,
    )
    return AdminUserListResponse(
        items=[AdminUserResponse.model_validate(u) for u in users],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.post("", response_model=AdminUserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    request: Request,
    current_user: User = Depends(require_permission("user:manage")),
    db: AsyncSession = Depends(get_db),
):
    """Create a new user (admin only)."""
    try:
        new_user = await service.create_user(db, user_data=user_data, actor=current_user)
    except service.RoleBoundaryError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="权限不足：仅 super_admin 可创建 super_admin 用户",
        ) from exc
    except service.AdminUserError as exc:
        raise _admin_user_error_response(exc) from exc

    await log_audit_from_request(
        request,
        db,
        action="user.create",
        actor_user_id=current_user.id,
        target_type="user",
        target_id=new_user.id,
        details={
            "username": new_user.username,
            "email": new_user.email,
            "role": new_user.role,
        },
        commit=True,
    )

    logger.info(f"Admin {current_user.username} created user: {user_data.username}")
    return AdminUserResponse.model_validate(new_user)


@router.get("/{user_id}", response_model=AdminUserResponse)
async def get_user(
    user_id: int,
    current_user: User = Depends(require_permission("user:read")),
    db: AsyncSession = Depends(get_db),
):
    """Get a single user by ID (non-deleted only)."""
    try:
        user = await service.get_user(db, user_id=user_id)
    except service.AdminUserError as exc:
        raise _admin_user_error_response(exc) from exc

    return AdminUserResponse.model_validate(user)


@router.patch("/{user_id}", response_model=AdminUserResponse)
async def update_user(
    user_id: int,
    update_data: AdminUserUpdate,
    request: Request,
    current_user: User = Depends(require_permission("user:manage")),
    db: AsyncSession = Depends(get_db),
):
    """Update a user (admin only). Includes soft delete/restore via is_active."""
    try:
        user, changed_fields = await service.update_user(
            db,
            user_id=user_id,
            update_data=update_data,
            actor=current_user,
            stage_delete_sessions=stage_delete_user_sessions,
        )
    except service.AdminUserIntegrityError as exc:
        logger.error(f"IntegrityError in update_user: {exc.original}")
        raise _admin_user_error_response(exc) from exc
    except service.AdminUserError as exc:
        raise _admin_user_error_response(exc) from exc

    await log_audit_from_request(
        request,
        db,
        action="user.update",
        actor_user_id=current_user.id,
        target_type="user",
        target_id=user.id,
        details={"changed_fields": changed_fields},
        commit=True,
    )

    return AdminUserResponse.model_validate(user)


@router.delete("/{user_id}", response_model=MessageResponse)
async def delete_user(
    user_id: int,
    request: Request,
    current_user: User = Depends(require_permission("user:delete")),
    db: AsyncSession = Depends(get_db),
):
    """Soft delete a user and clean up their sessions (admin only)."""
    try:
        user = await service.delete_user(
            db,
            user_id=user_id,
            actor=current_user,
            stage_delete_sessions=stage_delete_user_sessions,
        )
    except service.AdminUserError as exc:
        raise _admin_user_error_response(exc) from exc

    await log_audit_from_request(
        request,
        db,
        action="user.delete",
        actor_user_id=current_user.id,
        target_type="user",
        target_id=user.id,
        details={"username": user.username},
        commit=True,
    )

    logger.info(f"Admin {current_user.username} deleted user: {user.username}")
    return MessageResponse(message="用户已删除")


# ── Audit Log Endpoints ───────────────────────────────────────────

@admin_router.get("/audit-logs", response_model=AuditLogListResponse)
async def list_audit_logs(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    actor_user_id: int | None = Query(None, description="按操作者过滤"),
    action: str | None = Query(None, description="按操作类型过滤"),
    current_user: User = Depends(require_permission("user:read")),
    db: AsyncSession = Depends(get_db),
):
    """Get paginated audit logs."""
    logs, total = await service.list_audit_logs(
        db,
        actor_user_id=actor_user_id,
        action=action,
        page=page,
        page_size=page_size,
    )
    return AuditLogListResponse(
        items=[AuditLogResponse.model_validate(log) for log in logs],
        total=total,
        page=page,
        page_size=page_size,
    )


# ── Resource Permission Endpoints ────────────────────────────────

@admin_router.post(
    "/resource-permissions",
    response_model=ResourcePermissionGrantResponse,
    status_code=status.HTTP_201_CREATED,
)
async def grant_resource_permission(
    grant: ResourcePermissionGrant,
    request: Request,
    current_user: User = Depends(require_permission("user:manage")),
    db: AsyncSession = Depends(get_db),
):
    """Grant one or more resource permissions to a user."""
    try:
        granted_count = await service.grant_resource_permissions(
            db, grant=grant, actor=current_user
        )
    except service.SubjectUserNotFoundError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="目标用户不存在或已删除",
        ) from exc
    except service.ResourcePermissionConflictError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="权限授予失败，所有变更已回滚",
        ) from exc

    await log_audit_from_request(
        request,
        db,
        action="permission.grant",
        actor_user_id=current_user.id,
        target_type="resource_permission",
        target_id=None,
        details={
            "subject_id": grant.subject_id,
            "resource_type": grant.resource_type,
            "resource_ids": grant.resource_ids,
            "permission": grant.permission,
            "count": granted_count,
        },
        commit=True,
    )

    return {"granted": granted_count}


@admin_router.get(
    "/resource-permissions",
    response_model=ResourcePermissionListResponse,
)
async def list_resource_permissions(
    user_id: int | None = Query(None, description="过滤：指定用户 ID"),
    resource_type: str | None = Query(None, pattern="^(product|job|user)$"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_permission("user:read")),
    db: AsyncSession = Depends(get_db),
):
    """List resource permission grants."""
    items, total = await service.list_resource_permissions(
        db,
        user_id=user_id,
        resource_type=resource_type,
        page=page,
        page_size=page_size,
    )
    return ResourcePermissionListResponse(
        items=[ResourcePermissionResponse.model_validate(item) for item in items],
        total=total,
        page=page,
        page_size=page_size,
    )


@admin_router.delete(
    "/resource-permissions/{permission_id}",
    response_model=MessageResponse,
    responses={404: {"model": MessageResponse}},
)
async def revoke_resource_permission(
    permission_id: int,
    request: Request,
    current_user: User = Depends(require_permission("user:manage")),
    db: AsyncSession = Depends(get_db),
):
    """Revoke a resource permission grant."""
    try:
        details = await service.revoke_resource_permission(
            db, permission_id=permission_id
        )
    except service.ResourcePermissionNotFoundError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="资源权限不存在",
        ) from exc

    await log_audit_from_request(
        request,
        db,
        action="permission.revoke",
        actor_user_id=current_user.id,
        target_type="resource_permission",
        target_id=permission_id,
        details=details,
        commit=True,
    )

    return {"message": "Resource permission revoked"}


@admin_router.patch(
    "/resource-permissions/{permission_id}",
    response_model=ResourcePermissionResponse,
)
async def update_resource_permission(
    permission_id: int,
    update_data: ResourcePermissionUpdate,
    request: Request,
    current_user: User = Depends(require_permission("user:manage")),
    db: AsyncSession = Depends(get_db),
):
    """Update an existing resource permission grant (resource_type, resource_id, permission)."""
    try:
        permission, updated_fields = await service.update_resource_permission(
            db, permission_id=permission_id, update_data=update_data
        )
    except service.ResourcePermissionNotFoundError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="资源权限不存在",
        ) from exc
    except service.ResourcePermissionValidationError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="资源 ID 不能为空",
        ) from exc
    except service.ResourcePermissionConflictError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="资源权限已存在，修改失败",
        ) from exc

    await log_audit_from_request(
        request,
        db,
        action="permission.update",
        actor_user_id=current_user.id,
        target_type="resource_permission",
        target_id=permission_id,
        details={"updated_fields": updated_fields},
        commit=True,
    )

    return ResourcePermissionResponse.model_validate(permission)


# ── RBAC Role-Permission Matrix Endpoints ─────────────────────────

@admin_router.get("/roles/permissions", response_model=RolePermissionMatrixResponse)
async def get_role_permission_matrix(
    current_user: User = Depends(require_permission("rbac:read")),
    db: AsyncSession = Depends(get_db),
):
    """Get the full role-permission matrix.

    Returns all roles with their assigned permissions, plus the list of all permissions.
    """
    roles, all_permissions = await service.get_role_permission_matrix(db)

    role_responses = []
    for role in roles:
        role_responses.append(
            RolePermissionResponse(
                role=role.name,
                description=role.description,
                permissions=sorted(p.name for p in role.permissions),
            )
        )

    return RolePermissionMatrixResponse(
        roles=role_responses,
        all_permissions=[
            PermissionResponse(name=p.name, description=p.description)
            for p in all_permissions
        ],
    )


@admin_router.patch(
    "/roles/{role_name}/permissions",
    response_model=RolePermissionUpdateResponse,
)
async def update_role_permissions(
    role_name: str,
    update_data: RolePermissionUpdate,
    request: Request,
    current_user: User = Depends(require_permission("rbac:manage")),
    db: AsyncSession = Depends(get_db),
):
    """Update permissions for a given role.

    Only super_admin can modify role permissions.
    """
    try:
        role, perms = await service.update_role_permissions(
            db, role_name=role_name, update_data=update_data
        )
    except service.RoleNotFoundError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="角色不存在",
        ) from exc
    except service.UnknownPermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"未知权限: {', '.join(sorted(exc.missing))}",
        ) from exc

    await log_audit_from_request(
        request,
        db,
        action="rbac.role_permissions_update",
        actor_user_id=current_user.id,
        target_type="role",
        target_id=role.id,
        details={"role": role_name, "permissions": update_data.permissions},
        commit=True,
    )

    return {
        "role": role_name,
        "permissions": [p.name for p in perms],
    }
