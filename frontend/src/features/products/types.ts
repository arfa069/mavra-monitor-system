export interface Product {
  id: number;
  user_id: number;
  platform: string;
  url: string;
  platform_product_id?: string | null;
  title: string | null;
  active: boolean;
  created_at: string;
  updated_at: string;
  permissions?: Record<string, boolean> | null;
}

export interface ProductListResponse {
  items: Product[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
  has_next: boolean;
  has_prev: boolean;
}

export interface ProductCreateRequest {
  platform: "taobao" | "jd" | "amazon";
  url: string;
  title?: string;
  active?: boolean;
}

export interface ProductUpdateRequest {
  title?: string;
  active?: boolean;
  url?: string;
}

export interface ProductFormValues {
  platform?: "taobao" | "jd" | "amazon";
  url: string;
  title?: string;
  active?: boolean;
}

export interface BatchImportRow {
  url: string;
  platform: string;
  title?: string;
}

export interface BatchCreateItem {
  url: string;
  platform: "taobao" | "jd" | "amazon";
  title?: string;
}

export interface BatchOperationResult {
  id: number | null;
  url: string | null;
  success: boolean;
  error: string | null;
}

export interface ProductPlatformCronSchedule {
  cron_expression: string | null;
  next_run_at: string | null;
}

export interface ProductPlatformCron {
  id: number;
  user_id: number;
  platform: string;
  cron_expression: string | null;
  cron_timezone: string;
  profile_key: string;
  created_at: string;
  updated_at: string;
}

export interface ProductPlatformCronCreate {
  platform: string;
  cron_expression?: string | null;
  cron_timezone?: string | null;
  profile_key?: string | null;
}

export interface ProductPlatformCronUpdate {
  cron_expression: string | null;
  cron_timezone?: string | null;
  profile_key?: string | null;
}

export interface PriceHistoryRecord {
  id: number;
  product_id: number;
  price: number;
  scraped_at: string;
}

export interface CrawlLog {
  id: number;
  product_id: number | null;
  platform: string | null;
  status: string | null;
  price: number | null;
  currency: string | null;
  timestamp: string;
  error_message: string | null;
}
