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

export interface BlogPostSummary {
  id?: number;
  title: string;
  slug: string;
  excerpt?: string | null;
  status?: string;
  cover_url?: string | null;
  seo_title?: string | null;
  seo_description?: string | null;
  published_at?: string | null;
  updated_at: string;
  category?: BlogCategory | null;
  tags: BlogTag[];
}

export interface BlogPost extends BlogPostSummary {
  content_html: string;
  content_text?: string;
  canonical_url?: string | null;
  og_image_url?: string | null;
}

export interface BlogPostListResponse {
  items: BlogPostSummary[];
  total: number;
  page: number;
  size: number;
}

const DEFAULT_PUBLIC_BASE_URL = "http://localhost:3001";
const DEFAULT_API_BASE_URL = "http://127.0.0.1:8000/api/v1";

export function publicBaseUrl(): string {
  return (
    process.env.NEXT_PUBLIC_BLOG_BASE_URL ||
    process.env.BLOG_PUBLIC_BASE_URL ||
    DEFAULT_PUBLIC_BASE_URL
  ).replace(/\/$/, "");
}

export function apiBaseUrl(): string {
  return (process.env.BLOG_API_BASE_URL || DEFAULT_API_BASE_URL).replace(
    /\/$/,
    "",
  );
}

export function canonicalUrl(path: string): string {
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  return `${publicBaseUrl()}${normalizedPath}`;
}

export function absoluteAssetUrl(url?: string | null): string | null {
  if (!url) return null;
  if (/^https?:\/\//i.test(url)) return url;
  return canonicalUrl(url);
}

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(`${apiBaseUrl()}${path}`, {
    next: { revalidate: 0 },
    headers: { Accept: "application/json" },
  });
  if (!response.ok) {
    throw new Error(`Blog API request failed: ${response.status}`);
  }
  return (await response.json()) as T;
}

function queryString(
  params: Record<string, string | number | undefined>,
): string {
  const search = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== "") {
      search.set(key, String(value));
    }
  });
  const serialized = search.toString();
  return serialized ? `?${serialized}` : "";
}

export async function getPosts(
  params: {
    keyword?: string;
    category?: string;
    tag?: string;
    page?: number;
    size?: number;
  } = {},
): Promise<BlogPostListResponse> {
  return fetchJson<BlogPostListResponse>(
    `/blog/posts${queryString({
      keyword: params.keyword,
      category: params.category,
      tag: params.tag,
      page: params.page ?? 1,
      size: params.size ?? 12,
    })}`,
  );
}

export async function getPost(slug: string): Promise<BlogPost> {
  return fetchJson<BlogPost>(`/blog/posts/${encodeURIComponent(slug)}`);
}

export async function getCategories(): Promise<BlogCategory[]> {
  return fetchJson<BlogCategory[]>("/blog/categories");
}

export async function getTags(): Promise<BlogTag[]> {
  return fetchJson<BlogTag[]>("/blog/tags");
}

export function buildArticleJsonLd(post: BlogPost) {
  const image = absoluteAssetUrl(post.og_image_url || post.cover_url);
  return {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: post.seo_title || post.title,
    description: post.seo_description || post.excerpt || undefined,
    datePublished: post.published_at || undefined,
    dateModified: post.updated_at,
    author: {
      "@type": "Organization",
      name: "Mavra",
    },
    mainEntityOfPage: post.canonical_url || canonicalUrl(`/blog/${post.slug}`),
    image: image ? [image] : undefined,
  };
}

export function formatDate(value?: string | null): string {
  if (!value) return "Unscheduled";
  return new Intl.DateTimeFormat("en", {
    year: "numeric",
    month: "short",
    day: "numeric",
  }).format(new Date(value));
}
