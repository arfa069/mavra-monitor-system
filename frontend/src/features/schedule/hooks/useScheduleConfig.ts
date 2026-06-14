import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { configApi } from "@/features/settings";

export const useScheduleConfig = () =>
  useQuery({
    queryKey: ["config"],
    queryFn: () => configApi.get(),
  });

export const useUpdateScheduleConfig = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: configApi.update,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["config"] }),
  });
};
