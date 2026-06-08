import type { EventCenterItem } from "./types";

export interface RealtimeEventState {
  items: EventCenterItem[];
  total: number;
}

export function mergeRealtimeEvent(
  current: RealtimeEventState,
  nextItem: EventCenterItem,
  pageSize: number,
): RealtimeEventState {
  if (current.items.some((item) => item.id === nextItem.id)) {
    return current;
  }

  return {
    items: [nextItem, ...current.items].slice(0, pageSize),
    total: current.total + 1,
  };
}
