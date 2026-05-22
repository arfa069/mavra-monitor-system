export type EventKind = "all" | "audit" | "system" | "platform";

export interface EventCenterItem {
  id: string;
  kind: "audit" | "system" | "platform";
  event_type: string;
  category: string;
  severity: string;
  message: string;
  occurred_at: string;
  source: string;
  status: string | null;
  user_id: number | null;
  entity_type: string | null;
  entity_id: string | null;
  trace_id: string | null;
  payload: Record<string, unknown> | null;
}

export interface EventCenterListResponse {
  items: EventCenterItem[];
  total: number;
  page: number;
  page_size: number;
}

export interface EventCenterQuery {
  kind?: EventKind;
  event_type?: string;
  category?: string;
  severity?: string;
  source?: string;
  keyword?: string;
  start_at?: string;
  end_at?: string;
  page?: number;
  page_size?: number;
}
