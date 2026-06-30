# Flutter Migration Final Verification Report

Date: 2026-06-18
Worktree: `C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement`
Branch: `codex/flutter-full-replacement`

## Verdict

**Current supported-platform gates are final-green after Task 17 supported-device revalidation and the 2026-06-18 Gate 06 review follow-up.**

Gates 01-06 were executed and are green or explicitly deferred as planned. The Windows release white-screen blocker found during Gate 05 no longer reproduces after the current release rebuild; the release executable renders the login shell from its release directory and the authenticated visual harness renders protected pages. The high-severity FileService runtime finding from Gate 06 is fixed with a real `file_selector`-backed platform implementation. Default `AuthController` startup restore now loads the injected or platform-selected repository before route guarding. The final Gate 06 review follow-up on 2026-06-18 also resolved generated-client auth refresh, `/settings` over-gating, dangerous-action permission gating, and WeChat temporary-token exposure.

iOS remains deferred by the Windows-only environment constraint and is not counted as a current blocker.

No automated gate triggered real crawling, Profile login/import/export, job matching, or Home Assistant service calls.

Task 16 revalidated the React-to-Flutter feature parity surface after restoring
the global shell and expanding Products, Jobs, Schedule, Events, Admin, Blog,
and Smart Home workflows. The current Web main build no longer stalls on the
startup restore shell for the Web cookie-token policy; Web local restore is
skipped because no JS-readable refresh token is available under that policy.
Native and Windows secure-storage restore remains enabled.

Task 17 revalidated the current Flutter parity work on Web, Windows, and Android
emulator. The Web release build, Windows release build, Android release APK,
Flutter full test suite, analyzer, Windows integration smoke, and Android
emulator integration smoke all passed on 2026-06-18. iOS remains deferred by
environment constraint.

## Task 17: Full React Parity Baseline

Baseline captured on 2026-06-18 before Task 17 production-code changes.

Worktree state:

- Branch: `codex/flutter-full-replacement`.
- Existing unrelated dirty files left untouched: `AGENTS.md`, `CLAUDE.md`.

Commands run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement
git branch --show-current
git status --short
npx gitnexus analyze

cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\frontend
flutter test
flutter analyze
```

Results:

- GitNexus indexed the repository successfully: `10,467 nodes`, `19,220 edges`, `418 clusters`, `300 flows`.
- GitNexus reported that optional grammar `tree-sitter-dart` is unavailable, so Dart files are not parsed for symbol-level impact. Task 17 Dart changes must compensate with source review, widget tests, `flutter analyze`, focused builds, and `mcp__gitnexus.detect_changes` on staged diffs before commits.
- Flutter tests passed: `87` tests, `All tests passed!`.
- Flutter analyzer passed: `No issues found!`.
- No automated baseline command triggered real crawling, Profile login/import/export, job matching, or Home Assistant service calls.

## Task 17: Supported Platform Revalidation

Commands run on 2026-06-18:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/.worktrees/flutter-full-replacement/frontend
flutter test
flutter analyze
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
python -m http.server 4173 --bind 127.0.0.1 -d build/web
flutter test integration_test/app_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter test integration_test/auth_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter test integration_test/platform_capability_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter emulators --launch Pixel_10_Pro_XL
flutter devices
flutter test integration_test/app_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter test integration_test/auth_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter test integration_test/platform_capability_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s emulator-5554 shell monkey -p com.example.mavra_frontend -c android.intent.category.LAUNCHER 1
```

Results:

