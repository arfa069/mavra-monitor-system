import {
  jobsListResumes,
  jobsCreateResume,
  jobsUpdateResume,
  jobsDeleteResume,
  jobsListMatchResults,
  jobsTriggerMatchAnalysisAsync,
  jobsGetMatchAnalysisTaskStatus,
} from "@/shared/api/generated/jobs/jobs";
import { encodePathSegment } from "@/shared/api/path";
import type {
  MatchAnalyzeRequest,
  UserResumeCreate,
  UserResumeUpdate,
  JobsListMatchResultsParams,
} from "@/shared/api/generated/models";

export const jobMatchApi = {
  listResumes: () => jobsListResumes(),
  createResume: (data: UserResumeCreate) => jobsCreateResume(data),
  updateResume: (id: number, data: UserResumeUpdate) =>
    jobsUpdateResume(id, data),
  deleteResume: (id: number) => jobsDeleteResume(id),
  listMatchResults: (params?: JobsListMatchResultsParams) =>
    jobsListMatchResults(params),
  triggerMatchAsync: (data: MatchAnalyzeRequest) =>
    jobsTriggerMatchAnalysisAsync(data),
  getMatchTaskStatus: (taskId: string) =>
    jobsGetMatchAnalysisTaskStatus(encodePathSegment(taskId)),
};
