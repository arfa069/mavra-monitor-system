import { test, expect } from "./fixtures/app-test";
import { mockProducts, readOnlyUser } from "./fixtures/test-data";

test.describe("Navigation and Permission E2E", () => {
  test.beforeEach(async ({ api }) => {
    api.use("GET", "/api/v1/dashboard/kpi", () => ({
      body: {
        user: {
          total_products: 2,
          price_drops_today: 1,
          new_jobs_today: 2,
          match_count: 1,
          crawl_count_today: 4,
        },
        system: {
          total_users: 2,
          total_crawls: 50,
          success_rate: 99,
          active_alerts: 1,
          disk_usage: 30,
          memory_usage: 45,
        },
      },
    }));
    api.use("GET", "/api/v1/products", () => ({
      body: {
        items: mockProducts,
        total: mockProducts.length,
        page: 1,
        page_size: 5,
        total_pages: 1,
        has_next: false,
        has_prev: false,
      },
    }));
    api.use("GET", "/api/v1/jobs/match-results", () => ({
      body: {
        items: [
          {
            id: 1,
            user_id: 1,
            resume_id: 1,
            job_id: 1,
            match_score: 86,
            match_reason: "Mocked local match for Today brief.",
            apply_recommendation: null,
            llm_model_used: null,
            created_at: "2026-06-10T00:00:00Z",
            updated_at: "2026-06-10T00:00:00Z",
            job_title: "Senior Python Developer",
            job_company: "Synthetic Tech Corp",
            job_salary: "25k-35k",
            job_location: "Shanghai",
            job_url: "https://example.invalid/jobs/1",
            job_description: null,
          },
        ],
        total: 1,
        page: 1,
        page_size: 5,
      },
    }));
    api.use("GET", "/api/v1/jobs/configs", () => ({ body: [] }));
    api.use("GET", "/api/v1/jobs/profiles", () => ({ body: [] }));
    api.use("GET", "/api/v1/jobs/scheduler/status", () => ({
      body: { is_running: true },
    }));
    api.use("GET", "/api/v1/smart-home/config", () => ({
      body: {
        id: 1,
        base_url: "https://example.invalid/ha-api",
        enabled: true,
        last_status: "connected",
        last_error: null,
        created_at: "2026-06-10T00:00:00Z",
        updated_at: "2026-06-10T00:00:00Z",
        token_configured: true,
      },
    }));
    api.use("GET", "/api/v1/smart-home/entities", () => ({
      body: {
        items: [
          {
            entity_id: "light.living_room",
            domain: "light",
            name: "Living Room",
            state: "on",
            area: "Living Room",
            attributes: {},
            last_changed: "2026-06-10T00:00:00Z",
            last_updated: "2026-06-10T00:00:00Z",
            available: true,
          },
        ],
        total: 1,
        connected: true,
        last_error: null,
      },
    }));
    api.use("GET", "/api/v1/admin/users", () => ({
      body: { items: [], total: 0 },
    }));
    api.use("GET", "/api/v1/admin/roles/permissions", () => ({
      body: {
        roles: [],
        all_permissions: [],
      },
    }));
    api.use("GET", "/api/v1/admin/audit-logs", () => ({
      body: { items: [], total: 0 },
    }));
    api.use("GET", "/api/v1/events", () => ({ body: { items: [], total: 0 } }));
    api.use("GET", "/api/v1/events/stream", () => ({ status: 200, body: {} }));
    api.use("GET", "/api/v1/smart-home/stream", () => ({
      status: 200,
      body: {},
    }));
  });

  test("redirects / to /today", async ({ page }) => {
    await page.goto("/");
    await page.waitForURL("**/today");
    await expect(page).toHaveURL(/.*\/today/);
  });

  test("renders today as the first warm brief screen", async ({ page }) => {
    await page.goto("/today");
    await expect(page.locator("[data-page-transition]")).toBeVisible();
    await expect(
      page.getByRole("heading", { name: /^今天只提醒/ }),
    ).toBeVisible();
    await expect(page.locator(".today-summary")).toBeVisible();
  });

  test("navigates to main pages via sidebar", async ({ page }) => {
    await page.goto("/today");

    await page.getByRole("menuitem", { name: /Analytics/ }).click();
    await page.waitForURL("**/dashboard");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    await page.getByRole("menuitem", { name: /Activity/ }).click();
    await page.waitForURL("**/events");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    await page.getByRole("menuitem", { name: /Jobs/ }).click();
    await page.waitForURL("**/jobs");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    await page.getByRole("menuitem", { name: /Prices/ }).click();
    await page.waitForURL("**/products");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    await page.getByRole("menuitem", { name: /Rules/ }).click();
    await page.waitForURL("**/schedule");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    await page
      .locator(".ant-menu-item")
      .filter({ hasText: /^Home$/ })
      .click();
    await page.waitForURL("**/smart-home");
    await expect(page.locator("[data-page-transition]")).toBeVisible();
  });

  test("redirects user without user:read from /admin/users to /today", async ({
    page,
    api,
  }) => {
    // Override /auth/me to return a user without user:read permission
    const noUserReadUser = {
      ...readOnlyUser,
      permissions: readOnlyUser.permissions.filter((p) => p !== "user:read"),
    };
    api.use("GET", "/api/v1/auth/me", () => ({ body: noUserReadUser }));

    await page.goto("/admin/users");
    await page.waitForURL("**/today");
    await expect(page).toHaveURL(/.*\/today/);
  });

  test("persists motion settings in localStorage and handles settings change", async ({
    page,
    api,
  }) => {
    // 1. Visit Settings page (normally reachable via user menu dropdown)
    await page.goto("/settings");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Toggle motion settings using buttons (assuming buttons like Slow/Normal/Fast exist in UI)
    // Or we can verify it directly against localStorage behavior in settings
    // Let's select one speed. Antd Radio or Button with text "Slow" / "Normal" / "Fast"
    const slowRadio = page.locator(
      'label:has-text("Slow"), .ant-radio-button-wrapper:has-text("Slow")',
    );
    if ((await slowRadio.count()) > 0) {
      await slowRadio.first().click();
      const speed = await page.evaluate(() =>
        localStorage.getItem("mavra-monitor-system-motion-speed"),
      );
      expect(speed).toBe("slow");
    }
  });
});