- Flutter tests passed: `112` tests, `All tests passed!`.
- Flutter analyzer passed: `No issues found!`.
- Web release build passed: `Built build\web`; Wasm dry run succeeded.
- Web release smoke passed in Microsoft Edge against `http://127.0.0.1:4173`: Flutter runtime mounted, screenshot rendered the login shell, and no console/page errors were captured. Text extraction is not used as evidence because Flutter Web renders this build through its Flutter surface rather than normal DOM text nodes.
- Windows release build passed: `Built build\windows\x64\runner\Release\mavra_frontend.exe`.
- Windows integration smoke passed for `app_smoke_test.dart`, `auth_smoke_test.dart`, and `platform_capability_smoke_test.dart`.
- Windows release executable rendered a nonblank app window with the global React-parity shell navigation visible. The captured state restored a native session and showed `Today could not load` because the release app was not connected to a seeded backend snapshot; this is not a white-screen regression.
- Android release APK build passed: `Built build\app\outputs\flutter-apk\app-release.apk (56.9MB)`.
- Android device was available as `emulator-5554`, Android 16 / API 36.
- Android `app_smoke_test.dart` had one initial VM service WebSocket startup failure immediately after emulator launch, then passed on rerun without code changes. `auth_smoke_test.dart` and `platform_capability_smoke_test.dart` passed.
- Android release APK installed and launched to the login shell on the emulator.
- No automated command triggered real crawling, real Profile login/import/export, real job matching, or Home Assistant service calls.

New evidence:

- `docs/flutter-migration/evidence/web-release-login.png`
- `docs/flutter-migration/evidence/windows-release-app.png`
- `docs/flutter-migration/evidence/android-emulator-release.png`

## Gate Summary

| Gate                          | Status                                         | Evidence                                                                                                                                            |
| ----------------------------- | ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| 01 Backend pytest             | Passed                                         | `737 passed, 23 skipped, 54 warnings in 41.19s`                                                                                                     |
| 02 Android emulator smoke     | Passed                                         | APK build passed; Android emulator single-file integration smoke passed; release APK launch screenshot captured                                     |
| 03 iOS deferred               | Deferred                                       | Windows host has no macOS/Xcode/iPhone capacity; iOS is not counted as a current blocker                                                            |
| 04 Web integration workaround | Passed with accepted exception                 | Web build passed; Edge release smoke and screenshot passed; `flutter test integration_test -d chrome` remains an accepted Flutter tooling exception |
| 05 Web/Windows visual QA      | Passed                                         | Web release login screenshot, Windows release app screenshot, and existing authenticated visual QA evidence captured                                |
| 06 Independent code review    | Completed, findings resolved at review surface | FileService, Windows release, native repository storage, default auth restore, Web font fallback, and authenticated visual QA findings are resolved |

## Task 16: React Feature Parity Revalidation

Commands run on 2026-06-18:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/.worktrees/flutter-full-replacement/frontend
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --no-web-resources-cdn
flutter build web -t lib/main_visual_qa.dart --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --no-web-resources-cdn
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter test integration_test/app_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter test integration_test/auth_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter test integration_test/platform_capability_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter test integration_test -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Results:

- Flutter analyzer: `No issues found`.
- Flutter tests: `87` tests passed.
- Web main build passed and was served through a local SPA fallback server.
- Web main smoke passed in Chrome: `/login` rendered the login shell; `/today` while unauthenticated redirected to `#/login`; no console/page/request errors were captured.
- Web visual QA harness captured current screenshots for Today, Dashboard, Events, Jobs, Products, Schedule, Smart Home, Admin Users, Audit Logs, Blog, and Settings.
- A visual regression found during this pass, Smart Home title wrapping vertically on desktop, was fixed by removing the stale page-local shell/header constraint and recapturing `web-visual-smart-home.png`.
- Windows release build passed: `Built build\windows\x64\runner\Release\mavra_frontend.exe`.
- Windows integration smoke passed for `app_smoke_test.dart`, `auth_smoke_test.dart`, and `platform_capability_smoke_test.dart`.
- Android release APK build passed: `Built build\app\outputs\flutter-apk\app-release.apk (55.2MB)`.
- Android emulator folder-level integration smoke passed: `3` tests.
- The auth smoke now injects a fake Today repository so login smoke does not depend on a real backend dashboard request on Android.

