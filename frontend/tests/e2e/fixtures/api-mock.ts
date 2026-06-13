import { expect, type Page, type Request, type Route } from "@playwright/test";

type Json = Record<string, unknown> | unknown[];
type MockResult = {
  status?: number;
  body?: Json;
  headers?: Record<string, string>;
};
type Handler = (request: Request) => MockResult | Promise<MockResult>;

const BLOCKED = [
  /^POST \/api\/v1\/crawl\/crawl-now$/,
  /^POST \/api\/v1\/jobs\/crawl-now(?:\/\d+)?$/,
  /^POST \/api\/v1\/crawl-profiles\/[^/]+\/login-session(?:\/close)?$/,
  /^POST \/api\/v1\/crawl-profiles\/[^/]+\/test$/,
  /^POST \/api\/v1\/jobs\/match-results\/(?:analyze|analyze-async)$/,
  /^POST \/api\/v1\/smart-home\/config\/test$/,
  /^POST \/api\/v1\/smart-home\/entities\/[^/]+\/service$/,
];

export class ApiMock {
  private handlers = new Map<string, Handler>();
  private violations: string[] = [];

  use(method: string, path: string, handler: Handler) {
    this.handlers.set(`${method.toUpperCase()} ${path}`, handler);
  }

  async install(page: Page) {
    await page.route(
      (url) =>
        url.pathname.startsWith("/api/") || url.pathname.startsWith("/v1/"),
      async (route: Route) => {
        const request = route.request();
        const url = new URL(request.url());
        const path = url.pathname;
        const key = `${request.method()} ${path}`;

        if (path.startsWith("/v1/")) {
          this.violations.push(`LEGACY ${key}`);
          await route.fulfill({
            status: 501,
            contentType: "application/json",
            body: JSON.stringify({ detail: `Legacy API path rejected: ${key}` }),
          });
          return;
        }

        if (BLOCKED.some((pattern) => pattern.test(key))) {
          this.violations.push(`BLOCKED ${key}`);
          await route.abort("blockedbyclient");
          return;
        }

        const handler = this.handlers.get(key);
        if (!handler) {
          console.error("FIREWALL UNMOCKED INTERCEPT:", key);
          this.violations.push(`UNMOCKED ${key}`);
          await route.fulfill({
            status: 501,
            contentType: "application/json",
            body: JSON.stringify({
              detail: `No E2E mock registered for ${key}`,
            }),
          });
          return;
        }

        try {
          const result = await handler(request);
          await route.fulfill({
            status: result.status ?? 200,
            contentType: "application/json",
            headers: result.headers,
            body: JSON.stringify(result.body ?? {}),
          });
        } catch (err) {
          await route.fulfill({
            status: 500,
            contentType: "application/json",
            body: JSON.stringify({ detail: String(err) }),
          });
        }
      },
    );
  }

  getViolations() {
    return this.violations;
  }

  assertSafe() {
    expect(this.violations).toEqual([]);
  }
}
