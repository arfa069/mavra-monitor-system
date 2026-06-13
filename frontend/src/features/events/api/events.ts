import api from "@/shared/api/client";
import { apiUrl } from "@/shared/api/base";
import type { EventCenterListResponse, EventCenterQuery } from "../types";

export const eventsApi = {
  listEvents: async (
    params: EventCenterQuery,
  ): Promise<EventCenterListResponse> => {
    const response = await api.get<EventCenterListResponse>("/events", {
      params,
    });
    return response.data;
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
