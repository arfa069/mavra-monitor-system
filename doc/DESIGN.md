# Design System — Mavra Monitor System

## Product Context

Mavra Monitor System is a personal automation center for prices, job opportunities, and Home Assistant state.

It watches the user's world quietly, then surfaces only the changes worth attention. The product is no longer positioned as a backend dashboard first. It should feel like a smart private assistant that does not interrupt you.

## Design Thesis

**Lived-In Morning Brief:** Mavra watches quietly, then only speaks when something is worth attention.

The first screen should answer three questions:

1. Is everything quiet?
2. What actually deserves attention?
3. What can safely wait?

The product should feel warm on first touch and precise on demand. Today can read like a morning note. Tables, rules, logs, and admin screens must still scan like real tools.

## Non-Negotiables

- The first screen is Today, not a KPI wall.
- Summary surfaces may be warm and human.
- Tables, forms, logs, and admin pages stay compact and precise.
- Browser QA must flag UI that still looks neo-brutalist: hard black borders, pop color blocks, offset shadows, uppercase zine labels.
- Do not trigger real crawls or real smart-home service calls during visual QA.

## Aesthetic Direction

- **Direction:** Lived-In Morning Brief
- **Decoration level:** Intentional
- **Mood:** warm, domestic, calm, attentive, precise
- **Memorable thing:** It feels like a smart private assistant that does not interrupt you.

The interface should feel like a home surface or morning note, not a SaaS analytics wall. It can use warm paper-like surfaces, soft borders, rounded cards, gentle status chips, and calm motion. It must not hide important operational details.

## Typography

The target typography is editorial warmth plus utility precision.

- **Display:** Newsreader / Noto Serif SC where self-hosted assets are available. Fallback: Georgia, Songti SC, serif.
- **Body/UI:** IBM Plex Sans / Noto Sans SC where self-hosted assets are available. Fallback: Outfit, Microsoft YaHei, system sans-serif.
- **Data/Code:** IBM Plex Mono where self-hosted assets are available. Fallback: JetBrains Mono, monospace.

Current implementation must not add remote font runtime dependencies. If exact target fonts are needed, vendor the font files into `frontend/public/fonts` and declare them in `frontend/src/styles/fonts.css`.

### Type Scale

| Token | Size | Weight | Usage |
| --- | ---: | ---: | --- |
| display-xl | `48px` | 500 | Today summary on desktop |
| display-lg | `34px` | 500 | Page title |
| headline | `22px` | 600 | Section title |
| card-title | `17px` | 600 | Card title |
| body | `14px` | 400 | Default UI text |
| small | `13px` | 400 | Secondary text |
| caption | `12px` | 500 | Labels and helper text |
| data | `13px` | 500 | Numeric cells |

Rule: summary copy may be warm; control labels must stay plain.

## Color

Approach: warm neutral base with natural status colors.

| Token | Hex | Usage |
| --- | --- | --- |
| canvas | `#f3dfc8` | App background, warm base |
| surface | `#fff7ec` | Main cards and panels |
| surface-raised | `#ffffff` | Data cards, tables, dialogs |
| ink | `#33251b` | Primary text |
| muted | `#705947` | Secondary text |
| border | `rgba(93, 61, 38, 0.12)` | Soft structural border |
| sage | `#7e976b` | Quiet, healthy, running |
| clay | `#d9826b` | Attention, price movement, warm alert |
| mist | `#7aa2a4` | Home, ambient info |
| butter | `#fff1cf` | Gentle action chips |
| rose | `#f8d7c8` | Important but non-critical notice |

Semantic tokens:

| Token | Hex | Meaning |
| --- | --- | --- |
| success | `#7e976b` | Good state, completed, normal |
| warning | `#d89a57` | Needs review soon |
| danger | `#c75f4c` | Failed, blocked, urgent |
| info | `#7aa2a4` | Neutral system information |
| opportunity | `#d9826b` | Price/job opportunity worth attention |

Avoid:

- Purple gradients
- Beige-only screens with no contrast
- Harsh black borders from the old neo-brutalist system
- Neon dark mode as the default personality

## Spacing And Shape

- **Base unit:** `4px`
- **Default density:** comfortable for Today and overview pages
- **Compact density:** required for tables, admin pages, logs, and configuration

