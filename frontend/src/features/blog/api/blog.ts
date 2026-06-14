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
  BlogPostCreate,
  BlogPostUpdate,
  BlogListAdminPostsStatus,
} from "@/shared/api/generated/models";

export const blogApi = {
  listAdminPosts: (params: {
    keyword?: string;
    status?: BlogListAdminPostsStatus;
    page?: number;
    size?: number;
  }) => {
    return blogListAdminPosts(params);
  },

  getAdminPost: (id: number) => blogGetAdminPost(id),

  createPost: (data: BlogPostCreate) => blogCreateAdminPost(data),

  updatePost: (id: number, data: BlogPostUpdate) => blogUpdateAdminPost(id, data),

  deletePost: (id: number) => blogDeleteAdminPost(id),

  uploadMedia: (file: File) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return blogUploadBlogMedia({ file } as any);
  },

  listCategories: () => blogListCategories(),

  listTags: () => blogListTags(),
};
