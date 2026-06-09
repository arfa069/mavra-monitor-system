import { test, expect } from "@playwright/test";
import { ApiMock } from "./api-mock";

test.describe("API Mock Firewall", () => {
  test.beforeEach(async ({ page }) => {
    // Prevent unmocked page initial loads (like /api/v1/auth/me) from cluttering logs
    // unless we explicitly want to test unmocked behavior
  });

  test("records UNMOCKED and responds 501 for unregistered api calls", async ({
    page,
  }) => {
    const api = new ApiMock();
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "unauthorized" },
    }));
    await api.install(page);

    await page.goto("/");

    const res = await page.evaluate(async () => {
      const r = await fetch("/api/v1/unknown");
      return { status: r.status, text: await r.text() };
    });

    expect(res.status).toBe(501);
    expect(JSON.parse(res.text).detail).toContain("No E2E mock registered");
    expect(api.getViolations()).toContain("UNMOCKED GET /api/v1/unknown");
  });

  test("records BLOCKED and aborts dangerous endpoints", async ({ page }) => {
    const api = new ApiMock();
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "unauthorized" },
    }));
    await api.install(page);

    await page.goto("/");

    const failed = await page.evaluate(async () => {
      try {
        await fetch("/api/v1/crawl/crawl-now", { method: "POST" });
        return false;
      } catch (e) {
        return true;
      }
    });

    expect(failed).toBe(true);
    expect(api.getViolations()).toContain(
      "BLOCKED POST /api/v1/crawl/crawl-now",
    );
  });

  test("fulfills registered safe routes", async ({ page }) => {
    const api = new ApiMock();
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "unauthorized" },
    }));
    api.use("GET", "/api/v1/safe-endpoint", () => ({
      status: 200,
      body: { ok: true },
    }));
    await api.install(page);

    await page.goto("/");

    const res = await page.evaluate(async () => {
      const r = await fetch("/api/v1/safe-endpoint");
      return r.json();
    });

    expect(res).toEqual({ ok: true });
  });
});
