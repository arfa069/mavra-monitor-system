# 商品域 API 参考

> 本页是商品监控子系统的完整接口参考。
> 路由前缀：`/api/v1`（前端调用路径）。后端同时在 `/` 和 `/v1` 兼容旧客户端。
> 端点对应文件：`backend/app/domains/products/router.py`、`backend/app/domains/crawling/router.py`、`backend/app/domains/alerts/router.py`、`backend/app/domains/smart_home/router.py`、`backend/app/domains/config/router.py`。

## 通用约定

| 项       | 值                                                                      |
| -------- | ----------------------------------------------------------------------- |
| 认证     | Cookie-first；`POST/PATCH/PUT/DELETE` 需 `X-CSRF-Token` 头              |
| 业务权限 | 商品 / 告警默认 `get_current_user`；配置 / cron / Smart Home 见每端点   |
| 数据隔离 | `user_id` 强隔离；admin / super_admin 通过资源权限绕过                  |
| 响应包装 | `crawl_logs` / 爬虫任务有自己的状态端点，其它端点直接返回 ORM 对象 JSON |
| 时区     | 全部 `TIMESTAMPTZ` UTC，ISO 8601 字符串                                 |
| 价格     | `Decimal` 序列化保留 2 位小数                                           |

---

## 商品 CRUD

### `POST /api/v1/products`

创建一个商品。

**权限**：`get_current_user`

**请求体**

| 字段          | 类型   | 必填        | 说明                                        |
| ------------- | ------ | ----------- | ------------------------------------------- |
| `url`         | string | ✅          | 商品页 URL                                  |
| `platform`    | enum   | ✅          | `taobao` / `jd` / `amazon`                  |
| `active`      | bool   | 默认 `true` | 是否启用监控                                |
| `title`       | string | ❌          | 首次可空，爬取后回填                        |
| `profile_key` | string | ❌          | 绑定的爬虫 profile，CDP/Playwright 模式使用 |

**响应**（201）：`Product` JSON（`title` 可能为 `null`）

### `GET /api/v1/products`

分页查询当前用户的商品。

**查询参数**

| 参数       | 类型   | 默认 | 说明                                    |
| ---------- | ------ | ---- | --------------------------------------- |
| `page`     | int    | 1    | 1-based                                 |
| `size`     | int    | 15   | 上限 100                                |
| `platform` | enum   | —    | 过滤                                    |
| `active`   | bool   | —    | 过滤                                    |
| `keyword`  | string | —    | title / url 模糊搜索（前端 400ms 防抖） |

**响应**

```json
{
  "items": [/* Product[] */],
  "total": 100,
  "page": 1,
  "page_size": 15,
  "total_pages": 7,
  "has_next": true,
  "has_prev": false
}
```

排序：`created_at DESC, id DESC` —— **新插入不导致分页漂移**。

### `GET /api/v1/products/{id}`

单个商品详情，含 `last_price` / `last_scraped_at`（由后端 join 计算）。

### `GET /api/v1/products/{id}/history`

价格历史，按 `scraped_at DESC` 倒序。

**查询参数**：`from` / `to`（ISO 8601）、`limit`（默认 100）

### `PATCH /api/v1/products/{id}`

部分更新。可改 `active` / `title` / `url` / `profile_key`。

### `DELETE /api/v1/products/{id}`

软删除。`crawl_tasks` / `crawl_logs` / `price_history` 不会被删，可观察历史。

### 批量

| 方法 | 端点                            | 说明                                                             |
| ---- | ------------------------------- | ---------------------------------------------------------------- |
| POST | `/api/v1/products/batch-create` | body `{"items": [...]}`，上限 200                                |
| POST | `/api/v1/products/batch-delete` | body `{"ids": [...]}`，原子事务                                  |
| POST | `/api/v1/products/batch-update` | body `{"ids":[...], "patch":{...}}`，统一改 active / profile_key |

---

## 商品定时（每平台）

### `GET /api/v1/products/cron-configs`

列出 3 个平台的 cron 配置。

### `POST /api/v1/products/cron-configs`

**请求体**

| 字段              | 类型   | 必填                 | 说明                       |
| ----------------- | ------ | -------------------- | -------------------------- |
| `platform`        | enum   | ✅                   | `taobao` / `jd` / `amazon` |
| `cron_expression` | string | ✅                   | 5 段 crontab               |
| `cron_timezone`   | string | 默认 `Asia/Shanghai` | IANA 名                    |

**权限**：`schedule:configure`（仅 `super_admin`）

### `PATCH /api/v1/products/cron-configs/{platform}`

### `DELETE /api/v1/products/cron-configs/{platform}`

### `GET /api/v1/products/cron-schedules`

返回所有 cron 的 `next_run_time`（admin / super_admin）

---

## 降价告警

### `POST /api/v1/alerts`

**请求体**

| 字段                | 类型    | 必填        | 说明              |
| ------------------- | ------- | ----------- | ----------------- |
| `product_id`        | int     | ✅          | 必须属于当前用户  |
| `threshold_percent` | decimal | ✅          | `0.01` - `100.00` |
| `active`            | bool    | 默认 `true` | 暂停告警用        |

### `GET /api/v1/alerts`

列出当前用户的所有告警。可选 `?product_id=` 过滤。

