import { renderHook, act } from "@testing-library/react";
import {
  describe,
  expect,
  it,
  vi,
  beforeAll,
  afterAll,
  beforeEach,
  afterEach,
} from "vitest";
import { useDashboardSSE } from "@/features/dashboard/hooks/useDashboardSSE";

class EventSourceStub {
  static instances: EventSourceStub[] = [];
  onopen: (() => void) | null = null;
  onmessage: ((event: MessageEvent<string>) => void) | null = null;
  onerror: (() => void) | null = null;
  close = vi.fn();

  constructor(
    public url: string,
    public options?: any,
  ) {
    EventSourceStub.instances.push(this);
  }

  emitMessage(payload: unknown) {
    this.onmessage?.(
      new MessageEvent("message", { data: JSON.stringify(payload) }),
    );
  }

  open() {
    this.onopen?.();
  }

  error() {
    this.onerror?.();
  }
}

const originalEventSource = global.EventSource;

describe("useDashboardSSE Hook", () => {
  beforeAll(() => {
    global.EventSource = EventSourceStub as any;
  });

  afterAll(() => {
    global.EventSource = originalEventSource;
  });

  beforeEach(() => {
    EventSourceStub.instances = [];
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it("manages connection status and receives KPI messages", () => {
    const { result } = renderHook(() => useDashboardSSE());

    expect(result.current.connected).toBe(false);
    expect(result.current.data).toBeNull();

    const esInstance = EventSourceStub.instances[0];
    expect(esInstance).toBeDefined();

    // Trigger onopen
    act(() => {
      esInstance.open();
    });

    expect(result.current.connected).toBe(true);
    expect(result.current.error).toBeNull();

    // Trigger onmessage with valid KPI payload
    const mockPayload = {
      event: "kpi_update",
      data: {
        total_products: 5,
        total_jobs: 10,
      },
      system: {
        cpu_usage: 12,
      },
    };

    act(() => {
      esInstance.emitMessage(mockPayload);
    });

    expect(result.current.data).toEqual({
      user: {
        total_products: 5,
        total_jobs: 10,
      },
      system: {
        cpu_usage: 12,
      },
    });
  });

  it("handles malformed JSON message without crashing", () => {
    const { result } = renderHook(() => useDashboardSSE());
    const esInstance = EventSourceStub.instances[0];

    act(() => {
      esInstance.open();
    });

    act(() => {
      esInstance.onmessage?.(
        new MessageEvent("message", { data: "invalid-json" }),
      );
    });

    expect(result.current.data).toBeNull();
  });

  it("schedules exponential reconnects on onerror", () => {
    const { result } = renderHook(() => useDashboardSSE());
    const esInstance1 = EventSourceStub.instances[0];

    act(() => {
      esInstance1.open();
    });

    // Trigger error
    act(() => {
      esInstance1.error();
    });

    expect(result.current.connected).toBe(false);
    expect(result.current.error).toBe("连接断开，正在重连...");
    expect(esInstance1.close).toHaveBeenCalled();

    // Reconnect delay should be 1000ms (1s) first
    expect(EventSourceStub.instances.length).toBe(1); // No new instance yet

    act(() => {
      vi.advanceTimersByTime(1000);
    });

    expect(EventSourceStub.instances.length).toBe(2); // New instance created
    const esInstance2 = EventSourceStub.instances[1];

    // Trigger error on second instance
    act(() => {
      esInstance2.error();
    });

    // Next delay is 2000ms (2s)
    act(() => {
      vi.advanceTimersByTime(1000);
    });
    expect(EventSourceStub.instances.length).toBe(2); // Still 2

    act(() => {
      vi.advanceTimersByTime(1000);
    });
    expect(EventSourceStub.instances.length).toBe(3); // New instance created
  });

  it("closes EventSource and clears timers on unmount", () => {
    const { result, unmount } = renderHook(() => useDashboardSSE());
    const esInstance = EventSourceStub.instances[0];

    act(() => {
      esInstance.open();
    });

    // Trigger error to schedule a reconnect timer
    act(() => {
      esInstance.error();
    });

    unmount();

    // Verify timer was cleared (reconnect doesn't fire after time advances)
    act(() => {
      vi.advanceTimersByTime(5000);
    });
    expect(EventSourceStub.instances.length).toBe(1); // Still only the first one
  });
});
