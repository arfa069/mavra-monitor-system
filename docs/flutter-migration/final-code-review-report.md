# Independent Code Review Report: Flutter Migration

Review date: 2026-06-17
Diff range: `6ba643b4..b4af331d`
Reviewer: Codex, separate pass after command verification

## Findings

### Finding 1: File Picking And Saving Advertised But Not Implemented

- Severity: High
- Status: Resolved on 2026-06-17
- File: `frontend/lib/core/files/file_service.dart`
- Location: `FileService.pickFile`, `FileService.saveBytes`, and `FileService.forCapabilities`
- Original issue: `FileService.forCapabilities` could advertise file picking, saving, or downloading support based on platform capabilities, but the concrete `pickFile()` and `saveBytes()` methods on the production service only threw `UnsupportedError`.
- Original impact: Blog media upload, job resume/profile import, product import, and export/download flows could present as supported and then fail at runtime on Web, Windows, or Android.
- Resolution: `FileService` now uses `file_selector` to pick files and read bytes on supported platforms. Desktop save uses the native save dialog and `XFile.saveTo`; Web save triggers the browser download path. Unsupported direct services still throw explicit `UnsupportedError`.
- Verification: `flutter test test/core/files/file_service_test.dart`, `flutter analyze`, `flutter test`, `flutter build web`, `flutter build windows`, `flutter build apk`, Windows platform capability smoke, and Android folder-level integration smoke all passed after the change.

### Finding 2: Native Token Policy Uses In-Memory Storage

- Severity: Medium
- Status: Resolved on 2026-06-17
- File: `frontend/lib/core/auth/auth_state.dart`
- Location: `authRepositoryProvider`
- Original issue: `AuthRepository` was created with `InMemoryTokenStorage()` while the configured policy was `TokenPersistencePolicy.nativeSecureStorage`.
- Original impact: The repository policy and storage implementation conflicted for Android and Windows.
- Resolution: `SecureTokenStorage` now wraps `flutter_secure_storage`, and `authRepositoryProvider` selects `SecureTokenStorage` for native secure storage while keeping Web on `TokenPersistencePolicy.webHttpOnlyRefreshCookie` with in-memory access-token storage. `MavraApp` also wires its default `AuthController` to an `AuthRepository`, waits for startup restore before creating the router, and keeps injected test/preview controllers on the immediate path.
- Verification: `flutter test test/core/auth/auth_repository_test.dart test/core/auth/auth_state_test.dart`, `flutter test test/features/auth/auth_flow_test.dart`, `flutter analyze`, `flutter test`, `flutter build windows`, `flutter build web`, and `flutter build apk` passed after the change.

### Finding 3: Windows Release App Builds But Visible Launch Shows White Window

- Severity: High
- Status: Resolved on 2026-06-17
- File: `frontend/windows/runner/main.cpp`, `frontend/windows/runner/flutter_window.cpp`, release packaging/runtime path
- Location: Windows release launch path
- Original issue: `flutter build windows` succeeded, and Windows integration smoke tests passed under the Flutter test harness, but visibly launching `build\windows\x64\runner\Release\mavra_frontend.exe` from its release directory left a white window instead of rendering the login shell.
- Original impact: Windows release users could receive a build that appears blank even though automated integration tests pass. This blocked Windows visual QA and final device coverage.
- Resolution: The release launch path was revalidated after a current rebuild. The executable now renders the login shell when launched from `build\windows\x64\runner\Release`.
- Verification: `flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1` passed, `flutter test integration_test/platform_capability_smoke_test.dart -d windows` passed, and the release screenshot `docs/flutter-migration/screenshots/2026-06-17/windows-release-login-after-final-build.png` shows the login shell after 15 seconds.

### Finding 4: Web Visual QA Can Hang On Remote CanvasKit Roboto Fallback

- Severity: Medium
- Status: Resolved on 2026-06-17
- File: `frontend/pubspec.yaml`, `frontend/assets/fonts/Roboto-Regular.ttf`
- Location: Flutter Web CanvasKit font initialization
- Original issue: Visual QA showed that Web engine initialization reached the loader but `initializeEngine()` did not resolve while CanvasKit attempted to fetch the default remote Roboto fallback from `fonts.gstatic.com`.
- Original impact: A local or offline Web final QA pass could see a blank first frame even after `main.dart.js` and local CanvasKit loaded.
- Resolution: Roboto is bundled as an application font so `FontManifest.json` includes the `Roboto` family and CanvasKit no longer blocks first frame on the remote default Roboto download.
- Verification: Visual Web build passed with `--no-web-resources-cdn`; Chrome visual QA screenshots captured Auth, Today, Analytics, Products, Jobs, Smart Home, Settings, Admin users, audit logs, blog, and mobile responsive samples with first frame rendered.

### Finding 5: Generated API Client Did Not Refresh Expired Sessions

- Severity: High
- Status: Resolved on 2026-06-18
- Files: `frontend/lib/core/api/authenticated_mavra_api.dart`, `frontend/lib/core/auth/auth_repository.dart`, `frontend/lib/features/auth/data/auth_api.dart`, `frontend/lib/app/mavra_app.dart`
- Location: generated API auth interceptor and default app auth repository wiring
- Original issue: The generated OpenAPI client path attached bearer tokens but did not recover from `401` responses in production, and the default `MavraApp` repository did not wire a generated-client refresh callback.
- Original impact: Web, Windows, and Android sessions could fail permanently after access-token expiry even though a refresh token existed, forcing unnecessary re-login and breaking long-lived authenticated flows.
- Resolution: The generated API client now retries exactly once after a successful refresh, `AuthRepository.refreshSession()` clears local state when refresh throws or returns null, `auth_api.dart` exposes `refreshGeneratedAuthSession()`, and the default `MavraApp` repository now uses that refresh path.
- Verification: `flutter test test/core/auth/auth_repository_test.dart test/core/api/authenticated_mavra_api_test.dart test/features/auth/auth_api_test.dart test/features/auth/auth_flow_test.dart`, `flutter test`, `flutter analyze`, `flutter build web`, and `flutter build windows` all passed after the change.

