export type CrawlProfileStatus =
  | "available"
  | "leased"
  | "login_required"
  | "cooling_down"
  | "disabled";

export interface CrawlProfile {
  profile_key: string;
  profile_dir: string;
  status: CrawlProfileStatus;
  platform_hint: string | null;
  lease_owner: string | null;
  lease_task_id: string | null;
  lease_until: string | null;
  last_used_at: string | null;
  last_error: string | null;
  created_at: string;
  updated_at: string;
}

export interface CrawlProfileCreate {
  profile_key: string;
  platform_hint?: string | null;
}

export interface CrawlProfileUpdate {
  status?: "available" | "login_required" | "disabled" | null;
  platform_hint?: string | null;
  last_error?: string | null;
}

export interface CrawlProfileRuntimeCapabilities {
  os: string;
  mode: "local_gui" | "headless_server";
  supports_login_session: boolean;
  supports_profile_import: boolean;
  supports_profile_export: boolean;
  recommended_action: "open_login_browser" | "import_profile_backup";
}

export interface CrawlProfileLoginSession {
  profile_key: string;
  platform: string;
  status: "active" | "closed" | "failed";
  start_url: string;
  message?: string | null;
}

export interface CrawlProfileTestResult {
  profile_key: string;
  platform: string;
  status: "ready" | "login_required" | "risk_blocked" | "error";
  message?: string | null;
}

export interface JobConfigScheduleInfo {
  cron_expression: string | null;
  next_run_at: string | null;
}

export interface JobConfigCronUpdate {
  cron_expression: string | null;
  cron_timezone?: string | null;
}

export interface JobSearchConfig {
  id: number;
  user_id: number;
  name: string;
  profile_key: string;
  platform: "boss" | "51job" | "liepin";
  keyword: string | null;
  city_code: string | null;
  salary_min: number | null;
  salary_max: number | null;
  experience: string | null;
  education: string | null;
  url: string;
  active: boolean;
  notify_on_new: boolean;
  deactivation_threshold: number;
  cron_expression: string | null;
  cron_timezone: string | null;
  enable_match_analysis: boolean;
  created_at: string;
  updated_at: string;
}

export interface JobSearchConfigCreate {
  name: string;
  profile_key?: string;
  platform?: "boss" | "51job" | "liepin";
  keyword?: string;
  city_code?: string;
  salary_min?: number;
  salary_max?: number;
  experience?: string;
  education?: string;
  url: string;
  active?: boolean;
  notify_on_new?: boolean;
  deactivation_threshold?: number;
  cron_expression?: string | null;
  cron_timezone?: string | null;
  enable_match_analysis?: boolean;
}

export interface JobSearchConfigUpdate {
  name?: string;
  profile_key?: string;
  platform?: "boss" | "51job" | "liepin";
  keyword?: string;
  city_code?: string;
  salary_min?: number;
  salary_max?: number;
  experience?: string;
  education?: string;
  url?: string;
  active?: boolean;
  notify_on_new?: boolean;
  deactivation_threshold?: number;
  cron_expression?: string | null;
  cron_timezone?: string | null;
  enable_match_analysis?: boolean;
}

export interface Job {
  id: number;
  job_id: string;
  search_config_id: number;
  platform: "boss" | "51job" | "liepin";
  title: string | null;
  company: string | null;
  company_id: string | null;
  salary: string | null;
  salary_min: number | null;
  salary_max: number | null;
  location: string | null;
  experience: string | null;
  education: string | null;
  description: string | null;
  address: string | null;
  url: string | null;
  first_seen_at: string;
  last_updated_at: string;
  is_active: boolean;
  permissions?: Record<string, boolean> | null;
  apply_recommendation?: string | null;
}

export interface JobListResponse {
  items: Job[];
  total: number;
  page: number;
  page_size: number;
}

export interface JobCrawlLog {
  id: number;
  search_config_id: number;
  status: string;
  new_jobs_count: number | null;
  total_jobs_count: number | null;
  error_message: string | null;
  scraped_at: string;
}

export interface UserResume {
  id: number;
  user_id: number;
  name: string;
  resume_text: string;
  created_at: string;
  updated_at: string;
}

export interface UserResumeCreateRequest {
  name: string;
  resume_text: string;
}

export interface UserResumeUpdateRequest {
  name?: string;
  resume_text?: string;
}

export type MatchResultWithJob = MatchResultResponse;
export type MatchResultListResponse = GeneratedMatchResultListResponse;

export interface MatchAnalyzeRequest {
  resume_id: number;
  job_ids?: number[] | null;
}

import type {
  MatchResultListResponse as GeneratedMatchResultListResponse,
  MatchResultResponse,
} from "@/shared/api/generated/models";
