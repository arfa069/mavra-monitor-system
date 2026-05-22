import api from "@/shared/api/client";
import type { SchedulerStatusResponse, UserConfig } from "../types";

export const configApi = {
  get: () => api.get<UserConfig>("/v1/config"),

  update: (data: Partial<UserConfig>) => api.patch<UserConfig>("/v1/config", data),

  getSchedulerStatus: () =>
    api.get<SchedulerStatusResponse>("/v1/scheduler/status"),
};
