# Frontend Testing Guide

This directory contains the testing architecture for the `frontend` React application, covering unit tests, integration tests, and end-to-end (E2E) browser tests.

---

## 1. Testing Stack

The frontend test system uses the following technologies:
- **Unit & Integration Tests:** [Vitest](https://vitest.dev/) + `@testing-library/react` + `jsdom`.
- **Unit Coverage:** `@vitest/coverage-v8`.
- **E2E Browser Tests:** [Playwright](https://playwright.dev/).
- **E2E Mock Firewall:** Custom `ApiMock` interceptor wrapper (located in [api-mock.ts](file:///C:/Users/arfac/Documents/mavra-monitor-system/frontend/tests/e2e/fixtures/api-mock.ts)).

---

## 2. Quality Gates & Red Lines

All frontend pull requests and commits are subject to these quality gates:
1. **Unit Test Coverage:** All lines, statements, functions, and branches must maintain a minimum coverage of **65%**.
2. **E2E Network Isolation:** The E2E tests must be **100% mocked** and run offline. Absolutely **no real network requests** are permitted to hit the backend or external web sites (e.g. Home Assistant, Taobao, Boss).
   - The E2E runner enforces this via the `ApiMock` firewall which logs and fails the test if any request lacks a registered mock router or attempts to pass through.

---

## 3. Test Commands

Run the following commands inside the `frontend/` directory:

| Command | Purpose |
| --- | --- |
| `npm run test:unit` | Run all Vitest unit and integration tests. |
| `npm run test:coverage` | Run unit tests and generate a V8 coverage report under `frontend/coverage/`. |
| `npm run test:e2e` | Run all Playwright E2E browser tests headlessly. |
| `npm run test:e2e:headed` | Run E2E tests in a visible browser for debugging. |
| `npm run test:frontend` | **Full CI Pipeline Gate:** Runs linting, coverage check, production build compilation, and E2E tests sequentially. |

---

## 4. API Mocking & E2E Fixtures

To ensure E2E tests are robust, isolated, and fast, we use `ApiMock` to intercept browser requests:

### The AppTest Fixture
The core E2E fixture is `test` from [app-test.ts](file:///C:/Users/arfac/Documents/mavra-monitor-system/frontend/tests/e2e/fixtures/app-test.ts). It:
1. Injects a console/page error listener to fail tests immediately if runtime React crashes occur.
2. Registers a set of **Common Fallbacks** (e.g., current login user, configuration settings, empty tables for products/jobs/events) to ensure basic navigation doesn't crash.
3. Automatically installs the `ApiMock` instance on the Playwright `page`.

### Extending or Customizing Mocks
You can override or define specific API mocks inline inside your test block:
```typescript
import { test, expect } from "./fixtures/app-test";

test("my custom feature flow", async ({ page, api }) => {
  // Override mock for this test block
  api.use("GET", "/api/v1/my-feature", () => ({
    body: { data: "custom-mocked-value" }
  }));

  await page.goto("/my-feature-page");
  await expect(page.locator("text=custom-mocked-value")).toBeVisible();
});
```

---

## 5. Adding New Tests

### Unit Tests
Create unit test files adjacent to components or hooks using the `.test.tsx` or `.test.ts` extension.
- **Example:** `src/features/my-feature/components/MyComponent.test.tsx`

### E2E Tests
Place browser interaction specifications under `tests/e2e/` using the `.spec.ts` extension.
- **Example:** `tests/e2e/my-feature.spec.ts`

Always import `{ test, expect }` from `./fixtures/app-test` rather than the raw `@playwright/test` package to inherit the API interceptor, error listeners, and global mocks automatically.
