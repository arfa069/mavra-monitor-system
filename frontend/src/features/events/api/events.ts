import api from "@/shared/api/client";
import type { EventCenterListResponse, EventCenterQuery } from "../types";

export const eventsApi = {
  listEvents: async (
    params: EventCenterQuery,
  ): Promise<EventCenterListResponse> => {
    const response = await api.get<EventCenterListResponse>("/v1/events", {
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

    return `/api/v1/events/stream?${searchParams.toString()}`;
  },
};
