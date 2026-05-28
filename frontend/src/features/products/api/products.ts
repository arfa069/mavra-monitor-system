import api from "@/shared/api/client";
import type {
  ProductListResponse,
  Product,
  ProductCreateRequest,
  ProductUpdateRequest,
  BatchCreateItem,
  BatchOperationResult,
  PriceHistoryRecord,
  ProductPlatformCron,
  ProductPlatformCronCreate,
  ProductPlatformCronUpdate,
  ProductPlatformCronSchedule,
  ProductPlatformProfileBinding,
  ProductPlatformProfileBindingUpdate,
} from "../types";

export const productsApi = {
  list: (params: {
    platform?: string;
    active?: boolean;
    keyword?: string;
    page?: number;
    size?: number;
  }) => api.get<ProductListResponse>("/v1/products", { params }),

  get: (id: number) => api.get<Product>(`/v1/products/${id}`),

  create: (data: ProductCreateRequest) =>
    api.post<Product>("/v1/products", data),

  update: (id: number, data: ProductUpdateRequest) =>
    api.patch<Product>(`/v1/products/${id}`, data),

  delete: (id: number) => api.delete(`/v1/products/${id}`),

  batchCreate: (items: BatchCreateItem[]) =>
    api.post<BatchOperationResult[]>("/v1/products/batch-create", { items }),

  batchDelete: (ids: number[]) =>
    api.post<BatchOperationResult[]>("/v1/products/batch-delete", { ids }),

  batchUpdate: (ids: number[], active?: boolean) =>
    api.post<BatchOperationResult[]>("/v1/products/batch-update", {
      ids,
      active,
    }),

  history: (id: number, days = 30, limit = 100) =>
    api.get<PriceHistoryRecord[]>(`/v1/products/${id}/history`, {
      params: { days, limit },
    }),

  // Per-platform cron configs
  getCronConfigs: () =>
    api.get<ProductPlatformCron[]>("/v1/products/cron-configs"),

  createCronConfig: (data: ProductPlatformCronCreate) =>
    api.post<ProductPlatformCron>("/v1/products/cron-configs", data),

  updateCronConfig: (platform: string, data: ProductPlatformCronUpdate) =>
    api.patch<ProductPlatformCron>(
      `/v1/products/cron-configs/${platform}`,
      data,
    ),

  deleteCronConfig: (platform: string) =>
    api.delete(`/v1/products/cron-configs/${platform}`),

  getCronSchedules: () =>
    api.get<{ platforms: Record<string, ProductPlatformCronSchedule> }>(
      "/v1/products/cron-schedules",
    ),

  getProfileBindings: () =>
    api.get<ProductPlatformProfileBinding[]>("/v1/products/profile-bindings"),

  updateProfileBinding: (
    platform: string,
    data: ProductPlatformProfileBindingUpdate,
  ) =>
    api.put<ProductPlatformProfileBinding>(
      `/v1/products/profile-bindings/${platform}`,
      data,
    ),

  deleteProfileBinding: (platform: string) =>
    api.delete(`/v1/products/profile-bindings/${platform}`),
};
