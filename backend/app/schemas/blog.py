"""Blog API schemas."""

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

BlogPostStatus = Literal["draft", "scheduled", "published", "archived"]


class BlogCategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    slug: str
    description: str | None = None


class BlogTagResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    slug: str


class BlogMediaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    file_name: str
    original_name: str
    content_type: str
    size_bytes: int
    public_url: str
    created_at: datetime


class BlogPostCreate(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    slug: str | None = Field(default=None, min_length=1, max_length=255)
    excerpt: str | None = Field(default=None, max_length=2000)
    content_json: dict[str, Any] = Field(default_factory=dict)
    content_html: str = Field(default="", max_length=500_000)
    status: BlogPostStatus = "draft"
    category_id: int | None = None
    category_name: str | None = Field(default=None, min_length=1, max_length=120)
    tag_ids: list[int] = Field(default_factory=list)
    tag_names: list[str] = Field(default_factory=list)
    cover_url: str | None = Field(default=None, max_length=1000)
    cover_media_id: int | None = None
    seo_title: str | None = Field(default=None, max_length=255)
    seo_description: str | None = Field(default=None, max_length=500)
    canonical_url: str | None = Field(default=None, max_length=1000)
    og_image_url: str | None = Field(default=None, max_length=1000)
    published_at: datetime | None = None

    @field_validator("tag_names")
    @classmethod
    def normalize_tag_names(cls, value: list[str]) -> list[str]:
        return [item.strip() for item in value if item.strip()]


class BlogPostUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    slug: str | None = Field(default=None, min_length=1, max_length=255)
    excerpt: str | None = Field(default=None, max_length=2000)
    content_json: dict[str, Any] | None = None
    content_html: str | None = Field(default=None, max_length=500_000)
    status: BlogPostStatus | None = None
    category_id: int | None = None
    category_name: str | None = Field(default=None, min_length=1, max_length=120)
    tag_ids: list[int] | None = None
    tag_names: list[str] | None = None
    cover_url: str | None = Field(default=None, max_length=1000)
    cover_media_id: int | None = None
    seo_title: str | None = Field(default=None, max_length=255)
    seo_description: str | None = Field(default=None, max_length=500)
    canonical_url: str | None = Field(default=None, max_length=1000)
    og_image_url: str | None = Field(default=None, max_length=1000)
    published_at: datetime | None = None

    @field_validator("tag_names")
    @classmethod
    def normalize_optional_tag_names(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None
        return [item.strip() for item in value if item.strip()]


class BlogPostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    slug: str
    excerpt: str | None = None
    content_json: dict[str, Any]
    content_html: str
    content_text: str
    status: BlogPostStatus
    cover_url: str | None = None
    seo_title: str | None = None
    seo_description: str | None = None
    canonical_url: str | None = None
    og_image_url: str | None = None
    published_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
    category: BlogCategoryResponse | None = None
    tags: list[BlogTagResponse] = Field(default_factory=list)


class BlogPostListItem(BaseModel):
    id: int
    title: str
    slug: str
    excerpt: str | None = None
    status: BlogPostStatus
    cover_url: str | None = None
    seo_title: str | None = None
    seo_description: str | None = None
    published_at: datetime | None = None
    updated_at: datetime
    category: BlogCategoryResponse | None = None
    tags: list[BlogTagResponse] = Field(default_factory=list)


class BlogPostListResponse(BaseModel):
    items: list[BlogPostListItem]
    total: int
    page: int
    size: int
