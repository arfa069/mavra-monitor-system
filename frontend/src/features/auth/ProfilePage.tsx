import { useState } from "react";
import { Form, Input, Button, App, Descriptions } from "antd";
import { formatApiError } from "@/shared/api/client";
import { useAuth } from "@/shared/contexts/AuthContext";
import { formatDateTime } from "@/shared/utils/date";
import { authApi } from "./api/auth";
import { strongPasswordMessage, strongPasswordRule } from "./passwordPolicy";
import { m } from "framer-motion";
import { useStaggerAnimation } from "@/shared/hooks/useStaggerAnimation";

export default function ProfilePage() {
  const { user, login } = useAuth();
  const stagger = useStaggerAnimation();
  const [form] = Form.useForm();
  const [passwordForm] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const message = App.useApp().message;

  const handleProfileUpdate = async (values: {
    username: string;
    email: string;
  }) => {
    setLoading(true);
    try {
      await authApi.updateProfile(values);
      const me = await authApi.getMe();
      login(me.data);
      message.success("Profile updated successfully");
    } catch (error: unknown) {
      message.error(formatApiError(error, "Update failed"));
    } finally {
      setLoading(false);
    }
  };

  const handlePasswordChange = async (values: {
    old_password: string;
    new_password: string;
  }) => {
    setLoading(true);
    try {
      await authApi.changePassword(values);
      message.success("Password changed successfully");
      passwordForm.resetFields();
    } catch (error: unknown) {
      message.error(formatApiError(error, "Change failed"));
    } finally {
      setLoading(false);
    }
  };

  if (!user) return null;

  return (
    <m.div variants={stagger.container} initial="hidden" animate="show">
      {/* Page header — cream color block */}
      <m.div variants={stagger.item} className="page-header bg-cream">
        <div className="page-header-inner">
          <div>
            <p className="page-eyebrow">Account</p>
            <h1 className="page-title">Personal Info</h1>
            <p className="page-subtitle">
              View and edit your account information
            </p>
          </div>
        </div>
      </m.div>

      <m.div variants={stagger.item} style={{ maxWidth: 560, marginTop: 24 }}>
        {/* Info card */}
        <div className="fg-card" style={{ marginBottom: 16 }}>
          <div className="fg-card-header">
            <span className="fg-card-header-title">Account Info</span>
          </div>
          <div style={{ padding: "20px 24px" }}>
            <Descriptions column={1}>
              <Descriptions.Item label="Username">
                {user.username}
              </Descriptions.Item>
              <Descriptions.Item label="Email">{user.email}</Descriptions.Item>
              <Descriptions.Item label="Role">
                {user.role === "user"
                  ? "Regular User"
                  : user.role === "admin"
                    ? "Admin"
                    : "System Admin"}
              </Descriptions.Item>
              <Descriptions.Item label="Registered">
                {formatDateTime(user.created_at)}
              </Descriptions.Item>
            </Descriptions>
          </div>
        </div>

        {/* Edit profile card */}
        <div className="fg-card" style={{ marginBottom: 16 }}>
          <div className="fg-card-header">
            <span className="fg-card-header-title">Edit Personal Info</span>
          </div>
          <div style={{ padding: "20px 24px" }}>
            <Form
              form={form}
              layout="vertical"
              initialValues={{ username: user.username, email: user.email }}
              onFinish={handleProfileUpdate}
            >
              <Form.Item
                name="username"
                label="Username"
                rules={[{ required: true, min: 3, max: 50 }]}
              >
                <Input
                  style={{ fontFamily: "var(--font-body)" }}
                  autoComplete="username"
                />
              </Form.Item>
              <Form.Item
                name="email"
                label="Email"
                rules={[{ required: true, type: "email" }]}
              >
                <Input
                  style={{ fontFamily: "var(--font-body)" }}
                  autoComplete="email"
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

        {/* Password card */}
        <div className="fg-card">
          <div className="fg-card-header">
            <span className="fg-card-header-title">Change Password</span>
          </div>
          <div style={{ padding: "20px 24px" }}>
            <Form
              form={passwordForm}
              layout="vertical"
              onFinish={handlePasswordChange}
            >
              <Form.Item
                name="old_password"
                label="Current Password"
                rules={[{ required: true }]}
              >
                <Input.Password
                  style={{ fontFamily: "var(--font-body)" }}
                  autoComplete="current-password"
                />
              </Form.Item>
              <Form.Item
                name="new_password"
                label="New Password"
                rules={[{ required: true }, strongPasswordRule()]}
                extra={strongPasswordMessage}
              >
                <Input.Password
                  style={{ fontFamily: "var(--font-body)" }}
                  autoComplete="new-password"
                />
              </Form.Item>
              <Form.Item style={{ marginBottom: 0 }}>
                <Button
                  type="primary"
                  htmlType="submit"
                  loading={loading}
                  className="fg-btn-primary"
                >
                  Change Password
                </Button>
              </Form.Item>
            </Form>
          </div>
        </div>
      </m.div>
    </m.div>
  );
}
