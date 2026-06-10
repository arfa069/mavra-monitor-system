# How to 添加一个商品并爬到价格

> 任务：把一个商品加进系统，让 `last_price` 列出现数字。
> 适用：商品监控、爬虫触发。

## 前置条件

- 后端、worker 都在跑（参见 [tutorial-getting-started](tutorial-getting-started.md) Step 5）
- 你是 `user` 角色（默认注册就是），且至少有 `get_current_user` 权限

## 步骤

### 1. 拿到商品页 URL

淘宝/京东/亚马逊任一商品页。例子：

```
https://item.jd.com/100012345678.html
https://detail.tmall.com/item.htm?id=123456789
https://www.amazon.com/dp/B0XXXXXX
```

### 2. 前端加商品

1. 左侧导航 → **Products**
2. 右上角 **+ Add Product**
3. 粘 URL，Platform 选 `taobao` / `jd` / `amazon`
4. 勾 **Active**
5. 保存

等价 API：

```bash
curl -X POST http://localhost:8000/api/v1/products \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{
    "url": "https://item.jd.com/100012345678.html",
    "platform": "jd",
    "active": true
  }'
```

响应（201）：

```json
{
  "id": 42,
  "user_id": 1,
  "platform": "jd",
  "url": "https://item.jd.com/100012345678.html",
  "title": null,
  "active": true,
  "created_at": "2026-06-10T08:00:00Z"
}
```

`title` 此时是 `null`，第一次爬成功后回填。

### 3. 触发爬取

前端：列表行 → **Crawl Now**。

API：

```bash
# 爬所有 active 商品
curl -X POST http://localhost:8000/api/v1/crawl/crawl-now \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt
```

或者**指定商品**（更精确的接口在 `/products/{id}/crawl`，但主路径推荐 `crawl-now` 整体触发）：

```bash
# 给单个商品加任务
curl -X POST http://localhost:8000/api/v1/products/42/crawl \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt
```

### 4. 等待 + 验证

爬取是**异步的**：

1. `POST /crawl/crawl-now` 写一行 `crawl_tasks` 表（status=`pending`）
2. Worker 抢任务（`SELECT ... FOR UPDATE SKIP LOCKED`）
3. Worker 通过 platform adapter 启动浏览器
4. 成功后写 `products_price_history`，并回填 `title`
5. 检查 `last_notified_price` 触发告警

如何看进度：

| 通道       | 接口                                 |
| ---------- | ------------------------------------ |
| 单任务状态 | `GET /api/v1/crawl/status/{task_id}` |
| 任务结果   | `GET /api/v1/crawl/result/{task_id}` |
| 日志列表   | `GET /api/v1/crawl/logs?limit=20`    |

## 验证成功的标准

- `GET /api/v1/products/42` 返回里 `title` 不为空，`last_price > 0`
- `GET /api/v1/products/42/history` 至少有 1 条记录
- `GET /api/v1/crawl/logs?product_id=42` 最近一条 status=`SUCCESS`

## 失败兜底

| 现象                    | 看哪里                                     | 见                                                              |
| ----------------------- | ------------------------------------------ | --------------------------------------------------------------- |
| 任务一直 PENDING        | `crawler-worker.log` 是否启动              | [howto-debug-crawl](howto-debug-crawl.md)                       |
| ERROR CDP not reachable | JD/淘宝需要登录                            | [tutorial-getting-started](tutorial-getting-started.md) Step 10 |
| 9 秒就 ERROR            | 反爬 403 / 风控                            | 同上                                                            |
| last_price=0            | 解析失败，看 price_history 里的 `price` 列 | 提 issue                                                        |

## 批量加

如果一次要加很多商品，用批量接口：

```bash
curl -X POST http://localhost:8000/api/v1/products/batch-create \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{
    "items": [
      {"url": "https://item.jd.com/1.html", "platform": "jd", "active": true},
      {"url": "https://item.jd.com/2.html", "platform": "jd", "active": true}
    ]
  }'
```

## 下一步

- [howto-feishu-webhook](howto-feishu-webhook.md) — 接到通知
- [howto-cron-schedule](howto-cron-schedule.md) — 改成自动爬
- [reference-api-products](reference-api-products.md) — 完整 API
