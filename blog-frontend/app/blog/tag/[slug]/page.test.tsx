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

import TagPage from "./page";
import { getPosts } from "../../../../src/lib/blog";

describe("TagPage", () => {
  beforeEach(() => {
    vi.mocked(getPosts).mockResolvedValue({
      items: [
        {
          title: "Tag post",
          slug: "tag-post",
          excerpt: "Tag excerpt",
          cover_url: "/blog-media/tag.webp",
          seo_title: null,
          seo_description: null,
          published_at: "2026-06-10T00:00:00Z",
          updated_at: "2026-06-10T01:00:00Z",
          category: { id: 1, name: "Updates", slug: "updates" },
          tags: [{ id: 2, name: "release", slug: "release" }],
        },
      ],
      total: 1,
      page: 1,
      size: 12,
    });
  });

  it("renders posts for a tag slug", async () => {
    const markup = renderToStaticMarkup(
      await TagPage({
        params: Promise.resolve({ slug: "release" }),
      }),
    );

    expect(getPosts).toHaveBeenCalledWith({ tag: "release" });
    expect(markup).toContain("TAG");
    expect(markup).toContain("Tag post");
    expect(markup).toContain("http://localhost:3001/blog-media/tag.webp");
  });
});
