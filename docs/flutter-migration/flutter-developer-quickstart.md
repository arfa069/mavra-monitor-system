# Flutter Migration Developer Quickstart

## Strategic Decision

- Migration mode: fully replace the React/Vite frontend with Flutter for Web,
  Android, iOS, and Windows.
- Release policy: big-bang replacement. React and Flutter will not remain as
  parallel runtime products.
- Rollback reference: the immutable React commit recorded in
  `react-parity-checklist.md`.
- Product direction: Today remains the first authenticated screen, with warm
  summary surfaces and compact operational tools.

The owner has accepted big-bang replacement. A staged implementation with one
final cutover remains the safer alternative, but it is not the active policy.
Changing that policy must happen before Task 7 removes the React runtime.

## Success Metrics

1. Auth, Today, Activity, and one CRUD-heavy module run on Web, Android, iOS,
   and Windows before feature expansion is accepted.
2. `flutter analyze`, `flutter test`, Web build, Windows build, Android build,
   and the macOS CI iOS no-codesign build pass before completion is claimed.
3. Ordinary business JSON calls use the generated Dart OpenAPI client. Raw Dio
   remains limited to approved core transport owners.
4. Token-first authentication documents and tests Web/native token storage,
   refresh rotation, replay handling, and session revocation.

## Release Gates

| Gate | Timing | Required evidence |
| --- | --- | --- |
| A | After Task 4 | Token auth, WeChat exchange, realtime auth, and error-contract tests pass. |
| B | After Task 7 | Flutter scaffold builds for Web and Windows; generated Dart client compiles and regenerates without diff. |
| C | After Task 10 | Auth and Today widget tests plus Web, Windows, Android, and iOS smoke evidence. |
| D | After Task 11 | Products and Jobs focused tests pass; backup/import/export scope is accepted. |
| E | After Task 13 | Admin tables, Blog editor, and Settings gaps are classified and accepted. |
| F | Before completion | Final validation, GitNexus change detection, verification pass, and separate code-review pass. |

Android SDK installation may remain pending during Tasks 0-6. It becomes a
blocking requirement at Gate B for Android build preparation and at Gate C for
the Android emulator smoke path.

## Time To Hello World

Target: after prerequisites are installed, a new contributor can render the
Flutter login shell in Chrome within five minutes.

### Required tools

- Git
- uv
- Python 3.11 through `backend/.venv`
- Node.js 20
- Java 17
- Flutter 3.44.2 stable with Dart 3.12.2
- Visual Studio Build Tools 2022 with Desktop development with C++
- Android Studio, Android SDK API 36, and an Android emulator
- Access to a macOS CI runner for iOS verification

### Backend setup

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/backend
uv sync --extra dev
$env:JWT_SECRET_KEY = "local-development-secret-change-me"
uv run --extra dev python -m uvicorn app.main:app
```

Do not use `--reload` on Windows because it interferes with Playwright child
processes.

### Flutter setup after Task 7

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
flutter pub get
flutter analyze
flutter test test/app_smoke_test.dart
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

Flutter prints the local Chrome debug URL. The expected first screen is the
login shell.

### Common fixes

```powershell
flutter doctor -v
flutter config --enable-windows-desktop
flutter config --android-sdk "$env:LOCALAPPDATA/Android/Sdk"
flutter doctor --android-licenses
```

- Restart Codex and terminals after changing user or system `PATH`.
- Use Android Studio's bundled JDK through `flutter config --jdk-dir`.
- If generated Dart output is stale, run
  `scripts/generate_dart_client.ps1 -Clean`, then rerun with `-Check`.
- Never commit signing keys, API keys, cookies, refresh tokens, or local `.env`
  files.

## Worker Contract

Each worker:

1. Owns one numbered task and only the files listed by that task.
2. Does not edit unrelated files, root metadata, CI, schemas, or generated
   clients unless the assigned task explicitly owns them.
3. Runs GitNexus upstream impact analysis before editing a function, class, or
   method and reports HIGH or CRITICAL risk before proceeding.
4. Uses TDD for behavior changes: failing test, observed failure, minimal
   implementation, passing test, then refactor.
5. Updates the relevant migration checklist rows in the same commit as feature
   work.
6. Runs GitNexus `detect_changes` before committing.
7. Reports exact commands run, skipped commands and reasons, changed files,
   affected flows, and residual risk.
8. Does not claim completion without fresh command output or a documented
   blocker.

Commits must remain task-scoped. Verification and code review are separate
passes.
