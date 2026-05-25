# 后端架构文档

## 1. 技术栈概览

| 层级     | 技术选型                                                                              |
| -------- | ------------------------------------------------------------------------------------- |
| 语言     | Python 3.11+                                                                          |
| Web 框架 | FastAPI（异步 via asyncio）                                                           |
| 数据库   | PostgreSQL（异步 via SQLAlchemy + asyncpg）                                           |
| 缓存     | Redis（异步 via redis.asyncio）                                                       |
| 爬虫     | Playwright（商品）+ curl_cffi（职位）+ CloakBrowser（Boss Cookie 刷新）               |
| 定时调度 | APScheduler（AsyncIOScheduler）                                                       |
| 通知     | 飞书 Webhook                                                                          |
| 认证     | HttpOnly Cookie + JWT + Refresh Token（python-jose + bcrypt + secrets.token_urlsafe） |

## 2. 项目结构

```
backend/
├── alembic/
│   ├── env.py                  # Alembic 迁移配置
│   └── versions/               # 数据库迁移文件
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI 应用工厂 + lifespan
│   ├── config.py               # Pydantic Settings（环境变量）
│   ├── database.py             # 异步 SQLAlchemy 引擎 + 会话
│   ├── core/
│   │   ├── security.py         # 认证依赖（get_current_user_cookie / csrf_protect / require_role）
│   │   ├── tokens.py           # JWT create/decode + opaque refresh/CSRF helpers
│   │   ├── permissions.py      # 细粒度权限矩阵 + require_permission
│   │   ├── resource_permission.py # 资源级 ACL 权限判断
│   │   ├── user_config_cache.py # Redis TTL 缓存用户配置（5min）
│   │   └── audit.py            # 审计日志写入工具
│   ├── models/
│   │   ├── base.py             # SQLAlchemy Base
│   │   ├── user.py             # User 模型
│   │   ├── session.py          # 会话管理（refresh_token_hash + token_hash 双模式，stage_* 事务安全）
│   │   ├── audit_log.py        # 审计日志（users_audit_logs）
│   │   ├── login_log.py        # 登录历史
│   │   ├── product.py          # Product / ProductPlatformCron 模型
│   │   ├── price_history.py    # PriceHistory 模型
│   │   ├── alert.py            # Alert 模型
│   │   ├── crawl_log.py        # CrawlLog 模型（商品爬取日志）
│   │   ├── job_crawl_log.py    # JobCrawlLog 模型（职位爬取日志）
│   │   ├── job.py              # Job / JobSearchConfig 模型
│   │   ├── job_match.py        # UserResume / MatchResult 模型
│   │   ├── permission.py       # Permission 模型（DB RBAC 运行时查询）
│   │   ├── role.py             # Role + role_permissions 关联表（DB RBAC 运行时查询）
│   │   └── resource_permission.py # 资源级 ACL（users_resource_permissions）
│   ├── platforms/
│   │   ├── base.py             # BasePlatformAdapter（ABC）
│   │   ├── taobao.py           # TaobaoAdapter
│   │   ├── jd.py               # JDAdapter
│   │   ├── amazon.py           # AmazonAdapter
│   │   ├── boss.py             # BossZhipinAdapter（legacy CDP 方案）
│   │   ├── boss_cloak_experimental.py # BossCloakExperimentalAdapter（当前 Boss 方案）
│   │   ├── job51.py            # Job51Adapter
│   │   └── liepin.py           # LiepinAdapter
│   ├── domains/
│   │   ├── admin/
│   │   │   ├── router.py       # 用户管理 / 审计日志 / 资源权限 / RBAC API
│   │   │   ├── service.py      # 管理端用户 CRUD 与角色边界规则
│   │   │   └── repository.py   # 管理端用户查询
│   │   ├── alerts/
│   │   │   ├── router.py       # 告警管理 API 薄路由
│   │   │   ├── service.py      # 告警 CRUD 与商品归属校验
│   │   │   └── repository.py   # 告警和商品归属查询
│   │   ├── auth/
│   │   │   ├── router.py       # 认证 API（注册/登录/登出/会话）薄路由
│   │   │   ├── wechat_router.py # 微信登录 API（feature flag，默认关闭）
│   │   │   ├── service.py      # 注册、登录查询、资料更新和会话清理编排
│   │   │   └── repository.py   # 用户、会话、登录日志查询和持久化
│   │   ├── config/
│   │   │   ├── router.py       # 用户配置 API 薄路由
│   │   │   ├── service.py      # 默认配置用户创建与配置更新
│   │   │   └── repository.py   # 默认配置用户查询和持久化
│   │   ├── crawling/
│   │   │   ├── router.py       # 商品爬取触发 / 日志 / 清理 API 薄路由
│   │   │   ├── scheduler_service.py # 商品爬取协调（Semaphore 并发控制）
│   │   │   ├── service.py      # 单商品爬取、活跃商品查询、爬取日志和旧数据清理编排
│   │   │   └── repository.py   # 商品、价格历史、爬取日志查询和持久化
│   │   ├── dashboard/
│   │   │   ├── router.py       # Dashboard KPI / 趋势 / SSE 薄路由
│   │   │   ├── dashboard_service.py # Dashboard KPI / 趋势聚合
│   │   │   ├── service.py      # Dashboard SSE 用户解析和最近告警编排
│   │   │   └── repository.py   # Dashboard 用户/告警查询
│   │   ├── events/
│   │   │   ├── router.py       # 事件中心 API / SSE 薄路由
│   │   │   ├── service.py      # 事件列表查询编排
│   │   │   └── repository.py   # 审计/系统日志 union 查询
│   │   ├── jobs/
│   │   │   ├── router.py       # 职位管理 API 薄路由
│   │   │   ├── scheduler.py    # 职位配置 cron manager
│   │   │   ├── crawl_service.py # 多平台职位爬取（Boss/51job/猎聘）
│   │   │   ├── match_service.py # LLM 简历-职位匹配分析
│   │   │   ├── notification_service.py # 职位新发现通知编排
│   │   │   ├── llm/            # 职位匹配 LLM provider
│   │   │   │   ├── provider.py
│   │   │   │   ├── anthropic.py
│   │   │   │   ├── openai.py
│   │   │   │   └── ollama.py
│   │   │   ├── service.py      # 职位配置、简历、匹配、列表查询业务边界
│   │   │   └── repository.py   # 职位配置、职位、简历、匹配、爬取日志查询
│   │   ├── products/
│   │   │   ├── router.py       # 商品管理 API 薄路由
│   │   │   ├── scheduler.py    # 商品平台 cron manager
│   │   │   ├── service.py      # 商品 CRUD、批量、cron 业务规则
│   │   │   └── repository.py   # 商品、cron、价格历史查询
│   │   └── scheduling/router.py # Scheduler status API
│   ├── schemas/
│   │   ├── admin.py
│   │   ├── user.py
│   │   ├── product.py
│   │   ├── price_history.py
│   │   ├── alert.py
│   │   ├── crawl_log.py
│   │   ├── dashboard.py
│   │   ├── events.py
│   │   ├── job.py
│   │   ├── job_crawl_log.py
│   │   └── job_match.py
│   ├── integrations/
│   │   └── feishu.py           # 飞书 Webhook transport
│   ├── core/
│   │   ├── scheduler.py        # APScheduler manager 共享基类
│   │   └── task_registry.py    # 后台爬取/匹配任务状态注册表
└── tests/                     # 单元/集成测试
```

