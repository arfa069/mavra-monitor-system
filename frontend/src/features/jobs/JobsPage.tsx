import { useMemo, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { m } from "framer-motion";
import { Card, message, Table, Tag, Tabs } from "antd";

import type { ColumnsType } from "antd/es/table";
import {
  useCrawlAllJobs,
  useCrawlSingleJob,
  useCopyCrawlProfile,
  useCreateCrawlProfile,
  useCreateJobConfig,
  useCrawlProfiles,
  useDeleteCrawlProfile,
  useDeleteJobConfig,
  useCloseProfileLoginSession,
  useExportProfileBackup,
  useImportProfileBackup,
  useJobConfigs,
  useJobCrawlLogs,
  useJobs,
  useMatchResults,
  useOpenProfileLoginSession,
  useProfileRuntimeCapabilities,
  useRenameCrawlProfile,
  useReleaseStaleCrawlProfile,
  useTestCrawlProfile,
  useUpdateCrawlProfile,
  useUpdateJobConfig,
} from "./hooks/useJobs";
import JobConfigList from "./components/JobConfigList";
import JobDrawer from "./components/JobDrawer";
import JobList from "./components/JobList";
import MatchResultList from "./components/MatchResultList";
import ProfileManagement from "./components/ProfileManagement";
import ResumeManager from "./components/ResumeManager";
import { useAuth } from "@/shared/contexts/AuthContext";
import { useStaggerAnimation } from "@/shared/hooks/useStaggerAnimation";
import { formatDateTime } from "@/shared/utils/date";
import type { Job, JobCrawlLog, JobSearchConfigCreate } from "./types";

export default function JobsPage() {
  const { hasPermission } = useAuth();
  const stagger = useStaggerAnimation(0.05, 0.05);
  const canCrawl = hasPermission("crawl:execute");
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [keyword, setKeyword] = useState("");
  const [isActive, setIsActive] = useState<boolean | undefined>(undefined);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [selectedJob, setSelectedJob] = useState<Job | null>(null);
  const [activeTab, setActiveTab] = useState("configs");

  const qc = useQueryClient();
  const CRAWLING_IDS_KEY = ["crawling", "config-ids"] as const;
  const { data: crawlingConfigIds = new Set<number>() } = useQuery({
    queryKey: CRAWLING_IDS_KEY,
    queryFn: () => new Set<number>(),
    initialData: new Set<number>(),
    staleTime: Infinity,
    gcTime: Infinity,
  });
  const updateCrawlingIds = (updater: (prev: Set<number>) => Set<number>) => {
    qc.setQueryData(CRAWLING_IDS_KEY, updater);
  };

  const {
    data: configs,
    isLoading: configsLoading,
    refetch: refetchConfigs,
  } = useJobConfigs();
  const createConfig = useCreateJobConfig();
  const updateConfig = useUpdateJobConfig();
  const deleteConfig = useDeleteJobConfig();

  const {
    data: jobsResp,
    isLoading: jobsLoading,
    refetch: refetchJobs,
  } = useJobs({
    keyword: keyword || undefined,
    is_active: isActive,
    page,
    page_size: pageSize,
  });
  const { data: allMatches } = useMatchResults({ page: 1, page_size: 100 });

  const crawlAll = useCrawlAllJobs();
  const crawlSingle = useCrawlSingleJob();
  const { data: jobCrawlLogs, isLoading: logsLoading } = useJobCrawlLogs({
    limit: 20,
  });

  const { data: profiles, isLoading: profilesLoading } = useCrawlProfiles();
  const { data: profileCapabilities } = useProfileRuntimeCapabilities();
  const createProfile = useCreateCrawlProfile();
  const updateProfile = useUpdateCrawlProfile();
  const deleteProfile = useDeleteCrawlProfile();
  const renameProfile = useRenameCrawlProfile();
  const copyProfile = useCopyCrawlProfile();
  const releaseStaleProfile = useReleaseStaleCrawlProfile();
  const openProfileLoginSession = useOpenProfileLoginSession();
  const closeProfileLoginSession = useCloseProfileLoginSession();
  const testProfile = useTestCrawlProfile();
  const exportProfileBackup = useExportProfileBackup();
  const importProfileBackup = useImportProfileBackup();

  const handleCreateProfile = async (
    profileKey: string,
    platformHint?: string | null,
  ) => {
    await createProfile.mutateAsync({
      profile_key: profileKey,
      platform_hint: platformHint,
    });
  };

  const handleReleaseStaleProfile = async (profileKey: string) => {
    await releaseStaleProfile.mutateAsync(profileKey);
  };

  const handleUpdateProfileStatus = async (
    profileKey: string,
    status: "available" | "login_required" | "disabled",
  ) => {
    await updateProfile.mutateAsync({ profileKey, data: { status } });
  };

  const handleDeleteProfile = async (profileKey: string) => {
    await deleteProfile.mutateAsync(profileKey);
  };

  const handleRenameProfile = async (
    profileKey: string,
    newProfileKey: string,
  ) => {
    await renameProfile.mutateAsync({ profileKey, newProfileKey });
  };

  const handleCopyProfile = async (profileKey: string) => {
    await copyProfile.mutateAsync(profileKey);
  };

  const handleOpenLoginSession = async (
    profileKey: string,
    platform: string,
  ) => {
    await openProfileLoginSession.mutateAsync({ profileKey, platform });
  };

  const handleCloseLoginSession = async (profileKey: string) => {
    await closeProfileLoginSession.mutateAsync(profileKey);
  };

  const handleTestProfile = async (profileKey: string, platform: string) => {
    await testProfile.mutateAsync({ profileKey, platform });
  };

  const handleExportBackup = async (profileKey: string, password: string) => {
    const response = await exportProfileBackup.mutateAsync({
      profileKey,
      password,
    });
    const url = URL.createObjectURL(response.data);
    const link = document.createElement("a");
    link.href = url;
    link.download = `${profileKey}.pmprofile`;
    link.click();
    URL.revokeObjectURL(url);
  };

  const handleImportBackup = async (
    profileKey: string,
    file: File,
    password: string,
    force: boolean,
  ) => {
    await importProfileBackup.mutateAsync({
      profileKey,
      file,
      password,
      force,
    });
  };

  const matchRecommendations = useMemo(() => {
    const recommendationRank: Record<string, number> = {
      强烈推荐: 3,
      可以考虑: 2,
      不太匹配: 1,
    };
    const map: Record<number, string> = {};
    allMatches?.items.forEach((item) => {
      const recommendation = item.apply_recommendation;
      if (!recommendation) return;
      const current = map[item.job_id];
      if (
        !current ||
        (recommendationRank[recommendation] ?? 0) >
          (recommendationRank[current] ?? 0)
      ) {
        map[item.job_id] = recommendation;
      }
    });
    return map;
  }, [allMatches]);

  const configNameMap = useMemo(() => {
    const map: Record<number, string> = {};
    configs?.forEach((c) => {
      map[c.id] = c.name;
    });
    return map;
  }, [configs]);

  const crawlLogColumns: ColumnsType<JobCrawlLog> = [
    {
      title: "Time",
      dataIndex: "scraped_at",
      width: 160,
      render: (value: string) => formatDateTime(value),
    },
    {
      title: "Config",
      dataIndex: "search_config_id",
      width: 120,
      render: (id: number) => configNameMap[id] || `#${id}`,
    },
    {
      title: "Status",
      dataIndex: "status",
      width: 100,
      render: (value: string) => {
        const config: Record<string, { color: string; text: string }> = {
          SUCCESS: { color: "success", text: "Success" },
          ERROR: { color: "error", text: "Failed" },
        };
        const c = config[value];
        return <Tag color={c?.color || "default"}>{c?.text || value}</Tag>;
      },
    },
    {
      title: "New Jobs",
      dataIndex: "new_jobs_count",
      width: 80,
      render: (value: number | null) => (value !== null ? value : "-"),
    },
    {
      title: "Total",
      dataIndex: "total_jobs_count",
      width: 80,
      render: (value: number | null) => (value !== null ? value : "-"),
    },
    {
      title: "Error",
      dataIndex: "error_message",
      render: (value: string | null) =>
        value ? (
          <span style={{ color: "#ff4d4f", cursor: "pointer" }} title={value}>
            {value.length > 40 ? `${value.slice(0, 40)}...` : value}
          </span>
        ) : null,
    },
  ];

  const handleCreateConfig = async (data: JobSearchConfigCreate) => {
    await createConfig.mutateAsync(data);
    await refetchConfigs();
  };

  const handleUpdateConfig = async (
    id: number,
    data: Partial<JobSearchConfigCreate>,
  ) => {
    await updateConfig.mutateAsync({ id, data });
    await refetchConfigs();
  };

  const handleDeleteConfig = async (id: number) => {
    await deleteConfig.mutateAsync(id);
    await refetchConfigs();
  };

  const handleCrawlSingle = async (id: number) => {
    const msgKey = `crawl-single-${id}`;
    message.loading({
      content: `Starting crawl for config #${id}...`,
      key: msgKey,
      duration: 0,
    });
    updateCrawlingIds((prev) => new Set(prev).add(id));
    try {
      const result = await crawlSingle.mutateAsync(id);
      if (result.type === "error") {
        message.error({
          content: `Crawl #${id} failed: ${result.reason || "Unknown error"}`,
          key: msgKey,
        });
      } else {
        message.success({
          content: `Crawl #${id} completed: ${result.success} succeeded, ${result.errors} failed`,
          key: msgKey,
        });
      }
      await refetchJobs();
      await refetchConfigs();
    } catch (error) {
      message.error({
        content: `Crawl #${id} request failed: ${error instanceof Error ? error.message : "Unknown error"}`,
        key: msgKey,
      });
    } finally {
      updateCrawlingIds((prev) => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      });
    }
  };

  const handleCrawlAll = async () => {
    message.loading({
      content: "Starting crawl for all configs...",
      key: "crawl-all",
      duration: 0,
    });
    try {
      const result = await crawlAll.mutateAsync();
      if (result.type === "error") {
        message.error({
          content: `Crawl all failed: ${result.reason || "Unknown error"}`,
          key: "crawl-all",
        });
      } else {
        message.success({
          content: `Crawl all completed: ${result.success} succeeded, ${result.errors} failed`,
          key: "crawl-all",
        });
      }
      await refetchJobs();
      await refetchConfigs();
    } catch (error) {
      message.error({
        content: `Crawl all request failed: ${error instanceof Error ? error.message : "Unknown error"}`,
        key: "crawl-all",
      });
    }
  };

  const handleViewDetail = (job: Job) => {
    setSelectedJob(job);
    setDrawerOpen(true);
  };

  const handleFilterChange = (filters: {
    keyword?: string;
    is_active?: boolean;
  }) => {
    setPage(1);
    if (filters.keyword !== undefined) setKeyword(filters.keyword);
    setIsActive(filters.is_active);
  };

  const items = [
    {
      key: "configs",
      label: "Search Config",
      children: (
        <>
          <Card size="small">
            <JobConfigList
              configs={configs}
              profiles={profiles}
              isLoading={configsLoading}
              onCreate={handleCreateConfig}
              onUpdate={handleUpdateConfig}
              onDelete={handleDeleteConfig}
              onCreateProfile={handleCreateProfile}
              onCrawl={canCrawl ? handleCrawlSingle : undefined}
              createLoading={createConfig.isPending}
              updateLoading={updateConfig.isPending}
              crawlingConfigIds={crawlingConfigIds}
              crawlAllPending={crawlAll.isPending}
            />
          </Card>

          <m.div
            variants={stagger.item}
            className="fg-card"
            style={{ marginTop: 16 }}
          >
            <div className="fg-card-header">
              <span className="fg-card-header-title">Jobs List</span>
            </div>
            <div style={{ padding: "20px 24px" }}>
              <JobList
                jobs={jobsResp?.items || []}
                total={jobsResp?.total || 0}
                isLoading={jobsLoading}
                onViewDetail={handleViewDetail}
                onCrawlAll={canCrawl ? handleCrawlAll : undefined}
                crawlAllLoading={crawlAll.isPending}
                crawlAllDisabled={crawlingConfigIds.size > 0}
                filters={{ keyword, is_active: isActive }}
                onFilterChange={handleFilterChange}
                page={page}
                pageSize={pageSize}
                onPageChange={setPage}
                onPageSizeChange={setPageSize}
                matchRecommendations={matchRecommendations}
              />
            </div>
          </m.div>
        </>
      ),
    },
    {
      key: "profiles",
      label: "Profiles Management",
      children: (
        <Card size="small" title="Crawler Profiles">
          <ProfileManagement
            profiles={profiles}
            loading={profilesLoading}
            onCreate={handleCreateProfile}
            onDelete={handleDeleteProfile}
            onRename={handleRenameProfile}
            onCopy={handleCopyProfile}
            onUpdateStatus={handleUpdateProfileStatus}
            onReleaseStale={handleReleaseStaleProfile}
            capabilities={profileCapabilities}
            onOpenLoginSession={handleOpenLoginSession}
            onCloseLoginSession={handleCloseLoginSession}
            onTestProfile={handleTestProfile}
            onExportBackup={handleExportBackup}
            onImportBackup={handleImportBackup}
          />
        </Card>
      ),
    },
    {
      key: "resume",
      label: "Resume Management",
      children: <ResumeManager />,
    },
    {
      key: "matches",
      label: "Analysis Results",
      children: <MatchResultList />,
    },
    {
      key: "logs",
      label: "Crawl Logs",
      children: (
        <Card size="small" title="Recent Job Crawl Logs">
          <Table<JobCrawlLog>
            columns={crawlLogColumns}
            dataSource={jobCrawlLogs}
            rowKey="id"
            loading={logsLoading}
            size="small"
            pagination={false}
          />
        </Card>
      ),
    },
  ];

  return (
    <div>
      {/* Page header — cream color block */}
      <div className="page-header bg-cream">
        <div className="page-header-inner">
          <div>
            <p className="page-eyebrow">Job Search</p>
            <h1 className="page-title">Job Management</h1>
            <p className="page-subtitle">
              Configure Boss Zhipin, 51job, and Liepin search rules,
              intelligently match candidates
            </p>
          </div>
        </div>
      </div>

      {/* Tab sections */}
      <m.div
        variants={stagger.container}
        initial="hidden"
        animate="show"
        style={{ marginTop: 24 }}
      >
        <m.div variants={stagger.item}>
          <Tabs activeKey={activeTab} onChange={setActiveTab} items={items} />
        </m.div>
      </m.div>

      <JobDrawer
        open={drawerOpen}
        job={selectedJob}
        onClose={() => setDrawerOpen(false)}
      />
    </div>
  );
}
