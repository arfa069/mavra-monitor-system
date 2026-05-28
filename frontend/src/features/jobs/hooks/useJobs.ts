import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { jobMatchApi } from "../api/job_match";
import { jobsApi } from "../api/jobs";
import type {
  JobCrawlLog,
  JobSearchConfigUpdate,
  MatchAnalyzeRequest,
  UserResumeCreateRequest,
  UserResumeUpdateRequest,
} from "../types";

export const jobQueryKeys = {
  configs: (active?: boolean) => ["job-configs", active] as const,
  config: (id: number) => ["job-config", id] as const,
  jobs: (params?: {
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
  }) => ["jobs", params] as const,
  job: (jobId: string) => ["job", jobId] as const,
  crawlLogs: (params?: {
    search_config_id?: number;
    status?: string;
    hours?: number;
    limit?: number;
  }) => ["job-crawl-logs", params] as const,
  resumes: ["resumes"] as const,
  matchResults: (params?: {
    resume_id?: number;
    job_id?: number;
    min_score?: number;
    page?: number;
    page_size?: number;
  }) => ["match-results", params] as const,
  profiles: ["crawl-profiles"] as const,
};

const JOB_CRAWL_POLL_INTERVAL_MS = 3000;
const JOB_CRAWL_MAX_POLL_ATTEMPTS = 600;

export const useJobCrawlLogs = (params?: {
  search_config_id?: number;
  status?: string;
  hours?: number;
  limit?: number;
}) =>
  useQuery<JobCrawlLog[]>({
    queryKey: jobQueryKeys.crawlLogs(params),
    queryFn: () => jobsApi.getCrawlLogs(params).then((res) => res.data),
    refetchInterval: 60_000,
  });

export const useJobConfigs = (active?: boolean) =>
  useQuery({
    queryKey: jobQueryKeys.configs(active),
    queryFn: () => jobsApi.getConfigs(active).then((res) => res.data),
  });

export const useJobConfig = (id: number) =>
  useQuery({
    queryKey: jobQueryKeys.config(id),
    queryFn: () => jobsApi.getConfig(id).then((res) => res.data),
    enabled: !!id,
  });

export const useCreateJobConfig = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: jobsApi.createConfig,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["job-configs"] }),
  });
};

export const useUpdateJobConfig = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: JobSearchConfigUpdate }) =>
      jobsApi.updateConfig(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["job-configs"] }),
  });
};

export const useDeleteJobConfig = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: jobsApi.deleteConfig,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["job-configs"] }),
  });
};

export const useJobs = (params?: {
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
}) =>
  useQuery({
    queryKey: jobQueryKeys.jobs(params),
    queryFn: () => jobsApi.getJobs(params).then((res) => res.data),
    staleTime: 30_000,
  });

export const useJob = (jobId: string) =>
  useQuery({
    queryKey: jobQueryKeys.job(jobId),
    queryFn: () => jobsApi.getJob(jobId).then((res) => res.data),
    enabled: !!jobId,
  });

export const useCrawlAllJobs = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (): Promise<{
      type: "completed" | "error";
      total?: number;
      success?: number;
      errors?: number;
      reason?: string;
    }> => {
      const response = await jobsApi.crawlAll();
      const taskId = response.data.task_id;
      for (let attempt = 0; attempt < JOB_CRAWL_MAX_POLL_ATTEMPTS; attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, JOB_CRAWL_POLL_INTERVAL_MS));
        try {
          const statusRes = await jobsApi.getCrawlStatus(taskId);
          const s = statusRes.data;
          if (s.status === "completed") {
            const resultRes = await jobsApi.getCrawlResult(taskId);
            const r = resultRes.data;
            qc.invalidateQueries({ queryKey: ["jobs"] });
            qc.invalidateQueries({ queryKey: ["job-configs"] });
            return {
              type: "completed",
              total: r.total,
              success: r.success,
              errors: r.errors,
            };
          }
          if (s.status === "failed")
            return { type: "error", reason: "crawl task failed" };
        } catch (e) {
          console.warn("Job crawl polling error:", e);
        }
      }
      return { type: "error", reason: "timeout_polling" };
    },
  });
};