New screenshot evidence:

- `docs/flutter-migration/screenshots/2026-06-18/task16/web-main-login.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-main-today-redirect.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-today.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-dashboard.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-events.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-jobs.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-products.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-schedule.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-smart-home.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-admin-users.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-admin-audit-logs.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-admin-blog.png`
- `docs/flutter-migration/screenshots/2026-06-18/task16/web-visual-settings.png`

## Gate 01: Backend Pytest

Environment:

- PostgreSQL database: `pricemonitor_pytest`
- Redis database: `15`
- Credentials were supplied through local environment variables and are not recorded in this report.

Commands run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/.worktrees/flutter-full-replacement/backend
uv run --extra dev alembic upgrade head
uv run --extra dev python -m pytest tests/test_api_v1_routes.py tests/test_audit_best_effort.py -q
uv run --extra dev python -m pytest tests/test_crawl_task_store.py -q
uv run --extra dev python -m pytest
uv run --extra dev python -m ruff check .
uv run --extra dev python -m pytest tests/test_worker_enqueue_only.py -q
```

Results:

- Route/audit focused tests: `15 passed, 3 warnings in 2.00s`
- Crawl task store tests: `9 passed in 1.34s`
- Full backend pytest: `737 passed, 23 skipped, 54 warnings in 41.19s`
- Backend ruff: `All checks passed`
- Worker enqueue targeted tests after import sorting: `2 passed in 1.20s`

Backend files changed during Gate 01:

- `backend/alembic/env.py`
- `backend/tests/test_api_v1_routes.py`
- `backend/tests/test_audit_best_effort.py`
- `backend/tests/test_crawl_task_store.py`
- `backend/tests/test_worker_enqueue_only.py`

Root cause fixed during this pass:

- `tests/test_crawl_task_store.py::test_recover_stale_running_tasks_marks_failed` asserted that a global stale-task recovery function recovered exactly one row while sharing a real test database with other tests. The test now verifies it is running against a test database and clears `crawl_tasks` before creating its own stale row.

## Gate 02: Android Emulator Smoke

Device:

- AVD: `Pixel_10_Pro_XL`
- Device id: `emulator-5554`
- Runtime: Android 16 / API 36
- Flutter: `3.44.2`
- Android SDK: `36.1.0`

Commands run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/.worktrees/flutter-full-replacement/frontend
flutter doctor -v
flutter devices --device-timeout 120
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter test integration_test/app_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter test integration_test/auth_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter test integration_test/platform_capability_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter test integration_test -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Results:

- `flutter doctor -v`: no issues found.
- `flutter devices`: Android emulator visible as `emulator-5554`.
- APK build: `Built build\app\outputs\flutter-apk\app-release.apk (54.4MB)` after the default auth restore and bundled Roboto updates.
- Individual Android integration tests: all passed.
- Folder-level Android integration smoke: `3` tests passed, rerun after the FileService implementation.
- Release APK manual launch: login shell rendered after installing `app-release.apk`.
- Android SDK Platform 34 was installed with `sdkmanager --install "platforms;android-34"` because the pinned `file_selector_android` implementation compiles against API 34.

Screenshots:

- `docs/flutter-migration/screenshots/2026-06-17/android-release-launch-20s.png`
- `docs/flutter-migration/screenshots/2026-06-17/android-emulator-smoke-portrait.png`
- `docs/flutter-migration/screenshots/2026-06-17/android-emulator-smoke-rotated.png`

## Gate 03: iOS Deferred

iOS remains deferred for this phase.

Reason:

- Current host OS is Windows.
- No macOS runner, Xcode installation, simulator, signing setup, or iPhone is available in this environment.

Future commands once macOS capacity exists:

```bash
flutter build ios --no-codesign --dart-define=API_BASE_URL=/api/v1
flutter test integration_test/app_smoke_test.dart -d <ios-simulator-id> --dart-define=API_BASE_URL=/api/v1
flutter test integration_test/auth_smoke_test.dart -d <ios-simulator-id> --dart-define=API_BASE_URL=/api/v1
flutter test integration_test/platform_capability_smoke_test.dart -d <ios-simulator-id> --dart-define=API_BASE_URL=/api/v1
```

## Gate 04: Web Integration Workaround

Commands run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/.worktrees/flutter-full-replacement/frontend
flutter build web --dart-define=API_BASE_URL=/api/v1
flutter build web --dart-define=API_BASE_URL=/api/v1 --no-web-resources-cdn
flutter test integration_test -d chrome
cd C:/Users/arfac/Documents/mavra-monitor-system/.worktrees/flutter-full-replacement/backend
uv run --extra dev python ../scripts/check_dart_api_usage.py
```

