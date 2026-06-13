import { test as base, expect } from "@playwright/test";
import { ApiMock } from "./api-mock";
import { adminUser } from "./test-data";

type Fixtures = { api: ApiMock };

export const test = base.extend<Fixtures>({
  api: async ({ page }, use) => {
    page.on("console", (msg) => {
      if (msg.type() === "error") {
        console.error("Browser Console Error:", msg.text());
      }
    });
    page.on("pageerror", (err) => {
      console.error("Browser Page Error:", err.message);
    });

    // Inject global EventSource stub to prevent unmocked / pending EventSource streams from hanging E2E navigation
    await page.addInitScript(() => {
      const FakeEventSource = function (url: string) {
        this.url = url;
        this.readyState = 1; // OPEN
        this.onopen = null;
        this.onmessage = null;
        this.onerror = null;
        const listeners: Record<string, any[]> = {};
        this.addEventListener = function (type: string, fn: any) {
          listeners[type] = listeners[type] || [];
          listeners[type].push(fn);
        };
        this.removeEventListener = function (type: string, fn: any) {
          if (!listeners[type]) return;
          listeners[type] = listeners[type].filter((f) => f !== fn);
        };
        this.dispatchEvent = function (event: any) {
          const type = event.type;
          if (listeners[type]) {
            listeners[type].forEach((fn) => fn(event));
          }
          if (type === "message" && this.onmessage) {
            this.onmessage(event);
          }
          return true;
        };
        this.close = function () {};
        (window as any).lastEventSource = this;
      };
      (FakeEventSource as any).CONNECTING = 0;
      (FakeEventSource as any).OPEN = 1;
      (FakeEventSource as any).CLOSED = 2;
      (window as any).EventSource = FakeEventSource as any;
    });

    const api = new ApiMock();

    // Auth
    api.use("GET", "/api/v1/auth/me", () => ({ body: adminUser }));
    api.use("POST", "/api/v1/auth/logout", () => ({
      body: { message: "logged out" },
    }));
    api.use("POST", "/api/v1/auth/refresh", () => ({
      status: 401,
      body: { detail: "Refresh token expired" },
    }));
    api.use("GET", "/api/v1/auth/wechat/qr", () => ({
      body: {
        qr_url: "https://open.weixin.qq.com/connect/qrconnect?state=test-state",
        state: "test-state",
      },
    }));
    api.use("POST", "/api/v1/auth/wechat/bind", () => ({
      body: adminUser,
    }));
    api.use("POST", "/api/v1/auth/wechat/register", () => ({
      body: adminUser,
    }));

    // Dashboard
    api.use("GET", "/api/v1/dashboard/kpi", () => ({
      body: {
        user: {
          total_products: 5,
          price_drops_today: 1,
          new_jobs_today: 2,
          match_count: 1,
          crawl_count_today: 10,
        },
        system: {
          total_users: 2,
          total_crawls: 50,
          success_rate: 99.0,
          active_alerts: 1,
          disk_usage: 30.0,
          memory_usage: 45.0,
        },
      },
    }));
    api.use("GET", "/api/v1/dashboard/trends", () => ({
      body: {
        labels: ["Mon", "Tue", "Wed"],
        datasets: [
          { label: "Price Changes", data: [{ label: "Mon", value: 1 }] },
        ],
      },
    }));
    api.use("GET", "/api/v1/dashboard/alerts/recent", () => ({ body: [] }));
    api.use("GET", "/api/v1/dashboard/events", () => ({ body: [] }));

    // Realtime events & Smart Home SSE
    api.use("GET", "/api/v1/events/stream", () => ({ status: 200, body: {} }));
    api.use("GET", "/api/v1/smart-home/stream", () => ({
      status: 200,
      body: {},
    }));
    api.use("GET", "/api/v1/smart-home/entities/stream", () => ({
      status: 200,
      body: {},
    }));

    // Common Fallbacks
    api.use("GET", "/api/v1/config", () => ({
      body: {
        feishu_webhook_url: "",
        data_retention_days: 365,
      },
    }));
    api.use("PATCH", "/api/v1/config", async (request) => {
      const data = await request.postDataJSON();
      return { body: data };
    });
    api.use("GET", "/api/v1/scheduler/status", () => ({
      body: { is_running: true },
    }));
    api.use("GET", "/api/v1/products/cron-configs", () => ({ body: [] }));
    api.use("GET", "/api/v1/products/cron-schedules", () => ({
      body: { platforms: {} },
    }));
    api.use("GET", "/api/v1/jobs/scheduler/job-configs", () => ({
      body: { configs: [] },
    }));

    // Feature components helper fallbacks
    api.use("GET", "/api/v1/crawl/logs", () => ({ body: [] }));
    api.use("GET", "/api/v1/alerts", () => ({ body: [] }));
    api.use("GET", "/api/v1/jobs/resumes", () => ({ body: [] }));
    api.use("GET", "/api/v1/jobs/match-results", () => ({
      body: { items: [], total: 0 },
    }));
    api.use("GET", "/api/v1/jobs", () => ({ body: { items: [], total: 0 } }));
    api.use("GET", "/api/v1/jobs/crawl-logs", () => ({ body: [] }));
    api.use("GET", "/api/v1/crawl-profiles", () => ({ body: [] }));
    api.use("GET", "/api/v1/crawl-profiles/runtime-capabilities", () => ({
      body: {},
    }));

    api.use("GET", "/api/v1/products", () => ({
      body: { items: [], total: 0 },
    }));
    api.use("GET", "/api/v1/jobs/configs", () => ({ body: [] }));
    api.use("GET", "/api/v1/jobs/profiles", () => ({ body: [] }));
    api.use("GET", "/api/v1/jobs/scheduler/status", () => ({
      body: { is_running: true },
    }));
    api.use("GET", "/api/v1/smart-home/config", () => ({
      body: { url: "", token_configured: false },
    }));
    api.use("GET", "/api/v1/smart-home/entities", () => ({ body: [] }));
    api.use("GET", "/api/v1/admin/users", () => ({
      body: { items: [], total: 0 },
    }));
    api.use("GET", "/api/v1/admin/roles/permissions", () => ({
      body: {
        roles: [
          {
            role: "user",
            description: "Standard User",
            permissions: ["product:read", "job:read"],
          },
          {
            role: "admin",
            description: "Administrator",
            permissions: [
              "product:read",
              "product:write",
              "job:read",
              "job:write",
              "user:read",
              "user:manage",
            ],
          },
        ],
        all_permissions: [
          { name: "product:read", description: "Read products" },
          { name: "product:write", description: "Write products" },
          { name: "job:read", description: "Read jobs" },
          { name: "job:write", description: "Write jobs" },
          { name: "user:read", description: "Read users" },
          { name: "user:manage", description: "Manage users" },
        ],
      },
    }));
    api.use("GET", "/api/v1/admin/audit-logs", () => ({
      body: { items: [], total: 0 },
    }));
    api.use("GET", "/api/v1/events", () => ({ body: { items: [], total: 0 } }));
    api.use("GET", "/api/v1/crawling/config-ids", () => ({ body: [] }));

    await api.install(page);
    await use(api);
    api.assertSafe();
  },
});

export { expect };
