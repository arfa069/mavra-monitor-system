# Flutter Information Architecture

Status: approved route and navigation baseline for the Flutter replacement.

Source references:

- `frontend/src/App.tsx`
- `frontend/src/shared/components/AppLayout.tsx`
- `docs/flutter-migration/react-parity-checklist.md`

## IA Thesis

Mavra opens on Today. From there, users drill into focused modules only when
something deserves attention.

Navigation vocabulary:

- Today
- Prices
- Jobs
- Home
- Rules
- Activity
- Analytics
- Settings

`/dashboard` remains available, but the user-facing label becomes Analytics.
Admin and Blog are permission-gated management destinations, not primary mobile
tabs.

## Route Tree

| Route | Flutter module | Shell | Access |
| --- | --- | --- | --- |
| `/login` | `features/auth` | `AuthShell` | public, redirects authenticated users to `/today` |
| `/register` | `features/auth` | `AuthShell` | public, redirects authenticated users to `/today` |
| `/auth/wechat/callback` | `features/auth` | `AuthCallbackShell` | public exchange route |
| `/today` | `features/today` | `AppShell` | authenticated |
| `/products` | `features/products` | `AppShell` | authenticated |
| `/jobs` | `features/jobs` | `AppShell` | authenticated |
| `/smart-home` | `features/smart_home` | `AppShell` | authenticated |
| `/schedule` | `features/schedule` | `AppShell` | authenticated |
| `/events` | `features/events` | `AppShell` | authenticated |
| `/dashboard` | `features/analytics` | `AppShell` | authenticated |
| `/profile` | `features/auth` | `AppShell` | authenticated |
| `/settings` | `features/settings` | `AppShell` | authenticated |
| `/admin/users` | `features/admin` | `AdminShell` | `user:read` |
| `/admin/audit-logs` | `features/admin` | `AdminShell` | `user:read` |
| `/admin/blog` | `features/blog` | `AdminShell` | `blog:read_admin` |
| `/` | router redirect | none | redirect to `/today` |
| `*` | router redirect | none | redirect to `/today` |

## Shells

### AuthShell

Routes:

- `/login`
- `/register`

Behavior:

- Shows the calm Mavra login surface and short product signal copy.
- Offers username/password login and WeChat login entry when configured.
- Redirects authenticated users to `/today`.
- Preserves the originally requested route for post-login return.

### AuthCallbackShell

Route:

- `/auth/wechat/callback`

Behavior:

- Reads the one-time exchange code from the platform callback.
- Exchanges it through the backend session contract.
- Never displays raw tokens.
- Shows success, bind/register, expired, and retry states.

### AppShell

Routes:

- Today
- Prices
- Jobs
- Home
- Rules
- Activity
- Analytics
- Profile
- Settings

Behavior:

- Requires authentication.
- Uses adaptive navigation based on width and platform.
- Owns global realtime/offline banners.
- Owns user menu, profile, settings, theme preference, and logout.

### AdminShell

Routes:

- Users
- Audit Logs
- Blog Studio

Behavior:

- Uses desktop-dense layout on Web/Windows.
- On mobile, opens through More and may use a warning that management screens
  are optimized for larger screens.
- Permission failures render explicit permission state instead of silent
  redirect.

## Web And Windows Side Navigation

Primary tree:

```text
Today
Prices
Jobs
Home
Rules
Activity
Analytics
Settings
```

Secondary user menu:

```text
Profile
Account Settings
Admin
  Users
  Audit Logs
  Blog Studio
Log Out
```

Desktop rules:

- `>= 1280 px`: expanded side navigation with labels.
- `1024-1279 px`: collapsible side navigation, labels available through hover.
- `< 1024 px`: navigation rail or drawer depending on platform.
- Windows keeps the top app bar for account actions and window-safe spacing.

## Mobile Bottom Navigation

Tabs:

1. Today
2. Prices
3. Jobs
4. Home
5. More

More destinations:

- Rules
- Activity
- Analytics
- Settings
- Profile
- Admin: Users, Audit Logs, Blog Studio when permitted
- Log Out

Mobile rules:

- Admin and Blog never appear as bottom tabs.
- More opens as a full-height sheet on narrow phones.
- Current deep route stays highlighted in More when not a primary tab.
- System back closes sheets before leaving the route.

