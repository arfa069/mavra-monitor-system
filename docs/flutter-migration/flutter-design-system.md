# Flutter Design System

Status: approved baseline for the Flutter replacement.

Source references:

- `doc/DESIGN.md`
- `frontend/src/App.tsx`
- `frontend/src/shared/components/AppLayout.tsx`
- `frontend/src/features/today/`
- `frontend/src/features/products/ProductsPage.tsx`
- `frontend/src/features/jobs/JobsPage.tsx`
- `frontend/src/features/smart-home/SmartHomePage.tsx`
- `frontend/src/features/blog/BlogAdminPage.tsx`

## Design Thesis

Flutter is not copying Ant Design. It must replace the React implementation with
a native, cross-platform interface that keeps Mavra's calm private-assistant
feel:

> Mavra watches quietly, then surfaces only the changes worth attention.

Today remains the first authenticated screen. Today can feel warm and editorial.
Prices, Jobs, Rules, Activity, Admin, Blog, and Analytics must still behave like
real operational tools: compact, scannable, keyboard-friendly, and precise.

## Product Personality

Mavra should feel like a lived-in morning brief:

- warm on first touch;
- precise on demand;
- quiet when nothing needs action;
- direct when a price, job, device, schedule, or permission issue needs review;
- never like a marketing landing page or a decorative dashboard.

Design copy may be warm on Today and quiet states. Controls, validation, logs,
tables, and permission messages must stay plain.

## Color Tokens

Flutter uses Material 3 token mapping, but product tokens remain the source of
truth. The palette keeps the current warm assistant mood while avoiding a
beige-only screen. Semantic hues must be visible in charts, status chips, and
action priority.

| Token | Light | Dark | Usage |
| --- | --- | --- | --- |
| `mavra.canvas` | `#F5EFE6` | `#211A16` | App background |
| `mavra.surface` | `#FFFBF4` | `#2B221C` | Main surfaces |
| `mavra.surfaceRaised` | `#FFFFFF` | `#352A23` | Dialogs, tables, menus |
| `mavra.surfaceSoft` | `#EFE7DC` | `#2F261F` | Navigation, grouped panels |
| `mavra.ink` | `#33251B` | `#F7F0E4` | Primary text |
| `mavra.muted` | `#705947` | `#C9B8A5` | Secondary text |
| `mavra.border` | `#D8C8B6` | `#5A4638` | Structural borders |
| `mavra.primary` | `#7E976B` | `#B8CDA5` | Calm primary action |
| `mavra.action` | `#2563EB` | `#93C5FD` | Explicit command action |
| `mavra.home` | `#0F766E` | `#5EEAD4` | Home Assistant state |
| `mavra.price` | `#C05621` | `#FDBA74` | Price opportunity |
| `mavra.job` | `#7C3AED` | `#C4B5FD` | Job opportunity |
| `mavra.info` | `#0369A1` | `#7DD3FC` | Neutral system info |
| `mavra.success` | `#15803D` | `#86EFAC` | Healthy, complete |
| `mavra.warning` | `#B45309` | `#FCD34D` | Needs review soon |
| `mavra.danger` | `#B91C1C` | `#FCA5A5` | Failed, blocked, urgent |

Rules:

- Use `mavra.action` for commands where the user explicitly starts work.
- Use `mavra.primary` for calm, recommended next actions.
- Use semantic colors only when state carries meaning.
- Charts must use at least three distinguishable hues before repeating shade.
- Do not use purple gradients, decorative orbs, bokeh, or one-hue dashboards.
- Letter spacing is always `0`.

## Typography

Flutter text roles map to Material roles while preserving the current Chinese
and English reading feel.

