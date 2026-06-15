# Frontend Shared Guide

## OVERVIEW

跨 feature 基础层：Orval mutator/Axios client、认证上下文、布局、主题/动效、权限类型和共享 UI primitives。

## WHERE TO LOOK

| Task        | Location                                                        | Notes                                                      |
| ----------- | --------------------------------------------------------------- | ---------------------------------------------------------- |
| HTTP client | `api/client.ts`, `api/mutator.ts`, `api/generated/*`            | `/api/v1` baseURL, Orval URL normalization, credentials, CSRF, refresh |
| Auth state  | `contexts/AuthContext.tsx`                                      | User, permissions, login/logout helpers                    |
| Layout/nav  | `components/AppLayout.tsx`                                      | Navigation, permissions, responsive layout                 |
| Theme       | `components/ThemeProvider.tsx`, `hooks/useTheme.ts`             | Theme and density/motion settings                          |
| Motion      | `components/PageTransition.tsx`, `hooks/useStaggerAnimation.ts` | Route and list transitions                                 |
| Permissions | `types/permissions.ts`, `components/PermissionBadge.tsx`        | Shared permission display/types                            |

## CONVENTIONS

- Ordinary JSON API calls must go through Orval generated functions under `api/generated/*`; those functions use `api/mutator.ts` and the shared Axios client for cookies and CSRF.
- Unsafe methods rely on `pm_csrf_token` cookie → `X-CSRF-Token` header injection.
- 401 refresh must avoid loops for login/me initialization paths.
- Permission UI should use `user.permissions`; role string is for display/boundary hints only.
- Motion must respect both `prefers-reduced-motion` and app motion settings.

## ANTI-PATTERNS

- Do not store access/refresh tokens in frontend state or localStorage.
- Do not create per-feature Axios clients or hand-written `api.get/post/put/patch/delete` JSON calls.
- Do not hardcode role-only checks where permission checks exist.
- Do not bypass `doc/DESIGN.md` tokens for layout/theme changes.

## VERIFY

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run lint"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run build"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; $env:E2E_BASE_URL='http://localhost:3000'; npx playwright test tests/e2e/basic.spec.ts --project=chromium"
```
