import { Button, Select, Space, Tag, Tooltip, Typography } from "antd";
import { LockOutlined, PlusOutlined, ReloadOutlined } from "@ant-design/icons";
import type { CrawlProfile } from "@/features/jobs/types";

type Props = {
  value: string;
  profiles: CrawlProfile[];
  onChange: (profileKey: string) => void;
  onCreate: () => void;
  onReleaseStale: (profileKey: string) => void;
};

const STATUS_COLOR: Record<string, string> = {
  available: "green",
  leased: "blue",
  login_required: "orange",
  cooling_down: "gold",
  disabled: "red",
};

export function ProductProfileCell({
  value,
  profiles,
  onChange,
  onCreate,
  onReleaseStale,
}: Props) {
  const profile = profiles.find((item) => item.profile_key === value);
  const options = profiles.map((item) => ({
    label: item.profile_key,
    value: item.profile_key,
  }));

  return (
    <Space direction="vertical" size={4} style={{ width: "100%" }}>
      <Space.Compact style={{ width: "100%" }}>
        <Select
          value={value}
          options={options}
          onChange={onChange}
          showSearch
          style={{ minWidth: 220, flex: 1 }}
          popupMatchSelectWidth={false}
        />
        <Tooltip title="Create profile">
          <Button icon={<PlusOutlined />} onClick={onCreate} />
        </Tooltip>
        <Tooltip title="Release stale lease">
          <Button
            icon={<ReloadOutlined />}
            onClick={() => onReleaseStale(value)}
            disabled={!profile?.lease_until}
          />
        </Tooltip>
      </Space.Compact>
      <Space size={6} wrap>
        <Tag color={STATUS_COLOR[profile?.status ?? ""] ?? "default"}>
          {profile?.status ?? "missing"}
        </Tag>
        {profile?.lease_until ? <LockOutlined /> : null}
        {profile?.last_error ? (
          <Typography.Text type="danger" ellipsis style={{ maxWidth: 260 }}>
            {profile.last_error}
          </Typography.Text>
        ) : null}
      </Space>
    </Space>
  );
}