| Token | Value | Usage |
| --- | ---: | --- |
| xs | `4px` | Tight icon/text gaps |
| sm | `8px` | Chips, compact controls |
| md | `12px` | Form rows, list rows |
| lg | `16px` | Card internals |
| xl | `24px` | Section gaps |
| 2xl | `32px` | Page-level spacing |
| 3xl | `48px` | Today composition |

Radius:

| Token | Value | Usage |
| --- | ---: | --- |
| sm | `10px` | Inputs, chips |
| md | `16px` | Table containers |
| lg | `24px` | Cards |
| xl | `32px` | Today hero panels |
| pill | `9999px` | Chips and small action buttons |

Use soft shadows sparingly:

- `0 16px 50px rgba(92, 58, 29, 0.10)` for raised warm panels
- `0 24px 80px rgba(92, 58, 29, 0.12)` for Today hero panels
- No heavy offset shadows
- No decorative blurred blobs

## Layout

The first screen is `Today`.

Recommended structure:

1. Time and quiet badge
2. Human summary
3. Attention queue
4. Module status panel
5. Recent assistant actions

Desktop:

- Two-column layout: main rhythm and side status
- Max content width: `1280px`
- Today can be more spacious than operational pages

Mobile:

- Single-column feed
- Attention queue first
- Summary copy wraps cleanly and never covers controls

Data-heavy pages:

- Use compact tables
- Keep filters sticky when useful
- Prefer row actions over decorative card grids
- Charts should answer one question at a time

## Information Architecture

Primary navigation:

- Today
- Prices
- Jobs
- Home
- Rules
- Activity
- Analytics
- Settings

Keep `/dashboard` available as Analytics. Do not remove the current chart-heavy dashboard until Today is proven in daily use.

## Component Language

### Daily Summary

Large serif statement with one specific sentence.

Good:

> 今天只提醒 2 件事。

Bad:

> Welcome back to your powerful dashboard.

### Attention Queue

A ranked list of things worth attention.

Each item includes:

- life-context label, such as morning, today, later
- short plain-language reason
- source/module marker
- one primary action
- one defer action when useful

### Quiet State

Quiet is a first-class state, not an empty state.

Examples:

- 家里设备都在安静运行。
- 今天没有新的高匹配职位。
- 价格看守没有发现值得处理的变化。

### Rule Cards

Rules should read like outcomes before settings.

Example:

> 当显示器低于 1299 元时提醒我。

Advanced configuration can expand below the plain sentence.

### Tables

Tables stay practical. Use tabular numbers, right-align numeric values, keep row height compact, and use color only for meaningful state.

## Motion

Approach: quiet, tactile, low-frequency.

Rules:

- Page transitions: `180-240ms`
- Card hover: small lift, `1-2px`
- Attention item entrance: subtle fade and vertical movement
- Status changes: soft color wash, no bouncing
- Background animation: none by default

Easing:

- enter: `cubic-bezier(0.2, 0.8, 0.2, 1)`
- exit: `cubic-bezier(0.4, 0, 1, 1)`
- move: `cubic-bezier(0.2, 0, 0, 1)`

## Writing Style

The UI voice is warm but not cute.

Use:

- short sentences
- specific observations
- "worth looking at" language
- calm verbs like watching, running, quiet, ready, changed

Avoid:

- hype
- fake personality
- "AI assistant" theatrics
- jokes in operational states
- vague praise

Good examples:

- 今天只提醒 2 件事。
- 这个职位值得晚点打开。
- 客厅已经进入早晨模式。
- 价格还没有到你设的目标。

## Migration From Previous System

The old system was Neo-Brutalist Zine: thick black borders, hard shadows, pop colors, Syne, Outfit, and Space Grotesk.

The new system changes the emotional center:

| Previous | New |
| --- | --- |
| high contrast zine dashboard | warm lived-in assistant |
| hard black `3px` borders | soft warm `1px` borders |
| pop color blocks | natural semantic color |
| loud hover movement | quiet tactile motion |
| dashboard-first | Today brief first |
| technical module naming | life-context summary first |

Implementation should not be a one-file token swap. The homepage composition, navigation language, empty states, and table density need to change together.

## QA Checklist

- `/today` communicates quiet/attention status without showing a KPI wall.
- Prices, Jobs, and Home are reachable in one click.
- `/dashboard` remains available as Analytics.
- Dense tables remain faster to scan than card grids.
- Empty states are calm and useful.
- Mobile layout stacks without overlap.
- Browser QA uses mocked APIs only.
