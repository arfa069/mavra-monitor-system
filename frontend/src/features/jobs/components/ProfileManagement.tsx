import { useState } from "react";
import { App, Button, Checkbox, Dropdown, Form, Input, Modal, Popconfirm, Select, Space, Table, Tag, Upload } from "antd";
import type { UploadFile } from "antd";
import type { ColumnsType } from "antd/es/table";
import type { CrawlProfile, CrawlProfileRuntimeCapabilities } from "../types";

interface ProfileManagementProps {
  profiles?: CrawlProfile[];
  loading?: boolean;
  onCreate: (profileKey: string, platformHint?: string | null) => Promise<void>;
  onDelete: (profileKey: string) => Promise<void>;
  onUpdateStatus: (profileKey: string, status: "available" | "login_required" | "disabled") => Promise<void>;
  onReleaseStale: (profileKey: string) => Promise<void>;
  capabilities?: CrawlProfileRuntimeCapabilities;
  onOpenLoginSession: (profileKey: string, platform: string) => Promise<void>;
  onCloseLoginSession: (profileKey: string) => Promise<void>;
  onTestProfile: (profileKey: string, platform: string) => Promise<void>;
  onExportBackup: (profileKey: string, password: string) => Promise<void>;
  onImportBackup: (profileKey: string, file: File, password: string, force: boolean) => Promise<void>;
}

