import { useState } from "react";
import { useSSE } from "@/shared/hooks/useSSE";
import type { DashboardKPIResponse } from "../types";

interface SSEState {
  data: DashboardKPIResponse | null;
  connected: boolean;
  error: string | null;
}

import { apiUrl } from "@/shared/api/base";

const SSE_URL = apiUrl("/dashboard/events");

export function useDashboardSSE(): SSEState {
  const [state, setState] = useState<SSEState>({
    data: null,
    connected: false,
    error: null,
  });

  useSSE(SSE_URL, {
    onOpen: () =>
      setState((prev) => ({ ...prev, connected: true, error: null })),
    onMessage: (event) => {
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
    },
    onError: () =>
      setState((prev) => ({
        ...prev,
        connected: false,
        error: "连接断开，正在重连...",
      })),
  });

  return state;
}
