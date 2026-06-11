"""Blog data access helpers."""

from datetime import datetime

from sqlalchemy import and_, desc, func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.blog import BlogCategory, BlogMedia, BlogPost, BlogTag


def public_visibility_clause(now: datetime):
    return or_(
        BlogPost.status == "published",
        and_(BlogPost.status == "scheduled", BlogPost.published_at <= now),
    )


async def post_slug_exists(
    db: AsyncSession,
    slug: str,
    *,
    exclude_post_id: int | None = None,
) -> bool:
    query = select(BlogPost.id).where(BlogPost.slug == slug)
    if exclude_post_id is not None:
        query = query.where(BlogPost.id != exclude_post_id)
    result = await db.execute(query.limit(1))
    return result.scalar_one_or_none() is not None


async def get_category_by_slug(db: AsyncSession, slug: str) -> BlogCategory | None:
    result = await db.execute(select(BlogCategory).where(BlogCategory.slug == slug))
    return result.scalar_one_or_none()


async def get_tag_by_slug(db: AsyncSession, slug: str) -> BlogTag | None:
    result = await db.execute(select(BlogTag).where(BlogTag.slug == slug))
    return result.scalar_one_or_none()


async def get_or_create_category(
    db: AsyncSession,
    *,
    name: str,
    slug: str,
) -> BlogCategory:
    result = await db.execute(select(BlogCategory).where(BlogCategory.slug == slug))
    category = result.scalar_one_or_none()
    if category is not None:
        return category
    category = BlogCategory(name=name, slug=slug)
    db.add(category)
    await db.flush()
    return category


async def get_or_create_tags(
    db: AsyncSession,
    *,
    names_and_slugs: list[tuple[str, str]],
) -> list[BlogTag]:
    tags: list[BlogTag] = []
    for name, slug in names_and_slugs:
        result = await db.execute(select(BlogTag).where(BlogTag.slug == slug))
        tag = result.scalar_one_or_none()
        if tag is None:
            tag = BlogTag(name=name, slug=slug)
            db.add(tag)
            await db.flush()
        tags.append(tag)
    return tags


async def list_tags_by_ids(db: AsyncSession, tag_ids: list[int]) -> list[BlogTag]:
    if not tag_ids:
        return []
    result = await db.execute(select(BlogTag).where(BlogTag.id.in_(tag_ids)))
    return list(result.scalars().all())


async def get_category_by_id(
    db: AsyncSession,
    category_id: int,
) -> BlogCategory | None:
    result = await db.execute(select(BlogCategory).where(BlogCategory.id == category_id))
    return result.scalar_one_or_none()


def _apply_post_filters(
    query,
    *,
    keyword: str | None,
    status: str | None,
    category_slug: str | None,
    tag_slug: str | None,
):
    if status is not None:
        query = query.where(BlogPost.status == status)
    if category_slug is not None:
        query = query.join(BlogPost.category).where(BlogCategory.slug == category_slug)
    if tag_slug is not None:
        query = query.join(BlogPost.tags).where(BlogTag.slug == tag_slug)
    if keyword:
        escaped = keyword.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        pattern = f"%{escaped}%"
        query = query.outerjoin(BlogPost.category).outerjoin(BlogPost.tags).where(
            or_(
                BlogPost.title.ilike(pattern, escape="\\"),
                BlogPost.excerpt.ilike(pattern, escape="\\"),
                BlogPost.content_text.ilike(pattern, escape="\\"),
                BlogCategory.name.ilike(pattern, escape="\\"),
                BlogTag.name.ilike(pattern, escape="\\"),
            )
        ).distinct()
    return query


async def list_public_posts(
    db: AsyncSession,
    *,
    now: datetime,
    keyword: str | None,
    category_slug: str | None,
    tag_slug: str | None,
    page: int,
    size: int,
) -> tuple[list[BlogPost], int]:
    base_query = select(BlogPost).where(public_visibility_clause(now))
    base_query = _apply_post_filters(
        base_query,
        keyword=keyword,
        status=None,
        category_slug=category_slug,
        tag_slug=tag_slug,
    )

    count_result = await db.execute(
        select(func.count()).select_from(base_query.order_by(None).subquery())
    )
    total = count_result.scalar() or 0
    items_result = await db.execute(
        base_query.options(selectinload(BlogPost.category), selectinload(BlogPost.tags))
        .order_by(desc(BlogPost.published_at), desc(BlogPost.id))
        .offset((page - 1) * size)
        .limit(size)
    )
    return list(items_result.scalars().unique().all()), total


async def list_admin_posts(
    db: AsyncSession,
    *,
    keyword: str | None,
    status: str | None,
    page: int,
    size: int,
) -> tuple[list[BlogPost], int]:
    base_query = _apply_post_filters(
        select(BlogPost),
        keyword=keyword,
        status=status,
        category_slug=None,
        tag_slug=None,
    )
    count_result = await db.execute(
        select(func.count()).select_from(base_query.order_by(None).subquery())
    )
    total = count_result.scalar() or 0
    items_result = await db.execute(
        base_query.options(selectinload(BlogPost.category), selectinload(BlogPost.tags))
        .order_by(desc(BlogPost.updated_at), desc(BlogPost.id))
        .offset((page - 1) * size)
        .limit(size)
    )
    return list(items_result.scalars().unique().all()), total


async def get_public_post_by_slug(
    db: AsyncSession,
    *,
    slug: str,
    now: datetime,
) -> BlogPost | None:
    result = await db.execute(
        select(BlogPost)
        .where(BlogPost.slug == slug, public_visibility_clause(now))
        .options(selectinload(BlogPost.category), selectinload(BlogPost.tags))
    )
    return result.scalar_one_or_none()


async def get_post_by_id(db: AsyncSession, post_id: int) -> BlogPost | None:
    result = await db.execute(
        select(BlogPost)
        .where(BlogPost.id == post_id)
        .options(selectinload(BlogPost.category), selectinload(BlogPost.tags))
    )
    return result.scalar_one_or_none()


async def create_post(db: AsyncSession, post: BlogPost) -> BlogPost:
    db.add(post)
    await db.commit()
    await db.refresh(post, attribute_names=["category", "tags"])
    return post


async def save_post(db: AsyncSession, post: BlogPost) -> BlogPost:
    await db.commit()
    await db.refresh(post, attribute_names=["category", "tags"])
    return post


async def delete_post(db: AsyncSession, post: BlogPost) -> None:
    await db.delete(post)
    await db.commit()


async def list_categories(db: AsyncSession) -> list[BlogCategory]:
    result = await db.execute(select(BlogCategory).order_by(BlogCategory.name))
    return list(result.scalars().all())


async def list_tags(db: AsyncSession) -> list[BlogTag]:
    result = await db.execute(select(BlogTag).order_by(BlogTag.name))
    return list(result.scalars().all())


async def create_media(db: AsyncSession, media: BlogMedia) -> BlogMedia:
    db.add(media)
    await db.commit()
    await db.refresh(media)
    return media


async def publish_due_posts(db: AsyncSession, *, now: datetime) -> int:
    result = await db.execute(
        update(BlogPost)
        .where(BlogPost.status == "scheduled", BlogPost.published_at <= now)
        .values(status="published")
    )
    await db.commit()
    return int(result.rowcount or 0)
