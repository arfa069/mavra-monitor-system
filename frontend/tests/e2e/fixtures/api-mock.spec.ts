import { test, expect } from "@playwright/test";
import { ApiMock } from "./api-mock";

test.describe("API Mock Firewall", () => {
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
      const response = await fetch("/api/v1/unknown");
      return { status: response.status, text: await response.text() };
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
      } catch {
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

    const response = await page.evaluate(async () => {
      const result = await fetch("/api/v1/safe-endpoint");
      return result.json();
    });

    expect(response).toEqual({ ok: true });
  });

  test("records LEGACY and rejects v1 calls", async ({ page }) => {
    const api = new ApiMock();
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "unauthorized" },
    }));
    await api.install(page);
    await page.goto("/");

    const status = await page.evaluate(async () => {
      const response = await fetch("/v1/products");
      return response.status;
    });

    expect(status).toBe(501);
    expect(api.getViolations()).toContain("LEGACY GET /v1/products");
  });
});
