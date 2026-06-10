# 数据模型参考

> 所有表、字段、约束、关系。SQLAlchemy 声明见 `backend/app/models/`。
> 表名前缀反映归属：与多租户相关的用 `users_*`，否则直接命名。

## 索引

| 表                           | 用途                              |
| ---------------------------- | --------------------------------- |
| `users`                      | 账号 + 偏好                       |
| `users_roles`                | 三种角色枚举                      |
| `users_permissions`          | 权限名枚举                        |
| `users_roles_permissions`    | 角色 ↔ 权限矩阵                   |
| `users_resource_permissions` | 资源级 ACL                        |
| `users_sessions`             | refresh token 会话                |
| `users_audit_logs`           | 审计                              |
| `products`                   | 监控商品                          |
| `products_price_history`     | 价格历史                          |
| `products_alerts`            | 降价告警配置                      |
| `crawl_logs`                 | 商品爬取日志                      |
| `products_platform_crons`    | 商品 per-platform cron            |
| `jobs_search_configs`        | 职位搜索配置                      |
| `jobs`                       | 抓取到的职位                      |
| `jobs_resumes`               | 简历                              |
| `jobs_match_results`         | LLM 匹配结果                      |
| `crawl_tasks`                | **持久化任务**（产品 + 职位共用） |
| `crawl_profiles`             | 浏览器 profile 元数据 + lease     |
| `crawler_workers`            | worker 进程心跳                   |
| `smart_home_configs`         | HA 连接配置（加密 token）         |
| `smart_home_audit`           | 智能家居操作审计                  |
| `system_logs`                | 平台事件（爬虫 / LLM / 飞书）     |

---

## users

| 字段                  | 类型         | 约束            | 说明                     |
| --------------------- | ------------ | --------------- | ------------------------ |
| `id`                  | BIGSERIAL    | PK              |                          |
| `username`            | VARCHAR(50)  | UNIQUE NOT NULL |                          |
| `email`               | VARCHAR(255) | UNIQUE NOT NULL |                          |
| `hashed_password`     | VARCHAR(255) | NOT NULL        | bcrypt-sha256            |
| `role`                | VARCHAR(20)  | NOT NULL        | 冗余字段；以 RBAC 表为准 |
| `wechat_openid`       | VARCHAR(64)  | UNIQUE NULL     | 微信绑定                 |
| `feishu_webhook_url`  | TEXT         | NULL            | 用户级 webhook           |
| `data_retention_days` | SMALLINT     | DEFAULT 365     |                          |
| `is_active`           | BOOLEAN      | DEFAULT TRUE    |                          |
| `deleted_at`          | TIMESTAMPTZ  | NULL            | 软删                     |
| `created_at`          | TIMESTAMPTZ  | DEFAULT now()   |                          |
| `updated_at`          | TIMESTAMPTZ  | DEFAULT now()   |                          |

## users_sessions

| 字段                 | 类型        | 说明                          |
| -------------------- | ----------- | ----------------------------- |
| `id`                 | BIGSERIAL   | PK                            |
| `user_id`            | BIGINT      | FK users.id ON DELETE CASCADE |
| `refresh_token_hash` | VARCHAR(64) | SHA-256 hex；**不存明文**     |
| `user_agent`         | TEXT        | 浏览器 UA                     |
| `ip_address`         | VARCHAR(45) | IPv6 兼容                     |
| `expires_at`         | TIMESTAMPTZ | 14 天                         |
| `revoked_at`         | TIMESTAMPTZ | 软删                          |

每用户最多 5 条 `revoked_at IS NULL AND expires_at > now()` 的行。

## users_roles / users_permissions / users_roles_permissions

- `users_roles`: `id, name('user'|'admin'|'super_admin'), description`
- `users_permissions`: `id, name('product:read'|...)`, `description`
- `users_roles_permissions`: `(role_id, permission_id)` 多对多

权限矩阵见 [doc/permission-architecture.md](permission-architecture.md)。

## users_resource_permissions

| 字段            | 类型         | 说明                         |
| --------------- | ------------ | ---------------------------- |
| `id`            | BIGSERIAL    | PK                           |
| `subject_id`    | BIGINT       | 被授权 user                  |
| `resource_type` | VARCHAR(50)  | `product` / `job` / `user`   |
| `resource_id`   | VARCHAR(100) | 资源 ID（string 以兼容跨域） |
| `permission`    | VARCHAR(50)  | `read` / `edit` / `manage`   |
| `granted_by`    | BIGINT       | 授权人 user.id               |
| `created_at`    | TIMESTAMPTZ  |                              |