### `PATCH /api/v1/alerts/{id}` / `DELETE /api/v1/alerts/{id}`

### 触发逻辑

`check_price_alerts(product_id)` 在每次成功爬后调用：

- 取最近两次价格历史
- `(old - new) / old * 100 >= threshold_percent`
- 推送飞书 webhook（节流 24h）

---

## 爬虫控制

### `POST /api/v1/crawl/crawl-now`

**权限**：`crawl:execute`

立即为所有 `active` 商品入队一个爬取任务。

**响应**（202）：

```json
{
  "task_id": "uuid",
  "queued": 5,
  "kind": "product"
}
```

### `GET /api/v1/crawl/status/{task_id}`

轮询任务状态。值：`pending` / `claimed` / `running` / `success` / `error` / `cancelled`

### `GET /api/v1/crawl/result/{task_id}`

任务完成时返回的最终结果（成功 / 错误堆栈）。

### `GET /api/v1/crawl/logs`

**查询参数**：`limit`（默认 50）、`product_id`（过滤）、`status`（过滤 `SUCCESS` / `ERROR` / `SKIPPED`）

### `GET /api/v1/crawl/workers`

列出当前所有 worker 进程及其心跳。

### `POST /api/v1/crawl/cleanup`

**权限**：`crawl:execute`

**查询参数**：`retention_days`（不能大于用户配置 `data_retention_days`）

清理过期的 `crawl_logs` 和 `price_history`。

### `GET /api/v1/scheduler/status`

**权限**：`require_role("admin", "super_admin")`

返回所有注册过的 APScheduler job（产品 / 职位 cron）的 `next_run_time` / `trigger`。

---

## 用户配置

### `GET /api/v1/config`

**权限**：`config:read`

```json
{
  "feishu_webhook_url": "...",
  "data_retention_days": 365,
  "crawl_frequency_hours": 1,
  "crawl_cron": null,
  "crawl_timezone": "Asia/Shanghai"
}
```

### `POST /api/v1/config`

**权限**：`config:write`（admin / super_admin）

全量替换。

### `PATCH /api/v1/config`

**权限**：`config:write`（admin / super_admin）

部分更新；合法字段：`feishu_webhook_url` / `data_retention_days` / `crawl_cron` / `crawl_timezone` / `crawl_frequency_hours`。

> 注：商品 / 职位的 cron 现在走 `/products/cron-configs` 和 `/jobs/configs/{id}/cron`，不再用这里的 `crawl_cron`。该字段保留仅作迁移期兼容。

---

## Smart Home（轻量跨域引用）

完整路径：`/api/v1/smart-home/*`（详见 [reference-api-products](reference-api-products.md) § Smart Home 段或后续 `reference-smart-home.md`）。

| 方法      | 端点                          | 权限                   | 说明                                                  |
| --------- | ----------------------------- | ---------------------- | ----------------------------------------------------- |
| GET / PUT | `/smart-home/config`          | `smart_home:configure` | base_url + Fernet 加密 token                          |
| POST      | `/smart-home/config/test`     | `smart_home:configure` | 测连通性                                              |
| GET       | `/smart-home/entities`        | `smart_home:read`      | 列实体                                                |
| POST      | `/smart-home/services/call`   | `smart_home:control`   | 调 service，body `{entity_id, service, service_data}` |
| GET       | `/smart-home/entities/stream` | `smart_home:read`      | SSE                                                   |

---

## Dashboard

| 方法 | 端点                       | 权限     | 说明                                                                  |
| ---- | -------------------------- | -------- | --------------------------------------------------------------------- |
| GET  | `/dashboard/kpi`           | `user`+  | KPI 卡片聚合                                                          |
| GET  | `/dashboard/events`        | 已登录   | SSE 实时 KPI 增量                                                     |
| GET  | `/dashboard/trends`        | `user`+  | 趋势图，参数 `type=price\|jobs\|matches\|platforms`、`days=7\|30\|90` |
| GET  | `/dashboard/alerts/recent` | `admin`+ | 平台级最近告警                                                        |

---

## 错误码

| 状态 | 含义                 | 触发                                                 |
| ---- | -------------------- | ---------------------------------------------------- |
| 400  | 业务校验失败         | Pydantic 校验、cron 解析、空 `SMART_HOME_SECRET_KEY` |
| 401  | 认证失败             | Cookie 缺失 / 过期                                   |
| 403  | 权限不足 / CSRF 失败 | RBAC / 缺 `X-CSRF-Token`                             |
| 404  | 资源不存在           | 商品 / 告警跨用户                                    |
| 409  | 状态冲突             | profile 已被其他 task 占用                           |
| 422  | 请求体 / 字段格式错  | Pydantic 422 detail                                  |
| 429  | 频次超限             | 登录失败 5 次锁 15 分钟                              |
| 5xx  | 后端故障             | 看 `uvicorn` / worker 日志                           |

详见 [`backend/docs/auth-error-codes.md`](../backend/docs/auth-error-codes.md)。

## 详见

- [howto-add-product](howto-add-product.md) — 加商品流程
- [reference-data-model](reference-data-model.md) — 涉及的所有表
- [explanation-crawler-architecture](explanation-crawler-architecture.md) — 为什么是任务持久化 + worker
