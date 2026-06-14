import {
  blogListAdminPosts,
  blogGetAdminPost,
  blogCreateAdminPost,
  blogUpdateAdminPost,
  blogDeleteAdminPost,
  blogUploadBlogMedia,
  blogListCategories,
  blogListTags,
} from "@/shared/api/generated/blog/blog";
import type {
  BlogListAdminPostsParams,
  BlogPostCreate,
  BlogPostListItem as GeneratedBlogPostListItem,
  BlogPostResponse,
  BlogPostUpdate,
} from "@/shared/api/generated/models";
import type { BlogPost, BlogPostListItem } from "../types";

function normalizeBlogPostListItem(
  post: GeneratedBlogPostListItem,
): BlogPostListItem {
  return {
    ...post,
    tags: post.tags ?? [],
  };
}

function normalizeBlogPost(post: BlogPostResponse): BlogPost {
  return {
    ...post,
    tags: post.tags ?? [],
  };
}

export const blogApi = {
  listAdminPosts: async (params?: BlogListAdminPostsParams) => {
    const response = await blogListAdminPosts(params);
    return {
      ...response,
      items: response.items.map(normalizeBlogPostListItem),
    };
  },

  getAdminPost: async (id: number) =>
    normalizeBlogPost(await blogGetAdminPost(id)),

  createPost: async (data: BlogPostCreate) =>
    normalizeBlogPost(await blogCreateAdminPost(data)),

  updatePost: async (id: number, data: BlogPostUpdate) =>
    normalizeBlogPost(await blogUpdateAdminPost(id, data)),

  deletePost: (id: number) => blogDeleteAdminPost(id),

  uploadMedia: (file: File) => blogUploadBlogMedia({ file }),

  listCategories: () => blogListCategories(),

  listTags: () => blogListTags(),
};
