# Phase 4 Product Profile Browser Manager Design

Date: 2026-05-26

## Status

Approved design direction for Phase 4 of crawler production hardening.

This is a design spec, not the implementation plan. The implementation plan should be written separately after review.

## Goal

Phase 4 makes product crawling production-ready by moving JD, Taobao/Tmall, and Amazon away from ad-hoc CDP/manual-cookie operation and toward managed persistent browser profiles.

The scope is intentionally limited to product profile handling and browser lifecycle control. It does not introduce the independent crawler worker from Phase 5.

## Decisions

- Use platform-level product profiles, not per-product profiles.
- Use BrowserManager as the owner of Playwright persistent context lifecycle.
- Keep FastAPI/APScheduler as the executor for Phase 4.
- Use profile-first product crawling in production.
- Keep `CDP_ENABLED` and `JD_COOKIE` only as development or emergency fallback paths.
- Build complete UI for product platform profile management and binding.

## Non-Goals

- Do not implement `python -m app.workers.crawler`.
- Do not move task execution out of FastAPI/APScheduler.
- Do not add per-product profile selection.
- Do not remove CDP or `JD_COOKIE` compatibility paths in this phase.
- Do not require users to store raw cookies in files.
- Do not force an Amazon HTTP fast path; only evaluate and record feasibility.

## Profile Binding Model

Product profiles are bound at the product platform level.

Default profile keys:

| Platform | Default profile key |
| --- | --- |
| JD | `product-jd-default` |
| Taobao/Tmall | `product-taobao-default` |
| Amazon | `product-amazon-default` |

The preferred storage location is `products_platform_crons.profile_key`, because that table already represents user plus product platform configuration.

Rules:

- Product rows remain unchanged and do not store `profile_key`.
- Platform cron/config create and update paths validate that `profile_key` exists in `crawl_profiles`.
- If a platform config does not specify `profile_key`, the service resolves the platform default.
- Manual all-product crawl and per-platform cron crawl write `profile_key` into `crawl_tasks`.
- A single profile can store login state for multiple sites, but one profile directory can only be leased by one crawl task at a time.

## BrowserManager

Add `app.domains.crawling.browser_manager`.

BrowserManager owns browser/session lifecycle. Product adapters should not own shared browser process state.

Core API shape:

```python
async with browser_manager.acquire(
    platform=platform,
    profile_key=profile_key,
    owner=task_id,
    task_id=task_id,
) as session:
    page = await session.new_page()
    result = await adapter.crawl_with_page(url, page)
```

Responsibilities:

- Acquire `DatabaseProfilePool` lease before launching a browser context.
- Start a Playwright persistent context rooted at `profiles/{profile_key}`.
- Enforce one active `BrowserSession` per profile.
- Enforce per-session page limits. Phase 4 default is `max_pages=1`.
- Close pages after each product crawl.
- Close context on session exit.
- Release DB profile lease on session exit.
- Record startup/crash/timeout errors into `crawl_profiles.last_error`.
- Emit Event Center system events for session start, browser failure, profile unavailable, and session cleanup.

`BrowserSession` should expose:

- `profile_key`
- `profile_dir`
- `platform`
- `context`
- `new_page()`
- `close_page(page)`
- `close()`

## Adapter Boundary

`BasePlatformAdapter` should stop being the owner of the product crawl browser lifecycle for the new production path.

Target boundary:

- BrowserManager creates context/page.
- Product adapter receives an existing page or session and performs navigation/extraction.
- Adapter still owns platform-specific extraction logic.
- Existing `crawl(url)` can remain for fallback compatibility, but the new product path should call a page-based method.

This keeps future Phase 5 worker migration straightforward: workers can reuse BrowserManager without rewriting product adapters again.

## Platform Behavior

### JD

Primary path:

- Persistent profile through BrowserManager.
- User logs in once in `profiles/product-jd-default` or another configured JD profile.
- JD adapter uses the profile's browser state.

Fallback:

- `JD_COOKIE` injection only when an explicit fallback setting enables it.
- `CDP_ENABLED` only for local development or emergency fallback, not the production default.

Failure behavior:

- If login state is invalid, mark profile as `login_required` and fail the task with a profile-specific reason.

### Taobao/Tmall

Primary path:

- Persistent profile through BrowserManager.
- Conservative crawl cadence.
- No product-level profile selection.

Failure behavior:

- Anti-bot/login-wall failures should be categorized separately from generic price extraction failure where possible.

### Amazon

Primary path:

- Persistent profile through BrowserManager.

Phase 4 evaluation:

