import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  crawlProfilesImportProfileBackup,
  crawlProfilesUpdateProfile,
} from "@/shared/api/generated/crawl-profiles/crawl-profiles";
import { jobsApi } from "@/features/jobs/api/jobs";

vi.mock("@/shared/api/generated/jobs/jobs", () => ({
  jobsListConfigs: vi.fn(),
  jobsGetConfig: vi.fn(),
  jobsCreateConfig: vi.fn(),
  jobsUpdateConfig: vi.fn(),
  jobsDeleteConfig: vi.fn(),
  jobsUpdateConfigCron: vi.fn(),
  jobsListResumes: vi.fn(),
  jobsCreateResume: vi.fn(),
  jobsUpdateResume: vi.fn(),
  jobsDeleteResume: vi.fn(),
  jobsListMatchResults: vi.fn(),
  jobsTriggerMatchAnalysis: vi.fn(),
  jobsGetJobConfigSchedules: vi.fn(),
  jobsListJobs: vi.fn(),
  jobsGetJob: vi.fn(),
  jobsCrawlNow: vi.fn(),
  jobsCrawlSingle: vi.fn(),
  jobsGetJobCrawlStatus: vi.fn(),
  jobsGetJobCrawlResult: vi.fn(),
  jobsGetJobCrawlLogs: vi.fn(),
}));

vi.mock("@/shared/api/generated/crawl-profiles/crawl-profiles", () => ({
  crawlProfilesListProfiles: vi.fn(),
  crawlProfilesGetRuntimeCapabilities: vi.fn(),
  crawlProfilesCreateProfile: vi.fn(),
  crawlProfilesUpdateProfile: vi.fn(),
  crawlProfilesRenameProfile: vi.fn(),
  crawlProfilesCopyProfile: vi.fn(),
  crawlProfilesDeleteProfile: vi.fn(),
  crawlProfilesReleaseStaleProfile: vi.fn(),
  crawlProfilesOpenLoginSession: vi.fn(),
  crawlProfilesCloseLoginSession: vi.fn(),
  crawlProfilesTestProfile: vi.fn(),
  crawlProfilesImportProfileBackup: vi.fn(),
}));

describe("jobsApi crawl profiles", () => {
  beforeEach(() => {
    vi.mocked(crawlProfilesUpdateProfile).mockReset();
    vi.mocked(crawlProfilesImportProfileBackup).mockReset();
  });

  it("encodes profile keys before generated path calls", async () => {
    vi.mocked(crawlProfilesUpdateProfile).mockResolvedValue({} as never);

    await jobsApi.updateProfile("profile name#1", { status: "available" });

    expect(crawlProfilesUpdateProfile).toHaveBeenCalledWith(
      "profile%20name%231",
      { status: "available" },
    );
  });

  it("uses the generated multipart profile import", async () => {
    vi.mocked(crawlProfilesImportProfileBackup).mockResolvedValue({
      profile_key: "profile name#1",
      imported: true,
    });
    const file = new File(["backup"], "profile.pmprofile");

    await jobsApi.importProfileBackup(
      "profile name#1",
      file,
      "secret",
      true,
    );

    expect(crawlProfilesImportProfileBackup).toHaveBeenCalledWith(
      "profile%20name%231",
      {
        file,
        password: "secret",
        force: true,
      },
    );
  });
});
