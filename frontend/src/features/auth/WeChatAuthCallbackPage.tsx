import { Alert, Button, Card, Flex, Spin, Typography } from "antd";
import { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";

import { authApi } from "./api/auth";
import WeChatAccountLinkPanel from "./components/WeChatAccountLinkPanel";
import { clearWeChatCallbackHash, parseWeChatCallback } from "./wechatCallback";
import { useAuth } from "@/shared/contexts/AuthContext";

const callbackErrorMessage = "微信登录失败，请重新扫码";

function CallbackShell({ children }: { children: React.ReactNode }) {
  return (
    <Flex
      align="center"
      justify="center"
      style={{ minHeight: "100vh", padding: 24 }}
    >
      <Card style={{ width: "100%", maxWidth: 520 }}>{children}</Card>
    </Flex>
  );
}

export default function WeChatAuthCallbackPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const { login } = useAuth();
  const callbackState = parseWeChatCallback(location.search, location.hash);
  const isSuccessCallback = callbackState.status === "success";
  const [restoringSession, setRestoringSession] = useState(isSuccessCallback);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (callbackState.tempToken) {
      clearWeChatCallbackHash(location.pathname, location.search);
    }

    if (!isSuccessCallback) {
      return;
    }

    let cancelled = false;

    authApi
      .getMe()
      .then((response) => {
        if (cancelled) {
          return;
        }
        login(response.data);
        navigate(callbackState.next, { replace: true });
      })
      .catch(() => {
        if (cancelled) {
          return;
        }
        setError("登录状态恢复失败，请重试");
      })
      .finally(() => {
        if (!cancelled) {
          setRestoringSession(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [
    isSuccessCallback,
    callbackState.next,
    callbackState.tempToken,
    location.pathname,
    location.search,
    login,
    navigate,
  ]);

  if (isSuccessCallback && restoringSession) {
    return (
      <CallbackShell>
        <Flex align="center" justify="center" style={{ minHeight: 240 }}>
          <Spin size="large" />
        </Flex>
      </CallbackShell>
    );
  }

  if (callbackState.status === "unbound" && callbackState.tempToken) {
    return (
      <CallbackShell>
        <Typography.Title level={3}>微信账号待绑定</Typography.Title>
        <Typography.Paragraph type="secondary">
          扫码成功，但当前微信账号还没有绑定到 Mavra 账号。
        </Typography.Paragraph>
        <WeChatAccountLinkPanel
          nextPath={callbackState.next}
          tempToken={callbackState.tempToken}
        />
      </CallbackShell>
    );
  }

  return (
    <CallbackShell>
      <Alert
        type="error"
        title={callbackErrorMessage}
        description={error || callbackState.reason || "请返回登录页后重新扫码。"}
        showIcon
      />
      <Button
        type="primary"
        onClick={() => navigate("/login", { replace: true })}
        style={{ marginTop: 16 }}
      >
        返回登录页
      </Button>
    </CallbackShell>
  );
}