| Role | Flutter token | Size | Weight | Usage |
| --- | --- | ---: | ---: | --- |
| `display` | `displaySmall` | 34 | 500 | Today headline, never table panels |
| `title` | `headlineSmall` | 24 | 600 | Page title |
| `sectionTitle` | `titleMedium` | 18 | 600 | Section header |
| `cardTitle` | `titleSmall` | 15 | 600 | Compact panel title |
| `body` | `bodyMedium` | 14 | 400 | Default UI text |
| `small` | `bodySmall` | 13 | 400 | Helper text |
| `caption` | `labelSmall` | 12 | 500 | Labels, chips, metadata |
| `data` | custom mono | 13 | 500 | Numeric cells, timestamps, cron |

Font stack:

- Body/UI: `Noto Sans SC`, `Microsoft YaHei`, system sans-serif.
- Display: `Noto Serif SC`, Georgia, serif when bundled locally.
- Data/code: `JetBrains Mono`, `Consolas`, monospace.

Implementation rules:

- No remote font runtime dependency.
- No viewport-width font scaling.
- Support 200 percent text scale without clipping buttons, tabs, or table rows.
- Table numbers use tabular figures where available.

## Spacing And Density

Base spacing unit: `4 px`.

| Token | Value | Usage |
| --- | ---: | --- |
| `space.1` | 4 | Icon gaps, dense metadata |
| `space.2` | 8 | Chips, compact controls |
| `space.3` | 12 | Form rows, list rows |
| `space.4` | 16 | Card internals |
| `space.6` | 24 | Section gaps |
| `space.8` | 32 | Page rhythm |
| `space.12` | 48 | Today desktop composition |

Density modes:

| Mode | Platforms | Row height | Control height | Page padding |
| --- | --- | ---: | ---: | ---: |
| `mobileComfort` | Android, iOS narrow | 56 | 44 | 16 |
| `tabletComfort` | tablet, foldable | 52 | 44 | 20 |
| `desktopCompact` | Web, Windows | 40 | 36 | 24 |
| `desktopDense` | Admin, logs, data tables | 36 | 32 | 24 |

Shape:

- Operational cards, tables, side panels: `8 px`.
- Inputs, selects, segmented controls: `8 px`.
- Dialogs and drawers: `12 px`.
- Today summary feature panel: up to `16 px` because the approved design uses a
  warmer first-screen composition.
- Chips and icon buttons may be pill-shaped.

Page sections are not floating cards. Cards are for repeated items, dialogs,
tables, and framed tools.

## Motion

Motion is quiet and low-frequency.

| Token | Duration | Usage |
| --- | ---: | --- |
| `motion.fast` | 120 ms | Button feedback, chip state |
| `motion.page` | 180 ms | Route content fade |
| `motion.panel` | 220 ms | Drawer/dialog entrance |
| `motion.slow` | 280 ms | Today attention entrance |

Rules:

- Respect reduced-motion by removing page and attention entrance movement.
- Avoid bouncing, springy layout shifts, or background animation.
- Loading state skeletons must not resize the page once data arrives.
- Realtime updates may use a soft status color wash, not a moving badge.

## Accessibility Checklist

Every screen must pass this checklist before a route can leave the parity
checklist:

- Touch targets are at least `44 x 44 px` on Android and iOS.
- Desktop icon buttons have tooltips and semantic labels.
- Contrast is at least `4.5:1` for body text and controls.
- Keyboard traversal order follows visual order on Web and Windows.
- Data tables expose row count, column labels, sort state, and selected rows.
- Charts have a text summary and accessible data table fallback.
- Status chips expose state text, not only color.
- Realtime banners expose connected/disconnected state.
- Form errors are attached to their fields.
- Text scale at 200 percent does not overlap or hide controls.
- Reduced-motion mode removes non-essential transitions.

## Component Specs

### Responsive Shell

- Web and Windows: fixed top app bar plus adaptive side navigation.
- Desktop side navigation uses labels when width is `>= 1024 px` and icon rail
  when width is below that.
- Mobile: bottom navigation for high-frequency destinations plus a More sheet.
- Today remains the initial authenticated destination on all platforms.
- Admin and Blog are never primary mobile tabs.

### NavigationRail And Side Navigation

Primary destinations:

