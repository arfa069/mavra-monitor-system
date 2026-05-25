# Price Monitor

E-commerce price monitoring system for Taobao, JD, and Amazon with Feishu webhook notifications.

## Features

- Track product prices across Taobao, JD, and Amazon; monitor jobs across Boss Zhipin, 51job, and Liepin
- Automated product crawling with Playwright (handles dynamic JS-rendered pages)
- Price drop alerts via Feishu Webhook
- CDP mode: reuse an existing browser session for product crawlers and JD login walls
- Boss Zhipin job crawling uses CloakBrowser profile cookies plus `curl_cffi` search/detail APIs
- Per-product crawl schedule (cron support per product)
- Job search monitoring for Boss Zhipin, 51job, and Liepin
- Dashboard with KPI cards, trend charts, salary/platform distributions, admin system health, and SSE KPI updates
- Database-backed RBAC with dynamic role-permission matrix and resource-level permissions
- RESTful API for product and alert management
- Mobile-responsive UI with accessibility support (WCAG compliance)

## Quick Start

```powershell
# Install dependencies
cd backend && pip install -e .

# 1. Create and edit .env at project root
# Required: DATABASE_URL, REDIS_URL, FEISHU_WEBHOOK_URL
# See the Configuration section below for the full .env content.

# 2. Run migrations
cd backend && alembic upgrade head

# 3. Start the server
cd backend && uvicorn app.main:app
```

> **Windows note**: Do **not** add `--reload` — it breaks Playwright's subprocess handling. Use `python -m uvicorn app.main:app` or `uvicorn app.main:app` instead (without `--reload`).

## Configuration

Create a `.env` file at the project root:

```env
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/pricemonitor
REDIS_URL=redis://localhost:6379/0
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/xxx

# CDP mode — connect to an already-running browser (e.g. Edge/Chrome started with --remote-debugging-port=9222)
# Used by product/JD flows that need a real browser session.
CDP_ENABLED=true
CDP_URL=http://127.0.0.1:9222

# Boss Zhipin job crawl
# Login once in the CloakBrowser profile at ~/.cloakbrowser/profiles/boss-test.
# Runtime JSONL progress logs are written under backend/logs/.

# Proxy (optional, for rotating IPs)
CRAWL_PROXY_ENABLED=false
CRAWL_PROXY_URL=http://user:pass@host:port

# Platform credentials (optional)
JD_COOKIE=...
```

## API Endpoints

> **认证说明**：浏览器端使用 HttpOnly Cookie 认证。`/auth/login` 设置 `pm_access_token`、`pm_refresh_token` 和 `pm_csrf_token`；前端通过 `withCredentials` 自动携带 Cookie，不安全方法需要 `X-CSRF-Token`。脚本/API 客户端仍可使用 legacy `Authorization: Bearer <token>` fallback。

| Method           | Path                              | Description                                        | 认证  |
| ---------------- | --------------------------------- | -------------------------------------------------- | ----- |
| GET              | /health                           | Health check (database + Redis + scheduler)        | 否    |
| GET              | /config                           | Get current configuration                          | 是    |
| POST             | /config                           | Create or update full configuration                | 是    |
| PATCH            | /config                           | Partial update configuration (cron/tz/hours)       | 是    |
| POST             | /products                         | Add a product to track                             | 是    |
| GET              | /products                         | List products (paginated: page, size, total, etc.) | 是    |
| GET              | /products/{id}                    | Get product details                                | 是    |
| GET              | /products/{id}/history            | Get price history                                  | 是    |
| POST             | /products/batch-create            | Batch import products                              | 是    |
| POST             | /products/batch-delete            | Batch delete products                              | 是    |
| POST             | /products/batch-update            | Batch enable/disable products                      | 是    |
| POST             | /alerts                           | Create an alert                                    | 是    |
| GET              | /alerts                           | List all alerts                                    | 是    |
| POST             | /products/crawl/crawl-now         | Crawl all active products                          | 是    |
| GET              | /products/crawl/logs              | Get recent crawl logs                              | 是    |
| POST             | /products/crawl/cleanup           | Delete old price history and crawl logs            | 是    |
| GET              | /scheduler/status                 | Scheduler status (both product and job crawl)      | 是    |
| GET              | /dashboard/kpi                    | User KPI and admin system KPI                      | 是    |
| GET              | /dashboard/events                 | Dashboard KPI SSE stream                           | 是    |
| GET              | /dashboard/trends                 | Dashboard chart data (`type`, `days`)              | 是    |
| GET              | /dashboard/alerts/recent          | Recent alerts for admin dashboard                  | admin |
| GET/POST/DELETE  | /jobs/resumes                     | List/Create/Delete resumes                         | 是    |
| PATCH            | /jobs/resumes/{id}                | Update a resume                                    | 是    |
| GET              | /jobs/match-results               | List match results                                 | 是    |
| POST             | /jobs/match-results/analyze       | Analyze resume vs jobs (sync)                      | 是    |
| POST             | /jobs/match-results/analyze-async | Analyze resume vs jobs (async)                     | 是    |
| GET              | /jobs/tasks/{task_id}             | Poll async task status                             | 是    |
| GET/POST         | /jobs/configs                     | List/Create job search configs                     | 是    |
| GET/PATCH/DELETE | /jobs/configs/{id}                | Manage a job search config                         | 是    |
| GET              | /jobs                             | List crawled jobs (paginated)                      | 是    |
| POST             | /jobs/crawl-now                   | Crawl all active job configs                       | 是    |
| POST             | /jobs/crawl-now/{id}              | Crawl single job config                            | 是    |