Results:

- Web build passed: `Built build\web`; Wasm dry run succeeded.
- Web build was rerun after the FileService dependency and default auth restore updates and passed.
- Web build was rerun after bundling Roboto as an app font and passed. This avoids blocking the CanvasKit first frame on the default remote Roboto fallback download.
- Local SPA fallback server returned `200` for `/login`.
- Chrome opened `/login`, direct `/today`, refresh, and browser back successfully.
- `/today` while unauthenticated normalized to the login route.
- Console output contained only Flutter loader debug messages during route smoke.
- `flutter test integration_test -d chrome` failed with the expected tool limitation: `Web devices are not supported for integration tests yet.`
- Dart API usage validation passed.

Screenshots:

- `docs/flutter-migration/screenshots/2026-06-17/web-login.png`
- `docs/flutter-migration/screenshots/2026-06-17/web-today-direct.png`
- `docs/flutter-migration/screenshots/2026-06-17/web-login-mobile-390x844.png`
- `docs/flutter-migration/screenshots/2026-06-17/web-today-mobile-redirect-390x844.png`

Limitations:

- Browser automation could not use Flutter Web semantic selectors for form submission.
- API path evidence for this gate is from `scripts/check_dart_api_usage.py` and source inspection, not a captured login network request.

## Gate 05: Web And Windows Visual QA

Commands run:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/.worktrees/flutter-full-replacement/frontend
flutter build web --dart-define=API_BASE_URL=/api/v1
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter test integration_test/app_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter test integration_test/auth_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter test integration_test/platform_capability_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Results:

- Web build passed, including the rerun after default auth restore wiring.
- Windows build passed: `Built build\windows\x64\runner\Release\mavra_frontend.exe`, including the rerun after default auth restore wiring.
- Windows integration smoke single-file runs passed:
  - `app_smoke_test.dart`
  - `auth_smoke_test.dart`
  - `platform_capability_smoke_test.dart`
- Windows platform capability smoke was rerun after the FileService implementation and passed.
- Windows release visual QA for the unauthenticated login shell passed: launching `mavra_frontend.exe` from its release directory renders the login shell after 15 seconds.

Screenshot evidence:

- Web Auth login: `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-auth-login.png`
- Web authenticated desktop: `web-today.png`, `web-analytics.png`, `web-products.png`, `web-jobs.png`, `web-smart-home.png`, `web-settings.png`, `web-admin-users.png`, `web-admin-audit-logs.png`, `web-admin-blog.png`
- Web authenticated mobile: `web-today-mobile.png`, `web-settings-mobile.png`, `web-admin-users-mobile.png`
- Windows Auth login: `docs/flutter-migration/screenshots/2026-06-17/visual-qa/windows-auth-login.png`
- Windows authenticated desktop: `windows-today.png`, `windows-analytics.png`, `windows-settings.png`, `windows-admin-users.png`
- Historical Windows white-screen repro: `docs/flutter-migration/screenshots/2026-06-17/windows-release-screen-workingdir.png`

Visual QA notes:

