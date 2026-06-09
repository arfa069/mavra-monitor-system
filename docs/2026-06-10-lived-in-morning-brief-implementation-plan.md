# Lived-In Morning Brief Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the dashboard-first neo-brutalist UI with a warm `/today` first screen and supporting design-system foundation for the Lived-In Morning Brief direction.

**Architecture:** Implement the new direction as an incremental frontend migration. Add new design tokens and Today feature surfaces first, keep the existing `/dashboard` page as a data-heavy Analytics page, then migrate shared shell/navigation and Ant Design overrides without touching crawler or smart-home control behavior.

**Tech Stack:** React 18, Vite, TypeScript, Ant Design 6, Framer Motion, Vitest, React Testing Library, Playwright mock-only E2E, CSS custom properties.

---

## Non-Negotiable Safety Boundary

- Do not run real crawl tests.
- Do not trigger smart-home service calls against a real Home Assistant instance.
- Browser QA must use existing Playwright API mocks.
- Before modifying any function, class, or method, run `gitnexus impact` for that symbol if GitNexus is available and current.
- Before commit, run `gitnexus detect_changes` on staged changes.
- If GitNexus reports a stale index and `npx gitnexus analyze` is blocked by network policy, record that in the handoff and continue with local checks.

## File Structure

Create:

- `frontend/src/features/today/types.ts` — Today domain types used by pure builders, hook, and UI.
- `frontend/src/features/today/todayBrief.ts` — pure data-to-brief builder with no React or network dependency.
- `frontend/src/features/today/hooks/useTodayData.ts` — frontend-only aggregator that calls existing APIs and returns a stable Today view model.
- `frontend/src/features/today/components/DailySummary.tsx` — first-screen summary sentence and quiet badge.
- `frontend/src/features/today/components/AttentionQueue.tsx` — ranked attention items with view/snooze-style actions.
- `frontend/src/features/today/components/QuietStatusPanel.tsx` — module status panel for prices, jobs, and home.
- `frontend/src/features/today/components/TodayRhythm.tsx` — day-rhythm layout wrapper.
- `frontend/src/features/today/components/index.ts` — component exports.
- `frontend/src/features/today/TodayPage.tsx` — `/today` route page.
- `frontend/src/features/today/index.ts` — route export.
- `frontend/tests/unit/today/today-brief.test.ts` — pure builder coverage.
- `frontend/tests/unit/today/today-page.test.tsx` — rendered Today page coverage with mocked APIs.

Modify:

- `doc/DESIGN.md` — replace the old Neo-Brutalist Zine source of truth with the approved Lived-In Morning Brief system.
- `frontend/src/styles/fonts.css` — add Newsreader, Noto Serif SC, IBM Plex Sans, Noto Sans SC, and IBM Plex Mono font faces or imports using the existing self-hosting pattern.
- `frontend/src/styles/design-tokens.css` — replace or alias old tokens to warm lived-in tokens.
- `frontend/src/styles/components.css` — soften Ant Design overrides and remove hard neo-brutalist global styling.
- `frontend/src/styles/motion.css` — replace bounce motion with quiet tactile timings.
- `frontend/src/index.css` — remove dot-grid paper background and brutalist scrollbar colors.
- `frontend/src/App.tsx` — add `/today`, redirect `/` and auth fallback to `/today`, update Ant Design tokens.
- `frontend/src/shared/components/AppLayout.tsx` — update brand, navigation labels, shell styling, and selected-key handling.
- `frontend/src/features/dashboard/DashboardPage.tsx` — relabel as Analytics/Data Board and keep dense charts.
- `frontend/tests/e2e/navigation.spec.ts` — update root redirect and nav expectations.
- `frontend/tests/unit/shared/theme-provider.test.tsx` — add evening-mode expectation if dark mode copy changes.
- `frontend/tests/unit/mocks/handlers.ts` — add Today page API data needed by tests.

Do not modify backend routes in this plan.

---

### Task 1: Refresh Design Source And Token Contract

**Files:**
- Modify: `doc/DESIGN.md`
- Modify: `frontend/src/styles/fonts.css`
- Modify: `frontend/src/styles/design-tokens.css`
- Modify: `frontend/src/styles/motion.css`
- Test: none, visual/token-only

- [ ] **Step 1: Run impact checks for changed frontend symbols**

Run these before code edits if GitNexus is usable:

```powershell
gitnexus impact --repo mavra-monitor-system --target ThemeProvider --direction upstream
gitnexus impact --repo mavra-monitor-system --target AppRoutes --direction upstream
gitnexus impact --repo mavra-monitor-system --target AppLayout --direction upstream
```

Expected: risk is reviewed before editing. If the GitNexus index is stale and cannot be rebuilt safely, record the exact warning in the task notes.

- [ ] **Step 2: Update `doc/DESIGN.md`**

Replace the current Neo-Brutalist Zine guidance with the approved system from `docs/2026-06-10-lived-in-morning-brief-design-system.md`.

Keep these sections:

