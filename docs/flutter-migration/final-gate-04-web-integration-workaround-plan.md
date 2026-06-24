# Final Gate 04: Web Integration Workaround Plan

> **For agentic workers:** use this plan because Flutter Web integration tests are not a reliable current gate in this repo. Prove the built Web app through browser smoke instead.

## Goal

Replace the blocked `flutter test integration_test -d chrome` path with a reproducible Web smoke that validates the production Web build in Chrome.

## Accepted Tool Limitation

Do not require this command as a current completion gate:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
flutter test integration_test -d chrome
```

Record the Flutter tooling limitation as an accepted exception in the final verification report. This exception covers only Flutter's Web integration-test runner. It does not waive Web build, browser smoke, route, or API-path validation.

## Build Command

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
flutter build web --dart-define=API_BASE_URL=/api/v1
```

## Local SPA Server

Serve `build/web` with `index.html` fallback so direct route refresh and bookmarks exercise the same behavior as production reverse proxy routing.

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
$env:FLUTTER_WEB_ROOT = (Resolve-Path build/web).Path
@'
import http.server
import os
import socketserver

root = os.environ["FLUTTER_WEB_ROOT"]
port = 4174

class Handler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        translated = super().translate_path(path)
        relative = os.path.relpath(translated, os.getcwd())
        return os.path.join(root, relative)

    def send_head(self):
        path = self.translate_path(self.path.split("?", 1)[0].split("#", 1)[0])
        if os.path.isdir(path):
            path = os.path.join(path, "index.html")
        if not os.path.exists(path):
            path = os.path.join(root, "index.html")
        self.path = "/" + os.path.relpath(path, root).replace("\\", "/")
        return super().send_head()

os.chdir(root)
with socketserver.TCPServer(("127.0.0.1", port), Handler) as httpd:
    print(f"Serving Flutter Web build on http://127.0.0.1:{port}")
    httpd.serve_forever()
'@ | python -
```

## Browser Smoke Checklist

Use Chrome against `http://127.0.0.1:4174`.

- Open `/login`; login shell renders.
- Open `/today` while unauthenticated; app redirects or guards the route correctly.
- Refresh `/login` and `/today`; the SPA fallback keeps the app loadable.
- Bookmark or direct-open a protected route; route guard behavior is stable.
- Trigger a mocked or disposable login flow; Today route becomes reachable.
- Verify network requests use `/api/v1/...`, not `/v1/...` or a bare business route.
- Use browser back and forward across login and Today routes.
- Confirm no console errors block first render.

## Safety Rules

- Use a mocked auth path or disposable local backend credentials only.
- Do not run real crawling.
- Do not perform real Profile login, import, export, or browser session mutation.
- Do not start job matching tasks.
- Do not call Home Assistant services.

## Acceptance Criteria

- `flutter build web` exits `0`.
- Chrome loads the built app from the local SPA server.
- Protected-route refresh and direct-open behavior is verified.
- Network inspection proves business calls use `/api/v1`.
- The blocked Flutter Web integration runner is recorded as an accepted tooling exception.

## Evidence To Record

Update both files after this gate runs:

- `docs/flutter-migration/final-verification-report.md`
- `docs/flutter-migration/platform-verification-matrix.md`

Record:

- Web build summary.
- Local server command and URL.
- Chrome version.
- Route smoke results.
- API-path network evidence.
- Console error summary.
