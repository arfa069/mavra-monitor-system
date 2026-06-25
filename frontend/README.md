# Mavra Flutter Frontend

Flutter replacement frontend for Mavra Monitor System. This app targets Web,
Android, iOS, and Windows from the same Dart codebase.

## Requirements

- Flutter 3.44.2 stable
- Dart 3.12.2
- Java 17 for Android and OpenAPI generator runs
- Node.js 20 for the pinned OpenAPI generator wrapper
- Visual Studio Build Tools 2022 with C++ desktop workload for Windows builds
- Android SDK and an API 36 emulator for Android smoke tests
- macOS with Xcode for iOS builds and simulator smoke tests

## Common Commands

Run from `C:/Users/arfac/Documents/mavra-monitor-system/frontend` unless noted.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=/api/v1
flutter build windows --dart-define=API_BASE_URL=http://localhost:8000/api/v1
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Run the Web app in development:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Use `flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1`
only when Flutter DevTools or Inspector needs a Chrome debug session.

Run desktop smoke tests when the platform toolchain is available:

```powershell
flutter test integration_test/auth_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

## API Client

The backend OpenAPI document is the source of truth. The generated Dart Dio
client lives in `lib/core/api/generated/`.

Regenerate from the repository root:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system
./scripts/generate_dart_client.ps1
```

Check generated output without modifying tracked files:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system
./scripts/generate_dart_client.ps1 -Check
cd backend
uv run --extra dev python ../scripts/check_dart_api_usage.py
```

Feature code should depend on generated API clients through repositories.
Only `lib/core/api/api_client.dart`, realtime transport, and file platform
adapters own low-level transport details.

## Local Full Stack

The repository launcher starts backend, Flutter web-server, crawler worker, and
the Next.js public blog by default:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system
./scripts/start_server.ps1
```

Use Chrome mode when Flutter Inspector is needed:

```powershell
./scripts/start_server.ps1 -ChromeDev
```

Use static web assets only after a build:

```powershell
cd frontend
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
cd ..
./scripts/start_server.ps1 -StaticFrontend
```

`-FlutterDev` remains as a compatibility alias for the default web-server mode.
Use `-NoCrawlerWorker`, `-NoBlogFrontend`, or `-BackendOnly` to avoid local
services that are not needed for a focused frontend check.
