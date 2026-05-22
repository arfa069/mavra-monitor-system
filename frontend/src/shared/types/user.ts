import type { Permission } from "./permissions";

export interface User {
  id: number;
  username: string;
  email: string;
  role: "user" | "admin" | "super_admin";
  permissions: Permission[];
  is_active?: boolean;
  created_at?: string;
  feishu_webhook_url?: string;
  data_retention_days?: number;
}
