export type BlogPostStatus = "draft" | "scheduled" | "published" | "archived";

export interface BlogCategory {
  id: number;
  name: string;
  slug: string;
  description?: string | null;
}

export interface BlogTag {
  id: number;
  name: string;
  slug: string;
}

export interface BlogPostListItem {
  id: number;
  title: string;
  slug: string;
  excerpt?: string | null;
  status: BlogPostStatus;
  cover_url?: string | null;
  seo_title?: string | null;
  seo_description?: string | null;
  published_at?: string | null;
  updated_at: string;
  category?: BlogCategory | null;
  tags: BlogTag[];
}

export interface BlogPost extends BlogPostListItem {
  content_json: Record<string, unknown>;
  content_html: string;
  content_text: string;
  created_at: string;
  canonical_url?: string | null;
  og_image_url?: string | null;
}

export interface BlogPostListResponse {
  items: BlogPostListItem[];
  total: number;
  page: number;
  size: number;
}

export interface BlogPostPayload {
  title: string;
  slug?: string | null;
  excerpt?: string | null;
  content_json: Record<string, unknown>;
  content_html: string;
  status: BlogPostStatus;
  category_name?: string | null;
  tag_names?: string[];
  cover_url?: string | null;
  seo_title?: string | null;
  seo_description?: string | null;
  canonical_url?: string | null;
  og_image_url?: string | null;
  published_at?: string | null;
}

export interface BlogMedia {
  id: number;
  file_name: string;
  original_name: string;
  content_type: string;
  size_bytes: number;
  public_url: string;
  created_at: string;
}