## 3. 应用生命周期（main.py）

FastAPI 应用通过 lifespan 上下文管理器管理启动和关闭顺序：

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动阶段
    await _start_scheduler(app)  # 初始化 APScheduler，注册所有 cron 任务
    yield
    # 关闭阶段
    await _stop_scheduler(app)   # 优雅关闭调度器
    await engine.dispose()        # 关闭数据库连接池
```

**启动顺序：**

1. 创建 `asyncio.Semaphore(1)` 作为全局爬取锁
2. 初始化 `AsyncIOScheduler`（时区 UTC，job_defaults: coalesce=True, max_instances=1）
3. 创建 `JobConfigScheduler` 和 `ProductCronScheduler` 实例并调用 `sync_all()` 从数据库恢复 cron 任务
4. 启动调度器

## 4. 配置管理（config.py）

基于 Pydantic Settings，按优先级从环境变量或 `.env` 文件加载：

| 配置项                | 说明                        | 默认值                   |
| --------------------- | --------------------------- | ------------------------ |
| `database_url`        | PostgreSQL 连接 URL         | postgresql+asyncpg://... |
| `redis_url`           | Redis 连接 URL              | redis://localhost:6379/0 |
| `redis_password`      | Redis 密码（可选）          |                          |
| `feishu_webhook_url`  | 飞书 Webhook URL            |                          |
| `jwt_secret_key`      | JWT 签名密钥                | （需在生产环境修改）     |
| `cdp_enabled`         | 启用 CDP 模式连接已有浏览器 | false                    |
| `cdp_url`             | CDP 端点                    | http://127.0.0.1:9222    |
| `crawl_proxy_enabled` | 启用代理                    | false                    |
| `crawl_proxy_url`     | 代理 URL                    |                          |
| `data_retention_days` | 数据保留天数                | 365                      |
| `jd_cookie`           | JD 登录态 Cookie            |                          |
| `job_match_provider`  | LLM provider                | minimax                  |
| `minimax_api_key`     | MiniMax API Key             |                          |
| `openai_api_key`      | OpenAI API Key              |                          |
| `ollama_base_url`     | Ollama 服务地址             | http://127.0.0.1:11434   |

Redis URL 支持在 `redis_password` 字段设置密码时会自动拼接为 `redis://:password@host:port/0` 格式。

