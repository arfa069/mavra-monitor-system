import { useEffect, useState } from "react";
import { Button, Form, Input, InputNumber, Modal, Select, Space, Switch } from "antd";
import type { JobSearchConfig, JobSearchConfigCreate } from "../types";

import type { CrawlProfile } from "../types";

interface JobConfigFormProps {
  open: boolean;
  record?: JobSearchConfig | null;
  profiles?: CrawlProfile[];
  onCreateProfile?: (profileKey: string, platformHint?: string | null) => Promise<void>;
  onCancel: () => void;
  onSubmit: (values: Partial<JobSearchConfigCreate>) => Promise<void>;
  confirmLoading?: boolean;
}

export default function JobConfigForm({
  open,
  record,
  profiles,
  onCreateProfile,
  onCancel,
  onSubmit,
  confirmLoading,
}: JobConfigFormProps) {
  const [form] = Form.useForm();
  const [profileForm] = Form.useForm<{ profile_key: string }>();
  const [profileModalOpen, setProfileModalOpen] = useState(false);

  useEffect(() => {
    if (!open) return;
    if (record) {
      form.setFieldsValue(record);
      return;
    }
    form.resetFields();
    form.setFieldsValue({
      platform: "boss",
      profile_key: "default",
      active: true,
      notify_on_new: true,
      enable_match_analysis: false,
      deactivation_threshold: 3,
    });
  }, [open, record, form]);

  const handleCancel = () => {
    form.resetFields();
    onCancel();
  };

  const handleUrlChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (record) return;
    const url = e.target.value;
    try {
      const parsed = new URL(url);
      // Boss uses 'query', 51job uses 'keyword', liepin uses 'key'
      const query =
        parsed.searchParams.get("query") ||
        parsed.searchParams.get("keyword") ||
        parsed.searchParams.get("key");
      if (query) form.setFieldsValue({ keyword: query });
    } catch {
      // ignore malformed URL while typing
    }
  };

  const platform = Form.useWatch("platform", form) || "boss";
  const urlConfigMap = {
    boss: {
      label: "Boss Search URL",
      placeholder: "https://www.zhipin.com/web/geek/job?query=frontend",
    },
    "51job": {
      label: "51job Search URL",
      placeholder: "https://we.51job.com/pc/search?keyword=python&searchType=2",
    },
    liepin: {
      label: "Liepin Search URL",
      placeholder:
        "https://www.liepin.com/zhaopin/?key=python&dqs=020&currentPage=0",
    },
  } as const;
  const urlConfig = urlConfigMap[platform as keyof typeof urlConfigMap] || {
    label: "Search URL",
    placeholder: "",
  };

  const handleOk = async () => {
    const values = await form.validateFields();
    await onSubmit(values);
    form.resetFields();
  };

  const handleCreateProfile = async () => {
    if (!onCreateProfile) return;
    const values = await profileForm.validateFields();
    await onCreateProfile(values.profile_key, platform);
    form.setFieldsValue({ profile_key: values.profile_key });
    profileForm.resetFields();
    setProfileModalOpen(false);
  };

  return (
    <Modal
      title={record ? "Edit Job Config" : "Add Job Config"}
      open={open}
      onCancel={handleCancel}
      onOk={handleOk}
      confirmLoading={confirmLoading}
    >
      <Form form={form} layout="vertical">
        <Form.Item
          name="name"
          label="Config Name"
          rules={[{ required: true, message: "Please enter config name" }]}
        >
          <Input placeholder="e.g. Shanghai Frontend Jobs" autoComplete="off" />
        </Form.Item>
        <Form.Item
          name="platform"
          label="Platform"
          rules={[{ required: true }]}
        >
          <Select disabled={!!record}>
            <Select.Option value="boss">Boss 直聘</Select.Option>
            <Select.Option value="51job">前程无忧 (51job)</Select.Option>
            <Select.Option value="liepin">猎聘 (Liepin)</Select.Option>
          </Select>
        </Form.Item>
        <Form.Item label="Profile">
          <Space.Compact style={{ width: "100%" }}>
            <Form.Item
              name="profile_key"
              noStyle
              rules={[{ required: true, message: "Please select profile" }]}
            >
              <Select
                showSearch
                optionFilterProp="label"
                style={{ width: "100%" }}
                options={(profiles || []).map((profile) => ({
                  value: profile.profile_key,
                  label: `${profile.profile_key} (${profile.status})`,
                  disabled: profile.status === "disabled",
                }))}
              />
            </Form.Item>
            <Button onClick={() => setProfileModalOpen(true)}>New</Button>
          </Space.Compact>
        </Form.Item>
        <Form.Item
          name="url"
          label={urlConfig.label}
          rules={[
            { required: true, message: "Please enter URL" },
            { type: "url", message: "Invalid URL format" },
          ]}
        >
          <Input
            placeholder={urlConfig.placeholder}
            autoComplete="off"
            onChange={handleUrlChange}
          />
        </Form.Item>
        <Form.Item name="keyword" label="Keyword">
          <Input placeholder="e.g. React" autoComplete="off" />
        </Form.Item>
        <Form.Item name="city_code" label="City Code">
          <Input placeholder="e.g. 101020100" autoComplete="off" />
        </Form.Item>
        <Form.Item name="salary_min" label="Min Salary (K)">
          <InputNumber min={0} style={{ width: "100%" }} />
        </Form.Item>
        <Form.Item name="salary_max" label="Max Salary (K)">
          <InputNumber min={0} style={{ width: "100%" }} />
        </Form.Item>
        <Form.Item name="experience" label="Experience">
          <Input placeholder="e.g. 3-5 years" autoComplete="off" />
        </Form.Item>
        <Form.Item name="education" label="Education">
          <Input placeholder="e.g. Bachelor" autoComplete="off" />
        </Form.Item>
        <Form.Item name="deactivation_threshold" label="Deactivation Threshold">
          <InputNumber min={1} style={{ width: "100%" }} />
        </Form.Item>
        <Form.Item name="active" label="Enable Config" valuePropName="checked">
          <Switch />
        </Form.Item>
        <Form.Item
          name="notify_on_new"
          label="New Job Notification"
          valuePropName="checked"
        >
          <Switch />
        </Form.Item>
        <Form.Item
          name="enable_match_analysis"
          label="Auto Match After Crawl"
          valuePropName="checked"
        >
          <Switch />
        </Form.Item>
      </Form>
      <Modal
        title="New Profile"
        open={profileModalOpen}
        onOk={handleCreateProfile}
        onCancel={() => setProfileModalOpen(false)}
      >
        <Form form={profileForm} layout="vertical">
          <Form.Item name="profile_key" label="Profile Key" rules={[{ required: true }]}>
            <Input placeholder={`${platform}-default-2`} autoComplete="off" />
          </Form.Item>
        </Form>
      </Modal>
    </Modal>
  );
}
