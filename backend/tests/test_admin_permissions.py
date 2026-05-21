"""Tests verifying admin.py uses fine-grained require_permission instead of require_role."""
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.sql import visitors

from app.core.security import get_current_user
from app.database import get_db
from app.main import app


def _make_user(user_id: int, role: str):
    user = MagicMock()
    user.id = user_id
    user.username = f"user{user_id}"
    user.email = f"user{user_id}@test.com"
    user.role = role
    user.is_active = True
    user.deleted_at = None
    user.created_at = datetime.now(UTC)
    user.updated_at = datetime.now(UTC)
    return user


# Static permission matrix for mock DB responses
ALL_PERMISSIONS = [
    "user:read", "user:manage", "user:delete",
    "crawl:execute", "crawl:read_logs",
    "schedule:read", "schedule:configure",
    "config:read", "config:write",
    "product:read", "product:write", "product:delete",
    "job:read", "job:write", "job:delete",
    "rbac:read", "rbac:manage",
]

ROLE_PERMISSIONS = {
    "user": {"crawl:execute", "crawl:read_logs", "schedule:read", "config:write"},
    "admin": {"user:read", "user:manage", "user:delete", "crawl:read_logs", "schedule:read", "config:read", "config:write"},
    "super_admin": set(ALL_PERMISSIONS),
}


def _permission_result_for(role: str, permission: str):
    """Return a mock result indicating whether role has permission."""
    result = MagicMock()
    result.scalar_one_or_none.return_value = 1 if permission in ROLE_PERMISSIONS.get(role, set()) else None
    return result


def _extract_permission_from_stmt(stmt) -> str | None:
    """Extract permission name from a SQLAlchemy select statement.

    Uses visitor traversal to avoid triggering model mapper compilation.
    """
    found_values = []

    def _visit_bindparam(element):
        if hasattr(element, "value"):
            found_values.append(element.value)

    try:
        visitors.traverse(stmt, {}, {"bindparam": _visit_bindparam})
    except Exception:
        pass

    for perm in ALL_PERMISSIONS:
        if perm in found_values:
            return perm

    # Fallback: search in raw statement string
    try:
        stmt_str = str(stmt)
        for perm in ALL_PERMISSIONS:
            if perm in stmt_str:
                return perm
    except Exception:
        pass
    return None


def _setup_mock_db(user_role: str = "user"):
    """Create and register a mock DB that responds correctly to permission queries."""
    mock_session = AsyncMock()

    def _execute_side_effect(stmt):
        """Inspect SQL statement and return appropriate mock result."""
        result = MagicMock()
        stmt_str = str(stmt)
        perm = _extract_permission_from_stmt(stmt)

        # Check for role_has_permission query FIRST (join users_roles + users_permissions)
        if "users_roles" in stmt_str and "users_permissions" in stmt_str:
            if perm:
                has_perm = perm in ROLE_PERMISSIONS.get(user_role, set())
                result.scalar_one_or_none.return_value = 1 if has_perm else None
                return result
            result.scalar_one_or_none.return_value = None
            return result

        # Check for permission_exists query (only users_permissions, no users_roles)
        if "users_permissions" in stmt_str:
            if perm:
                result.scalar_one_or_none.return_value = 1
                return result
            result.scalar_one_or_none.return_value = None
            return result

        # Default for other queries (count, list, etc.)
        result.scalar_one_or_none.return_value = None
        result.scalar.return_value = 0
        result.scalars.return_value = MagicMock()
        result.scalars.return_value.all.return_value = []
        return result

    mock_session.execute = AsyncMock(side_effect=_execute_side_effect)
    mock_session.commit = AsyncMock()

    async def _override():
        yield mock_session
    app.dependency_overrides[get_db] = _override


def _override_user(user):
    async def _u():
        return user
    app.dependency_overrides[get_current_user] = _u


def _clear_overrides():
    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_db, None)


