"""Authentication schemas for request/response validation."""
from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.core.passwords import validate_password_strength
from app.schemas._common import IsActiveFromDeletedAtMixin
from app.schemas.base import BaseResponseSchema


class UserRegister(BaseModel):
    """Request schema for user registration."""
    username: str = Field(..., min_length=3, max_length=50, description="用户名")
    email: EmailStr = Field(..., description="邮箱")
    password: str = Field(..., max_length=100, description="密码")

    @field_validator("username")
    @classmethod
    def validate_username(cls, v: str) -> str:
        """Validate username: alphanumeric and underscore only."""
        if not v.replace("_", "").replace("-", "").isalnum():
            raise ValueError("用户名只能包含字母、数字、下划线和连字符")
        return v.strip()

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        return validate_password_strength(v)


class UserLogin(BaseModel):
    """Request schema for user login."""
    username: str = Field(..., description="用户名")
    password: str = Field(..., description="密码")


class WeChatQrResponse(BaseModel):
    """Response schema for WeChat QR login bootstrap."""
    qr_url: str
    state: str


class WeChatBindRequest(BaseModel):
    """Request schema for binding WeChat to an existing account."""
    temp_token: str
    username: str
    password: str


class WeChatRegisterRequest(BaseModel):
    """Request schema for registering an account from a WeChat callback."""
    temp_token: str
    username: str = Field(..., min_length=3, max_length=50, description="用户名")
    email: EmailStr = Field(..., description="邮箱")
    password: str = Field(..., max_length=100, description="密码")

    @field_validator("username")
    @classmethod
    def validate_username(cls, v: str) -> str:
        """Validate username: alphanumeric and underscore only."""
        if not v.replace("_", "").replace("-", "").isalnum():
            raise ValueError("用户名只能包含字母、数字、下划线和连字符")
        return v.strip()

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        return validate_password_strength(v)


class UserResponse(IsActiveFromDeletedAtMixin, BaseResponseSchema):
    """Response schema for user information.

    is_active is a compatibility projection of deleted_at (not the DB column).
    """
    id: int
    username: str
    email: str
    role: str | None = None
    permissions: list[str] = Field(default_factory=list)
    is_active: bool = True
    created_at: datetime


class TokenResponse(BaseModel):
    """Response schema for authentication token."""
    access_token: str
    token_type: str = "bearer"


class ProfileUpdate(BaseModel):
    """Schema for updating current user's profile (username, email only)."""
    username: str | None = Field(default=None, min_length=3, max_length=50)
    email: EmailStr | None = None


class PasswordChange(BaseModel):
    """Schema for password change."""
    old_password: str
    new_password: str = Field(..., max_length=100)

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v: str) -> str:
        return validate_password_strength(v)


class MessageResponse(BaseModel):
    """Generic message response."""
    message: str


class LoginLogResponse(BaseResponseSchema):
    """Response schema for login history."""
    id: int
    ip_address: str | None
    user_agent: str | None
    created_at: datetime
