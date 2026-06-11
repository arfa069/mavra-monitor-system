from importlib import import_module
from types import SimpleNamespace

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_current_user
from app.database import get_db
from app.main import app
from app.models.user import User
from app.schemas.blog import BlogPostListResponse, BlogPostResponse

blog_router_module = import_module("app.domains.blog.router")


async def _db_override():
    yield SimpleNamespace()


def _user(role: str = "admin") -> User:
    return User(
        id=1,
        username="writer",
        email="writer@example.com",
        role=role,
        is_active=True,
    )


def _override_user(role: str = "admin") -> None:
    async def _current_user():
        return _user(role)

    app.dependency_overrides[get_current_user] = _current_user


def _clear_overrides() -> None:
    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_public_blog_posts_do_not_require_auth(monkeypatch):
    app.dependency_overrides[get_db] = _db_override

    async def list_public_posts(db, **kwargs):
        return BlogPostListResponse(items=[], total=0, page=1, size=10)

    async def fail_if_auth_is_called(*args, **kwargs):
        raise AssertionError("public blog list must not require auth")

    monkeypatch.setattr("app.domains.blog.service.list_public_posts", list_public_posts)
    app.dependency_overrides[get_current_user] = fail_if_auth_is_called

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.get("/v1/blog/posts")
    finally:
        _clear_overrides()

    assert response.status_code == 200
    assert response.json() == {"items": [], "total": 0, "page": 1, "size": 10}


@pytest.mark.asyncio
async def test_public_blog_post_detail_does_not_require_auth(monkeypatch):
    app.dependency_overrides[get_db] = _db_override

    async def get_public_post(db, **kwargs):
        return BlogPostResponse(
            id=1,
            title="Public note",
            slug="public-note",
            excerpt="Visible to everyone",
            content_json={"type": "doc", "content": []},
            content_html="<p>Hello</p>",
            content_text="Hello",
            status="published",
            cover_url=None,
            seo_title=None,
            seo_description=None,
            canonical_url=None,
            og_image_url=None,
            published_at=None,
            created_at="2026-06-10T00:00:00Z",
            updated_at="2026-06-10T00:00:00Z",
            category=None,
            tags=[],
        )

    async def fail_if_auth_is_called(*args, **kwargs):
        raise AssertionError("public blog detail must not require auth")

    monkeypatch.setattr("app.domains.blog.service.get_public_post", get_public_post)
    app.dependency_overrides[get_current_user] = fail_if_auth_is_called

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.get("/v1/blog/posts/public-note")
    finally:
        _clear_overrides()

    assert response.status_code == 200
    assert response.json()["slug"] == "public-note"


@pytest.mark.asyncio
async def test_admin_blog_create_requires_write_permission(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("user")

    async def deny_permission(db, role_name, permission):
        assert permission == "blog:write"
        return False

    async def permission_exists(db, permission):
        return True

    monkeypatch.setattr("app.core.permissions.role_has_permission", deny_permission)
    monkeypatch.setattr("app.core.permissions.permission_exists", permission_exists)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/v1/blog/admin/posts",
                json={
                    "title": "First post",
                    "content_json": {"type": "doc", "content": []},
                    "content_html": "<p>Hello</p>",
                    "status": "draft",
                },
            )
    finally:
        _clear_overrides()

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_admin_blog_publish_requires_publish_permission(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("admin")

    async def role_permission(db, role_name, permission):
        return permission == "blog:write"

    async def permission_exists(db, permission):
        return True

    monkeypatch.setattr("app.core.permissions.role_has_permission", role_permission)
    monkeypatch.setattr("app.core.permissions.permission_exists", permission_exists)
    monkeypatch.setattr(blog_router_module, "role_has_permission", role_permission)
    monkeypatch.setattr(blog_router_module, "permission_exists", permission_exists)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/v1/blog/admin/posts",
                json={
                    "title": "Launch post",
                    "content_json": {"type": "doc", "content": []},
                    "content_html": "<p>Hello</p>",
                    "status": "published",
                },
            )
    finally:
        _clear_overrides()

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_blog_upload_rejects_unsupported_content_type(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("admin")

    async def allow_permission(db, role_name, permission):
        return True

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/v1/blog/admin/uploads",
                files={"file": ("notes.txt", b"hello", "text/plain")},
            )
    finally:
        _clear_overrides()

    assert response.status_code == 400
    assert response.json()["detail"] == "Unsupported blog media type"


@pytest.mark.asyncio
async def test_blog_upload_rejects_too_large_files(monkeypatch):
    app.dependency_overrides[get_db] = _db_override
    _override_user("admin")

    async def allow_permission(db, role_name, permission):
        return True

    async def save_upload(*args, **kwargs):
        raise blog_router_module.service.BlogMediaTooLargeError

    monkeypatch.setattr("app.core.permissions.role_has_permission", allow_permission)
    monkeypatch.setattr("app.domains.blog.service.save_upload", save_upload)

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/v1/blog/admin/uploads",
                files={"file": ("cover.png", b"x" * 10, "image/png")},
            )
    finally:
        _clear_overrides()

    assert response.status_code == 413
    assert response.json()["detail"] == "Blog media file is too large"


@pytest.mark.asyncio
async def test_blog_media_rejects_path_traversal():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/blog-media/..%2Fsecret.png")

    assert response.status_code == 400
