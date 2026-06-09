import { useEffect, useState } from "react";
import api from "@/shared/api/client";
import { productsApi } from "@/features/products/api/products";
import { jobsApi } from "@/features/jobs/api/jobs";
import { smartHomeApi } from "@/features/smart-home/api/smartHome";
import { buildTodayBrief } from "../todayBrief";
import type { DashboardKPIResponse } from "@/features/dashboard/types";
import type { MatchResultListResponse } from "@/features/jobs/types";
import type { TodayBrief, TodaySourceData } from "../types";

interface TodayDataState {
  data: TodayBrief | null;
  loading: boolean;
  error: string | null;
}

const DEFAULT_KPI = {
  total_products: 0,
  price_drops_today: 0,
  new_jobs_today: 0,
  match_count: 0,
  crawl_count_today: 0,
};

export function useTodayData(): TodayDataState {
  const [state, setState] = useState<TodayDataState>({
    data: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    let cancelled = false;

    async function loadToday() {
      setState((prev) => ({ ...prev, loading: true, error: null }));

      try {
        const [
          kpiResult,
          productsResult,
          matchesResult,
          configResult,
          entitiesResult,
        ] = await Promise.allSettled([
          api.get<DashboardKPIResponse>("/v1/dashboard/kpi"),
          productsApi.list({ active: true, page: 1, size: 5 }),
          jobsApi.getMatchResults({ page: 1, page_size: 5 }),
          smartHomeApi.getConfig(),
          smartHomeApi.listEntities(),
        ]);

        if (cancelled) return;

        const kpi =
          kpiResult.status === "fulfilled"
            ? kpiResult.value.data.user
            : DEFAULT_KPI;
        const products =
          productsResult.status === "fulfilled"
            ? productsResult.value.data.items.map((product) => ({
                id: product.id,
                title: product.title,
                platform: product.platform,
              }))
            : [];
        const matchResponse =
          matchesResult.status === "fulfilled"
            ? (matchesResult.value.data as MatchResultListResponse)
            : null;
        const jobMatches =
          matchResponse?.items.map((match) => ({
            id: match.id,
            score: match.match_score,
            title: match.job_title,
            company: match.job_company,
            location: match.job_location,
          })) ?? [];
        const config =
          configResult.status === "fulfilled" ? configResult.value.data : null;
        const entities =
          entitiesResult.status === "fulfilled"
            ? entitiesResult.value.data
            : null;

        const source: TodaySourceData = {
          now: new Date(),
          kpi,
          products,
          jobMatches,
          home: {
            configured: Boolean(config?.enabled && config?.token_configured),
            connected: Boolean(entities?.connected),
            unavailableCount:
              entities?.items.filter((entity) => !entity.available).length ?? 0,
            activeCount:
              entities?.items.filter((entity) => entity.available).length ?? 0,
          },
        };

        setState({
          data: buildTodayBrief(source),
          loading: false,
          error: null,
        });
      } catch {
        if (!cancelled) {
          setState({
            data: buildTodayBrief({
              now: new Date(),
              kpi: DEFAULT_KPI,
              products: [],
              jobMatches: [],
              home: {
                configured: false,
                connected: false,
                unavailableCount: 0,
                activeCount: 0,
              },
            }),
            loading: false,
            error: "今天的简报没有完全同步，稍后会再试。",
          });
        }
      }
    }

    void loadToday();

    return () => {
      cancelled = true;
    };
  }, []);

  return state;
}
