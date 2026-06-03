import { useEffect } from "react";
import { smartHomeApi } from "../api/smartHome";
import type { SmartHomeEntity } from "../types";

export function useSmartHomeSSE(
  enabled: boolean,
  onEntity: (entity: SmartHomeEntity) => void,
  onError: () => void,
) {
  useEffect(() => {
    if (!enabled) return;
    const source = new EventSource(smartHomeApi.buildStreamUrl(), {
      withCredentials: true,
    });
    source.onmessage = (event) => {
      try {
        onEntity(JSON.parse(event.data) as SmartHomeEntity);
      } catch {
        onError();
      }
    };
    source.onerror = () => onError();
    return () => source.close();
  }, [enabled, onEntity, onError]);
}
