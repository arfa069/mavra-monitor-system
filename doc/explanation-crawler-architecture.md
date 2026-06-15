# 爬虫架构：Adapter、Profile 池、持久化任务、独立 Worker

> 本页解释**为什么**系统是这种形状。它在 2026-05 的一次大型重构里定型。
> 适用：所有要碰爬虫的开发者 / 运维。

## 一句话总结

爬虫子系统用「**Adapter 模式封装平台差异**、**Profile 池隔离登录态**、**持久化任务 + 独立 worker 进程**做扩展性、**Lease 心跳**做容错」四件套，把「快平台」（淘宝 / 京东 / 亚马逊，登录一次跑全网）和「慢平台」（Boss / 51job / 猎聘，每次请求都要反爬）装进同一套调度里。

## 关键问题

| 问题                     | 早期方案                | 失败模式                                        | 现在                         |
| ------------------------ | ----------------------- | ----------------------------------------------- | ---------------------------- |
| 多种平台代码全堆一个文件 | if platform == "jd" ... | 一个平台改了 selector，其它平台误伤；新人改不动 | Adapter 模式 + Strategy 子包 |
| 爬虫和 API 在同一进程    | 同步 await              | 一次失败 / 卡死拖死 API                         | 写 `crawl_tasks` 立即返回    |
| 浏览器 profile 共享      | 文件锁                  | 慢、不可靠、跨平台不行                          | DB 行锁 + lease 心跳         |
| 单 worker                | 全靠单机                | OOM / 限流                                      | 多 worker 进程争抢任务       |
| 任务超时没人接           | 任务丢失                | 卡死 30 分钟才发现                              | `lease_expires_at` 自动可抢  |

## Adapter 模式

```text
base.py                    BasePlatformAdapter (ABC)
strategies/css_selector    价格提取策略 1
strategies/js_deep_scan    价格提取策略 2（淘宝）
strategies/chained         多个策略按顺序试

taobao.py / jd.py / amazon.py  继承 Base，注入策略
boss_cloak_experimental.py     走 curl_cffi + CloakBrowser
job51.py / liepin.py           走 curl_cffi
```

**Adapter 自己负责**：

1. 启动浏览器（launch / CDP / 纯 HTTP）
2. `page.goto` + 等待（4-6s + `domcontentloaded` 而非 `networkidle`）
3. 调 Strategy 提价
4. 写 `crawl_logs` / `price_history`
5. 触发 `check_price_alerts` 飞书通知

**Adapter 不负责**：

- 任务领取（worker 抢）
- Lease 管理（`profile_pool` 包）
- 通知发送（`feishu` 包）
- 调度（APScheduler）

这条线让 Adapter 几乎是**无状态**的：一个 crawl 任务丢进去，吐出来价格或错。

## 持久化任务

所有「爬取 / LLM 匹配 / 匹配分析」都走 `crawl_tasks` 表（产品 / 职位共用同一 schema，靠 `kind` 区分）。

### 一次爬取的数据流

```text
用户 POST /crawl/crawl-now
   │
   ▼
router.py 解析，crawl_service.enqueue_crawl_task()
   │
   ▼
INSERT INTO crawl_tasks (kind='product', status='pending', payload={...})
   │
   ▼ 202 Accepted { task_id, queued }

[独立 worker 进程]
   │
   ▼ 每 5s 轮询：
   SELECT * FROM crawl_tasks
   WHERE status='pending'
   ORDER BY created_at
   FOR UPDATE SKIP LOCKED
   LIMIT 1
   │
   ▼
UPDATE crawl_tasks SET status='claimed', worker_id=?, lease_expires_at=now()+60s
   │
   ▼
CrawlTaskRunner.run(task)
   │
   ├─ ProductAdapter.crawl(...)
   ├─ 写 price_history
   ├─ 触发 check_price_alerts → 飞书
   │
   ▼
UPDATE crawl_tasks SET status='success'/'error', result=?, finished_at=now()
```

### 为什么是「写表 + 轮询」而不是 Redis 队列 / Celery

- **同一份 DB，零额外组件**：不用部署 Redis（除了缓存和 lockout） / RabbitMQ
- **事务一致**：`crawl_tasks.status` + `price_history` 写同一事务，崩溃恢复无歧义
- **可观测**：所有任务可 SQL 查询，比 celery flower 简单
- **代价**：5s 延迟（vs 队列毫秒），但爬虫本来就是分钟级任务

## Profile 池

每个 `profile_key` 对应一个本地 Chromium 目录，**同时只能被一个 worker 占用**（lease 机制）。

