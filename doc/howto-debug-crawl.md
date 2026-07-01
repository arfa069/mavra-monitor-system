# How to 排查爬虫失败

> 任务：商品 / 职位爬取没出结果，从哪里开始看。
> 适用：所有 `crawl_logs` 出现 `ERROR` 或任务一直 `PENDING` 的场景。

## 一分钟流程图

```text
任务一直 PENDING  →  看 worker 是否在跑
                     ↓
                 不是 → 启动 worker (start_server.ps1)
                 是   → 看 task_runner.py 日志

任务 ERROR          →  分三段定位：
                       1. 浏览器启动（CDP / profile）
                       2. 页面加载（networkidle / timeout）
                       3. 价格 / 字段解析（selectors 错）
```

## 关键日志位置

| 日志            | 路径                                             | 用途                             |
| --------------- | ------------------------------------------------ | -------------------------------- |
| Worker 主日志   | `backend/logs/crawler-worker.log`                | 任务领取 / 错误堆栈              |
| Boss 专属 JSONL | `backend/logs/boss_cloak_adapter_<时间戳>.jsonl` | Boss 列表 / 详情 / cookie 刷新   |
| 商品爬取日志    | `crawl_logs` 表（`GET /api/v1/crawl/logs`）      | 业务层 success / error / skipped |
| 飞书重试        | `backend/logs/feishu_retry.log`（如果有）        | 通知失败                         |
| 后端运行日志    | uvicorn 终端窗口                                 | 路由 / DB                        |

## 任务一直 PENDING

Worker 没抢到任务。原因：

1. **没启动 worker**：`scripts/start_server.ps1` 会自动起一个 `-NoCrawlerWorker` 才会跳过。手动起：
   ```powershell
   powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; python -m app.workers.crawler --kind all"
   ```
2. **数据库锁**：另一个 worker 拿了任务但没释放。看 `crawl_tasks.locked_at` / `lease_expires_at`。
3. **DB 写满了**：`pg_stat_activity` 看活跃连接 / `disk usage`。

修复：先 `Stop-Process` 卡住的 worker，**再**重启。

## 任务 ERROR 拆解

### 1. 浏览器启动失败

```
playwright._impl._errors.Error: BrowserType.launch: Executable doesn't exist
```

→ `playwright install chromium`

```
BrowserType.connect_over_cdp: connect ECONNREFUSED 127.0.0.1:9222
```

→ CDP 模式的 Edge 没起来，或端口不对。开 Edge：

```powershell
"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --remote-debugging-port=9222
```

### 2. 页面加载超时

```
TimeoutError: Page.goto: Timeout 90000ms exceeded
```

- 把 `CRAWLER_HEADLESS=false` 重跑，看真实页面
- 检查商品 URL 是否能浏览器打开
- 看 `page.on('response')` 是否 403 / 风控

### 3. 价格解析失败

```
ExtractionError: no price selector matched
```

- 平台页面改版，selector 失效
- 看 `app/platforms/strategies/` 选哪种策略：
  - `css_selector.py` — 普通商品
  - `js_deep_scan.py` — 淘宝专用（需要等 JS 跑完）
  - `chained.py` — 多个策略链

修复：到 `app/platforms/<platform>.py` 调 selector。

### 4. Boss 频繁 cookie 刷新

`boss_cloak_adapter_*.jsonl` 里 `cookie_refresh` 事件多：

```text
"event": "cookie_refresh",
"trigger_status": 36
```

说明列表 / 详情被风控拒绝。处理顺序：

1. 重新 `Login Session`（profile cookie 失效）
2. 多个 job config 共用同一 profile 串行起疑，分流
3. 调 `sleep` 区间（`app/platforms/boss_cloak_experimental.py:REQUEST_DELAYS`）

### 5. Liepin Challenge 拦截

`adapter_logs/liepin` 里 `status 412`：

- 没给 profile → Windows 下提供 profile path 让 DPAPI 解 cookie
- 给 profile 仍失败 → 重跑 `Login Session`，因为 `crypt_unprotect` 解出来空 cookie

## 任务 SUCCESS 但 last_price=0

大概率**字段解析返回 0** 而不是失败：

- 看 `crawl_logs.price` 列
- 看 `crawl_logs.error_message`（如果填了「`price=0` selector matched but value invalid」）
- 跑一次商品的 `GET /api/v1/products/{id}` 触发手动解析

## 任务 SUCCESS 但没飞书通知

通知触发位置：`app/domains/crawling/service.py:check_price_alerts` 每次成功爬后调。可能的「静默」原因：

| 原因                             | 排查                                                                      |
| -------------------------------- | ------------------------------------------------------------------------- |
| 没设 alert                       | `GET /api/v1/alerts?product_id=42`                                        |
| 阈值太大                         | 改 `threshold_percent`                                                    |
| 24h 内已通知过                   | `last_notified_at` 看时间                                                 |
| `last_notified_price` 仍 >= 新价 | 数据库手动 `UPDATE products_alerts SET last_notified_price=NULL` 强制重发 |
| Webhook URL 空                   | `GET /api/v1/config`                                                      |

## 跑一次 BrowserSession 单步

```python
# powershell 进 backend/ 目录后
uv run --extra dev python -c "
import asyncio
from app.platforms.jd_opencli import crawl_jd_via_opencli

async def main():
    result = await crawl_jd_via_opencli('https://item.jd.com/100012345678.html')
    print(result)

asyncio.run(main())
"
```

这样能直接看到浏览器窗口 + 解析日志，比跑全链路快。

## 性能

- 单商品爬取：6-15 秒（视平台）
- 50 个商品全量：5-15 分钟（看 `PRODUCT_CRAWL_CONCURRENCY`）
- 全量突然变慢：
  - `pg_stat_statements` 看是不是 DB 慢查询
  - `cache hit` 看 Redis（`app/core/redis_client.py`）
  - 反爬频次：检查最近 1h 是不是被风控了

## 详见

- [tutorial-getting-started](tutorial-getting-started.md) Step 9-10 — 第一次失败如何兜底
- [explanation-anti-bot](explanation-anti-bot.md) — 平台风控触发原因
- [explanation-crawler-architecture](explanation-crawler-architecture.md) — 任务 / worker / profile 池怎么连
