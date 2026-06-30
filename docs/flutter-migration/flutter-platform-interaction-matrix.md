# Flutter Platform Interaction Matrix

Status: required platform behavior baseline for Flutter Web, Android, iOS, and
Windows.

## Matrix

| Area                | Web                                                                                                               | Android                                                   | iOS                                                          | Windows                                                               | Verification                                                      |
| ------------------- | ----------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Route URLs          | Path URLs match `/today`, `/products`, `/jobs`, `/smart-home`, `/schedule`, `/events`, `/dashboard`, admin routes | App links may open callback and selected module routes    | Universal links may open callback and selected module routes | Optional launch argument maps to a route after packaging              | Widget router tests plus Web integration test refreshing `/today` |
| Back behavior       | Browser back follows URL history                                                                                  | System back closes dialog/sheet, then pops route          | Edge/back gesture closes dialog/sheet, then pops route       | Alt-left or app back action follows route history                     | Integration tests for route pop and sheet dismissal               |
| Refresh recovery    | Full browser refresh restores auth before route decision                                                          | Cold start restores secure token before deep link         | Cold start restores keychain token before deep link          | App restart restores secure token before route decision               | Auth guard test with stored token and protected route             |
| Navigation          | Side navigation or rail, compact density                                                                          | Bottom nav plus More sheet                                | Bottom nav plus More sheet                                   | Side navigation, keyboard-friendly                                    | Golden/widget tests at mobile, tablet, desktop widths             |
| Minimum size        | Responsive down to mobile browser width                                                                           | Safe for 360 px width                                     | Safe for 390 px width with safe areas                        | Minimum `1100 x 720`; content scrolls below that                      | Layout tests with constrained viewports                           |
| Keyboard            | Tab order, Enter/Space activation, Escape dialogs                                                                 | Hardware keyboard optional                                | Hardware keyboard optional                                   | Required keyboard traversal and shortcuts                             | Widget focus traversal tests                                      |
| Focus               | Visible focus ring on controls and rows                                                                           | Focus not required for touch-only, but semantics required | Focus not required for touch-only, but semantics required    | Visible focus ring required                                           | Semantics and focus tests                                         |
| Hover               | Tooltips and hover affordances                                                                                    | None required                                             | None required                                                | Tooltips and hover affordances                                        | Desktop widget tests for tooltip labels                           |
| Context menus       | Optional row menus, duplicate visible actions                                                                     | Long-press sheet where needed                             | Long-press sheet where needed                                | Context menus allowed, duplicate visible actions                      | Widget tests ensure visible fallback action exists                |
| Secure storage      | Web secure storage abstraction with session fallback rules                                                        | Android encrypted storage                                 | iOS keychain                                                 | Windows secure storage or encrypted file store                        | Auth storage unit tests by platform interface                     |
| WeChat callback     | Browser redirect to `/auth/wechat/callback?exchange_code=...`                                                     | App link/deep link, then exchange                         | Universal link/deep link, then exchange                      | Custom URI or browser redirect back to app when packaging supports it | Callback parser tests plus platform smoke notes                   |
| Realtime            | SSE/EventSource where available; fallback polling                                                                 | SSE or streaming HTTP fallback, background-safe polling   | SSE or streaming HTTP fallback, app lifecycle aware          | SSE over desktop network, fallback polling                            | Realtime repository tests for connected/disconnected states       |
| Offline state       | Banner plus stale timestamps                                                                                      | Banner/snackbar plus pull-to-refresh                      | Banner/snackbar plus pull-to-refresh                         | Banner plus manual refresh controls                                   | Widget tests for stale labels and reconnect actions               |
| File upload         | Browser picker for import and media                                                                               | System file picker                                        | Document picker/photo library where applicable               | Native open file dialog                                               | File adapter unit tests and manual smoke checklist                |
| File download       | Browser download                                                                                                  | Share sheet or app downloads directory                    | Share sheet/files app                                        | Native save dialog                                                    | Adapter tests with fake bytes and expected filename               |
| Profile backup      | Export/import through `core/files`, never raw feature Dio                                                         | Same, password field visible                              | Same, password field visible                                 | Same, native save/open dialogs                                        | Profile backup adapter tests                                      |
| Blog media          | Browser upload to `/blog-media` result                                                                            | System picker then upload                                 | Photo/file picker then upload                                | Native picker then upload                                             | Blog media fake upload test                                       |
| IME handling        | Forms remain visible under browser viewport                                                                       | Keyboard avoids focused field                             | Keyboard avoids focused field                                | Desktop IME works in text fields/editor                               | Widget tests for scroll-into-view on focus                        |
| Safe areas          | Browser viewport padding only                                                                                     | System insets respected                                   | Notch/home indicator insets respected                        | Window padding only                                                   | Device-preview/widget tests for safe area                         |
| Notifications       | In-app snackbars only unless later enabled                                                                        | In-app snackbars; OS notification future work             | In-app snackbars; OS notification future work                | In-app snackbars; tray future work                                    | Snackbar semantics tests                                          |
| Destructive actions | Confirmation dialog, Escape cancel                                                                                | Bottom sheet/dialog confirmation                          | Action sheet/dialog confirmation                             | Confirmation dialog, keyboard cancel                                  | Widget tests for delete confirmation                              |
| Smart Home controls | Commands require explicit tap/click and confirmation for scene/script                                             | Same, larger controls                                     | Same, larger controls                                        | Same, keyboard activation supported                                   | Fake service-call test asserts no command on render               |
| Tables              | Dense table, sticky header where useful                                                                           | Horizontal scroll plus row detail sheet                   | Horizontal scroll plus row detail sheet                      | Dense table, keyboard row focus                                       | Table semantics tests and viewport screenshots                    |
| Charts              | Chart plus text summary and data fallback                                                                         | Simplified chart plus summary                             | Simplified chart plus summary                                | Full chart plus data fallback                                         | Chart semantics test and no-color-only check                      |
| Auth logout         | Clears session and redirects `/login`                                                                             | Clears secure storage and route stack                     | Clears keychain and route stack                              | Clears secure storage and route stack                                 | Auth repository logout tests                                      |
| Error envelope      | Show message, copyable trace id/details                                                                           | Same, compact details sheet                               | Same, compact details sheet                                  | Same, copy button and keyboard focus                                  | Error widget tests with fake envelope                             |

