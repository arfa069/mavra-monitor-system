import {
  adminListUsers,
  adminCreateUser,
  adminUpdateUser,
  adminDeleteUser,
  adminListAuditLogs,
  adminListResourcePermissions,
  adminGrantResourcePermission,
  adminRevokeResourcePermission,
  adminUpdateResourcePermission,
  adminGetRolePermissionMatrix,
  adminUpdateRolePermissions,
} from "@/shared/api/generated/admin/admin";
import type {
  UserCreate,
  AdminUserUpdate as UserUpdate,
  ResourcePermissionGrant,
  ResourcePermissionUpdate,
  RolePermissionUpdate,
  AuditLogResponse as AuditLog,
  AuditLogListResponse,
  AdminUserListResponse as UserListResponse,
} from "@/shared/api/generated/models";

export type { AuditLog, AuditLogListResponse, UserListResponse, UserCreate, UserUpdate };

export const adminApi = {
  listUsers: (params: {
    page?: number;
    page_size?: number;
    search?: string;
    role?: string;
  }) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminListUsers(params as any) as any;
  },

  createUser: (data: UserCreate) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminCreateUser(data) as any;
  },

  updateUser: (id: number, data: UserUpdate) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminUpdateUser(id, data as any) as any;
  },

  deleteUser: (id: number) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminDeleteUser(id) as any;
  },

  getAuditLogs: (params: {
    page?: number;
    page_size?: number;
    actor_user_id?: number;
    action?: string;
  }) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminListAuditLogs(params as any) as any;
  },

  listResourcePermissions: (params: {
    user_id?: number;
    resource_type?: string;
    page?: number;
    page_size?: number;
  }) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminListResourcePermissions(params as any) as any;
  },

  grantResourcePermission: (grant: ResourcePermissionGrant) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminGrantResourcePermission(grant) as any;
  },

  revokeResourcePermission: (id: number) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminRevokeResourcePermission(id) as any;
  },

  updateResourcePermission: (id: number, data: ResourcePermissionUpdate) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminUpdateResourcePermission(id, data) as any;
  },

  getRolePermissionMatrix: () => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminGetRolePermissionMatrix() as any;
  },

  updateRolePermissions: (role: string, data: RolePermissionUpdate) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return adminUpdateRolePermissions(role, data) as any;
  },
};
