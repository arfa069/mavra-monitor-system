import { describe, expect, it } from "vitest";
import { buildTodayBrief } from "@/features/today/todayBrief";
import type { TodaySourceData } from "@/features/today/types";

const baseSource: TodaySourceData = {
  now: new Date("2026-06-10T08:20:00+08:00"),
  kpi: {
    total_products: 3,
    price_drops_today: 0,
    new_jobs_today: 0,
    match_count: 0,
    crawl_count_today: 4,
  },
  products: [],
  jobMatches: [],
  home: {
    configured: true,
    connected: true,
    unavailableCount: 0,
    activeCount: 4,
  },
};

describe("buildTodayBrief", () => {
  it("returns a quiet summary when nothing needs attention", () => {
    const brief = buildTodayBrief(baseSource);

    expect(brief.headline).toBe("今天很安静，Mavra 会继续帮你看着。");
    expect(brief.attentionItems).toHaveLength(0);
    expect(brief.moduleStatuses.home.label).toBe("家里设备");
    expect(brief.moduleStatuses.home.state).toBe("quiet");
  });

  it("prioritizes price drops and job matches before quiet home state", () => {
    const brief = buildTodayBrief({
      ...baseSource,
      kpi: {
        ...baseSource.kpi,
        price_drops_today: 1,
        new_jobs_today: 2,
        match_count: 1,
      },
      products: [
        {
          id: 12,
          title: "Dell 显示器",
          platform: "jd",
        },
      ],
      jobMatches: [
        {
          id: 9,
          score: 92,
          title: "Frontend Engineer",
          company: "Example Co",
          location: "Shanghai",
        },
      ],
    });

    expect(brief.headline).toBe("今天只提醒 2 件事。");
    expect(brief.attentionItems.map((item) => item.kind)).toEqual([
      "price",
      "job",
    ]);
    expect(brief.attentionItems[0].title).toContain("Dell 显示器");
    expect(brief.attentionItems[1].metric).toBe("92");
  });

  it("shows a home attention item when Home Assistant is disconnected", () => {
    const brief = buildTodayBrief({
      ...baseSource,
      home: {
        configured: true,
        connected: false,
        unavailableCount: 3,
        activeCount: 0,
      },
    });

    expect(brief.attentionItems[0]).toMatchObject({
      kind: "home",
      title: "家里连接需要看一下",
      metric: "3",
    });
    expect(brief.moduleStatuses.home.state).toBe("attention");
  });
});
