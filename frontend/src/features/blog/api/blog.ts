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
  }) => api.get<BlogPostListResponse>("/blog/admin/posts", { params }),

  getAdminPost: (id: number) => api.get<BlogPost>(`/blog/admin/posts/${id}`),

  createPost: (data: BlogPostPayload) =>
    api.post<BlogPost>("/blog/admin/posts", data),

  updatePost: (id: number, data: Partial<BlogPostPayload>) =>
    api.patch<BlogPost>(`/blog/admin/posts/${id}`, data),

  deletePost: (id: number) => api.delete(`/blog/admin/posts/${id}`),

  uploadMedia: (file: File) => {
    const formData = new FormData();
    formData.append("file", file);
    return api.post<BlogMedia>("/blog/admin/uploads", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  },

  listCategories: () => api.get<BlogCategory[]>("/blog/categories"),

  listTags: () => api.get<BlogTag[]>("/blog/tags"),
};