## Windows App Requirements

Windows is a first-class target, not a later wrapper.

Baseline:

- `flutter build windows` must pass before the Web/Windows scaffold is accepted.
- Minimum window size is `1100 x 720`.
- The app must remain usable when resized narrower by using scroll and adaptive
  rail behavior.
- Keyboard traversal is required across navigation, tables, dialogs, and forms.
- Native file open/save dialogs are required for import/export flows.
- Installer/update work can be staged later, but the interaction contract must
  not assume a browser-only runtime.

Expected Windows shortcuts:

| Shortcut   | Behavior                                                  |
| ---------- | --------------------------------------------------------- |
| `Ctrl+R`   | Refresh current route data where safe                     |
| `Alt+Left` | Back                                                      |
| `Ctrl+F`   | Focus route search/filter when present                    |
| `Esc`      | Close dialog, drawer, sheet, or clear transient selection |

Shortcuts must never be the only way to perform an action.

## Android Development Environment Notes

Android toolchain availability does not block Web/Windows scaffold work.
Android-specific verification starts once Android Studio, SDK, platform tools,
and an emulator or device are ready.

Minimum Android acceptance later:

- `flutter doctor -v` shows Android toolchain ready.
- `flutter build apk --debug` succeeds.
- One emulator/device smoke test opens `/login`, logs in with mocked/local test
  state where available, and reaches `/today`.
- System back behavior is verified for navigation, dialogs, and More sheet.

## iOS Development Notes

iOS cannot be fully built on this Windows workstation. iOS design and code paths
still remain in the Flutter project because the target app includes iOS.

Minimum iOS acceptance later on macOS:

- `flutter doctor -v` shows Xcode and CocoaPods ready.
- `flutter build ios --simulator` or simulator run succeeds.
- Safe area, edge gestures, file picker, and WeChat callback link behavior are
  smoke-tested.
