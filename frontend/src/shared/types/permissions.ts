export type Permission =
  | "user:read"
  | "user:manage"
  | "user:delete"
  | "crawl:execute"
  | "crawl:read_logs"
  | "schedule:read"
  | "schedule:configure"
  | "config:read"
  | "config:write"
  | "product:read"
  | "product:write"
  | "product:delete"
  | "job:read"
  | "job:write"
  | "job:delete"
  | "rbac:read"
  | "rbac:manage";

export type PermissionLevel = "manage" | "edit" | "read" | null;
