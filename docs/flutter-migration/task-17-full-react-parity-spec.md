# Task 17 Full React Parity Spec

Date: 2026-06-18
Worktree: `C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement`
Reference app: React app on `main`
Target app: Flutter app in `codex/flutter-full-replacement`

## Decision

Task 17 replaces the earlier "implemented with accepted follow-ups" parity
standard. The new standard is:

- Business parity with the old React app is the completion gate.
- Flutter may use native Material layout, controls, and responsive reflow.
- Desktop/Web/Windows screens must preserve React's information density for
  operational pages.
- Mobile/Android may reflow into lists, sheets, and stacked forms, but must keep
  the same workflows.
- All old React protected routes are in scope in one pass. Schedule, Blog,
  Smart Home, Settings, Profile, Users, and Audit Logs are not deferred.
- Flutter-only `/alerts` remains as a compatible deep link, but React protected
  routes define the parity scope.

## Non-Goals And Safety Boundaries

- No pixel-perfect React clone.
- No hardcoded credentials, tokens, cookies, or secrets.
- No automated test may trigger real product crawls, real job crawls, real
  profile login/import/export side effects, real match jobs, or real Home
  Assistant service control.
- iOS remains deferred on this Windows host. Web, Windows, and Android emulator
  are required device gates.
- Existing React code on `main` is reference-only and must not be edited in this
  task.

## Evidence From Current Comparison

The route layer is mostly present, but page capability parity is not complete.
Important source findings:

- React protected routes are `/today`, `/dashboard`, `/events`, `/jobs`,
  `/products`, `/schedule`, `/smart-home`, `/profile`, `/settings`,
  `/admin/users`, `/admin/audit-logs`, and `/admin/blog`.
- Flutter has corresponding routes plus a Flutter-only `/alerts` deep link.
- Current Flutter pages frequently use simplified lists/cards where React uses
  table, filter, pagination, modal, drawer, and batch-action workflows.
- Current Flutter `Jobs` has a visual tab strip whose chips do not switch the
  page content.
- Current Flutter `Dashboard` renders trend data as simple progress rows, while
  React renders multiple trend/pie/bar chart panels.
- Current Flutter `Profile` is read-only account/session/history display, while
  React includes profile update and password-change forms.
- Current Flutter `Admin` uses one shared page for both Users and Audit Logs,
  while React has separate route-specific experiences and deeper resource
  permission workflows.

## Route Scope

| Entry      | React route         | Flutter route       | Gate                                                                                                                         |
| ---------- | ------------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Today      | `/today`            | `/today`            | Keep dashboard summary, attention queue, quiet status, and module status usable on all devices.                              |
| Analytics  | `/dashboard`        | `/dashboard`        | Render directly at `/dashboard`; `/analytics` remains alias.                                                                 |
| Activity   | `/events`           | `/events`           | Full filter, pagination, realtime merge, and details workflow.                                                               |
| Jobs       | `/jobs`             | `/jobs`             | Restore tabbed job operations and all job/profile/resume/match workflows.                                                    |
| Prices     | `/products`         | `/products`         | Restore product table, filters, pagination, batch actions, trend, alert, crawl log, schedule, and profile binding workflows. |
| Schedules  | `/schedule`         | `/schedule`         | Restore product and job schedule tables with cron generator and settings.                                                    |
| Home       | `/smart-home`       | `/smart-home`       | Restore grouped entity controls, config/test, filters, realtime, and confirmations.                                          |
| Profile    | `/profile`          | `/profile`          | Restore account edit and password change; keep Flutter session/history extras.                                               |
| Settings   | `/settings`         | `/settings`         | Restore Feishu, retention, and motion speed; keep Flutter theme/platform extras.                                             |
| Users      | `/admin/users`      | `/admin/users`      | Separate Users experience with user CRUD, role/resource permissions, and RBAC matrix.                                        |
| Audit Logs | `/admin/audit-logs` | `/admin/audit-logs` | Separate audit log table with pagination and details display.                                                                |
| Blog       | `/admin/blog`       | `/admin/blog`       | Restore Blog Studio table, filters, modal editor, rich text, taxonomy, media, scheduling, and SEO.                           |

## Page Acceptance Matrix

