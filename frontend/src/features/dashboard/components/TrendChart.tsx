import { useState } from "react";
import { Spin } from "antd";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
  Brush,
} from "recharts";
import type { TrendResponse } from "../types";

interface TrendChartProps {
  data: TrendResponse;
  chartType?: "line" | "bar";
  height?: number;
  isLoading?: boolean;
}

export function TrendChart({
  data,
  chartType = "line",
  height = 300,
  isLoading = false,
}: TrendChartProps) {
  const [hiddenSeries, setHiddenSeries] = useState<Set<string>>(new Set());

  // Transform data for recharts
  const chartData = data.labels.map((label, index) => {
    const point: Record<string, string | number> = { label };
    data.datasets.forEach((dataset) => {
      point[dataset.label] = dataset.data[index]?.value ?? 0;
    });
    return point;
  });

  const colors = ["#000000", "#3b82f6", "#1ea64a", "#f5a623", "#e5484d"];

  const ChartComponent = chartType === "bar" ? BarChart : LineChart;
  const DataComponent = chartType === "bar" ? Bar : Line;
  const showBrush = data.labels.length >= 60;

  const toggleSeries = (series: string) => {
    setHiddenSeries((prev) => {
      const next = new Set(prev);
      if (next.has(series)) {
        next.delete(series);
      } else {
        next.add(series);
      }
      return next;
    });
  };

  return (
    <div style={{ position: "relative" }}>
      <div
        style={{
          opacity: isLoading ? 0.55 : 1,
          transition: "opacity 150ms ease-out",
        }}
      >
        <ResponsiveContainer width="100%" height={height}>
          <ChartComponent data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e6e6e6" />
            <XAxis dataKey="label" tick={{ fontSize: 12 }} />
            <YAxis tick={{ fontSize: 12 }} />
            <Tooltip />
            <Legend
              onClick={(entry) => {
                if (entry.value) {
                  toggleSeries(String(entry.value));
                }
              }}
            />
            {data.datasets.map((dataset, index) => (
              <DataComponent
                key={dataset.label}
                type="monotone"
                dataKey={dataset.label}
                hide={hiddenSeries.has(dataset.label)}
                stroke={colors[index % colors.length]}
                fill={colors[index % colors.length]}
                strokeWidth={2}
                dot={{ r: 3 }}
              />
            ))}
            {showBrush && (
              <Brush
                dataKey="label"
                height={24}
                travellerWidth={8}
                stroke="#666666"
              />
            )}
          </ChartComponent>
        </ResponsiveContainer>
      </div>
      {isLoading && (
        <div
          style={{
            position: "absolute",
            top: 8,
            right: 8,
            padding: "4px 10px",
            borderRadius: 50,
            background: "rgba(255,255,255,0.9)",
            border: "1px solid #e6e6e6",
            boxShadow: "0 4px 16px rgba(0,0,0,0.06)",
            fontSize: 12,
            color: "#666666",
          }}
        >
          <Spin size="small" /> 刷新中
        </div>
      )}
    </div>
  );
}
