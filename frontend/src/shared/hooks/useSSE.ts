import { useEffect, useRef } from "react";

export interface UseSSEOptions {
  /** Called when the connection opens. */
  onOpen?: () => void;
  /** Called for each message event. */
  onMessage: (event: MessageEvent) => void;
  /** Called when an error occurs. Receives the current retry index (0-based). */
  onError?: (retryIndex: number) => void;
  /**
   * Exponential backoff delays (ms) for reconnects.
   * Defaults to [1000, 2000, 4000, 8000, 15000, 30000].
   */
  reconnectDelays?: number[];
  /** Maximum number of reconnect attempts. Defaults to unlimited. */
  maxRetries?: number;
  /** Pass `false` to disable the SSE connection entirely. Defaults to true. */
  enabled?: boolean;
}

const DEFAULT_DELAYS = [1000, 2000, 4000, 8000, 15000, 30000];

/**
 * Shared low-level EventSource hook.
 *
 * Handles open/message/error lifecycle, exponential-backoff reconnection, and
 * cleanup.  Individual feature hooks own message parsing and state management.
 */
export function useSSE(url: string, options: UseSSEOptions): void {
  const {
    onOpen,
    onMessage,
    onError,
    reconnectDelays = DEFAULT_DELAYS,
    maxRetries = Infinity,
    enabled = true,
  } = options;

  // Keep callback refs in sync so inner `connect()` always sees the latest
  // without triggering a re-subscription on every render.
  const onOpenRef = useRef(onOpen);
  const onMessageRef = useRef(onMessage);
  const onErrorRef = useRef(onError);

  useEffect(() => {
    onOpenRef.current = onOpen;
    onMessageRef.current = onMessage;
    onErrorRef.current = onError;
  });

  useEffect(() => {
    if (!enabled) return;

    const sourceRef = { current: null as EventSource | null };
    const retryRef = { current: 0 };
    const timerRef = { current: null as ReturnType<typeof setTimeout> | null };

    function connect() {
      sourceRef.current?.close();
      const es = new EventSource(url, { withCredentials: true });
      sourceRef.current = es;

      es.onopen = () => {
        retryRef.current = 0;
        onOpenRef.current?.();
      };

      es.onmessage = (event) => {
        onMessageRef.current(event);
      };

      es.onerror = () => {
        es.close();
        if (sourceRef.current === es) sourceRef.current = null;

        const attempt = retryRef.current;
        onErrorRef.current?.(attempt);

        if (attempt < maxRetries) {
          retryRef.current += 1;
          const delay =
            reconnectDelays[Math.min(attempt, reconnectDelays.length - 1)];
          timerRef.current = setTimeout(connect, delay);
        }
      };
    }

    connect();

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
      sourceRef.current?.close();
      sourceRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [url, enabled]);
}
