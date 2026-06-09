import { useState } from "react";
import { Form, Input, InputNumber, Button, App, Segmented } from "antd";
import { useAuth } from "@/shared/contexts/AuthContext";
import { formatApiError } from "@/shared/api/client";
import { useThemeContext } from "@/shared/components/ThemeProvider";
import { configApi } from "./api/config";
import { applyUserConfig } from "./userConfigState";
import type { MotionSpeed } from "./types";
import { m } from "framer-motion";
import { useStaggerAnimation } from "@/shared/hooks/useStaggerAnimation";

export default function SettingsPage() {
  const { user, login } = useAuth();
  const stagger = useStaggerAnimation();
  const { motionSpeed, setMotionSpeed } = useThemeContext();
  const message = App.useApp().message;
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (values: {
    feishu_webhook_url?: string;
    data_retention_days?: number;
  }) => {
    setLoading(true);
    try {
      const response = await configApi.update(values);
      if (user) {
        login(applyUserConfig(user, response.data));
      }
      message.success("Settings saved");
    } catch (error: unknown) {
      message.error(formatApiError(error, "Save failed"));
    } finally {
      setLoading(false);
    }
  };

  return (
    <m.div variants={stagger.container} initial="hidden" animate="show">
      {/* Page header */}
      <m.div variants={stagger.item} className="page-header bg-mint">
        <div className="page-header-inner">
          <div>
            <p className="page-eyebrow">Preferences</p>
            <h1 className="page-title">Account Settings</h1>
            <p className="page-subtitle">
              Configure notification channels and data retention
            </p>
          </div>
        </div>
      </m.div>

      <m.div variants={stagger.item} style={{ maxWidth: 560, marginTop: 24 }}>
        <div className="fg-card">
          <div className="fg-card-header">
            <span className="fg-card-header-title">Personal Settings</span>
          </div>
          <div style={{ padding: "20px 24px" }}>
            <Form
              form={form}
              layout="vertical"
              initialValues={{
                feishu_webhook_url: user?.feishu_webhook_url || "",
                data_retention_days: user?.data_retention_days || 365,
              }}
              onFinish={handleSubmit}
            >
              <Form.Item
                name="feishu_webhook_url"
                label="飞书 Webhook URL"
                style={{ fontFamily: "var(--font-body)" }}
              >
                <Input
                  placeholder="https://open.feishu.cn/open-apis/bot/v2/hook/xxx"
                  style={{ fontFamily: "var(--font-body)", fontSize: 14 }}
                  autoComplete="off"
                />
              </Form.Item>
              <Form.Item
                name="data_retention_days"
                label="Data Retention (Days)"
                rules={[{ type: "number", min: 1, max: 3650 }]}
              >
                <InputNumber
                  min={1}
                  max={3650}
                  style={{ width: 200, fontFamily: "var(--font-body)" }}
                />
              </Form.Item>
              <Form.Item label="Page Transition Speed">
                <Segmented
                  value={motionSpeed}
                  onChange={(value) => setMotionSpeed(value as MotionSpeed)}
                  options={[
                    { label: "Fast", value: "fast" },
                    { label: "Normal", value: "normal" },
                    { label: "Slow", value: "slow" },
                  ]}
                />
              </Form.Item>
              <Form.Item style={{ marginBottom: 0 }}>
                <Button
                  type="primary"
                  htmlType="submit"
                  loading={loading}
                  className="fg-btn-primary"
                >
                  Save
                </Button>
              </Form.Item>
            </Form>
          </div>
        </div>
      </m.div>
    </m.div>
  );
}
