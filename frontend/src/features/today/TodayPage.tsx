import { Alert, Skeleton } from "antd";
import { m } from "framer-motion";
import { useTodayData } from "./hooks/useTodayData";
import {
  AttentionQueue,
  DailySummary,
  QuietStatusPanel,
  TodayRhythm,
} from "./components";

export default function TodayPage() {
  const { data, loading, error } = useTodayData();

  if (loading || !data) {
    return (
      <div className="today-page today-page--loading">
        <Skeleton active paragraph={{ rows: 4 }} title={{ width: "60%" }} />
        <p>正在整理今天的节奏...</p>
      </div>
    );
  }

  return (
    <m.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.22, ease: [0.2, 0.8, 0.2, 1] }}
    >
      {error ? (
        <Alert
          type="warning"
          showIcon
          message={error}
          style={{ marginBottom: 16 }}
        />
      ) : null}
      <TodayRhythm
        summary={<DailySummary brief={data} />}
        attention={<AttentionQueue items={data.attentionItems} />}
        status={<QuietStatusPanel brief={data} />}
      />
    </m.div>
  );
}
