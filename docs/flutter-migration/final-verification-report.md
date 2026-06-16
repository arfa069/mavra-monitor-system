# Flutter Final Verification Report

Date: 2026-06-16

Branch: `codex/flutter-full-replacement`

Worktree: `C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement`

## Verdict

Flutter Web and Windows are buildable and covered by analyzer, unit/widget
tests, API usage checks, and focused Windows integration smoke tests.

The full final gate is not completely green in this local environment. The
remaining blockers are local backend database credentials, unavailable Android
device/emulator evidence, unavailable iOS build support on Windows, unsupported
Flutter Web integration tests, missing Web/Windows screenshot comparison
evidence, and the separate final code-review pass.

## Backend Commands

| Command | Result |
| --- | --- |
| `uv run --extra dev python -m ruff check .` | Passed. |
| `uv run --extra dev python -m pytest` | Failed locally: 669 passed, 50 failed, 41 skipped, 51 warnings in 72.51s. |
| `uv run --extra dev python ../scripts/export_openapi.py` | Passed and exported `frontend/openapi.json`. |
| `uv run --extra dev python ../scripts/check_api_contract.py` | Passed, including Dart generator check. |
| `uv run --extra dev python ../scripts/check_dart_api_usage.py` | Passed. |

The full backend test failure is not attributed to Flutter code. Most failures
are database-backed crawler/profile/worker tests failing with
`asyncpg.exceptions.InvalidPasswordError` for local user `postgres`. Additional
local failures were reproduced in:

- `tests/test_api_v1_routes.py::test_only_canonical_business_routes_are_registered`:
  route inventory assertion assumes every `app.routes` item has `.path`, but an
  included router object does not.
- `tests/test_audit_best_effort.py`: login/logout best-effort audit tests fail
  locally with a `KeyError: 'username'` and a logout `403` while system-log DB
  writes also fail under the same local database authentication issue.

## Flutter Commands

| Command | Result |
| --- | --- |
| `flutter pub get` | Passed. |
| `flutter analyze` | Passed. |
| `flutter test` | Passed: 65 tests. |
| `flutter build web --dart-define=API_BASE_URL=/api/v1` | Passed after removing the unused `file_picker` dependency; Wasm dry run succeeded. |
| `flutter build windows --dart-define=API_BASE_URL=http://localhost:8000/api/v1` | Passed and produced `build\windows\x64\runner\Release\mavra_frontend.exe`. |
| `flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` | Passed and produced `build\app\outputs\flutter-apk\app-release.apk` at 53.8 MB. |

## Platform Builds

| Platform | Status | Evidence |
| --- | --- | --- |
| Web | Passed | `flutter build web --dart-define=API_BASE_URL=/api/v1`. |
| Windows | Passed | `flutter build windows --dart-define=API_BASE_URL=http://localhost:8000/api/v1`. |
| Android | Passed | `flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` passes after reinstalling local NDK `28.2.13676358`, installing CMake `3.22.1`, and removing the unused `file_picker` dependency that pulled an incompatible Android Gradle plugin. |
| iOS | Not run locally | Windows Flutter exposes no iOS build subcommand. The local help output lists `aar`, `apk`, `appbundle`, `bundle`, `web`, and `windows` only. macOS CI/simulator evidence is still required. |

## Integration Smoke

| Target | Command | Result |
| --- | --- | --- |
| Windows full set | `flutter test integration_test -d windows` | Partial: `app_smoke_test.dart` passed, then Flutter Windows test hosting failed to start the app for the next files. |
| Windows auth | `flutter test integration_test/auth_smoke_test.dart -d windows` | Passed. |
| Windows platform capability | `flutter test integration_test/platform_capability_smoke_test.dart -d windows` | Passed. |
| Web | `flutter test integration_test -d chrome` | Blocked by Flutter tool: `Web devices are not supported for integration tests yet.` |
| Android | `flutter test integration_test -d android` | Blocked locally: no supported Android device or emulator is connected. |
| iOS | Not run locally | Requires macOS simulator/CI runner. |

Automated smoke tests did not perform real crawls, profile logins, match jobs,
or Home Assistant service calls.

## Leftover Audit

| Check | Result |
| --- | --- |
| Legacy React app paths | Clean: `frontend/src`, `frontend/tests/e2e`, `frontend/tests/unit`, React `package.json`, Vite, Orval, TypeScript, ESLint, and Playwright app config files do not exist. |
| Active non-doc React/Vite/Orval references | Clean for the migrated app. The only non-doc `npm run` hits are `scripts/start_server.*` entries for the independent `blog-frontend`. |
| Legacy business `/v1` usage | Clean in `frontend/lib`, `frontend/test`, and `frontend/integration_test`. |
| Dart business API usage | Passed with `scripts/check_dart_api_usage.py`. |

## Android Environment Repair

The local Android blocker recorded during Task 15 was repaired after the
initial final report:

- The malformed `C:\Users\arfac\AppData\Local\Android\Sdk\ndk\28.2.13676358`
  directory only contained `.installer` and no `source.properties`.
- The damaged NDK directory was moved to
  `C:\Users\arfac\AppData\Local\Android\Sdk\_ndk_broken_backups`.
- `android-ndk-r28c-windows.zip` was downloaded directly from Google's Android
  repository and verified with SHA1
  `086BBA43FF2F5EB0E387B15C8278BB4E0D89BA1D`.
- NDK `source.properties` now reports `Pkg.Revision = 28.2.13676358`.
- The Android build then exposed a damaged CMake `3.22.1` SDK component; it was
  reinstalled from `cmake-3.22.1-windows.zip`, verified with SHA1
  `292778F32A7D5183E1C49C7897B870653F2D2C1B`.
- `flutter doctor -v` now reports no issues, Android SDK `36.1.0`, and all
  Android licenses accepted.
- The unused `file_picker` direct dependency was removed because it was not
  imported by Dart code and its Android Gradle plugin was incompatible with the
  current Gradle/AGP stack.

## Accessibility And Visual Status

Code-level accessibility evidence exists for shared semantics and touch target
minimums:

- `frontend/lib/core/widgets/async_state_view.dart` wraps async states in
  `Semantics`.
- `frontend/lib/core/theme/app_theme.dart` sets 44 px minimum filled and
  outlined button heights.
- `frontend/lib/features/blog/presentation/blog_page.dart` includes explicit
  media upload semantics.
- Widget tests use scroll visibility checks for dense jobs/blog forms.

Not yet collected:

- Dedicated text-scale, focus traversal, keyboard traversal, reduced-motion,
  and screen-reader regression tests.
- Web/Windows screenshot comparisons against approved screen references.

## Parity Summary

All rows in `react-parity-checklist.md` are now classified as `Implemented` or
`Accepted replacement`.

Accepted route-level replacements:

- `/dashboard` redirects to `/analytics`, where KPI cards, charts, recent
  alerts, and realtime override behavior are implemented.
- `/profile` implements account overview, sessions, and login history. Profile
  update and password mutation UI are not present in Flutter and remain an
  accepted product gap until a follow-up task is approved.

## Remaining Risk

- Run Android integration smoke on a connected emulator or device.
- Run iOS build and simulator smoke on macOS CI or a macOS developer machine.
- Provide backend PostgreSQL/Redis credentials that match the test suite, then
  rerun full `uv run --extra dev python -m pytest`.
- Fix or reclassify the route inventory and audit best-effort backend test
  failures after the database-backed suite is runnable.
- Add or run visual QA for Web and Windows screenshot comparisons.
- Run an independent final code-review pass before declaring the migration
  complete.
