import {
  jobsListResumes,
  jobsCreateResume,
  jobsUpdateResume,
  jobsDeleteResume,
  jobsListMatchResults,
  jobsTriggerMatchAnalysis,
  jobsTriggerMatchAnalysisAsync,
  jobsGetMatchAnalysisTaskStatus,
} from "@/shared/api/generated/jobs/jobs";
import type {
  MatchAnalyzeRequest,
  UserResumeCreate,
  UserResumeUpdate,
  JobsListMatchResultsParams,
} from "@/shared/api/generated/models";
import type {
  MatchAnalyzeResponse,
  MatchResultListResponse,
  UserResume,
} from "../types";

export const jobMatchApi = {
  listResumes: () => jobsListResumes() as unknown as Promise<UserResume[]>,
  createResume: (data: UserResumeCreate) => jobsCreateResume(data) as unknown as Promise<UserResume>,
  updateResume: (id: number, data: UserResumeUpdate) => jobsUpdateResume(id, data) as unknown as Promise<UserResume>,
  deleteResume: (id: number) => jobsDeleteResume(id) as unknown as Promise<void>,
  listMatchResults: (params?: JobsListMatchResultsParams) => jobsListMatchResults(params) as unknown as Promise<MatchResultListResponse>,
  triggerMatch: (data: MatchAnalyzeRequest) => jobsTriggerMatchAnalysis(data) as unknown as Promise<MatchAnalyzeResponse>,
  triggerMatchAsync: (data: MatchAnalyzeRequest) => jobsTriggerMatchAnalysisAsync(data) as unknown as Promise<{ status: string; task_id: string | null; total: number }>,
  getMatchTaskStatus: (taskId: string) => jobsGetMatchAnalysisTaskStatus(taskId) as unknown as Promise<{
    task_id: string;
    status: string;
    total: number;
    success: number;
    errors: number;
    reason?: string;
  }>,
};
