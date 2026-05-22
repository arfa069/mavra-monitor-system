import api from "@/shared/api/client";
import type {
  Job,
  JobConfigCronUpdate,
  JobConfigScheduleInfo,
  JobCrawlLog,
  JobListResponse,
  JobSearchConfig,
  JobSearchConfigCreate,
  JobSearchConfigUpdate,
} from "../types";

export interface JobCrawlStatus {
  task_id: string;
  status: "pending" | "running" | "completed" | "failed";
  total: number;
  success: number;
  errors: number;
}

export interface JobCrawlFinalResult {
  status: string;
  task_id: string;
  total: number;
  success: number;
  errors: number;
  reason?: string;
}

export const jobsApi = {
  getConfigs: (active?: boolean) =>
    api.get<JobSearchConfig[]>("/v1/jobs/configs", {
      params: active !== undefined ? { active } : undefined,
    }),

  getConfig: (id: number) => api.get<JobSearchConfig>(`/v1/jobs/configs/${id}`),

  createConfig: (data: JobSearchConfigCreate) =>
    api.post<JobSearchConfig>("/v1/jobs/configs", data),

  updateConfig: (id: number, data: JobSearchConfigUpdate) =>
    api.patch<JobSearchConfig>(`/v1/jobs/configs/${id}`, data),

  deleteConfig: (id: number) => api.delete(`/v1/jobs/configs/${id}`),

  updateConfigCron: (id: number, data: JobConfigCronUpdate) =>
    api.patch<JobSearchConfig>(`/v1/jobs/configs/${id}/cron`, data),

  getResumes: () => api.get("/v1/jobs/resumes"),

  createResume: (data: { name: string; resume_text: string }) =>
    api.post("/v1/jobs/resumes", data),

  updateResume: (id: number, data: { name?: string; resume_text?: string }) =>
    api.patch(`/v1/jobs/resumes/${id}`, data),

  deleteResume: (id: number) => api.delete(`/v1/jobs/resumes/${id}`),

  getMatchResults: (params?: {
    resume_id?: number;
    job_id?: number;
    min_score?: number;
    page?: number;
    page_size?: number;
  }) => api.get("/v1/jobs/match-results", { params }),

  triggerMatch: (data: { resume_id: number; job_ids?: number[] | null }) =>
    api.post("/v1/jobs/match-results/analyze", data),

  getJobConfigSchedules: () =>
    api.get<{ configs: (JobConfigScheduleInfo & { config_id: number })[] }>(
      "/v1/jobs/scheduler/job-configs",
    ),

  getJobs: (params?: {
    search_config_id?: number;
    keyword?: string;
    company?: string;
    salary_min?: number;
    salary_max?: number;
    location?: string;
    is_active?: boolean;
    sort_by?: string;
    sort_order?: string;
    page?: number;
    page_size?: number;
  }) => api.get<JobListResponse>("/v1/jobs", { params }),

  getJob: (jobId: string) => api.get<Job>(`/v1/jobs/${jobId}`),

  crawlAll: () =>
    api.post<{ status: string; task_id: string; message: string }>(
      "/v1/jobs/crawl-now",
      undefined,
      { timeout: 10000 },
    ),

  crawlSingle: (configId: number) =>
    api.post<{ status: string; task_id: string; message: string }>(
      `/v1/jobs/crawl-now/${configId}`,
      undefined,
      { timeout: 10000 },
    ),

  getCrawlStatus: (taskId: string) =>
    api.get<JobCrawlStatus>(`/v1/jobs/crawl/status/${taskId}`),

  getCrawlResult: (taskId: string) =>
    api.get<JobCrawlFinalResult>(`/v1/jobs/crawl/result/${taskId}`),

  getCrawlLogs: (params?: {
    search_config_id?: number;
    status?: string;
    hours?: number;
    limit?: number;
  }) => api.get<JobCrawlLog[]>("/v1/jobs/crawl-logs", { params }),
};
