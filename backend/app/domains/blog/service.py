"""Blog business logic."""

from __future__ import annotations

import re
import unicodedata
from datetime import UTC, datetime
from pathlib import Path
from uuid import uuid4

import nh3
from bs4 import BeautifulSoup
from fastapi import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.domains.blog import repository
from app.models.blog import BlogMedia, BlogPost
from app.schemas.blog import (
    BlogMediaResponse,
    BlogPostCreate,
    BlogPostListItem,
    BlogPostListResponse,
    BlogPostResponse,
    BlogPostUpdate,
)

ALLOWED_MEDIA_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}
ALLOWED_HTML_TAGS = {
    "a",
    "blockquote",
    "br",
    "code",
    "div",
    "em",
    "h1",
    "h2",
    "h3",
    "h4",
    "hr",
    "img",
    "li",
    "ol",
    "p",
    "pre",
    "s",
    "span",
    "strong",
    "u",
    "ul",
}
ALLOWED_HTML_ATTRIBUTES = {
    "a": {"href", "title", "target"},
    "img": {"src", "alt", "title", "width", "height"},
    "code": {"class"},
    "pre": {"class"},
    "span": {"class"},
}


class BlogPostNotFoundError(LookupError):
    pass


class BlogMediaTypeError(ValueError):
    pass


class BlogMediaTooLargeError(ValueError):
    pass


class BlogMediaPathError(ValueError):
    pass


def now_utc() -> datetime:
    return datetime.now(UTC)


def sanitize_content_html(raw_html: str) -> str:
    return nh3.clean(
        raw_html or "",
        tags=ALLOWED_HTML_TAGS,
        attributes=ALLOWED_HTML_ATTRIBUTES,
        clean_content_tags={"script", "style", "iframe", "object", "embed"},
        url_schemes={"http", "https", "mailto", ""},
    )


def html_to_text(html: str) -> str:
    soup = BeautifulSoup(html or "", "html.parser")
    return " ".join(soup.get_text(" ").split())


def slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFKC", value).strip().lower()
    normalized = re.sub(r"[^\w\u4e00-\u9fff]+", "-", normalized, flags=re.UNICODE)
    normalized = normalized.strip("-")
    return normalized or "post"


async def generate_unique_slug(
    db: AsyncSession,
    *,
    title: str,
    requested_slug: str | None,
    exclude_post_id: int | None = None,
) -> str:
    base_slug = slugify(requested_slug or title)
    slug = base_slug
    suffix = 2
    while await repository.post_slug_exists(db, slug, exclude_post_id=exclude_post_id):
        slug = f"{base_slug}-{suffix}"
        suffix += 1
    return slug


def is_publicly_visible(post: object, *, now: datetime | None = None) -> bool:
    current = now or now_utc()
    status = getattr(post, "status", None)
    published_at = getattr(post, "published_at", None)
    if status == "published":
        return True
    return bool(status == "scheduled" and published_at and published_at <= current)


def _post_to_list_item(post: BlogPost) -> BlogPostListItem:
    return BlogPostListItem(
        id=post.id,
        title=post.title,
        slug=post.slug,
        excerpt=post.excerpt,
        status=post.status,
        cover_url=post.cover_url,
        seo_title=post.seo_title,
        seo_description=post.seo_description,
        published_at=post.published_at,
        updated_at=post.updated_at,
        category=post.category,
        tags=list(post.tags or []),
    )


def _post_to_response(post: BlogPost) -> BlogPostResponse:
    return BlogPostResponse.model_validate(
        {
            **post.__dict__,
            "category": post.category,
            "tags": list(post.tags or []),
        }
    )


async def list_public_posts(
    db: AsyncSession,
    *,
    keyword: str | None = None,
    category_slug: str | None = None,
    tag_slug: str | None = None,
    page: int = 1,
    size: int = 10,
) -> BlogPostListResponse:
    items, total = await repository.list_public_posts(
        db,
        now=now_utc(),
        keyword=keyword,
        category_slug=category_slug,
        tag_slug=tag_slug,
        page=page,
        size=size,
    )
    return BlogPostListResponse(
        items=[_post_to_list_item(post) for post in items],
        total=total,
        page=page,
        size=size,
    )


async def list_admin_posts(
    db: AsyncSession,
    *,
    keyword: str | None = None,
    status: str | None = None,
    page: int = 1,
    size: int = 20,
) -> BlogPostListResponse:
    items, total = await repository.list_admin_posts(
        db,
        keyword=keyword,
        status=status,
        page=page,
        size=size,
    )
    return BlogPostListResponse(
        items=[_post_to_list_item(post) for post in items],
        total=total,
        page=page,
        size=size,
    )


async def get_public_post(db: AsyncSession, *, slug: str) -> BlogPostResponse:
    post = await repository.get_public_post_by_slug(db, slug=slug, now=now_utc())
    if post is None:
        raise BlogPostNotFoundError
    return _post_to_response(post)


async def get_admin_post(db: AsyncSession, *, post_id: int) -> BlogPostResponse:
    post = await repository.get_post_by_id(db, post_id)
    if post is None:
        raise BlogPostNotFoundError
    return _post_to_response(post)


