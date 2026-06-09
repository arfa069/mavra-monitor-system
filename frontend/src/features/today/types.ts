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