1. Today
2. Prices
3. Jobs
4. Home
5. Rules
6. Activity
7. Analytics
8. Settings

Admin destinations are permission-gated management entries:

- Users
- Audit Logs
- Blog Studio

### Bottom Navigation

Mobile tabs:

1. Today
2. Prices
3. Jobs
4. Home
5. More

More contains Rules, Activity, Analytics, Settings, Profile, and permission-gated
Admin/Blog entries.

### Data Table

Use Flutter table components only when they support:

- horizontal scroll on mobile;
- sticky header on Web/Windows where useful;
- row selection;
- compact row density;
- semantic column labels;
- keyboard focus per row action;
- empty, error, and permission panels inside the table frame.

Action icons:

- view/open: icon button with tooltip;
- edit: icon button with tooltip;
- delete: destructive icon button plus confirmation;
- crawl/run/test: text button with icon because the command is domain-specific.

### Filter Bar

- Web/Windows: filters sit above the table in one dense row with wrap.
- Mobile: filters collapse into a bottom sheet.
- Search input uses debounce and exposes a clear action.
- Active filters render as removable chips.

### Form Field

- Labels are visible, never placeholder-only.
- Required fields announce required state.
- Validation copy is concrete and recoverable.
- Password/token fields never reveal secret values in logs or screenshots.

### Status Chip

Chip text is the state. Color is secondary.

Examples:

- `安静运行`
- `需要看看`
- `未启用`
- `Connected`
- `Offline`
- `Draft`
- `Published`

### Attention Item

Used on Today only.

Fields:

- life-context label: `今天`, `稍后`, `早晨`;
- concise title;
- reason;
- metric;
- source marker;
- one primary action;
- optional defer action.

### Quiet State

Quiet is not empty. It is a first-class successful state.

Approved copy examples:

- `没有需要你立刻处理的事。`
- `价格还没有到你设的目标。`
- `今天没有新的高匹配职位。`
- `家里设备都在安静运行。`

### Dialog

- Dialog width is constrained by content.
- Destructive dialogs name the affected object.
- Forms in dialogs keep primary action in the bottom-right on desktop and full
  width at the bottom on mobile.
- Escape closes non-destructive dialogs on Web/Windows.

### Toast And Snackbar

- Use snackbars for transient success and recoverable errors.
- Long-running crawl/run commands use a persistent in-progress banner or task
  row, not only a toast.
- Errors from the backend envelope show `message`; diagnostic details expose
  `trace_id` in a copyable secondary area.

### Chart Palette

Chart colors must use semantic meaning where possible:

- price movement: `mavra.price`;
- job match: `mavra.job`;
- home state: `mavra.home`;
- success/warning/danger for health;
- neutral comparison series from `mavra.info` and muted grays.

Charts never rely on color alone.

### File Picker Panel

Used for profile backup import/export, batch import, and blog media upload.

- Web: browser file picker and download behavior.
- Android/iOS: system picker and share sheet where supported.
- Windows: native open/save dialogs.
- File names and sizes are visible before upload.
- Password-protected profile backups require a visible password field and
  confirmation action.

### Permission Panel

Permission failures should be explicit in Flutter.

Fields:

- title: `没有权限访问此功能`
- body: name the destination and required permission group in plain language;
- primary action: return to Today or request admin help;
- secondary action: open Profile or Settings when relevant.

## Platform Density Rules

### Web

- Favor scan density over large marketing composition.
- Browser URL mirrors route state.
- Tables and editors may use the full viewport width.
- Hover and keyboard affordances are required.

### Windows

- Minimum supported window size: `1100 x 720`.
- Preferred layout mirrors Web compact density.
- Context menus are allowed for row actions but must duplicate visible actions.
- Keyboard shortcuts must never hide required buttons.

### Android And iOS

- Primary workflows fit thumb navigation.
- Dense tables become horizontal scroll plus detail sheets.
- Risky service calls and destructive actions require confirmation.
- Safe areas are respected.
- Bottom navigation and sheets must not cover form fields when the keyboard is
  open.

