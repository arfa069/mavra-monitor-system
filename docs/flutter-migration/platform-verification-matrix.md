# Flutter Platform Verification Matrix

## Current Toolchain

| Platform | Current status | Blocking point |
| --- | --- | --- |
| Web | Ready | None |
| Windows | Ready | Packaging/signing is a release concern, not a development blocker |
| Android | Toolchain ready | AVD exists, but first `assembleDebug` for integration smoke timed out locally |
| iOS | CI required | macOS runner, simulator, signing and provisioning |

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
the `/api/v1` path guard.

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
