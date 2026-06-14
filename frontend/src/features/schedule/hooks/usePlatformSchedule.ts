import { useCallback, useState } from "react";
import { productsApi } from "@/features/products";
import type {
  ProductPlatformCron,
  ProductPlatformCronSchedule,
} from "../types";

export function usePlatformSchedule(message: {
  error: (msg: string) => void;
  success: (msg: string) => void;
}) {
  const [configs, setConfigs] = useState<ProductPlatformCron[]>([]);
  const [schedules, setSchedules] = useState<
    Record<string, ProductPlatformCronSchedule>
  >({});
  const [loading, setLoading] = useState(false);
  const [cronInputs, setCronInputs] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState<Record<string, boolean>>({});

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [configsRes, schedulesRes] = await Promise.all([
        productsApi.getCronConfigs(),
        productsApi.getCronSchedules(),
      ]);
      const configs = configsRes;
      setConfigs(configs as unknown as ProductPlatformCron[]);
      setSchedules(schedulesRes.platforms as unknown as Record<string, ProductPlatformCronSchedule>);
      const inputs: Record<string, string> = {};
      configs.forEach((configItem) => {
        inputs[configItem.platform] = configItem.cron_expression || "";
      });
      setCronInputs(inputs);
    } catch {
      message.error("Failed to load product schedule config");
    } finally {
      setLoading(false);
    }
  }, [message]);

  const updateInput = useCallback((platform: string, value: string) => {
    setCronInputs((prev) => ({ ...prev, [platform]: value }));
  }, []);

  const save = useCallback(
    async (platform: string, value: string | null) => {
      setSaving((prev) => ({ ...prev, [platform]: true }));
      try {
        await productsApi.updateCronConfig(platform, {
          cron_expression: value,
          cron_timezone: "Asia/Shanghai",
        });
        message.success("Saved");
        void load();
      } catch {
        message.error("Save failed");
      } finally {
        setSaving((prev) => ({ ...prev, [platform]: false }));
      }
    },
    [load, message],
  );

  const remove = useCallback(
    async (platform: string) => {
      try {
        await productsApi.deleteCronConfig(platform);
        message.success("Deleted");
        void load();
      } catch {
        message.error("Delete failed");
      }
    },
    [load, message],
  );

  const create = useCallback(
    async (platform: string, cronExpression: string | null) => {
      await productsApi.createCronConfig({
        platform,
        cron_expression: cronExpression,
        cron_timezone: "Asia/Shanghai",
      });
      message.success("Added");
      void load();
    },
    [load, message],
  );

  return {
    configs,
    schedules,
    loading,
    cronInputs,
    saving,
    load,
    updateInput,
    save,
    remove,
    create,
  };
}