## users_audit_logs

| 字段          | 类型         | 说明                                     |
| ------------- | ------------ | ---------------------------------------- |
| `id`          | BIGSERIAL    | PK                                       |
| `actor_id`    | BIGINT       | 谁触发（NULL 表示系统）                  |
| `action`      | VARCHAR(64)  | `user.update` / `auth.login` 等          |
| `target_type` | VARCHAR(50)  | `user` / `role` / `smart_home_config` 等 |
| `target_id`   | VARCHAR(100) | 资源 ID                                  |
| `details`     | JSONB        | 脱敏后的细节                             |
| `ip_address`  | VARCHAR(45)  |                                          |
| `created_at`  | TIMESTAMPTZ  |                                          |

`details` 走 `app/core/log_redaction.py` 替换 `password` / `token` / `webhook_url` 等敏感键。

## products

| 字段                        | 类型         | 说明                       |
| --------------------------- | ------------ | -------------------------- |
| `id`                        | BIGSERIAL    | PK                         |
| `user_id`                   | BIGINT       | FK users                   |
| `platform`                  | VARCHAR(20)  | `taobao` / `jd` / `amazon` |
| `url`                       | TEXT         | 商品页 URL                 |
| `platform_product_id`       | VARCHAR(100) | 平台原生 ID（爬取时回填）  |
| `title`                     | TEXT         | 爬取后回填                 |
| `active`                    | BOOLEAN      | DEFAULT TRUE               |
| `profile_key`               | VARCHAR(64)  | 可选，绑爬虫 profile       |
| `created_at` / `updated_at` | TIMESTAMPTZ  |                            |

UNIQUE：`（user_id, url）` 防止重复添加。

## products_price_history

| 字段         | 类型          | 说明                          |
| ------------ | ------------- | ----------------------------- |
| `id`         | BIGSERIAL     | PK                            |
| `product_id` | BIGINT        | FK products ON DELETE CASCADE |
| `price`      | NUMERIC(12,2) | 爬到的价格                    |
| `currency`   | VARCHAR(3)    | `CNY` / `USD`                 |
| `scraped_at` | TIMESTAMPTZ   |                               |

INDEX：`(product_id, scraped_at DESC)`

## products_alerts

| 字段                  | 类型          | 说明              |
| --------------------- | ------------- | ----------------- |
| `id`                  | BIGSERIAL     | PK                |
| `product_id`          | BIGINT        | FK products       |
| `threshold_percent`   | NUMERIC(5,2)  | 触发阈值 0.01-100 |
| `last_notified_at`    | TIMESTAMPTZ   | 节流              |
| `last_notified_price` | NUMERIC(12,2) | 防重复            |
| `active`              | BOOLEAN       |                   |

## crawl_logs

| 字段            | 类型          | 说明                                                            |
| --------------- | ------------- | --------------------------------------------------------------- |
| `id`            | BIGSERIAL     | PK                                                              |
| `product_id`    | BIGINT        | NULL 表示系统级                                                 |
| `platform`      | VARCHAR(20)   | NULLABLE                                                        |
| `status`        | VARCHAR(20)   | `SUCCESS` / `ERROR` / `SKIPPED` / `CRON_SUCCESS` / `CRON_ERROR` |
| `price`         | NUMERIC(12,2) | 成功时填                                                        |
| `error_message` | TEXT          | 失败时填                                                        |
| `timestamp`     | TIMESTAMPTZ   |                                                                 |

## products_platform_crons

| 字段                        | 类型        | 说明                    |
| --------------------------- | ----------- | ----------------------- |
| `id`                        | BIGSERIAL   | PK                      |
| `user_id`                   | BIGINT      | FK users                |
| `platform`                  | VARCHAR(20) | UNIQUE                  |
| `cron_expression`           | VARCHAR(64) | 5 段                    |
| `cron_timezone`             | VARCHAR(64) | DEFAULT `Asia/Shanghai` |
| `created_at` / `updated_at` | TIMESTAMPTZ |                         |

## jobs_search_configs

