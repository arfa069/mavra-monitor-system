import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import type { TrendResponse } from "@/types/dashboard";

interface DashboardPieChartProps {
  data: TrendResponse;
  height?: number;
}

export function DashboardPieChart({
  data,
  height = 300,
}: DashboardPieChartProps) {
  const pieData = data.labels.map((label, index) => ({
    name: label,
    value: data.datasets[0]?.data[index]?.value ?? 0,
  }));

  const colors = [
    "#000000",
    "#3b82f6",
    "#1ea64a",
    "#f5a623",
    "#e5484d",
    "#8b5cf6",
  ];

  return (
    <ResponsiveContainer width="100%" height={height}>
      <PieChart>
        <Pie
          data={pieData}
          cx="50%"
          cy="50%"
          outerRadius={80}
          fill="#8884d8"
          dataKey="value"
          label
        >
          {pieData.map((_, index) => (
            <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
          ))}
        </Pie>
        <Tooltip />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
}
