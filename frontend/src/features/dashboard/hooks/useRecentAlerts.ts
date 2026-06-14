import { useDashboardGetRecentAlerts } from "@/shared/api/generated/dashboard/dashboard";
import { useAuth } from "@/shared/contexts/AuthContext";
import type { RecentAlert } from "../types";

interface AlertsState {
  data: RecentAlert[];
  loading: boolean;
  error: string | null;
}

const DEFAULT_STATE: AlertsState = {
  data: [],
  loading: false,
  error: null,
};

export function useRecentAlerts(limit = 10): AlertsState {
  const { isAdmin } = useAuth();

  const { data, isLoading, error } = useDashboardGetRecentAlerts(
    { limit },
    { query: { enabled: isAdmin } }
  );

  if (!isAdmin) {
    return DEFAULT_STATE;
  }

  return {
    data: (data as RecentAlert[]) ?? [],
    loading: isLoading,
    error: error ? (error.message || "Failed to load recent alerts") : null,
  };
}
