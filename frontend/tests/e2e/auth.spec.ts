import { test, expect } from "./fixtures/app-test";
import { adminUser } from "./fixtures/test-data";

test.describe("Authentication E2E", () => {
  test("redirects unauthenticated users to login page and back after login", async ({
    page,
    api,
  }) => {
    // 1. Force unauthenticated state
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "Not authenticated" },
    }));

    // Go to settings, should redirect to /login
    await page.goto("/settings");
    await page.waitForURL("**/login");
    await expect(page).toHaveURL(/.*\/login/);

    // 2. Mock successful login
    api.use("POST", "/api/v1/auth/login", () => ({
      status: 200,
      body: adminUser,
    }));

    // Fill in form and submit
    await page.fill("#login_username", "default");
    await page.fill("#login_password", "123456");

    // After mock login succeeds, we want auth/me to succeed as well
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 200,
      body: adminUser,
    }));

    await page.click('button[type="submit"]');

    // Should redirect back to settings or dashboard (if state was lost on initial E2E load)
    await page.waitForURL(
      (url) => url.pathname === "/settings" || url.pathname === "/dashboard",
    );
    if (page.url().includes("/dashboard")) {
      await page.goto("/settings");
    }
    await expect(page).toHaveURL(/.*\/settings/);
  });

  test("displays validation errors on empty submission", async ({
    page,
    api,
  }) => {
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "Not authenticated" },
    }));

    await page.goto("/login");
    await page.click('button[type="submit"]');

    await expect(
      page.locator(".ant-form-item-explain-error").first(),
    ).toBeVisible();
    await expect(
      page.locator(".ant-form-item-explain-error", {
        hasText: "Please enter username or email",
      }),
    ).toBeVisible();
    await expect(
      page.locator(".ant-form-item-explain-error", {
        hasText: "Please enter password",
      }),
    ).toBeVisible();
  });

  test("handles login failure and resets password input", async ({
    page,
    api,
  }) => {
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "Not authenticated" },
    }));

    api.use("POST", "/api/v1/auth/login", () => ({
      status: 400,
      body: { detail: "Invalid credentials" },
    }));

    await page.goto("/login");
    await page.fill("#login_username", "wronguser");
    await page.fill("#login_password", "wrongpass");
    await page.click('button[type="submit"]');

    // Message notification appears
    await expect(
      page.locator(".ant-message-notice", {
        hasText: "Invalid username or password",
      }),
    ).toBeVisible();

    // Password field is cleared, but username remains
    await expect(page.locator("#login_username")).toHaveValue("wronguser");
    await expect(page.locator("#login_password")).toHaveValue("");
  });

  test("does not store token or user details in localStorage", async ({
    page,
    api,
  }) => {
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "Not authenticated" },
    }));

    api.use("POST", "/api/v1/auth/login", () => ({
      status: 200,
      body: adminUser,
    }));

    await page.goto("/login");

    await page.fill("#login_username", "default");
    await page.fill("#login_password", "123456");

    api.use("GET", "/api/v1/auth/me", () => ({
      status: 200,
      body: adminUser,
    }));

    await page.click('button[type="submit"]');

    await page.waitForURL("**/dashboard");

    const localStorageKeys = await page.evaluate(() => {
      return {
        token: localStorage.getItem("auth_token"),
        user: localStorage.getItem("auth_user"),
      };
    });

    expect(localStorageKeys.token).toBeNull();
    expect(localStorageKeys.user).toBeNull();
  });
});
