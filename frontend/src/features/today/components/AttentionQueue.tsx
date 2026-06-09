import { Button, Empty } from "antd";
import { Link } from "react-router-dom";
import type { TodayAttentionItem } from "../types";

interface AttentionQueueProps {
  items: TodayAttentionItem[];
}

export function AttentionQueue({ items }: AttentionQueueProps) {
  if (items.length === 0) {
    return (
      <div className="today-card today-empty">
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description="没有需要你立刻处理的事。"
        />
      </div>
    );
  }

  return (
    <section
      className="today-attention-section"
      aria-labelledby="today-attention-title"
    >
      <h2 id="today-attention-title">值得看</h2>
      <div className="today-attention-list">
        {items.map((item) => (
          <article
            className={`today-attention today-attention--${item.kind}`}
            key={item.id}
          >
            <div className="today-attention__time">{item.timeLabel}</div>
            <div>
              <h3>{item.title}</h3>
              <p>{item.description}</p>
            </div>
            <div className="today-attention__action">
              <strong>{item.metric}</strong>
              <Button type="primary" size="small">
                <Link to={item.href}>{item.actionLabel}</Link>
              </Button>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