| 字段                        | 类型         | 说明                        |
| --------------------------- | ------------ | --------------------------- |
| `id`                        | BIGSERIAL    | PK                          |
| `user_id`                   | BIGINT       | FK users                    |
| `name`                      | VARCHAR(100) |                             |
| `url`                       | TEXT         | 搜索页 URL                  |
| `platform`                  | VARCHAR(20)  | `boss` / `51job` / `liepin` |
| `active`                    | BOOLEAN      |                             |
| `notify_on_new`             | BOOLEAN      |                             |
| `deactivation_threshold`    | SMALLINT     | DEFAULT 3                   |
| `cron_expression`           | VARCHAR(64)  | 可空                        |
| `cron_timezone`             | VARCHAR(64)  | DEFAULT `Asia/Shanghai`     |
| `profile_key`               | VARCHAR(64)  |                             |
| `created_at` / `updated_at` | TIMESTAMPTZ  |                             |

## jobs

| 字段                                        | 类型         | 说明                             |
| ------------------------------------------- | ------------ | -------------------------------- |
| `id`                                        | BIGSERIAL    | PK                               |
| `job_id`                                    | VARCHAR(100) | 平台原生 ID（Boss `securityId`） |
| `search_config_id`                          | BIGINT       | FK configs                       |
| `title` / `company` / `salary` / `location` | TEXT         |                                  |
| `company_id`                                | VARCHAR(100) | Boss `encryptBrandId`            |
| `salary_min` / `salary_max`                 | INTEGER      | K                                |
| `description`                               | TEXT         | 详情 API 抓                      |
| `address`                                   | TEXT         | 详情 API 抓                      |
| `experience` / `education`                  | VARCHAR(50)  |                                  |
| `url`                                       | TEXT         | 详情页                           |
| `is_active`                                 | BOOLEAN      | 连续未出现会置 false             |
| `first_seen_at`                             | TIMESTAMPTZ  | **新职位判定的核心**             |
| `last_active_at`                            | TIMESTAMPTZ  |                                  |
| `consecutive_miss_count`                    | SMALLINT     | 累计 N 次后 `is_active=false`    |
| `last_updated_at`                           | TIMESTAMPTZ  |                                  |

UNIQUE：`(search_config_id, job_id)`

## jobs_resumes

| 字段                        | 类型         | 说明                  |
| --------------------------- | ------------ | --------------------- |
| `id`                        | BIGSERIAL    | PK                    |
| `user_id`                   | BIGINT       |                       |
| `name`                      | VARCHAR(100) |                       |
| `content`                   | TEXT         | Markdown              |
| `is_active`                 | BOOLEAN      | 单份 `is_active=true` |
| `created_at` / `updated_at` | TIMESTAMPTZ  |                       |

## jobs_match_results

| 字段         | 类型        | 说明         |
| ------------ | ----------- | ------------ |
| `id`         | BIGSERIAL   | PK           |
| `resume_id`  | BIGINT      | FK           |
| `job_id`     | BIGINT      | FK           |
| `score`      | SMALLINT    | 0-100        |
| `reason`     | TEXT        | LLM 解释     |
| `highlights` | JSONB       | string[]     |
| `concerns`   | JSONB       | string[]     |
| `llm_model`  | VARCHAR(64) | 实际用的模型 |
| `created_at` | TIMESTAMPTZ |              |

UNIQUE：`(resume_id, job_id)` —— 同一对只评一次，重评覆盖。

## crawl_tasks（核心）

> 这是「持久化任务」模型，产品爬取和职位爬取共用。

| 字段               | 类型        | 说明                                                                  |
| ------------------ | ----------- | --------------------------------------------------------------------- |
| `id`               | UUID        | PK                                                                    |
| `kind`             | VARCHAR(20) | `product` / `job`                                                     |
| `status`           | VARCHAR(20) | `pending` / `claimed` / `running` / `success` / `error` / `cancelled` |
| `payload`          | JSONB       | 任务参数（如 `{"product_ids": [...]}`）                               |
| `user_id`          | BIGINT      | 触发人                                                                |
| `worker_id`        | VARCHAR(64) | 抢任务的 worker UUID                                                  |
| `locked_at`        | TIMESTAMPTZ |                                                                       |
| `lease_expires_at` | TIMESTAMPTZ |                                                                       |
| `started_at`       | TIMESTAMPTZ |                                                                       |
| `finished_at`      | TIMESTAMPTZ |                                                                       |
| `result`           | JSONB       | 完成后回填                                                            |
| `error_message`    | TEXT        |                                                                       |
| `created_at`       | TIMESTAMPTZ |                                                                       |