## 5. 数据库架构

### 5.1 连接管理（database.py）

- 异步引擎：`create_async_engine` + `async_sessionmaker`
- 会话获取：通过 `Depends(get_db)` 依赖注入
- Windows 兼容：禁用了 `pool_pre_ping`（避免跨事件循环 Future 问题）

### 5.2 数据模型关系

```
User (1) ──────< Product (多)
     │                │
     │                └────< PriceHistory
     │                └────< Alert
     │                └────< CrawlLog
     │
     ├────< ProductPlatformCron (per-platform cron 配置)
     │
     └────< JobSearchConfig (1) ─────< Job (多)
                    │
                    └────< MatchResult
                    └────< UserResume
```

### 5.3 关键表说明

| 表名                         | 说明                           | 隔离方式                               |
| ---------------------------- | ------------------------------ | -------------------------------------- |
| `users`                      | 用户账户（含飞书 Webhook URL） | 无（全局）                             |
| `users_roles`                | RBAC 角色定义                  | 无（全局）                             |
| `users_permissions`          | RBAC 权限定义                  | 无（全局）                             |
| `users_roles_permissions`    | RBAC 角色-权限多对多关联       | 无（全局）                             |
| `users_resource_permissions` | 资源级 ACL（跨用户资源授权）   | subject_id + resource_type/resource_id |
| `products`                   | 监控的商品                     | user_id 隔离                           |
| `products_price_history`     | 价格历史记录                   | 通过 product_id 间接隔离               |
| `products_alerts`            | 降价告警配置                   | 通过 product_id 间接隔离               |
| `crawl_logs`                 | 爬取日志                       | product_id nullable（系统日志无归属）  |
| `products_platform_crons`    | per-platform 商品爬取 cron     | user_id 隔离                           |
| `jobs_search_configs`        | BOSS 搜索配置                  | user_id 隔离                           |
| `jobs`                       | 爬取的职位                     | 通过 search_config_id 间接隔离         |
| `jobs_resumes`               | 用户简历                       | user_id 隔离                           |
| `jobs_match_results`         | LLM 匹配结果                   | user_id 隔离                           |

**数据隔离原则**：所有包含 `user_id` 的表均通过 `user_id = current_user.id` 过滤查询。

## 6. API 路由架构

### 6.1 路由分组

