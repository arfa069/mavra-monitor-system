# Frontend Unit and E2E Test Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a maintainable frontend test pyramid that covers shared infrastructure and every major feature, replaces stale localStorage-auth E2E tests, and makes any attempt to contact a real crawl or browser-profile endpoint fail immediately.

**Architecture:** Use Vitest, React Testing Library, and MSW for pure logic, hooks, providers, and component behavior. Use Playwright with a strict in-process API mock router for browser-level flows; every `/api/**` request must be explicitly mocked, so the default E2E suite never needs the backend, database, Redis, workers, browser profiles, or crawler runtime.

**Tech Stack:** React 18, TypeScript 6, Vite 8, Vitest, React Testing Library, MSW, Playwright, GitHub Actions.

---

## Non-Negotiable Safety Boundary

**No test in this plan may trigger a real crawl, real browser-profile session, real LLM analysis, or real Home Assistant control.**

The default unit and E2E commands must satisfy all of these constraints:

- Unit tests use MSW with `onUnhandledRequest: "error"`; no request may leave the test process.
- Playwright routes every `/api/**` request through a local mock router. An unregistered API request is a test failure and is never forwarded with `route.continue()`.
- The following requests are always blocked, even if a test author accidentally registers a generic handler:
  - `POST /api/v1/crawl/crawl-now`
  - `POST /api/v1/jobs/crawl-now`
  - `POST /api/v1/jobs/crawl-now/{config_id}`
  - `POST /api/v1/crawl-profiles/{profile_key}/login-session`
  - `POST /api/v1/crawl-profiles/{profile_key}/login-session/close`
  - `POST /api/v1/crawl-profiles/{profile_key}/test`
  - `POST /api/v1/jobs/match-results/analyze`
  - `POST /api/v1/jobs/match-results/analyze-async`
  - `POST /api/v1/smart-home/config/test`
  - `POST /api/v1/smart-home/entities/{entity_id}/service`
- E2E tests may verify that crawl/profile/control buttons are hidden or disabled. They must not click those buttons against a real backend.
- Tests that exercise UI behavior around dangerous actions must replace the API module with a spy or a fully local mock response.
- CI runs only the mock-backed Playwright project. There is no CI environment variable that enables real crawling.
- Do not start `app.workers.crawler`, Playwright profile login sessions, CloakBrowser, or any live product/job crawl while implementing or verifying this plan.

## Target Test Matrix

| Layer | Required coverage |
| --- | --- |
| Pure unit | cron validation, event deduplication, user-config merge, date/error formatting |
| Shared infrastructure | Axios CSRF/refresh behavior, AuthContext restore/login/logout/permissions, theme and motion persistence |
| Hooks | schedule load/save, dashboard/event/smart-home SSE parsing and cleanup, React Query mutation invalidation |
| Components | auth forms, settings, schedule permissions, product/job forms, profile management callbacks, admin permissions |
| E2E auth/navigation | unauthenticated redirect, login success/failure, Cookie-first state, permission redirects, main navigation |
| E2E features | settings persistence, schedule validation, event deduplication, products/jobs rendering, admin and smart-home read-only states |
| Safety | no unmocked API calls and zero dangerous endpoint requests |

## File Structure

### Test foundation

- Modify: `frontend/package.json`
- Modify: `frontend/package-lock.json`
- Create: `frontend/vitest.config.ts`
- Create: `frontend/tsconfig.test.json`
- Create: `frontend/tests/unit/setup.ts`
- Create: `frontend/tests/unit/test-utils.tsx`
- Create: `frontend/tests/unit/mocks/handlers.ts`
- Create: `frontend/tests/unit/mocks/server.ts`
- Modify: `frontend/tests/unit/review-regressions.test.ts`

### Unit and component coverage

- Create: `frontend/tests/unit/shared/api-client.test.ts`
- Create: `frontend/tests/unit/shared/auth-context.test.tsx`
- Create: `frontend/tests/unit/shared/theme-provider.test.tsx`
- Create: `frontend/tests/unit/auth/login-page.test.tsx`
- Create: `frontend/tests/unit/auth/register-page.test.tsx`
- Create: `frontend/tests/unit/events/events.test.tsx`
- Create: `frontend/tests/unit/schedule/job-config-schedule.test.tsx`
- Create: `frontend/tests/unit/settings/settings-page.test.tsx`
- Create: `frontend/tests/unit/products/product-form-modal.test.tsx`
- Create: `frontend/tests/unit/jobs/job-config-form.test.tsx`
- Create: `frontend/tests/unit/jobs/profile-management.test.tsx`
- Create: `frontend/tests/unit/admin/admin-users-page.test.tsx`
- Create: `frontend/tests/unit/dashboard/dashboard-sse.test.tsx`
- Create: `frontend/tests/unit/smart-home/smart-home-sse.test.tsx`

