# 职位域 API 参考

> 本页是职位监控子系统的完整接口参考。
> 路由前缀：`/api/v1`。
> 端点对应文件：`backend/app/domains/jobs/router.py`、`backend/app/domains/scheduling/router.py`。

## 子域

| 子域         | 端点前缀                                                   | 说明                       |
| ------------ | ---------------------------------------------------------- | -------------------------- |
| 搜索配置     | `/api/v1/jobs/configs`                                     | Boss/51job/猎聘 的搜索条件 |
| 简历         | `/api/v1/jobs/resumes`                                     | LLM 匹配用的简历文本       |
| 匹配结果     | `/api/v1/jobs/match-results`                               | LLM 给的简历 vs 职位评分   |
| 异步任务     | `/api/v1/jobs/tasks/{task_id}`                             | 异步匹配分析的状态轮询     |
| 爬取         | `/api/v1/jobs/crawl-now`、`/crawl/status`、`/crawl/result` | 手动 / 调度触发的爬取任务  |
| 爬虫 Profile | `/api/v1/crawl-profiles`                                   | 浏览器 profile 池管理      |
| 调度器       | `/api/v1/jobs/scheduler/job-configs`                       | per-config cron 状态       |

---

## 搜索配置（configs）

### `GET /api/v1/jobs/configs`

**查询参数**：`active` / `platform` / `keyword` / `page` / `size`

### `POST /api/v1/jobs/configs`

**请求体**

| 字段                     | 类型     | 必填                 | 说明                                    |
| ------------------------ | -------- | -------------------- | --------------------------------------- |
| `name`                   | string   | ✅                   | 任意 1-100 字符                         |
| `url`                    | string   | ✅                   | 平台搜索页 URL（Boss / 51job / 猎聘）   |
| `active`                 | bool     | 默认 `true`          |                                         |
| `notify_on_new`          | bool     | 默认 `true`          | 推送飞书                                |
| `deactivation_threshold` | smallint | 默认 `3`             | 连续 N 次没出现就标记 `is_active=false` |
| `cron_expression`        | string   | ❌                   | 5 段 crontab                            |
| `cron_timezone`          | string   | 默认 `Asia/Shanghai` |                                         |
| `profile_key`            | string   | ❌                   | 必填 for Boss；51job / 猎聘可选         |

### `GET /api/v1/jobs/configs/{id}`

### `PATCH /api/v1/jobs/configs/{id}`

可改所有字段。

### `DELETE /api/v1/jobs/configs/{id}`

### `PATCH /api/v1/jobs/configs/{id}/cron`

**权限**：`schedule:configure`（仅 super_admin）

```json
{ "cron_expression": "0 9 * * *", "cron_timezone": "Asia/Shanghai" }
```

单独更新 cron，避免覆盖其他字段。

---

## 简历（resumes）

### `GET /api/v1/jobs/resumes`

返回当前用户所有简历。`is_active=true` 的是 LLM 匹配时使用的。

### `POST /api/v1/jobs/resumes`

```json
{
  "name": "前端工程师-2026",
  "content": "## 简介\n3 年 React 经验...",
  "is_active": true
}
```

### `PATCH /api/v1/jobs/resumes/{id}`

### `DELETE /api/v1/jobs/resumes/{id}`

只有一份 `is_active` 简历能进 LLM 匹配。设另一份 `is_active=true` 会自动把旧的关掉。

---

## 匹配结果

### `GET /api/v1/jobs/match-results`

**查询参数**：`resume_id` / `job_id` / `min_score`（默认 0）/ `page` / `size` / `sort`（`score_desc` 默认 / `created_desc`）

每行含 `score` (0-100)、`reason`（LLM 解释）、`highlights[]`、`concerns[]`。

### `POST /api/v1/jobs/match-results/analyze`

**同步**，耗时 30s-3min，**不推荐**生产用。Body：`{ "resume_id": 1, "job_ids": [1,2,3,...] }`

