# React To Flutter Feature Parity Ledger

Date: 2026-06-18
Worktree: `C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement`

> Superseded for implementation by
> `docs/flutter-migration/task-17-full-react-parity-spec.md`. The newer Task 17
> spec removes the earlier "accepted follow-up" standard and requires all old
> React protected-route workflows to be brought into the current parity pass.

## Purpose

This ledger supersedes the optimistic route-only parity view in
`react-parity-checklist.md` for Task 16 execution. A Flutter route counts as
complete only when the old React entry point is visible and the old page's
user-facing workflows are available or explicitly accepted as a replacement.

## Entry Point Parity

| React entry      | React route         | Flutter route       | Current Flutter state       | Required Task 16 outcome                                              |
| ---------------- | ------------------- | ------------------- | --------------------------- | --------------------------------------------------------------------- |
| Today            | `/today`            | `/today`            | Present                     | Keep visible in global shell                                          |
| Analytics        | `/dashboard`        | `/dashboard`        | Redirects to `/analytics`   | Render dashboard directly at `/dashboard`; keep `/analytics` as alias |
| Activity         | `/events`           | `/events`           | Present, but local nav only | Expose in global shell                                                |
| Jobs             | `/jobs`             | `/jobs`             | Present, simplified         | Expose in global shell and restore tabs                               |
| Prices           | `/products`         | `/products`         | Present, simplified         | Expose in global shell and restore table workflow                     |
| Schedules        | `/schedule`         | `/schedule`         | Present, simplified         | Expose in global shell and restore schedule tables                    |
| Home             | `/smart-home`       | `/smart-home`       | Present, simplified         | Expose in global shell and restore control workflow                   |
| Blog             | `/admin/blog`       | `/admin/blog`       | Present, permission-gated   | Expose in global shell when permitted                                 |
| Users            | `/admin/users`      | `/admin/users`      | Present, mostly read-only   | Expose in global shell when permitted                                 |
| Audit Logs       | `/admin/audit-logs` | `/admin/audit-logs` | Present, shares admin page  | Expose in global shell when permitted                                 |
| Profile          | `/profile`          | `/profile`          | Present from route only     | Keep in user menu                                                     |
| Account Settings | `/settings`         | `/settings`         | Present from route only     | Keep in user menu                                                     |
| Alerts           | `/alerts`           | `/alerts`           | Present as separate route   | Keep deep link and page-level entry                                   |

## Feature Workflow Parity

| Module     | React reference                                         | Current Flutter state                                                                                                                                                                                                                           | Required Task 16 outcome                                                                                              |
| ---------- | ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Products   | `frontend/src/features/products/ProductsPage.tsx`       | Task 16 implemented: filters, row actions, single delete, batch delete, trend dialog, crawl trigger intent, import, create/edit, crawl logs, cron/profile sections are available                                                                | Accepted follow-up: alert linkage and true server-side pagination                                                     |
| Jobs       | `frontend/src/features/jobs/JobsPage.tsx`               | Task 16 implemented: tabs strip, config create/edit/delete, per-config/all crawl intent, job detail dialog, match intent, resume upload/delete, profile create/status/rename/copy/delete/release/login/test/import/export intents are available | Accepted follow-up: richer server-side pagination/filtering and multi-resume selection for match analysis             |
| Schedule   | `frontend/src/features/schedule/ScheduleConfigPage.tsx` | Task 16 implemented: product/job schedule sections, cron generator, rule save, retention days, and Feishu webhook settings save are available                                                                                                   | Accepted follow-up: richer cron presets and inline update/delete of existing product cron rows                        |
| Events     | `frontend/src/features/events/EventCenterPage.tsx`      | Task 16 implemented: kind, type, category, severity, source, keyword, date range filters, pagination, detail dialog, and SSE merge are available                                                                                                | Accepted follow-up: denser table styling and saved filter presets                                                     |
| Admin      | `frontend/src/features/admin/`                          | Task 16 implemented: user filters, role filter, audit action/actor filters, user/audit pagination, create/edit/enable/disable/delete user intents, permission matrix, and audit list are available                                              | Accepted follow-up: fully split route-specific Users and Audit Logs layouts beyond the shared Admin shell             |
| Blog       | `frontend/src/features/blog/BlogAdminPage.tsx`          | Task 16 implemented: search/status filters, taxonomy display, category/tag editing, cover upload, publish time, SEO title/description, and editor form are available                                                                            | Accepted follow-up: richer category/tag picker widgets and dedicated modal shell polish                               |
| Smart Home | `frontend/src/features/smart-home/SmartHomePage.tsx`    | Task 16 implemented: config edit/test, entity filters, entity-level turn on/off confirmation, manual service request form, read-only control gating, realtime entity updates, and desktop-safe header layout are available                      | Accepted follow-up: richer service picker and entity detail panels                                                    |
| Dashboard  | `frontend/src/features/dashboard/DashboardPage.tsx`     | Task 16 implemented: direct `/dashboard` Analytics rendering                                                                                                                                                                                    | `/dashboard` route renders KPI/trend/recent alert page and remains bookmark-stable                                    |
| Profile    | `frontend/src/features/auth/ProfilePage.tsx`            | Accepted partial replacement                                                                                                                                                                                                                    | Keep overview/session/history; profile update and password mutation remain out of Task 16 unless requested separately |

## Verification Rules

- Widget tests must cover global shell visibility, permission gating, and old route deep links.
- Module tests must assert dangerous actions call fake repositories only; tests must not perform real crawling, Profile login/import/export, matching, or Home Assistant service calls.
- Device verification must cover Web, Windows, and Android emulator; iOS remains deferred on this Windows host.
- `final-verification-report.md` and `platform-verification-matrix.md` must be updated after Task 16 verification evidence is collected.
