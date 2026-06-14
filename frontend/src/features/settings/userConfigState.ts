import type { User } from "../../shared/types/user";
import type { UserConfigResponse } from "@/shared/api/generated/models";

export function applyUserConfig(user: User, config: UserConfigResponse): User {
  return {
    ...user,
    feishu_webhook_url: config.feishu_webhook_url ?? undefined,
    data_retention_days:
      config.data_retention_days ?? user.data_retention_days,
  };
}
