# Crawling Domain Guide

## OVERVIEW

商品/职位爬取执行边界：任务持久化、profile 租约、浏览器会话、worker 观测、爬取日志。

## WHERE TO LOOK

| Task              | Location                                                                | Notes                                                |
| ----------------- | ----------------------------------------------------------------------- | ---------------------------------------------------- |
| Manual/API crawl  | `router.py`, `service.py`                                               | Product crawl trigger, logs, cleanup                 |
| Profile APIs      | `profile_router.py`, `profile_service.py`, `profile_runtime_service.py` | Create/test/login/import/export profiles             |
| Lease logic       | `profile_pool.py`                                                       | DB `SELECT ... FOR UPDATE`, heartbeat, stale release |
| Browser lifecycle | `browser_manager.py`                                                    | Persistent Playwright contexts and max-page guard    |
| Durable tasks     | `task_store.py`, `task_runner.py`, `scheduler_service.py`               | Persist/claim/execute crawl tasks                    |
| Worker status     | `worker_registry.py`                                                    | `crawler_workers` heartbeat and capabilities         |

## CONVENTIONS

- `profile_key` is the stable identity; profile directories are derived, not hand-built.
- Use `build_profile_dir(profile_key)` from `app.core.crawler_paths` for local paths.
- Profile acquisition failures should bubble as profile-busy/retry semantics, not generic 500s.
- Keep parent all-crawl tasks and child profile/platform lanes distinguishable in `crawl_tasks`.
- Emit system logs through redaction-safe helpers; never store raw cookies/tokens/webhooks.

## ANTI-PATTERNS

- Do not open two persistent browser contexts for the same `profile_key`.
- Do not edit folders under project-root `profiles/` manually; sync through API/UI.
- Do not bypass DB profile leases with filesystem locks.
- Do not skip lease release in exception paths.
- Do not mark profile login/runtime healthy without checking persisted `crawl_profiles.status`.

## VERIFY

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_crawl_profile_api.py tests/test_profile_pool.py tests/test_browser_manager.py tests/test_crawl_task_store.py tests/test_crawl_task_runner.py"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app/domains/crawling tests/test_crawl_profile_api.py tests/test_profile_pool.py tests/test_browser_manager.py"
```
