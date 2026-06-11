import api from "@/shared/api/client";
import type {
  BlogCategory,
  BlogMedia,
  BlogPost,
  BlogPostListResponse,
  BlogPostPayload,
  BlogPostStatus,
  BlogTag,
} from "../types";

export const blogApi = {
  listAdminPosts: (params: {
    keyword?: string;
    status?: BlogPostStatus;
    page?: number;
    size?: number;
  }) => api.get<BlogPostListResponse>("/v1/blog/admin/posts", { params }),

  getAdminPost: (id: number) => api.get<BlogPost>(`/v1/blog/admin/posts/${id}`),

  createPost: (data: BlogPostPayload) =>
    api.post<BlogPost>("/v1/blog/admin/posts", data),

  updatePost: (id: number, data: Partial<BlogPostPayload>) =>
    api.patch<BlogPost>(`/v1/blog/admin/posts/${id}`, data),

  deletePost: (id: number) => api.delete(`/v1/blog/admin/posts/${id}`),

  uploadMedia: (file: File) => {
    const formData = new FormData();
    formData.append("file", file);
    return api.post<BlogMedia>("/v1/blog/admin/uploads", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  },

  listCategories: () => api.get<BlogCategory[]>("/v1/blog/categories"),

  listTags: () => api.get<BlogTag[]>("/v1/blog/tags"),
};
