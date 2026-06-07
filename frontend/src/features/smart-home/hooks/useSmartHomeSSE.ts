import { useEffect, useRef } from "react";
import { smartHomeApi } from "../api/smartHome";
import type { SmartHomeEntity } from "../types";

export function useSmartHomeSSE(
  enabled: boolean,
  onEntity: (entity: SmartHomeEntity) => void,
  onError: () => void,
) {
  const sourceRef = useRef<EventSource | null>(null);
  const retryCountRef = useRef(0);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const onEntityRef = useRef(onEntity);
  const onErrorRef = useRef(onError);

  useEffect(() => {
    // Keep refs in sync with latest callbacks to avoid re-subscription
    onEntityRef.current = onEntity;
    onErrorRef.current = onError;
  });

  useEffect(() => {
    if (!enabled) return;
    const maxRetry = 5;
    const baseDelay = 2000;

    function connect() {
      sourceRef.current?.close();
      const source = new EventSource(smartHomeApi.buildStreamUrl(), {
        withCredentials: true,
      });
      sourceRef.current = source;
      source.onmessage = (event) => {
        retryCountRef.current = 0;
        try {
          onEntityRef.current(JSON.parse(event.data) as SmartHomeEntity);
        } catch {
          onErrorRef.current();
        }
      };
      source.onerror = () => {
        source.close();
        if (sourceRef.current === source) {
          sourceRef.current = null;
        }
        if (retryCountRef.current < maxRetry) {
          retryCountRef.current += 1;
          const delay = baseDelay * Math.pow(2, retryCountRef.current - 1);
          timeoutRef.current = setTimeout(connect, delay);
        } else {
          onErrorRef.current();
        }
      };
      return source;
    }

    const source = connect();
    return () => {
      source.close();
      sourceRef.current?.close();
      sourceRef.current = null;
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
      retryCountRef.current = 0;
    };
  }, [enabled]);
}
