import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterAll, afterEach, beforeAll, vi } from "vitest";
import { server } from "./mocks/server";

import { MotionGlobalConfig } from "framer-motion";

MotionGlobalConfig.skipAnimations = true;

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));

afterEach(() => {
  cleanup();
  server.resetHandlers();
  localStorage.clear();
  document.cookie = "pm_csrf_token=; Max-Age=0; Path=/";
  vi.useRealTimers();
});

afterAll(() => server.close());

window.matchMedia = (query: string) => ({
  matches: false,
  media: query,
  onchange: null,
  addListener: () => {},
  removeListener: () => {},
  addEventListener: () => {},
  removeEventListener: () => {},
  dispatchEvent: () => false
});

class ResizeObserverStub {
  observe() {}
  unobserve() {}
  disconnect() {}
}

global.ResizeObserver = ResizeObserverStub;
(window as any).ResizeObserver = ResizeObserverStub;
Element.prototype.scrollIntoView = () => {};

process.on("unhandledRejection", (reason: any) => {
  if (reason && (reason.errorFields || reason.values)) {
    return;
  }
  console.error("Unhandled Rejection:", reason);
});
