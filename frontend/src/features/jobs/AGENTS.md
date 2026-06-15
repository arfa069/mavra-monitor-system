# Frontend Jobs Feature Guide

## OVERVIEW

前端最复杂业务页：职位配置、职位列表、详情抽屉、profile 管理、简历、LLM 匹配、爬取触发。

## WHERE TO LOOK

| Task               | Location                                              | Notes                                         |
| ------------------ | ----------------------------------------------------- | --------------------------------------------- |
| Page orchestration | `JobsPage.tsx`                                        | Tabs, query composition, major UI state       |
| API wrappers       | `api/jobs.ts`, `api/job_match.ts`                     | Wrappers around Orval generated jobs/profile APIs |
| Blob export        | `api/profileBackupExport.ts`                          | Explicit non-JSON API exception for profile backup export |
| Queries/mutations  | `hooks/useJobs.ts`                                    | React Query keys and invalidation             |
| Config UI          | `components/JobConfigForm.tsx`, `JobConfigList.tsx`   | `profile_key`, cron, platform inputs          |
| Profile UI         | `components/ProfileManagement.tsx`                    | Profile create/test/login/import/export flows |
| Job display        | `components/JobList.tsx`, `JobDrawer.tsx`             | List filters and detail rendering             |
| Resume/match       | `components/ResumeManager.tsx`, `MatchResultList.tsx` | Resume upload/list and match result display   |

## CONVENTIONS

- Ordinary JSON calls must use Orval generated functions from `shared/api/generated/*`; feature API files should only wrap, normalize, or compose those calls.
- Types mirror backend snake_case payloads; do not silently camelCase API fields.
- Mutations must invalidate the precise React Query keys in `useJobs.ts`.
- `profile_key` selection is part of job config correctness, not just UI metadata.
- Use existing Ant Design + design tokens; read `doc/DESIGN.md` before visual changes.
- Crawl/match actions are long-running; keep loading, polling, and error states explicit.

## ANTI-PATTERNS

- Do not bypass `shared/api/generated/*` for ordinary JSON calls; `profileBackupExport.ts` is the Blob export exception and still uses the shared Axios client.
- Do not trigger profile login/test flows without surfacing busy/login-required status.
- Do not add new local API types that drift from `types.ts`.
- Do not hide backend permission/crawl errors behind generic notifications only.

## VERIFY

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run lint"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run build"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; $env:E2E_BASE_URL='http://localhost:3000'; npx playwright test tests/e2e/test_profile_settings.spec.ts --project=chromium"
```