### Finding 6: Settings Was Over-Gated By `config:read`

- Severity: Medium
- Status: Resolved on 2026-06-18
- Files: `frontend/lib/app/router.dart`, `frontend/lib/features/settings/presentation/settings_page.dart`
- Location: `/settings` route guard and settings page permission handling
- Original issue: `/settings` was wrapped in a route-level `config:read` permission guard, which blocked ordinary authenticated users from reaching personal preferences that do not require server-side config access.
- Original impact: Users without `config:read` could not reach theme, motion, API environment, or platform capability settings even though those are part of the personal account surface.
- Resolution: The route-level guard was removed for `/settings`. The page now always renders the personal settings surface, while the server-backed config section is shown only when `config:read` is present and save actions remain gated by `config:write`.
- Verification: `flutter test test/features/auth/auth_flow_test.dart test/features/settings/settings_page_test.dart`, `flutter test`, and `flutter analyze` all passed after the change.

### Finding 7: Dangerous Actions Were Not Consistently Permission-Gated

- Severity: High
- Status: Resolved on 2026-06-18
- Files: `frontend/lib/app/router.dart`, `frontend/lib/features/products/presentation/products_page.dart`, `frontend/lib/features/jobs/presentation/jobs_page.dart`, `frontend/lib/features/schedule/presentation/schedule_page.dart`, `frontend/lib/features/smart_home/presentation/smart_home_page.dart`, `frontend/lib/features/schedule/data/schedule_api.dart`, `frontend/lib/features/smart_home/data/smart_home_api.dart`
- Location: products crawl-now, jobs crawl/match/profile actions, schedule configuration, and smart-home configure/control actions
- Original issue: Several dangerous actions were always enabled in the Flutter UI, and generated schedule/smart-home repositories advertised `canConfigure` / `canControl` as `true` regardless of the current user.
- Original impact: Users could be presented with crawl, profile session, match-analysis, schedule-edit, and smart-home control affordances that they were not authorized to execute.
- Resolution: App-router permission subsets are now passed into the affected pages, dangerous buttons are disabled when the required permissions are absent, and generated schedule/smart-home repositories now default those capability flags to safe `false` values instead of optimistic `true`.
- Verification: `flutter test test/features/products/products_page_test.dart test/features/jobs/jobs_page_test.dart test/features/schedule/schedule_page_test.dart test/features/smart_home/smart_home_page_test.dart`, `flutter test`, `flutter analyze`, `flutter build web`, and `flutter build windows` all passed after the change.

### Finding 8: WeChat Callback Exposed The Temporary Token In UI

- Severity: High
- Status: Resolved on 2026-06-18
- Files: `frontend/lib/features/auth/presentation/wechat_callback_page.dart`, `frontend/test/features/auth/auth_flow_test.dart`
- Location: WeChat unbound callback message
- Original issue: The unbound WeChat callback state rendered `tempToken` directly in the page body.
- Original impact: A short-lived but still sensitive linkage token was exposed in the browser UI and screenshots. The callback also kicked off its exchange inside `initState`, which could trigger router rebuild warnings during the first frame.
- Resolution: The callback page now starts the exchange after the first frame and replaces the raw token with a generic account-linking message.
- Verification: `flutter test test/features/auth/auth_flow_test.dart`, `flutter test`, `flutter analyze`, `flutter build web`, and `flutter build windows` all passed after the change.

## Residual Risks

- iOS remains deferred until macOS/Xcode/simulator or device capacity exists.
- Flutter Web integration tests remain an accepted tooling exception because Flutter reports Web devices are not supported for integration tests.
- Default `AuthController` startup session restore is covered at widget/unit level, including protected initial-route preservation, and authenticated Web/Windows visual QA now uses a seeded visual harness.
- Browser automation could not trigger Flutter Web form submission through semantic selectors, so Web API-path evidence currently comes from the Dart API usage checker and source inspection.

## Positive Checks

- Backend full pytest is green.
- Flutter analyzer and unit/widget tests are green.
- Android emulator integration smoke passes at folder level.
- Android release APK launches to the login shell on the emulator.
- Windows integration smoke passes under the Flutter test harness.
- Windows release executable renders the login shell from the release directory after the final rebuild.
- Authenticated Web and Windows visual QA screenshots are captured under `docs/flutter-migration/screenshots/2026-06-17/visual-qa/`.
- FileService has a real platform-backed implementation for pick/save paths.
- Native auth repository storage now uses `flutter_secure_storage` through `SecureTokenStorage` and keeps Web on the cookie policy.
- Default `MavraApp` startup restores saved native sessions before route guarding.
- Generated API requests now refresh expired sessions and retry once through the production client path.
- `/settings` now remains reachable for authenticated users without `config:read`, while server-backed config fields stay permission-gated.
- Products, Jobs, Schedule, and Smart Home dangerous actions now respect explicit frontend permissions.
- WeChat unbound callback no longer displays the temporary token in the UI.
- Web build and unauthenticated route smoke pass through the local SPA fallback server.

## Decision

The current supported-platform final gates are green. iOS remains explicitly deferred until macOS/Xcode/simulator or device capacity exists.