```markdown
# Design System — Mavra Monitor System

## Product Context

Mavra Monitor System is a personal automation center for prices, job opportunities, and Home Assistant state.

## Design Thesis

Lived-In Morning Brief: Mavra watches quietly, then only speaks when something is worth attention.

## Non-Negotiables

- The first screen is Today, not a KPI wall.
- Summary surfaces may be warm and human.
- Tables, forms, logs, and admin pages stay compact and precise.
- Browser QA must flag UI that still looks neo-brutalist: hard black borders, pop color blocks, offset shadows, uppercase zine labels.
```

- [ ] **Step 3: Update fonts**

In `frontend/src/styles/fonts.css`, keep the existing self-hosting strategy if local font files already exist. If the current file imports Google Fonts, replace with these families:

```css
@import url("https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@400;500;600;700&family=Newsreader:opsz,wght@6..72,400;6..72,500;6..72,600&family=Noto+Sans+SC:wght@400;500;700&family=Noto+Serif+SC:wght@500;600;700&display=swap");
```

If self-hosted font files exist under `frontend/src/assets`, use `@font-face` instead of remote imports and keep `font-display: swap`.

- [ ] **Step 4: Replace token foundation**

In `frontend/src/styles/design-tokens.css`, define the new token set. Keep legacy aliases for old variable names during migration so existing pages do not break.

```css
:root {
  --color-canvas: #f3dfc8;
  --color-surface: #fff7ec;
  --color-surface-soft: #fff7ec;
  --color-surface-raised: #ffffff;
  --color-ink: #33251b;
  --color-muted: #705947;
  --color-border: rgba(93, 61, 38, 0.12);
  --color-border-strong: rgba(93, 61, 38, 0.22);
  --color-sage: #7e976b;
  --color-clay: #d9826b;
  --color-mist: #7aa2a4;
  --color-butter: #fff1cf;
  --color-rose: #f8d7c8;
  --color-success: #7e976b;
  --color-warning: #d89a57;
  --color-error: #c75f4c;
  --color-info: #7aa2a4;
  --color-opportunity: #d9826b;
  --color-primary: #7e976b;
  --color-on-primary: #ffffff;

  --font-display: "Newsreader", "Noto Serif SC", serif;
  --font-body: "IBM Plex Sans", "Noto Sans SC", sans-serif;
  --font-data: "IBM Plex Mono", monospace;
  --font-mono: "IBM Plex Mono", monospace;

  --font-size-display-xl: 48px;
  --font-size-display-lg: 34px;
  --font-size-headline: 22px;
  --font-size-card-title: 17px;
  --font-size-body: 14px;
  --font-size-body-sm: 13px;
  --font-size-caption: 12px;

  --radius-sm: 10px;
  --radius-md: 16px;
  --radius-lg: 24px;
  --radius-xl: 32px;
  --radius-pill: 9999px;

  --shadow-soft: 0 16px 50px rgba(92, 58, 29, 0.1);
  --shadow-panel: 0 24px 80px rgba(92, 58, 29, 0.12);

  --border-width: 1px;

  /* Legacy aliases for incremental migration. */
  --color-block-yellow: var(--color-butter);
  --color-block-lime: var(--color-sage);
  --color-block-lilac: #e9dfd2;
  --color-block-cyan: var(--color-mist);
  --color-block-pink: var(--color-rose);
  --color-block-orange: var(--color-clay);
  --color-block-cream: var(--color-surface);
  --color-hairline: var(--color-border);
  --shadow-offset-sm: var(--shadow-soft);
  --shadow-offset-md: var(--shadow-soft);
  --shadow-offset-lg: var(--shadow-panel);
  --shadow-card: var(--shadow-soft);
}
```

- [ ] **Step 5: Update motion tokens**

In `frontend/src/styles/motion.css`, replace the brutalist easing variables:

```css
:root {
  --ease-calm-enter: cubic-bezier(0.2, 0.8, 0.2, 1);
  --ease-calm-exit: cubic-bezier(0.4, 0, 1, 1);
  --ease-calm-move: cubic-bezier(0.2, 0, 0, 1);
  --ease-brutalist: var(--ease-calm-enter);
  --duration-micro: 100ms;
  --duration-short: 180ms;
  --duration-medium: 240ms;
}
```

- [ ] **Step 6: Run style-adjacent checks**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run lint
```

Expected: lint passes or only reports pre-existing unrelated issues. If lint fails, fix files touched in this task before committing.

- [ ] **Step 7: Commit**

```powershell
git add doc/DESIGN.md frontend/src/styles/fonts.css frontend/src/styles/design-tokens.css frontend/src/styles/motion.css
git commit -m "style: add lived-in morning brief design tokens"
```

---

### Task 2: Add Today Brief Pure Model

**Files:**
- Create: `frontend/src/features/today/types.ts`
- Create: `frontend/src/features/today/todayBrief.ts`
- Create: `frontend/tests/unit/today/today-brief.test.ts`

- [ ] **Step 1: Write failing tests for brief generation**

Create `frontend/tests/unit/today/today-brief.test.ts`:

```ts
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
```

- [ ] **Step 2: Run the failing test**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/today/today-brief.test.ts
```

Expected: FAIL because `@/features/today/todayBrief` does not exist.

