import { Skeleton } from "antd";
import { DashboardPieChart } from "./PieChart";
import type { TrendResponse } from "../types";

interface PieChartSectionProps {
  data: TrendResponse | null;
  loading: boolean;
  refreshing?: boolean;
}

export function PieChartSection({ data, loading }: PieChartSectionProps) {
  if (data) {
    return <DashboardPieChart data={data} />;
  }
  if (loading) {
    return <Skeleton active paragraph={{ rows: 6 }} />;
  }
  return <div>暂无数据</div>;
}
