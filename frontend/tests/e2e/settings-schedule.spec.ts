import { test, expect } from "./fixtures/app-test";
import { adminUser, readOnlyUser } from "./fixtures/test-data";

test.describe("Settings and Schedule E2E", () => {
  test("renders settings form, handles PATCH update and persists motion settings", async ({ page, api }) => {
    // 1. Mock GET and PATCH config settings
    const testUserWithConfig = {
      ...adminUser,
      feishu_webhook_url: "https://open.feishu.cn/open-apis/bot/v2/hook/old",
      data_retention_days: 30
    };
    api.use("GET", "/api/v1/auth/me", () => ({ body: testUserWithConfig }));

    api.use("GET", "/api/v1/config", () => ({
      body: {
        feishu_webhook_url: "https://open.feishu.cn/open-apis/bot/v2/hook/old",
        data_retention_days: 30
      }
    }));

    let patchPayload: any = null;
    api.use("PATCH", "/api/v1/config", async (request) => {
      patchPayload = await request.postDataJSON();
      return { body: patchPayload };
    });

    await page.goto("/settings");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Verify initial values in input fields
    await expect(page.locator('input[placeholder*="open.feishu.cn"]')).toHaveValue("https://open.feishu.cn/open-apis/bot/v2/hook/old");
    await expect(page.locator('#data_retention_days')).toHaveValue("30");

    // Modify settings and submit
    await page.fill('input[placeholder*="open.feishu.cn"]', "https://open.feishu.cn/open-apis/bot/v2/hook/new");
    await page.click('button:has-text("Save")');

    // Verify payload
    expect(patchPayload).toEqual({
      feishu_webhook_url: "https://open.feishu.cn/open-apis/bot/v2/hook/new",
      data_retention_days: 30
    });

    // 2. Change motion speed and verify localStorage
    const slowRadio = page.locator('label:has-text("Slow"), .ant-radio-button-wrapper:has-text("Slow")');
    if (await slowRadio.count() > 0) {
      await slowRadio.first().click();
      let speed = await page.evaluate(() => localStorage.getItem("mavra-monitor-system-motion-speed"));
      expect(speed).toBe("slow");

      // Reload page and check if speed survives
      await page.reload();
      speed = await page.evaluate(() => localStorage.getItem("mavra-monitor-system-motion-speed"));
      expect(speed).toBe("slow");
    }
  });

  test("validates job schedule config cron expression", async ({ page, api }) => {
    // Override jobs configs response to show one active cron job
    api.use("GET", "/api/v1/jobs/configs", () => ({
      body: [
        {
          id: 101,
          name: "Schedule Test Job",
          platform: "boss",
          url: "https://example.invalid/job/test",
          profile_key: "boss_profile",
          is_active: true,
          cron_expression: "0 9 * * *",
          timezone: "Asia/Shanghai"
        }
      ]
    }));

    api.use("GET", "/api/v1/jobs/scheduler/job-configs", () => ({
      body: {
        configs: [
          {
            config_id: 101,
            next_run_at: "2026-06-08T10:00:00Z",
            cron_expression: "0 9 * * *",
            cron_timezone: "Asia/Shanghai"
          }
        ]
      }
    }));

    let updatedCronPayload: any = null;
    api.use("PATCH", "/api/v1/jobs/configs/101/cron", async (request) => {
      updatedCronPayload = await request.postDataJSON();
      return { body: { ok: true } };
    });

    await page.goto("/schedule");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Verify existing cron value in table row
    const row = page.locator('tr:has-text("Schedule Test Job")');
    const cronInput = row.locator('input.ant-input');
    await expect(cronInput).toHaveValue("0 9 * * *");

    // 1. Enter invalid cron
    await cronInput.fill("invalid_cron_expr");
    
    // Click Save button in the same row
    const saveButton = row.locator('button:has-text("Save"), button:has(.anticon-save)');
    await saveButton.click();

    // Message alert for invalid cron expression
    await expect(page.locator(".ant-message-notice", { hasText: "Invalid cron expression" })).toBeVisible();
    expect(updatedCronPayload).toBeNull();

    // 2. Enter valid cron
    await cronInput.fill("*/5 * * * *");
    await saveButton.click();

    await expect(page.locator(".ant-message-notice", { hasText: "Saved" })).toBeVisible();
    expect(updatedCronPayload).toEqual({
      cron_expression: "*/5 * * * *",
      cron_timezone: "Asia/Shanghai"
    });
  });

  test("disables schedule controls for read-only user", async ({ page, api }) => {
    // Return read-only user
    const noConfigureUser = {
      ...readOnlyUser,
      permissions: readOnlyUser.permissions.filter(p => p !== "schedule:configure")
    };
    api.use("GET", "/api/v1/auth/me", () => ({ body: noConfigureUser }));

    await page.goto("/schedule");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Check that Add Cron or Save buttons are disabled or hidden
    const saveButtons = page.locator('button:has-text("Save"), button:has(.anticon-save)');
    const count = await saveButtons.count();
    for (let i = 0; i < count; i++) {
      await expect(saveButtons.nth(i)).toBeDisabled();
    }
  });
});
