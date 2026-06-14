import api from "@/shared/api/client";
import {
  jobsListConfigs,
  jobsGetConfig,
  jobsCreateConfig,
  jobsUpdateConfig,
  jobsDeleteConfig,
  jobsUpdateConfigCron,
  jobsListResumes,
  jobsCreateResume,
  jobsUpdateResume,
  jobsDeleteResume,
  jobsListMatchResults,
  jobsTriggerMatchAnalysis,
  jobsGetJobConfigSchedules,
  jobsListJobs,
  jobsGetJob,
  jobsCrawlNow,
  jobsCrawlSingle,
  jobsGetJobCrawlStatus,
  jobsGetJobCrawlResult,
  jobsGetJobCrawlLogs,
} from "@/shared/api/generated/jobs/jobs";
import {
  crawlProfilesListProfiles,
  crawlProfilesGetRuntimeCapabilities,
  crawlProfilesCreateProfile,
  crawlProfilesUpdateProfile,
  crawlProfilesRenameProfile,
  crawlProfilesCopyProfile,
  crawlProfilesDeleteProfile,
  crawlProfilesReleaseStaleProfile,
  crawlProfilesOpenLoginSession,
  crawlProfilesCloseLoginSession,
  crawlProfilesTestProfile,
} from "@/shared/api/generated/crawl-profiles/crawl-profiles";
import type {
  JobSearchConfigCreate,
  JobSearchConfigUpdate,
  JobConfigCronUpdate,
  JobsListConfigsParams,
  JobsListJobsParams,
  JobsListMatchResultsParams,
  JobsGetJobCrawlLogsParams,
  CrawlProfileCreate,
  CrawlProfileUpdate,
  CrawlProfileLoginSessionRequest,
  CrawlProfileTestRequest,
  MatchAnalyzeRequest,
} from "@/shared/api/generated/models";
import type {
  CrawlProfile,
  CrawlProfileLoginSession,
  CrawlProfileRuntimeCapabilities,
  CrawlProfileTestResult,
  Job,
  JobConfigScheduleInfo,
  JobCrawlLog,
  JobListResponse,
  JobSearchConfig,
  UserResume,
} from "../types";