## 认证 API

系统使用 Cookie-first 认证。浏览器登录后由后端设置 HttpOnly access/refresh Cookie；access JWT 有效期 15 分钟，refresh token 有效期 14 天并按刷新轮换。`get_current_user` 对脚本/API 客户端保留 Bearer fallback。

### 端点

| Method | Path           | Description                         | 认证                    |
| ------ | -------------- | ----------------------------------- | ----------------------- |
| POST   | /auth/register | 注册新用户                          | 否                      |
| POST   | /auth/login    | 用户登录并设置认证 Cookie           | 否                      |
| POST   | /auth/refresh  | 通过 refresh Cookie 轮换认证 Cookie | 否（需 refresh Cookie） |
| POST   | /auth/logout   | 用户登出并清理 Cookie               | 是                      |
| GET    | /auth/me       | 获取当前用户信息                    | 是                      |

### 注册

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "email": "test@example.com", "password": "123456"}'
```

**请求体：**
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | 是 | 用户名（3-50字符） |
| email | string | 是 | 邮箱地址 |
| password | string | 是 | 密码（至少6位） |

**响应（201 Created）：**

```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "is_active": true,
  "created_at": "2026-05-06T10:30:00Z"
}
```

### 登录

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "123456"}'
```

**响应（200 OK）：**

```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "role": "user",
  "permissions": ["products:read", "products:write"],
  "is_active": true,
  "created_at": "2026-05-06T10:30:00Z"
}
```

登录响应通过 `Set-Cookie` 写入 `pm_access_token`、`pm_refresh_token`、`pm_csrf_token`，响应体不再返回 bearer token。

### 访问受保护资源

浏览器端由 Axios 自动携带 Cookie。curl 验证可使用 cookie jar：

```bash
curl -c cookies.txt -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "123456"}'

curl -b cookies.txt http://localhost:8000/auth/me
```

对 `POST` / `PATCH` / `PUT` / `DELETE` 等不安全方法，还需要把 `pm_csrf_token` Cookie 值作为 `X-CSRF-Token` 请求头发送。`POST /auth/refresh` 只依赖 HttpOnly refresh Cookie，不要求 CSRF header。

### 错误码

| 状态码 | 含义               | 说明                                               |
| ------ | ------------------ | -------------------------------------------------- |
| 201    | 注册成功           | 新用户创建成功                                     |
| 200    | 登录/登出成功      | 操作成功                                           |
| 400    | 用户名或邮箱已注册 | 注册时用户名或邮箱冲突                             |
| 401    | 认证失败           | 用户名/密码错误、Cookie 缺失、Token 过期或会话失效 |
| 403    | CSRF 失败          | 不安全方法缺少或携带了错误的 `X-CSRF-Token`        |
| 422    | 参数验证失败       | 密码太短、邮箱格式错误等                           |
| 429    | 请求过于频繁       | 连续5次登录失败后锁定15分钟                        |

### 安全机制

- **登录失败锁定**：连续5次登录失败后，账户将被锁定15分钟
- **Access Token 有效期**：15分钟；Refresh Token 有效期：14天
- **Refresh 轮换**：`POST /auth/refresh` 使用 `pm_refresh_token` Cookie，成功后轮换 refresh token 并重设三类认证 Cookie
- **CSRF 保护**：不安全方法校验 `pm_csrf_token` Cookie 与 `X-CSRF-Token` 请求头
- **密码加密**：使用 bcrypt 算法加密存储
- **数据隔离**：所有数据按 `user_id` 隔离，用户只能访问自己的数据
- **强制认证**：除 `/auth/register`、`/auth/login`、`/auth/refresh` 外，业务接口均需认证

