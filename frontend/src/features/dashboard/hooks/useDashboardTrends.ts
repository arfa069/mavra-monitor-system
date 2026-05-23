import { useEffect, useState } from "react";
import api from "@/shared/api/client";
import type { TrendResponse, TrendType, TimeRange } from "../types";

interface TrendsState {
  data: TrendResponse | null;
  loading: boolean;
  error: string | null;
}

export function useDashboardTrends(
  type: TrendType,
  days: TimeRange,
): TrendsState {
  const [state, setState] = useState<TrendsState>({
    data: null,
    loading: false,
    error: null,
  });

  useEffect(() => {
    const fetchData = async () => {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      try {
        const response = await api.get<TrendResponse>("/v1/dashboard/trends", {
          params: { type, days },
        });
        setState({ data: response.data, loading: false, error: null });
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Failed to load trend data";
        setState({ data: null, loading: false, error: message });
      }
    };

    fetchData();
  }, [type, days]);

  return state;
}
