import { useEffect, useRef, useState } from "react";
import type { DashboardKPIResponse } from "../types";

interface SSEState {
  data: DashboardKPIResponse | null;
  connected: boolean;
  error: string | null;
}

const RECONNECT_DELAYS = [1000, 2000, 4000, 8000, 15000, 30000];

export function useDashboardSSE(token: string | null): SSEState {
  const [state, setState] = useState<SSEState>({
    data: null,
    connected: false,
    error: null,
  });
  const eventSourceRef = useRef<EventSource | null>(null);
  const reconnectAttemptRef = useRef(0);
  const reconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    function connect() {
      if (!token) return;
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
      }

      const apiUrl = import.meta.env.VITE_API_URL || "/api/v1";
      const es = new EventSource(
        `${apiUrl}/dashboard/events?token=${encodeURIComponent(token)}`,
      );
      eventSourceRef.current = es;

      es.onopen = () => {
        setState((prev) => ({ ...prev, connected: true, error: null }));
        reconnectAttemptRef.current = 0;
      };

      es.onmessage = (event) => {
        try {
          const parsed = JSON.parse(event.data);
          if (parsed.event === "kpi_update") {
            const response: DashboardKPIResponse = {
              user: parsed.data,
              system: parsed.system || null,
            };
            setState((prev) => ({ ...prev, data: response }));
          }
        } catch {
          // Ignore parse errors
        }
      };

      es.onerror = () => {
        setState((prev) => ({
          ...prev,
          connected: false,
          error: "连接断开，正在重连...",
        }));
        es.close();

        const delay =
          RECONNECT_DELAYS[
            Math.min(reconnectAttemptRef.current, RECONNECT_DELAYS.length - 1)
          ];
        reconnectAttemptRef.current += 1;

        reconnectTimerRef.current = setTimeout(() => {
          connect();
        }, delay);
      };
    }

    connect();
    return () => {
      if (reconnectTimerRef.current) {
        clearTimeout(reconnectTimerRef.current);
      }
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
      }
    };
  }, [token]);

  return state;
}
