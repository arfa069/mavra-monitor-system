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
  AdminListUsersParams,
  AdminListAuditLogsParams,
  AdminListResourcePermissionsParams,
} from "@/shared/api/generated/models";
import { encodePathSegment } from "@/shared/api/path";

export type { AuditLog, AuditLogListResponse, UserListResponse, UserCreate, UserUpdate };

export const adminApi = {
  listUsers: (params: AdminListUsersParams) => adminListUsers(params),

  createUser: (data: UserCreate) => adminCreateUser(data),

  updateUser: (id: number, data: UserUpdate) => adminUpdateUser(id, data),

  deleteUser: (id: number) => adminDeleteUser(id),

  getAuditLogs: (params: AdminListAuditLogsParams) =>
    adminListAuditLogs(params),

  listResourcePermissions: (params: AdminListResourcePermissionsParams) =>
    adminListResourcePermissions(params),

  grantResourcePermission: (grant: ResourcePermissionGrant) =>
    adminGrantResourcePermission(grant),

  revokeResourcePermission: (id: number) =>
    adminRevokeResourcePermission(id),

  updateResourcePermission: (id: number, data: ResourcePermissionUpdate) =>
    adminUpdateResourcePermission(id, data),

  getRolePermissionMatrix: () => adminGetRolePermissionMatrix(),

  updateRolePermissions: (role: string, data: RolePermissionUpdate) =>
    adminUpdateRolePermissions(encodePathSegment(role), data),
};
