"""Blog publishing models."""

from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Table,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from app.models.base import Base, TimestampMixin

blog_posts_tags = Table(
    "blog_posts_tags",
    Base.metadata,
    Column("post_id", ForeignKey("blog_posts.id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", ForeignKey("blog_tags.id", ondelete="CASCADE"), primary_key=True),
)


class BlogCategory(Base, TimestampMixin):
    """Public blog category."""

    __tablename__ = "blog_categories"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(120), nullable=False, unique=True)
    slug = Column(String(160), nullable=False, unique=True, index=True)
    description = Column(Text, nullable=True)

    posts = relationship("BlogPost", back_populates="category")


class BlogTag(Base, TimestampMixin):
    """Public blog tag."""

    __tablename__ = "blog_tags"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(120), nullable=False, unique=True)
    slug = Column(String(160), nullable=False, unique=True, index=True)

    posts = relationship("BlogPost", secondary=blog_posts_tags, back_populates="tags")


class BlogMedia(Base, TimestampMixin):
    """Uploaded blog media file metadata."""

    __tablename__ = "blog_media"

    id = Column(Integer, primary_key=True, autoincrement=True)
    uploader_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    file_name = Column(String(255), nullable=False, unique=True)
    original_name = Column(String(255), nullable=False)
    content_type = Column(String(100), nullable=False)
    size_bytes = Column(Integer, nullable=False)
    storage_path = Column(String(1000), nullable=False)
    public_url = Column(String(1000), nullable=False)


class BlogPost(Base, TimestampMixin):
    """Blog post with public SEO metadata and sanitized HTML content."""

    __tablename__ = "blog_posts"
    __table_args__ = (
        UniqueConstraint("slug", name="uq_blog_posts_slug"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    author_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    category_id = Column(Integer, ForeignKey("blog_categories.id", ondelete="SET NULL"), nullable=True, index=True)
    cover_media_id = Column(Integer, ForeignKey("blog_media.id", ondelete="SET NULL"), nullable=True)
    title = Column(String(255), nullable=False)
    slug = Column(String(255), nullable=False, index=True)
    excerpt = Column(Text, nullable=True)
    content_json = Column(JSONB, nullable=False, default=dict)
    content_html = Column(Text, nullable=False, default="")
    content_text = Column(Text, nullable=False, default="")
    status = Column(String(20), nullable=False, default="draft", index=True)
    cover_url = Column(String(1000), nullable=True)
    seo_title = Column(String(255), nullable=True)
    seo_description = Column(Text, nullable=True)
    canonical_url = Column(String(1000), nullable=True)
    og_image_url = Column(String(1000), nullable=True)
    published_at = Column(DateTime(timezone=True), nullable=True, index=True)

    category = relationship("BlogCategory", back_populates="posts")
    tags = relationship("BlogTag", secondary=blog_posts_tags, back_populates="posts")
    cover_media = relationship("BlogMedia", foreign_keys=[cover_media_id])
