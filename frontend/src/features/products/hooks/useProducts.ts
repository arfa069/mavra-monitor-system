import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { crawlApi } from "../api/crawl";
import { productsApi } from "../api/products";
import type { CrawlLog } from "../types";

export type CrawlNowMutationResult =
  | { type: "skipped"; reason?: string }
  | { type: "error"; reason?: string }
  | {
      type: "completed";
      total: number;
      success: number;
      errors: number;
      details: unknown[];
    };

export const productQueryKeys = {
  all: ["products"] as const,
  list: (params: {
    platform?: string;
    active?: boolean;
    keyword?: string;
    page?: number;
    size?: number;
  }) =>
    [
      ...productQueryKeys.all,
      params.platform ?? "",
      params.active ?? "",
      params.keyword ?? "",
      params.page ?? 1,
      params.size ?? 15,
    ] as const,
  history: (id: number, days: number) => ["product-history", id, days] as const,
  crawlLogs: (params?: {
    product_id?: number;
    hours?: number;
    limit?: number;
  }) => ["crawl-logs", params] as const,
};

export const useProducts = (params: {
  platform?: string;
  active?: boolean;
  keyword?: string;
  page?: number;
  size?: number;
}) =>
  useQuery({
    queryKey: productQueryKeys.list(params),
    queryFn: () => productsApi.list(params).then((res) => res.data),
    staleTime: 10_000,
  });

export const useCreateProduct = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: productsApi.create,
    onSuccess: () => qc.invalidateQueries({ queryKey: productQueryKeys.all }),
  });
};

export const useUpdateProduct = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: number;
      data: Parameters<typeof productsApi.update>[1];
    }) => productsApi.update(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: productQueryKeys.all }),
  });
};

export const useDeleteProduct = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: productsApi.delete,
    onSuccess: () => qc.invalidateQueries({ queryKey: productQueryKeys.all }),
  });
};

export const useBatchCreate = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: productsApi.batchCreate,
    onSuccess: () => qc.invalidateQueries({ queryKey: productQueryKeys.all }),
  });
};

export const useBatchDelete = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: productsApi.batchDelete,
    onSuccess: () => qc.invalidateQueries({ queryKey: productQueryKeys.all }),
  });
};

export const useBatchUpdate = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ ids, active }: { ids: number[]; active?: boolean }) =>
      productsApi.batchUpdate(ids, active),
    onSuccess: () => qc.invalidateQueries({ queryKey: productQueryKeys.all }),
  });
};

export const useProductHistory = (id: number, days = 30) =>
  useQuery({
    queryKey: productQueryKeys.history(id, days),
    queryFn: () => productsApi.history(id, days).then((res) => res.data),
    enabled: !!id,
  });

export const useCrawlNow = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (): Promise<CrawlNowMutationResult> => {
      const response = await crawlApi.crawlNow();
      const data = response.data;
      if (data.status === "skipped")
        return { type: "skipped", reason: data.reason };
      if (data.status === "error")
        return { type: "error", reason: data.reason };

      const taskId = data.task_id!;
      for (let attempts = 0; attempts < 60; attempts += 1) {
        await new Promise((resolve) => setTimeout(resolve, 3000));
        try {
          const statusRes = await crawlApi.getStatus(taskId);
          const status = statusRes.data;
          if (status.status === "completed") {
            const resultRes = await crawlApi.getResult(taskId);
            const result = resultRes.data;
            qc.invalidateQueries({ queryKey: ["crawl-logs"] });
            return {
              type: "completed",
              total: result.total ?? 0,
              success: result.success ?? 0,
              errors: result.errors ?? 0,
              details: result.details ?? [],
            };
          }
          if (status.status === "failed")
            return { type: "error", reason: status.reason };
        } catch (e) {
          console.warn("Polling error:", e);
        }
      }
      return { type: "error", reason: "timeout_polling" };
    },
  });
};

export const useCrawlLogs = (params?: {
  product_id?: number;
  hours?: number;
  limit?: number;
}) =>
  useQuery<CrawlLog[]>({
    queryKey: productQueryKeys.crawlLogs(params),
    queryFn: () => crawlApi.getLogs(params).then((res) => res.data),
    refetchInterval: 60_000,
  });