### 为什么要池化

- 反爬检测：同一 profile 短时间内高并发 → 必被识别为爬虫
- 登录态：Cookie 文件锁，并发读写会破坏 sessions
- 隔离：同 profile 给多平台用没问题；多 profile 给同平台可提升并发

### Lease 心跳

```text
worker 抢到 profile
   ↓
UPDATE crawl_profiles
   SET status='locked', lease_worker_id=?, lease_expires_at=now()+60s
   WHERE profile_key=? AND (status='idle' OR lease_expires_at < now())
   ↓
worker 跑任务，每 15s 续约：
   UPDATE crawl_profiles SET lease_expires_at=now()+60s WHERE lease_worker_id=?
   ↓
任务完成 → status='idle'
   OR
worker 崩了 → 60s 后 lease_expires_at 过期
   → 其他 worker 可抢
```

`lease_expires_at` 用 PostgreSQL `TIMESTAMPTZ`，行级锁自动并发安全。

### 任务粒度

- `crawl_tasks` 是「爬 N 个商品」或「爬 1 个 config」
- **N 大时单任务会跑很久**，所以 `PRODUCT_CRAWL_CONCURRENCY=1`（默认）避免内部并发引爆反爬
- 想扩并发：开**多个** profile_key，每个绑定到不同 config

## 独立 Worker 进程

### 为什么不在 FastAPI 进程内

- 爬虫是 CPU / 内存密集的（Playwright 一个浏览器 200-400MB）
- 一个慢爬能拖慢整个 uvicorn 事件循环
- 失败（OOM、segfault）应该只影响一个进程
- worker 多了能横向扩

### 进程模型

```text
[uv run --extra dev uvicorn app.main:app]             # API 进程：处理 HTTP + 写 crawl_tasks
[uv run --extra dev python -m app.workers.crawler]    # worker 进程：抢任务、跑爬虫
[uv run --extra dev python -m app.workers.crawler]    # （可选）第二个 worker：负载分摊
```

每个 worker：

1. 启动时注册 `worker_id` 到 `crawler_workers`
2. 每 15s 刷新 `last_heartbeat`
3. 主循环：`SELECT FOR UPDATE SKIP LOCKED` 抢任务
4. 任务完成或失败 → 写回 + 续 / 释放 lease
5. 优雅退出：等当前任务跑完（处理 SIGTERM）

### 部署

参见 [howto-deploy-worker](howto-deploy-worker.md)。

## 错误恢复矩阵

| 失败点           | 检测                              | 恢复                                                    |
| ---------------- | --------------------------------- | ------------------------------------------------------- |
| worker 进程崩    | 60s lease 过期                    | 其他 worker 抢                                          |
| 网络抖动         | `tenacity` 重试 3 次指数退避      | 任务标 `error`                                          |
| 平台反爬         | 状态码 403/Challenge              | 触发 `cookie_refresh` 事件                              |
| Adapter 抛错     | `try/except` 顶层                 | 任务标 `error` + `error_message`                        |
| 数据库短暂不可用 | `tenacity` 重试 + `pool_pre_ping` | 任务重试 / worker 退出                                  |
| LLM 限流         | provider 429                      | `analyze-async` 任务标 `partial`，`failed_job_ids` 记录 |

## 关键设计取舍

| 取舍                    | 我们选了            | 理由                         |
| ----------------------- | ------------------- | ---------------------------- |
| 队列 vs 写表            | **写表**            | 一致性 + 可观测 + 少一个组件 |
| 进程内爬 vs 独立 worker | **独立**            | 故障隔离 + 横向扩            |
| profile 串行 vs 并发    | **同 profile 串行** | 反爬 + 文件锁                |
| 同步 vs 异步 LLM 匹配   | **默认异步**        | 30s+ 任务阻塞 API 不行       |
| 轮询 vs 通知            | **轮询 5s**         | 5s 延迟可接受，逻辑简单      |
| 全量扫描 vs 增量        | **per-user 增量**   | 任务表天然分片               |

## 详见

- [explanation-anti-bot](explanation-anti-bot.md) — 平台反爬策略
- [explanation-scheduler](explanation-scheduler.md) — APScheduler 怎么和任务表衔接
- [explanation-sse-realtime](explanation-sse-realtime.md) — 任务状态怎么实时推前端
- [howto-deploy-worker](howto-deploy-worker.md) — 部署细节
- [howto-debug-crawl](howto-debug-crawl.md) — 失败排查
- [reference-data-model](reference-data-model.md) — `crawl_tasks` / `crawl_profiles` / `crawler_workers` 三表
