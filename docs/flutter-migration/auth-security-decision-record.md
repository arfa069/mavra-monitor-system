# Auth Security Decision Record

## Decision

Mavra uses token-first authentication for Flutter clients while retaining
cookie compatibility only where an existing flow still requires it during the
migration.

## Web Storage

- Access tokens live in Flutter Web memory only.
- Refresh tokens use an HttpOnly, Secure outside debug, SameSite=Lax cookie.
- Refresh tokens are never exposed to JavaScript or written to localStorage,
  sessionStorage, IndexedDB, or plain files.
- A browser reload restores the session through refresh, then `/auth/me`.

## Native Storage

- Android, iOS, and Windows receive access and refresh tokens in the response
  body.
- Both tokens are stored through platform secure storage.
- Authentication fails closed if secure storage is unavailable.

## CSRF And Origin Boundary

- Bearer-only requests do not require the cookie CSRF token.
- Cookie-backed refresh, logout, and password rotation require a trusted
  `Origin`, with `Referer` origin as fallback.
- Trusted origins come from `settings.allowed_origins`.
- Cookie deletion reuses the original Path, Secure, SameSite, and HttpOnly
  attributes.

## XSS Boundary

- The Web refresh token is unreadable to Flutter Web code.
- The access token has the configured short lifetime and remains in memory.
- Content Security Policy and output escaping remain required deployment
  controls; token storage alone does not eliminate XSS risk.

## CORS

- Credentialed Web requests are allowed only from configured origins.
- Wildcard origins are incompatible with refresh cookies.
- Native clients use Bearer tokens and do not depend on browser CORS.

## Refresh Rotation And Replay

- Every successful refresh replaces the stored refresh-token hash.
- Reuse of the previous token returns 401.
- The current data model treats one `users_sessions` row as one token family.
  Replay rejection invalidates the presented old token; explicit device
  revocation deletes the session row.
- A future multi-generation family table is out of scope unless replay
  telemetry shows a need for broader family revocation.

## Logout And Revocation

- Bearer logout resolves the strict access-token `sid` and deletes that
  session.
- Native logout may identify the session with the refresh token body.
- Web logout may identify the session with the refresh cookie after origin
  validation.
- Password change deletes other sessions and rotates the current refresh token.

## Windows Secure Storage

- Windows uses credential-backed secure storage through the selected Flutter
  plugin.
- No plaintext preference or file fallback is allowed.
- Packaging and signing must preserve the application identity used by secure
  storage.

## Logging

Logs, audit events, and error reports must redact Authorization headers,
cookies, refresh tokens, access tokens, CSRF tokens, and WeChat exchange codes.
