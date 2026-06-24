# Mavra Monitor System - Architecture Document

> **Note (2026-06-08)**: This document is a high-level summary. For the detailed backend architecture including complete data models, service boundaries, worker execution, and platform adapter internals, see [`doc/backend-architecture.md`](doc/backend-architecture.md). For frontend architecture, see [`doc/frontend-architecture.md`](doc/frontend-architecture.md). For permission architecture, see [`doc/permission-architecture.md`](doc/permission-architecture.md).

## Overview

A multi-user e-commerce price monitoring system that tracks product prices across Taobao, JD, and Amazon, plus job searches across Boss Zhipin, 51job, and Liepin. When price drops are detected, notifications are sent via Feishu Webhook.

Browser clients authenticate with HttpOnly access/refresh cookies, short-lived access JWTs, refresh-token rotation, and CSRF protection on unsafe methods. API clients/scripts can still use the legacy `Authorization: Bearer <token>` fallback through `get_current_user`. Data is isolated per user — each user can only access their own products, alerts, jobs, and configurations.

Auth write paths use a shared strong-password policy: new registrations, password changes, and WeChat registration-bound passwords must be at least 10 characters and include uppercase, lowercase, numeric, and special characters.

## Tech Stack

- **Language**: Python 3.11+
- **Web Framework**: FastAPI (async via asyncio)
- **Database**: PostgreSQL (async via SQLAlchemy)
- **Cache**: Redis
- **Crawler**: Playwright for product pages; `curl_cffi` HTTP clients for job platforms; CloakBrowser for Boss cookie refresh
- **Notification**: Feishu Webhook
- **Frontend**: Flutter + Dart (mobile-responsive, desktop-dense, WCAG accessible)
- **API Generation**: OpenAPI Generator CLI + generated Dart Dio package (automated End-to-End Type Safety)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      FastAPI Service Layer                         │
│  POST /config │ POST/GET /products │ GET /history │ POST /alerts│
│  POST /products/crawl/crawl-now │ GET /products/crawl/logs │ POST /products/crawl/cleanup   │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐   ┌─────────────────┐   ┌─────────────────────┐
│  PostgreSQL   │   │      Redis      │   │  Playwright Crawler  │
│  (data store)  │   │  (cache layer)  │   │  (in-process async)  │
└───────────────┘   └─────────────────┘   └─────────────────────┘
                          │                         │
                          │            ┌─────────────┼─────────────┐
                          │            ▼             ▼             ▼
                          │     ┌──────────┐  ┌──────────┐  ┌──────────┐
                          │     │  Taobao  │  │   JD    │  │  Amazon  │
                          │     │ Adapter  │  │ Adapter │  │ Adapter  │
                          │     └──────────┘  └──────────┘  └──────────┘
                          │                         │
                          ▼                         ▼
                  ┌─────────────┐           ┌─────────────┐
                  │   Feishu    │           │    CDP /     │
                  │  Webhook    │           │  Launch Mode │
                  └─────────────┘           └─────────────┘