### `POST /api/v1/jobs/match-results/analyze-async`

**异步**，立即返回 `task_id`。Body 同上。

### `GET /api/v1/jobs/tasks/{task_id}`

轮询。`status` ∈ `pending` / `running` / `success` / `error` / `partial`（部分成功）。

`status=partial` 时，`result.failed_job_ids` 给出失败列表。

---

## 触发爬取

### `POST /api/v1/jobs/crawl-now`

**权限**：`crawl:execute`

为所有 `active` config 入队一个 crawl 任务。`config_id` 留空。

**响应**

```json
{
  "task_id": "uuid",
  "queued": 3,
  "kind": "job"
}
```

### `POST /api/v1/jobs/crawl-now/{config_id}`

只爬单个 config。

### `GET /api/v1/jobs/crawl/status/{task_id}`

### `GET /api/v1/jobs/crawl/result/{task_id}`

`result.items` 是这次爬取发现的（新增 + 仍存在的）职位列表。

---

## 爬虫 Profile 池

`/api/v1/crawl-profiles/*` 端点。详见 [howto-boss-profile](howto-boss-profile.md)。

| 方法   | 端点                                        | 权限     | 说明                                    |
| ------ | ------------------------------------------- | -------- | --------------------------------------- |
| GET    | `/crawl-profiles`                           | 已登录   | 列出所有 profile（自己的 + 公开共享的） |
| POST   | `/crawl-profiles`                           | 已登录   | 创建新 profile                          |
| PATCH  | `/crawl-profiles/{key}`                     | 已登录   | 改 status / platform_hint / error       |
| DELETE | `/crawl-profiles/{key}`                     | 已登录   | 必须 idle 且无引用                      |
| POST   | `/crawl-profiles/{key}/rename`              | 已登录   | body `{"new_key": "..."}`，同步改引用   |
| POST   | `/crawl-profiles/{key}/copy`                | 已登录   | body `{"new_key": "..."}`               |
| POST   | `/crawl-profiles/{key}/test`                | 已登录   | 测 profile 浏览器能不能开               |
| POST   | `/crawl-profiles/{key}/login-session`       | 已登录   | 弹浏览器登录                            |
| POST   | `/crawl-profiles/{key}/login-session/close` | 已登录   | 关闭浏览器                              |
| POST   | `/crawl-profiles/{key}/release-stale`       | 已登录   | 释放过期 lease                          |
| POST   | `/crawl-profiles/{key}/export`              | `admin`+ | 加密 zip 备份                           |
| POST   | `/crawl-profiles/import`                    | `admin`+ | multipart file                          |
| GET    | `/crawl-profiles/runtime-capabilities`      | 已登录   | 当前 worker 支持的浏览器 / 平台         |

---

## 调度

### `GET /api/v1/jobs/scheduler/job-configs`

返回所有 job config 的 cron 注册状态（含 `next_run_time`）。

---

## 事件中心

事件中心是另一个域（`/api/v1/events`）：

- `GET /events?level=info|warning|error&category=audit|system|platform&from=&to=` — 分页历史
- `GET /events/stream` — SSE 实时

事件载荷**经过 redact**（cookie / token / webhook / 密码 → `***REDACTED***`），详见 [explanation-sse-realtime](explanation-sse-realtime.md)。

---

## 错误码

与商品域一致，补充：

| 状态 | 触发                         |
| ---- | ---------------------------- |
| 409  | profile 已被 lease 占用      |
| 422  | cron 解析失败 / 简历内容超长 |
| 503  | LLM provider 不可用          |

LLM provider 通过 `LLMProviderFactory` 切换（`app/domains/jobs/llm/`），支持 `minimax` / `anthropic` / `openai` / `ollama`。

## 详见

- [tutorial-job-monitoring](tutorial-job-monitoring.md) — 跑通一次
- [howto-boss-profile](howto-boss-profile.md) — profile 池
- [explanation-anti-bot](explanation-anti-bot.md) — 平台差异
