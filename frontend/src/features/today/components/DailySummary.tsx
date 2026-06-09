import { Tag } from "antd";
import type { TodayBrief } from "../types";

interface DailySummaryProps {
  brief: TodayBrief;
}

export function DailySummary({ brief }: DailySummaryProps) {
  return (
    <section className="today-summary" aria-labelledby="today-summary-title">
      <div className="today-summary__meta">
        <span>今天</span>
        <Tag className="today-summary__quiet" bordered={false}>
          Quiet score {brief.quietScore}
        </Tag>
      </div>
      <h1 id="today-summary-title">{brief.headline}</h1>
      <p>{brief.subhead}</p>
    </section>
  );
}
