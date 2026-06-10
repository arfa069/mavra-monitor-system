# How to 配置商品 / 职位的定时爬取

> 任务：让爬取自动在固定时间跑，不用手动点。
> 适用：所有商品监控、所有职位 config。

## 两种独立调度

| 调度对象          | 表 / 字段                             | 接口                                   | cron 表达                 |
| ----------------- | ------------------------------------- | -------------------------------------- | ------------------------- |
| 商品（每平台）    | `products_platform_crons`             | `/api/v1/products/cron-configs`        | 平台级别，5 段 crontab    |
| 职位（每 config） | `jobs_search_configs.cron_expression` | `PATCH /api/v1/jobs/configs/{id}/cron` | config 级别，5 段 crontab |

调度执行器：

- `ProductCronScheduler`（`app/domains/products/cron_scheduler.py`） — 平台级
- `JobConfigScheduler`（`app/domains/jobs/scheduler.py`） — config 级

注册时机：FastAPI lifespan 启动时 `sync_all()` 把 DB 里有 cron 表达式的行注册为 APScheduler job。

## Step 1：商品平台级 cron

前端 → **Schedule** 页 → 顶部 **Product Platforms** 表格 → 选 `taobao` 行 → 输入 `0 9 * * *`（每天 9:00）→ Save。

等价 API：

```bash
curl -X POST http://localhost:8000/api/v1/products/cron-configs \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{
    "platform": "taobao",
    "cron_expression": "0 9 * * *",
    "cron_timezone": "Asia/Shanghai"
  }'
```

更新：

```bash
curl -X PATCH http://localhost:8000/api/v1/products/cron-configs/taobao \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{"cron_expression": "*/30 * * * *", "cron_timezone": "Asia/Shanghai"}'
```

（每 30 分钟一次）

## Step 2：职位 config 级 cron

前端 → **Schedule** 页 → 底部 **Job Configs** 表格 → 找到 config 行 → 输入 `0 9 * * *` → Save。

等价 API：

```bash
curl -X PATCH http://localhost:8000/api/v1/jobs/configs/3/cron \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{
    "cron_expression": "0 9 * * *",
    "cron_timezone": "Asia/Shanghai"
  }'
```

## Step 3：验证

1. `GET /api/v1/scheduler/status`（admin）应能看到：
   - `product_cron_taobao`、`product_cron_jd` 注册
   - `job_config_cron_3` 注册
   - 每条带 `next_run_time`
2. 把 cron 设成 `* * * * *`（每分钟）等一分钟，看 `backend/logs/crawler-worker.log` 是否被触发了
3. 改回正常 cron

## 权限

- 写 cron：`schedule:configure`（仅 `super_admin`）
- 读 cron：`schedule:read`（user / admin / super_admin）

所以**普通用户改不了 cron**。这是有意设计 —— 防止误操作把爬虫频次调爆。

## 时区

`cron_timezone` 用 IANA 名（`Asia/Shanghai` / `UTC` / `Europe/Berlin`）。APScheduler 会按这个时区算下次触发时间。

## 失败兜底

| 现象                      | 原因                     | 修复                                                           |
| ------------------------- | ------------------------ | -------------------------------------------------------------- |
| cron 设了不触发           | 没 super_admin 角色      | 找 super_admin 改                                              |
| `next_run_time` 一直 null | `cron_expression` 语法错 | 用 crontab.guru 验证；保存时 Pydantic 校验过但语义错误可能漏过 |
| 重启后 cron 没了          | `sync_all()` 失败        | 看 lifespan 启动日志                                           |
| cron 触发了但没爬成功     | worker 不在 / 反爬       | [howto-debug-crawl](howto-debug-crawl.md)                      |

## crontab 速查

```text
0 9 * * *       每天 9:00
*/30 * * * *    每 30 分钟
0 */2 * * *     每 2 小时整点
0 9 * * 1-5     工作日 9:00
0 0 1 * *       每月 1 号 0:00
```

5 段：`分 时 日 月 周`。

## 详见

- [explanation-scheduler](explanation-scheduler.md) — 注册 / sync / 持久化任务怎么衔接
- [tutorial-getting-started](tutorial-getting-started.md) Step 8 — 手动触发一次
- [reference-config](reference-config.md) — 全局爬虫配置（`crawl_frequency_hours` 备用）
