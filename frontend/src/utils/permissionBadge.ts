import type { PermissionLevel } from "@/shared/types";

export function getBadgeLevel(
  permissions?: Record<string, boolean> | null,
): PermissionLevel {
  if (!permissions) return null;
  if (permissions.read && permissions.write && permissions.delete)
    return "manage";
  if (permissions.read && permissions.write) return "edit";
  if (permissions.read) return "read";
  return null;
}