### E2E foundation and scenarios

- Modify: `frontend/playwright.config.ts`
- Create: `frontend/tests/e2e/fixtures/api-mock.ts`
- Create: `frontend/tests/e2e/fixtures/api-mock.spec.ts`
- Create: `frontend/tests/e2e/fixtures/app-test.ts`
- Create: `frontend/tests/e2e/fixtures/test-data.ts`
- Create: `frontend/tests/e2e/auth.spec.ts`
- Create: `frontend/tests/e2e/navigation.spec.ts`
- Create: `frontend/tests/e2e/settings-schedule.spec.ts`
- Create: `frontend/tests/e2e/products-jobs.spec.ts`
- Create: `frontend/tests/e2e/events-smart-home.spec.ts`
- Create: `frontend/tests/e2e/admin.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/basic.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/product-profile-schedule.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/test_admin_users.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/test_motion_settings.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/test_profile_settings.spec.ts`

### CI and documentation

- Modify: `.github/workflows/ci.yml`
- Create: `frontend/tests/README.md`

---

### Task 1: Install and Configure the Unit-Test Foundation

**Files:**
- Modify: `frontend/package.json`
- Modify: `frontend/package-lock.json`
- Create: `frontend/vitest.config.ts`
- Create: `frontend/tsconfig.test.json`
- Create: `frontend/tests/unit/setup.ts`
- Create: `frontend/tests/unit/test-utils.tsx`
- Create: `frontend/tests/unit/mocks/handlers.ts`
- Create: `frontend/tests/unit/mocks/server.ts`
- Modify: `frontend/tests/unit/review-regressions.test.ts`

- [ ] **Step 1: Replace the experimental Node test runner with Vitest scripts**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\frontend
npm install --save-dev vitest @vitest/coverage-v8 jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event msw
```

Update `frontend/package.json` scripts to:

```json
{
  "test": "vitest run",
  "test:unit": "vitest run",
  "test:unit:watch": "vitest",
  "test:coverage": "vitest run --coverage",
  "test:e2e": "playwright test",
  "test:e2e:headed": "playwright test --headed",
  "test:frontend": "npm run lint && npm run test:coverage && npm run build && npm run test:e2e"
}
```

- [ ] **Step 2: Add Vitest configuration with an enforceable baseline**

Create `frontend/vitest.config.ts`:

```ts
import { mergeConfig } from "vite";
import { defineConfig } from "vitest/config";
import viteConfig from "./vite.config";

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: "jsdom",
      setupFiles: ["./tests/unit/setup.ts"],
      clearMocks: true,
      restoreMocks: true,
      mockReset: true,
      coverage: {
        provider: "v8",
        reporter: ["text", "html", "lcov"],
        include: ["src/**/*.{ts,tsx}"],
        exclude: [
          "src/main.tsx",
          "src/**/index.ts",
          "src/**/*.d.ts",
          "src/**/types.ts",
        ],
        thresholds: {
          lines: 65,
          statements: 65,
          functions: 60,
          branches: 55
        }
      }
    }
  })
);
```

Do not lower these thresholds to make CI green. Add tests until the thresholds pass.

- [ ] **Step 3: Add editor/type-checking support for tests**

Create `frontend/tsconfig.test.json`:

```json
{
  "extends": "./tsconfig.app.json",
  "compilerOptions": {
    "types": ["vite/client", "vitest/globals", "@testing-library/jest-dom"]
  },
  "include": ["src", "tests", "vitest.config.ts", "playwright.config.ts"]
}
```

- [ ] **Step 4: Add DOM polyfills and a no-network MSW lifecycle**

Create `frontend/tests/unit/setup.ts`:

```ts
import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterAll, afterEach, beforeAll, vi } from "vitest";
import { server } from "./mocks/server";

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));

afterEach(() => {
  cleanup();
  server.resetHandlers();
  localStorage.clear();
  document.cookie = "pm_csrf_token=; Max-Age=0; Path=/";
  vi.useRealTimers();
});

afterAll(() => server.close());

Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn()
  }))
});

class ResizeObserverStub {
  observe() {}
  unobserve() {}
  disconnect() {}
}

vi.stubGlobal("ResizeObserver", ResizeObserverStub);
Element.prototype.scrollIntoView = vi.fn();
```

Create `frontend/tests/unit/mocks/handlers.ts`:

```ts
import { http, HttpResponse } from "msw";

export const testUser = {
  id: 1,
  username: "default",
  email: "default@example.com",
  role: "super_admin" as const,
  permissions: [
    "user:read",
    "user:manage",
    "crawl:execute",
    "schedule:read",
    "schedule:configure",
    "config:read",
    "config:write",
    "product:read",
    "product:write",
    "job:read",
    "job:write",
    "smart_home:read"
  ]
};