export default function ProfileManagement({
  profiles,
  loading,
  onCreate,
  onDelete,
  onUpdateStatus,
  onReleaseStale,
  capabilities,
  onOpenLoginSession,
  onCloseLoginSession,
  onTestProfile,
  onExportBackup,
  onImportBackup,
}: ProfileManagementProps) {
  const message = App.useApp().message;
  const [open, setOpen] = useState(false);
  const [backupOpen, setBackupOpen] = useState(false);
  const [backupMode, setBackupMode] = useState<"import" | "export">("import");
  const [backupProfile, setBackupProfile] = useState<CrawlProfile | null>(null);
  const [form] = Form.useForm<{ profile_key: string; platform_hint?: string }>();
  const [backupForm] = Form.useForm<{
    password: string;
    force?: boolean;
    file?: UploadFile[];
  }>();

  const platformFor = (record: CrawlProfile) => record.platform_hint || "boss";

  const columns: ColumnsType<CrawlProfile> = [
    { title: "Profile", dataIndex: "profile_key", width: 130 },
    {
      title: "Status",
      dataIndex: "status",
      width: 110,
      render: (value: CrawlProfile["status"]) => {
        const color = value === "available" ? "success" : value === "leased" ? "processing" : value === "disabled" ? "default" : "warning";
        return <Tag color={color}>{value}</Tag>;
      },
    },
    { title: "Platform", dataIndex: "platform_hint", width: 90, render: (value) => value || "-" },
    { title: "Task", dataIndex: "lease_task_id", width: 110, render: (value) => value || "-" },
    { title: "Lease Until", dataIndex: "lease_until", width: 140, render: (value) => value ? new Date(value).toLocaleString() : "-" },
    { title: "Last Error", dataIndex: "last_error", width: 100, render: (value) => value || "-" },
    {
      title: "Actions",
      width: 280,
      render: (_, record) => {
        const menuItems = [
          ...(capabilities?.supports_login_session
            ? [{
                key: "open-login-browser",
                label: "Open Login Browser",
                onClick: () => onOpenLoginSession(record.profile_key, platformFor(record)),
              }]
            : []),
          {
            key: "close-browser",
            label: "Close Browser",
            onClick: () => onCloseLoginSession(record.profile_key),
          },
          ...(capabilities?.supports_profile_import
            ? [{
                key: "import",
                label: "Import",
                onClick: () => {
                  setBackupMode("import");
                  setBackupProfile(record);
                  setBackupOpen(true);
                },
              }]
            : []),
          ...(capabilities?.supports_profile_export
            ? [{
                key: "export",
                label: "Export",
                onClick: () => {
                  setBackupMode("export");
                  setBackupProfile(record);
                  setBackupOpen(true);
                },
              }]
            : []),
          {
            key: "available",
            label: "Mark Available",
            onClick: () => onUpdateStatus(record.profile_key, "available"),
          },
          {
            key: "login-required",
            label: "Mark Login Required",
            onClick: () => onUpdateStatus(record.profile_key, "login_required"),
          },
          {
            key: "release-stale",
            label: "Release Stale",
            onClick: () => onReleaseStale(record.profile_key),
          },
        ];

        return (
          <Space size={6} style={{ flexWrap: "nowrap" }}>
            <Dropdown menu={{ items: menuItems }} trigger={["click"]}>
              <Button size="small">Edit</Button>
            </Dropdown>
            <Button size="small" onClick={() => onTestProfile(record.profile_key, platformFor(record))}>Test</Button>
            <Popconfirm
              title="Delete profile?"
              description="This removes the profile record and local files when it is not in use."
              okText="Delete"
              okButtonProps={{ danger: true }}
              onConfirm={() => onDelete(record.profile_key)}
            >
              <Button size="small" danger>Delete</Button>
            </Popconfirm>
            <Button size="small" danger onClick={() => onUpdateStatus(record.profile_key, "disabled")}>Disable</Button>
          </Space>
        );
      },
    },
  ];

  const handleCreate = async () => {
    const values = await form.validateFields();
    await onCreate(values.profile_key, values.platform_hint || null);
    form.resetFields();
    setOpen(false);
    message.success("Profile created");
  };

  const normFile = (event: { fileList?: UploadFile[] } | UploadFile[]) =>
    Array.isArray(event) ? event : event?.fileList;

  const handleBackup = async () => {
    if (!backupProfile) return;
    const values = await backupForm.validateFields();
    if (backupMode === "export") {
      await onExportBackup(backupProfile.profile_key, values.password);
      message.success("Profile backup exported");
    } else {
      const file = values.file?.[0]?.originFileObj;
      if (!file) {
        message.error("Select a profile backup file");
        return;
      }
      await onImportBackup(
        backupProfile.profile_key,
        file,
        values.password,
        Boolean(values.force),
      );
      message.success("Profile backup imported");
    }
    backupForm.resetFields();
    setBackupOpen(false);
    setBackupProfile(null);
  };

  return (
    <>
      <Space style={{ width: "100%", justifyContent: "space-between", marginBottom: 12 }}>
        <Tag>{capabilities?.mode || "loading"}</Tag>
        <Button onClick={() => setOpen(true)}>Create Profile</Button>
      </Space>
      <Table<CrawlProfile>
        rowKey="profile_key"
        columns={columns}
        dataSource={profiles || []}
        loading={loading}
        size="small"
      />
      <Modal title="Create Profile" open={open} onOk={handleCreate} onCancel={() => setOpen(false)}>
        <Form form={form} layout="vertical">
          <Form.Item name="profile_key" label="Profile Key" rules={[{ required: true }]}>
            <Input placeholder="job-a" autoComplete="off" />
          </Form.Item>
          <Form.Item name="platform_hint" label="Platform Hint">
            <Select allowClear options={[
              { value: "boss", label: "Boss" },
              { value: "51job", label: "51job" },
              { value: "liepin", label: "Liepin" },
              { value: "jd", label: "JD" },
              { value: "taobao", label: "Taobao" },
              { value: "amazon", label: "Amazon" },
            ]} />
          </Form.Item>
        </Form>
      </Modal>
      <Modal
        title={`${backupMode === "export" ? "Export" : "Import"} Profile Backup`}
        open={backupOpen}
        onOk={handleBackup}
        onCancel={() => {
          backupForm.resetFields();
          setBackupOpen(false);
          setBackupProfile(null);
        }}
      >
        <Form form={backupForm} layout="vertical">
          <Form.Item name="password" label="Backup Password" rules={[{ required: true, min: 8 }]}>
            <Input.Password autoComplete="new-password" />
          </Form.Item>
          {backupMode === "import" && (
            <>
              <Form.Item name="file" label="Backup File" valuePropName="fileList" getValueFromEvent={normFile} rules={[{ required: true }]}>
                <Upload beforeUpload={() => false} maxCount={1}>
                  <Button>Select Backup</Button>
                </Upload>
              </Form.Item>
              <Form.Item name="force" valuePropName="checked">
                <Checkbox>Overwrite existing profile files</Checkbox>
              </Form.Item>
            </>
          )}
        </Form>
      </Modal>
    </>
  );
}
