# React To Flutter Feature Parity Ledger

Date: 2026-06-18
Worktree: `C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement`

## Purpose

This ledger supersedes the optimistic route-only parity view in
`react-parity-checklist.md` for Task 16 execution. A Flutter route counts as
complete only when the old React entry point is visible and the old page's
user-facing workflows are available or explicitly accepted as a replacement.

## Entry Point Parity

| React entry | React route | Flutter route | Current Flutter state | Required Task 16 outcome |
| --- | --- | --- | --- | --- |
| Today | `/today` | `/today` | Present | Keep visible in global shell |
| Analytics | `/dashboard` | `/dashboard` | Redirects to `/analytics` | Render dashboard directly at `/dashboard`; keep `/analytics` as alias |
| Activity | `/events` | `/events` | Present, but local nav only | Expose in global shell |
| Jobs | `/jobs` | `/jobs` | Present, simplified | Expose in global shell and restore tabs |
| Prices | `/products` | `/products` | Present, simplified | Expose in global shell and restore table workflow |
| Schedules | `/schedule` | `/schedule` | Present, simplified | Expose in global shell and restore schedule tables |
| Home | `/smart-home` | `/smart-home` | Present, simplified | Expose in global shell and restore control workflow |
| Blog | `/admin/blog` | `/admin/blog` | Present, permission-gated | Expose in global shell when permitted |
| Users | `/admin/users` | `/admin/users` | Present, mostly read-only | Expose in global shell when permitted |
| Audit Logs | `/admin/audit-logs` | `/admin/audit-logs` | Present, shares admin page | Expose in global shell when permitted |
| Profile | `/profile` | `/profile` | Present from route only | Keep in user menu |
| Account Settings | `/settings` | `/settings` | Present from route only | Keep in user menu |
| Alerts | `/alerts` | `/alerts` | Present as separate route | Keep deep link and page-level entry |

## Feature Workflow Parity

| Module | React reference | Current Flutter state | Required Task 16 outcome |
| --- | --- | --- | --- |
| Products | `frontend/src/features/products/ProductsPage.tsx` | Task 16 in progress: filters, row actions, single delete, batch delete, trend dialog, crawl trigger intent, import, create/edit, crawl logs, cron/profile sections are available | Remaining follow-up: alert linkage and true server-side pagination |
| Jobs | `frontend/src/features/jobs/JobsPage.tsx` | Task 16 in progress: tabs strip, config create/edit/delete, per-config/all crawl intent, job detail dialog, match intent, resume upload/delete, profile create/status/rename/copy/delete/release/login/test/import/export intents are available | Remaining follow-up: richer server-side pagination/filtering and multi-resume selection for match analysis |
| Schedule | `frontend/src/features/schedule/ScheduleConfigPage.tsx` | Partial: rule form and schedule lists | Product schedule table, job schedule table, cron generator, retention/webhook saves |
| Events | `frontend/src/features/events/EventCenterPage.tsx` | Partial: kind filter and list | Full filters, keyword/date range, paged table, detail drawer, SSE merge |
| Admin | `frontend/src/features/admin/` | Partial: user table, permission matrix, audit list | Users and audit logs route-specific views, filters, pagination, user create/edit/status/delete intents, role/permission display |
| Blog | `frontend/src/features/blog/BlogAdminPage.tsx` | Partial: post list/editor/media upload | Search/status filters, publish time, taxonomy selectors, cover upload, SEO fields, edit dialog |
| Smart Home | `frontend/src/features/smart-home/SmartHomePage.tsx` | Partial: config, entity list, manual service form | Config test intent, entity filters, entity-level service controls with confirmation, realtime state |
| Dashboard | `frontend/src/features/dashboard/DashboardPage.tsx` | Partial replacement under analytics | `/dashboard` route renders KPI/trend/recent alert page and remains bookmark-stable |
| Profile | `frontend/src/features/auth/ProfilePage.tsx` | Accepted partial replacement | Keep overview/session/history; profile update and password mutation remain out of Task 16 unless requested separately |

## Verification Rules

- Widget tests must cover global shell visibility, permission gating, and old route deep links.
- Module tests must assert dangerous actions call fake repositories only; tests must not perform real crawling, Profile login/import/export, matching, or Home Assistant service calls.
- Device verification must cover Web, Windows, and Android emulator; iOS remains deferred on this Windows host.
- `final-verification-report.md` and `platform-verification-matrix.md` must be updated after Task 16 verification evidence is collected.