| 兼容前缀            | v1 前缀                                            | 路由文件                       | 说明                                                 |
| ------------------- | -------------------------------------------------- | ------------------------------ | ---------------------------------------------------- |
| `/auth`             | `/v1/auth`, `/api/v1/auth`                         | `domains/auth/router.py`       | 注册/登录/登出/当前用户                              |
| `/config`           | `/v1/config`, `/api/v1/config`                     | `domains/config/router.py`     | 用户配置（飞书 Webhook、数据保留期）                 |
| `/products`         | `/v1/products`, `/api/v1/products`                 | `domains/products/router.py`   | 商品 CRUD + 批量操作                                 |
| `/alerts`           | `/v1/alerts`, `/api/v1/alerts`                     | `domains/alerts/router.py`     | 告警管理                                             |
| `/products/crawl`   | `/v1/crawl`, `/api/v1/crawl`                       | `domains/crawling/router.py`   | 商品爬取触发 + 日志查询                              |
| `/jobs`             | `/v1/jobs`, `/api/v1/jobs`                         | `domains/jobs/router.py`       | 职位搜索配置 + 爬取 + 匹配分析                       |
| `/admin`            | `/v1/admin`, `/api/v1/admin`                       | `domains/admin/router.py`      | 用户管理 + 审计日志 + RBAC 矩阵（admin/super_admin） |
| `/events`           | `/v1/events`, `/api/v1/events`                     | `domains/events/router.py`     | 事件中心列表和 SSE                                   |
| `/dashboard`        | `/v1/dashboard`, `/api/v1/dashboard`               | `domains/dashboard/router.py`  | Dashboard KPI / 趋势 / SSE                           |
| `/scheduler/status` | `/v1/scheduler/status`, `/api/v1/scheduler/status` | `domains/scheduling/router.py` | APScheduler 状态（admin/super_admin）                |

`main.py` 同时注册旧路径、`/v1` 和 `/api/v1`。前端开发环境中 Vite 代理会去掉浏览器 URL 的 `/api` 前缀，因此浏览器请求 `/api/v1/...` 到达后端时对应 `/v1/...`。

### 6.2 认证系统

- `POST /auth/register` — 用户注册
- `POST /auth/login` — 用户登录（设置 HttpOnly Cookie：pm_access_token / pm_refresh_token / pm_csrf_token）
- `POST /auth/refresh` — 刷新 access token（通过 pm_refresh_token Cookie）
- `POST /auth/logout` — 登出（清除 Cookie + 删除 session）
- `GET /auth/me` — 获取当前用户信息
- `GET /auth/sessions` — 获取当前用户活跃会话列表
- 密码 bcrypt 加密，登录失败锁定（5次失败锁定15分钟，Redis 持久化，重启不丢失）
- 前端 AuthContext 状态管理，路由守卫（PublicRoute/ProtectedRoute）
- 请求拦截器自动添加 Token

### 6.3 认证流程

所有 API（除 `/auth/login`、`/auth/register` 外）均通过 `Depends(get_current_user_cookie)` 强制认证：

1. 从 `pm_access_token` HttpOnly Cookie 读取 access JWT
2. 验证 JWT signature、expiry、`typ="access"`、`sub`、`sid` 声明
3. 通过 `sid` 查找 `users_sessions` 行，校验 `user_id` 匹配
4. 校验用户 `deleted_at IS NULL`
5. 不需要 `is_active` 检查（仅 API 兼容字段）

Access JWT payload 结构：

```json
{
  "sub": "1",
  "username": "testuser",
  "sid": 42,
  "typ": "access",
  "exp": 1712345678
}
```

Access JWT 有效期 15 分钟；Refresh token（opaque，secrets.token_urlsafe(48)）有效期 14 天，仅存储 SHA-256 哈希到 `users_sessions.refresh_token_hash`。

不安全方法（POST/PATCH/PUT/DELETE）需额外通过 `Depends(csrf_protect)`：

- 读取 `pm_csrf_token` Cookie（非 HttpOnly，前端可读取）
- 比较 `X-CSRF-Token` 请求头
- 不匹配返回 403；安全方法（GET/HEAD/OPTIONS）跳过

变更摘要（从 Bearer token 迁移到 Cookie 认证）：

| 项目              | 旧系统                          | 新系统                                     |
| ----------------- | ------------------------------- | ------------------------------------------ |
| Token 存储        | localStorage (浏览器)           | HttpOnly Cookie                            |
| 请求方式          | `Authorization: Bearer <token>` | 自动携带 Cookie                            |
| Access JWT 有效期 | 60 分钟                         | 15 分钟                                    |
| 会话标识          | token_hash (JWT 原文哈希)       | sid (session ID claim)                     |
| 登录返回          | `TokenResponse {access_token}`  | `UserResponse` + 设置 Cookie               |
| Refresh 机制      | 无                              | POST /auth/refresh，opaque token 轮换      |
| CSRF 保护         | 无                              | pm_csrf_token Cookie + X-CSRF-Token Header |

````

### 6.3 请求/响应模型（schemas/）

每个资源有独立的 schema 文件，遵循以下模式：

