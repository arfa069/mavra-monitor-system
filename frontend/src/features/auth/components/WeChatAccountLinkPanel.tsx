import { App, Button, Form, Input, Tabs, Typography } from "antd";
import { useNavigate } from "react-router-dom";

import { authApi } from "../api/auth";
import { strongPasswordMessage, strongPasswordRule } from "../passwordPolicy";
import { formatApiError } from "@/shared/api/client";
import { useAuth } from "@/shared/contexts/AuthContext";

interface Props {
  tempToken: string;
  nextPath: string;
}

interface BindValues {
  username: string;
  password: string;
}

interface RegisterValues extends BindValues {
  email: string;
}

export default function WeChatAccountLinkPanel({
  tempToken,
  nextPath,
}: Props) {
  const navigate = useNavigate();
  const { login } = useAuth();
  const { message } = App.useApp();

  const handleBound = async (user: Awaited<ReturnType<typeof authApi.bindWeChat>>["data"]) => {
    login(user);
    navigate(nextPath, { replace: true });
  };

  const handleBind = async (values: BindValues) => {
    try {
      const response = await authApi.bindWeChat({
        temp_token: tempToken,
        ...values,
      });
      await handleBound(response.data);
    } catch (error) {
      message.error(formatApiError(error, "绑定失败，请重新扫码"));
    }
  };

  const handleRegister = async (values: RegisterValues) => {
    try {
      const response = await authApi.registerWithWeChat({
        temp_token: tempToken,
        ...values,
      });
      await handleBound(response.data);
    } catch (error) {
      message.error(formatApiError(error, "注册失败，请重新扫码"));
    }
  };

  return (
    <>
      <Typography.Paragraph type="secondary">
        你可以绑定已有账号，也可以直接注册一个新账号完成本次登录。
      </Typography.Paragraph>
      <Tabs
        items={[
          {
            key: "bind",
            label: "绑定已有账号",
            children: (
              <Form layout="vertical" onFinish={handleBind}>
                <Form.Item
                  name="username"
                  label="Username"
                  rules={[{ required: true, message: "请输入用户名" }]}
                >
                  <Input autoComplete="username" />
                </Form.Item>
                <Form.Item
                  name="password"
                  label="Password"
                  rules={[{ required: true, message: "请输入密码" }]}
                >
                  <Input.Password autoComplete="current-password" />
                </Form.Item>
                <Button block htmlType="submit" type="primary">
                  绑定已有账号
                </Button>
              </Form>
            ),
          },
          {
            key: "register",
            label: "注册新账号",
            children: (
              <Form layout="vertical" onFinish={handleRegister}>
                <Form.Item
                  name="username"
                  label="Username"
                  rules={[{ required: true, message: "请输入用户名" }]}
                >
                  <Input autoComplete="username" />
                </Form.Item>
                <Form.Item
                  name="email"
                  label="Email"
                  rules={[
                    { required: true, message: "请输入邮箱" },
                    { type: "email", message: "请输入有效邮箱地址" },
                  ]}
                >
                  <Input autoComplete="email" />
                </Form.Item>
                <Form.Item
                  name="password"
                  label="Password"
                  rules={[
                    { required: true, message: "请输入密码" },
                    strongPasswordRule(),
                  ]}
                  extra={strongPasswordMessage}
                >
                  <Input.Password autoComplete="new-password" />
                </Form.Item>
                <Button block htmlType="submit" type="primary">
                  注册新账号
                </Button>
              </Form>
            ),
          },
        ]}
      />
    </>
  );
}