export const handlers = [
  http.get("/api/v1/auth/me", () => HttpResponse.json(testUser)),
  http.post("/api/v1/auth/logout", () =>
    HttpResponse.json({ message: "logged out" })
  )
];
```

Create `frontend/tests/unit/mocks/server.ts`:

```ts
import { setupServer } from "msw/node";
import { handlers } from "./handlers";

export const server = setupServer(...handlers);
```

- [ ] **Step 5: Add a standard provider-aware render helper**

Create `frontend/tests/unit/test-utils.tsx`:

```tsx
import type { PropsWithChildren, ReactElement } from "react";
import { App, ConfigProvider } from "antd";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { AuthProvider } from "@/shared/contexts/AuthContext";
import { ThemeProvider } from "@/shared/components/ThemeProvider";

export function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
      mutations: { retry: false }
    }
  });
}

export function renderWithApp(
  ui: ReactElement,
  options: { route?: string; withAuth?: boolean } = {}
) {
  const queryClient = createTestQueryClient();
  const Wrapper = ({ children }: PropsWithChildren) => {
    const content = options.withAuth === false ? children : (
      <AuthProvider>{children}</AuthProvider>
    );

    return (
      <MemoryRouter initialEntries={[options.route ?? "/"]}>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider>
            <ConfigProvider>
              <App>{content}</App>
            </ConfigProvider>
          </ThemeProvider>
        </QueryClientProvider>
      </MemoryRouter>
    );
  };

  return { queryClient, ...render(ui, { wrapper: Wrapper }) };
}
```

- [ ] **Step 6: Migrate the three existing regression tests to Vitest**

Replace Node imports in `frontend/tests/unit/review-regressions.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { mergeRealtimeEvent } from "../../src/features/events/realtimeState";
import { isValidCronExpression } from "../../src/features/schedule/utils/cron";
import { applyUserConfig } from "../../src/features/settings/userConfigState";

describe("review regressions", () => {
  it("increments total only for a new realtime event", () => {
    const first = { id: "first", kind: "system" } as never;
    const next = { id: "next", kind: "system" } as never;
    const added = mergeRealtimeEvent({ items: [first], total: 1 }, next, 20);

    expect(added.items).toEqual([next, first]);
    expect(added.total).toBe(2);
    expect(mergeRealtimeEvent(added, next, 20)).toBe(added);
  });

  it("preserves auth fields while applying saved settings", () => {
    const user = {
      id: 7,
      username: "default",
      email: "default@example.com",
      role: "admin" as const,
      permissions: ["config:read" as const],
      feishu_webhook_url: "old",
      data_retention_days: 365
    };

    expect(
      applyUserConfig(user, {
        id: 7,
        username: "default",
        feishu_webhook_url: "new",
        data_retention_days: 180,
        created_at: null,
        updated_at: null
      })
    ).toEqual({
      ...user,
      feishu_webhook_url: "new",
      data_retention_days: 180
    });
  });

  it("rejects malformed cron expressions", () => {
    expect(isValidCronExpression("0 9 * * *")).toBe(true);
    expect(isValidCronExpression("bad_cron")).toBe(false);
  });
});
```

- [ ] **Step 7: Run the migrated tests**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\frontend
npm run test:unit -- tests/unit/review-regressions.test.ts
```

Expected: 3 tests pass and no unhandled network request is reported.

- [ ] **Step 8: Commit the test foundation**

```powershell
git add frontend/package.json frontend/package-lock.json frontend/vitest.config.ts frontend/tsconfig.test.json frontend/tests/unit
git commit -m "test(frontend): establish vitest test foundation"
```

---

### Task 2: Cover Shared API, Authentication, and Theme Infrastructure

**Files:**
- Create: `frontend/tests/unit/shared/api-client.test.ts`
- Create: `frontend/tests/unit/shared/auth-context.test.tsx`
- Create: `frontend/tests/unit/shared/theme-provider.test.tsx`
- Create: `frontend/tests/unit/auth/login-page.test.tsx`
- Create: `frontend/tests/unit/auth/register-page.test.tsx`

- [ ] **Step 1: Write API-client tests for error formatting and CSRF**

Create `frontend/tests/unit/shared/api-client.test.ts` with these exact cases:

```ts
import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";
import api, { formatApiError } from "@/shared/api/client";
import { server } from "../mocks/server";

describe("shared API client", () => {
  it("formats string and validation-list errors", () => {
    expect(
      formatApiError({ response: { data: { detail: "denied" } } }, "fallback")
    ).toBe("denied");
    expect(
      formatApiError(
        { response: { data: { detail: [{ msg: "first" }, "second"] } } },
        "fallback"
      )
    ).toBe("first; second");
  });

  it("adds the CSRF cookie to unsafe requests", async () => {
    document.cookie = "pm_csrf_token=csrf-test; Path=/";
    server.use(
      http.patch("/api/v1/config", async ({ request }) => {
        expect(request.headers.get("X-CSRF-Token")).toBe("csrf-test");
        return HttpResponse.json({ ok: true });
      })
    );

    await api.patch("/v1/config", { data_retention_days: 30 });
  });
});
```

