import api from "@/shared/api/client";
import type { Alert, AlertCreateRequest, AlertUpdateRequest } from "../types";

export const alertsApi = {
  list: (params?: { product_id?: number; active?: boolean }) =>
    api.get<Alert[]>("/v1/alerts", { params }),

  get: (id: number) => api.get<Alert>(`/v1/alerts/${id}`),

  create: (data: AlertCreateRequest) => api.post<Alert>("/v1/alerts", data),

  update: (id: number, data: AlertUpdateRequest) =>
    api.patch<Alert>(`/v1/alerts/${id}`, data),

  delete: (id: number) => api.delete(`/v1/alerts/${id}`),
};
