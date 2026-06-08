import { screen, waitFor } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { describe, expect, it, vi, beforeAll, afterAll, beforeEach } from "vitest";
import EventCenterPage from "@/features/events/EventCenterPage";
import { eventsApi } from "@/features/events/api/events";
import { server } from "../mocks/server";
import { renderWithApp } from "../test-utils";

class EventSourceStub {
  static instances: EventSourceStub[] = [];
  onmessage: ((event: MessageEvent<string>) => void) | null = null;
  onerror: (() => void) | null = null;
  close = vi.fn();

  constructor(public url: string) {
    EventSourceStub.instances.push(this);
  }

  emit(payload: unknown) {
    this.onmessage?.(
      new MessageEvent("message", { data: JSON.stringify(payload) })
    );
  }

  error() {
    this.onerror?.();
  }
}

const originalEventSource = global.EventSource;

describe("EventCenterPage (Events feature)", () => {
  beforeAll(() => {
    global.EventSource = EventSourceStub as any;
  });

  afterAll(() => {
    global.EventSource = originalEventSource;
  });

  beforeEach(() => {
    EventSourceStub.instances = [];
  });

  it("buildStreamUrl omits empty query values and preserves filters", () => {
    const url = eventsApi.buildStreamUrl({
      kind: "system",
      event_type: "",
      category: null,
      severity: undefined,
      keyword: "test"
    } as any);

    expect(url).toBe("/api/v1/events/stream?kind=system&keyword=test");
  });

  it("renders initial event list response total and prepends new SSE items with deduplication", async () => {
    const mockEvents = [
      {
        id: "event-1",
        kind: "system",
        event_type: "info",
        category: "app",
        severity: "info",
        source: "scheduler",
        message: "Scheduler started",
        payload: {},
        created_at: "2026-06-08T00:00:00Z"
      }
    ];

    server.use(
      http.get("/api/v1/events", () => {
        return HttpResponse.json({
          items: mockEvents,
          total: 1
        });
      })
    );

    const { unmount } = renderWithApp(<EventCenterPage />);

    // Renders initial event total
    expect(await screen.findByText("Total 1 events")).toBeInTheDocument();
    expect(screen.getByText("Scheduler started")).toBeInTheDocument();

    const sseInstance = EventSourceStub.instances[0];
    expect(sseInstance).toBeDefined();

    // Emit a new unique event
    const newEvent = {
      id: "event-2",
      kind: "user",
      event_type: "action",
      category: "auth",
      severity: "info",
      source: "web",
      message: "User logged in",
      payload: {},
      created_at: "2026-06-08T00:01:00Z"
    };

    sseInstance.emit(newEvent);

    // Should prepend and increment total
    expect(await screen.findByText("Total 2 events")).toBeInTheDocument();
    expect(screen.getByText("User logged in")).toBeInTheDocument();

    // Emit duplicate event
    sseInstance.emit(newEvent);

    // Total should NOT increment (remain 2) because it is deduplicated by ID
    expect(screen.getByText("Total 2 events")).toBeInTheDocument();

    // Unmount closes EventSource
    unmount();
    expect(sseInstance.close).toHaveBeenCalled();
  });
});
