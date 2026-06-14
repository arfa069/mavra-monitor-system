import { beforeEach, describe, expect, it, vi } from "vitest";
import { blogListAdminPosts } from "@/shared/api/generated/blog/blog";
import { blogApi } from "@/features/blog/api/blog";

vi.mock("@/shared/api/generated/blog/blog", () => ({
  blogListAdminPosts: vi.fn(),
  blogGetAdminPost: vi.fn(),
  blogCreateAdminPost: vi.fn(),
  blogUpdateAdminPost: vi.fn(),
  blogDeleteAdminPost: vi.fn(),
  blogUploadBlogMedia: vi.fn(),
  blogListCategories: vi.fn(),
  blogListTags: vi.fn(),
}));

describe("blogApi", () => {
  beforeEach(() => {
    vi.mocked(blogListAdminPosts).mockReset();
  });

  it("normalizes optional generated tags for UI consumers", async () => {
    vi.mocked(blogListAdminPosts).mockResolvedValue({
      items: [
        {
          id: 1,
          title: "Draft",
          slug: "draft",
          status: "draft",
          updated_at: "2026-06-14T00:00:00Z",
        },
      ],
      total: 1,
      page: 1,
      size: 20,
    });

    const response = await blogApi.listAdminPosts();

    expect(response.items[0].tags).toEqual([]);
  });
});
