import { useSSE } from "@/shared/hooks/useSSE";
import { smartHomeApi } from "../api/smartHome";
import type { SmartHomeEntity } from "../types";

export function useSmartHomeSSE(
  enabled: boolean,
  onEntity: (entity: SmartHomeEntity) => void,
  onError: () => void,
) {
  useSSE(smartHomeApi.buildStreamUrl(), {
    enabled,
    maxRetries: 5,
    reconnectDelays: [2000, 4000, 8000, 16000, 32000],
    onMessage: (event) => {
      try {
        onEntity(JSON.parse(event.data) as SmartHomeEntity);
      } catch {
        onError();
      }
    },
    onError: (attempt) => {
      if (attempt >= 5) onError();
    },
  });
}