INDEX：

- `(status, lease_expires_at)` — worker 抢任务
- `(kind, created_at DESC)` — 历史

## crawl_profiles

| 字段                        | 类型        | 说明                                     |
| --------------------------- | ----------- | ---------------------------------------- |
| `id`                        | BIGSERIAL   | PK                                       |
| `profile_key`               | VARCHAR(64) | UNIQUE NOT NULL                          |
| `user_id`                   | BIGINT      | 拥有者                                   |
| `description`               | TEXT        |                                          |
| `platform_hint`             | VARCHAR(20) | `boss` / `51job` / `liepin`              |
| `status`                    | VARCHAR(20) | `idle` / `locked` / `error` / `disabled` |
| `lease_worker_id`           | VARCHAR(64) | 当前占用的 worker                        |
| `lease_expires_at`          | TIMESTAMPTZ |                                          |
| `last_used_at`              | TIMESTAMPTZ |                                          |
| `error_message`             | TEXT        | 状态 error 时填                          |
| `created_at` / `updated_at` | TIMESTAMPTZ |                                          |

## crawler_workers

| 字段             | 类型         | 说明                      |
| ---------------- | ------------ | ------------------------- |
| `worker_id`      | VARCHAR(64)  | PK（启动时生成）          |
| `host`           | VARCHAR(255) | 主机名                    |
| `pid`            | INTEGER      | 进程号                    |
| `kinds`          | VARCHAR(20)  | `product` / `job` / `all` |
| `concurrency`    | INTEGER      | 当前 worker 并发          |
| `started_at`     | TIMESTAMPTZ  |                           |
| `last_heartbeat` | TIMESTAMPTZ  | **15s 刷新一次**          |

> 60s 没刷新视为 worker 死亡，lease 自动可被抢。

## smart_home_configs

| 字段                        | 类型         | 说明                 |
| --------------------------- | ------------ | -------------------- |
| `id`                        | BIGSERIAL    | PK                   |
| `user_id`                   | BIGINT       | UNIQUE（每用户一份） |
| `base_url`                  | VARCHAR(255) | HA base URL          |
| `encrypted_token`           | TEXT         | Fernet 加密          |
| `verify_ssl`                | BOOLEAN      | DEFAULT TRUE         |
| `created_at` / `updated_at` | TIMESTAMPTZ  |                      |

## smart_home_audit

| 字段                 | 类型         | 说明                |
| -------------------- | ------------ | ------------------- |
| `id`                 | BIGSERIAL    | PK                  |
| `user_id`            | BIGINT       |                     |
| `entity_id`          | VARCHAR(255) | `light.living_room` |
| `domain` / `service` | VARCHAR(50)  | `light` / `turn_on` |
| `data`               | JSONB        | service 参数        |
| `success`            | BOOLEAN      |                     |
| `error_message`      | TEXT         |                     |
| `created_at`         | TIMESTAMPTZ  |                     |

## system_logs

| 字段         | 类型        | 说明                                |
| ------------ | ----------- | ----------------------------------- |
| `id`         | BIGSERIAL   | PK                                  |
| `level`      | VARCHAR(20) | `info` / `warning` / `error`        |
| `category`   | VARCHAR(50) | `crawl` / `feishu` / `llm` / `auth` |
| `message`    | TEXT        |                                     |
| `details`    | JSONB       | 脱敏后                              |
| `created_at` | TIMESTAMPTZ |                                     |

> 全部走 `app/core/log_redaction.py` redact 后再写。

## 关系图（简化）

```text
users 1—N users_sessions
users 1—N products 1—N products_price_history
products 1—N products_alerts
products 1—N crawl_logs
users 1—N jobs_search_configs 1—N jobs
users 1—N jobs_resumes 1—N jobs_match_results
jobs_resumes 1—N jobs_match_results N—1 jobs

users N—M users_roles
users_roles N—M users_permissions

crawl_tasks 0—1 crawler_workers
crawl_profiles 0—1 crawler_workers (via lease)
```

## 详见

- [reference-api-products](reference-api-products.md) — 涉及 products / alerts / crawl_logs 的 API
- [reference-api-jobs](reference-api-jobs.md) — 涉及 jobs / resumes / configs 的 API
- [explanation-crawler-architecture](explanation-crawler-architecture.md) — `crawl_tasks` 设计
