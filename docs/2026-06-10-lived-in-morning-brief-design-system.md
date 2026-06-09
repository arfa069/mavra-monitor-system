# Lived-In Morning Brief Design System

Date: 2026-06-10
Status: Proposed design direction
Project: Mavra Monitor System

## Product Context

Mavra Monitor System is moving from a backend-style monitoring dashboard toward a personal automation center. It watches prices, job opportunities, and Home Assistant entities, then tells the user only what is worth attention.

The selected memory is:

> It feels like a smart private assistant that does not interrupt you.

This design system should make the product feel warmer, more lived-in, and less like an operations console, while keeping hard data fast to scan when the user opens a table or configuration screen.

## Design Thesis

**Lived-In Morning Brief** turns the first screen into a quiet daily rhythm.

The app should not lead with KPIs, crawler internals, or device lists. It should lead with a short human summary:

> 家里已经醒了，机会也帮你看着。

The product should answer three questions before anything else:

1. Is everything quiet?
2. What actually deserves attention?
3. What can safely wait?

## Aesthetic Direction

Direction: Warm Editorial Utility

Decoration level: Intentional

Mood: warm, domestic, calm, attentive, precise

The interface should feel like a home surface or morning note, not a SaaS analytics wall. It can use paper-like surfaces, soft borders, rounded cards, warm light, and gentle status chips. The data should still remain crisp. A warm product that hides important details is cute, then useless. Not our goal.

## Safe Choices

- Keep clear module boundaries for prices, jobs, and smart home.
- Preserve dense table modes for watchlists, crawl logs, job lists, admin pages, and permissions.
- Use semantic statuses consistently so users can scan risk, opportunity, and quiet states.
- Keep primary actions predictable: view, save, snooze, run, configure.

These choices keep the product legible as a real monitoring tool.

## Creative Risks

- The home page becomes a daily brief instead of a dashboard wall.
- Navigation becomes more life-contextual, with "Today", "Watchlist", "Home", and "Rules" taking priority over implementation categories.
- Copy becomes warmer and more assistant-like, but only on summary surfaces.

The risk is that the app may feel softer than a normal technical dashboard. The gain is that the product finally has a face that matches the selected memory.

## Information Architecture

Primary navigation:

- Today
- Prices
- Jobs
- Home
- Rules
- Activity
- Settings

The old product areas still exist, but the first screen becomes Today.

### Today

Purpose: show the current rhythm of the user's day.

Recommended sections:

- Daily summary sentence
- Attention queue, limited to the most important 1-5 items
- Quiet status for modules with nothing urgent
- Next scheduled checks
- Recent assistant actions

Example:

> 今天只提醒 2 件事。一个商品到了心理价位，一个职位值得晚点打开。家里设备都在安静运行。

### Prices

Purpose: detailed product tracking.

Tone: precise, compact, transactional.

Keep tables, filters, price trend charts, crawler status, and item-level actions here. Warmth should appear through surfaces and empty states, not through hiding numbers.

### Jobs

Purpose: opportunity review.

Tone: focused, less mechanical than crawler logs.

Prioritize match quality, salary range, location, source, freshness, and next action.

### Home

Purpose: Home Assistant state and controls.

Tone: calm, room-based, safe.

Lead with rooms/scenes and recent changes. Advanced entity details stay one click deeper.

### Rules

Purpose: automation and monitoring configuration.

Tone: plain-language rule builder.

Rules should read like outcomes before settings:

- Tell me when a watched item drops below my target price.
- Show me jobs above my match threshold.
- Run evening mode when the house is quiet.

## Typography

Display:

- English: Newsreader
- Chinese: Noto Serif SC

Use for the Today summary, page-level warm headings, and empty states.

Body and UI:

- English: IBM Plex Sans
- Chinese: Noto Sans SC

Use for navigation, forms, tables, filters, and body copy.

Data and code:

- IBM Plex Mono

Use for prices, timestamps, scores, cron strings, logs, and IDs.

Scale:

| Token | Size | Weight | Usage |
| --- | ---: | ---: | --- |
| display-xl | 48px | 500 | Today summary on desktop |
| display-lg | 34px | 500 | Page title |
| title | 22px | 600 | Section title |
| card-title | 17px | 600 | Card title |
| body | 14px | 400 | Default UI text |
| small | 13px | 400 | Secondary text |
| caption | 12px | 500 | Labels and helper text |
| data | 13px | 500 | Numeric cells |

Rule: summary copy may be warm; control labels must stay plain.

## Color System

Approach: warm neutral base with natural status colors.

Core tokens:

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
- Single-hue beige-only screens
- Harsh black borders from the old neo-brutalist system
- Neon dark mode as the default personality

## Spacing And Shape

