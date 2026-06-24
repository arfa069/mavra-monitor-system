# Final Gate 02: Android Emulator Smoke Plan

> **For agentic workers:** use the `executing-plans` workflow for this gate. Device evidence must come from an Android emulator, not from desktop-only Flutter targets.

## Goal

Complete the Flutter Android integration smoke on an emulator and prove the migrated frontend starts, authenticates through the mocked smoke path, and exposes expected platform capabilities.

## Emulator Target

Use the installed AVD when available:

```powershell
flutter emulators
flutter emulators --launch Pixel_10_Pro_XL
flutter devices --device-timeout 120
```

If the device id is different from `emulator-5554`, use the id printed by `flutter devices` in the commands below.

## Build And Test Commands

1. Verify the Android toolchain and visible device.

   ```powershell
   cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
   flutter doctor -v
   flutter devices --device-timeout 120
   ```

2. Build the APK against the Android emulator host alias.

   ```powershell
   cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
   flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
   ```

3. Run each integration smoke test separately first.

   ```powershell
   cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
   flutter test integration_test/app_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
   flutter test integration_test/auth_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
   flutter test integration_test/platform_capability_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
   ```

4. Run the integration smoke folder once the individual files pass.

   ```powershell
   cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
   flutter test integration_test -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
   ```

## Manual Device Checks

Perform these checks on the emulator after the smoke tests:

- Login shell renders without clipped controls.
- Mocked auth smoke reaches the Today surface.
- Android system back returns to the previous route or exits only from the root route.
- Rotation keeps visible content usable.
- Text input focuses correctly and the soft keyboard does not hide the active field.
- Safe-area padding is respected around status and navigation bars.
- Platform capability smoke reports file picking support on Android.

Useful emulator commands:

```powershell
adb shell input keyevent 4
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 1
adb exec-out screencap -p > docs/flutter-migration/screenshots/android-emulator-smoke.png
```

## Safety Rules

- Do not run real crawling.
- Do not perform real Profile login, import, export, or browser session mutation.
- Do not start job matching tasks.
- Do not call Home Assistant services.
- Keep all integration smoke paths mocked or pointed at a disposable local backend.

## Acceptance Criteria

- `flutter build apk` exits `0`.
- All three named integration smoke tests pass on the Android emulator.
- The folder-level `flutter test integration_test -d <android-id>` pass is recorded, or any Flutter runner limitation is documented with the individual passing commands.
- Manual back, rotation, input, and safe-area checks have screenshots or written evidence.
- The final report names the emulator, Android API level, Flutter version, and command outputs.

## Evidence To Record

Update both files after this gate runs:

- `docs/flutter-migration/final-verification-report.md`
- `docs/flutter-migration/platform-verification-matrix.md`

Record:

- `flutter doctor -v` Android section.
- `flutter devices` output with Android id.
- APK build summary.
- Integration smoke command summaries.
- Screenshot paths and manual check notes.
