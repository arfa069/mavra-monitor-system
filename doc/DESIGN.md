# Design System - Mavra Monitor System

## Product Context

Mavra is an operational monitor for prices, jobs, schedules, activity, and Home
Assistant state. The app should now read like a MiniMax-inspired product
showcase first, then settle back into dense operational tools below the fold.

## Design Thesis

Mavra uses the MiniMax reference directly for its first impression: stark
black-and-white structure, oversized DM Sans display type, black pill CTAs,
32px colorful product identity cards, and a dark brand rail. Large content
surfaces stay light in the default theme; dense tables, forms, and logs remain
compact once the user is doing operational work.

The default app theme is Light, matching the white MiniMax content canvas.
Dark theme is available only through the account menu toggle; the app should
not silently switch to dark just because the OS/browser preference is dark.

## Core Tokens

| Token           | Value     | Use                                        |
| --------------- | --------- | ------------------------------------------ |
| `primary`       | `#0A0A0A` | Main CTA, active pill tabs                 |
| `canvas`        | `#FFFFFF` | Primary app surface                        |
| `surfaceSoft`   | `#F7F8FA` | Scaffold background, subtle bands          |
| `surfaceMuted`  | `#F2F3F5` | Selected nav, quiet panels                 |
| `hairline`      | `#E5E7EB` | Inputs, cards, table borders               |
| `ink`           | `#0A0A0A` | Primary text                               |
| `steel`         | `#5F5F5F` | Secondary text                             |
| `focusBlue`     | `#1D4ED8` | Input focus and keyboard focus             |
| `brandCoral`    | `#FF5530` | Attention accents only                     |
| `brandMagenta`  | `#EA5EC1` | Showcase gradients and model-card energy   |
| `brandBlue`     | `#1456F0` | Jobs/showcase identity                     |
| `brandBlueDeep` | `#1D4ED8` | Products/showcase identity                 |
| `brandBlue700`  | `#17437D` | Schedule/showcase identity                 |
| `brandCyan`     | `#3DAEFF` | Smart-home/showcase identity               |
| `brandBlue200`  | `#BFDBFE` | Light accent cards and admin/blog identity |
| `brandPurple`   | `#A855F7` | Admin/showcase identity                    |

Semantic colors stay meaningful: price uses orange, jobs use purple, Home
Assistant uses teal, success uses green, danger uses red.

## Typography

Use `DM Sans` for English UI and `NotoSansSC` as the Chinese fallback. Showcase
surfaces may use 80px, 56px, and 40px display steps. Body text uses 16px for
readability; compact labels use 12-14px. Letter spacing is always 0. Do not
scale type continuously with viewport width.

## Components

- First-viewport surfaces use light hero bands, black pill CTAs, and vivid
  product cards.
- Primary buttons are black pills with white text.
- Secondary buttons are outline pills; text buttons remain pill-shaped but flat.
- Icon buttons are circular 36px controls on desktop with tooltips.
- Inputs use 8px corners, white fill, hairline border, and blue 2px focus ring.
- Tables remain compact: 40px header, 44-48px body rows, flat border chrome.
- Cards use white surfaces, 8-16px corners, hairline borders, and no heavy
  shadows.
- Showcase/product cards use saturated coral, magenta, blue, purple, or teal
  identity color with 32px corners.
- Shared page banners are single-color Brand & Accent surfaces. Do not add the
  black `Mavra Intelligence Layer` promo strip above them.
- Page sections are not decorative nested cards; use cards only for repeated
  items, dialogs, and framed tools.

## Route Guidance

`/today` is the strongest MiniMax-style surface: light hero, oversized brand
headline, and a three-card product matrix for Price Monitor, Job Radar, and
Smart Home. The `/today` and `/dashboard` (Analytics) pages are fully translated to
English to align with the MiniMax stark design aesthetic and maintain clean presentation.
Products, Jobs, Smart Home, Events, Schedule, Admin, and Analytics
use the shared Brand & Accent banner at the top, then return to scannable
tools.

## Do Not

- Do not use showcase gradients or product-color blocks for ordinary controls.
- Do not reintroduce the old warm beige-only theme.
- Do not hand-edit generated OpenAPI/Dart client files for visual work.
- Do not trigger real crawl, profile login, worker, or Home Assistant actions
  for visual QA.

## QA Gate

Before shipping visual-system changes, run Flutter analysis, focused widget
tests, Web build, and mock visual QA through `main_visual_qa.dart`. Screenshots
must show no clipped button text, no overlapping controls, no unreadable table
rows, and no unexpected mobile layout at desktop width.
