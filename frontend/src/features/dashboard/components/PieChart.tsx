import { useState } from "react";
import {
  PieChart,
  Pie,
  Cell,
  Sector,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import type { PieSectorShapeProps } from "recharts";
import type { TrendResponse } from "../types";

interface DashboardPieChartProps {
  data: TrendResponse;
  height?: number;
}

export function DashboardPieChart({
  data,
  height = 300,
}: DashboardPieChartProps) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  const renderPieSector = (props: PieSectorShapeProps) => {
    const outerRadius = Number(props.outerRadius ?? 80);

    return (
      <Sector
        {...props}
        outerRadius={props.index === activeIndex ? outerRadius + 8 : outerRadius}
      />
    );
  };

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
          shape={renderPieSector}
          fill="#8884d8"
          dataKey="value"
          label
          onMouseEnter={(_, index) => setActiveIndex(index)}
          onMouseLeave={() => setActiveIndex(null)}
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
