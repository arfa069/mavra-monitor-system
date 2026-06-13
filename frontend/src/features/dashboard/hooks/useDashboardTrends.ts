import { useEffect, useState } from "react";
import api from "@/shared/api/client";
import type { TrendResponse, TrendType, TimeRange } from "../types";

interface TrendsState {
  data: TrendResponse | null;
  loading: boolean;
  refreshing: boolean;
  error: string | null;
}

export function useDashboardTrends(
  type: TrendType,
  days: TimeRange,
  enabled = true,
): TrendsState {
  const [state, setState] = useState<TrendsState>({
    data: null,
    loading: false,
    refreshing: false,
    error: null,
  });

  useEffect(() => {
    let cancelled = false;

    if (!enabled) {
      return undefined;
    }

    const fetchData = async () => {
      setState((prev) => ({
        ...prev,
        loading: true,
        refreshing: prev.data !== null,
        error: null,
      }));
      try {
        const response = await api.get<TrendResponse>("/dashboard/trends", {
          params: { type, days },
        });
        if (!cancelled) {
          setState({
            data: response.data,
            loading: false,
            refreshing: false,
            error: null,
          });
        }
      } catch (err) {
        if (cancelled) {
          return;
        }
        const message =
          err instanceof Error ? err.message : "Failed to load trend data";
        setState({
          data: null,
          loading: false,
          refreshing: false,
          error: message,
        });
      }
    };

    fetchData();

    return () => {
      cancelled = true;
    };
  }, [type, days, enabled]);

  return state;
}
