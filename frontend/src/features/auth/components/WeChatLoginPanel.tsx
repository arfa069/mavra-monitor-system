import { Alert, Button, Card, Flex, Spin, Typography } from "antd";
import { useEffect, useState } from "react";
import QRCode from "react-qr-code";

import { authApi } from "../api/auth";
import { formatApiError } from "@/shared/api/client";

interface Props {
  nextPath: string;
  onClose: () => void;
}

export default function WeChatLoginPanel({ nextPath, onClose }: Props) {
  const [loading, setLoading] = useState(true);
  const [qrUrl, setQrUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    authApi
      .getWeChatQr(nextPath)
      .then((response) => {
        if (!cancelled) {
          setQrUrl(response.qr_url);
        }
      })
      .catch((err) => {
        if (cancelled) {
          return;
        }
        const message = formatApiError(err, "当前环境未启用微信登录");
        setError(message.includes("未启用") ? "当前环境未启用微信登录" : message);
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [nextPath]);

  if (loading) {
    return (
      <Card>
        <Flex align="center" justify="center" style={{ minHeight: 180 }}>
          <Spin size="small" />
        </Flex>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <Alert type="warning" title={error} showIcon />
      </Card>
    );
  }

  if (!qrUrl) {
    return (
      <Card>
        <Alert type="error" title="二维码加载失败，请重试" showIcon />
      </Card>
    );
  }

  return (
    <Card>
      <Typography.Title level={4} style={{ marginTop: 0 }}>
        Scan with WeChat
      </Typography.Title>
      <Flex justify="center" style={{ marginBottom: 16 }}>
        <div title="WeChat login QR" style={{ background: "#fff", padding: 12 }}>
          <QRCode value={qrUrl} size={180} />
        </div>
      </Flex>
      <Typography.Paragraph type="secondary">
        使用微信扫一扫并确认网页登录，成功后会自动返回当前页面继续登录。
      </Typography.Paragraph>
      <Button block onClick={onClose}>
        返回账号登录
      </Button>
    </Card>
  );
}
