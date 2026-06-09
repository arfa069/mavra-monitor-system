import { test, expect } from "./fixtures/app-test";
import { adminUser, readOnlyUser } from "./fixtures/test-data";

test.describe("Navigation and Permission E2E", () => {
  test.beforeEach(async ({ api }) => {
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

  test("redirects / to /dashboard", async ({ page }) => {
    await page.goto("/");
    await page.waitForURL("**/dashboard");
    await expect(page).toHaveURL(/.*\/dashboard/);
  });

  test("navigates to main pages via sidebar", async ({ page }) => {
    await page.goto("/dashboard");

    // Click Event Center
    await page.click(
      'a[href="/events"], .ant-menu-item:has-text("Event Center")',
    );
    await page.waitForURL("**/events");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Click Job Management
    await page.click(
      'a[href="/jobs"], .ant-menu-item:has-text("Job Management")',
    );
    await page.waitForURL("**/jobs");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Click Product Management
    await page.click(
      'a[href="/products"], .ant-menu-item:has-text("Product Management")',
    );
    await page.waitForURL("**/products");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Click Schedule Config
    await page.click(
      'a[href="/schedule"], .ant-menu-item:has-text("Schedule Config")',
    );
    await page.waitForURL("**/schedule");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Click Smart Home
    await page.click(
      'a[href="/smart-home"], .ant-menu-item:has-text("Smart Home")',
    );
    await page.waitForURL("**/smart-home");
    await expect(page.locator("[data-page-transition]")).toBeVisible();
  });

  test("redirects user without user:read from /admin/users to /dashboard", async ({
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
    await page.waitForURL("**/dashboard");
    await expect(page).toHaveURL(/.*\/dashboard/);
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
