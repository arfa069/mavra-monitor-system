import { Card, Statistic } from "antd";
import type { ReactNode } from "react";

interface KPICardProps {
  title: string;
  value: number;
  prefix?: ReactNode;
  suffix?: string;
  precision?: number;
  valueStyle?: React.CSSProperties;
}

export function KPICard({
  title,
  value,
  prefix,
  suffix,
  precision = 0,
  valueStyle,
}: KPICardProps) {
  return (
    <Card bordered={false} style={{ borderRadius: 16 }}>
      <Statistic
        title={title}
        value={value}
        prefix={prefix}
        suffix={suffix}
        precision={precision}
        valueStyle={valueStyle}
      />
    </Card>
  );
}
