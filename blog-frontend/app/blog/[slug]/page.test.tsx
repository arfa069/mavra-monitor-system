import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("next/link", () => ({
  default: ({
    href,
    children,
    ...props
  }: {
    href: string;
    children: unknown;
  }) => createElement("a", { href, ...props }, children),
}));

vi.mock("next/navigation", () => ({
  notFound: vi.fn(() => {
    throw new Error("not-found");
  }),
}));

vi.mock("../../../src/lib/blog", () => ({
  absoluteAssetUrl: vi.fn((url?: string | null) =>
    url ? `http://localhost:3001${url}` : null,
  ),
  buildArticleJsonLd: vi.fn(() => ({
    "@context": "https://schema.org",
    "@type": "Article",
    headline: "First SEO title",
  })),
  canonicalUrl: vi.fn((path: string) => `http://localhost:3001${path}`),
  formatDate: vi.fn(() => "Jun 11, 2026"),
  getPost: vi.fn(),
}));

import BlogPostPage, { generateMetadata } from "./page";
import { getPost } from "../../../src/lib/blog";

const post = {
  title: "First post",
  slug: "first-post",
  excerpt: "A first note",
  seo_title: "First SEO title",
  seo_description: "SEO description",
  cover_url: "/blog-media/cover.webp",
  og_image_url: null,
  canonical_url: null,
  published_at: "2026-06-10T00:00:00Z",
  updated_at: "2026-06-10T01:00:00Z",
  content_html: "<p>Hello world</p>",
  category: { id: 1, name: "Updates", slug: "updates" },
  tags: [{ id: 1, name: "release", slug: "release" }],
};

describe("BlogPostPage", () => {
  beforeEach(() => {
    vi.mocked(getPost).mockResolvedValue(post);
  });

  it("builds metadata with canonical, description, and open graph image", async () => {
    const metadata = await generateMetadata({
      params: Promise.resolve({ slug: "first-post" }),
    });

    expect(metadata.title).toBe("First SEO title");
    expect(metadata.description).toBe("SEO description");
    expect(metadata.alternates?.canonical).toBe(
      "http://localhost:3001/blog/first-post",
    );
    expect(metadata.openGraph?.images).toEqual([
      { url: "http://localhost:3001/blog-media/cover.webp" },
    ]);
  });

  it("renders the article body, tags, and structured data script", async () => {
    const markup = renderToStaticMarkup(
      await BlogPostPage({
        params: Promise.resolve({ slug: "first-post" }),
      }),
    );

    expect(markup).toContain("First post");
    expect(markup).toContain("Hello world");
    expect(markup).toContain("/blog/tag/release");
    expect(markup).toContain("application/ld+json");
    expect(markup).toContain("http://localhost:3001/blog-media/cover.webp");
  });
});
