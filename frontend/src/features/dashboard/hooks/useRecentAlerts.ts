import { useEffect, useState } from "react";
import api from "@/shared/api/client";
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

  const [state, setState] = useState<AlertsState>(DEFAULT_STATE);

  useEffect(() => {
    if (!isAdmin) return;

    let cancelled = false;

    const fetchAlerts = async () => {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      try {
        const response = await api.get<RecentAlert[]>(
          "/dashboard/alerts/recent",
          { params: { limit } },
        );
        if (!cancelled) {
          setState({ data: response.data, loading: false, error: null });
        }
      } catch {
        if (cancelled) {
          return;
        }
        // Silently handle 403 (non-admin) and other errors
        setState({ data: [], loading: false, error: null });
      }
    };

    void fetchAlerts();

    return () => {
      cancelled = true;
    };
  }, [limit, isAdmin]);

  if (!isAdmin) {
    return DEFAULT_STATE;
  }

  return state;
}
