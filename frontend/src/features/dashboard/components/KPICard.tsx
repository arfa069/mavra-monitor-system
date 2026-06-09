import { Card, Statistic } from "antd";
import type { ReactNode } from "react";
import { m, useReducedMotion } from "framer-motion";

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
  const prefersReducedMotion = useReducedMotion();

  return (
    <m.div
      whileHover={prefersReducedMotion ? {} : { y: -4, scale: 1.015 }}
      transition={{ type: "spring", stiffness: 400, damping: 25 }}
      style={{ cursor: "pointer" }}
    >
      <Card
        variant="borderless"
        className="card-transition"
        style={{
          borderRadius: 16,
          boxShadow: "0 4px 16px rgba(0,0,0,0.04)",
        }}
      >
        <Statistic
          title={title}
          value={value}
          prefix={prefix}
          suffix={suffix}
          precision={precision}
          valueStyle={valueStyle}
        />
      </Card>
    </m.div>
  );
}