Add a separate test using two concurrent protected requests: both return `401`, `/api/v1/auth/refresh` is called once, then both original requests succeed. This proves refresh queuing does not duplicate refresh calls.

- [ ] **Step 2: Write AuthContext state and permission tests**

Create `frontend/tests/unit/shared/auth-context.test.tsx`. Use a small probe component exposing `username`, `isAuthenticated`, `isAdmin`, and permission results. Cover:

- `/auth/me` success restores the user.
- `/auth/me` `401` produces an unauthenticated state.
- `login(user)` replaces the in-memory user.
- `logout()` calls the API and clears the user even when the logout request fails.
- `hasPermission`, `hasAnyPermission`, and `hasAllPermissions` use the permission array, not only the role.

Core assertion:

```tsx
expect(await screen.findByText("default:true:true")).toBeVisible();
expect(screen.getByText("schedule:true")).toBeVisible();
```

- [ ] **Step 3: Write theme and motion persistence tests**

Create `frontend/tests/unit/shared/theme-provider.test.tsx` and verify:

```tsx
expect(localStorage.getItem("mavra-monitor-system-motion-speed")).toBe("slow");
```

Also verify invalid stored motion values fall back to `"normal"` and `matchMedia("(prefers-color-scheme: dark)")` selects the dark theme only when no explicit theme is stored.

- [ ] **Step 4: Write LoginPage behavior tests**

Create `frontend/tests/unit/auth/login-page.test.tsx`. Cover:

- Empty submission displays required validation.
- Successful login sends `{ username, password }`, updates AuthContext, and returns to `location.state.from`.
- Failed login shows `"Invalid username or password"` and clears only the password field.
- The submit button is disabled/loading while the request is pending.
- No `auth_token` or `auth_user` key is written to localStorage.

Use MSW:

```ts
server.use(
  http.post("/api/v1/auth/login", async ({ request }) => {
    expect(await request.json()).toEqual({
      username: "default",
      password: "123456"
    });
    return HttpResponse.json(testUser);
  })
);
```

- [ ] **Step 5: Write RegisterPage validation and payload tests**

Create `frontend/tests/unit/auth/register-page.test.tsx`. Cover required fields, password confirmation mismatch, successful payload, API error display, and navigation to `/login`.

- [ ] **Step 6: Run the shared/auth tests**

```powershell
npm run test:unit -- tests/unit/shared tests/unit/auth
```

Expected: all shared/auth tests pass; MSW reports zero unhandled requests.

- [ ] **Step 7: Commit shared infrastructure coverage**

```powershell
git add frontend/tests/unit/shared frontend/tests/unit/auth
git commit -m "test(frontend): cover auth and shared infrastructure"
```

---

### Task 3: Cover Events, Schedule, and Settings Regressions

**Files:**
- Create: `frontend/tests/unit/events/events.test.tsx`
- Create: `frontend/tests/unit/schedule/job-config-schedule.test.tsx`
- Create: `frontend/tests/unit/settings/settings-page.test.tsx`

- [ ] **Step 1: Add a reusable EventSource stub inside the event test**

The stub must expose `emit`, `fail`, and `close` without opening a network connection:

```ts
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
}
```

- [ ] **Step 2: Cover event URL construction and realtime deduplication**

In `frontend/tests/unit/events/events.test.tsx`, verify:

- `buildStreamUrl` omits empty query values and preserves filters.
- Initial list response renders its total.
- A new SSE item is prepended and increments total once.
- Repeating the same SSE item does not increment total.
- Malformed SSE JSON shows the warning path.
- Unmount closes EventSource.

- [ ] **Step 3: Cover job schedule hook behavior**

Create `frontend/tests/unit/schedule/job-config-schedule.test.tsx` with `renderHook`. Mock `jobsApi` and cover:

```ts
expect(jobsApi.updateConfigCron).not.toHaveBeenCalled();
expect(message.error).toHaveBeenCalledWith("Invalid cron expression");
```

Also cover:

- `load()` merges config rows and scheduler status by `config_id`.
- Successful save sends timezone `"Asia/Shanghai"` and reloads.
- Failed save displays `"Save failed"` and clears the per-row saving flag.
- Blank cron is accepted as `null`, disabling the schedule.

- [ ] **Step 4: Cover SettingsPage state synchronization**

Create `frontend/tests/unit/settings/settings-page.test.tsx`. Verify:

- Initial form values come from AuthContext.
- Successful PATCH updates the rendered AuthContext user without reloading.
- Saved `email`, `role`, and `permissions` are preserved.
- API validation errors pass through `formatApiError`.
- Changing motion speed writes the expected localStorage key.

