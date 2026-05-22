import type { Permission, User } from "@/shared/types";

export type { Permission, User };

export interface ResourcePermission {
  id: number;
  subject_id: number;
  subject_type: string;
  resource_type: string;
  resource_id: string;
  permission: string;
  granted_by: number;
  created_at: string;
}

export interface ResourcePermissionUpdate {
  resource_type?: string;
  resource_id?: string;
  permission?: string;
}

export interface ResourcePermissionGrant {
  subject_id: number;
  resource_type: string;
  resource_ids: string[];
  permission: string;
}

export interface ResourcePermissionListResponse {
  items: ResourcePermission[];
  total: number;
  page: number;
  page_size: number;
}

export interface PermissionInfo {
  name: Permission;
  description: string | null;
}

export interface RolePermissionInfo {
  role: "user" | "admin" | "super_admin";
  description: string | null;
  permissions: Permission[];
}

export interface RolePermissionMatrix {
  roles: RolePermissionInfo[];
  all_permissions: PermissionInfo[];
}

export interface RolePermissionUpdate {
  permissions: Permission[];
}
