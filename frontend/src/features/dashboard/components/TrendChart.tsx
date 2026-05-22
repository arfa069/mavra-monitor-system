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
} from "recharts";
import type { TrendResponse } from "../types";

interface TrendChartProps {
  data: TrendResponse;
  chartType?: "line" | "bar";
  height?: number;
}

export function TrendChart({
  data,
  chartType = "line",
  height = 300,
}: TrendChartProps) {
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

  return (
    <ResponsiveContainer width="100%" height={height}>
      <ChartComponent data={chartData}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e6e6e6" />
        <XAxis dataKey="label" tick={{ fontSize: 12 }} />
        <YAxis tick={{ fontSize: 12 }} />
        <Tooltip />
        <Legend />
        {data.datasets.map((dataset, index) => (
          <DataComponent
            key={dataset.label}
            type="monotone"
            dataKey={dataset.label}
            stroke={colors[index % colors.length]}
            fill={colors[index % colors.length]}
            strokeWidth={2}
            dot={{ r: 3 }}
          />
        ))}
      </ChartComponent>
    </ResponsiveContainer>
  );
}
