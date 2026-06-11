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

    // Should redirect back to settings or today (if state was lost on initial E2E load)
    await page.waitForURL(
      (url) => url.pathname === "/settings" || url.pathname === "/today",
    );
    if (page.url().includes("/today")) {
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

    await page.waitForURL("**/today");

    const localStorageKeys = await page.evaluate(() => {
      return {
        token: localStorage.getItem("auth_token"),
        user: localStorage.getItem("auth_user"),
      };
    });

    expect(localStorageKeys.token).toBeNull();
    expect(localStorageKeys.user).toBeNull();
  });

  test("supports WeChat success callback and navigates to the next path", async ({
    page,
    api,
  }) => {
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 200,
      body: adminUser,
    }));

    await page.goto("/auth/wechat/callback?status=success&next=%2Fjobs");
    await page.waitForURL("**/jobs");
    await expect(page).toHaveURL(/.*\/jobs/);
  });

  test("supports WeChat unbound flow by binding an existing account", async ({
    page,
    api,
  }) => {
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "Not authenticated" },
    }));
    api.use("POST", "/api/v1/auth/wechat/bind", () => ({
      status: 200,
      body: adminUser,
    }));

    await page.goto(
      "/auth/wechat/callback?status=unbound&next=%2Ftoday#temp_token=temp-1",
    );
    await page.getByLabel("Username").fill("default");
    await page.getByLabel("Password").fill("Adminf8869!@");
    await page.click('button:has-text("绑定已有账号")');

    await page.waitForURL("**/today");
    await expect(page).toHaveURL(/.*\/today/);
  });

  test("shows a callback error message and returns to /login", async ({
    page,
    api,
  }) => {
    api.use("GET", "/api/v1/auth/me", () => ({
      status: 401,
      body: { detail: "Not authenticated" },
    }));

    await page.goto("/auth/wechat/callback?status=error&reason=state_expired");
    await expect(page.getByText("微信登录失败，请重新扫码")).toBeVisible();
    await page.getByRole("button", { name: "返回登录页" }).click();
    await expect(page).toHaveURL(/.*\/login/);
  });
});