```

## Crawling Strategy

Crawl tasks are persisted in PostgreSQL. In normal mode, FastAPI and APScheduler only enqueue `crawl_tasks`; independent `python -m app.workers.crawler` processes claim pending tasks with row locks, heartbeat, execute via `CrawlTaskRunner`, and write results back. Inline execution is a local fallback only when `CRAWLER_INLINE_EXECUTION_ENABLED=true`.

### Cron Scheduling

APScheduler (AsyncIOScheduler) is managed by FastAPI's lifespan startup/shutdown. Two scheduler managers handle per-entity cron jobs:

**Product crawl (per-platform)** — `ProductCronScheduler`:

- Each platform (taobao/jd/amazon) gets its own cron expression stored in `products_platform_crons` table
- APScheduler job ID format: `product_cron_{platform}`
- When triggered, calls `crawl_products_by_platform(platform)` — only crawls products of that platform
- API: `GET/POST /products/cron-configs`, `PATCH/DELETE /products/cron-configs/{platform}`
- Frontend: `/schedule` page shows a table with 3 platform rows, add/delete via modal

**Job crawl (per-config)** — `JobConfigScheduler`:

- Each `JobSearchConfig` gets its own cron expression stored in `cron_expression` / `cron_timezone` fields on `jobs_search_configs`
- APScheduler job ID format: `job_config_cron_{config_id}`
- When triggered, calls `crawl_single_config(config_id)` — only crawls that specific config
- API: `PATCH /jobs/configs/{id}/cron`, `GET /jobs/scheduler/job-configs`
- Frontend: `/schedule` page shows a table of all configs with cron inputs

**Registration**: Both managers are initialized in `main.py:_start_scheduler()`. On startup, `sync_all()` reads the DB and registers jobs for all entities with non-null `cron_expression`.

**Concurrency protection**: Durable `crawl_tasks` are claimed by workers; product crawl fan-out inside one claimed task is bounded by `PRODUCT_CRAWL_CONCURRENCY` (default `1`, minimum `1`). Job profile lanes remain serial per `(platform, profile_key)`.

**Status endpoint**: `GET /scheduler/status` returns all registered jobs in `products_platforms` and `job_configs` objects.

### Browser Modes

1. **Launch mode** (default): Launches a Chromium instance per crawl. It is headless by default and can be made visible for local debugging with `CRAWLER_HEADLESS=false`.
2. **CDP mode**: Connects to an existing browser via Chrome DevTools Protocol (`--remote-debugging-port=9222`). Reuses cookies/login sessions to bypass anti-bot detection.

### Page Load Strategy

- Uses `domcontentloaded` instead of `networkidle` (avoids stalling on ad trackers/WebSocket pings)
- Explicitly waits for price selectors to appear
- Stays 4–6 seconds on each page for full rendering (WebFont loading, especially JD's anti-scraping custom fonts)
- Overall operation timeout: 90s

### Anti-Bot Measures

- CDP mode reuses real browser sessions for product/JD flows that need login cookies
- Boss job crawling uses CloakBrowser only for profile cookie refresh; list/detail requests are serial `curl_cffi` calls
- Randomized delays between page interactions
- Disabled automation-controlled blink feature
- Proxy support for rotating IPs

## Data Model

> **数据隔离**：所有包含 `user_id` 字段的表（users 除外）均按 `user_id` 隔离查询。用户只能操作属于自己的数据。

### users

| Column              | Type        | Description                      |
| ------------------- | ----------- | -------------------------------- |
| id                  | BIGSERIAL   | Primary key                      |
| feishu_webhook_url  | TEXT        | Feishu webhook URL               |
| data_retention_days | SMALLINT    | History retention (default: 365) |
| created_at          | TIMESTAMPTZ | Creation timestamp               |
| updated_at          | TIMESTAMPTZ | Last update timestamp            |

### users_roles

| Column      | Type         | Description                                 |
| ----------- | ------------ | ------------------------------------------- |
| id          | BIGSERIAL    | Primary key                                 |
| name        | VARCHAR(50)  | Role name: `user` / `admin` / `super_admin` |
| description | VARCHAR(200) | Human-readable description                  |
| created_at  | TIMESTAMPTZ  | Creation timestamp                          |
| updated_at  | TIMESTAMPTZ  | Last update timestamp                       |

### users_permissions

| Column      | Type         | Description                        |
| ----------- | ------------ | ---------------------------------- |
| id          | BIGSERIAL    | Primary key                        |
| name        | VARCHAR(50)  | Permission name (e.g. `user:read`) |
| description | VARCHAR(200) | Human-readable description         |
| created_at  | TIMESTAMPTZ  | Creation timestamp                 |
| updated_at  | TIMESTAMPTZ  | Last update timestamp              |

### users_roles_permissions

| Column        | Type   | Description             |
| ------------- | ------ | ----------------------- |
| role_id       | BIGINT | FK to users_roles       |
| permission_id | BIGINT | FK to users_permissions |

### users_resource_permissions

| Column        | Type         | Description                               |
| ------------- | ------------ | ----------------------------------------- |
| id            | BIGSERIAL    | Primary key                               |
| subject_id    | BIGINT       | FK to users (grantee)                     |
| resource_type | VARCHAR(50)  | Resource type (e.g. `product`, `job`)     |
| resource_id   | VARCHAR(100) | Resource identifier                       |
| permission    | VARCHAR(50)  | Permission level (`manage`/`edit`/`read`) |
| granted_by    | BIGINT       | FK to users (granter)                     |
| created_at    | TIMESTAMPTZ  | Grant timestamp                           |

### products

| Column   | Type        | Description                  |
| -------- | ----------- | ---------------------------- |
| id       | BIGSERIAL   | Primary key                  |
| user_id  | BIGINT      | FK to users                  |
| platform | VARCHAR(20) | 'taobao', 'jd', 'amazon'     |
| url      | TEXT        | Product URL                  |
| title    | TEXT        | Product title                |
| active   | BOOLEAN     | Whether monitoring is active |

### products_price_history

| Column     | Type          | Description        |
| ---------- | ------------- | ------------------ |
| id         | BIGSERIAL     | Primary key        |
| product_id | BIGINT        | FK to products     |
| price      | NUMERIC(12,2) | Scraped price      |
| currency   | VARCHAR(3)    | Currency code      |
| scraped_at | TIMESTAMPTZ   | Scraping timestamp |

### products_alerts

| Column              | Type          | Description                |
| ------------------- | ------------- | -------------------------- |
| id                  | BIGSERIAL     | Primary key                |
| product_id          | BIGINT        | FK to products             |
| threshold_percent   | NUMERIC(5,2)  | Trigger threshold          |
| last_notified_at    | TIMESTAMPTZ   | Last notification time     |
| last_notified_price | NUMERIC(12,2) | Price at last notification |
| active              | BOOLEAN       | Whether alert is active    |

### crawl_logs

| Column        | Type          | Description                                   |
| ------------- | ------------- | --------------------------------------------- |
| id            | BIGSERIAL     | Primary key                                   |
| product_id    | BIGINT        | FK to products (NULL for system-level logs)   |
| platform      | VARCHAR(20)   | Platform (nullable)                           |
| status        | VARCHAR(20)   | SUCCESS/ERROR/SKIPPED/CRON_SUCCESS/CRON_ERROR |
| price         | NUMERIC(12,2) | Scraped price (nullable)                      |
| timestamp     | TIMESTAMPTZ   | Crawl timestamp                               |
| error_message | TEXT          | Error details or summary if failed/skipped    |

### products_platform_crons

| Column          | Type        | Description                       |
| --------------- | ----------- | --------------------------------- |
| id              | BIGSERIAL   | Primary key                       |
| user_id         | BIGINT      | FK to users                       |
| platform        | VARCHAR(20) | 'taobao', 'jd', 'amazon' (unique) |
| cron_expression | VARCHAR     | 5-segment crontab (nullable)      |
| cron_timezone   | VARCHAR     | Timezone (default: Asia/Shanghai) |
| created_at      | TIMESTAMPTZ | Creation timestamp                |
| updated_at      | TIMESTAMPTZ | Last update timestamp             |

### jobs_search_configs

| Column                 | Type        | Description                                         |
| ---------------------- | ----------- | --------------------------------------------------- |
| id                     | BIGSERIAL   | Primary key                                         |
| user_id                | BIGINT      | FK to users                                         |
| name                   | VARCHAR     | Config name                                         |
| url                    | TEXT        | Boss search URL                                     |
| active                 | BOOLEAN     | Whether monitoring is active                        |
| notify_on_new          | BOOLEAN     | Send notification for new jobs                      |
| deactivation_threshold | SMALLINT    | Consecutive misses before deactivation (default: 3) |
| cron_expression        | VARCHAR     | Per-config 5-segment crontab (nullable)             |
| cron_timezone          | VARCHAR     | Timezone (default: Asia/Shanghai)                   |
| created_at             | TIMESTAMPTZ | Creation timestamp                                  |
| updated_at             | TIMESTAMPTZ | Last update timestamp                               |

### jobs

| Column                 | Type        | Description                                              |
| ---------------------- | ----------- | -------------------------------------------------------- |
| id                     | BIGSERIAL   | Primary key                                              |
| job_id                 | VARCHAR     | Boss securityId (API调用); encryptJobId 用于拼详情页 URL |
| search_config_id       | BIGINT      | FK to jobs_search_configs                                |
| title                  | TEXT        | Job title                                                |
| company                | TEXT        | Company name                                             |
| company_id             | VARCHAR     | Boss encryptBrandId                                      |
| salary                 | VARCHAR     | Salary string (e.g. "20-40K")                            |
| salary_min             | INTEGER     | Parsed minimum salary (K)                                |
| salary_max             | INTEGER     | Parsed maximum salary (K)                                |
| location               | VARCHAR     | Job location                                             |
| experience             | VARCHAR     | Experience requirement                                   |
| education              | VARCHAR     | Education requirement                                    |
| description            | TEXT        | Job description (from detail API)                        |
| address                | TEXT        | Company address (from detail API)                        |
| url                    | TEXT        | Job detail URL                                           |
| is_active              | BOOLEAN     | Whether job is currently listed                          |
| first_seen_at          | TIMESTAMPTZ | First discovery timestamp                                |
| last_active_at         | TIMESTAMPTZ | Last seen in crawl                                       |
| consecutive_miss_count | SMALLINT    | Consecutive crawls not seen                              |
| last_updated_at        | TIMESTAMPTZ | Last update timestamp                                    |

## API Endpoints

| Method          | Path                              | Description                                      |
| --------------- | --------------------------------- | ------------------------------------------------ |
| GET             | /health                           | Health check (database + Redis + scheduler)      |
| GET             | /config                           | Get current configuration                        |
| POST            | /config                           | Create or update full configuration              |
| PATCH           | /config                           | Partial update (feishu url, retention days)      |
| POST            | /products                         | Add a product to track                           |
| GET             | /products                         | List products (paginated)                        |
| GET             | /products/{id}                    | Get product details                              |
| GET             | /products/{id}/history            | Get price history                                |
| POST            | /products/batch-create            | Batch import products                            |
| POST            | /products/batch-delete            | Batch delete products                            |
| POST            | /products/batch-update            | Batch enable/disable products                    |
| GET             | /products/cron-configs            | List per-platform cron configs                   |
| POST            | /products/cron-configs            | Create per-platform cron config                  |
| PATCH           | /products/cron-configs/{platform} | Update platform cron                             |
| DELETE          | /products/cron-configs/{platform} | Delete platform cron                             |
| GET             | /products/cron-schedules          | Next run times for product cron                  |
| POST            | /alerts                           | Create an alert                                  |
| GET             | /alerts                           | List all alerts                                  |
| POST            | /products/crawl/crawl-now         | Crawl all active products                        |
| GET             | /products/crawl/logs              | Get recent crawl logs                            |
| POST            | /products/crawl/cleanup           | Delete old data                                  |
| GET             | /scheduler/status                 | Scheduler job state                              |
| GET             | /dashboard/kpi                    | User KPI and admin system KPI                    |
| GET             | /dashboard/events                 | SSE stream for KPI updates                       |
| GET             | /dashboard/trends                 | Dashboard trends and distributions               |
| GET             | /dashboard/alerts/recent          | Recent alerts for admin dashboard                |
| GET/POST/DELETE | /jobs/resumes                     | List/Create/Delete resumes                       |
| PATCH           | /jobs/resumes/{id}                | Update a resume                                  |
| GET             | /jobs/match-results               | List LLM match results                           |
| POST            | /jobs/match-results/analyze       | Sync resume-job analysis                         |
| POST            | /jobs/match-results/analyze-async | Async resume-job analysis                        |
| GET             | /jobs/tasks/{task_id}             | Poll async analysis task                         |
| GET             | /jobs/configs                     | List job search configs                          |
| POST            | /jobs/configs                     | Create job search config                         |
| GET             | /jobs/configs/{id}                | Get job search config                            |
| PATCH           | /jobs/configs/{id}                | Update job search config                         |
| PATCH           | /jobs/configs/{id}/cron           | Update per-config cron                           |
| DELETE          | /jobs/configs/{id}                | Delete job search config                         |
| GET             | /jobs/scheduler/job-configs       | Next run times for job cron                      |
| GET             | /jobs                             | List crawled jobs (paginated)                    |
| GET             | /jobs/{id}                        | Get job details                                  |
| POST            | /jobs/crawl-now                   | Crawl all active job configs                     |
| POST            | /jobs/crawl-now/{id}              | Crawl single job config                          |
| GET             | /jobs/crawl-logs                  | Get job crawl logs (filterable by config/status) |
| GET             | /admin/users                      | List all users                                   |
| POST            | /admin/users                      | Create user                                      |
| GET             | /admin/users/{id}                 | Get user details                                 |
| PATCH           | /admin/users/{id}                 | Update user                                      |
| DELETE          | /admin/users/{id}                 | Soft delete user                                 |
| GET             | /admin/audit-logs                 | Query audit logs                                 |
| POST            | /admin/resource-permissions       | Grant resource permission                        |
| GET             | /admin/resource-permissions       | List resource permissions                        |
| PATCH           | /admin/resource-permissions/{id}  | Update resource permission                       |
| DELETE          | /admin/resource-permissions/{id}  | Revoke resource permission                       |
| GET             | /admin/roles/permissions          | Query role-permission matrix                     |
| PATCH           | /admin/roles/{role}/permissions   | Update role permissions                          |

## Notification System

- **Feishu Webhook**: JSON payload with text message
- **Idempotency**: Store last_notified_price to prevent duplicate alerts (only notifies if new price is lower than the last notified price)
- **Retry**: 3 attempts with exponential backoff
- **Alert Logic**: Compares the latest two price history records. If the drop percentage >= threshold_percent, sends notification.
- **Payload Format**:

```json
{
  "msg_type": "text",
  "content": {
    "text": "Price Drop Alert: {title_or_url}\nPlatform: {platform}\nOld Price: {old} {currency}\nNew Price: {new} {currency}\nDrop: {percent}%\nLink: {url}"
  }
}
```

## Platform Adapter Pattern

```
backend/app/platforms/base.py     — BasePlatformAdapter (ABC): _init_browser, crawl, extract_price/title
backend/app/platforms/taobao.py   — TaobaoAdapter
backend/app/platforms/jd.py       — JDAdapter
backend/app/platforms/amazon.py   — AmazonAdapter
backend/app/platforms/boss.py    — BossZhipinAdapter (legacy CDP + curl_cffi)
backend/app/platforms/boss_cloak_experimental.py — BossCloakExperimentalAdapter (CloakBrowser cookies + curl_cffi)
backend/app/platforms/job51.py   — Job51Adapter (curl_cffi)
backend/app/platforms/liepin.py  — LiepinAdapter (curl_cffi)
```

Each product adapter implements `extract_price()` and `extract_title()`. The base class manages browser lifecycle (launch or CDP connection), page navigation with timeout handling, and error recovery.

### Job Crawling Adapters

Unlike product adapters, job adapters do not use Playwright for their normal crawl paths. Instead:

- **BossCloakExperimentalAdapter** is the active Boss path. It uses the job config's leased CloakBrowser profile at project-root `profiles/{profile_key}` to refresh cookies, then calls Boss list/detail APIs through `curl_cffi` with `impersonate="chrome124"`.
- **Boss request strategy**: list pages use `pageSize=30`; list delay is 2-5s; detail delay is 2-3s; list and detail are interleaved per page; no batch/concurrent detail requests.
- **Boss anti-bot handling**: refresh cookies only when list/detail responses return code 36/37/38. Refresh is `reload` of the current search page, wait 1s, read full `.zhipin.com` cookie scope, then retry the current request.
- **Boss data completeness**: the adapter fetches details during `crawl()`, so `process_job_results()` normally receives jobs with `description` and `address` already present. `crawl_detail(security_id)` remains for legacy/fallback paths.
- **Boss observability**: each run writes JSONL progress to `backend/logs/boss_cloak_adapter_<timestamp>.jsonl` with `crawl_start`, `list_page`, `cookie_refresh`, `detail`, `sleep`, and `crawl_finish` events. `backend/logs/` is ignored by git.
- **Validated Boss baseline**: on 2026-05-25, config `id=3` (`IT服务台`, Guangzhou `101280100`) crawled 200 jobs in 589.57s; the database had 200/200 rows with `description` and `address`.
- **Job51Adapter** uses `curl_cffi` search and HTML detail parsing.
- **LiepinAdapter** uses `curl_cffi` for both search and detail. Search posts to `https://api-c.liepin.com/api/com.liepin.searchfront4c.pc-search-job`, seeded by a search-page GET for cookies/XSRF. Detail parsing tries standard `/job/<id>.shtml` and anonymous `/a/<id>.shtml` URLs. Under Windows, it loads and decrypts Chromium profile cookies (via Windows DPAPI decryption) from the assigned profile directory to authenticate requests and bypass challenge verification, without opening browser tabs. Detail page fetches are throttled with a 5-10s delay to prevent triggering anti-bot walls.
- Job configs store `profile_key`. Full job crawls create child tasks by `(platform, profile_key)`: different profile lanes may run concurrently, while tasks in the same profile lane stay serial.

