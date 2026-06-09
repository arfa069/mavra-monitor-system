import { useCallback, useEffect, useState } from "react";
import {
  DeleteOutlined,
  SaveOutlined,
  ThunderboltOutlined,
} from "@ant-design/icons";
import {
  Alert,
  App,
  Button,
  Divider,
  Input,
  InputNumber,
  Modal,
  Select,
  Space,
  Table,
  Tag,
} from "antd";
import { m } from "framer-motion";
import { useStaggerAnimation } from "@/shared/hooks/useStaggerAnimation";
import type { ColumnsType } from "antd/es/table";
import { configApi } from "@/features/settings";
import { useAuth } from "@/shared/contexts/AuthContext";
import CronGenerator from "./components/CronGenerator";
import {
  useScheduleConfig,
  useUpdateScheduleConfig,
} from "./hooks/useScheduleConfig";
import { usePlatformSchedule } from "./hooks/usePlatformSchedule";
import { useJobConfigSchedule } from "./hooks/useJobConfigSchedule";
import { useCronGenerator } from "./hooks/useCronGenerator";
import { formatDateTime } from "@/shared/utils/date";
import type { JobSearchConfig, ProductPlatformCron } from "./types";

const CRON_SEGMENT_RE = /^(\*|[0-9]+(?:-[0-9]+)?(?:\/[0-9]+)?)$/;

const isValidCronFormat = (value: string): boolean => {
  const parts = value.trim().split(/\s+/);
  return (
    parts.length === 5 && parts.every((part) => CRON_SEGMENT_RE.test(part))
  );
};

const PLATFORM_LABELS: Record<string, string> = {
  taobao: "Taobao",
  jd: "JD",
  amazon: "Amazon",
};

