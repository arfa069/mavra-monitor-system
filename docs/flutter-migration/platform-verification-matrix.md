# Flutter Platform Verification Matrix

Last updated: 2026-06-17

## Current Platform Status

| Platform | Current status | Blocking point |
| --- | --- | --- |
| Web | Build, route smoke, and authenticated visual QA passed | None for the current Web gate |
| Windows | Build, integration smoke, release login visual, and authenticated visual QA passed | None for the current Windows gate |
| Android | Passed on emulator | None for the current emulator gate |
| iOS | Deferred | Windows host has no iOS build subcommand; macOS runner/simulator/signing remain required |

## Evidence Matrix

| Area | Command or Evidence | Result |
| --- | --- | --- |
| Backend lint | `uv run --extra dev python -m ruff check .` | Passed |
| Backend full tests | `uv run --extra dev python -m pytest` | Passed: `737 passed, 23 skipped, 54 warnings in 41.19s` |
| Flutter analyzer | `flutter analyze` | Passed |
| Flutter tests | `flutter test` | Passed: `77` tests |
| Dart API usage | `uv run --extra dev python ../scripts/check_dart_api_usage.py` | Passed |
| Web build | `flutter build web --dart-define=API_BASE_URL=/api/v1 --no-web-resources-cdn` | Passed |
| Web browser smoke | Chrome against local SPA fallback server | Passed for `/login`, direct `/today`, refresh, and back navigation |
| Web integration runner | `flutter test integration_test -d chrome` | Accepted exception: Flutter reports Web devices are not supported for integration tests |
| Windows build | `flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1` | Passed |
| Windows integration smoke | Three single-file `flutter test integration_test/*.dart -d windows` runs | Passed |
| Web visual QA | Chrome against visual QA harness | Passed: Auth, Today, Analytics, Products, Jobs, Smart Home, Settings, Admin users, audit logs, blog, and mobile responsive samples captured |
| Windows release visual | Release exe visible launch screenshots | Passed: Auth, Today, Analytics, Settings, and Admin users captured |
| Android APK | `flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` | Passed: `app-release.apk (54.4MB)` |
| Android integration smoke | `flutter test integration_test -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` | Passed: `3` tests after FileService update |
| Android release launch | Installed release APK on `emulator-5554` | Passed: login shell screenshot captured |
| iOS | Not executed locally | Deferred by environment constraint |

## Screenshot Evidence

| Platform | Screenshot | Notes |
| --- | --- | --- |
| Web desktop | `docs/flutter-migration/screenshots/2026-06-17/web-login.png` | Login shell |
| Web desktop | `docs/flutter-migration/screenshots/2026-06-17/web-today-direct.png` | Direct `/today` unauthenticated route guard |
| Web mobile | `docs/flutter-migration/screenshots/2026-06-17/web-login-mobile-390x844.png` | Mobile login shell |
| Web mobile | `docs/flutter-migration/screenshots/2026-06-17/web-today-mobile-redirect-390x844.png` | Mobile unauthenticated route guard |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-auth-login.png` | Auth login |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-today.png` | Authenticated Today |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-analytics.png` | Authenticated Analytics |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-products.png` | Dense Products state |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-jobs.png` | Dense Jobs state |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-smart-home.png` | Smart Home state |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-settings.png` | Authenticated Settings |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-admin-users.png` | Admin users and permissions |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-admin-audit-logs.png` | Admin audit logs |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-admin-blog.png` | Admin blog state |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-today-mobile.png` | Mobile Today |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-settings-mobile.png` | Mobile Settings |
| Web visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/web-admin-users-mobile.png` | Mobile Admin users |
| Android emulator | `docs/flutter-migration/screenshots/2026-06-17/android-release-launch-20s.png` | Release APK login shell |
| Android emulator | `docs/flutter-migration/screenshots/2026-06-17/android-emulator-smoke-portrait.png` | System-back/manual emulator state after smoke |
| Android emulator | `docs/flutter-migration/screenshots/2026-06-17/android-emulator-smoke-rotated.png` | Rotation/manual emulator state after smoke |
| Windows release | `docs/flutter-migration/screenshots/2026-06-17/windows-release-login-after-final-build.png` | Release login shell after final rebuild |
| Windows release | `docs/flutter-migration/screenshots/2026-06-17/windows-release-screen-workingdir.png` | Historical white-screen repro before revalidation |
| Windows visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/windows-auth-login.png` | Auth login |
| Windows visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/windows-today.png` | Authenticated Today |
| Windows visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/windows-analytics.png` | Authenticated Analytics |
| Windows visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/windows-settings.png` | Authenticated Settings |
| Windows visual QA | `docs/flutter-migration/screenshots/2026-06-17/visual-qa/windows-admin-users.png` | Admin users and permissions |

## Required Before Final-Green

- Current supported platforms are final-green.
- Keep iOS marked deferred until macOS capacity exists; do not mark it passed without a real macOS build/simulator/device run.

## Safety Rules

- Automated platform tests must not trigger real crawls.
- Automated platform tests must not perform real Profile login, import, export, or browser session mutation.
- Automated platform tests must not start job matching tasks.
- Automated platform tests must not call Home Assistant services.
