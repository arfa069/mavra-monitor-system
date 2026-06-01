export interface UserKPI {
  total_products: number;
  price_drops_today: number;
  new_jobs_today: number;
  match_count: number;
  crawl_count_today: number;
}

export interface SystemKPI {
  total_users: number;
  total_crawls: number;
  success_rate: number;
  active_alerts: number;
  disk_usage: number;
  memory_usage: number;
}

export interface DashboardKPIResponse {
  user: UserKPI;
  system?: SystemKPI | null;
}

export interface TrendDataPoint {
  label: string;
  value: number;
}

export interface TrendDataset {
  label: string;
  data: TrendDataPoint[];
}

export interface TrendResponse {
  labels: string[];
  datasets: TrendDataset[];
}

export interface RecentAlert {
  id: number;
  product_id: number | null;
  alert_type: string;
  message: string;
  active: boolean;
  created_at: string | null;
  product_title: string | null;
  platform: string | null;
}

export type TrendType =
  | "price"
  | "jobs"
  | "platform_products"
  | "platform_jobs"
  | "salary"
  | "system_health"
  | "platform_success"
  | "price_change"
  | "job_matches"
  | "crawl_failures";

export type TimeRange = 7 | 30 | 90;