- `XxxCreate` — POST 请求体
- `XxxUpdate` — PATCH 请求体（字段可选）
- `XxxResponse` — 响应体
- `XxxListResponse` — 分页列表响应（items, total, page, page_size）

## 7. 服务层架构

### 7.1 爬取协调服务（domains/crawling/scheduler_service.py）

**职责**：作为 APScheduler cron 触发和手动爬取 API 的共享入口，提供并发保护。

**关键机制：**

- `asyncio.Semaphore(1)` — 全局锁，防止 cron 和手动爬取重叠执行
- `CONCURRENCY_LIMIT = 3` — 同一批次内最多 3 个并发商品爬取
- `CRAWL_INTERVAL_MIN/MAX = 2-3s` — 批次内商品间随机间隔（避免反爬）

**入口函数：**

- `crawl_all_products(source, background)` — 爬取所有活跃商品
- `crawl_products_by_platform(platform)` — 按平台爬取（ProductCronScheduler 调用）
- `core/task_registry.py:get_task(task_id)` / `create_task(source)` — 任务状态追踪

### 7.2 定时任务管理（domains/jobs/scheduler.py + domains/products/scheduler.py）

共享 `BaseScheduler` 位于 `core/scheduler.py`。

**JobConfigScheduler**（`domains/jobs/scheduler.py`）— 管理 per-config 的职位爬取 cron：

- Job ID 格式：`job_config_cron_{config_id}`
- `add_job(config_id, cron_expression, timezone)` — 注册或替换任务
- `remove_job(config_id)` — 移除任务
- `sync_all()` — 启动时从数据库恢复所有有 cron 的配置

**ProductCronScheduler**（`domains/products/scheduler.py`）— 管理 per-platform 的商品爬取 cron：

- Job ID 格式：`product_cron_{user_id}:{platform}`
- `add_job(user_id, platform, cron_expression, timezone)` — 注册或替换任务
- `remove_job(user_id, platform)` — 移除任务
- `sync_all()` — 启动时从数据库恢复所有有 cron 的配置

### 7.3 商品爬取服务（domains/crawling/service.py）

`get_active_products()` — 查询当前用户所有 `active=True` 的商品，返回 `List[Product]`。

实际抓取逻辑在 `crawl_one()` 中，`domains/crawling/router.py:_crawl_one()` 仅作为 scheduler import/patch 路径的兼容包装。流程：

1. 根据 platform 路由到对应 Adapter
2. 调用 `adapter.crawl(url)` 执行 Playwright 自动化
3. 提取价格和标题
4. 写入 `products_price_history` 表
5. 调用 `check_price_alerts()` 检查是否触发通知

### 7.4 职位爬取（domains/jobs/crawl_service.py）

正常路径不使用 Playwright，改用 `curl_cffi` 的 TLS 指纹模拟；Boss 当前通过 CloakBrowser 持久 profile 刷新 cookies，不再走 Edge/Chrome CDP：

**核心逻辑：**

- `crawl_all_job_searches_background()` — 后台爬取所有活跃配置
- `crawl_single_config_background(config_id)` — 后台爬取单个配置
- Boss 当前入口：`_create_adapter("boss")` 固定返回 `BossCloakExperimentalAdapter`
- Boss Cookie 获取：从 `~/.cloakbrowser/profiles/boss-test` 的已登录 CloakBrowser profile 读取整套 `.zhipin.com` cookies
- Boss Token 刷新：列表/详情遇 code 36/37/38 时 reload 当前搜索页，wait 1s，读取 cookies 后重试当前请求
- Boss 抓取节奏：`pageSize=30`，列表页间隔 2-5s，详情间隔 2-3s，列表与详情按页交替，禁止并发详情请求
- Boss 数据完整性：`crawl()` 内部已抓详情，返回给入库层的 job 通常已包含 `description` 和 `address`；`crawl_detail(security_id)` 仅保留作 legacy/fallback
- Boss 运行日志：每次运行写 `backend/logs/boss_cloak_adapter_<timestamp>.jsonl`，记录列表页、详情、cookie refresh、sleep 和汇总耗时
- Boss 验证基线：2026-05-25 真实联调，广州 `IT服务台` 200 条耗时 589.57s，数据库 `description/address` 完整 200/200
- Liepin 搜索直接 POST `https://api-c.liepin.com/api/com.liepin.searchfront4c.pc-search-job`；先 GET 搜索页只为获取 cookie/XSRF，不打开浏览器 tab
- Liepin 详情直接 HTTP 解析，依次尝试 `/job/<id>.shtml` 和 `/a/<id>.shtml`，无地址时标记为 `无地址`
- 详情页串行获取，间隔 2-5s，连续 3 次 cookie 失败则熔断