- Record whether a non-browser HTTP fast path is feasible.
- Do not make the HTTP path the default unless real validation proves it reliable.

## UI Design

Phase 4 includes complete product profile UI, but the UI manages platform-level profiles rather than per-product profiles.

### Global Profile Pool

The existing Profiles tab remains the global pool manager:

- List all profiles.
- Create profile.
- Update status: `available`, `login_required`, `disabled`.
- Release stale lease.
- Display `platform_hint`, `profile_dir`, `last_error`, `lease_until`, and current status.

### Schedule Page

The Schedule page gets product platform profile controls.

For each product platform row:

- Show bound `profile_key`.
- Show profile status.
- Show last error.
- Allow selecting an existing profile.
- Allow creating a new profile.
- Allow releasing a stale lease.
- Save cron expression, timezone, and `profile_key` together.

Default binding:

- JD uses `product-jd-default`.
- Taobao uses `product-taobao-default`.
- Amazon uses `product-amazon-default`.

### Products Page

Products do not expose per-product profile selection.

Products page should:

- Keep platform/product CRUD focused on products.
- Surface profile-related crawl failures with a clear message.
- Point users toward Schedule/Profile management when a product crawl fails because of profile state.

## Login State Preparation

Phase 4 should not depend on users pasting raw cookies.

The UI should show profile path and platform instructions. Users prepare login state by opening the relevant persistent profile and logging in once.

An API to open a visible browser profile is not required in Phase 4. It has security and production-operations risk, especially across Windows and Linux environments.

## Error Handling

Profile errors:

- Missing profile: create the default profile metadata if appropriate, but fail with `login_required` when the platform requires login and the profile has no usable session.
- Active lease: fail or skip quickly with `profile_leased`; do not wait indefinitely.
- `login_required`, `disabled`, or `cooling_down`: do not launch browser; fail early.

Browser errors:

- Browser startup failure: mark `crawl_profiles.last_error`, fail task, emit `product_crawl.browser_failed`.
- Page timeout: close page and continue only when the task policy allows.
- Repeated page failures: close session and fail the task.
- Context crash: close context, release lease, fail task.

Task persistence:

- `crawl_tasks.profile_key` must be set for product crawl tasks using profiles.
- Final task reason should distinguish profile, browser, timeout, and extraction failures.

## Compatibility

Compatibility paths remain available but are not the production default.

- `CDP_ENABLED`: local development or emergency fallback only.
- `JD_COOKIE`: explicit fallback only.
- Existing product crawl API response shapes remain compatible.
- Existing product cron behavior remains compatible except for added profile binding.

## Observability

Add structured events for:

- `product_browser.session_started`
- `product_browser.session_closed`
- `product_browser.start_failed`
- `product_browser.page_timeout`
- `product_profile.login_required`
- `product_profile.leased`

Logs and Event Center payloads must continue to use existing redaction rules. Profile paths are allowed; cookies, tokens, webhook URLs, and security identifiers are not.

## Testing And Verification

Backend tests:

- Platform config can save and return `profile_key`.
- Default profile keys resolve for JD/Taobao/Amazon.
- Unknown profile key is rejected.
- Product crawl task records include `profile_key`.
- BrowserManager acquire/release updates profile lease state.
- BrowserManager refuses active leased profiles.
- BrowserManager records startup failures into `last_error`.
- JD cookie fallback is disabled by default.
- Profile states `login_required`, `disabled`, and `cooling_down` fail before browser launch.

Frontend tests:

- Schedule page displays product platform profile binding.
- User can select an existing profile for a platform.
- User can create a profile from the product platform profile UI.
- Leased profile cannot be forcibly marked available from normal update controls.
- Profile-related crawl failure points to profile management.

Real environment integration:

- Run database migration.
- Log into the UI.
- Create or confirm `product-jd-default`.
- Prepare JD login state in `profiles/product-jd-default`.
- Bind JD platform config to `product-jd-default`.
- Trigger JD product crawl.
- Verify `crawl_tasks.profile_key`, `crawl_profiles` lease release, crawl logs, price history, and Event Center events.
- Verify an unprepared JD profile returns `login_required` rather than a generic crawl failure.

## Implementation Planning Notes

The implementation plan should split work into small reviewable batches:

1. Schema and service binding for product platform `profile_key`.
2. BrowserManager and tests with mocked Playwright context.
3. Product crawl integration through BrowserManager.
4. JD profile-first behavior and fallback gating.
5. Taobao/Amazon profile integration.
6. Frontend product platform profile UI.
7. Real environment integration and docs.

