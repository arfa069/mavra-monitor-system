# Flutter Approved Screen References

Status: approved reference set for implementation and screenshot QA.

These references are text wireframes anchored to the current React source.
Later screenshot QA must compare the Flutter implementation against these
references. Screenshots may be added after the Flutter shell exists.

## Reference 1: Today Mobile

Target viewport:

- Android/iOS narrow phone, `360-430 px` width.

Source route:

- `/today`

Source files:

- `frontend/src/features/today/TodayPage.tsx`
- `frontend/src/features/today/components/DailySummary.tsx`
- `frontend/src/features/today/components/AttentionQueue.tsx`
- `frontend/src/features/today/components/QuietStatusPanel.tsx`

Interaction state:

- Authenticated user with one or more attention items.
- Offline/realtime banner may appear above the summary without covering content.

Wireframe:

```text
[Top app bar: Mavra, profile/action]
[Today meta + quiet score]
[Large headline: 今天只提醒 N 件事。]
[Short subhead]
[Attention item 1]
[Attention item 2]
[Today status rows: Prices, Jobs, Home]
[Bottom nav: Today, Prices, Jobs, Home, More]
```

Acceptance notes:

- Attention queue appears before module status.
- Copy wraps without overlapping actions at 200 percent text scale.
- Primary action per attention item is visible without opening a menu.
- Quiet state is treated as success, not blank content.
- Bottom navigation never hides the last status row.

## Reference 2: Today Desktop And Windows

Target viewport:

- Web desktop `1440 x 900`.
- Windows app minimum verification at `1100 x 720`.

Source route:

- `/today`

Source files:

- `frontend/src/features/today/`
- `frontend/src/shared/components/AppLayout.tsx`

Interaction state:

- Authenticated user with mixed quiet and attention module states.

Wireframe:

```text
[Top app bar: Mavra, account actions]
[Left side navigation: Today, Prices, Jobs, Home, Rules, Activity, Analytics, Settings]
[Main column]
  [Today meta + quiet score]
  [Large morning brief headline]
  [Attention queue]
[Side column]
  [Today status panel]
  [Recent assistant/activity summary when available]
```

Acceptance notes:

- Today feels like a morning brief, not a KPI wall.
- Navigation is compact and keyboard-focusable.
- Side status panel remains visible without making content feel card-heavy.
- Windows width below `1100 px` scrolls or collapses navigation cleanly.

## Reference 3: Dense Management Table

Target viewport:

- Web/Windows desktop, `1280-1440 px` width.
- Mobile fallback `390 px` width with horizontal table scroll and detail sheet.

Source routes:

- `/products`
- `/jobs`
- `/admin/users` as later admin reference

Source files:

- `frontend/src/features/products/ProductsPage.tsx`
- `frontend/src/features/jobs/JobsPage.tsx`
- `frontend/src/features/admin/AdminUsersPage.tsx`

Interaction state:

- Loaded table with filters, row actions, selection, and at least one warning or
  failed row.

Wireframe:

```text
[Page title and compact subtitle]
[Filter/search bar with active filter chips]
[Command row: add/import/crawl/refresh depending on permission]
[Dense table]
  columns, row selection, status chips, row action icons
[Pagination or load-more]
[Scoped empty/error/partial panel inside table frame]
```

Acceptance notes:

- Tables prioritize scanning over decorative cards.
- Row height follows desktop compact or dense tokens.
- Icon actions have tooltips and semantic labels.
- Missing permissions disable or hide commands with an accessible reason.
- Error states stay scoped to the affected table or tab.

## Reference 4: Smart Home Mobile Control Panel

Target viewport:

- Android/iOS phone, `390 x 844`.

Source route:

- `/smart-home`

Source files:

- `frontend/src/features/smart-home/SmartHomePage.tsx`

Interaction state:

- Connected Home Assistant with grouped entities.
- One unavailable device.
- User may or may not have `smart_home:control`.

Wireframe:

```text
[Top app bar]
[Connection chip: Connected/Offline]
[Refresh and Configure when permitted]
[Room group]
  [Device row/card: name, entity id, state chip]
  [Switch or service controls]
[Unavailable device warning]
[Bottom nav]
```

Acceptance notes:

- Device state is readable without relying on color.
- Controls are at least `44 x 44 px`.
- Scene/script actions ask for confirmation.
- Missing control permission leaves state visible and controls disabled.
- Realtime disconnect shows a persistent banner with reconnect and refresh.

## Reference 5: Blog Editor

Target viewport:

- Web/Windows desktop, `1440 x 900`.
- Mobile fallback list-first, editor in a full-screen route or sheet.

Source route:

- `/admin/blog`

Source files:

- `frontend/src/features/blog/BlogAdminPage.tsx`
- `frontend/src/features/blog/components/RichTextEditor.tsx`

Interaction state:

- Blog admin user editing a draft with taxonomy loaded.
- Media upload available.

Wireframe:

```text
[Blog Studio title]
[Command: New post]
[Search + status filter]
[Posts table]
[Editor dialog/full page]
  title, status, slug, publish time
  excerpt
  category, tags
  cover image upload
  rich text body
  SEO fields
  Save/Create actions
```

Acceptance notes:

- Blog remains permission-gated and does not appear as a primary mobile tab.
- Editor body has a semantic label.
- Unsaved content survives taxonomy reload or save error.
- Upload errors use backend error envelope copy and keep the chosen draft.
- Desktop editor may use a wide dialog; mobile uses a route or full-screen sheet
  to avoid cramped fields.

## Screenshot QA Expectations

When Flutter screens exist, QA must capture:

- Today mobile;
- Today Web desktop;
- Today Windows minimum window;
- dense Products or Jobs table Web/Windows;
- Smart Home mobile;
- Blog editor desktop.

Each screenshot review checks:

- spacing and density match this reference;
- hierarchy is obvious at a glance;
- text does not overlap at normal or 200 percent text scale;
- empty/error/permission/offline states are visibly recoverable;
- target platform controls do not obscure primary content.