### 7.5 LLM 匹配分析（domains/jobs/match_service.py）

- `POST /jobs/analyze` — 对职位进行 LLM 匹配分析
- `POST /jobs/batch-analyze` — 批量并发分析（asyncio.gather batch=3）
- 支持多 LLM provider：Anthropic、OpenAI、Ollama
- 匹配结果记录到 `job_match` 表，高分职位发送飞书通知

**Provider 工厂**（domains/jobs/llm/provider.py）：

- `get_llm_provider()` — 根据配置创建 Provider
- 支持：minimax（默认）、anthropic、openai、ollama

**分析流程：**

1. `analyze_resume_vs_jobs(resume_id, job_ids)` — 批量分析
2. `run_match_analysis_task(task, resume_id, job_ids)` — 异步任务执行
3. 每个 Job 调用 `llm_provider.analyze(resume_text, job_description)`
4. 将 `match_score`（0-100）、`match_reason`、`apply_recommendation` 存入 `jobs_match_results` 表

### 7.6 通知服务（integrations/feishu.py + domains/jobs/notification_service.py）

飞书 Webhook transport 位于 `integrations/feishu.py`，只负责发送 JSON；职位新发现通知文案位于 `domains/jobs/notification_service.py`。

飞书 Webhook JSON 推送格式：

