# How to 接入飞书 Webhook 接收降价 / 新职位通知

> 任务：让降价或新职位时，消息推到你的飞书机器人。
> 适用：所有需要通知的场景。

## 飞书侧

1. 进飞书群 → 设置 → 群机器人 → **添加机器人** → **自定义机器人**
2. 安全设置选**自定义关键词**（推荐 `价格` 或 `降价`）或 IP 白名单
3. 复制 Webhook URL，**不要外传**

URL 形如 `https://open.feishu.cn/open-apis/bot/v2/hook/<your-key>`。

## 项目侧

### 方式 A：环境变量（全局默认）

`.env` 写：

```env
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/<your-key>
```

适用：单机 / 演示。**所有用户共用同一个 webhook**。

### 方式 B：用户级配置（推荐）

每个用户在前端 **Settings** 页填自己的 webhook，覆盖环境变量。

等价 API：

```bash
curl -X PATCH http://localhost:8000/api/v1/config \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{"feishu_webhook_url": "https://open.feishu.cn/open-apis/bot/v2/hook/<your-key>"}'
```

读取当前值：

```bash
curl -b cookies.txt http://localhost:8000/api/v1/config
# { ..., "feishu_webhook_url": "https://..." }  （环境变量或用户值优先）
```

优先级：**用户级 PATCH 值 > 环境变量**。

## 触发点

| 事件       | 触发位置                                                          | 节流                                                |
| ---------- | ----------------------------------------------------------------- | --------------------------------------------------- |
| 商品降价   | `app/domains/crawling/service.py:check_price_alerts` 每次爬成功后 | `last_notified_price < new_price` 且不在 24h 内重复 |
| 职位新出现 | `app/domains/jobs/crawl_service.py:process_new_jobs`              | 按 `first_seen_at` 判定                             |
| 告警激活   | `app/domains/alerts/router.py` 创建时                             | 不发 webhook                                        |

## 消息格式

**降价**：

```text
Price Drop Alert: <title>
Platform: jd
Old Price: ¥299.00 CNY
New Price: ¥259.00 CNY
Drop: 13.38%
Link: https://item.jd.com/100.html
```

**新职位**：

```text
New Job Alert: <title>
Company: <company>
Salary: <salary>
Location: <location>
Link: <url>
```

> 群机器人对关键词敏感时，关键词必须出现在消息里。当前消息含 `Price Drop Alert` / `New Job Alert`，配 `价格` / `新职位` 关键词都行。

## 验证

加一个 0.1% 阈值的告警，把商品价格手动改低一点，下一次爬取后：

1. 飞书群收到消息
2. `products_alerts.last_notified_at` 更新
3. 24 小时内不会重复推（`last_notified_price` 防抖）

## 失败兜底

| 现象                               | 原因                 | 修复                                       |
| ---------------------------------- | -------------------- | ------------------------------------------ |
| 消息发不出去                       | Webhook 关键词不匹配 | 改飞书端安全设置（IP 白名单 / 任意关键词） |
| HTTP 403                           | Feishu 拒绝 / 群被封 | 重新建机器人                               |
| 报 `feishu_webhook_url is empty`   | 没人配置             | 先 PATCH /config 或填 .env                 |
| Worker 报 `feishu retry exhausted` | 网络 / 飞书限流      | 看 `backend/logs/feishu_retry.log`         |

`send_feishu_notification` 自带 3 次重试 + 指数退避（`tenacity` 实现），单次失败不丢任务。

## 进阶：自定义 payload

目前 `app/integrations/feishu.py` 走的是飞书的「text / message card」协议，**不支持 Markdown 直接渲染**。如果你想加富文本：

1. 改 `app/integrations/feishu.py` 把 `msg_type` 改 `interactive` 并加 `card` 字段
2. 写测试覆盖新格式
3. 飞书侧不需要任何改动

## 下一步

- [howto-add-product](howto-add-product.md) — 加商品并配告警
- [reference-config](reference-config.md) — 完整环境变量
- [reference-api-products](reference-api-products.md) — `/alerts` 端点
