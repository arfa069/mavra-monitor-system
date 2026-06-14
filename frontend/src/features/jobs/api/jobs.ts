import {
  jobsListConfigs,
  jobsGetConfig,
  jobsCreateConfig,
  jobsUpdateConfig,
  jobsDeleteConfig,
  jobsUpdateConfigCron,
  jobsListMatchResults,
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
  crawlProfilesImportProfileBackup,
} from "@/shared/api/generated/crawl-profiles/crawl-profiles";
import { encodePathSegment } from "@/shared/api/path";
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
  JobCrawlLogResponse,
  JobSearchConfigResponse,
  TaskProgressResponse,
  TaskQueuedResponse,
} from "@/shared/api/generated/models";
import type {
  JobConfigScheduleInfo,
  JobCrawlLog,
  JobSearchConfig,
} from "../types";

function normalizeJobConfig(
  config: JobSearchConfigResponse,
): JobSearchConfig {
  return {
    ...config,
    platform: config.platform ?? "boss",
  };
}

function normalizeJobCrawlLog(log: JobCrawlLogResponse): JobCrawlLog {
  return {
    ...log,
    error_message: log.error_message ?? null,
    new_jobs_count: log.new_jobs_count ?? null,
    total_jobs_count: log.total_jobs_count ?? null,
  };
}

async function requireQueuedTask(
  request: Promise<TaskQueuedResponse>,
): Promise<TaskQueuedResponse & { task_id: string }> {
  const response = await request;
  if (!response.task_id) {
    throw new Error(response.reason || "Job crawl did not return a task ID");
  }
  return { ...response, task_id: response.task_id };
}

export const jobsApi = {
  getConfigs: (active?: boolean) => {
    const params: JobsListConfigsParams = active !== undefined ? { active } : {};
    return jobsListConfigs(params).then((configs) =>
      configs.map(normalizeJobConfig),
    );
  },

  getConfig: (id: number) => jobsGetConfig(id).then(normalizeJobConfig),

  createConfig: (data: JobSearchConfigCreate) =>
    jobsCreateConfig(data).then(normalizeJobConfig),

  updateConfig: (id: number, data: JobSearchConfigUpdate) =>
    jobsUpdateConfig(id, data).then(normalizeJobConfig),

  deleteConfig: (id: number) => jobsDeleteConfig(id),

  updateConfigCron: (id: number, data: JobConfigCronUpdate) =>
    jobsUpdateConfigCron(id, data).then(normalizeJobConfig),

  getMatchResults: (params?: JobsListMatchResultsParams) =>
    jobsListMatchResults(params),

  getJobConfigSchedules: () =>
    jobsGetJobConfigSchedules().then((response) => ({
      configs: (response.configs ?? []).map(
        (item): JobConfigScheduleInfo & { config_id: number } => ({
          config_id: item.config_id,
          cron_expression: item.cron_expression ?? null,
          next_run_at: item.next_run_at ?? null,
        }),
      ),
    })),

  getJobs: (params?: JobsListJobsParams) => jobsListJobs(params),

  getJob: (jobId: string) => jobsGetJob(encodePathSegment(jobId)),

  crawlAll: () => requireQueuedTask(jobsCrawlNow()),

  crawlSingle: (configId: number) =>
    requireQueuedTask(jobsCrawlSingle(configId)),

  getCrawlStatus: (taskId: string): Promise<TaskProgressResponse> =>
    jobsGetJobCrawlStatus(encodePathSegment(taskId)),

  getCrawlResult: (taskId: string): Promise<TaskProgressResponse> =>
    jobsGetJobCrawlResult(encodePathSegment(taskId)),

  getCrawlLogs: (params?: JobsGetJobCrawlLogsParams) =>
    jobsGetJobCrawlLogs(params).then((logs) =>
      logs.map(normalizeJobCrawlLog),
    ),

  getProfiles: () => crawlProfilesListProfiles(),

  getProfileRuntimeCapabilities: () =>
    crawlProfilesGetRuntimeCapabilities(),

  createProfile: (data: CrawlProfileCreate) =>
    crawlProfilesCreateProfile(data),

  updateProfile: (profileKey: string, data: CrawlProfileUpdate) =>
    crawlProfilesUpdateProfile(encodePathSegment(profileKey), data),

  renameProfile: (profileKey: string, newProfileKey: string) =>
    crawlProfilesRenameProfile(encodePathSegment(profileKey), {
      profile_key: newProfileKey,
    }),

  copyProfile: (profileKey: string) =>
    crawlProfilesCopyProfile(encodePathSegment(profileKey)),

  deleteProfile: (profileKey: string) =>
    crawlProfilesDeleteProfile(encodePathSegment(profileKey)),

  releaseStaleProfile: (profileKey: string) =>
    crawlProfilesReleaseStaleProfile(encodePathSegment(profileKey)),

  openProfileLoginSession: (profileKey: string, data: CrawlProfileLoginSessionRequest) =>
    crawlProfilesOpenLoginSession(encodePathSegment(profileKey), data),

  closeProfileLoginSession: (profileKey: string) =>
    crawlProfilesCloseLoginSession(encodePathSegment(profileKey)),

  testProfile: (profileKey: string, data: CrawlProfileTestRequest) =>
    crawlProfilesTestProfile(encodePathSegment(profileKey), data),

  importProfileBackup: (
    profileKey: string,
    file: File,
    password: string,
    force: boolean,
  ) =>
    crawlProfilesImportProfileBackup(encodePathSegment(profileKey), {
      file,
      password,
      force,
    }),
};

export type JobCrawlStatus = TaskProgressResponse;
export type JobCrawlFinalResult = TaskProgressResponse;
