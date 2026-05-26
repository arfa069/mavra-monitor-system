import { useState } from "react";
import { App, Button, Form, Input, Modal, Select, Space, Table, Tag } from "antd";
import type { ColumnsType } from "antd/es/table";
import type { CrawlProfile } from "../types";

interface ProfileManagementProps {
  profiles?: CrawlProfile[];
  loading?: boolean;
  onCreate: (profileKey: string, platformHint?: string | null) => Promise<void>;
  onUpdateStatus: (profileKey: string, status: "available" | "login_required" | "disabled") => Promise<void>;
  onReleaseStale: (profileKey: string) => Promise<void>;
}

export default function ProfileManagement({
  profiles,
  loading,
  onCreate,
  onUpdateStatus,
  onReleaseStale,
}: ProfileManagementProps) {
  const message = App.useApp().message;
  const [open, setOpen] = useState(false);
  const [form] = Form.useForm<{ profile_key: string; platform_hint?: string }>();

  const columns: ColumnsType<CrawlProfile> = [
    { title: "Profile", dataIndex: "profile_key", width: 140 },
    {
      title: "Status",
      dataIndex: "status",
      width: 130,
      render: (value: CrawlProfile["status"]) => {
        const color = value === "available" ? "success" : value === "leased" ? "processing" : value === "disabled" ? "default" : "warning";
        return <Tag color={color}>{value}</Tag>;
      },
    },
    { title: "Platform", dataIndex: "platform_hint", width: 120, render: (value) => value || "-" },
    { title: "Task", dataIndex: "lease_task_id", width: 180, render: (value) => value || "-" },
    { title: "Lease Until", dataIndex: "lease_until", width: 180, render: (value) => value ? new Date(value).toLocaleString() : "-" },
    { title: "Last Error", dataIndex: "last_error", render: (value) => value || "-" },
    {
      title: "Actions",
      width: 280,
      render: (_, record) => (
        <Space wrap>
          <Button size="small" onClick={() => onUpdateStatus(record.profile_key, "available")}>Available</Button>
          <Button size="small" onClick={() => onUpdateStatus(record.profile_key, "login_required")}>Login Required</Button>
          <Button size="small" danger onClick={() => onUpdateStatus(record.profile_key, "disabled")}>Disable</Button>
          <Button size="small" onClick={() => onReleaseStale(record.profile_key)}>Release Stale</Button>
        </Space>
      ),
    },
  ];

  const handleCreate = async () => {
    const values = await form.validateFields();
    await onCreate(values.profile_key, values.platform_hint || null);
    form.resetFields();
    setOpen(false);
    message.success("Profile created");
  };

  return (
    <>
      <Space style={{ width: "100%", justifyContent: "space-between", marginBottom: 12 }}>
        <span />
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
            ]} />
          </Form.Item>
        </Form>
      </Modal>
    </>
  );
}