- Web screenshots were captured from a local SPA fallback server serving `build\web`.
- Windows screenshots were captured from `build\windows\x64\runner\Release\mavra_frontend.exe` using fixed 1440x1000 client-area captures.
- Products and Smart Home can still request Noto fallback fonts after first frame for symbols/CJK glyphs, but they no longer block initial rendering. Roboto is bundled in the app to avoid the previous CanvasKit first-frame hang on remote Roboto fallback.
- Screenshot non-blank checks were run over all Web/Windows visual QA PNGs.

## Gate 06: Independent Code Review

Review range:

```text
6ba643b4..b4af331d
```

Commands run:

```powershell
git show -s --oneline 6ba643b4
git show -s --oneline b4af331d
git diff --stat 6ba643b4..b4af331d -- frontend .github docs doc backend
git diff --name-only 6ba643b4..b4af331d -- frontend .github docs doc backend
```

Review report:

- `docs/flutter-migration/final-code-review-report.md`

Default auth restore follow-up:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/.worktrees/flutter-full-replacement/frontend
flutter test test/features/auth/auth_flow_test.dart
flutter test test/app_smoke_test.dart test/features/auth/auth_flow_test.dart
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=/api/v1
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Results:

- Auth flow targeted tests passed after adding repository-backed save/load/logout coverage.
- The default app now restores a saved session before route guarding and preserves a protected initial route (`/settings`).
- Full Flutter analyzer passed: `No issues found`.
- Full Flutter tests passed: `87` tests.
- Web, Windows, and Android builds passed after the auth restore change.
- Gate 06 follow-up fixes on 2026-06-18 passed:
  - `flutter test test/core/auth/auth_repository_test.dart test/core/api/authenticated_mavra_api_test.dart test/features/auth/auth_api_test.dart test/features/auth/auth_flow_test.dart`
  - `flutter test test/features/products/products_page_test.dart test/features/jobs/jobs_page_test.dart test/features/schedule/schedule_page_test.dart test/features/smart_home/smart_home_page_test.dart`
  - `flutter test test/app_shell_navigation_test.dart`
  - `flutter test`
  - `flutter analyze`
  - `flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1`
  - `flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1`
- Gate 06 follow-up outcomes:
  - Generated OpenAPI client requests now refresh expired sessions and retry once.
  - `/settings` now remains reachable for authenticated users without `config:read`, while server-backed config editing remains gated.
  - Products crawl-now, Jobs crawl/match/profile session actions, Schedule editing, and Smart Home control/config actions now honor explicit frontend permissions.
  - WeChat callback no longer renders the temporary token in the UI, and the exchange is deferred until after the first frame to avoid router rebuild warnings.
  - Full Flutter test suite passed with `121` tests.

Decision:

- Code-review findings are resolved at their stated surface. Current supported-platform final gates are green. iOS remains deferred until macOS capacity exists.

## 2026-06-24 Flutter Replacement Follow-up

Commit:

```text
1ffdaa9d Finalize Flutter replacement UI parity
```

Scope:

- Restored the remaining Flutter parity pages and visual cleanup for Today,
  Dashboard, Events, Jobs, Products, Schedule, Smart Home, Blog Admin, Users,
  and Audit Logs.
- Standardized page banners, compact controls, and product-style tables across
  the restored management pages.
- Hardened admin user enable/disable/delete handling so the current or last
  active `super_admin` cannot be disabled or deleted from the UI or backend.
- Hardened native session restore: expired local sessions now refresh before
  route guarding, and refresh failures clear local state and return to login
  instead of leaving a protected page in a loading state.

Verification:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/.worktrees/flutter-full-replacement/frontend
flutter test test/core/auth/auth_repository_test.dart test/features/auth/auth_flow_test.dart
flutter analyze
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
git diff --check
```

Results:

- Targeted auth tests passed.
- Flutter analyzer passed.
- Windows release build passed and produced
  `build\windows\x64\runner\Release\mavra_frontend.exe`.
- `git diff --check` reported only existing CRLF whitespace warnings.
