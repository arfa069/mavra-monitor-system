from datetime import UTC, datetime, timedelta
from io import BytesIO
from types import SimpleNamespace

import pytest
from fastapi import UploadFile
from starlette.datastructures import Headers

from app.domains.blog import service


def test_sanitize_html_removes_scripts_and_event_handlers():
    raw_html = (
        "<h1>Hello</h1>"
        "<p onclick=\"alert('x')\">Welcome <strong>home</strong></p>"
        "<script>alert('xss')</script>"
        "<img src=\"/blog-media/cover.webp\" onerror=\"alert('x')\">"
    )

    cleaned = service.sanitize_content_html(raw_html)

    assert "<script" not in cleaned
    assert "onclick" not in cleaned
    assert "onerror" not in cleaned
    assert "<strong>home</strong>" in cleaned
    assert 'src="/blog-media/cover.webp"' in cleaned


def test_sanitize_html_falls_back_when_nh3_unavailable(monkeypatch):
    monkeypatch.setattr(service, "_nh3", None)
    raw_html = (
        "<p onclick=\"alert('x')\">Welcome <strong>home</strong></p>"
        "<a href=\"javascript:alert('x')\" title=\"bad\">bad link</a>"
        "<script>alert('xss')</script>"
    )

    cleaned = service.sanitize_content_html(raw_html)

    assert "<script" not in cleaned
    assert "alert('xss')" not in cleaned
    assert "onclick" not in cleaned
    assert "javascript:" not in cleaned
    assert "<strong>home</strong>" in cleaned
    assert 'title="bad"' in cleaned


@pytest.mark.asyncio
async def test_generate_unique_slug_adds_numeric_suffix(monkeypatch):
    seen_slugs = {"hello-world"}

    async def slug_exists(db, slug, **kwargs):
        return slug in seen_slugs

    monkeypatch.setattr(service.repository, "post_slug_exists", slug_exists)

    slug = await service.generate_unique_slug(
        SimpleNamespace(),
        title="Hello World!",
        requested_slug=None,
    )

    assert slug == "hello-world-2"


def test_is_publicly_visible_accepts_published_and_due_scheduled_posts():
    now = datetime(2026, 6, 10, 12, tzinfo=UTC)

    published = SimpleNamespace(status="published", published_at=now + timedelta(days=10))
    due_scheduled = SimpleNamespace(status="scheduled", published_at=now - timedelta(seconds=1))
    future_scheduled = SimpleNamespace(status="scheduled", published_at=now + timedelta(hours=1))
    draft = SimpleNamespace(status="draft", published_at=None)

    assert service.is_publicly_visible(published, now=now) is True
    assert service.is_publicly_visible(due_scheduled, now=now) is True
    assert service.is_publicly_visible(future_scheduled, now=now) is False
    assert service.is_publicly_visible(draft, now=now) is False


@pytest.mark.asyncio
async def test_save_upload_persists_supported_images(monkeypatch, tmp_path):
    monkeypatch.setattr(service.settings, "blog_media_root", str(tmp_path))
    monkeypatch.setattr(service.settings, "blog_media_public_prefix", "/blog-media")

    async def create_media(db, media):
        media.id = 1
        media.created_at = datetime(2026, 6, 10, 12, tzinfo=UTC)
        return media

    monkeypatch.setattr(service.repository, "create_media", create_media)

    upload = UploadFile(
        file=BytesIO(b"fake-image-bytes"),
        filename="cover.png",
        headers=Headers({"content-type": "image/png"}),
    )

    saved = await service.save_upload(SimpleNamespace(), uploader_id=7, file=upload)

    assert saved.id == 1
    assert saved.content_type == "image/png"
    assert saved.public_url.startswith("/blog-media/")
    stored_path = tmp_path / saved.file_name
    assert stored_path.read_bytes() == b"fake-image-bytes"
