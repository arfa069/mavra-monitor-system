# Core Backend Guide

## OVERVIEW

横切基础设施：认证、Cookie/CSRF、RBAC、资源 ACL、session/token、日志脱敏、scheduler/profile lease、事件流。

## WHERE TO LOOK

| Task              | Location                                               | Notes                            |
| ----------------- | ------------------------------------------------------ | -------------------------------- |
| Auth dependencies | `security.py`, `auth_cookies.py`                       | Cookie-first + Bearer fallback   |
| Sessions/tokens   | `sessions.py`, `tokens.py`, `passwords.py`             | Refresh rotation, JWT, hashing   |
| Lockout           | `login_lockout.py`                                     | 5 failures → 15 min lock         |
| Permissions       | `permissions.py`, `resource_permission.py`             | DB RBAC + resource ACL           |
| Scheduling        | `scheduler.py`, `task_registry.py`                     | Shared scheduler/task primitives |
| Profiles          | `crawler_paths.py`, `profile_lease.py`                 | Safe profile path/lease helpers  |
| Logs/events       | `log_redaction.py`, `system_log.py`, `event_stream.py` | Redaction and SSE helpers        |

## CONVENTIONS

- Browser main auth path uses HttpOnly cookies; `Authorization: Bearer` is fallback for scripts/API clients.
- Unsafe methods require CSRF: `pm_csrf_token` cookie must match `X-CSRF-Token`.
- Password writes must reuse the shared strong-password validator: minimum 10 characters with uppercase, lowercase, digit, and special character requirements.
- New business permissions should prefer DB-backed `require_permission`; reserve `require_role` for operational boundaries.
- Profile keys must reject empty/dot/path-traversal values.
- Redact before persistence and before display.

## ANTI-PATTERNS

- Do not store plaintext refresh tokens; store hashes.
- Do not weaken soft-delete/session checks in `get_current_user` paths.
- Do not introduce non-local CDP endpoints unless explicitly allowed by config.
- Do not log passwords, tokens, cookies, webhook URLs, security IDs, or raw profile secrets.

## VERIFY

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; pytest tests/test_auth.py tests/test_auth_api.py tests/test_cookie_auth.py tests/test_tokens.py tests/test_sessions.py tests/test_resource_permission.py tests/test_db_rbac_permissions.py tests/test_cdp_security.py tests/test_log_redaction.py"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; ruff check app/core tests/test_auth.py tests/test_cookie_auth.py"
```
