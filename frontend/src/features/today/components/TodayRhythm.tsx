import type { ReactNode } from "react";

interface TodayRhythmProps {
  summary: ReactNode;
  attention: ReactNode;
  status: ReactNode;
}

export function TodayRhythm({ summary, attention, status }: TodayRhythmProps) {
  return (
    <div className="today-page">
      <div className="today-page__main">
        {summary}
        {attention}
      </div>
      <div className="today-page__side">{status}</div>
    </div>
  );
}
