import { useEffect, useState } from "react";
import api from "@/shared/api/client";
import { useAuth } from "@/shared/contexts/AuthContext";
import type { RecentAlert } from "../types";

interface AlertsState {
  data: RecentAlert[];
  loading: boolean;
  error: string | null;
}

export function useRecentAlerts(limit = 10): AlertsState {
  const { user } = useAuth();
  const isAdmin = user?.role === "admin" || user?.role === "super_admin";

  const [state, setState] = useState<AlertsState>({
    data: [],
    loading: false,
    error: null,
  });

  useEffect(() => {
    let cancelled = false;

    if (!isAdmin) {
      Promise.resolve().then(() => {
        setState((prev) => {
          if (prev.data.length === 0 && !prev.loading && !prev.error)
            return prev;
          return { data: [], loading: false, error: null };
        });
      });
      return undefined;
    }

    const fetchAlerts = async () => {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      try {
        const response = await api.get<RecentAlert[]>(
          "/v1/dashboard/alerts/recent",
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

    fetchAlerts();

    return () => {
      cancelled = true;
    };
  }, [limit, isAdmin]);

  return state;
}
