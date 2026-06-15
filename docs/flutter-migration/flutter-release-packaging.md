# Flutter Release Packaging

## Current Environment Status

Verified on June 16, 2026:

| Target | Status | Evidence |
| --- | --- | --- |
| Flutter SDK | Ready | Flutter 3.44.2 stable, Dart 3.12.2 |
| Web | Ready | Chrome and Edge detected |
| Windows | Ready | A clean Flutter Windows project produced a release `.exe` |
| Android | Setup in progress | Android Studio, SDK, ADB, and AVD were not yet detected |
| iOS | CI-only on Windows | Requires a macOS runner for simulator and build checks |

## Web

- Deployment: static `flutter build web` output served behind the existing
  production reverse proxy.
- Application path: `/`.
- API base URL: `/api/v1` in same-origin production; explicit
  `API_BASE_URL` dart define in development.
- Routing: browser history URLs with server fallback to `index.html`.
- Cache policy: hashed assets are immutable; `index.html` and service-worker
  metadata use no-cache or short revalidation.
- Distribution: existing Web deployment channel.

## Android

- Compile and target SDK: API 36.
- Emulator smoke target: Pixel 8 class device with API 36 x86_64 image.
- Development output: `flutter build apk`.
- Release output: `flutter build appbundle`.
- Initial distribution: internal testing track or signed private AAB/APK.
- Signing owner: repository owner or designated release maintainer.
- Signing material: external secret storage only; never commit keystores or
  passwords.
- Deep-link scheme: `mavra://auth/wechat`.

The minimum Android SDK remains the Flutter-generated project default unless a
plugin requires a higher version. Any increase must be recorded with the
requiring plugin.

## iOS

- Bundle identifier: `com.mavra.monitor`.
- CI build: `flutter build ios --no-codesign` on macOS.
- Simulator smoke target: current stable iOS simulator available on the CI
  runner.
- Release distribution: TestFlight first, then private or App Store release.
- Signing owner: repository owner or designated Apple release maintainer.
- Certificates and provisioning profiles: CI secret storage only.
- Callback scheme: `mavra://auth/wechat`.

No Windows developer may mark iOS complete from a local no-op. The macOS CI run
URL is required evidence.

## Windows

- Toolchain: Visual Studio Build Tools 2022, C++ desktop workload, CMake, and
  Windows SDK.
- Build command: `flutter build windows`.
- Package format: signed MSIX.
- Package identity: `Mavra.Monitor`.
- Minimum supported OS: Windows 10 version 2004, build 19041.
- Minimum window size: 1024 x 720 for dense management views.
- File behavior: native open/save dialogs for import and export.
- Callback scheme: `mavra://auth/wechat`, with loopback callback as a fallback
  only if custom URI registration is unavailable.
- Initial update channel: signed GitHub Release or private release storage.
  Automatic App Installer updates require a stable signed HTTPS feed.
- Signing owner: repository owner or designated Windows release maintainer.

## Shared Security And Operations

- Web access token: memory only.
- Web refresh token: HttpOnly cookie, unreadable by Flutter Web.
- Android, iOS, and Windows tokens: platform secure storage.
- If secure storage is unavailable, authentication fails closed instead of
  writing refresh tokens to plain files or preferences.
- Logs and crash reports redact cookies, Bearer tokens, refresh tokens, Home
  Assistant tokens, webhook URLs, exchange codes, and authorization headers.
- Build artifacts contain environment endpoints but no credentials.
- Web, Android, iOS, and Windows each require a release smoke test before
  promotion.
