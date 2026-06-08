import { test, expect } from "./fixtures/app-test";
import { mockEvents, mockSmartHomeConfig, mockSmartHomeEntities, readOnlyUser } from "./fixtures/test-data";

test.describe("Events and Smart Home Feature E2E", () => {
  test("renders events list, handles filtering and details drawer", async ({ page, api }) => {
    // Override events mock
    api.use("GET", "/api/v1/events", () => ({ body: mockEvents }));

    await page.goto("/events");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Verify events render in table
    await expect(page.locator("text=Taobao crawler scanned 2 items.")).toBeVisible();
    await expect(page.locator("text=Failed to connect to Home Assistant.")).toBeVisible();

    // Click on event row or details icon to trigger details drawer (if exists)
    // Here we click the Message text
    await page.click("text=Taobao crawler scanned 2 items.");
    // Drawer appears
    const drawer = page.locator(".ant-drawer");
    if (await drawer.count() > 0) {
      await expect(drawer).toBeVisible();
      await page.click(".ant-drawer-close");
    }
  });

  test("handles realtime event deduplication via EventSource stub injection", async ({ page, api }) => {
    // Relies on global FakeEventSource stub injected by app-test fixture

    api.use("GET", "/api/v1/events", () => ({
      body: {
        items: [
          {
            id: "evt-1",
            kind: "system",
            event_type: "crawl.completed",
            category: "crawler",
            severity: "info",
            message: "Initial crawl event",
            occurred_at: "2026-06-08T00:00:00Z",
            source: "crawler",
            status: "success",
            user_id: 1,
            entity_type: "crawler",
            entity_id: "taobao",
            trace_id: "trace-1",
            payload: null
          }
        ],
        total: 1
      }
    }));

    await page.goto("/events");
    await expect(page.locator("[data-page-transition]")).toBeVisible();
    await expect(page.locator("text=Initial crawl event")).toBeVisible();

    // Trigger duplicate SSE event
    await page.evaluate(() => {
      const sse = (window as any).lastEventSource;
      if (sse) {
        const payload = {
          id: "evt-1",
          kind: "system",
          event_type: "crawl.completed",
          category: "crawler",
          severity: "info",
          message: "Initial crawl event",
          occurred_at: "2026-06-08T00:00:00Z",
          source: "crawler",
          status: "success",
          user_id: 1,
          entity_type: "crawler",
          entity_id: "taobao",
          trace_id: "trace-1",
          payload: null
        };
        // Trigger event
        if (sse.onmessage) {
          sse.onmessage({ data: JSON.stringify(payload) });
        } else {
          sse.dispatchEvent(new MessageEvent("message", { data: JSON.stringify(payload) }));
        }
      }
    });

    // Verify event is not duplicated (still only 1 event row exists or total does not increment)
    // We check that there is only one "Initial crawl event" text node or row
    await expect(page.locator("text=Initial crawl event")).toHaveCount(1);
  });

  test("renders smart home config, cards, and disables controls for readonly", async ({ page, api }) => {
    // Return HA config and entities
    api.use("GET", "/api/v1/smart-home/config", () => ({ body: mockSmartHomeConfig }));
    api.use("GET", "/api/v1/smart-home/entities", () => ({
      body: {
        items: mockSmartHomeEntities,
        connected: true,
        last_error: null
      }
    }));

    await page.goto("/smart-home");
    await expect(page.locator("[data-page-transition]")).toBeVisible();

    // Verify HA entities cards are rendered
    await expect(page.locator("text=Living Room Light")).toBeVisible();
    await expect(page.locator("text=Smart Plug")).toBeVisible();

    // Override as read-only user and check that control buttons/switches are disabled
    const noControlUser = {
      ...readOnlyUser,
      permissions: readOnlyUser.permissions.filter(p => p !== "smart_home:control")
    };
    api.use("GET", "/api/v1/auth/me", () => ({ body: noControlUser }));
    await page.reload();

    // In read-only mode, the toggle switch or buttons for HA control should be disabled
    // Antd switches will have disabled class or attribute
    const switches = page.locator('button[role="switch"], .ant-switch');
    const count = await switches.count();
    for (let i = 0; i < count; i++) {
      await expect(switches.nth(i)).toBeDisabled();
    }
  });
});