- [ ] **Step 5: Run the regression-domain tests**

```powershell
npm run test:unit -- tests/unit/events tests/unit/schedule tests/unit/settings
```

Expected: all tests pass, EventSource is closed on cleanup, and no real endpoint is contacted.

- [ ] **Step 6: Commit the regression coverage**

```powershell
git add frontend/tests/unit/events frontend/tests/unit/schedule frontend/tests/unit/settings
git commit -m "test(frontend): cover events schedules and settings"
```

---

### Task 4: Cover Product, Job, Admin, Dashboard, and Smart-Home Components

**Files:**
- Create: `frontend/tests/unit/products/product-form-modal.test.tsx`
- Create: `frontend/tests/unit/jobs/job-config-form.test.tsx`
- Create: `frontend/tests/unit/jobs/profile-management.test.tsx`
- Create: `frontend/tests/unit/admin/admin-users-page.test.tsx`
- Create: `frontend/tests/unit/dashboard/dashboard-sse.test.tsx`
- Create: `frontend/tests/unit/smart-home/smart-home-sse.test.tsx`

- [ ] **Step 1: Cover ProductFormModal without triggering crawl**

Test URL-to-platform detection for JD, Taobao, and Amazon; required URL/platform validation; edit-mode initial values; alert enable/disable payloads; and cancel behavior.

The test must pass callback spies only:

```tsx
const onSubmit = vi.fn();
renderWithApp(
  <ProductFormModal
    open
    onCancel={vi.fn()}
    onSubmit={onSubmit}
    confirmLoading={false}
  />
);
```

Do not render or click `ProductsPage` crawl controls in this unit test.

- [ ] **Step 2: Cover JobConfigForm and profile selection**

Test:

- Required config name and valid platform.
- `profile_key` is included in submitted values.
- Existing config values populate edit mode.
- Cron and timezone values are preserved.
- `onCreateProfile` is a spy and never calls `/crawl-profiles`.

- [ ] **Step 3: Cover ProfileManagement as a callback-only component**

Test visible status, create/rename validation, disabled actions for leased profiles, and confirmation dialogs. Every operation prop must be a `vi.fn()`; no test imports `jobsApi.testProfile` or `openProfileLoginSession`.

Add this explicit negative assertion with an explicit spy:

```ts
const fetchSpy = vi.spyOn(globalThis, "fetch");
expect(globalThis.fetch).not.toHaveBeenCalled();
fetchSpy.mockRestore();
```

If Axios rather than `fetch` is globally instrumented, assert the API spy module received zero calls.

- [ ] **Step 4: Cover admin permission gates**

Mock admin API responses and verify:

- Read-only users see the table but not create/delete controls.
- `user:manage` enables create/edit controls.
- Super-admin core permissions cannot be unchecked.
- Validation errors do not produce an API mutation.

- [ ] **Step 5: Cover dashboard SSE lifecycle**

Use fake timers and EventSourceStub to verify message parsing, malformed payload handling, exponential reconnect scheduling, and timer/EventSource cleanup on unmount.

- [ ] **Step 6: Cover smart-home SSE without controlling devices**

Test entity update merging, reconnect delay, malformed messages, and cleanup in `useSmartHomeSSE`. Do not call `smartHomeApi.testConfig` or `smartHomeApi.callService`.

- [ ] **Step 7: Run the feature component tests**

```powershell
npm run test:unit -- tests/unit/products tests/unit/jobs tests/unit/admin tests/unit/dashboard tests/unit/smart-home
```

Expected: all tests pass with zero MSW unhandled requests and zero dangerous operation calls.

- [ ] **Step 8: Run and satisfy coverage**

```powershell
npm run test:coverage
```

Expected: lines/statements at least 65%, functions at least 60%, and branches at least 55%. Add focused tests rather than exclusions if a threshold is missed.

- [ ] **Step 9: Commit feature coverage**

```powershell
git add frontend/tests/unit
git commit -m "test(frontend): cover feature components and realtime hooks"
```

---

### Task 5: Build a Mock-Only Playwright API Firewall

**Files:**
- Modify: `frontend/playwright.config.ts`
- Create: `frontend/tests/e2e/fixtures/api-mock.ts`
- Create: `frontend/tests/e2e/fixtures/app-test.ts`
- Create: `frontend/tests/e2e/fixtures/test-data.ts`

- [ ] **Step 1: Make Playwright start only the frontend**

Update `frontend/playwright.config.ts`:

```ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/e2e",
  fullyParallel: true,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL: "http://127.0.0.1:3000",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure"
  },
  webServer: {
    command: "npm run dev -- --host 127.0.0.1",
    url: "http://127.0.0.1:3000",
    reuseExistingServer: !process.env.CI,
    timeout: 120_000
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] }
    }
  ]
});
```

