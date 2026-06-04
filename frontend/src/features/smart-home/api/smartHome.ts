import api from "@/shared/api/client";
import type {
  SmartHomeConfig,
  SmartHomeConfigUpdate,
  SmartHomeEntityListResponse,
  SmartHomeServiceRequest,
} from "../types";

export const smartHomeApi = {
  getConfig: () => api.get<SmartHomeConfig>("/v1/smart-home/config"),
  updateConfig: (data: SmartHomeConfigUpdate) =>
    api.put<SmartHomeConfig>("/v1/smart-home/config", data),
  testConfig: (data: Partial<SmartHomeConfigUpdate>) =>
    api.post<{
      ok: boolean;
      message: string;
      home_assistant_version: string | null;
    }>("/v1/smart-home/config/test", data),
  listEntities: () =>
    api.get<SmartHomeEntityListResponse>("/v1/smart-home/entities"),
  callService: (entityId: string, data: SmartHomeServiceRequest) =>
    api.post(
      `/v1/smart-home/entities/${encodeURIComponent(entityId)}/service`,
      data,
    ),
  buildStreamUrl: () => "/api/v1/smart-home/entities/stream",
};
