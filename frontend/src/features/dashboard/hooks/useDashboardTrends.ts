import { useDashboardGetTrendData } from "@/shared/api/generated/dashboard/dashboard";
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
  const { data, isLoading, isFetching, error } = useDashboardGetTrendData(
    { type, days },
    { query: { enabled } },
  );

  return {
    data: data ?? null,
    loading: isLoading,
    refreshing: isFetching && !isLoading,
    error: error ? (error.message || "Failed to load trend data") : null,
  };
}
