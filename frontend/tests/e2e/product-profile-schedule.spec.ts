import { test, expect } from "@playwright/test";

test("schedule page exposes product profile binding controls", async ({ page }) => {
  await page.goto("http://127.0.0.1:3000");
  await page.getByPlaceholder("Username").fill("default123");
  await page.getByPlaceholder("Password").fill("123456");
  await page.getByRole("button", { name: /login/i }).click();

  await page.getByRole("link", { name: /schedule/i }).click();

  await expect(page.getByText("product-jd-default")).toBeVisible();
  await expect(page.getByText("product-taobao-default")).toBeVisible();
  await expect(page.getByText("product-amazon-default")).toBeVisible();
});
