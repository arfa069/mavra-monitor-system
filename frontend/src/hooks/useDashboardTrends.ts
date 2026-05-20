import { useEffect, useState } from "react";
import axios from "axios";
import type { TrendResponse, TrendType, TimeRange } from "@/types/dashboard";

interface TrendsState {
  data: TrendResponse | null;
  loading: boolean;
  error: string | null;
}

export function useDashboardTrends(
  type: TrendType,
  days: TimeRange,
  token: string | null,
): TrendsState {
  const [state, setState] = useState<TrendsState>({
    data: null,
    loading: false,
    error: null,
  });

  useEffect(() => {
    if (!token) return;

    const fetchData = async () => {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      try {
        const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:8000";
        const response = await axios.get<TrendResponse>(
          `${apiUrl}/dashboard/trends`,
          {
            params: { type, days },
            headers: { Authorization: `Bearer ${token}` },
          },
        );
        setState({ data: response.data, loading: false, error: null });
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Failed to load trend data";
        setState({ data: null, loading: false, error: message });
      }
    };

    fetchData();
  }, [type, days, token]);

  return state;
}