export default function ScheduleConfigPage() {
  const { hasPermission } = useAuth();
  const stagger = useStaggerAnimation();
  const isReadOnly = !hasPermission("schedule:configure");
  const message = App.useApp().message;
  const {
    data: scheduleConfig,
    isLoading,
    isError,
    refetch,
  } = useScheduleConfig();
  const updateMutation = useUpdateScheduleConfig();

  const [retentionDays, setRetentionDays] = useState(365);
  const [feishuWebhookUrl, setFeishuWebhookUrl] = useState("");

  const platform = usePlatformSchedule(message);
  const jobConfig = useJobConfigSchedule(message);
  const generator = useCronGenerator();

  const [addModalOpen, setAddModalOpen] = useState(false);
  const [addPlatform, setAddPlatform] = useState<string | undefined>(undefined);
  const [addCron, setAddCron] = useState("");
  const [addSaving, setAddSaving] = useState(false);

  const fetchSchedulerStatus = useCallback(async () => {
    try {
      await configApi.getSchedulerStatus();
    } catch {
      // page uses per-table schedule endpoints directly; ignore status failures
    }
  }, []);

  useEffect(() => {
    if (scheduleConfig) {
      const timer = window.setTimeout(() => {
        setRetentionDays(scheduleConfig.data_retention_days || 365);
        setFeishuWebhookUrl(scheduleConfig.feishu_webhook_url || "");
      }, 0);
      return () => window.clearTimeout(timer);
    }
  }, [scheduleConfig]);

  // Extract stable load function references. The hook return objects are
  // new references each render, but the load functions themselves are stable
  // (useCallback with stable message ref).
  const loadPlatforms = platform.load;
  const loadJobConfigs = jobConfig.load;

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void fetchSchedulerStatus();
      void loadPlatforms();
      void loadJobConfigs();
    }, 0);
    return () => window.clearTimeout(timer);
  }, [fetchSchedulerStatus, loadPlatforms, loadJobConfigs]);

  const handleSaveRetention = async () => {
    try {
      await updateMutation.mutateAsync({ data_retention_days: retentionDays });
      message.success("Retention days saved");
      refetch();
    } catch {
      message.error("Save failed");
    }
  };

  const handleSaveWebhook = async () => {
    try {
      await updateMutation.mutateAsync({
        feishu_webhook_url: feishuWebhookUrl,
      });
      message.success("Webhook URL saved");
      refetch();
    } catch {
      message.error("Save failed");
    }
  };

  const handleAddPlatformCron = async () => {
    if (!addPlatform) {
      message.error("Please select a platform");
      return;
    }
    const value = addCron.trim() || null;
    if (value && !isValidCronFormat(value)) {
      message.error("Invalid cron expression");
      return;
    }
    setAddSaving(true);
    try {
      await platform.create(addPlatform, value);
      setAddModalOpen(false);
      setAddPlatform(undefined);
      setAddCron("");
    } catch {
      message.error("Add failed");
    } finally {
      setAddSaving(false);
    }
  };

  const handleDeletePlatformCron = async (p: string) => {
    Modal.confirm({
      title: "Delete Schedule Config",
      content: `Delete schedule config for ${PLATFORM_LABELS[p] || p}?`,
      onOk: async () => {
        await platform.remove(p);
      },
    });
  };

  const handleApplyCron = useCallback(
    (cronExpression: string) => {
      if (!generator.target) return;
      switch (generator.target.type) {
        case "platform":
          platform.updateInput(generator.target.platform, cronExpression);
          break;
        case "config":
          jobConfig.updateInput(generator.target.configId, cronExpression);
          break;
        case "add":
          setAddCron(cronExpression);
          break;
      }
      generator.closeGenerator();
    },
    [generator, platform, jobConfig],
  );

  const platformColumns: ColumnsType<ProductPlatformCron> = [
    {
      title: "Platform",
      dataIndex: "platform",
      key: "platform",
      width: 200,
      render: (value: string) => PLATFORM_LABELS[value] || value,
    },
    {
      title: "Cron Expression",
      key: "cron",
      width: 450,
      render: (_: unknown, record: ProductPlatformCron) => (
        <Space>
          <Input
            value={platform.cronInputs[record.platform] ?? ""}
            onChange={(e) =>
              platform.updateInput(record.platform, e.target.value)
            }
            placeholder="0 9 * * *"
            style={{ width: 190 }}
            disabled={isReadOnly}
          />
          <Button
            icon={<ThunderboltOutlined />}
            size="small"
            onClick={() =>
              generator.openGenerator({
                type: "platform",
                platform: record.platform,
              })
            }
            disabled={isReadOnly}
            className="fg-btn-secondary fg-btn-sm"
          />
          <Button
            onClick={() =>
              void platform.save(
                record.platform,
                platform.cronInputs[record.platform]?.trim() || null,
              )
            }
            loading={platform.saving[record.platform]}
            disabled={isReadOnly}
            className="fg-btn-secondary"
          >
            Save
          </Button>
        </Space>
      ),
    },
    {
      title: "Next Run",
      key: "next_run",
      render: (_, record) => {
        const schedule = platform.schedules[record.platform];
        const nextRun = schedule?.next_run_at
          ? formatDateTime(schedule.next_run_at)
          : null;
        return nextRun ? nextRun : <Tag>Unscheduled</Tag>;
      },
    },
    ...(isReadOnly
      ? []
      : [
          {
            title: "Actions",
            key: "action",
            width: 90,
            render: (_: unknown, record: ProductPlatformCron) => (
              <Button
                danger
                size="small"
                icon={<DeleteOutlined />}
                onClick={() => void handleDeletePlatformCron(record.platform)}
              >
                Delete
              </Button>
            ),
          },
        ]),
  ] as ColumnsType<ProductPlatformCron>;

  const configColumns: ColumnsType<JobSearchConfig> = [
    {
      title: "Config Name",
      dataIndex: "name",
      key: "name",
      width: 200,
      ellipsis: true,
    },
    {
      title: "Cron Expression",
      key: "cron",
      width: 450,
      render: (_, record) => (
        <Space>
          <Input
            value={jobConfig.cronInputs[record.id] ?? ""}
            onChange={(e) => jobConfig.updateInput(record.id, e.target.value)}
            placeholder="0 9 * * *"
            style={{ width: 190 }}
            disabled={isReadOnly}
          />
          <Button
            icon={<ThunderboltOutlined />}
            size="small"
            onClick={() =>
              generator.openGenerator({ type: "config", configId: record.id })
            }
            disabled={isReadOnly}
            className="fg-btn-secondary fg-btn-sm"
          />
          <Button
            onClick={() =>
              void jobConfig.save(
                record.id,
                jobConfig.cronInputs[record.id]?.trim() || null,
              )
            }
            loading={jobConfig.saving[record.id]}
            disabled={isReadOnly}
            className="fg-btn-secondary"
          >
            Save
          </Button>
        </Space>
      ),
    },
    {
      title: "Next Run",
      key: "next_run",
      render: (_, record) => {
        const schedule = jobConfig.schedules[record.id];
        const nextRun = schedule?.next_run_at
          ? formatDateTime(schedule.next_run_at)
          : null;
        return nextRun ? nextRun : <Tag>Unscheduled</Tag>;
      },
    },
  ];

  return (
    <m.div variants={stagger.container} initial="hidden" animate="show">
      {/* Page header — mint color block (DESIGN.md: Mint — Config) */}
      <m.div variants={stagger.item} className="page-header bg-mint">
        <div className="page-header-inner">
          <div>
            <p className="page-eyebrow">Automation</p>
            <h1 className="page-title">Schedule Config</h1>
            <p className="page-subtitle">
              Configure product and job crawl schedules and notification
              channels
            </p>
          </div>
        </div>
      </m.div>

      {isReadOnly && (
        <m.div variants={stagger.item}>
          <Alert
            type="warning"
            message="Read-only Mode"
            description="Admin accounts cannot modify schedule configs. Please contact the system administrator."
            style={{ marginBottom: 24 }}
            showIcon
          />
        </m.div>
      )}

      {isError && !isLoading && (
        <m.div variants={stagger.item}>
          <Alert
            type="error"
            message="Load Failed"
            description="Unable to fetch configuration. Please try again later."
            action={
              <Button
                size="small"
                onClick={() => void refetch()}
                className="fg-btn-secondary fg-btn-sm"
              >
                Retry
              </Button>
            }
            style={{ marginBottom: 24 }}
          />
        </m.div>
      )}

      {/* Cron config card */}
      <m.div
        variants={stagger.item}
        className="fg-card"
        style={{ marginTop: 24 }}
      >
        <div className="fg-card-header">
          <span className="fg-card-header-title">
            Cron Schedule Configuration
          </span>
        </div>
        <div style={{ padding: "20px 24px" }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 8,
              margin: "0 0 12px",
            }}
          >
            <h4
              style={{
                fontFamily: "var(--font-body)",
                fontSize: 14,
                fontWeight: 480,
                color: "var(--color-ink)",
                margin: 0,
              }}
            >
              Product Crawl Schedule Config
            </h4>
            {!isReadOnly && (
              <Button
                size="small"
                onClick={() => setAddModalOpen(true)}
                className="fg-btn-secondary fg-btn-sm"
              >
                Add Product Timer
              </Button>
            )}
          </div>
          <Table
            dataSource={platform.configs}
            columns={platformColumns}
            rowKey="platform"
            loading={platform.loading}
            pagination={false}
            size="small"
            scroll={{ x: 1000 }}
            locale={{ emptyText: "No product schedule configs" }}
          />

          <Divider style={{ margin: "16px 0" }} />

          <h4
            style={{
              fontFamily: "var(--font-body)",
              fontSize: 14,
              fontWeight: 480,
              color: "var(--color-ink)",
              margin: "0 0 12px",
            }}
          >
            Job Crawl Schedule Config
          </h4>
          <Table
            dataSource={jobConfig.list}
            columns={configColumns}
            rowKey="id"
            loading={jobConfig.loading}
            pagination={false}
            size="small"
            scroll={{ x: 1000 }}
            locale={{ emptyText: "No job search configs" }}
          />
        </div>
      </m.div>

      {/* Data & notification card */}
      <m.div
        variants={stagger.item}
        className="fg-card"
        style={{ marginTop: 16 }}
      >
        <div className="fg-card-header">
          <span className="fg-card-header-title">
            Data Retention & Notification Config
          </span>
        </div>
        <div style={{ padding: "20px 24px" }}>
          <div style={{ marginBottom: 20 }}>
            <div
              style={{
                marginBottom: 6,
                fontFamily: "var(--font-body)",
                fontSize: 14,
                fontWeight: 330,
                color: "var(--color-muted)",
              }}
            >
              Feishu Webhook URL
            </div>
            <Space>
              <Input
                value={feishuWebhookUrl}
                onChange={(e) => setFeishuWebhookUrl(e.target.value)}
                placeholder="https://open.feishu.cn/open-apis/bot/v2/hook/..."
                autoComplete="off"
                style={{
                  width: 420,
                  fontFamily: "var(--font-body)",
                  fontSize: 14,
                }}
              />
              <Button
                onClick={() => void handleSaveWebhook()}
                loading={updateMutation.isPending}
                disabled={isReadOnly}
                className="fg-btn-secondary"
              >
                Save
              </Button>
            </Space>
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <span
              style={{
                fontFamily: "var(--font-body)",
                fontSize: 14,
                fontWeight: 330,
                color: "var(--color-muted)",
                whiteSpace: "nowrap",
              }}
            >
              Data Retention Days
            </span>
            <Space>
              <InputNumber
                min={1}
                max={3650}
                value={retentionDays}
                onChange={(v) => setRetentionDays(v ?? 365)}
                style={{ width: 160, fontFamily: "var(--font-body)" }}
                disabled={isReadOnly}
              />
              <Button
                icon={<SaveOutlined style={{ fontSize: 13 }} />}
                onClick={() => void handleSaveRetention()}
                loading={updateMutation.isPending}
                disabled={isReadOnly}
                className="fg-btn-secondary"
              >
                Save
              </Button>
            </Space>
          </div>
        </div>
      </m.div>

      <Modal
        title="Add Product Crawl Timer"
        open={addModalOpen}
        onOk={() => void handleAddPlatformCron()}
        onCancel={() => {
          setAddModalOpen(false);
          setAddPlatform(undefined);
          setAddCron("");
        }}
        confirmLoading={addSaving}
        okText="Add"
      >
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 12,
            marginTop: 16,
          }}
        >
          <div>
            <div
              style={{
                marginBottom: 4,
                fontFamily: "var(--font-body)",
                fontSize: 14,
                fontWeight: 330,
                color: "var(--color-muted)",
              }}
            >
              Platform
            </div>
            <Select
              value={addPlatform}
              onChange={setAddPlatform}
              placeholder="Select platform"
              style={{ width: "100%", fontFamily: "var(--font-body)" }}
              options={[
                { value: "taobao", label: "Taobao" },
                { value: "jd", label: "JD" },
                { value: "amazon", label: "Amazon" },
              ]}
            />
          </div>
          <div>
            <div
              style={{
                marginBottom: 4,
                fontFamily: "var(--font-body)",
                fontSize: 14,
                fontWeight: 330,
                color: "var(--color-muted)",
              }}
            >
              Cron Expression
            </div>
            <Space style={{ width: "100%" }}>
              <Input
                value={addCron}
                onChange={(e) => setAddCron(e.target.value)}
                placeholder="0 9 * * *"
                style={{
                  flex: 1,
                  fontFamily: "'JetBrains Mono', monospace",
                  fontSize: 14,
                }}
              />
              <Button
                icon={<ThunderboltOutlined />}
                size="small"
                onClick={() => generator.openGenerator({ type: "add" })}
                disabled={isReadOnly}
                className="fg-btn-secondary fg-btn-sm"
              />
            </Space>
          </div>
        </div>
      </Modal>

      <CronGenerator
        open={generator.open}
        onClose={() => generator.closeGenerator()}
        onApply={handleApplyCron}
      />
    </m.div>
  );
}