| Page       | Required Flutter outcome                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Today      | Preserve the current responsive Today layout if it continues to show daily summary, attention queue, quiet status, module status, loading, and warning/error states. Verify click-through routes still work.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| Analytics  | Add a time-range selector equivalent to React. Render user KPI cards, product platform distribution, price trends, price-change trends, job platform distribution, new-job trends, job-match trends, admin system KPI cards, platform success comparison, crawl-failure trend, and recent alerts. Use a Flutter chart implementation rather than progress-row placeholders. Preserve SSE refresh behavior and warning state.                                                                                                                                                                                                                                                                                  |
| Events     | Desktop/Web/Windows use a dense table with columns equivalent to React and pagination with page size. Mobile/Android may use cards/list. Filters must include kind, event type, category, severity, source, keyword, start/end date-time, reset, and apply behavior. Details should use a side sheet/drawer on wide screens and dialog/sheet on mobile. SSE updates merge without duplicating rows.                                                                                                                                                                                                                                                                                                           |
| Products   | Restore server-side keyword/platform/active filters, pagination, row selection, batch import, batch delete with confirmation, add/edit dialog, delete confirmation, open product link, trend chart dialog with day range, alert create/update linkage in the product form, crawl-now intent button, crawl log table, product schedule summary, and profile binding display/manage entry.                                                                                                                                                                                                                                                                                                                      |
| Jobs       | Replace decorative chips with an actual tab controller: Configs, Jobs, Match Results, Resumes, Profiles, Crawl Logs. Configs require CRUD, profile selection/create, active/notify/auto-match fields, single/all crawl intent, loading/disabled states, and delete confirmation. Jobs require keyword/status filters, pagination, detail drawer/sheet, original link, and match action with resume selection. Resumes require create/edit/delete/upload. Profiles require create, status update, rename, copy, delete, release stale, open/close login session, test profile, import backup, and export backup UI. Match Results and Crawl Logs require dense tables/lists with filters where React has them. |
| Schedule   | Restore React's two-table workflow: product platform schedule table and job config schedule table. Each row supports cron edit, generator open/apply, save, delete where applicable, next-run display, read-only disabled state, add product timer dialog, retention days, and Feishu webhook save. Cron generator supports presets, natural-language input, validation, generated expression preview, and apply.                                                                                                                                                                                                                                                                                             |
| Smart Home | Restore status header, refresh, configure dialog, config save/test, grouped device grid, domain/entity filters, realtime updates, unavailable/error states, permission gating, and entity-specific controls for switch/light/fan, cover, climate, scene, and script. Any service call that could control Home Assistant must have a confirmation path in automated tests and must be mocked.                                                                                                                                                                                                                                                                                                                  |
| Profile    | Restore account info, edit username/email form with validation, change-password form with the existing strong-password guidance, loading/error/success feedback, and keep Flutter's session/login-history panels as additional native value.                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| Settings   | Restore personal Feishu webhook, data-retention days, and page transition speed setting. Keep Flutter's theme selector and platform capability chips only as additional sections. Respect `config:read` and write permissions.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Users      | Split `/admin/users` from `/admin/audit-logs`. Users page requires search, role filter, paginated table, create/edit modal or inline editor, enable/disable, delete confirmation, role display, permission badges, resource permission tab, grant permission modal, inline edit/revoke of resource permissions, and role-permission matrix with editable checkboxes when `rbac:manage` is available.                                                                                                                                                                                                                                                                                                          |
| Audit Logs | Separate page title and table. Include action label/color mapping, actor ID, target type/id, details JSON display, IP address, timestamp, loading/error/empty states, and pagination. Keep action/actor filters if already useful, but do not collapse this into the Users page.                                                                                                                                                                                                                                                                                                                                                                                                                              |
| Blog       | Restore search, status filter, post table, new/edit modal, title/status/slug/publish-time/excerpt fields, category picker, tag picker, cover upload, body editor with toolbar actions for bold, italic, bullet list, numbered list, link, and image URL, SEO title/description, canonical URL, Open Graph image, validation, loading/error states, and permission-gated write actions.                                                                                                                                                                                                                                                                                                                        |

## Architecture Direction

- Keep the global `MavraShell` as the route shell.
- Remove leftover local `AdaptiveScaffold` nav from individual feature pages
  where it duplicates the global shell.
- Introduce small shared Flutter page primitives only where they reduce real
  duplication:
  - responsive page header,
  - dense toolbar/filter row,
  - wide-screen table plus mobile-list adapter,
  - confirmation helper,
  - side sheet/dialog details helper,
  - empty/loading/error panels.
- Use generated OpenAPI Dart client and repository interfaces as the API
  boundary. If the generated client exposes a React-used endpoint, wire it
  through repositories. If an endpoint is missing, update FastAPI/OpenAPI and
  regenerate the Flutter client in the same logical change.
- Add a Flutter chart package or equivalent chart primitive before replacing
  Analytics and product trend placeholders. Prefer a maintained Flutter chart
  package over hand-written chart math unless a package is blocked.
- Keep domain models explicit. Do not mask API drift with `dynamic`, `as any`
  equivalents, or lossy string maps.

## Implementation Order

This is one parity pass, but it should still land in coherent commits:

1. Shared page primitives, chart dependency decision, and repository/domain
   contract expansion.
2. Analytics, Events, Products, Jobs.
3. Schedule, Smart Home, Profile, Settings.
4. Users, Audit Logs, Blog.
5. Cross-route navigation, permission gating, visual QA, and device smoke.

No module is intentionally left for a later "follow-up" milestone.

## Test And Verification Gates

Development gates:

- Add or update fake repository widget tests before or alongside each page
  implementation.
- Test wide-screen and narrow-screen behavior for pages that switch between
  table and list/sheet modes.
- Test permissions for Blog, Users/Audit Logs, Settings, crawl controls, profile
  operations, and Smart Home control/configuration.
- Test dangerous actions only as fake repository calls or request intents.

Final local commands:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\frontend
flutter test
flutter analyze
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Device gates:

- Web smoke on local static build or Flutter web server.
- Windows release smoke on the built `.exe`.
- Android emulator smoke:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\frontend
flutter test integration_test/app_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Evidence gates:

- Update `docs/flutter-migration/final-verification-report.md`.
- Update `docs/flutter-migration/platform-verification-matrix.md`.
- Add screenshots for Today, Dashboard, Events, Products, Jobs, Schedule, Smart
  Home, Profile, Settings, Users, Audit Logs, and Blog on Web and Windows.
- Add Android emulator smoke evidence for route coverage, navigation, login,
  back button, rotation, input fields, and safe-area behavior.

## Open Risks

- GitNexus Dart parsing is currently unavailable in this environment because
  `tree-sitter-dart` is not installed; symbol impact for Dart changes must be
  supplemented by targeted source review, `flutter analyze`, and tests.
- Adding a chart package may update `pubspec.lock` and require extra build
  verification on Windows and Android.
- Blog rich text and profile backup flows require careful platform-specific file
  handling on Web, Windows, and Android.
- Some React parity fields may already exist in OpenAPI but not in Flutter
  domain models; those should be wired through generated models, not invented.
