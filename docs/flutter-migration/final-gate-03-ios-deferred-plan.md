# Final Gate 03: iOS Deferred Plan

> **For agentic workers:** use this gate to record the current iOS limitation. Do not mark iOS as locally verified from a Windows machine.

## Goal

Document that iOS build and device smoke are deferred for this migration phase because the current environment has no macOS runner, Mac, or iPhone. Per user instruction, iOS is not a blocker for the current completion gate.

## Current Decision

- iOS local build is not executed in the Windows environment.
- iOS simulator smoke is not executed in the Windows environment.
- iOS physical device smoke is not executed in the Windows environment.
- Current required device coverage is Web, Windows, and Android emulator.
- iOS remains a future verification track once macOS capacity exists.

This is an explicit deferral, not a pass.

## Future Entry Conditions

iOS verification can reopen when one of these is available:

- A macOS CI runner with Xcode and Flutter installed.
- A local Mac with Xcode and a configured simulator.
- A local iPhone with signing assets and developer trust configured.

## Future Verification Commands

Run these from the Flutter frontend on macOS:

```bash
cd /path/to/mavra-monitor-system/frontend
flutter doctor -v
flutter build ios --no-codesign --dart-define=API_BASE_URL=/api/v1
flutter devices
flutter test integration_test/app_smoke_test.dart -d <ios-simulator-id> --dart-define=API_BASE_URL=/api/v1
flutter test integration_test/auth_smoke_test.dart -d <ios-simulator-id> --dart-define=API_BASE_URL=/api/v1
flutter test integration_test/platform_capability_smoke_test.dart -d <ios-simulator-id> --dart-define=API_BASE_URL=/api/v1
```

If signing and a physical device are available, add a physical-device smoke after the simulator pass.

## Future Manual Checks

- App starts on iOS simulator.
- Login shell respects safe areas and keyboard insets.
- Mock auth reaches the Today surface.
- Browser back equivalent and iOS edge-swipe navigation behave predictably.
- File picking capability is either supported or gracefully unavailable according to the platform adapter.
- No real crawler, Profile, job matching, or Home Assistant side effect is triggered.

## Acceptance Criteria For Current Gate

- `docs/flutter-migration/final-verification-report.md` states that iOS is deferred by environment constraint and user instruction.
- `docs/flutter-migration/platform-verification-matrix.md` marks iOS as deferred for the current gate, not failed and not passed.
- Web, Windows, and Android emulator remain required before the current migration can be called fully verified.

## Evidence To Record

Update both files after this gate is documented:

- `docs/flutter-migration/final-verification-report.md`
- `docs/flutter-migration/platform-verification-matrix.md`

Record:

- Host OS limitation.
- Missing macOS/Xcode/iPhone capacity.
- Future command set above.
- Statement that iOS is outside the current completion blocker set.
