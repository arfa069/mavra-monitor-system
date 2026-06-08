import type { User } from "../../shared/types/user";
import type { UserConfig } from "./types";

export function applyUserConfig(user: User, config: UserConfig): User {
  return {
    ...user,
    feishu_webhook_url: config.feishu_webhook_url,
    data_retention_days: config.data_retention_days,
  };
}
