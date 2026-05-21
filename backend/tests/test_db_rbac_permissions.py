"""Tests for DB-backed RBAC permission checks."""
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from app.core.permissions import (
    get_role_permissions,
    require_permission,
    role_has_permission,
)
from app.models.user import User


def _user(role: str = "user") -> User:
    user = MagicMock(spec=User)
    user.id = 1
    user.role = role
    return user


def _result(value):
    result = MagicMock()
    result.scalar_one_or_none.return_value = value
    return result


@pytest.mark.asyncio
async def test_role_has_permission_true_when_role_permission_mapping_exists():
    db = AsyncMock()
    db.execute.return_value = _result(1)
    assert await role_has_permission(db, "admin", "user:read") is True


@pytest.mark.asyncio
async def test_role_has_permission_false_when_mapping_missing():
    db = AsyncMock()
    db.execute.return_value = _result(None)
    assert await role_has_permission(db, "admin", "crawl:execute") is False


@pytest.mark.asyncio
async def test_require_permission_allows_when_db_mapping_exists():
    db = AsyncMock()
    db.execute.return_value = _result(1)
    checker = require_permission("user:read")
    result = await checker(current_user=_user("admin"), db=db)
    assert result.role == "admin"


@pytest.mark.asyncio
async def test_require_permission_denies_when_db_mapping_missing():
    db = AsyncMock()
    db.execute.side_effect = [_result(None), _result(1)]
    checker = require_permission("crawl:execute")
    with pytest.raises(HTTPException) as exc:
        await checker(current_user=_user("admin"), db=db)
    assert exc.value.status_code == 403
    assert exc.value.detail == "权限不足"


@pytest.mark.asyncio
async def test_require_permission_unknown_permission_returns_500():
    db = AsyncMock()
    db.execute.side_effect = [_result(None), _result(None)]
    checker = require_permission("missing:permission")
    with pytest.raises(HTTPException) as exc:
        await checker(current_user=_user("admin"), db=db)
    assert exc.value.status_code == 500
    assert "未知权限" in exc.value.detail


@pytest.mark.asyncio
async def test_get_role_permissions_returns_sorted_permission_names():
    db = AsyncMock()
    result = MagicMock()
    result.scalars.return_value.all.return_value = ["config:read", "config:write", "user:read"]
    db.execute.return_value = result
    perms = await get_role_permissions(db, "admin")
    assert perms == ["config:read", "config:write", "user:read"]