export const useCrawlSingleJob = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (
      configId: number,
    ): Promise<{
      type: "completed" | "error";
      total?: number;
      success?: number;
      errors?: number;
      reason?: string;
    }> => {
      const response = await jobsApi.crawlSingle(configId);
      const taskId = response.data.task_id;
      for (let attempt = 0; attempt < JOB_CRAWL_MAX_POLL_ATTEMPTS; attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, JOB_CRAWL_POLL_INTERVAL_MS));
        try {
          const statusRes = await jobsApi.getCrawlStatus(taskId);
          const s = statusRes.data;
          if (s.status === "completed") {
            const resultRes = await jobsApi.getCrawlResult(taskId);
            const r = resultRes.data;
            qc.invalidateQueries({ queryKey: ["jobs"] });
            qc.invalidateQueries({ queryKey: ["job-configs"] });
            return {
              type: "completed",
              total: r.total,
              success: r.success,
              errors: r.errors,
            };
          }
          if (s.status === "failed")
            return { type: "error", reason: "crawl task failed" };
        } catch (e) {
          console.warn("Job crawl polling error:", e);
        }
      }
      return { type: "error", reason: "timeout_polling" };
    },
  });
};

export const useResumes = () =>
  useQuery({
    queryKey: jobQueryKeys.resumes,
    queryFn: () => jobMatchApi.listResumes().then((res) => res.data),
  });

export const useCreateResume = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: UserResumeCreateRequest) =>
      jobMatchApi.createResume(data),
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.resumes }),
  });
};

export const useUpdateResume = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UserResumeUpdateRequest }) =>
      jobMatchApi.updateResume(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.resumes }),
  });
};

export const useDeleteResume = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => jobMatchApi.deleteResume(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.resumes }),
  });
};

export const useMatchResults = (params?: {
  resume_id?: number;
  job_id?: number;
  min_score?: number;
  page?: number;
  page_size?: number;
}) =>
  useQuery({
    queryKey: jobQueryKeys.matchResults(params),
    queryFn: () => jobMatchApi.listMatchResults(params).then((res) => res.data),
  });

export const useTriggerMatch = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: MatchAnalyzeRequest) =>
      jobMatchApi.triggerMatchAsync(data).then(
        (resp) =>
          resp.data as {
            status: string;
            task_id: string | null;
            total: number;
          },
      ),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["match-results"] });
      qc.invalidateQueries({ queryKey: ["jobs"] });
    },
  });
};

export const useCrawlProfiles = () =>
  useQuery({
    queryKey: jobQueryKeys.profiles,
    queryFn: () => jobsApi.getProfiles().then((res) => res.data),
  });

export const useProfileRuntimeCapabilities = () =>
  useQuery({
    queryKey: ["crawl-profile-runtime-capabilities"],
    queryFn: () => jobsApi.getProfileRuntimeCapabilities().then((res) => res.data),
  });

export const useCreateCrawlProfile = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: jobsApi.createProfile,
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.profiles }),
  });
};

export const useUpdateCrawlProfile = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ profileKey, data }: { profileKey: string; data: Parameters<typeof jobsApi.updateProfile>[1] }) =>
      jobsApi.updateProfile(profileKey, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.profiles }),
  });
};

export const useDeleteCrawlProfile = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: jobsApi.deleteProfile,
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.profiles }),
  });
};

export const useRenameCrawlProfile = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ profileKey, newProfileKey }: { profileKey: string; newProfileKey: string }) =>
      jobsApi.renameProfile(profileKey, newProfileKey),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: jobQueryKeys.profiles });
      qc.invalidateQueries({ queryKey: ["job-configs"] });
    },
  });
};

export const useCopyCrawlProfile = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: jobsApi.copyProfile,
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.profiles }),
  });
};

export const useReleaseStaleCrawlProfile = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: jobsApi.releaseStaleProfile,
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.profiles }),
  });
};

export const useOpenProfileLoginSession = () =>
  useMutation({
    mutationFn: ({ profileKey, platform }: { profileKey: string; platform: string }) =>
      jobsApi.openProfileLoginSession(profileKey, { platform }),
  });

export const useCloseProfileLoginSession = () =>
  useMutation({
    mutationFn: jobsApi.closeProfileLoginSession,
  });

export const useTestCrawlProfile = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ profileKey, platform }: { profileKey: string; platform: string }) =>
      jobsApi.testProfile(profileKey, { platform }),
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.profiles }),
  });
};

export const useExportProfileBackup = () =>
  useMutation({
    mutationFn: ({ profileKey, password }: { profileKey: string; password: string }) =>
      jobsApi.exportProfileBackup(profileKey, password),
  });

export const useImportProfileBackup = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      profileKey,
      file,
      password,
      force,
    }: {
      profileKey: string;
      file: File;
      password: string;
      force: boolean;
    }) => jobsApi.importProfileBackup(profileKey, file, password, force),
    onSuccess: () => qc.invalidateQueries({ queryKey: jobQueryKeys.profiles }),
  });
};
