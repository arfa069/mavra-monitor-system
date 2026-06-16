# Final Gate 05: Web And Windows Visual QA Plan

> **For agentic workers:** use the approved screen references as the visual baseline. Screenshots are evidence for this gate, not optional decoration.

## Goal

Complete screenshot-based visual QA for Flutter Web and Flutter Windows release builds using `docs/flutter-migration/flutter-approved-screen-references.md` as the reference list.

## Required Builds

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
flutter build web --dart-define=API_BASE_URL=/api/v1
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Run the Windows release app from:

```powershell
C:/Users/arfac/Documents/mavra-monitor-system/frontend/build/windows/x64/runner/Release/mavra_frontend.exe
```

Serve Web with the SPA fallback server from `docs/flutter-migration/final-gate-04-web-integration-workaround-plan.md`.

## Screenshot Set

Store screenshots under a dated folder:

```text
docs/flutter-migration/screenshots/<yyyy-mm-dd>/
```

Capture at least:

- Web desktop Today at 1440 x 900.
- Web mobile Today at 390 x 844.
- Windows Today at the minimum supported window size.
- Auth login shell on Web and Windows.
- Analytics or dashboard surface on Web and Windows.
- Admin or settings surface on Web and Windows.
- Dense Products or Jobs table on Web and Windows.
- Smart Home mobile layout on Web.
- Blog editor desktop layout if the Flutter build exposes it.
- Empty, error, loading, and permission-denied states for at least one representative data surface.
- Light and dark theme captures for Today plus one dense table surface.

## Visual Checks

Compare screenshots against `docs/flutter-migration/flutter-approved-screen-references.md` and check:

- Navigation remains reachable and visually consistent.
- Text does not overflow, overlap, or clip inside buttons, tables, cards, dialogs, or sidebars.
- Responsive breakpoints preserve readable hierarchy on mobile, desktop Web, and Windows.
- Modals, menus, snackbars, and overlays do not obscure required actions.
- Loading, empty, error, offline, and permission-denied states are recoverable.
- Data-dense tables remain scannable without horizontal layout breakage.
- Theme switching preserves contrast and state visibility.
- Windows window resizing does not move critical controls outside the viewport.
- Browser refresh and Windows relaunch keep auth and route state behavior understandable.

## Data And Safety Rules

- Prefer mocked fixtures or disposable local backend data for protected screens.
- Do not run real crawling.
- Do not perform real Profile login, import, export, or browser session mutation.
- Do not start job matching tasks.
- Do not call Home Assistant services.
- Label each screenshot with platform, route, viewport, theme, and data source in the report.

## Acceptance Criteria

- Required Web screenshots exist and are referenced from the final report.
- Required Windows screenshots exist and are referenced from the final report.
- Every visual issue has severity, platform, route, screenshot path, and owner decision.
- No severity high visual defect remains unresolved for Web, Windows, or Android-relevant responsive layouts.
- The final report states whether visual QA allows final merge.

## Evidence To Record

Update both files after this gate runs:

- `docs/flutter-migration/final-verification-report.md`
- `docs/flutter-migration/platform-verification-matrix.md`

Record:

- Build outputs used for screenshots.
- Screenshot folder path.
- Viewport and Windows size list.
- Visual issue table.
- Final Web/Windows visual QA decision.
