# React To Flutter Parity Checklist

## React Reference Point

Last React commit before Flutter cutover:
`5f8f61f5005e0053d34c6ef3ebcb6b7c58876dc5`.

Use this commit for source lookup, behavioral comparison, and rollback. React
does not remain a runtime product after Task 7.

## Route Behavior

- Unauthenticated access to protected routes redirects to `/login` while
  preserving the requested location.
- Authenticated access to `/login` or `/register` redirects to `/today`.
- `/` and unknown routes redirect to `/today`.
- `/settings` requires `config:read`.
- `/admin/users` requires `user:read`.
- `/admin/audit-logs` requires `user:read`.
- `/admin/blog` requires `blog:read_admin`.
- Permission failures render an explicit permission state with a return path to
  `/today`.

## Routes

| Route | React source | Flutter target | Required parity | Status |
| --- | --- | --- | --- | --- |
| `/login` | `frontend/src/features/auth/LoginPage.tsx` | `frontend/lib/features/auth/` | username/password login, WeChat entry, loading and error state | Not started |
| `/register` | `frontend/src/features/auth/RegisterPage.tsx` | `frontend/lib/features/auth/` | registration form, password validation, errors | Not started |
| `/auth/wechat/callback` | `frontend/src/features/auth/WeChatAuthCallbackPage.tsx` | `frontend/lib/features/auth/` | cross-platform exchange result handling | Not started |
| `/today` | `frontend/src/features/today/TodayPage.tsx` | `frontend/lib/features/today/` | summary, attention queue, quiet state, module status | Not started |
| `/dashboard` | `frontend/src/features/dashboard/DashboardPage.tsx` | `frontend/lib/features/analytics/` | KPIs, charts, recent alerts, realtime updates | Not started |
| `/events` | `frontend/src/features/events/EventCenterPage.tsx` | `frontend/lib/features/events/` | filters, list, empty state, realtime stream | Not started |
| `/jobs` | `frontend/src/features/jobs/JobsPage.tsx` | `frontend/lib/features/jobs/` | configs, jobs, resumes, matching, profiles, backup | Implemented in Task 11; widget coverage for list/config/resume/profile backup/matches/logs |
| `/products` | `frontend/src/features/products/ProductsPage.tsx` | `frontend/lib/features/products/` | product CRUD, price history, batch import, crawl logs | Implemented in Task 11; widget coverage for CRUD/history/profile binding/cron/import/log states |
| `/schedule` | `frontend/src/features/schedule/ScheduleConfigPage.tsx` | `frontend/lib/features/schedule/` | cron generation, product/job schedules, status | Implemented in Task 12; widget coverage for product/job schedules, cron preview, validation, scheduler status, loading/empty/error/permission states |
| `/smart-home` | `frontend/src/features/smart-home/SmartHomePage.tsx` | `frontend/lib/features/smart_home/` | config, entities, service calls, realtime state | Implemented in Task 12; widget coverage for config edit, entity filters, mocked service calls, realtime updates, loading/empty/error/permission states |
| `/profile` | `frontend/src/features/auth/ProfilePage.tsx` | `frontend/lib/features/auth/` | profile update, password, sessions, login history | Not started |
| `/settings` | `frontend/src/features/settings/SettingsPage.tsx` | `frontend/lib/features/settings/` | user/system config, theme and validation | Implemented in Task 13; widget coverage for config load/update validation, theme preference, API environment, platform status, loading/empty/error/permission states |
| `/admin/users` | `frontend/src/features/admin/AdminUsersPage.tsx` | `frontend/lib/features/admin/` | user administration and permissions | Implemented in Task 13; widget coverage for users, permission matrix, row permission actions, filters, loading/empty/error/permission states |
| `/admin/audit-logs` | `frontend/src/features/admin/AdminAuditLogsPage.tsx` | `frontend/lib/features/admin/` | audit filters and dense table | Implemented in Task 13; shares Admin page with audit filters and `rbac:read` route gate |
| `/admin/blog` | `frontend/src/features/blog/BlogAdminPage.tsx` | `frontend/lib/features/blog/` | posts, editor, statuses and media upload | Implemented in Task 13; widget coverage for list, create/edit, status changes, media upload, validation, editor persistence, loading/empty/error/permission states |

## Shared Shell Parity

| Capability | React behavior | Flutter acceptance |
| --- | --- | --- |
| Initial route | `/today` after authentication | Same |
| Desktop navigation | Collapsible side navigation | Adaptive `NavigationRail` or side navigation |
| Mobile navigation | Drawer below 768 px | Bottom navigation plus overflow destinations |
| User menu | Profile, Settings, permitted admin entries, logout | Same destinations and permission visibility |
| Theme | Light/dark preference | Preserve preference with Flutter theme tokens |
| Loading | Full-screen or route spinner | Shared accessible loading state |
| Fatal route error | Recovery message and return to login | Typed error state with retry or login action |
| Footer | Product status phrase | Optional on desktop; must not reduce mobile content space |

## API And Transport Parity

- Business API paths remain canonical `/api/v1`.
- Ordinary JSON requests move from Orval/Axios to generated Dart clients.
- SSE/EventSource remains owned by `core/realtime`.
- Profile backup Blob export moves from
  `frontend/src/features/jobs/api/profileBackupExport.ts` to `core/files`.
- OAuth/WeChat callback remains a redirect/exchange transport.
- `/health`, `/health/detailed`, and `/blog-media/{file_name}` remain
  non-business resources.
- Feature code must not create raw Dio business requests.

## Feature Inventory

| Feature | React location | Important subflows |
| --- | --- | --- |
| Today | `frontend/src/features/today/` | daily summary, attention queue, quiet status, rhythm |
| Auth | `frontend/src/features/auth/` | login, registration, profile, password, WeChat |
| Products | `frontend/src/features/products/` | CRUD, price trend, batch import, crawl |
| Jobs | `frontend/src/features/jobs/` | configs, listings, resumes, matching, profiles, backup |
| Schedule | `frontend/src/features/schedule/` | cron generator, product schedules, job schedules |
| Smart Home | `frontend/src/features/smart-home/` | configuration, entities, services, SSE |
| Events | `frontend/src/features/events/` | filters, list, realtime state |
| Alerts | `frontend/src/features/alerts/` | alert queries and mutations |
| Analytics | `frontend/src/features/dashboard/` | KPI, trends, pie charts, recent alerts |
| Admin | `frontend/src/features/admin/` | users, permissions, audit logs |
| Blog | `frontend/src/features/blog/` | posts, rich-text editor, media |
| Settings | `frontend/src/features/settings/` | user configuration and validation |

## Verification Baseline

Before Flutter cutover, the isolated worktree recorded:

- React lint passed.
- React unit tests passed: 29 files, 95 tests.
- React production build passed.
- Blog tests passed: 7 files, 11 tests.
- Blog production build passed.
- Backend Ruff passed.
- Full backend pytest requires configured PostgreSQL and Redis; the local
  environment result was 635 passed, 59 failed, 41 skipped, with failures
  dominated by unavailable service credentials and existing auth/route
  assertions.

Each route row must become `Implemented` or `Accepted replacement` before Gate
F. No row may remain `Not started` at final completion.
