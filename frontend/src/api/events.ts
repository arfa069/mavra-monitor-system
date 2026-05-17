import api from "./client";
import type { EventCenterListResponse, EventCenterQuery } from "@/types";

const TOKEN_KEY = "auth_token";

export const eventsApi = {
  listEvents: async (params: EventCenterQuery): Promise<EventCenterListResponse> => {
    const response = await api.get<EventCenterListResponse>("/events", { params });
    return response.data;
  },

  buildStreamUrl: (params: EventCenterQuery) => {
    const token = localStorage.getItem(TOKEN_KEY);
    const searchParams = new URLSearchParams();

    Object.entries(params).forEach(([key, value]) => {
      if (value === undefined || value === null || value === "") {
        return;
      }
      searchParams.set(key, String(value));
    });

    if (token) {
      searchParams.set("token", token);
    }

    return `/api/events/stream?${searchParams.toString()}`;
  },
};
