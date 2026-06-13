import { describe, expect, it } from "vitest";
import { apiBaseUrl, buildArticleJsonLd, canonicalUrl } from "./blog";

describe("blog SEO helpers", () => {
  it("builds canonical URLs against the public base URL", () => {
    expect(canonicalUrl("/blog/first-post")).toBe(
      "http://localhost:3001/blog/first-post",
    );
  });

  it("builds Article JSON-LD with post metadata", () => {
    const jsonLd = buildArticleJsonLd({
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
      content_html: "<p>Hello</p>",
      category: { id: 1, name: "Updates", slug: "updates" },
      tags: [],
    });

    expect(jsonLd["@type"]).toBe("Article");
    expect(jsonLd.headline).toBe("First SEO title");
    expect(jsonLd.datePublished).toBe("2026-06-10T00:00:00Z");
    expect(jsonLd.image).toEqual(["http://localhost:3001/blog-media/cover.webp"]);
  });

  it("defaults the backend API base to the canonical prefix", () => {
    const previous = process.env.BLOG_API_BASE_URL;
    delete process.env.BLOG_API_BASE_URL;

    try {
      expect(apiBaseUrl()).toBe("http://127.0.0.1:8000/api/v1");
    } finally {
      if (previous === undefined) {
        delete process.env.BLOG_API_BASE_URL;
      } else {
        process.env.BLOG_API_BASE_URL = previous;
      }
    }
  });
});
