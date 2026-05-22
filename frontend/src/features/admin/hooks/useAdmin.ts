import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { adminApi } from "../api/admin";
import type {
  Permission,
  ResourcePermissionGrant,
  ResourcePermissionUpdate,
} from "../types";

export const useResourcePermissions = (params: {
  user_id?: number;
  resource_type?: string;
  page?: number;
  page_size?: number;
}) =>
  useQuery({
    queryKey: ["resource-permissions", params],
    queryFn: () => adminApi.listResourcePermissions(params),
  });

export const useGrantResourcePermission = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (grant: ResourcePermissionGrant) =>
      adminApi.grantResourcePermission(grant),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["resource-permissions"] });
    },
  });
};

export const useRevokeResourcePermission = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => adminApi.revokeResourcePermission(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["resource-permissions"] });
    },
  });
};

export const useUpdateResourcePermission = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: number;
      data: ResourcePermissionUpdate;
    }) => adminApi.updateResourcePermission(id, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["resource-permissions"] });
    },
  });
};

export const useRolePermissionMatrix = () =>
  useQuery({
    queryKey: ["role-permission-matrix"],
    queryFn: () => adminApi.getRolePermissionMatrix(),
  });

export const useUpdateRolePermissions = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      role,
      permissions,
    }: {
      role: string;
      permissions: Permission[];
    }) => adminApi.updateRolePermissions(role, { permissions }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["role-permission-matrix"] });
    },
  });
};