Base unit: 4px

Density modes:

- Warm default: comfortable, for Today and overview pages
- Compact: dense, for tables, admin, logs, and configuration

Spacing scale:

| Token | Value | Usage |
| --- | ---: | --- |
| xs | 4px | Tight icon/text gaps |
| sm | 8px | Chips, compact controls |
| md | 12px | Form rows, list rows |
| lg | 16px | Card internals |
| xl | 24px | Section gaps |
| 2xl | 32px | Page-level spacing |
| 3xl | 48px | Hero/Today composition |

Radius:

| Token | Value | Usage |
| --- | ---: | --- |
| sm | 10px | Inputs, chips |
| md | 16px | Table containers |
| lg | 24px | Cards |
| xl | 32px | Today hero panels |
| pill | 9999px | Chips and small action buttons |

Use soft shadows sparingly:

- `0 16px 50px rgba(92, 58, 29, 0.10)` for raised warm panels
- No heavy offset shadows
- No blur-heavy decorative blobs

## Layout

The first screen should be structured as a day rhythm:

1. Time and quiet badge
2. Human summary
3. Attention queue
4. Module status panel
5. Recent assistant actions

Desktop:

- Two-column layout: main rhythm and side status
- Max content width: 1280px
- Today page can be more spacious than operational pages

Mobile:

- Single-column feed
- Attention queue first
- Summary copy should wrap cleanly and never cover controls

Data-heavy pages:

- Use compact tables
- Keep filters sticky
- Prefer row actions over large card grids
- Charts should answer one question at a time

## Component Language

### Daily Summary

Large serif statement with one sentence. It should be specific, not motivational.

Good:

> 今天只提醒 2 件事。

Bad:

> Welcome back to your powerful dashboard.

### Attention Queue

A small ranked list of things worth attention.

Each item should include:

- life-context label, such as morning, today, later
- short plain-language reason
- source icon or module marker
- one primary action
- one defer action when useful

### Quiet State

Quiet is a first-class state, not an empty state.

Examples:

- 家里设备都在安静运行。
- 今天没有新的高匹配职位。
- 价格看守没有发现值得处理的变化。

### Rule Cards

Rules should be readable before editable.

Example:

> 当显示器低于 1299 元时提醒我。

Advanced configuration can expand below the plain sentence.

### Tables

Tables stay practical.

Use IBM Plex Mono for numbers, right-align numeric values, keep row height compact, and use color only for meaningful state.

## Motion

Approach: quiet, tactile, low-frequency.

Motion should make the assistant feel alive without making the app feel busy.

Rules:

- Page transitions: 180-240ms
- Card hover: small lift, 2-4px
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

## Migration From Current Design

The current `doc/DESIGN.md` defines Neo-Brutalist Zine: thick black borders, hard shadows, pop colors, Syne, Outfit, and Space Grotesk.

The new system deliberately changes the emotional center:

| Current | New |
| --- | --- |
| high contrast zine dashboard | warm lived-in assistant |
| hard black 3px borders | soft warm borders |
| pop color blocks | natural semantic color |
| loud hover movement | quiet tactile motion |
| dashboard-first | Today brief first |
| technical module naming | life-context summary first |

Implementation should not happen as a one-file token swap. The homepage composition, navigation language, empty states, and table density need to change together.

## Rollout Plan

1. Update design source of truth.
2. Add new CSS tokens beside the existing token file.
3. Redesign the app shell and Today page first.
4. Convert shared cards, chips, buttons, tables, and status components.
5. Migrate Prices, Jobs, and Home pages module by module.
6. Run browser QA against desktop and mobile.
7. Remove old neo-brutalist-only tokens after all active surfaces are migrated.

## Acceptance Criteria

- The first screen communicates quiet/attention status without showing a KPI wall.
- Prices, jobs, and smart-home state are still reachable in one click.
- Data-heavy pages remain faster to scan than the current card-heavy style.
- The product does not look like generic SaaS, Apple Home, Notion, or Home Assistant.
- Empty states are calm and useful.
- Tables and forms remain dense enough for repeated operational work.
- Visual QA verifies desktop and mobile layouts.

## Open Decisions

- Whether `Today` replaces `/dashboard` or becomes the new root route.
- Whether the old dashboard remains as an advanced analytics page.
- Whether dark mode should be a true evening mode or a simple inverted theme.
- Whether the product name should appear as Mavra, Mavra Monitor, or a more personal assistant name in UI copy.

## Recommendation

Proceed with Lived-In Morning Brief as the new design system direction.

The strongest version is not "more lifestyle app everywhere." It is warm on the first touch, precise on demand. That is the product promise: Mavra watches quietly, then only speaks when something is worth your attention.
