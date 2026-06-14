import { eventsListEvents } from "@/shared/api/generated/events/events";
import { apiUrl } from "@/shared/api/base";
import type { EventCenterListResponse, EventCenterQuery } from "../types";

export const eventsApi = {
  listEvents: async (
    params: EventCenterQuery,
  ): Promise<EventCenterListResponse> => {
    return eventsListEvents(params as any);
  },

  buildStreamUrl: (params: EventCenterQuery) => {
    const searchParams = new URLSearchParams();

    Object.entries(params).forEach(([key, value]) => {
      if (value === undefined || value === null || value === "") {
        return;
      }
      searchParams.set(key, String(value));
    });

    const query = searchParams.toString();
    return apiUrl(`/events/stream${query ? `?${query}` : ""}`);
  },
};