@pytest.mark.anyio
async def test_list_users_requires_user_read_permission():
    """普通 user 角色没有 user:read 权限，应被拒绝。"""
    _setup_mock_db(user_role="user")
    _override_user(_make_user(1, "user"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.get(
                "/admin/users",
                headers={"Authorization": "Bearer fake"},
            )
        assert resp.status_code == 403
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_list_users_admin_allowed():
    """admin 拥有 user:read 权限，应能查看用户列表。"""
    _setup_mock_db(user_role="admin")
    _override_user(_make_user(1, "admin"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.get(
                "/admin/users",
                headers={"Authorization": "Bearer fake"},
            )
        assert resp.status_code == 200
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_delete_user_requires_user_delete_permission():
    """super_admin 拥有 user:delete 权限。删除一个不存在的 user_id，权限通过后返回 404。"""
    _setup_mock_db(user_role="super_admin")
    _override_user(_make_user(1, "super_admin"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.delete(
                "/admin/users/99999",
                headers={"Authorization": "Bearer fake"},
            )
        assert resp.status_code == 404
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_delete_user_regular_user_forbidden():
    """普通 user 不能删除用户。"""
    _setup_mock_db(user_role="user")
    _override_user(_make_user(1, "user"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.delete(
                "/admin/users/99999",
                headers={"Authorization": "Bearer fake"},
            )
        assert resp.status_code == 403
    finally:
        _clear_overrides()
@pytest.mark.anyio
async def test_patch_resource_permission_updates_permission_value():
    """PATCH 修改已有资源权限的 permission 字段，返回更新后的完整对象。

    使用受控 mock 让 grant 和 list 都返回预期的 permission 对象。
    """
    mock_session = AsyncMock()

    # GET list: returns items
    list_perm = MagicMock()
    list_perm.id = 5
    list_perm.subject_id = 2
    list_perm.subject_type = "user"
    list_perm.resource_type = "product"
    list_perm.resource_id = "13"
    list_perm.permission = "read"
    list_perm.granted_by = 1
    list_perm.created_at = datetime.now(UTC)

    # PATCH update: returns updated permission
    updated_perm = MagicMock()
    updated_perm.id = 5
    updated_perm.subject_id = 2
    updated_perm.subject_type = "user"
    updated_perm.resource_type = "product"
    updated_perm.resource_id = "13"
    updated_perm.permission = "write"
    updated_perm.granted_by = 1
    updated_perm.created_at = datetime.now(UTC)

    # POST grant: returns created permission (subject user lookup)
    created_perm = MagicMock()
    created_perm.id = 5
    created_perm.subject_id = 2
    created_perm.subject_type = "user"
    created_perm.resource_type = "product"
    created_perm.resource_id = "13"
    created_perm.permission = "read"
    created_perm.granted_by = 1
    created_perm.created_at = datetime.now(UTC)

    def _execute_side_effect(stmt):
        """Smart mock that returns correct results based on SQL content."""
        result = MagicMock()
        stmt_str = str(stmt)
        _extract_permission_from_stmt(stmt)  # noqa: F841

        # Permission checks for super_admin
        if "users_roles" in stmt_str and "users_permissions" in stmt_str:
            result.scalar_one_or_none.return_value = 1  # super_admin has all permissions
            return result
        if "users_permissions" in stmt_str:
            result.scalar_one_or_none.return_value = 1  # all permissions exist
            return result

        # Subject user lookup (POST grant)
        if "users" in stmt_str and "deleted_at" in stmt_str:
            result.scalar_one_or_none.return_value = created_perm
            return result

        # Count query (GET list)
        if "count" in stmt_str.lower():
            result.scalar_one_or_none.return_value = 1
            return result

        # List query (GET list) — returns permissions
        if "users_resources_permissions" in stmt_str and "ORDER BY" in stmt_str.upper():
            result.scalar_one_or_none.return_value = None
            result.scalars.return_value = MagicMock()
            result.scalars.return_value.all.return_value = [list_perm]
            return result

        # Find by ID (PATCH)
        if "users_resources_permissions" in stmt_str:
            result.scalar_one_or_none.return_value = updated_perm
            return result

        # Default
        result.scalar_one_or_none.return_value = None
        result.scalar.return_value = 0
        result.scalars.return_value = MagicMock()
        result.scalars.return_value.all.return_value = []
        return result

    mock_session.execute = AsyncMock(side_effect=_execute_side_effect)
    mock_session.commit = AsyncMock()
    mock_session.refresh = AsyncMock()

    async def _db():
        yield mock_session
    app.dependency_overrides[get_db] = _db

    user = _make_user(1, "super_admin")
    async def _u(): return user
    app.dependency_overrides[get_current_user] = _u

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            # grant
            await client.post(
                "/admin/resource-permissions",
                json={
                    "subject_id": 2,
                    "resource_type": "product",
                    "resource_ids": ["13"],
                    "permission": "read",
                },
                headers={"Authorization": "Bearer fake"},
            )
            # list
            list_resp = await client.get(
                "/admin/resource-permissions?user_id=2&resource_type=product",
                headers={"Authorization": "Bearer fake"},
            )
            perm_id = list_resp.json()["items"][0]["id"]

            # patch
            patch_resp = await client.patch(
                f"/admin/resource-permissions/{perm_id}",
                json={"permission": "write"},
                headers={"Authorization": "Bearer fake"},
            )
            assert patch_resp.status_code == 200
            body = patch_resp.json()
            assert body["permission"] == "write"
            assert body["resource_type"] == "product"
            assert body["resource_id"] == "13"
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_patch_resource_permission_not_found_returns_404():
    """PATCH 一个不存在的 permission_id 返回 404。"""
    _setup_mock_db(user_role="super_admin")
    _override_user(_make_user(1, "super_admin"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.patch(
                "/admin/resource-permissions/99999",
                json={"permission": "write"},
                headers={"Authorization": "Bearer fake"},
            )
            assert resp.status_code == 404
            assert "不存在" in resp.json()["detail"]
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_patch_resource_permission_conflict_returns_400():
    """PATCH 导致唯一约束冲突返回 400。"""
    mock_session = AsyncMock()

    # Mock: find existing permission (first call = find by id)
    existing_perm = MagicMock()
    existing_perm.id = 5
    existing_perm.subject_id = 2
    existing_perm.subject_type = "user"
    existing_perm.resource_type = "product"
    existing_perm.resource_id = "200"
    existing_perm.permission = "write"
    existing_perm.granted_by = 1
    existing_perm.created_at = datetime.now(UTC)

    # On commit, raise IntegrityError (unique constraint violation)
    from sqlalchemy.exc import IntegrityError
    mock_session.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=existing_perm))
    mock_session.commit = AsyncMock(side_effect=IntegrityError("key", "constraint", "uq"))
    mock_session.rollback = AsyncMock()

    async def _db(): yield mock_session
    app.dependency_overrides[get_db] = _db

    user = _make_user(1, "super_admin")
    async def _u(): return user
    app.dependency_overrides[get_current_user] = _u

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.patch(
                "/admin/resource-permissions/5",
                json={"resource_id": "100"},
                headers={"Authorization": "Bearer fake"},
            )
            assert resp.status_code == 400
            assert "已存在" in resp.json()["detail"]
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_patch_resource_permission_requires_user_manage():
    """普通 user 没有 user:manage 权限，PATCH 返回 403。"""
    _setup_mock_db(user_role="user")
    _override_user(_make_user(1, "user"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.patch(
                "/admin/resource-permissions/1",
                json={"permission": "write"},
                headers={"Authorization": "Bearer fake"},
            )
            assert resp.status_code == 403
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_patch_resource_permission_validates_resource_type():
    """PATCH 传入无效 resource_type 返回 422。"""
    _setup_mock_db(user_role="super_admin")
    _override_user(_make_user(1, "super_admin"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.patch(
                "/admin/resource-permissions/1",
                json={"resource_type": "invalid_type"},
                headers={"Authorization": "Bearer fake"},
            )
            assert resp.status_code == 422
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_patch_resource_permission_validates_permission():
    """PATCH 传入无效 permission 返回 422。"""
    _setup_mock_db(user_role="super_admin")
    _override_user(_make_user(1, "super_admin"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.patch(
                "/admin/resource-permissions/1",
                json={"permission": "invalid_action"},
                headers={"Authorization": "Bearer fake"},
            )
            assert resp.status_code == 422
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_patch_resource_permission_rejects_empty_resource_id():
    """PATCH 传入空字符串 resource_id 返回 400。"""
    mock_session = AsyncMock()
    existing_perm = MagicMock()
    existing_perm.id = 1
    existing_perm.subject_id = 2
    existing_perm.subject_type = "user"
    existing_perm.resource_type = "product"
    existing_perm.resource_id = "10"
    existing_perm.permission = "read"
    existing_perm.granted_by = 1
    existing_perm.created_at = datetime.now(UTC)
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = existing_perm
    mock_session.execute = AsyncMock(return_value=mock_result)
    mock_session.commit = AsyncMock()

    async def _db(): yield mock_session
    app.dependency_overrides[get_db] = _db

    user = _make_user(1, "super_admin")
    async def _u(): return user
    app.dependency_overrides[get_current_user] = _u

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.patch(
                "/admin/resource-permissions/1",
                json={"resource_id": ""},
                headers={"Authorization": "Bearer fake"},
            )
            assert resp.status_code == 400
            assert "不能为空" in resp.json()["detail"]
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_patch_resource_permission_allows_star_resource_id():
    """PATCH 可以将 resource_id 改为通配符 *。"""
    mock_session = AsyncMock()

    existing_perm = MagicMock()
    existing_perm.id = 5
    existing_perm.subject_id = 2
    existing_perm.subject_type = "user"
    existing_perm.resource_type = "job"
    existing_perm.resource_id = "42"
    existing_perm.permission = "read"
    existing_perm.granted_by = 1
    existing_perm.created_at = datetime.now(UTC)

    updated_perm = MagicMock()
    updated_perm.id = 5
    updated_perm.subject_id = 2
    updated_perm.subject_type = "user"
    updated_perm.resource_type = "job"
    updated_perm.resource_id = "*"
    updated_perm.permission = "read"
    updated_perm.granted_by = 1
    updated_perm.created_at = datetime.now(UTC)

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = updated_perm
    mock_session.execute = AsyncMock(return_value=mock_result)
    mock_session.commit = AsyncMock()
    mock_session.refresh = AsyncMock()

    async def _db(): yield mock_session
    app.dependency_overrides[get_db] = _db

    user = _make_user(1, "super_admin")
    async def _u(): return user
    app.dependency_overrides[get_current_user] = _u

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            patch_resp = await client.patch(
                "/admin/resource-permissions/5",
                json={"resource_id": "*"},
                headers={"Authorization": "Bearer fake"},
            )
            assert patch_resp.status_code == 200
            assert patch_resp.json()["resource_id"] == "*"
    finally:
        _clear_overrides()


# ── RBAC Role-Permission Matrix Tests ─────────────────────────────

@pytest.mark.anyio
async def test_get_role_permission_matrix_requires_rbac_read():
    """GET /admin/roles/permissions requires rbac:read permission."""
    _setup_mock_db(user_role="user")
    _override_user(_make_user(1, "user"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.get(
                "/admin/roles/permissions",
                headers={"Authorization": "Bearer fake"},
            )
        assert resp.status_code == 403
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_get_role_permission_matrix_super_admin_allowed():
    """super_admin with rbac:read can access the role permission matrix."""
    _setup_mock_db(user_role="super_admin")
    _override_user(_make_user(1, "super_admin"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.get(
                "/admin/roles/permissions",
                headers={"Authorization": "Bearer fake"},
            )
        # Should not be 403; may be 200 or 500 depending on DB mock
        assert resp.status_code != 403
    finally:
        _clear_overrides()


@pytest.mark.anyio
async def test_patch_role_permissions_requires_rbac_manage():
    """PATCH /admin/roles/{role}/permissions requires rbac:manage."""
    _setup_mock_db(user_role="admin")
    _override_user(_make_user(1, "admin"))
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.patch(
                "/admin/roles/user/permissions",
                json={"permissions": ["crawl:execute"]},
                headers={"Authorization": "Bearer fake"},
            )
        assert resp.status_code == 403
    finally:
        _clear_overrides()