```json
{
  "msg_type": "text",
  "content": {
    "text": "Price Drop Alert: {title}\nPlatform: {platform}\nOld Price: {old} CNY\nNew Price: {new} CNY\nDrop: {percent}%\nLink: {url}"
  }
}
````

**幂等性保障**：告警表存 `last_notified_price`，只有新价格低于上次通知价格才触发。

## 8. 平台适配器架构

```
backend/app/platforms/base.py     — BasePlatformAdapter (ABC)：_init_browser、crawl、extract_price/title（抽象方法）
backend/app/platforms/taobao.py   — TaobaoAdapter
backend/app/platforms/jd.py       — JDAdapter
backend/app/platforms/amazon.py  — AmazonAdapter
backend/app/platforms/boss.py    — BossZhipinAdapter (legacy 裸 WebSocket CDP + curl_cffi)
backend/app/platforms/boss_cloak_experimental.py — BossCloakExperimentalAdapter (CloakBrowser cookies + curl_cffi)
backend/app/platforms/job51.py   — Job51Adapter (curl_cffi)
backend/app/platforms/liepin.py  — LiepinAdapter (curl_cffi)
```

### 8.1 BasePlatformAdapter（platforms/base.py）

抽象基类，管理 Playwright 浏览器生命周期：

**浏览器模式：**

- **Launch 模式**（默认）：每次启动新的 headless Chromium
- **CDP 模式**：连接已运行浏览器的 DevTools（复用登录态）

**共享浏览器缓存**（类级别）：

```python
_shared_playwright: Playwright
_shared_browser: Browser
_shared_context: BrowserContext
```

**爬取流程（90s 超时）：**

1. `goto(url, wait_until='domcontentloaded', timeout=45s)` — 页面导航
2. `wait_for_selector(price_selector, state='attached', timeout=20s)` — 等待价格元素
3. `window.scrollBy(0, 300)` — 滚动触发懒加载（淘宝）
4. `wait_for_timeout(8-12s)` — 等待 JS 渲染（尤其是 JD 自定义字体反爬）
5. `extract_price()` / `extract_title()` — 子类实现

### 8.2 平台特定适配器

| 适配器                       | 提取策略                                                           |
| ---------------------------- | ------------------------------------------------------------------ |
| TaobaoAdapter                | CSS 选择器 + 活动页价格处理                                        |
| JDAdapter                    | 价格元素定位                                                       |
| AmazonAdapter                | 价格区域定位                                                       |
| BossCloakExperimentalAdapter | CloakBrowser 刷新 cookies + curl_cffi 串行调用搜索/详情 API        |
| BossZhipinAdapter            | legacy CDP/curl_cffi 方案，当前不由 `_create_adapter("boss")` 选择 |
| Job51Adapter                 | curl_cffi 搜索 + HTML 详情解析                                     |
| LiepinAdapter                | curl_cffi 搜索 API + HTTP 详情解析，不开 tab                       |

### 8.3 商品抓取流程（`POST /products/crawl/crawl-now`）

- `_crawl_one()` 在 FastAPI async 上下文中直接运行，无 Celery 依赖
- `check_price_alerts()` 在每次抓取后对比最近两条价格记录，跌幅达标则发飞书通知
- `POST /products/crawl/cleanup` 手动触发旧数据清理

### 8.4 职位抓取流程（`POST /jobs/crawl-now`）

- `BossCloakExperimentalAdapter.crawl()` 通过 curl_cffi 调 Boss 搜索/详情 API，CloakBrowser 只负责维持真实 profile 和刷新 cookies
- **Cookie 获取**：从 `~/.cloakbrowser/profiles/boss-test` 读取整套 Boss domain cookies；使用前需要用户在该 profile 登录 Boss
- **Token 刷新**：搜索和详情遇 code=36/37/38 时 reload 当前搜索页，wait 1s，读取 cookies 后重试当前列表页或详情请求
- **详情策略**：按页交替抓列表和详情；详情间隔 2-3s；不使用批量请求或并发
- **日志**：`backend/logs/boss_cloak_adapter_<timestamp>.jsonl` 是排查真实运行耗时和风控行为的第一现场
- `LiepinAdapter.crawl()` 先 GET 搜索页拿 cookie/XSRF，再 POST `api-c.liepin.com` 的 PC 搜索 API；不要为搜索列表打开 tab
- `LiepinAdapter.crawl_detail()` 直接 HTTP 解析 `/job/` 和 `/a/` 两类详情页；不要为详情打开 tab
- **连续失败熔断**：`process_job_results` 中连续 3 次 cookie 失败自动跳过剩余详情获取
- **Adapter 共享**：`crawl_all_job_searches()` 所有 config 共享一个 adapter 实例，详情串行 2-5s 间隔

## 9. 安全设计

### 9.1 认证与授权

- JWT Access Token：15 分钟有效期（`access_token_expire_minutes = 15`）
- 密码：bcrypt 加密
- 登录失败锁定：5 次失败后锁定 15 分钟（Redis 持久化，重启不丢失）

### 9.2 数据隔离

- 所有数据库查询通过 `user_id = current_user.id` 过滤
- 跨用户 URL 枚举防护：批量操作中先通过 user_id 过滤再处理

### 9.3 输入防护

- LIKE 查询使用 `escape='\\'` 转义 LIKE 元字符（`%`、`_`、`\`）
- URL 格式基础校验
- Pydantic schema 层验证

## 10. 关键约束

| 约束            | 说明                                         |
| --------------- | -------------------------------------------- |
| Windows uvicorn | 禁止使用 `--reload`（Playwright 子进程问题） |
| 数据库时间戳    | 全部使用 UTC（`datetime.now(timezone.utc)`） |
| 价格比较        | 使用 `Decimal` 避免浮点误差                  |
| 爬取并发        | 全局 Semaphore(1) 互斥 + 批次 Semaphore(3)   |
| CDP 连接        | 通过 `settings.cdp_enabled` 开关控制         |

## 11. 环境变量配置示例

```bash
# 数据库
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/pricemonitor

# Redis
REDIS_URL=redis://localhost:6379/0
REDIS_PASSWORD=your_redis_password

# 飞书
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/xxx

# JWT
JWT_SECRET_KEY=your-very-long-secret-key-min-32-chars

# CDP（可选，连接已登录浏览器复用会话）
CDP_ENABLED=false
CDP_URL=http://127.0.0.1:9222

# 代理（可选）
CRAWL_PROXY_ENABLED=false
CRAWL_PROXY_URL=

# JD Cookie（可选，绕过京东登录墙）
JD_COOKIE=

# LLM 配置
JOB_MATCH_PROVIDER=minimax
MINIMAX_API_KEY=your_key
```

## 12. 启动命令

```bash
# 开发环境（Windows 禁用 --reload）
cd backend && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

# 数据库迁移
cd backend && alembic upgrade head

# 运行测试
cd backend && pytest
```