## Admin API

> 详见 `doc/permission-architecture.md` 完整权限矩阵。

| Method | Path                             | 说明             | 所需权限          |
| ------ | -------------------------------- | ---------------- | ----------------- |
| GET    | /admin/users                     | 列出所有用户     | admin/super_admin |
| POST   | /admin/users                     | 创建用户         | admin/super_admin |
| GET    | /admin/users/{id}                | 获取用户详情     | admin/super_admin |
| PATCH  | /admin/users/{id}                | 更新用户信息     | admin/super_admin |
| DELETE | /admin/users/{id}                | 软删除用户       | admin/super_admin |
| GET    | /admin/audit-logs                | 查询审计日志     | admin/super_admin |
| POST   | /admin/resource-permissions      | 授予资源级权限   | admin/super_admin |
| GET    | /admin/resource-permissions      | 列出资源级权限   | admin/super_admin |
| PATCH  | /admin/resource-permissions/{id} | 更新资源级权限   | admin/super_admin |
| DELETE | /admin/resource-permissions/{id} | 撤销资源级权限   | admin/super_admin |
| GET    | /admin/roles/permissions         | 查询角色权限矩阵 | super_admin       |
| PATCH  | /admin/roles/{role}/permissions  | 修改角色权限     | super_admin       |

**角色边界**：admin 不能创建/修改/删除 super_admin；super_admin 不能删除自己或最后一个活跃的 super_admin。

## Development

```powershell
# Run linter
cd backend && ruff check .

# Run tests
cd backend && pytest

# Run with coverage
cd backend && coverage run -m pytest
cd backend && coverage report

# Start frontend
cd frontend && npm run dev
```

## Architecture

- **FastAPI**: Web framework (async via asyncio)
- **PostgreSQL**: Database (async via SQLAlchemy)
- **Playwright**: Product crawler for dynamic pages (launch or CDP mode)
- **curl_cffi**: Job crawler HTTP client with browser-like TLS fingerprints
- **CloakBrowser**: Boss Zhipin cookie refresh/profile browser for anti-bot-sensitive job crawls
- **Redis**: Cache layer
- **Feishu Webhook**: Notification service

Crawl tasks run **directly in FastAPI's async context** — no Celery or background worker needed. Each crawl uses a 90s timeout with platform-specific price selectors.

### Cron Scheduling (APScheduler)

The system supports two independent cron jobs:

**Product crawl** — two mutually exclusive modes:

- **Interval mode**: Crawl every N hours (default: 1 hour)
- **Cron mode**: Crawl on a cron schedule (e.g., `0 9 * * *` = daily at 9:00)

Configured via `GET/POST/PATCH /config`:

```
# Interval mode
crawl_frequency_hours: 2

# Cron mode
crawl_cron: "0 9 * * *"
crawl_timezone: "Asia/Shanghai"
```

**Job crawl** — always cron mode (default `"0 9 * * *"`, configured via `GET/PUT /config/job-crawl-cron`).

Both cron jobs are managed via the **Schedule page** (`/schedule`) in the frontend, which shows registration state, next run time, and provides independent save buttons.

Concurrent crawl protection: both cron and manual crawls share a global `asyncio.Semaphore(1)` — only one crawl runs at a time. On cron failure, a CrawlLog entry is written and a Feishu notification is sent if configured.

### Job Platform Notes

- Boss Zhipin uses `BossCloakExperimentalAdapter`: CloakBrowser opens the logged-in profile only to refresh cookies, while list/detail requests run serially through `curl_cffi`. The adapter logs progress to `backend/logs/boss_cloak_adapter_<timestamp>.jsonl`; a 2026-05-25 real run for Guangzhou `IT服务台` crawled 200 jobs in 589.57s with 200/200 descriptions and addresses in the database.
- 51job uses `curl_cffi` search and HTML detail parsing.
- Liepin uses `curl_cffi` for both search and detail. Search calls `https://api-c.liepin.com/api/com.liepin.searchfront4c.pc-search-job`; detail parsing tries `/job/<id>.shtml` and `/a/<id>.shtml`. The normal Liepin path should not open browser tabs.

### Products Pagination

`GET /products` supports pagination with full metadata:

```json
{
  "items": [...],
  "total": 100,
  "page": 1,
  "page_size": 15,
  "total_pages": 7,
  "has_next": true,
  "has_prev": false
}
```

Query parameters: `page` (default 1), `size` (default 15, max 100), `platform`, `active`, `keyword` (debounced search by title/URL).

See `ARCHITECTURE.md` for detailed architecture.

## License

MIT
