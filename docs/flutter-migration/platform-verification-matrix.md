# Flutter Platform Verification Matrix

## Current Toolchain

| Platform | Current status | Blocking point |
| --- | --- | --- |
| Web | Ready | None |
| Windows | Ready | Packaging/signing is a release concern, not a development blocker |
| Android | Toolchain installed but locally blocked | Local NDK `28.2.13676358` is a malformed download and no Android device/emulator is connected |
| iOS | CI required | The Windows Flutter tool exposes no iOS build subcommand; macOS runner, simulator, signing and provisioning remain required |

## CI Evidence Matrix

| Job | Runner | Trigger | Required evidence |
| --- | --- | --- | --- |
| `Backend lint` | Ubuntu | PR, push, schedule, manual | `uv run --extra dev python -m ruff check .` |
| `Backend tests` | Ubuntu | PR, push, schedule, manual | `uv run --extra dev python -m pytest` |
| `API contract` | Ubuntu | PR, push, schedule, manual | pinned OpenAPI generator wrapper `2.38.0`, generator jar `7.23.0`, `scripts/generate_dart_client.ps1 -Check`, `check_api_contract.py`, `check_dart_api_usage.py` |
| `Flutter Web fast PR` | Ubuntu | PR, push, schedule, manual | `flutter pub get`, Dart generator check, `flutter analyze`, `flutter test`, `flutter build web`, analyzer/test artifacts on failure |
| `Android build and smoke` | Ubuntu | push, schedule, manual | Java 17, Android cache, `flutter build apk`, Android emulator auth-to-Today smoke |
| `Windows build and smoke` | Windows | push, schedule, manual | Dart generator check, `flutter analyze`, `flutter test`, `flutter build windows`, Windows auth-to-Today smoke |
| `macOS iOS build and smoke` | macOS | push, schedule, manual | Dart generator check, `flutter analyze`, `flutter test`, iOS simulator auth-to-Today smoke, `flutter build ios --no-codesign` |
| `Scheduled full-platform summary` | Ubuntu | schedule, manual | Web, Android, Windows, and iOS smoke jobs completed in one run |

## Capability Matrix

| Capability | Web | Android | iOS | Windows | Verification command or check |
| --- | --- | --- | --- | --- | --- |
| Build | Required | Required | Required | Required | `flutter build web`, `flutter build apk`, `flutter build ios --no-codesign`, `flutter build windows` |
| Token login | Required | Required | Required | Required | platform auth integration smoke |
| Secure token storage | access in memory, refresh cookie | secure storage | Keychain | Windows credential-backed storage | auth repository tests and platform smoke |
| WeChat callback | browser URL callback | app link/custom scheme | universal link/custom scheme | custom URI or loopback | WeChat exchange tests |
| File upload | browser picker | platform picker | platform picker | native open dialog | jobs/blog/product upload tests |
| File download | browser download | save/share flow | save/share flow | native save dialog | profile backup export smoke |
| Realtime stream | SSE or fallback | SSE or polling fallback | SSE or polling fallback | SSE or fallback | realtime client tests |
| Dense tables | required | reduced list/table | reduced list/table | required | admin/products/jobs widget tests |
| URL and history | route URL, browser back, bookmark | deep-link entry | deep-link entry | custom URI/direct route | router integration tests |
| System back and safe area | browser back | system back and system bars | safe area and edge gestures | Escape/back shortcut where defined | navigation widget tests |
| Keyboard and focus | full traversal | form focus and IME | form focus and IME | full traversal, focus rings, context menu | accessibility/focus tests |
| Window and resize | responsive breakpoints | portrait/landscape | portrait/landscape | minimum size and resizable panes | screenshot QA |
| Notifications | browser support optional | native later phase | native later phase | native later phase | explicit scope decision before implementation |
| Offline state | visible disconnected state | visible disconnected state | visible disconnected state | visible disconnected state | state-widget tests |

## Required Platform Evidence

