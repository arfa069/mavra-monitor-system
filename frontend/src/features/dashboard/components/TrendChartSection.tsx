import { Skeleton } from "antd";
import { TrendChart } from "./TrendChart";
import type { TrendResponse } from "../types";

interface TrendChartSectionProps {
  data: TrendResponse | null;
  loading: boolean;
  refreshing: boolean;
  chartType?: "line" | "bar";
}

export function TrendChartSection({
  data,
  loading,
  refreshing,
  chartType = "line",
}: TrendChartSectionProps) {
  if (data) {
    return (
      <TrendChart data={data} chartType={chartType} isLoading={refreshing} />
    );
  }
  if (loading) {
    return <Skeleton active paragraph={{ rows: 6 }} />;
  }
  return <div>暂无数据</div>;
}
