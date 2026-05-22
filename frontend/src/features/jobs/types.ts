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

export interface MatchResultWithJob {
  id: number;
  user_id: number;
  resume_id: number;
  job_id: number;
  match_score: number;
  match_reason: string | null;
  apply_recommendation: string | null;
  llm_model_used: string | null;
  created_at: string;
  updated_at: string;
  job_title: string | null;
  job_company: string | null;
  job_salary: string | null;
  job_location: string | null;
  job_url: string | null;
  job_description: string | null;
}

export interface MatchResultListResponse {
  items: MatchResultWithJob[];
  total: number;
  page: number;
  page_size: number;
}

export interface MatchAnalyzeRequest {
  resume_id: number;
  job_ids?: number[] | null;
}

export interface MatchAnalyzeResponse {
  processed: number;
  created: number;
  updated: number;
  skipped: number;
  items: MatchResultWithJob[];
}
