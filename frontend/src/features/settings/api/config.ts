import {
  configGetConfig,
  configUpdateConfigPartial,
} from "@/shared/api/generated/config/config";
import { schedulerGetSchedulerStatus } from "@/shared/api/generated/scheduler/scheduler";
import type { UserConfigUpdate } from "@/shared/api/generated/models";

export const configApi = {
  get: () => configGetConfig(),

  update: (data: UserConfigUpdate) => configUpdateConfigPartial(data),

  getSchedulerStatus: () => schedulerGetSchedulerStatus(),
};