async def _resolve_category(db: AsyncSession, *, data) -> object | None:
    if data.category_name:
        return await repository.get_or_create_category(
            db,
            name=data.category_name,
            slug=slugify(data.category_name),
        )
    if data.category_id is not None:
        return await repository.get_category_by_id(db, data.category_id)
    return None


async def _resolve_tags(db: AsyncSession, *, tag_ids: list[int], tag_names: list[str]):
    existing = await repository.list_tags_by_ids(db, tag_ids)
    created = await repository.get_or_create_tags(
        db,
        names_and_slugs=[(name, slugify(name)) for name in tag_names],
    )
    by_slug = {tag.slug: tag for tag in [*existing, *created]}
    return list(by_slug.values())


def _normalize_status_and_publish_time(status: str, published_at: datetime | None) -> datetime | None:
    if status == "published" and published_at is None:
        return now_utc()
    return published_at


async def create_post(
    db: AsyncSession,
    *,
    author_id: int,
    data: BlogPostCreate,
) -> BlogPostResponse:
    cleaned_html = sanitize_content_html(data.content_html)
    category = await _resolve_category(db, data=data)
    tags = await _resolve_tags(db, tag_ids=data.tag_ids, tag_names=data.tag_names)
    post = BlogPost(
        author_id=author_id,
        title=data.title,
        slug=await generate_unique_slug(db, title=data.title, requested_slug=data.slug),
        excerpt=data.excerpt,
        content_json=data.content_json,
        content_html=cleaned_html,
        content_text=html_to_text(cleaned_html),
        status=data.status,
        category=category,
        tags=tags,
        cover_url=data.cover_url,
        cover_media_id=data.cover_media_id,
        seo_title=data.seo_title,
        seo_description=data.seo_description,
        canonical_url=data.canonical_url,
        og_image_url=data.og_image_url,
        published_at=_normalize_status_and_publish_time(data.status, data.published_at),
    )
    return _post_to_response(await repository.create_post(db, post))


async def update_post(
    db: AsyncSession,
    *,
    post_id: int,
    data: BlogPostUpdate,
) -> BlogPostResponse:
    post = await repository.get_post_by_id(db, post_id)
    if post is None:
        raise BlogPostNotFoundError

    update_data = data.model_dump(exclude_unset=True)
    if "title" in update_data:
        post.title = data.title
    if "slug" in update_data or "title" in update_data:
        post.slug = await generate_unique_slug(
            db,
            title=post.title,
            requested_slug=data.slug or post.slug,
            exclude_post_id=post.id,
        )
    if data.content_html is not None:
        post.content_html = sanitize_content_html(data.content_html)
        post.content_text = html_to_text(post.content_html)
    if data.content_json is not None:
        post.content_json = data.content_json
    for field in (
        "excerpt",
        "status",
        "cover_url",
        "cover_media_id",
        "seo_title",
        "seo_description",
        "canonical_url",
        "og_image_url",
        "published_at",
    ):
        if field in update_data:
            setattr(post, field, getattr(data, field))
    if data.status is not None:
        post.published_at = _normalize_status_and_publish_time(data.status, post.published_at)
    if data.category_name is not None or data.category_id is not None:
        post.category = await _resolve_category(db, data=data)
    if data.tag_ids is not None or data.tag_names is not None:
        post.tags = await _resolve_tags(
            db,
            tag_ids=data.tag_ids or [],
            tag_names=data.tag_names or [],
        )
    return _post_to_response(await repository.save_post(db, post))


async def delete_post(db: AsyncSession, *, post_id: int) -> None:
    post = await repository.get_post_by_id(db, post_id)
    if post is None:
        raise BlogPostNotFoundError
    await repository.delete_post(db, post)


async def publish_due_posts(db: AsyncSession) -> int:
    return await repository.publish_due_posts(db, now=now_utc())


def media_root() -> Path:
    configured = Path(settings.blog_media_root)
    if configured.is_absolute():
        return configured
    backend_root = Path(__file__).resolve().parents[3]
    return backend_root / configured


def resolve_media_path(file_name: str) -> Path:
    if "/" in file_name or "\\" in file_name or Path(file_name).name != file_name:
        raise BlogMediaPathError
    root = media_root().resolve()
    candidate = (root / file_name).resolve()
    if candidate.parent != root:
        raise BlogMediaPathError
    return candidate


async def save_upload(
    db: AsyncSession,
    *,
    uploader_id: int,
    file: UploadFile,
) -> BlogMediaResponse:
    extension = ALLOWED_MEDIA_TYPES.get(file.content_type or "")
    if extension is None:
        raise BlogMediaTypeError

    data = await file.read(settings.blog_media_max_bytes + 1)
    if len(data) > settings.blog_media_max_bytes:
        raise BlogMediaTooLargeError

    root = media_root()
    root.mkdir(parents=True, exist_ok=True)
    file_name = f"{uuid4().hex}{extension}"
    path = resolve_media_path(file_name)
    path.write_bytes(data)
    media = BlogMedia(
        uploader_id=uploader_id,
        file_name=file_name,
        original_name=file.filename or file_name,
        content_type=file.content_type or "application/octet-stream",
        size_bytes=len(data),
        storage_path=str(path),
        public_url=f"{settings.blog_media_public_prefix}/{file_name}",
    )
    return BlogMediaResponse.model_validate(await repository.create_media(db, media))
