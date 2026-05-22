export type { MotionSpeed } from "@/shared/types";

export interface UserConfig {
  id: number;
  username: string;
  feishu_webhook_url: string;
  data_retention_days: number;
  created_at: string | null;
  updated_at: string | null;
}

export interface SchedulerJobStatus {
  registered: boolean;
  cron_expression: string | null;
  next_run_at: string | null;
}

export interface ProductPlatformCronSchedule {
  cron_expression: string | null;
  next_run_at: string | null;
}

export interface JobConfigScheduleInfo {
  cron_expression: string | null;
  next_run_at: string | null;
}

export interface SchedulerStatusResponse {
  scheduler: string;
  timezone: string;
  jobs: {
    product_crawl: SchedulerJobStatus;
    product_platforms: Record<string, ProductPlatformCronSchedule>;
    job_configs: Record<string, JobConfigScheduleInfo>;
  };
}