- [ ] **Step 3: Add Today types**

Create `frontend/src/features/today/types.ts`:

```ts
import type { UserKPI } from "@/features/dashboard/types";

export type TodayAttentionKind = "price" | "job" | "home";
export type TodayStatusState = "quiet" | "attention" | "inactive";

export interface TodayProductSignal {
  id: number;
  title: string | null;
  platform: string;
}

export interface TodayJobSignal {
  id: number;
  score: number;
  title: string | null;
  company: string | null;
  location: string | null;
}

export interface TodayHomeSignal {
  configured: boolean;
  connected: boolean;
  unavailableCount: number;
  activeCount: number;
}

export interface TodaySourceData {
  now: Date;
  kpi: UserKPI;
  products: TodayProductSignal[];
  jobMatches: TodayJobSignal[];
  home: TodayHomeSignal;
}

export interface TodayAttentionItem {
  id: string;
  kind: TodayAttentionKind;
  timeLabel: "早晨" | "今天" | "稍后";
  title: string;
  description: string;
  metric: string;
  actionLabel: string;
  href: string;
}

export interface TodayModuleStatus {
  label: string;
  state: TodayStatusState;
  summary: string;
  href: string;
}

export interface TodayBrief {
  headline: string;
  subhead: string;
  quietScore: number;
  attentionItems: TodayAttentionItem[];
  moduleStatuses: {
    prices: TodayModuleStatus;
    jobs: TodayModuleStatus;
    home: TodayModuleStatus;
  };
}
```

- [ ] **Step 4: Add pure brief builder**

Create `frontend/src/features/today/todayBrief.ts`:

```ts
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
      summary: `${Math.max(source.kpi.match_count, source.kpi.new_jobs_today)} 个职位值得看看。`,
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
      metric: topMatch ? String(Math.round(topMatch.score)) : String(source.kpi.match_count),
      actionLabel: "收藏",
      href: "/jobs",
    });
  }

  if (source.home.configured && (!source.home.connected || source.home.unavailableCount > 0)) {
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
```

- [ ] **Step 5: Run the test again**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/today/today-brief.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add frontend/src/features/today/types.ts frontend/src/features/today/todayBrief.ts frontend/tests/unit/today/today-brief.test.ts
git commit -m "feat(frontend): add today brief model"
```

---

### Task 3: Add Today Data Hook With Existing APIs

**Files:**
- Create: `frontend/src/features/today/hooks/useTodayData.ts`
- Create: `frontend/src/features/today/index.ts`
- Modify: `frontend/tests/unit/mocks/handlers.ts`
- Test: `frontend/tests/unit/today/today-page.test.tsx`

- [ ] **Step 1: Write a hook/page-level loading test**

Create `frontend/tests/unit/today/today-page.test.tsx`:

```tsx
import { screen, waitFor } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { renderWithProviders } from "../test-utils";
import { TodayPage } from "@/features/today";

