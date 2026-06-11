import { describe, expect, it, vi } from "vitest";

vi.mock("../src/lib/blog", () => ({
  canonicalUrl: vi.fn((path: string) => `http://localhost:3001${path}`),
  getPosts: vi.fn(),
}));

import sitemap from "./sitemap";
import { getPosts } from "../src/lib/blog";

describe("sitemap", () => {
  it("includes the blog index and public post URLs", async () => {
    vi.mocked(getPosts).mockResolvedValue({
      items: [
        {
          title: "First post",
          slug: "first-post",
          excerpt: null,
          cover_url: null,
          seo_title: null,
          seo_description: null,
          published_at: "2026-06-10T00:00:00Z",
          updated_at: "2026-06-10T01:00:00Z",
          category: null,
          tags: [],
        },
      ],
      total: 1,
      page: 1,
      size: 50,
    });

    const entries = await sitemap();

    expect(getPosts).toHaveBeenCalledWith({ size: 50 });
    expect(entries[0].url).toBe("http://localhost:3001/blog");
    expect(entries[1].url).toBe("http://localhost:3001/blog/first-post");
    expect(entries).toHaveLength(2);
  });

  it("falls back to the index when the post lookup fails", async () => {
    vi.mocked(getPosts).mockRejectedValueOnce(new Error("boom"));

    const entries = await sitemap();

    expect(entries).toHaveLength(1);
    expect(entries[0].url).toBe("http://localhost:3001/blog");
  });
});
