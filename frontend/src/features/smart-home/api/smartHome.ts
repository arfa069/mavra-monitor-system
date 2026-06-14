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
  SmartHomeConfigResponse,
  SmartHomeEntity as GeneratedSmartHomeEntity,
  SmartHomeServiceRequest,
} from "@/shared/api/generated/models";
import { apiUrl } from "@/shared/api/base";
import type { SmartHomeConfig, SmartHomeEntity } from "../types";

function normalizeSmartHomeConfig(
  config: SmartHomeConfigResponse,
): SmartHomeConfig {
  return {
    ...config,
    last_status: config.last_status ?? null,
    last_error: config.last_error ?? null,
    token_configured: config.token_configured ?? true,
  };
}

function normalizeSmartHomeEntity(
  entity: GeneratedSmartHomeEntity,
): SmartHomeEntity {
  return {
    ...entity,
    area: entity.area ?? null,
    attributes: entity.attributes ?? {},
    last_changed: entity.last_changed ?? null,
    last_updated: entity.last_updated ?? null,
    available: entity.available ?? true,
  };
}

export const smartHomeApi = {
  getConfig: async () => normalizeSmartHomeConfig(await smartHomeGetConfig()),
  updateConfig: async (data: SmartHomeConfigUpdate) =>
    normalizeSmartHomeConfig(await smartHomeUpdateConfig(data)),
  testConfig: (data: SmartHomeConfigTestRequest) => smartHomeTestConfig(data),
  listEntities: async () => {
    const response = await smartHomeListEntities();
    return {
      ...response,
      items: response.items.map(normalizeSmartHomeEntity),
      last_error: response.last_error ?? null,
    };
  },
  getSummary: () => smartHomeGetSummary(),
  callService: (
    entityId: string,
    data: Omit<SmartHomeServiceRequest, "entity_id">,
  ) => smartHomeCallService({ entity_id: entityId, ...data }),
  buildStreamUrl: () => apiUrl("/smart-home/entities/stream"),
};
