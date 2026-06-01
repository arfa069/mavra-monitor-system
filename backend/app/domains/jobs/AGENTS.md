# Jobs Domain Guide

## OVERVIEW

职位监控域：搜索配置、Boss/51job/猎聘爬取、简历管理、LLM 匹配、通知和 per-config cron。

## WHERE TO LOOK

| Task           | Location                         | Notes                                                 |
| -------------- | -------------------------------- | ----------------------------------------------------- |
| API routes     | `router.py`                      | Jobs, configs, crawl, resumes, match endpoints        |
| Business rules | `service.py`                     | Config/resume/job permissions and CRUD                |
| Crawling       | `crawl_service.py`, `runtime.py` | Platform grouping, runtime context, result processing |
| Scheduling     | `scheduler.py`                   | Per-config cron sync and job IDs                      |
| LLM matching   | `match_service.py`, `llm/`       | Provider factory and analysis contract                |
| Persistence    | `repository.py`                  | Query boundaries and user isolation                   |
| Notifications  | `notification_service.py`        | New-job Feishu notification orchestration             |

## CONVENTIONS

- Job configs carry `profile_key`; full crawls group by `(platform, profile_key)`.
- Same profile lane stays serial; different profile lanes may run concurrently.
- Boss active path is `BossCloakExperimentalAdapter`; CDP Boss path is legacy/fallback only.
- LLM provider selection goes through `llm/provider.py`; keep provider-specific code in `llm/*.py`.
- Queries must preserve `user_id` isolation via config/resume ownership checks.

## ANTI-PATTERNS

- Do not fetch Boss detail pages concurrently in batches; current strategy interleaves list/detail serially.
- Do not bypass `profile_key` validation when creating/updating configs.
- Do not put raw resume/job sensitive text into logs beyond existing redaction boundaries.
- Do not change cron fields without syncing scheduler status and tests.

## VERIFY

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_jobs_api.py tests/test_job_crawl.py tests/test_job_config_profile_key.py tests/test_job_match_service.py tests/test_job_match_api.py"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_boss_cloak_experimental.py tests/test_liepin_pipeline.py tests/test_liepin_http_only_phase3.py tests/test_job_phase3_integration.py"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app/domains/jobs app/platforms/boss_cloak_experimental.py app/platforms/liepin.py"
```
