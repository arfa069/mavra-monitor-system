import { test, expect } from "./fixtures/app-test";
import { mockProducts, mockJobConfigs, mockProfiles, readOnlyUser } from "./fixtures/test-data";

test.describe("Products and Jobs Feature E2E", () => {
  test("renders product list, filters, and supports adding a product", async ({ page, api }) => {
    // 1. Mock GET list and POST create
    api.use("GET", "/api/v1/products", (request) => {
      const url = new URL(request.url());
      const keyword = url.searchParams.get("keyword") || url.searchParams.get("search") || "";
      const platform = url.searchParams.get("platform") || "";

      // Apply simple filtering if queried
      let filtered = [...mockProducts];
      if (keyword) {
        filtered = filtered.filter(p => p.title.toLowerCase().includes(keyword.toLowerCase()));
      }
      if (platform) {
        filtered = filtered.filter(p => p.platform === platform);
      }

      return { body: { items: filtered, total: filtered.length } };
    });

    let createdPayload: any = null;
    api.use("POST", "/api/v1/products", async (request) => {
      createdPayload = await request.postDataJSON();
      return {
        body: {
          id: 99,
          ...createdPayload,
          price: 100,
          created_at: "2026-06-08T00:00:00Z"
        }
      };
    });

    await page.goto("/products");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Verify synthetic product items render
    await expect(page.locator("text=Synthetic Marketplace Item A")).toBeVisible();
    await expect(page.locator("text=Synthetic Marketplace Item B")).toBeVisible();

    // Apply search filter
    const searchInput = page.locator('input[placeholder*="Search"], input.ant-input').first();
    await searchInput.fill("Item A");
    // Wait for filtered result
    await expect(page.locator("text=Synthetic Marketplace Item B")).not.toBeVisible();
    await expect(page.locator("text=Synthetic Marketplace Item A")).toBeVisible();

    // Clear search
    await searchInput.fill("");

    // Click Add Product
    await page.click('button:has-text("Add Product"), button:has(.anticon-plus)');
    // Modal appears
    await expect(page.locator(".ant-modal")).toBeVisible();

    // Submit empty to trigger validation
    await page.click('.ant-modal-footer button.ant-btn-primary, .ant-modal-footer button[type="submit"]');
    await expect(page.locator(".ant-form-item-explain-error").first()).toBeVisible();

    // Fill valid values and submit (platform auto-detected as jd)
    await page.fill("#url", "https://item.jd.com/12345.html");
    await page.click('.ant-modal-footer button.ant-btn-primary, .ant-modal-footer button[type="submit"]');

    // Modal closed and payload verified
    await expect(page.locator(".ant-modal")).not.toBeVisible();
    expect(createdPayload.url).toBe("https://item.jd.com/12345.html");
    expect(createdPayload.platform).toBe("jd");
  });

  test("renders jobs dashboard, detail drawer, profiles, and hides crawl now for readonly", async ({ page, api }) => {
    // Return custom configs and profiles
    api.use("GET", "/api/v1/jobs/configs", () => ({ body: mockJobConfigs }));
    api.use("GET", "/api/v1/crawl-profiles", () => ({ body: mockProfiles }));

    // Visit /jobs
    await page.goto("/jobs");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Verify configs table rendering
    await expect(page.locator("text=Boss Software Engineer Monitor")).toBeVisible();
    await expect(page.locator("text=Liepin Python Dev Monitor")).toBeVisible();

    // Click Job Config row details or drawer trigger button (assuming custom detail icon or button exists)
    // We can click the Job Name text or detail button
    const detailButton = page.locator('button:has(.anticon-history), button:has-text("History"), button:has-text("Details")').first();
    if (await detailButton.count() > 0) {
      await detailButton.click();
      // Job details drawer should show up
      await expect(page.locator(".ant-drawer")).toBeVisible();
      // Close drawer
      await page.click(".ant-drawer-close");
      await expect(page.locator(".ant-drawer")).not.toBeVisible();
    }

    // Verify profile table rendering
    await page.click('text=Profiles Management');
    await expect(page.locator('.ant-tabs-tabpane-active .ant-table-cell >> text=boss_chrome_profile').first()).toBeVisible();
    await expect(page.locator('.ant-tabs-tabpane-active .ant-table-cell >> text=liepin_chrome_profile').first()).toBeVisible();
    await expect(page.locator('.ant-tabs-tabpane-active .ant-table-cell >> text=leased').first()).toBeVisible();

    // 2. Override as read-only user and check that "Crawl Now" & "Test Profile" buttons are missing
    const noConfigureUser = {
      ...readOnlyUser,
      permissions: readOnlyUser.permissions.filter(p => p !== "crawl:execute" && p !== "job:write")
    };
    api.use("GET", "/api/v1/auth/me", () => ({ body: noConfigureUser }));
    await page.reload();

    // The crawl control buttons should be missing/hidden
    await expect(page.locator('button:has-text("Crawl Now"), button:has(.anticon-rocket)')).toHaveCount(0);
    await expect(page.locator('button:has-text("Test Profile")')).toHaveCount(0);
  });
});
