import { createElement } from "react";
import { screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("@/features/blog/components/RichTextEditor", () => ({
  default: () => createElement("div", { "data-testid": "rich-text-editor" }),
}));

import { BlogAdminPage } from "@/features/blog";
import { blogApi } from "@/features/blog/api/blog";
import { renderWithApp } from "../test-utils";

const listResponse = {
  items: [
    {
      id: 1,
      title: "First draft",
      slug: "first-draft",
      excerpt: "Opening note",
      status: "draft" as const,
      cover_url: null,
      seo_title: null,
      seo_description: null,
      published_at: null,
      updated_at: "2026-06-10T00:00:00Z",
      category: { id: 1, name: "Updates", slug: "updates" },
      tags: [{ id: 1, name: "Release", slug: "release" }],
    },
  ],
  total: 1,
  page: 1,
  size: 20,
};

const taxonomyResponse = {
  categories: [{ id: 1, name: "Updates", slug: "updates" }],
  tags: [{ id: 1, name: "Release", slug: "release" }],
};

function mockAdminPageApi() {
  vi.spyOn(blogApi, "listAdminPosts").mockResolvedValue(listResponse as never);
  vi.spyOn(blogApi, "listCategories").mockResolvedValue(
    taxonomyResponse.categories as never,
  );
  vi.spyOn(blogApi, "listTags").mockResolvedValue(taxonomyResponse.tags as never);
  vi.spyOn(blogApi, "createPost").mockResolvedValue({
    id: 2,
    title: "Created post",
    slug: "created-post",
    excerpt: null,
    content_json: { type: "doc", content: [] },
    content_html: "<p></p>",
    status: "draft",
    cover_url: null,
    seo_title: null,
    seo_description: null,
    canonical_url: null,
    og_image_url: null,
    published_at: null,
    created_at: "2026-06-10T00:00:00Z",
    updated_at: "2026-06-10T00:00:00Z",
    category: null,
    tags: [],
  } as never);
  vi.spyOn(blogApi, "uploadMedia").mockResolvedValue({
    id: 9,
    file_name: "cover.png",
    original_name: "cover.png",
    content_type: "image/png",
    size_bytes: 12,
    public_url: "/blog-media/cover.png",
    created_at: "2026-06-10T00:00:00Z",
  } as never);
}

describe("BlogAdminPage", () => {
  beforeEach(() => {
    mockAdminPageApi();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("renders the admin blog post list", async () => {
    renderWithApp(<BlogAdminPage />);

    expect(await screen.findByText("Blog Studio")).toBeInTheDocument();
    expect(await screen.findByText("First draft")).toBeInTheDocument();
    expect(screen.getByText("Draft")).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /new post/i }),
    ).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText("Release")).toBeInTheDocument();
    });
  });

  it("blocks scheduled posts without a publish time", async () => {
    const user = userEvent.setup();
    renderWithApp(<BlogAdminPage />);

    await user.click(await screen.findByRole("button", { name: /new post/i }));

    const dialog = await screen.findByRole("dialog");
    await user.type(
      within(dialog).getByPlaceholderText("Post title"),
      "Scheduled post",
    );
    await user.click(within(dialog).getByText("Draft"));
    await user.click(await screen.findByText("Scheduled"));
    await user.click(within(dialog).getByRole("button", { name: "Create" }));

    expect(await screen.findByText("Scheduled posts need a publish time")).toBeInTheDocument();
    expect(blogApi.createPost).not.toHaveBeenCalled();
  });

  it("uploads a cover image and fills the cover field", async () => {
    const user = userEvent.setup();
    renderWithApp(<BlogAdminPage />);

    await user.click(await screen.findByRole("button", { name: /new post/i }));

    const dialog = await screen.findByRole("dialog");
    const fileInput = dialog.querySelector('input[type="file"]') as HTMLInputElement;
    expect(fileInput).not.toBeNull();

    await user.upload(
      fileInput,
      new File(["cover"], "cover.png", { type: "image/png" }),
    );

    await waitFor(() => {
      expect(blogApi.uploadMedia).toHaveBeenCalled();
      expect(
        within(dialog).getByPlaceholderText("/blog-media/cover.webp"),
      ).toHaveValue("/blog-media/cover.png");
    });
    expect(await screen.findByText("Image uploaded")).toBeInTheDocument();
  });

  it("surfaces upload failures in the admin editor", async () => {
    vi.spyOn(blogApi, "uploadMedia").mockRejectedValueOnce(new Error("boom"));
    const user = userEvent.setup();
    renderWithApp(<BlogAdminPage />);

    await user.click(await screen.findByRole("button", { name: /new post/i }));

    const dialog = await screen.findByRole("dialog");
    const fileInput = dialog.querySelector('input[type="file"]') as HTMLInputElement;

    await user.upload(
      fileInput,
      new File(["cover"], "cover.png", { type: "image/png" }),
    );

    expect(await screen.findByText("boom")).toBeInTheDocument();
  });
});