This avoids the Playwright CDP `about:blank` redirect that Boss's anti-bot script triggers on detection, while keeping Boss requests serial enough for its anti-bot sensitivity.

### Runtime Profiles And Event Safety

- Browser profiles live under project-root `profiles/{key}` and are ignored by git.
- One profile can store login state for multiple platforms, but one profile directory can only be leased by one crawl task at a time. Use multiple profile keys when multiple crawler slots are needed.
- Profile metadata/status/leases live in `crawl_profiles`; `/crawl-profiles` lists, creates, renames, copies, deletes unused idle profiles, updates status, opens local login sessions, imports/exports encrypted backups, and releases expired leases.
- Profile folders must be renamed or copied through the UI/API, not manually in `profiles/`, because job configs and product cron rows store `profile_key` references.
- `emit_system_log()` redacts payloads before storage, and Event Center normalizers redact again before display. Sensitive cookie/token/webhook/security fields should not appear in runtime or audit event details.

## Data Retention

- Price history and crawl logs retained based on `data_retention_days` (default: 365 days)
- Cleanup triggered via `POST /products/crawl/cleanup` endpoint
- Accepts a `retention_days` query parameter (capped by config setting)

## Products Pagination

`GET /products` returns paginated results with full metadata:

- **Query params**: `page` (default 1), `size` (default 15, max 100), `platform`, `active`, `keyword`
- **Keyword search**: debounced 400ms, searches title and URL columns
- **Response shape**: `{ items, total, page, page_size, total_pages, has_next, has_prev }`
- **Stable sort**: `ORDER BY created_at DESC, id DESC` — prevents pagination drift on new inserts
- **Auto-rollback**: When batch delete empties the last page, frontend automatically steps back to the previous page

## Configuration

All settings via environment variables in `.env` (loaded via Pydantic Settings):

| Variable                   | Description                                         | Default                    |
| -------------------------- | --------------------------------------------------- | -------------------------- |
| DATABASE_URL               | PostgreSQL async connection URL                     | `postgresql+asyncpg://...` |
| REDIS_URL                  | Redis connection URL                                | `redis://localhost:6379/0` |
| REDIS_PASSWORD             | Redis password (alternative to URL)                 |                            |
| FEISHU_WEBHOOK_URL         | Feishu webhook URL for notifications                |                            |
| CDP_ENABLED                | Enable CDP mode (connect to existing browser)       | `false`                    |
| CDP_URL                    | CDP endpoint for existing browser                   | `http://127.0.0.1:9222`    |
| CRAWL_PROXY_ENABLED        | Enable proxy for crawling                           | `false`                    |
| CRAWL_PROXY_URL            | Proxy URL                                           |                            |
| DATA_RETENTION_DAYS        | Days to retain price history                        | `365`                      |
| JD_COOKIE_FALLBACK_ENABLED | Enable emergency JD cookie injection fallback       | `false`                    |
| JD_COOKIE                  | JD cookie string used only when fallback is enabled |                            |
