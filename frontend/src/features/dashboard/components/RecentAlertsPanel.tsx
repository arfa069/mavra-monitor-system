import { List, Tag, Badge, Empty, Skeleton } from "antd";
import { BellOutlined } from "@ant-design/icons";
import { useAuth } from "@/shared/contexts/AuthContext";
import type { RecentAlert } from "../types";

interface RecentAlertsPanelProps {
  alerts: RecentAlert[] | undefined;
  loading: boolean;
}

function formatTime(iso: string | null): string {
  if (!iso) return "-";
  const date = new Date(iso);
  return date.toLocaleString("zh-CN", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function RecentAlertsPanel({
  alerts = [],
  loading,
}: RecentAlertsPanelProps) {
  const { isAdmin } = useAuth();

  if (!isAdmin) {
    return null;
  }

  if (loading) {
    return (
      <div style={{ padding: 24 }}>
        <Skeleton active paragraph={{ rows: 4 }} />
      </div>
    );
  }

  if (!alerts || alerts.length === 0) {
    return (
      <div style={{ padding: 40 }}>
        <Empty description="暂无告警" image={Empty.PRESENTED_IMAGE_SIMPLE} />
      </div>
    );
  }

  return (
    <List
      dataSource={alerts}
      renderItem={(alert) => (
        <List.Item
          style={{
            padding: "12px 0",
            borderBottom: "1px solid var(--color-border)",
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "flex-start",
              gap: 12,
              width: "100%",
            }}
          >
            <div style={{ marginTop: 4 }}>
              {alert.active ? (
                <Badge dot color="#e5484d">
                  <BellOutlined style={{ fontSize: 16, color: "#666" }} />
                </Badge>
              ) : (
                <BellOutlined style={{ fontSize: 16, color: "#999" }} />
              )}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  marginBottom: 4,
                  flexWrap: "wrap",
                }}
              >
                <Tag
                  color={
                    alert.alert_type === "price_drop" ? "error" : "warning"
                  }
                  style={{ borderRadius: 50, fontSize: 12 }}
                >
                  {alert.alert_type === "price_drop"
                    ? "降价"
                    : alert.alert_type}
                </Tag>
                {alert.platform && (
                  <Tag style={{ borderRadius: 50, fontSize: 12 }}>
                    {alert.platform}
                  </Tag>
                )}
                <span
                  style={{
                    fontSize: 12,
                    color: "var(--color-muted)",
                    marginLeft: "auto",
                  }}
                >
                  {formatTime(alert.created_at)}
                </span>
              </div>
              <div
                style={{
                  fontSize: 14,
                  color: "var(--color-ink)",
                  lineHeight: 1.5,
                }}
              >
                {alert.product_title ? (
                  <span>
                    <strong>{alert.product_title}</strong>
                    <span
                      style={{ color: "var(--color-muted)", margin: "0 4px" }}
                    >
                      ·
                    </span>
                    {alert.message}
                  </span>
                ) : (
                  alert.message
                )}
              </div>
            </div>
          </div>
        </List.Item>
      )}
    />
  );
}
