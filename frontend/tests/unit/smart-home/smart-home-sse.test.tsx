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
import { useSmartHomeSSE } from "@/features/smart-home/hooks/useSmartHomeSSE";
import { smartHomeApi } from "@/features/smart-home/api/smartHome";

class EventSourceStub {
  static instances: EventSourceStub[] = [];
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

  error() {
    this.onerror?.();
  }
}

const originalEventSource = global.EventSource;

describe("useSmartHomeSSE Hook", () => {
  const onEntity = vi.fn();
  const onError = vi.fn();

  beforeAll(() => {
    global.EventSource = EventSourceStub as any;
  });

  afterAll(() => {
    global.EventSource = originalEventSource;
  });

  beforeEach(() => {
    EventSourceStub.instances = [];
    vi.useFakeTimers();
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it("does not connect if enabled is false", () => {
    renderHook(() => useSmartHomeSSE(false, onEntity, onError));
    expect(EventSourceStub.instances.length).toBe(0);
  });

  it("connects when enabled is true, and passes parsed entities to onEntity", () => {
    renderHook(() => useSmartHomeSSE(true, onEntity, onError));
    expect(EventSourceStub.instances.length).toBe(1);

    const esInstance = EventSourceStub.instances[0];

    const mockEntity = {
      entity_id: "light.living_room",
      state: "on",
      attributes: { friendly_name: "Living Room Light" },
    };

    act(() => {
      esInstance.emitMessage(mockEntity);
    });

    expect(onEntity).toHaveBeenCalledWith(mockEntity);
    expect(onError).not.toHaveBeenCalled();
  });

  it("triggers onError when JSON parsing fails", () => {
    renderHook(() => useSmartHomeSSE(true, onEntity, onError));
    const esInstance = EventSourceStub.instances[0];

    act(() => {
      esInstance.onmessage?.(
        new MessageEvent("message", { data: "invalid-json" }),
      );
    });

    expect(onEntity).not.toHaveBeenCalled();
    expect(onError).toHaveBeenCalled();
  });

  it("reconnects with exponential delays and halts after 5 retries", () => {
    renderHook(() => useSmartHomeSSE(true, onEntity, onError));
    expect(EventSourceStub.instances.length).toBe(1);

    const esInstance1 = EventSourceStub.instances[0];

    // Retry 1: error on instance 1, delay = 2000ms
    act(() => {
      esInstance1.error();
    });

    expect(esInstance1.close).toHaveBeenCalled();
    expect(EventSourceStub.instances.length).toBe(1); // No new instance yet

    act(() => {
      vi.advanceTimersByTime(2000);
    });
    expect(EventSourceStub.instances.length).toBe(2);

    // Retry 2: error on instance 2, delay = 4000ms
    const esInstance2 = EventSourceStub.instances[1];
    act(() => {
      esInstance2.error();
    });

    act(() => {
      vi.advanceTimersByTime(4000);
    });
    expect(EventSourceStub.instances.length).toBe(3);

    // Retry 3: delay = 8000ms
    const esInstance3 = EventSourceStub.instances[2];
    act(() => {
      esInstance3.error();
    });
    act(() => {
      vi.advanceTimersByTime(8000);
    });
    expect(EventSourceStub.instances.length).toBe(4);

    // Retry 4: delay = 16000ms
    const esInstance4 = EventSourceStub.instances[3];
    act(() => {
      esInstance4.error();
    });
    act(() => {
      vi.advanceTimersByTime(16000);
    });
    expect(EventSourceStub.instances.length).toBe(5);

    // Retry 5: delay = 32000ms
    const esInstance5 = EventSourceStub.instances[4];
    act(() => {
      esInstance5.error();
    });
    act(() => {
      vi.advanceTimersByTime(32000);
    });
    expect(EventSourceStub.instances.length).toBe(6);

    // Retry 6: Should not reconnect (exceeds maxRetry = 5), instead calls onError
    const esInstance6 = EventSourceStub.instances[5];
    expect(onError).not.toHaveBeenCalled(); // No terminal error yet

    act(() => {
      esInstance6.error();
    });

    expect(onError).toHaveBeenCalled(); // Terminal error triggered
    expect(EventSourceStub.instances.length).toBe(6); // Reconnections stopped
  });

  it("closes EventSource and clears timers on unmount", () => {
    const { unmount } = renderHook(() =>
      useSmartHomeSSE(true, onEntity, onError),
    );
    const esInstance = EventSourceStub.instances[0];

    act(() => {
      esInstance.error();
    });

    unmount();

    act(() => {
      vi.advanceTimersByTime(10000);
    });
    expect(EventSourceStub.instances.length).toBe(1); // Stopped reconnecting
  });
});
