"""Admin API schemas."""
from datetime import datetime
from typing import Any

from pydantic import BaseModel, EmailStr, Field

from app.schemas.base import BaseResponseSchema


class AuditLogResponse(BaseResponseSchema):
    """Schema for audit log entries."""
    id: int
    actor_user_id: int | None
    action: str
    target_type: str | None
    target_id: int | None
    details: dict[str, Any] | None
    ip_address: str | None
    user_agent: str | None
    created_at: datetime


class AuditLogListResponse(BaseModel):
    """Schema for paginated audit log list."""
    items: list[AuditLogResponse]
    total: int
    page: int
    page_size: int


class UserCreate(BaseModel):
    """Schema for creating a user (admin)."""
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=100)
    role: str = Field(default="user")


class AdminUserUpdate(BaseModel):
    """Schema for admin updating a user (includes role and is_active)."""
    username: str | None = Field(default=None, min_length=3, max_length=50)
    email: EmailStr | None = None
    role: str | None = None
    is_active: bool | None = None  # True=恢复, False=软删除


class AdminUserResponse(BaseResponseSchema):
    """Schema for user response (admin)."""
    id: int
    username: str
    email: str
    role: str
    is_active: bool = True
    created_at: datetime


class AdminUserListResponse(BaseModel):
    """Schema for paginated user list."""
    items: list[AdminUserResponse]
    total: int
    page: int
    page_size: int


class ResourcePermissionGrant(BaseModel):
    """Schema for granting resource permissions."""
    subject_id: int = Field(..., description="被授权用户 ID")
    resource_type: str = Field(..., pattern="^(product|job|user)$")
    resource_ids: list[str] = Field(
        ..., min_length=1, description="资源 ID 列表，支持 '*' 表示全部"
    )
    permission: str = Field(..., pattern="^(read|write|delete|\\*)$")


class ResourcePermissionResponse(BaseResponseSchema):
    """Schema for a resource permission grant."""
    id: int
    subject_id: int
    subject_type: str
    resource_type: str
    resource_id: str
    permission: str
    granted_by: int
    created_at: datetime


class ResourcePermissionUpdate(BaseModel):
    """Schema for updating an existing resource permission."""
    resource_type: str | None = Field(default=None, pattern="^(product|job|user)$")
    resource_id: str | None = Field(default=None, max_length=255)
    permission: str | None = Field(default=None, pattern="^(read|write|delete|\\*)$")


class ResourcePermissionListResponse(BaseModel):
    """Paginated resource permission list."""
    items: list[ResourcePermissionResponse]
    total: int
    page: int
    page_size: int


class PermissionResponse(BaseModel):
    """Schema for a permission entry."""
    name: str
    description: str | None = None


class RolePermissionResponse(BaseModel):
    """Schema for a role with its permissions."""
    role: str
    description: str | None = None
    permissions: list[str]


class RolePermissionMatrixResponse(BaseModel):
    """Schema for the full role-permission matrix."""
    roles: list[RolePermissionResponse]
    all_permissions: list[PermissionResponse]


class RolePermissionUpdate(BaseModel):
    """Schema for updating a role's permissions."""
    permissions: list[str] = Field(default_factory=list)


class ResourcePermissionGrantResponse(BaseModel):
    granted: int


class RolePermissionUpdateResponse(BaseModel):
    role: str
    permissions: list[str]