There is intentionally no backend `webServer` entry.

- [ ] **Step 2: Implement an API mock router that never forwards requests**

Create `frontend/tests/e2e/fixtures/api-mock.ts`:

```ts
import { expect, type Page, type Request, type Route } from "@playwright/test";

type Json = Record<string, unknown> | unknown[];
type MockResult = { status?: number; body?: Json; headers?: Record<string, string> };
type Handler = (request: Request) => MockResult | Promise<MockResult>;

const BLOCKED = [
  /^POST \/api\/v1\/crawl\/crawl-now$/,
  /^POST \/api\/v1\/jobs\/crawl-now(?:\/\d+)?$/,
  /^POST \/api\/v1\/crawl-profiles\/[^/]+\/login-session(?:\/close)?$/,
  /^POST \/api\/v1\/crawl-profiles\/[^/]+\/test$/,
  /^POST \/api\/v1\/jobs\/match-results\/(?:analyze|analyze-async)$/,
  /^POST \/api\/v1\/smart-home\/config\/test$/,
  /^POST \/api\/v1\/smart-home\/entities\/[^/]+\/service$/
];

export class ApiMock {
  private handlers = new Map<string, Handler>();
  private violations: string[] = [];

  use(method: string, path: string, handler: Handler) {
    this.handlers.set(`${method.toUpperCase()} ${path}`, handler);
  }

  async install(page: Page) {
    await page.route("**/api/**", async (route: Route) => {
      const request = route.request();
      const path = new URL(request.url()).pathname;
      const key = `${request.method()} ${path}`;

      if (BLOCKED.some((pattern) => pattern.test(key))) {
        this.violations.push(`BLOCKED ${key}`);
        await route.abort("blockedbyclient");
        return;
      }

      const handler = this.handlers.get(key);
      if (!handler) {
        this.violations.push(`UNMOCKED ${key}`);
        await route.fulfill({
          status: 501,
          contentType: "application/json",
          body: JSON.stringify({ detail: `No E2E mock registered for ${key}` })
        });
        return;
      }

      const result = await handler(request);
      await route.fulfill({
        status: result.status ?? 200,
        contentType: "application/json",
        headers: result.headers,
        body: JSON.stringify(result.body ?? {})
      });
    });
  }

  assertSafe() {
    expect(this.violations).toEqual([]);
  }
}
```

**Do not add `route.continue()` or `route.fallback()` to this class.** Those calls would allow a test to reach the real backend.

- [ ] **Step 3: Add shared test data**

Create `frontend/tests/e2e/fixtures/test-data.ts` with complete fixture objects for:

- super-admin user with all UI permissions;
- read-only user without `crawl:execute`, `schedule:configure`, `user:manage`, or `smart_home:control`;
- product list, job config/list, event list, scheduler status, smart-home config/entities, and admin users.

Use obviously synthetic URLs such as `https://example.invalid/product/1`; never use real marketplace/job URLs.

- [ ] **Step 4: Add a Playwright fixture that installs mocks before each test**

Create `frontend/tests/e2e/fixtures/app-test.ts`:

```ts
import { test as base, expect } from "@playwright/test";
import { ApiMock } from "./api-mock";
import { adminUser } from "./test-data";

type Fixtures = { api: ApiMock };

export const test = base.extend<Fixtures>({
  api: async ({ page }, use) => {
    const api = new ApiMock();
    api.use("GET", "/api/v1/auth/me", () => ({ body: adminUser }));
    api.use("POST", "/api/v1/auth/logout", () => ({
      body: { message: "logged out" }
    }));
    await api.install(page);
    await use(api);
    api.assertSafe();
  }
});

export { expect };
```

- [ ] **Step 5: Prove the firewall blocks dangerous and unmocked requests**

Add focused Playwright tests in `frontend/tests/e2e/fixtures/api-mock.spec.ts` using `test` from `@playwright/test`, not the guarded `fixtures/app-test` wrapper:

- An unregistered `/api/v1/unknown` request records `UNMOCKED`.
- `POST /api/v1/crawl/crawl-now` records `BLOCKED`.
- A registered safe GET is fulfilled locally.
- No test can access `http://127.0.0.1:8000`.

These tests should inspect `ApiMock` through a test-only `getViolations()` method, then use a fresh instance for normal fixture tests.

- [ ] **Step 6: Run the firewall test with the backend stopped**

```powershell
npm run test:e2e -- tests/e2e/fixtures/api-mock.spec.ts
```

Expected: pass while port `8000` is not running. This is evidence that E2E does not depend on or reach the backend.

- [ ] **Step 7: Commit the E2E foundation**

```powershell
git add frontend/playwright.config.ts frontend/tests/e2e/fixtures
git commit -m "test(frontend): add mock-only playwright firewall"
```

---

### Task 6: Replace Stale Authentication and Navigation E2E Tests

