import { useCallback, useState } from "react";
import { jobsApi } from "@/features/jobs";
import type { JobConfigScheduleInfo, JobSearchConfig } from "../types";
import { isValidCronExpression } from "../utils/cron";

export function useJobConfigSchedule(message: {
  error: (msg: string) => void;
  success: (msg: string) => void;
}) {
  const [list, setList] = useState<JobSearchConfig[]>([]);
  const [schedules, setSchedules] = useState<
    Record<number, JobConfigScheduleInfo>
  >({});
  const [loading, setLoading] = useState(false);
  const [cronInputs, setCronInputs] = useState<Record<number, string>>({});
  const [saving, setSaving] = useState<Record<number, boolean>>({});

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [configsRes, schedulesRes] = await Promise.all([
        jobsApi.getConfigs(),
        jobsApi.getJobConfigSchedules(),
      ]);
      const configs = configsRes.data;
      setList(configs);
      const scheduleMap: Record<number, JobConfigScheduleInfo> = {};
      schedulesRes.data.configs.forEach((item) => {
        scheduleMap[item.config_id] = item;
      });
      setSchedules(scheduleMap);
      const inputs: Record<number, string> = {};
      configs.forEach((configItem) => {
        inputs[configItem.id] = configItem.cron_expression || "";
      });
      setCronInputs(inputs);
    } catch {
      message.error("Failed to load job schedule config");
    } finally {
      setLoading(false);
    }
  }, [message]);

  const updateInput = useCallback((configId: number, value: string) => {
    setCronInputs((prev) => ({ ...prev, [configId]: value }));
  }, []);

  const save = useCallback(
    async (configId: number, value: string | null) => {
      if (!isValidCronExpression(value)) {
        message.error("Invalid cron expression");
        return;
      }

      setSaving((prev) => ({ ...prev, [configId]: true }));
      try {
        await jobsApi.updateConfigCron(configId, {
          cron_expression: value,
          cron_timezone: "Asia/Shanghai",
        });
        message.success("Saved");
        void load();
      } catch {
        message.error("Save failed");
      } finally {
        setSaving((prev) => ({ ...prev, [configId]: false }));
      }
    },
    [load, message],
  );

  return {
    list,
    schedules,
    loading,
    cronInputs,
    saving,
    load,
    updateInput,
    save,
  };
}