export const jobsApi = {
  getConfigs: (active?: boolean) => {
    const params: JobsListConfigsParams = active !== undefined ? { active } : {};
    return jobsListConfigs(params) as unknown as Promise<JobSearchConfig[]>;
  },

  getConfig: (id: number) => jobsGetConfig(id) as unknown as Promise<JobSearchConfig>,

  createConfig: (data: JobSearchConfigCreate) => jobsCreateConfig(data) as unknown as Promise<JobSearchConfig>,

  updateConfig: (id: number, data: JobSearchConfigUpdate) => jobsUpdateConfig(id, data) as unknown as Promise<JobSearchConfig>,

  deleteConfig: (id: number) => jobsDeleteConfig(id) as unknown as Promise<void>,

  updateConfigCron: (id: number, data: JobConfigCronUpdate) => jobsUpdateConfigCron(id, data) as unknown as Promise<JobSearchConfig>,

  getResumes: () => jobsListResumes() as unknown as Promise<UserResume[]>,

  createResume: (data: { name: string; resume_text: string }) =>
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    jobsCreateResume(data as any) as unknown as Promise<UserResume>,

  updateResume: (id: number, data: { name?: string; resume_text?: string }) =>
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    jobsUpdateResume(id, data as any) as unknown as Promise<UserResume>,

  deleteResume: (id: number) => jobsDeleteResume(id) as unknown as Promise<void>,

  getMatchResults: (params?: JobsListMatchResultsParams) => jobsListMatchResults(params) as unknown as Promise<any>,

  triggerMatch: (data: MatchAnalyzeRequest) => jobsTriggerMatchAnalysis(data) as unknown as Promise<any>,

  getJobConfigSchedules: () => jobsGetJobConfigSchedules() as unknown as Promise<{ configs: (JobConfigScheduleInfo & { config_id: number })[] }>,

  getJobs: (params?: JobsListJobsParams) => jobsListJobs(params) as unknown as Promise<JobListResponse>,

  getJob: (jobId: string) => jobsGetJob(jobId) as unknown as Promise<Job>,

  crawlAll: () => jobsCrawlNow() as unknown as Promise<{ status: string; task_id: string; message: string }>,

  crawlSingle: (configId: number) => jobsCrawlSingle(configId) as unknown as Promise<{ status: string; task_id: string; message: string }>,

  getCrawlStatus: (taskId: string) => jobsGetJobCrawlStatus(taskId) as unknown as Promise<JobCrawlStatus>,

  getCrawlResult: (taskId: string) => jobsGetJobCrawlResult(taskId) as unknown as Promise<JobCrawlFinalResult>,

  getCrawlLogs: (params?: JobsGetJobCrawlLogsParams) => jobsGetJobCrawlLogs(params) as unknown as Promise<JobCrawlLog[]>,

  getProfiles: () => crawlProfilesListProfiles() as unknown as Promise<CrawlProfile[]>,

  getProfileRuntimeCapabilities: () => crawlProfilesGetRuntimeCapabilities() as unknown as Promise<CrawlProfileRuntimeCapabilities>,

  createProfile: (data: CrawlProfileCreate) => crawlProfilesCreateProfile(data) as unknown as Promise<CrawlProfile>,

  updateProfile: (profileKey: string, data: CrawlProfileUpdate) => crawlProfilesUpdateProfile(profileKey, data) as unknown as Promise<CrawlProfile>,

  renameProfile: (profileKey: string, newProfileKey: string) =>
    crawlProfilesRenameProfile(profileKey, { profile_key: newProfileKey }) as unknown as Promise<CrawlProfile>,

  copyProfile: (profileKey: string) => crawlProfilesCopyProfile(profileKey) as unknown as Promise<CrawlProfile>,

  deleteProfile: (profileKey: string) => crawlProfilesDeleteProfile(profileKey) as unknown as Promise<void>,

  releaseStaleProfile: (profileKey: string) => crawlProfilesReleaseStaleProfile(profileKey) as unknown as Promise<CrawlProfile>,

  openProfileLoginSession: (profileKey: string, data: CrawlProfileLoginSessionRequest) =>
    crawlProfilesOpenLoginSession(profileKey, data) as unknown as Promise<CrawlProfileLoginSession>,

  closeProfileLoginSession: (profileKey: string) => crawlProfilesCloseLoginSession(profileKey) as unknown as Promise<CrawlProfileLoginSession>,

  testProfile: (profileKey: string, data: CrawlProfileTestRequest) =>
    crawlProfilesTestProfile(profileKey, data) as unknown as Promise<CrawlProfileTestResult>,

  exportProfileBackup: (profileKey: string, password: string) =>
    api.post<Blob>(
      `/crawl-profiles/${profileKey}/export`,
      { password },
      { responseType: "blob" },
    ),

  importProfileBackup: (
    profileKey: string,
    file: File,
    password: string,
    force: boolean,
  ) => {
    const form = new FormData();
    form.append("file", file);
    form.append("password", password);
    form.append("force", String(force));
    return api.post<{ profile_key: string; imported: boolean }>(
      `/crawl-profiles/${profileKey}/import`,
      form,
    );
  },
};

export interface JobCrawlStatus {
  task_id: string;
  status: "pending" | "running" | "completed" | "failed";
  total: number;
  success: number;
  errors: number;
  reason?: string | null;
  worker_id?: string | null;
  heartbeat_at?: string | null;
  lease_until?: string | null;
  started_at?: string | null;
  finished_at?: string | null;
  details?: Array<Record<string, unknown>> | null;
}

export interface JobCrawlFinalResult {
  status: string;
  task_id: string;
  total: number;
  success: number;
  errors: number;
  reason?: string | null;
  details?: Array<Record<string, unknown>> | null;
  worker_id?: string | null;
  heartbeat_at?: string | null;
  lease_until?: string | null;
  started_at?: string | null;
  finished_at?: string | null;
}