**Files:**
- Create: `frontend/tests/e2e/auth.spec.ts`
- Create: `frontend/tests/e2e/navigation.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/basic.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/test_profile_settings.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/test_motion_settings.spec.ts`

- [ ] **Step 1: Add unauthenticated and login E2E scenarios**

Create `frontend/tests/e2e/auth.spec.ts` using `test` from `fixtures/app-test`.

Required scenarios:

- Override `GET /api/v1/auth/me` with `401`, navigate to `/settings`, and expect redirect to `/login`.
- Submit empty login form and verify validation text.
- Mock successful login and verify redirect to the original protected path.
- Mock failed login and verify the error state.
- Assert `localStorage.getItem("auth_token")` and `localStorage.getItem("auth_user")` are both `null`.

Success handler:

```ts
api.use("POST", "/api/v1/auth/login", async (request) => {
  expect(await request.postDataJSON()).toEqual({
    username: "default",
    password: "123456"
  });
  return { body: adminUser };
});
```

- [ ] **Step 2: Add protected navigation and permission E2E scenarios**

Create `frontend/tests/e2e/navigation.spec.ts`. Register the minimum safe GET handlers required by the destination pages, then verify:

- `/` redirects to `/dashboard`.
- Main navigation reaches `/events`, `/jobs`, `/products`, `/schedule`, `/settings`, and `/profile`.
- A user without `user:read` is redirected from `/admin/users` to `/dashboard`.
- Page-transition wrappers remain present during navigation.
- No crawl button is clicked.

- [ ] **Step 3: Replace motion-setting coverage**

Move the old motion persistence scenario into `navigation.spec.ts` or `settings-schedule.spec.ts`, using the mock AuthContext path rather than localStorage auth tokens. Keep only the motion preference in localStorage.

- [ ] **Step 4: Run replacement tests before deleting old tests**

```powershell
npm run test:e2e -- tests/e2e/auth.spec.ts tests/e2e/navigation.spec.ts
```

Expected: pass with the backend and worker stopped.

- [ ] **Step 5: Delete stale auth-model tests**

Delete the three replaced files only after the replacement command passes:

```powershell
Remove-Item -LiteralPath tests/e2e/basic.spec.ts,tests/e2e/test_profile_settings.spec.ts,tests/e2e/test_motion_settings.spec.ts
```

- [ ] **Step 6: Commit auth/navigation E2E coverage**

```powershell
git add frontend/tests/e2e
git commit -m "test(frontend): replace stale auth and navigation e2e tests"
```

---

### Task 7: Add Safe Feature E2E Scenarios

**Files:**
- Create: `frontend/tests/e2e/settings-schedule.spec.ts`
- Create: `frontend/tests/e2e/products-jobs.spec.ts`
- Create: `frontend/tests/e2e/events-smart-home.spec.ts`
- Create: `frontend/tests/e2e/admin.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/product-profile-schedule.spec.ts`
- Delete after replacements pass: `frontend/tests/e2e/test_admin_users.spec.ts`

- [ ] **Step 1: Add settings and schedule browser flows**

In `settings-schedule.spec.ts`, cover:

- Settings form renders user values.
- Saving settings sends the PATCH payload and keeps the user authenticated.
- Motion speed survives reload.
- Invalid job cron shows an error and sends no PATCH.
- Valid job cron sends a mocked PATCH.
- Read-only user sees disabled schedule controls.

The API firewall remains active. A valid cron PATCH is safe because it is fulfilled by `ApiMock`, never forwarded.

- [ ] **Step 2: Add products and jobs read-only browser flows**

In `products-jobs.spec.ts`, cover:

- Product rows render from synthetic fixture data.
- Keyword and platform filters change the mocked GET query.
- Add/edit product modal validation works; mutations are locally mocked.
- Job configs and job rows render.
- Job detail drawer opens.
- Profile table renders status.
- Use the read-only user so crawl/profile-login/profile-test controls are absent or disabled.

Add explicit assertions:

```ts
await expect(page.getByRole("button", { name: /crawl now/i })).toHaveCount(0);
await expect(page.getByRole("button", { name: /test profile/i })).toHaveCount(0);
```

Do not click either control.

- [ ] **Step 3: Add event and smart-home read-only flows**

In `events-smart-home.spec.ts`, cover:

- Event list filtering and detail drawer rendering.
- Realtime event deduplication by installing a browser-side EventSource stub before navigation.
- Smart-home config and entity cards render from fixture data.
- Use a user without `smart_home:control`; service buttons are disabled.
- Do not call config test or entity service endpoints.

- [ ] **Step 4: Add admin browser flows**

In `admin.spec.ts`, cover user table rendering, create-modal validation, permission-tab rendering, and read-only permission behavior. Mock all admin mutations locally.

- [ ] **Step 5: Run all new feature specs with backend and worker stopped**

