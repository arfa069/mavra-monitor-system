import { Link } from "react-router-dom";
import type { TodayBrief, TodayModuleStatus } from "../types";

interface QuietStatusPanelProps {
  brief: TodayBrief;
}

const STATUS_ORDER: Array<keyof TodayBrief["moduleStatuses"]> = [
  "prices",
  "jobs",
  "home",
];

function statusText(status: TodayModuleStatus) {
  if (status.state === "attention") return "需要看看";
  if (status.state === "inactive") return "未启用";
  return "安静运行";
}

export function QuietStatusPanel({ brief }: QuietStatusPanelProps) {
  return (
    <aside className="today-card today-status" aria-label="今天的状态">
      <h2>今天的状态</h2>
      {STATUS_ORDER.map((key) => {
        const status = brief.moduleStatuses[key];
        return (
          <Link
            className={`today-status__row today-status__row--${status.state}`}
            key={key}
            to={status.href}
          >
            <span>
              <strong>{status.label}</strong>
              <small>{status.summary}</small>
            </span>
            <em>{statusText(status)}</em>
          </Link>
        );
      })}
    </aside>
  );
}