describe("TodayPage", () => {
  it("renders the lived-in morning brief from mocked APIs", async () => {
    renderWithProviders(<TodayPage />);

    expect(screen.getByText("正在整理今天的节奏...")).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText("今天只提醒 2 件事。")).toBeInTheDocument();
    });

    expect(screen.getByText(/Dell 显示器/)).toBeInTheDocument();
    expect(screen.getByText(/Frontend Engineer/)).toBeInTheDocument();
    expect(screen.getByText("家里设备都在安静运行。")).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run the failing test**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/today/today-page.test.tsx
```

Expected: FAIL because `TodayPage` does not exist.

- [ ] **Step 3: Add mock API handlers**

In `frontend/tests/unit/mocks/handlers.ts`, add handlers for the Today page if they are not already present:

```ts
http.get("/api/v1/dashboard/kpi", () =>
  HttpResponse.json({
    user: {
      total_products: 3,
      price_drops_today: 1,
      new_jobs_today: 2,
      match_count: 1,
      crawl_count_today: 4,
    },
    system: null,
  }),
),
http.get("/api/v1/products", () =>
  HttpResponse.json({
    items: [
      {
        id: 12,
        user_id: 1,
        platform: "jd",
        url: "https://item.jd.com/12.html",
        platform_product_id: "12",
        title: "Dell 显示器",
        active: true,
        created_at: "2026-06-10T00:00:00Z",
        updated_at: "2026-06-10T00:00:00Z",
      },
    ],
    total: 1,
    page: 1,
    page_size: 5,
  }),
),
http.get("/api/v1/jobs/match-results", () =>
  HttpResponse.json({
    items: [
      {
        id: 9,
        user_id: 1,
        resume_id: 1,
        job_id: 88,
        match_score: 92,
        match_reason: "Strong frontend match",
        apply_recommendation: "recommended",
        llm_model_used: "test",
        created_at: "2026-06-10T00:00:00Z",
        updated_at: "2026-06-10T00:00:00Z",
        job_title: "Frontend Engineer",
        job_company: "Example Co",
        job_salary: "30-45K",
        job_location: "Shanghai",
        job_url: "https://example.test/job",
        job_description: "Build UI",
      },
    ],
    total: 1,
    page: 1,
    page_size: 5,
  }),
),
http.get("/api/v1/smart-home/config", () =>
  HttpResponse.json({
    id: 1,
    base_url: "http://homeassistant.local:8123",
    enabled: true,
    last_status: "connected",
    last_error: null,
    token_configured: true,
    created_at: "2026-06-10T00:00:00Z",
    updated_at: "2026-06-10T00:00:00Z",
  }),
),
http.get("/api/v1/smart-home/entities", () =>
  HttpResponse.json({
    items: [
      {
        entity_id: "light.living_room",
        domain: "light",
        name: "Living Room",
        state: "on",
        area: "客厅",
        attributes: {},
        last_changed: "2026-06-10T00:00:00Z",
        last_updated: "2026-06-10T00:00:00Z",
        available: true,
      },
    ],
    total: 1,
    connected: true,
    last_error: null,
  }),
),
```

Use existing imports from the file. If the file uses `http` and `HttpResponse` already, do not duplicate imports.

- [ ] **Step 4: Implement the data hook**

Create `frontend/src/features/today/hooks/useTodayData.ts`:

```ts
import { useEffect, useState } from "react";
import api from "@/shared/api/client";
import { productsApi } from "@/features/products/api/products";
import { jobsApi } from "@/features/jobs/api/jobs";
import { smartHomeApi } from "@/features/smart-home/api/smartHome";
import { buildTodayBrief } from "../todayBrief";
import type { DashboardKPIResponse } from "@/features/dashboard/types";
import type { MatchResultListResponse } from "@/features/jobs/types";
import type { TodayBrief, TodaySourceData } from "../types";

interface TodayDataState {
  data: TodayBrief | null;
  loading: boolean;
  error: string | null;
}

const DEFAULT_KPI = {
  total_products: 0,
  price_drops_today: 0,
  new_jobs_today: 0,
  match_count: 0,
  crawl_count_today: 0,
};

export function useTodayData(): TodayDataState {
  const [state, setState] = useState<TodayDataState>({
    data: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    let cancelled = false;

    async function loadToday() {
      setState((prev) => ({ ...prev, loading: true, error: null }));

      try {
        const [kpiResult, productsResult, matchesResult, configResult, entitiesResult] =
          await Promise.allSettled([
            api.get<DashboardKPIResponse>("/v1/dashboard/kpi"),
            productsApi.list({ active: true, page: 1, size: 5 }),
            jobsApi.getMatchResults({ page: 1, page_size: 5 }),
            smartHomeApi.getConfig(),
            smartHomeApi.listEntities(),
          ]);

        if (cancelled) return;

        const kpi =
          kpiResult.status === "fulfilled"
            ? kpiResult.value.data.user
            : DEFAULT_KPI;
        const products =
          productsResult.status === "fulfilled"
            ? productsResult.value.data.items.map((product) => ({
                id: product.id,
                title: product.title,
                platform: product.platform,
              }))
            : [];
        const matchResponse =
          matchesResult.status === "fulfilled"
            ? (matchesResult.value.data as MatchResultListResponse)
            : null;
        const jobMatches =
          matchResponse?.items.map((match) => ({
            id: match.id,
            score: match.match_score,
            title: match.job_title,
            company: match.job_company,
            location: match.job_location,
          })) ?? [];
        const config =
          configResult.status === "fulfilled" ? configResult.value.data : null;
        const entities =
          entitiesResult.status === "fulfilled" ? entitiesResult.value.data : null;

        const source: TodaySourceData = {
          now: new Date(),
          kpi,
          products,
          jobMatches,
          home: {
            configured: Boolean(config?.enabled && config?.token_configured),
            connected: Boolean(entities?.connected),
            unavailableCount:
              entities?.items.filter((entity) => !entity.available).length ?? 0,
            activeCount: entities?.items.filter((entity) => entity.available).length ?? 0,
          },
        };

        setState({
          data: buildTodayBrief(source),
          loading: false,
          error: null,
        });
      } catch {
        if (!cancelled) {
          setState({
            data: buildTodayBrief({
              now: new Date(),
              kpi: DEFAULT_KPI,
              products: [],
              jobMatches: [],
              home: {
                configured: false,
                connected: false,
                unavailableCount: 0,
                activeCount: 0,
              },
            }),
            loading: false,
            error: "今天的简报没有完全同步，稍后会再试。",
          });
        }
      }
    }

    void loadToday();

    return () => {
      cancelled = true;
    };
  }, []);

  return state;
}
```

- [ ] **Step 5: Add feature export**

Create `frontend/src/features/today/index.ts`:

```ts
export { default as TodayPage } from "./TodayPage";
```

This will still fail until the page exists in Task 4.

- [ ] **Step 6: Run focused tests**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/today/today-brief.test.ts tests/unit/today/today-page.test.tsx
```

Expected: `today-brief.test.ts` passes, `today-page.test.tsx` still fails because `TodayPage.tsx` is not created yet.

- [ ] **Step 7: Commit**

Do not commit yet if the suite is red only because Task 4 must create `TodayPage.tsx`. If implementation is split across workers, commit Task 3 and Task 4 together.

---

### Task 4: Build Today UI Components And Page

**Files:**
- Create: `frontend/src/features/today/components/DailySummary.tsx`
- Create: `frontend/src/features/today/components/AttentionQueue.tsx`
- Create: `frontend/src/features/today/components/QuietStatusPanel.tsx`
- Create: `frontend/src/features/today/components/TodayRhythm.tsx`
- Create: `frontend/src/features/today/components/index.ts`
- Create: `frontend/src/features/today/TodayPage.tsx`
- Modify: `frontend/tests/unit/today/today-page.test.tsx`

- [ ] **Step 1: Create `DailySummary`**

Create `frontend/src/features/today/components/DailySummary.tsx`:

```tsx
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
```

- [ ] **Step 2: Create `AttentionQueue`**

Create `frontend/src/features/today/components/AttentionQueue.tsx`:

```tsx
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
    <section className="today-card" aria-labelledby="today-attention-title">
      <h2 id="today-attention-title">值得看</h2>
      <div className="today-attention-list">
        {items.map((item) => (
          <article className={`today-attention today-attention--${item.kind}`} key={item.id}>
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
```

- [ ] **Step 3: Create `QuietStatusPanel`**

Create `frontend/src/features/today/components/QuietStatusPanel.tsx`:

```tsx
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
```

- [ ] **Step 4: Create `TodayRhythm`**

Create `frontend/src/features/today/components/TodayRhythm.tsx`:

```tsx
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
```

- [ ] **Step 5: Export components**

Create `frontend/src/features/today/components/index.ts`:

```ts
export { AttentionQueue } from "./AttentionQueue";
export { DailySummary } from "./DailySummary";
export { QuietStatusPanel } from "./QuietStatusPanel";
export { TodayRhythm } from "./TodayRhythm";
```

- [ ] **Step 6: Create `TodayPage`**

Create `frontend/src/features/today/TodayPage.tsx`:

```tsx
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
```

- [ ] **Step 7: Add Today CSS**

Add these class rules to `frontend/src/styles/components.css` near custom component styles:

```css
.today-page {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(280px, 360px);
  gap: var(--spacing-xl);
  max-width: 1280px;
  margin: 0 auto;
}

.today-page--loading {
  display: block;
  max-width: 860px;
  color: var(--color-muted);
}

.today-page__main,
.today-page__side,
.today-attention-list {
  display: grid;
  gap: var(--spacing-lg);
}

.today-summary {
  padding: var(--spacing-xxl);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-xl);
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.72), rgba(255, 255, 255, 0.28)),
    var(--color-canvas);
  box-shadow: var(--shadow-panel);
}

.today-summary__meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--spacing-md);
  color: var(--color-muted);
  font-size: var(--font-size-body-sm);
}

.today-summary__quiet {
  border-radius: var(--radius-pill);
  background: rgba(126, 151, 107, 0.16);
  color: #526c43;
}

.today-summary h1 {
  max-width: 760px;
  margin: var(--spacing-xl) 0 var(--spacing-md);
  font-family: var(--font-display);
  font-size: clamp(34px, 5vw, var(--font-size-display-xl));
  line-height: 1.04;
  font-weight: 500;
  letter-spacing: -0.02em;
  color: var(--color-ink);
}

.today-summary p,
.today-attention p,
.today-status small {
  color: var(--color-muted);
  line-height: 1.55;
}

.today-card {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  background: rgba(255, 255, 255, 0.56);
  box-shadow: var(--shadow-soft);
  padding: var(--spacing-lg);
}

.today-card h2 {
  margin: 0 0 var(--spacing-md);
  font-family: var(--font-body);
  font-size: var(--font-size-headline);
  font-weight: 600;
}

.today-attention {
  display: grid;
  grid-template-columns: 76px minmax(0, 1fr) auto;
  gap: var(--spacing-md);
  align-items: center;
  padding: var(--spacing-md);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  background: rgba(255, 255, 255, 0.58);
}

.today-attention__time {
  color: var(--color-muted);
  font-size: var(--font-size-body-sm);
}

.today-attention h3 {
  margin: 0 0 var(--spacing-xs);
  font-size: var(--font-size-card-title);
}

.today-attention__action {
  display: grid;
  justify-items: end;
  gap: var(--spacing-sm);
}

.today-attention__action strong {
  font-family: var(--font-data);
  color: var(--color-clay);
}

.today-status__row {
  display: flex;
  justify-content: space-between;
  gap: var(--spacing-md);
  padding: var(--spacing-md) 0;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-ink);
  text-decoration: none;
}

.today-status__row:last-child {
  border-bottom: 0;
}

.today-status__row span {
  display: grid;
  gap: var(--spacing-xs);
}

.today-status__row em {
  color: var(--color-muted);
  font-style: normal;
  white-space: nowrap;
}

@media (max-width: 900px) {
  .today-page {
    grid-template-columns: 1fr;
  }

  .today-summary {
    padding: var(--spacing-xl);
  }

  .today-attention {
    grid-template-columns: 1fr;
  }

  .today-attention__action {
    justify-items: start;
  }
}
```

- [ ] **Step 8: Run focused tests**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/today/today-brief.test.ts tests/unit/today/today-page.test.tsx
```

Expected: PASS.

- [ ] **Step 9: Commit Task 3 and Task 4 together if Task 3 was not committed**

```powershell
git add frontend/src/features/today frontend/src/styles/components.css frontend/tests/unit/today frontend/tests/unit/mocks/handlers.ts
git commit -m "feat(frontend): add lived-in today page"
```

---

### Task 5: Route Today First And Update App Shell

**Files:**
- Modify: `frontend/src/App.tsx`
- Modify: `frontend/src/shared/components/AppLayout.tsx`
- Modify: `frontend/tests/e2e/navigation.spec.ts`
- Test: `frontend/tests/e2e/navigation.spec.ts`

- [ ] **Step 1: Run impact checks**

Run:

```powershell
gitnexus impact --repo mavra-monitor-system --target AppRoutes --direction upstream
gitnexus impact --repo mavra-monitor-system --target ProtectedRoute --direction upstream
gitnexus impact --repo mavra-monitor-system --target AppLayout --direction upstream
```

Expected: review risk before route edits. If unavailable, record the GitNexus limitation.

- [ ] **Step 2: Add lazy Today route**

In `frontend/src/App.tsx`, add:

```tsx
const TodayPage = React.lazy(() =>
  import("@/features/today").then((m) => ({ default: m.TodayPage })),
);
```

Add the protected route:

```tsx
<Route path="/today" element={<TodayPage />} />
```

Change auth redirects:

```tsx
return <Navigate to="/today" replace />;
```

Change default routes:

```tsx
<Route path="/" element={<Navigate to="/today" replace />} />
<Route path="*" element={<Navigate to="/today" replace />} />
```

Keep `/dashboard` mounted.

- [ ] **Step 3: Update Ant Design theme tokens**

In `frontend/src/App.tsx`, update the token object:

```tsx
token: {
  colorPrimary: currentTheme === "dark" ? "#d8c3a5" : "#7e976b",
  colorBgLayout: currentTheme === "dark" ? "#211a16" : "#f3dfc8",
  colorBgContainer: currentTheme === "dark" ? "#2b221c" : "#fff7ec",
  colorText: currentTheme === "dark" ? "#f7f0e4" : "#33251b",
  colorTextSecondary: currentTheme === "dark" ? "#c9b8a5" : "#705947",
  colorBorder: currentTheme === "dark" ? "rgba(247, 240, 228, 0.18)" : "rgba(93, 61, 38, 0.12)",
  colorBorderSecondary: currentTheme === "dark" ? "rgba(247, 240, 228, 0.12)" : "rgba(93, 61, 38, 0.08)",
  colorSuccess: "#7e976b",
  colorWarning: "#d89a57",
  colorError: "#c75f4c",
  colorInfo: "#7aa2a4",
  borderRadius: 16,
  fontSize: 14,
  fontFamily: '"IBM Plex Sans", "Noto Sans SC", sans-serif',
}
```

Update component tokens:

```tsx
components: {
  Button: {
    borderRadius: 999,
    controlHeight: 36,
  },
  Table: {
    borderRadius: 16,
    headerBg: currentTheme === "dark" ? "#2b221c" : "#fff7ec",
  },
  Card: {
    borderRadius: 24,
  },
  Menu: {
    itemSelectedBg:
      currentTheme === "dark"
        ? "rgba(216, 195, 165, 0.14)"
        : "rgba(126, 151, 107, 0.16)",
    itemSelectedColor: currentTheme === "dark" ? "#f7f0e4" : "#33251b",
  },
}
```

- [ ] **Step 4: Update layout menu items**

In `frontend/src/shared/components/AppLayout.tsx`, update selected route prefixes:

```ts
const prefix = [
  "/today",
  "/dashboard",
  "/events",
  "/jobs",
  "/products",
  "/schedule",
  "/smart-home",
].find((p) => path.startsWith(p));
```

Change fallback:

```ts
return "/today";
```

Update menu labels:

```tsx
{
  key: "/today",
  icon: <HomeOutlined style={{ fontSize: 14 }} />,
  label: "Today",
},
{
  key: "/dashboard",
  icon: <DashboardOutlined style={{ fontSize: 14 }} />,
  label: "Analytics",
},
{
  key: "/events",
  icon: <NotificationOutlined style={{ fontSize: 14 }} />,
  label: "Activity",
},
{
  key: "/jobs",
  icon: <TeamOutlined style={{ fontSize: 14 }} />,
  label: "Jobs",
},
{
  key: "/products",
  icon: <ShoppingCartOutlined style={{ fontSize: 14 }} />,
  label: "Prices",
},
{
  key: "/schedule",
  icon: <ScheduleOutlined style={{ fontSize: 14 }} />,
  label: "Rules",
},
{
  key: "/smart-home",
  icon: <HomeOutlined style={{ fontSize: 14 }} />,
  label: "Home",
},
```

- [ ] **Step 5: Update brand shell copy**

Replace visible `Price Monitor` with:

```tsx
Mavra
```

Replace footer:

```tsx
Mavra watches quietly © 2026
```

Change logo letter from `P` to:

```tsx
M
```

- [ ] **Step 6: Update route E2E**

In `frontend/tests/e2e/navigation.spec.ts`, change root redirect test:

```ts
test("redirects / to /today", async ({ page }) => {
  await page.goto("/");
  await page.waitForURL("**/today");
  await expect(page).toHaveURL(/.*\/today/);
});
```

Change navigation test to start at `/today` and click labels:

```ts
await page.goto("/today");

await page.click('a[href="/dashboard"], .ant-menu-item:has-text("Analytics")');
await page.waitForURL("**/dashboard");

await page.click('a[href="/events"], .ant-menu-item:has-text("Activity")');
await page.waitForURL("**/events");

await page.click('a[href="/jobs"], .ant-menu-item:has-text("Jobs")');
await page.waitForURL("**/jobs");

await page.click('a[href="/products"], .ant-menu-item:has-text("Prices")');
await page.waitForURL("**/products");

await page.click('a[href="/schedule"], .ant-menu-item:has-text("Rules")');
await page.waitForURL("**/schedule");

await page.click('a[href="/smart-home"], .ant-menu-item:has-text("Home")');
await page.waitForURL("**/smart-home");
```

Change permission redirect expectation:

```ts
await page.goto("/admin/users");
await page.waitForURL("**/today");
await expect(page).toHaveURL(/.*\/today/);
```

- [ ] **Step 7: Run focused tests**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/today/today-page.test.tsx tests/unit/shared/theme-provider.test.tsx
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run build
```

Expected: PASS.

- [ ] **Step 8: Commit**

```powershell
git add frontend/src/App.tsx frontend/src/shared/components/AppLayout.tsx frontend/tests/e2e/navigation.spec.ts
git commit -m "feat(frontend): route to today first"
```

---

### Task 6: Soften Global Components Without Breaking Dense Workflows

**Files:**
- Modify: `frontend/src/styles/components.css`
- Modify: `frontend/src/index.css`
- Modify: `frontend/src/features/dashboard/DashboardPage.tsx`
- Test: `frontend/tests/unit/dashboard/dashboard-sse.test.tsx`

- [ ] **Step 1: Remove global neo-brutalist body decoration**

In `frontend/src/index.css`, replace the header comment and remove `body::after`.

Use:

```css
/* ============================================================
   Global Styles — Lived-In Morning Brief Design System
   ============================================================ */
```

Replace scrollbar rules:

```css
::-webkit-scrollbar {
  width: 10px;
  height: 10px;
}

::-webkit-scrollbar-track {
  background: var(--color-canvas);
}

::-webkit-scrollbar-thumb {
  background: rgba(112, 89, 71, 0.28);
  border-radius: var(--radius-pill);
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(112, 89, 71, 0.44);
}
```

- [ ] **Step 2: Replace brutalist Ant Design card/button overrides**

In `frontend/src/styles/components.css`, update button/card/table sections to remove uppercase, hard borders, and offset shadows.

Use this button baseline:

```css
.ant-btn,
.fg-btn-primary,
.fg-btn-secondary,
.fg-btn-danger,
.header-cta {
  border-radius: var(--radius-pill) !important;
  font-family: var(--font-body) !important;
  font-weight: 600 !important;
  text-transform: none;
  box-shadow: none !important;
  transition:
    transform var(--duration-short) var(--ease-calm-enter),
    background-color var(--duration-short) var(--ease-calm-enter),
    border-color var(--duration-short) var(--ease-calm-enter) !important;
}

.ant-btn:hover:not(:disabled),
.fg-btn-primary:hover:not(:disabled),
.fg-btn-secondary:hover:not(:disabled),
.fg-btn-danger:hover:not(:disabled),
.header-cta:hover:not(:disabled) {
  transform: translateY(-1px) !important;
}
```

Use this card baseline:

```css
.ant-card,
.fg-card {
  border: 1px solid var(--color-border) !important;
  border-radius: var(--radius-lg) !important;
  background: var(--color-surface) !important;
  box-shadow: var(--shadow-soft) !important;
  overflow: hidden;
}

.ant-card:hover,
.fg-card:hover {
  transform: none;
  box-shadow: var(--shadow-soft) !important;
}

.ant-card-head,
.fg-card-header {
  border-bottom: 1px solid var(--color-border) !important;
  background: transparent !important;
  color: var(--color-ink) !important;
  font-family: var(--font-body) !important;
  font-weight: 600 !important;
  text-transform: none;
}
```

Use this table baseline:

```css
.ant-table-wrapper {
  border: 1px solid var(--color-border) !important;
  border-radius: var(--radius-md) !important;
  overflow: hidden !important;
  box-shadow: none !important;
}

.ant-table-thead > tr > th {
  background: var(--color-surface) !important;
  color: var(--color-ink) !important;
  font-family: var(--font-body) !important;
  font-weight: 600 !important;
  text-transform: none;
  border-bottom: 1px solid var(--color-border) !important;
}

.ant-table-tbody > tr > td {
  border-bottom: 1px solid var(--color-border) !important;
  background: var(--color-surface-raised) !important;
  font-family: var(--font-body) !important;
  color: var(--color-ink) !important;
}
```

- [ ] **Step 3: Relabel `DashboardPage` as Analytics**

In `frontend/src/features/dashboard/DashboardPage.tsx`, change the visible heading:

```tsx
<h1 style={{ margin: 0, fontSize: 24, fontWeight: 600 }}>数据分析</h1>
```

Do not remove KPI cards or charts in this task.

- [ ] **Step 4: Run focused tests**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit -- tests/unit/dashboard/dashboard-sse.test.tsx
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run build
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add frontend/src/styles/components.css frontend/src/index.css frontend/src/features/dashboard/DashboardPage.tsx
git commit -m "style(frontend): soften global app surfaces"
```

---

### Task 7: Mock-Only Browser QA

**Files:**
- Modify: `frontend/tests/e2e/navigation.spec.ts`
- Optionally modify: `frontend/tests/e2e/fixtures/api-mock.ts`

- [ ] **Step 1: Ensure E2E API mocks cover Today**

In `frontend/tests/e2e/fixtures/api-mock.ts`, add mocked routes matching Task 3 if missing:

```ts
api.use("GET", "/api/v1/dashboard/kpi", () => ({
  body: {
    user: {
      total_products: 3,
      price_drops_today: 1,
      new_jobs_today: 2,
      match_count: 1,
      crawl_count_today: 4,
    },
    system: null,
  },
}));
```

Also add `/api/v1/products`, `/api/v1/jobs/match-results`, `/api/v1/smart-home/config`, and `/api/v1/smart-home/entities` if the fixture does not already define them.

- [ ] **Step 2: Add Today visual smoke to navigation E2E**

In `frontend/tests/e2e/navigation.spec.ts`, add:

```ts
test("renders today as the first warm brief screen", async ({ page }) => {
  await page.goto("/today");
  await expect(page.getByRole("heading", { name: /今天只提醒|今天很安静/ })).toBeVisible();
  await expect(page.getByText("今天的状态")).toBeVisible();
  await expect(page.locator(".today-summary")).toBeVisible();
});
```

- [ ] **Step 3: Run mock-only E2E**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:e2e -- tests/e2e/navigation.spec.ts --project=chromium
```

Expected: PASS. If the dev server is required, use the repo's established frontend test workflow, still with mock API fixtures only.

- [ ] **Step 4: Manual browser QA**

Start local app if needed:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run dev
```

Open `/today` with mock-safe auth or the project's seeded test auth path. Verify:

- Desktop `/today` has summary, attention queue, and status panel.
- Mobile width stacks summary, queue, then status without overlap.
- `/dashboard` remains available as Analytics.
- `/products`, `/jobs`, `/smart-home`, `/schedule`, `/events` still navigate.
- No real crawl or smart-home service action is triggered.

- [ ] **Step 5: Commit**

```powershell
git add frontend/tests/e2e/navigation.spec.ts frontend/tests/e2e/fixtures/api-mock.ts
git commit -m "test(frontend): cover today-first navigation"
```

---

### Task 8: Final Verification And Documentation Sync

**Files:**
- Modify: `README.md` if it still describes root as `/jobs` or dashboard-first
- Modify: `doc/frontend-architecture.md` if it documents the old design-system routing
- Modify: `docs/2026-06-10-lived-in-morning-brief-design-system.md` only if implementation changed decisions

- [ ] **Step 1: Search for stale design copy**

Run:

```powershell
rg "Neo-Brutalist|Zine|Price Monitor|Dashboard-first|/dashboard|root redirects" README.md doc frontend/src frontend/tests -n
```

Expected: only intentional historical references remain. Update active docs and UI copy.

- [ ] **Step 2: Run frontend quality gate**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run lint
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:unit
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run build
```

Expected: PASS.

- [ ] **Step 3: Run mock-only E2E smoke**

Run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run test:e2e -- tests/e2e/navigation.spec.ts --project=chromium
```

Expected: PASS.

- [ ] **Step 4: Run GitNexus detect changes**

Run:

```powershell
gitnexus detect_changes --repo mavra-monitor-system --scope staged
```

Expected: affected flows match frontend design, routing, and Today page only. If risk is HIGH or CRITICAL, stop and review with the user before committing.

- [ ] **Step 5: Final commit**

```powershell
git add README.md doc/frontend-architecture.md docs/2026-06-10-lived-in-morning-brief-design-system.md
git commit -m "docs: sync lived-in morning brief rollout"
```

Skip this commit if no documentation files changed.

## Rollout Notes

The first implementation should stop after Today-first routing, shared token migration, and mock-only QA pass. Do not migrate every products/jobs/smart-home screen in the same batch unless the user explicitly asks for a full visual rewrite. The high-risk part is not CSS, it is preserving information density while changing the emotional posture.

## Execution Choice

Plan complete once this file is saved and self-reviewed.

Recommended execution mode: **Subagent-Driven**. Tasks 1-8 are separable enough for one worker per task, with review after each commit. Shared files (`App.tsx`, `AppLayout.tsx`, `components.css`) should still be edited serially, not in parallel.
