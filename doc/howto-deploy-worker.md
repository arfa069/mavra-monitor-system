# How to 部署独立 Worker 进程（生产模式）

> 任务：把后端 API 和爬虫拆到不同机器 / 不同进程，避免爬虫拖死 API。
> 适用：生产部署、多机协作。

## 模式

| 模式        | 触发                                                 | 适用                 |
| ----------- | ---------------------------------------------------- | -------------------- |
| 内联        | 默认；`CRAWLER_INLINE_EXECUTION_ENABLED=true` 时强制 | 本地开发、单进程演示 |
| 独立 worker | `python -m app.workers.crawler --kind all`           | 生产                 |

`scripts/start_server.ps1` 默认是「API + worker 两个进程 + 前端一个进程」三个窗口。

## 步骤 1：跑 worker

同一台机器：

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; python -m app.workers.crawler --kind all"
```

参数：

| 参数                     | 默认  | 说明                                   |
| ------------------------ | ----- | -------------------------------------- |
| `--kind`                 | `all` | `all` / `product` / `job`，只跑某类    |
| `--concurrency`          | `1`   | 同进程内多任务并发数（产品爬虫硬上限） |
| `--lease-renew-seconds`  | `15`  | heartbeat 间隔                         |
| `--lease-expire-seconds` | `60`  | 超时后其他 worker 可抢                 |

多机器：起多个 worker 进程（甚至多台机器），它们**会自然争抢**任务。PostgreSQL 行锁（`SELECT ... FOR UPDATE SKIP LOCKED`）保证一个任务不会被两个 worker 同时领。

## 步骤 2：内联 vs 独立 worker 的区别

|            | 内联（API 进程内） | 独立 worker                   |
| ---------- | ------------------ | ----------------------------- |
| 触发       | 同步 await         | 写 `crawl_tasks` 行后立刻返回 |
| 失败影响   | API 请求被卡住     | 只影响这一个任务              |
| 部署复杂度 | 0                  | 多一个进程要管                |
| 调试       | 看 uvicorn 终端    | 看 `crawler-worker.log`       |

切到内联（不推荐生产用）：

```env
CRAWLER_INLINE_EXECUTION_ENABLED=true
```

`POST /crawl/crawl-now` 就会在请求上下文里同步执行爬取。但**爬虫卡死会直接拖死 API**。

## 步骤 3：worker 进程的 OOM 防护

商品爬虫开浏览器，每个 Chromium 子进程独立占内存。生产环境建议：

- 每 worker `--concurrency 1`（默认就是）
- 监控 `crawler_workers.last_heartbeat`，超过 60s 没刷就告警
- 系统层用 cgroup / Windows Job Object 限制单 worker 内存

## 步骤 4：多 worker 负载

`SELECT count(*), kind, status FROM crawl_tasks GROUP BY kind, status;` 看积压。

积压增加的处理顺序：

1. 多起 worker 进程（横向扩）
2. **不要**调高 `--concurrency`（反爬敏感）
3. 看是不是反爬失败比例高（`status=ERROR` 多）—— 那就不是并发问题，是策略问题

## 步骤 5：跨机器部署

每台机器：

1. 装好 Python、PostgreSQL 客户端、Playwright Chromium
2. `.env` 共享一个 PostgreSQL + Redis（用同一 `DATABASE_URL` / `REDIS_URL`）
3. 起 worker：`python -m app.workers.crawler --kind all`
4. 不要在多机上跑同一个 `profile_key` —— 文件锁会乱

**Profile 目录** 必须在 worker 机器上**可访问**（NFS / 共享盘 / Docker volume），不然抢同一 profile 会冲突。

## 步骤 6：健康检查

```bash
# 看 worker 是否在跑
curl -b cookies.txt http://localhost:8000/api/v1/crawl/workers
# → 返回 [{ worker_id, last_heartbeat, kinds, concurrency, ... }, ...]

# 超过 60s 没刷心跳的 worker 自动被认为宕机
# 它的任务 lease 也会被其他 worker 抢走
```

## 步骤 7：滚动升级

1. 改代码 / 重启 worker：`Stop-Process <pid>` → 再起一个
2. 任务不会丢：被这个 worker 持有的任务 lease 过期后，其他 worker 接管
3. 重启时**不要** `--concurrency 100`，慢慢起

## 监控

| 指标        | 拿法                                                                                 |
| ----------- | ------------------------------------------------------------------------------------ |
| 任务积压    | SQL count on `crawl_tasks WHERE status='pending'`                                    |
| 失败率      | SQL count on `crawl_logs WHERE status='ERROR' AND timestamp > now() - interval '1h'` |
| Worker 存活 | `crawler_workers.last_heartbeat > now() - 60s`                                       |
| 平均耗时    | `crawl_tasks` 加 `started_at` / `finished_at` 计算                                   |

## 反模式

- ❌ 跑 `--concurrency 10`：反爬会立刻把你打死
- ❌ 不开 worker 直接生产：单次失败拖死 API
- ❌ 多机共享 profile 目录用 SMB 1.0：锁不可靠
- ❌ worker 跑在前台（`Ctrl+C` 杀掉）：用 `nohup` / Windows Service 托管

## 详见

- [explanation-crawler-architecture](explanation-crawler-architecture.md) — 任务持久化、lease 心跳细节
- [tutorial-getting-started](tutorial-getting-started.md) Step 5 — 启动脚本解析
- [howto-debug-crawl](howto-debug-crawl.md) — 失败排查
