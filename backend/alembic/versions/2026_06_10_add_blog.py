"""Add public blog publishing tables.

Revision ID: 2026_06_10_add_blog
Revises: 2026_06_06_smart_home_preferences
Create Date: 2026-06-10
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "2026_06_10_add_blog"
down_revision: str | None = "2026_06_06_smart_home_preferences"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

PERMISSIONS = {
    "blog:read_admin": "Read blog drafts and scheduled posts",
    "blog:write": "Create and edit blog posts",
    "blog:publish": "Publish and unpublish blog posts",
}

ROLE_PERMISSIONS = {
    "admin": set(PERMISSIONS.keys()),
    "super_admin": set(PERMISSIONS.keys()),
}


def upgrade() -> None:
    bind = op.get_bind()
    op.create_table(
        "blog_categories",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("slug", sa.String(length=160), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index("ix_blog_categories_slug", "blog_categories", ["slug"])
    op.create_table(
        "blog_tags",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("slug", sa.String(length=160), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index("ix_blog_tags_slug", "blog_tags", ["slug"])
    op.create_table(
        "blog_media",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("uploader_id", sa.Integer(), nullable=True),
        sa.Column("file_name", sa.String(length=255), nullable=False),
        sa.Column("original_name", sa.String(length=255), nullable=False),
        sa.Column("content_type", sa.String(length=100), nullable=False),
        sa.Column("size_bytes", sa.Integer(), nullable=False),
        sa.Column("storage_path", sa.String(length=1000), nullable=False),
        sa.Column("public_url", sa.String(length=1000), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["uploader_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("file_name"),
    )
    op.create_index("ix_blog_media_uploader_id", "blog_media", ["uploader_id"])
    op.create_table(
        "blog_posts",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("author_id", sa.Integer(), nullable=True),
        sa.Column("category_id", sa.Integer(), nullable=True),
        sa.Column("cover_media_id", sa.Integer(), nullable=True),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("slug", sa.String(length=255), nullable=False),
        sa.Column("excerpt", sa.Text(), nullable=True),
        sa.Column("content_json", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("content_html", sa.Text(), server_default="", nullable=False),
        sa.Column("content_text", sa.Text(), server_default="", nullable=False),
        sa.Column("status", sa.String(length=20), server_default="draft", nullable=False),
        sa.Column("cover_url", sa.String(length=1000), nullable=True),
        sa.Column("seo_title", sa.String(length=255), nullable=True),
        sa.Column("seo_description", sa.Text(), nullable=True),
        sa.Column("canonical_url", sa.String(length=1000), nullable=True),
        sa.Column("og_image_url", sa.String(length=1000), nullable=True),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["author_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["category_id"], ["blog_categories.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["cover_media_id"], ["blog_media.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("slug", name="uq_blog_posts_slug"),
    )
    op.create_index("ix_blog_posts_author_id", "blog_posts", ["author_id"])
    op.create_index("ix_blog_posts_category_id", "blog_posts", ["category_id"])
    op.create_index("ix_blog_posts_slug", "blog_posts", ["slug"])
    op.create_index("ix_blog_posts_status", "blog_posts", ["status"])
    op.create_index("ix_blog_posts_published_at", "blog_posts", ["published_at"])
    op.create_table(
        "blog_posts_tags",
        sa.Column("post_id", sa.Integer(), nullable=False),
        sa.Column("tag_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["post_id"], ["blog_posts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["tag_id"], ["blog_tags.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("post_id", "tag_id"),
    )

    for permission_name, description in PERMISSIONS.items():
        bind.execute(
            sa.text(
                "INSERT INTO users_permissions (name, description, created_at, updated_at) "
                "VALUES (:name, :description, NOW(), NOW()) "
                "ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description"
            ),
            {"name": permission_name, "description": description},
        )
    for role_name, permission_names in ROLE_PERMISSIONS.items():
        for permission_name in sorted(permission_names):
            bind.execute(
                sa.text(
                    "INSERT INTO users_roles_permissions (role_id, permission_id) "
                    "SELECT r.id, p.id FROM users_roles r, users_permissions p "
                    "WHERE r.name = :role_name AND p.name = :permission_name "
                    "ON CONFLICT DO NOTHING"
                ),
                {"role_name": role_name, "permission_name": permission_name},
            )


def downgrade() -> None:
    bind = op.get_bind()
    for role_name, permission_names in ROLE_PERMISSIONS.items():
        for permission_name in sorted(permission_names):
            bind.execute(
                sa.text(
                    "DELETE FROM users_roles_permissions "
                    "WHERE role_id = (SELECT id FROM users_roles WHERE name = :role_name) "
                    "AND permission_id = (SELECT id FROM users_permissions WHERE name = :permission_name)"
                ),
                {"role_name": role_name, "permission_name": permission_name},
            )
    for permission_name in PERMISSIONS:
        bind.execute(
            sa.text("DELETE FROM users_permissions WHERE name = :name"),
            {"name": permission_name},
        )
    op.drop_table("blog_posts_tags")
    op.drop_index("ix_blog_posts_published_at", table_name="blog_posts")
    op.drop_index("ix_blog_posts_status", table_name="blog_posts")
    op.drop_index("ix_blog_posts_slug", table_name="blog_posts")
    op.drop_index("ix_blog_posts_category_id", table_name="blog_posts")
    op.drop_index("ix_blog_posts_author_id", table_name="blog_posts")
    op.drop_table("blog_posts")
    op.drop_index("ix_blog_media_uploader_id", table_name="blog_media")
    op.drop_table("blog_media")
    op.drop_index("ix_blog_tags_slug", table_name="blog_tags")
    op.drop_table("blog_tags")
    op.drop_index("ix_blog_categories_slug", table_name="blog_categories")
    op.drop_table("blog_categories")
