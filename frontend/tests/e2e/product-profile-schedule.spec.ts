import { test, expect } from "@playwright/test";

test("schedule page exposes product profile binding controls", async ({
  page,
}) => {
  await page.goto("http://127.0.0.1:3000");
  await page.getByPlaceholder("Email").fill("default123");
  await page.getByPlaceholder("Password").fill("123456");
  await page.getByRole("button", { name: /sign in/i }).click();

  await page.waitForURL("**/dashboard");
  await page.goto("http://127.0.0.1:3000/schedule");

  await expect(page.getByText("product-jd-default")).toBeVisible();
});
