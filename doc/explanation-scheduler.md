# 调度系统：APScheduler × per-platform cron × per-config cron × 持久化任务

> 解释**为什么**调度是「APScheduler 注册 cron + 触发后写 crawl_tasks 排队」这套双层设计。
> 适用：改 cron / 改调度 / 加新定时任务的人。

## 一句话

> **APScheduler 只负责「到了」**；**真正干活**交给持久化任务 + 独立 worker。

## 关键问题

| 现象                           | 早期方案                   | 失败                                       |
| ------------------------------ | -------------------------- | ------------------------------------------ |
| 定时 + 爬取都在 FastAPI 进程内 | `asyncio.create_task` 跑爬 | API 重启 → 任务全丢；慢任务拖死 event loop |
| 单一 cron 表达式               | `crontab.guru` 一个        | 商品 / 职位 / 全局配置混在一起             |
| 同步爬                         | 阻塞                       | 卡死 90s                                   |
| 没持久化                       | APScheduler 内存任务       | 看不出任务历史、失败了难追溯               |

## 双层结构

```text
[APScheduler 内存]                   [持久化任务（crawl_tasks 表）]
   │                                       ▲
   │ 到点触发                              │
   ▼                                       │ 写一行
JobConfigScheduler.run()  ──────────►  enqueue_crawl_task()
ProductCronScheduler.run()                │
                                          ▼
                                   [独立 worker 抢]
                                          │
                                          ▼
                                    Adapter 跑爬
```

### 第一层：APScheduler

- 商品平台 cron：`products_platform_crons` 表 → `ProductCronScheduler` 内存注册
- 职位 config cron：`jobs_search_configs.cron_expression` → `JobConfigScheduler` 内存注册

### 第二层：crawl_tasks

- **入队**：所有爬取动作（cron 触发 / 手动 `crawl-now` / LLM 匹配）都写 `crawl_tasks`
- **执行**：独立 worker 进程抢任务
- **可观测**：`GET /crawl/status/{id}`、`GET /crawl/result/{id}`

为什么拆开：

- APScheduler 内存任务**不能被多机共享** —— 把「到了」从「跑完」解耦后，可以横向加 worker
- 写表是事务一致的 —— 任务入队 + 参数持久化一次性原子完成
- 任务历史可查 —— 失败 / 重试 / 进度都能看

## 注册时机

```text
FastAPI lifespan startup
   ↓
_start_scheduler()  # app/main.py
   ↓
ProductCronScheduler.sync_all()  # 从 products_platform_crons 读
JobConfigScheduler.sync_all()   # 从 jobs_search_configs 读
   ↓
APScheduler.add_job(...)  # 内存注册
```

`sync_all()` 是**幂等**的：每次启动都重新注册，不会重复也不会漏（取决于 APScheduler 替换 job 策略）。

新增 cron 不需要重启：

- 商品平台：调 `POST /products/cron-configs` → DB 写行 → `ProductCronScheduler.sync_one(platform)`（admin API 内调用）
- 职位 config：调 `PATCH /jobs/configs/{id}/cron` → DB 改字段 → `JobConfigScheduler.sync_one(config_id)`

## 时区

每个 cron 行带 `cron_timezone`（IANA 名），APScheduler 算 `next_run_time` 时按这个时区。

全局默认 `SCHEDULER_TIMEZONE=Asia/Shanghai`，但 cron 行可以覆盖（多用户不同时区友好）。

## 触发后的链路

```text
APScheduler 到点
   ↓
scheduler_service.crawl_products_by_platform('taobao')
   ↓
enqueue_crawl_task(
    kind='product',
    payload={'platform': 'taobao', 'user_id': None /* 所有用户 */}
)
   ↓
[worker] SELECT FOR UPDATE SKIP LOCKED
   ↓
product_service.crawl_all_active(platform='taobao')
   ↓
为每个 active product 调对应 Adapter
   ↓
写 products_price_history
   ↓
触发 check_price_alerts → 飞书
```

## 全局 cron 备选

`/api/v1/config` 的 `crawl_cron` 字段是**更老的接口**，保留是迁移期兼容。

新代码不要用。请用 `/products/cron-configs`（平台级）或 `/jobs/configs/{id}/cron`（config 级）。

## APScheduler 选型

我们用 `apscheduler.schedulers.asyncio.AsyncIOScheduler`，原因：

- 与 FastAPI `asyncio` 事件循环兼容
- 简单（vs Celery beat 那种重组件）
- 单进程够用（启动后 `sync_all()` 内存注册）
- 出问题日志可读

## 失败模式

| 现象                        | 原因                 | 修复                                                             |
| --------------------------- | -------------------- | ---------------------------------------------------------------- |
| cron 到了不触发             | lifespan 启动失败    | 看 uvicorn 启动日志                                              |
| cron 触发了但任务 PENDING   | worker 没起          | [howto-deploy-worker](howto-deploy-worker.md)                    |
| 时区错                      | `cron_timezone` 写错 | 用 IANA 名                                                       |
| `next_run_time` 一直是 null | cron 解析失败        | 写时 Pydantic 校验过但语义错会漏过                               |
| 多机部署每机都跑一次        | APScheduler 不去重   | **不**支持多机；要么用单实例 + 多 worker，要么改用外部 scheduler |

> 单 APScheduler 实例是设计上的简化。多机部署请用**单 API 实例**（lifespan 跑 scheduler） + **多 worker 实例**（抢 crawl_tasks）。

## 性能

| 指标                      | 数                                 |
| ------------------------- | ---------------------------------- |
| 注册 100 个 cron 启动耗时 | < 1s                               |
| `next_run_time` 计算      | O(1) per job（APScheduler 用算法） |
| `sync_all()` 100 行       | 200ms（一次 SQL + 内存加 job）     |

不需要为 cron 数量焦虑。

## 详见

- [howto-cron-schedule](howto-cron-schedule.md) — 怎么配
- [explanation-crawler-architecture](explanation-crawler-architecture.md) — 任务表设计
- [reference-data-model](reference-data-model.md) § crawl_tasks
- [reference-config](reference-config.md) § 调度变量
