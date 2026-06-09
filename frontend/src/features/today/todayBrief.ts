import type {
  TodayAttentionItem,
  TodayBrief,
  TodayModuleStatus,
  TodaySourceData,
} from "./types";

function productName(source: TodaySourceData): string {
  return source.products[0]?.title || "一个关注商品";
}

function jobName(source: TodaySourceData): string {
  return source.jobMatches[0]?.title || "一个职位";
}

function buildPriceStatus(source: TodaySourceData): TodayModuleStatus {
  if (source.kpi.price_drops_today > 0) {
    return {
      label: "价格看守",
      state: "attention",
      summary: `${source.kpi.price_drops_today} 个商品到了值得看的价位。`,
      href: "/products",
    };
  }
  return {
    label: "价格看守",
    state: source.kpi.total_products > 0 ? "quiet" : "inactive",
    summary:
      source.kpi.total_products > 0
        ? "价格还没有到你设的目标。"
        : "还没有添加关注商品。",
    href: "/products",
  };
}

function buildJobStatus(source: TodaySourceData): TodayModuleStatus {
  if (source.kpi.match_count > 0 || source.kpi.new_jobs_today > 0) {
    return {
      label: "职位雷达",
      state: "attention",
      summary: `${Math.max(
        source.kpi.match_count,
        source.kpi.new_jobs_today,
      )} 个职位值得看看。`,
      href: "/jobs",
    };
  }
  return {
    label: "职位雷达",
    state: "quiet",
    summary: "今天没有新的高匹配职位。",
    href: "/jobs",
  };
}

function buildHomeStatus(source: TodaySourceData): TodayModuleStatus {
  if (!source.home.configured) {
    return {
      label: "家里设备",
      state: "inactive",
      summary: "还没有连接 Home Assistant。",
      href: "/smart-home",
    };
  }
  if (!source.home.connected || source.home.unavailableCount > 0) {
    return {
      label: "家里设备",
      state: "attention",
      summary: `${source.home.unavailableCount} 个设备需要看一下。`,
      href: "/smart-home",
    };
  }
  return {
    label: "家里设备",
    state: "quiet",
    summary: "家里设备都在安静运行。",
    href: "/smart-home",
  };
}

function buildAttentionItems(source: TodaySourceData): TodayAttentionItem[] {
  const items: TodayAttentionItem[] = [];

  if (source.kpi.price_drops_today > 0) {
    items.push({
      id: "price-drop",
      kind: "price",
      timeLabel: "今天",
      title: `${productName(source)} 到了心理价位`,
      description: "价格低于你设定的提醒条件，适合今天决定要不要买。",
      metric: `-${source.kpi.price_drops_today}`,
      actionLabel: "查看",
      href: "/products",
    });
  }

  if (source.kpi.match_count > 0 || source.jobMatches.length > 0) {
    const topMatch = source.jobMatches[0];
    items.push({
      id: "job-match",
      kind: "job",
      timeLabel: "稍后",
      title: `${jobName(source)} 值得晚点打开`,
      description: topMatch?.company
        ? `${topMatch.company}${topMatch.location ? ` · ${topMatch.location}` : ""}`
        : "薪资、地点或匹配度接近你的设定。",
      metric: topMatch
        ? String(Math.round(topMatch.score))
        : String(source.kpi.match_count),
      actionLabel: "收藏",
      href: "/jobs",
    });
  }

  if (
    source.home.configured &&
    (!source.home.connected || source.home.unavailableCount > 0)
  ) {
    items.push({
      id: "home-attention",
      kind: "home",
      timeLabel: "早晨",
      title: "家里连接需要看一下",
      description: "Home Assistant 状态不是完全正常，建议确认连接和设备状态。",
      metric: String(source.home.unavailableCount),
      actionLabel: "看家里",
      href: "/smart-home",
    });
  }

  return items.slice(0, 5);
}

function quietScore(source: TodaySourceData): number {
  let score = 92;
  score -= Math.min(source.kpi.price_drops_today * 8, 24);
  score -= Math.min(source.kpi.match_count * 6, 18);
  score -= source.home.connected ? 0 : 18;
  score -= Math.min(source.home.unavailableCount * 5, 20);
  return Math.max(0, Math.min(100, score));
}

export function buildTodayBrief(source: TodaySourceData): TodayBrief {
  const attentionItems = buildAttentionItems(source);
  const count = attentionItems.length;

  return {
    headline:
      count === 0
        ? "今天很安静，Mavra 会继续帮你看着。"
        : `今天只提醒 ${count} 件事。`,
    subhead:
      count === 0
        ? "价格、职位和家里设备都没有需要你立刻处理的变化。"
        : "其他事情都在安静运行，你可以先看最值得注意的变化。",
    quietScore: quietScore(source),
    attentionItems,
    moduleStatuses: {
      prices: buildPriceStatus(source),
      jobs: buildJobStatus(source),
      home: buildHomeStatus(source),
    },
  };
}
