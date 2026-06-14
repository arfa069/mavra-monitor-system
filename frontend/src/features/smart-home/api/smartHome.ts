import {
  smartHomeGetConfig,
  smartHomeUpdateConfig,
  smartHomeTestConfig,
  smartHomeListEntities,
  smartHomeGetSummary,
  smartHomeCallService,
} from "@/shared/api/generated/smart-home/smart-home";
import type {
  SmartHomeConfigUpdate,
  SmartHomeConfigTestRequest,
  SmartHomeServiceRequest,
} from "@/shared/api/generated/models";
import { apiUrl } from "@/shared/api/base";

export const smartHomeApi = {
  getConfig: () => smartHomeGetConfig(),
  updateConfig: (data: SmartHomeConfigUpdate) => smartHomeUpdateConfig(data),
  testConfig: (data: SmartHomeConfigTestRequest) => smartHomeTestConfig(data),
  listEntities: () => smartHomeListEntities(),
  getSummary: () => smartHomeGetSummary(),
  callService: (entityId: string, data: SmartHomeServiceRequest) =>
    smartHomeCallService(entityId, data),
  buildStreamUrl: () => apiUrl("/smart-home/entities/stream"),
};