## Permission Visibility

| Destination | Required permission | Visible when missing | Flutter behavior |
| --- | --- | --- | --- |
| Today | authenticated | yes | Always first authenticated screen |
| Prices | authenticated | yes | Read view; crawl actions hidden if `crawl:execute` is missing |
| Jobs | authenticated | yes | Read view; crawl/profile test actions hidden if `crawl:execute` is missing |
| Home | authenticated | yes | Read view; controls disabled if `smart_home:control` is missing |
| Rules | authenticated | yes | Read view; edit actions disabled if `schedule:configure` is missing |
| Activity | authenticated | yes | Read-only event center |
| Analytics | authenticated | yes | Read-only dashboard data |
| Settings | authenticated | yes | User settings |
| Profile | authenticated | yes | User profile |
| Users | `user:read` | no primary nav entry | Direct URL shows permission panel |
| Audit Logs | `user:read` | no primary nav entry | Direct URL shows permission panel |
| Blog Studio | `blog:read_admin` | no primary nav entry | Direct URL shows permission panel |

## Today Drill-Downs

Today attention items route to modules:

| Today signal | Destination | Target state |
| --- | --- | --- |
| Price drop | `/products` | Product table filtered to attention or recent movement when available |
| Job match | `/jobs` | Jobs tab or match results tab with selected match context |
| Home issue | `/smart-home` | Entity group with connection or unavailable-device banner |
| Schedule issue | `/schedule` | Rules page with failing or upcoming run highlighted |
| Event warning | `/events` | Activity list filtered to warning/error |

Back-stack rule:

- From a module reached through Today, back returns to Today on mobile.
- On Web/Windows, browser back follows URL history exactly.

## Public And Authenticated Route Behavior

| Situation | Behavior |
| --- | --- |
| Unauthenticated user opens protected route | Redirect to `/login`, store requested route |
| Authenticated user opens `/login` or `/register` | Redirect to `/today` |
| User logs in from stored route | Return to stored route when still permitted |
| Stored route now forbidden | Show permission panel with `Go to Today` |
| User logs out | Clear session state and redirect to `/login` |
| Unknown route | Redirect to `/today` when authenticated, `/login` when unauthenticated |
| `/` | Redirect to `/today` when authenticated, `/login` when unauthenticated |

## Browser URL And Deep Links

Web:

- Uses path URLs matching the route tree.
- Refresh on a protected URL restores auth state before deciding redirect.
- Browser back follows route history.
- Bookmarks to module routes remain valid.

Android and iOS:

- Support app links for `/auth/wechat/callback` and selected module links.
- System back closes dialogs/sheets before route pop.
- A cold deep link restores session first, then opens the route or permission
  panel.

Windows:

- Supports command-line launch with a route argument when packaging adds it.
- Back action is available through keyboard shortcut and top-level navigation,
  not only browser semantics.

## Module Structure

```text
frontend/lib/
  app/
    mavra_app.dart
    router.dart
    shell/
  core/
    api/
    auth/
    config/
    errors/
    files/
    realtime/
    storage/
    theme/
  features/
    auth/
    today/
    products/
    jobs/
    schedule/
    smart_home/
    events/
    analytics/
    admin/
    blog/
    settings/
```

Ownership:

- `core/api`: generated Dart client and typed adapters.
- `core/auth`: token-first session, secure storage, auth guard.
- `core/realtime`: SSE/Web fallback and stream state.
- `core/files`: downloads, uploads, profile backup export/import.
- `core/errors`: backend error envelope mapping.
- `features/*`: screen state, view models, widgets, route-specific tests.

## Analytics Replacement For Dashboard

Current route `/dashboard` stays stable for bookmarks and parity. Flutter labels
the destination as Analytics.

Acceptance:

- Existing KPI and chart parity lands under `features/analytics`.
- Today remains the emotional first screen.
- Analytics is a drill-down workspace, not the landing page.

## Admin And Blog Visibility

Admin and Blog are management destinations:

- They appear in desktop side navigation only when permission exists.
- They appear in mobile More only when permission exists.
- Direct URL access without permission renders a permission panel.
- Blog Studio uses editor-first layout on desktop and draft-list-first layout
  on mobile.

