"""Blog API router."""

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
    Response,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import (
    permission_exists,
    require_permission,
    role_has_permission,
)
from app.database import get_db
from app.domains.blog import service
from app.models.user import User
from app.schemas.blog import (
    BlogCategoryResponse,
    BlogMediaResponse,
    BlogPostCreate,
    BlogPostListResponse,
    BlogPostResponse,
    BlogPostStatus,
    BlogPostUpdate,
    BlogTagResponse,
)

router = APIRouter(prefix="/blog", tags=["blog"])
media_router = APIRouter(prefix="/blog-media", tags=["blog-media"])


def _not_found(exc: service.BlogPostNotFoundError) -> HTTPException:
    return HTTPException(status_code=404, detail="Blog post not found")


async def _ensure_publish_permission(db: AsyncSession, current_user: User) -> None:
    permission = "blog:publish"
    if await role_has_permission(db, current_user.role, permission):
        return
    if not await permission_exists(db, permission):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"未知权限: {permission}",
        )
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="权限不足")


@router.get("/posts", response_model=BlogPostListResponse)
async def list_public_posts(
    keyword: str | None = Query(default=None, max_length=200),
    category: str | None = Query(default=None, max_length=160),
    tag: str | None = Query(default=None, max_length=160),
    page: int = Query(default=1, ge=1),
    size: int = Query(default=10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_public_posts(
        db,
        keyword=keyword,
        category_slug=category,
        tag_slug=tag,
        page=page,
        size=size,
    )


@router.get("/posts/{slug}", response_model=BlogPostResponse)
async def get_public_post(
    slug: str,
    db: AsyncSession = Depends(get_db),
):
    try:
        return await service.get_public_post(db, slug=slug)
    except service.BlogPostNotFoundError as exc:
        raise _not_found(exc) from exc


@router.get("/categories", response_model=list[BlogCategoryResponse])
async def list_categories(db: AsyncSession = Depends(get_db)):
    return await service.repository.list_categories(db)


@router.get("/tags", response_model=list[BlogTagResponse])
async def list_tags(db: AsyncSession = Depends(get_db)):
    return await service.repository.list_tags(db)


@router.get("/admin/posts", response_model=BlogPostListResponse)
async def list_admin_posts(
    keyword: str | None = Query(default=None, max_length=200),
    status: BlogPostStatus | None = None,
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission("blog:read_admin")),
):
    return await service.list_admin_posts(
        db,
        keyword=keyword,
        status=status,
        page=page,
        size=size,
    )


@router.post("/admin/posts", response_model=BlogPostResponse, status_code=201)
async def create_admin_post(
    data: BlogPostCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission("blog:write")),
):
    if data.status != "draft":
        await _ensure_publish_permission(db, current_user)
    return await service.create_post(db, author_id=current_user.id, data=data)


@router.get("/admin/posts/{post_id}", response_model=BlogPostResponse)
async def get_admin_post(
    post_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission("blog:read_admin")),
):
    try:
        return await service.get_admin_post(db, post_id=post_id)
    except service.BlogPostNotFoundError as exc:
        raise _not_found(exc) from exc


@router.patch("/admin/posts/{post_id}", response_model=BlogPostResponse)
async def update_admin_post(
    post_id: int,
    data: BlogPostUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission("blog:write")),
):
    if data.status is not None:
        await _ensure_publish_permission(db, current_user)
    try:
        return await service.update_post(db, post_id=post_id, data=data)
    except service.BlogPostNotFoundError as exc:
        raise _not_found(exc) from exc


@router.delete("/admin/posts/{post_id}", status_code=204)
async def delete_admin_post(
    post_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission("blog:write")),
):
    try:
        await service.delete_post(db, post_id=post_id)
    except service.BlogPostNotFoundError as exc:
        raise _not_found(exc) from exc
    return Response(status_code=204)


@router.post("/admin/uploads", response_model=BlogMediaResponse, status_code=201)
async def upload_blog_media(
    file: UploadFile,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission("blog:write")),
):
    try:
        return await service.save_upload(db, uploader_id=current_user.id, file=file)
    except service.BlogMediaTypeError as exc:
        raise HTTPException(status_code=400, detail="Unsupported blog media type") from exc
    except service.BlogMediaTooLargeError as exc:
        raise HTTPException(status_code=413, detail="Blog media file is too large") from exc


@media_router.get("/{file_name:path}")
async def get_blog_media(file_name: str):
    try:
        path = service.resolve_media_path(file_name)
    except service.BlogMediaPathError as exc:
        raise HTTPException(status_code=400, detail="Invalid blog media path") from exc
    if not path.exists() or not path.is_file():
        raise HTTPException(status_code=404, detail="Blog media not found")
    return FileResponse(path)