### Web

```powershell
flutter analyze
flutter test
flutter build web
flutter test integration_test -d chrome
```

Also verify direct navigation, refresh recovery, browser back, bookmarks, and
the `/api/v1` path guard. Web integration tests are not considered passed
unless the Flutter toolchain supports the selected Web integration target.

### Windows

```powershell
flutter analyze
flutter test
flutter build windows
flutter test integration_test -d windows
```

Also verify resizing, minimum size, keyboard traversal, file dialogs, and
custom callback handling.

### Android

```powershell
flutter doctor --android-licenses
flutter build apk
flutter test integration_test -d <android-device-id>
```

Also verify system back, safe areas, deep link, secure storage, file picker,
rotation, and IME behavior.

### iOS

```bash
flutter build ios --no-codesign
flutter test integration_test -d <ios-simulator-id>
```

The final verification report must include the macOS CI run URL.

## Status Rules

- `Required` means completion cannot be claimed without evidence.
- A locally unavailable target may use CI evidence, but must not be marked
  passed without a successful run.
- Android installation in progress is not an accepted final exception.
- Real crawls, profile logins, matching, and Home Assistant service calls stay
  disabled during automated platform tests.

## Gate C Evidence

Recorded during Task 10 on 2026-06-16:

| Target | Command | Result |
| --- | --- | --- |
| Web | `flutter test integration_test\auth_smoke_test.dart -d chrome` | Blocked by Flutter tool: `Web devices are not supported for integration tests yet.` |
| Windows | `flutter test integration_test\auth_smoke_test.dart -d windows` | Passed; Debug Windows app built and auth-to-Today smoke completed. |
| Android | `flutter test integration_test\auth_smoke_test.dart -d emulator-5554` | Blocked locally; `Pixel_10_Pro_XL` AVD booted as Android 16/API 36, but Gradle `assembleDebug` did not complete before timeout. |
| iOS | not run locally | Requires macOS CI/simulator evidence. |

## Task 15 Evidence

Recorded during final verification on 2026-06-16:

| Target | Command | Result |
| --- | --- | --- |
| Backend lint | `uv run --extra dev python -m ruff check .` | Passed. |
| Backend tests | `uv run --extra dev python -m pytest` | Failed locally: 669 passed, 50 failed, 41 skipped. Failures are dominated by local PostgreSQL password authentication failures, with additional route/audit test failures recorded in the final report. |
| API contract | `uv run --extra dev python ../scripts/export_openapi.py`; `uv run --extra dev python ../scripts/check_api_contract.py` | Passed. |
| Dart API usage | `uv run --extra dev python ../scripts/check_dart_api_usage.py` | Passed. |
| Flutter analyzer | `flutter analyze` | Passed. |
| Flutter tests | `flutter test` | Passed: 65 tests. |
| Web build | `flutter build web --dart-define=API_BASE_URL=/api/v1` | Passed; Flutter also emitted a WebAssembly dry-run warning for `file_picker` using `dart:html`. |
| Windows build | `flutter build windows --dart-define=API_BASE_URL=http://localhost:8000/api/v1` | Passed. |
| Android build | `flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` | Blocked locally by malformed NDK download at `C:\Users\arfac\AppData\Local\Android\Sdk\ndk\28.2.13676358`. |
| iOS build | `flutter build ios -h` | Not available on Windows; available build subcommands are `aar`, `apk`, `appbundle`, `bundle`, `web`, and `windows`. |
| Windows integration | `flutter test integration_test -d windows`; single-file reruns | Full command passed the first smoke then hit Flutter Windows app-start instability; `auth_smoke_test.dart` and `platform_capability_smoke_test.dart` passed when run individually. |
| Web integration | `flutter test integration_test -d chrome` | Blocked by Flutter tool: `Web devices are not supported for integration tests yet.` |
| Android integration | `flutter test integration_test -d android` | Blocked locally: no supported Android device or emulator is connected. |