```powershell
npm run test:e2e -- tests/e2e/settings-schedule.spec.ts tests/e2e/products-jobs.spec.ts tests/e2e/events-smart-home.spec.ts tests/e2e/admin.spec.ts
```

Expected:

- all tests pass;
- API firewall reports zero `BLOCKED` and zero `UNMOCKED` requests;
- no process is started for backend, worker, browser profile, CloakBrowser, or crawler.

- [ ] **Step 6: Delete replaced E2E files**

```powershell
Remove-Item -LiteralPath tests/e2e/product-profile-schedule.spec.ts,tests/e2e/test_admin_users.spec.ts
```

- [ ] **Step 7: Commit feature E2E coverage**

```powershell
git add frontend/tests/e2e
git commit -m "test(frontend): add safe feature e2e coverage"
```

---

### Task 8: Add CI Gates and Test Documentation

**Files:**
- Modify: `.github/workflows/ci.yml`
- Create: `frontend/tests/README.md`

- [ ] **Step 1: Add a frontend quality job**

Append a `frontend-quality` job to `.github/workflows/ci.yml`:

```yaml
  frontend-quality:
    name: Frontend lint, unit tests, and build
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: npm
          cache-dependency-path: frontend/package-lock.json
      - run: npm ci
      - run: npm run lint
      - run: npm run test:coverage
      - run: npm run build
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: frontend-coverage
          path: frontend/coverage
          if-no-files-found: ignore
```

- [ ] **Step 2: Add a mock-only Playwright CI job**

Append:

```yaml
  frontend-e2e:
    name: Frontend mock-only E2E
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: npm
          cache-dependency-path: frontend/package-lock.json
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run test:e2e
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: frontend/playwright-report
          if-no-files-found: ignore
```

Do not add PostgreSQL, Redis, backend startup, worker startup, crawler credentials, marketplace cookies, or browser-profile secrets to this job.

- [ ] **Step 3: Document commands and safety rules**

Create `frontend/tests/README.md` containing:

```markdown
# Frontend Tests

## Commands

- `npm run test:unit` - run Vitest once
- `npm run test:unit:watch` - run Vitest in watch mode
- `npm run test:coverage` - enforce coverage thresholds
- `npm run test:e2e` - run mock-only Playwright tests
- `npm run test:frontend` - run the complete frontend quality gate

## Safety

The default E2E suite starts only Vite. It must run successfully while backend
port 8000 and all crawler workers are stopped.

Every `/api/**` request must be explicitly mocked. Unmocked requests fail.
Real crawl, job-crawl, profile-login, profile-test, LLM-analysis, Home Assistant
test, and Home Assistant service endpoints are blocked by the Playwright API
firewall. Never add `route.continue()` or `route.fallback()` to the API mock.

Use only `example.invalid` URLs and synthetic fixture data. Do not use real
marketplace products, job listings, cookies, profile directories, tokens, or
webhooks in tests.
```

- [ ] **Step 4: Run the complete local frontend gate**

Ensure backend port `8000` and crawler workers are stopped, then run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\frontend
npm run test:frontend
```

Expected:

- ESLint exits `0`.
- Vitest coverage exits `0` and meets thresholds.
- Vite production build exits `0`.
- Playwright exits `0`.
- API firewall reports no unmocked or blocked requests.
- No real crawl, browser-profile session, worker, or Home Assistant action occurs.

- [ ] **Step 5: Run GitNexus change detection**

```text
gitnexus_detect_changes(scope="unstaged", repo="mavra-monitor-system")
```

Confirm affected scope is limited to frontend test infrastructure, test files, CI, and documentation. Investigate any unexpected production symbol changes.

- [ ] **Step 6: Run final diff checks**

```powershell
git diff --check
git status --short
```

Expected: no whitespace errors; only planned files are modified.

- [ ] **Step 7: Commit CI and documentation**

```powershell
git add .github/workflows/ci.yml frontend/tests/README.md
git commit -m "ci: enforce frontend unit and e2e tests"
```

---

## Completion Criteria

The initiative is complete only when all conditions are true:

- `npm run test:frontend` passes with backend port `8000` and all crawler workers stopped.
- Existing Node-only regression tests have been migrated to Vitest.
- Coverage thresholds are enforced and not bypassed with broad exclusions.
- Each major frontend feature has at least one unit/component test and one browser-level smoke scenario where appropriate.
- Authentication tests use Cookie-first semantics and assert no auth token is stored in localStorage.
- All obsolete Playwright files using localStorage auth or hard-coded mixed ports are removed.
- Playwright has no `route.continue()` or `route.fallback()` path for `/api/**`.
- Zero tests contact a real crawl, profile session/test, LLM analysis, or Home Assistant control endpoint.
- CI requires frontend lint, unit coverage, build, and mock-only E2E.
