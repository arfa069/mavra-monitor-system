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

vi.mock("../../../../src/lib/blog", () => ({
  absoluteAssetUrl: vi.fn((url?: string | null) =>
    url ? `http://localhost:3001${url}` : null,
  ),
  formatDate: vi.fn(() => "Jun 11, 2026"),
  getPosts: vi.fn(),
}));

import CategoryPage from "./page";
import { getPosts } from "../../../../src/lib/blog";

describe("CategoryPage", () => {
  beforeEach(() => {
    vi.mocked(getPosts).mockResolvedValue({
      items: [
        {
          title: "Category post",
          slug: "category-post",
          excerpt: "Category excerpt",
          cover_url: "/blog-media/category.webp",
          seo_title: null,
          seo_description: null,
          published_at: "2026-06-10T00:00:00Z",
          updated_at: "2026-06-10T01:00:00Z",
          category: { id: 1, name: "Updates", slug: "updates" },
          tags: [],
        },
      ],
      total: 1,
      page: 1,
      size: 12,
    });
  });

  it("renders posts for a category slug", async () => {
    const markup = renderToStaticMarkup(
      await CategoryPage({
        params: Promise.resolve({ slug: "updates" }),
      }),
    );

    expect(getPosts).toHaveBeenCalledWith({ category: "updates" });
    expect(markup).toContain("CATEGORY");
    expect(markup).toContain("Category post");
    expect(markup).toContain("http://localhost:3001/blog-media/category.webp");
  });
});
