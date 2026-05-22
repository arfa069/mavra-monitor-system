import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { alertsApi } from "../api/alerts";
import type { AlertUpdateRequest } from "../types";

export const useAlerts = (productId?: number) =>
  useQuery({
    queryKey: ["alerts", productId],
    queryFn: () =>
      alertsApi
        .list(productId !== undefined ? { product_id: productId } : undefined)
        .then((res) => res.data),
    enabled: productId !== undefined,
  });

export const useAllAlerts = () =>
  useQuery({
    queryKey: ["alerts", "all"],
    queryFn: () => alertsApi.list().then((res) => res.data),
  });

export const useCreateAlert = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: alertsApi.create,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["alerts"] }),
  });
};

export const useUpdateAlert = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: AlertUpdateRequest }) =>
      alertsApi.update(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["alerts"] }),
  });
};

export const useDeleteAlert = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: alertsApi.delete,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["alerts"] }),
  });
};
