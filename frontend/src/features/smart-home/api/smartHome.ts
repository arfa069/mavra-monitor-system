import api from "@/shared/api/client";
import { apiUrl } from "@/shared/api/base";
import type {
  SmartHomeConfig,
  SmartHomeConfigUpdate,
  SmartHomeEntityListResponse,
  SmartHomeSummary,
  SmartHomeServiceRequest,
} from "../types";

export const smartHomeApi = {
  getConfig: () => api.get<SmartHomeConfig>("/smart-home/config"),
  updateConfig: (data: SmartHomeConfigUpdate) =>
    api.put<SmartHomeConfig>("/smart-home/config", data),
  testConfig: (data: Partial<SmartHomeConfigUpdate>) =>
    api.post<{
      ok: boolean;
      message: string;
      home_assistant_version: string | null;
    }>("/smart-home/config/test", data),
  listEntities: () =>
    api.get<SmartHomeEntityListResponse>("/smart-home/entities"),
  getSummary: () => api.get<SmartHomeSummary>("/smart-home/summary"),
  callService: (entityId: string, data: SmartHomeServiceRequest) =>
    api.post(
      `/smart-home/entities/${encodeURIComponent(entityId)}/service`,
      data,
    ),
  buildStreamUrl: () => apiUrl("/smart-home/entities/stream"),
};
