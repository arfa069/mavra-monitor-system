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

vi.mock("../../src/lib/blog", () => ({
  absoluteAssetUrl: vi.fn((url?: string | null) =>
    url ? `http://localhost:3001${url}` : null,
  ),
  formatDate: vi.fn(() => "Jun 11, 2026"),
  getCategories: vi.fn(),
  getPosts: vi.fn(),
  getTags: vi.fn(),
}));

import BlogPage from "./page";
import { getCategories, getPosts, getTags } from "../../src/lib/blog";

describe("BlogPage", () => {
  beforeEach(() => {
    vi.mocked(getPosts).mockResolvedValue({
      items: [
        {
          title: "First post",
          slug: "first-post",
          excerpt: "A first note",
          cover_url: "/blog-media/cover.webp",
          seo_title: null,
          seo_description: null,
          published_at: "2026-06-10T00:00:00Z",
          updated_at: "2026-06-10T01:00:00Z",
          category: { id: 1, name: "Updates", slug: "updates" },
          tags: [{ id: 1, name: "release", slug: "release" }],
        },
      ],
      total: 1,
      page: 1,
      size: 12,
    });
    vi.mocked(getCategories).mockResolvedValue([
      { id: 1, name: "Updates", slug: "updates" },
    ]);
    vi.mocked(getTags).mockResolvedValue([
      { id: 1, name: "release", slug: "release" },
    ]);
  });

  it("renders published posts with search, categories, and tags", async () => {
    const markup = renderToStaticMarkup(
      await BlogPage({
        searchParams: Promise.resolve({ q: "First", page: "1" }),
      }),
    );

    expect(getPosts).toHaveBeenCalledWith({ keyword: "First", page: 1 });
    expect(markup).toContain("First post");
    expect(markup).toContain("http://localhost:3001/blog-media/cover.webp");
    expect(markup).toContain("/blog/category/updates");
    expect(markup).toContain("/blog/tag/release");
    expect(markup).toContain("Search notes, tags, and categories");
  });
});
