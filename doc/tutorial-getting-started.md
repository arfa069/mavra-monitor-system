# 入门：把第一个商品的降价通知发到飞书

> 适用读者：第一次接触 mavra-monitor-system，想从 0 到 1 跑通核心流程。
> 目标：20 分钟内让一个京东商品的降价通知出现在飞书群里。

## 你将看到什么

完成本教程后，你将得到：

- 一台本机运行的后端（端口 8000）+ 前端（Flutter Web，端口 3000）+ 一个爬虫 worker
- 一个京东商品加入监控
- 当价格下降 ≥ 5% 时，飞书机器人自动推送一条消息

## Step 1：环境准备

需要的工具：

| 工具       | 版本  | 检查命令              |
| ---------- | ----- | --------------------- |
| Python     | 3.11+ | `python --version`    |
| Node.js    | 18+   | `node --version`      |
| PostgreSQL | 13+   | `psql --version`      |
| Redis      | 6+    | `redis-cli --version` |
| PowerShell | 5+    | Windows 自带          |

> Windows 用户：所有命令都通过 `powershell.exe -Command "..."` 包装执行，详见 [`AGENTS.md` §3](../AGENTS.md)。

## Step 2：克隆与安装

```powershell
git clone <your-fork-url> mavra-monitor-system
cd mavra-monitor-system
powershell.exe -Command "cd backend; uv sync --extra dev"
powershell.exe -Command "cd frontend; flutter pub get"
```

## Step 3：写 .env

在**项目根目录**（不是 `backend/`）新建 `.env`：

```env
# 必填：PostgreSQL 异步连接
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/pricemonitor

# 必填：Redis
REDIS_URL=redis://localhost:6379/0

# 必填：飞书 Webhook
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/<your-key>

# 必填：智能家居 token 加密密钥（即使是空也要填一个 32 字节 base64）
# 生成方式：uv run --project backend --extra dev python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
SMART_HOME_SECRET_KEY=<your-fernet-key>

# 必填：CORS 允许的前端源
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

完整字段列表见 [`reference-config.md`](reference-config.md)。

## Step 4：初始化数据库

```powershell
powershell.exe -Command "cd backend; uv run --extra dev alembic upgrade head"
```

期望输出末尾：`Running upgrade  -> <hash>, <message>`。

## Step 5：启动服务

```powershell
powershell.exe -Command "powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1' -NoBlogFrontend"
```

`start_server.ps1` 默认使用 `backend/.venv/Scripts/python.exe`，会做四件事：

1. 杀掉占用 3000 / 8000 端口的旧进程
2. 启动后端（uvicorn，无 `--reload`，因为 Windows 上 Playwright 子进程会崩）
3. 启动爬虫 worker（`python -m app.workers.crawler --kind all`，使用后端虚拟环境）
4. 启动前端（Flutter Web，端口 3000）

验证：

- 前端 <http://localhost:3000> 打开应看到登录页
- 后端健康检查：<http://localhost:8000/health> 返回 `{"status":"ok"}`

## Step 6：注册并登录

1. 浏览器打开 <http://localhost:3000>
2. 第一次没有账号，点 **Sign Up** / 注册
3. 用户名 3-50 字符，密码至少 10 位且**必须同时包含**大写字母、小写字母、数字、特殊字符（例如 `MyPass1234!`）
4. 注册成功后自动跳转登录
5. 登录后默认进入 `/today`

> 强密码是 2026-06 commit `052158a1` 引入的，详见 [explanation-auth-rbac](explanation-auth-rbac.md)。

## Step 7：填入飞书 Webhook

1. 左侧导航 → **Settings**
2. 把 Step 3 里那个 `FEISHU_WEBHOOK_URL` 粘进去（这是用户级配置，会覆盖 .env 默认值）
3. 点 **Save**

这一步等价于调用 `PATCH /api/v1/config` 把 `feishu_webhook_url` 写进 `users` 表。

## Step 8：添加第一个商品

1. 左侧导航 → **Products**
2. 右上角 **Add Product**
3. URL 粘一个京东商品页（例如 `https://item.jd.com/100012345678.html`）
4. Platform 自动识别为 `jd`，也可手动选 `taobao` / `amazon`
5. 勾选 **Active**
6. 保存

调用栈：前端 `POST /api/v1/products` → 后端 `app/domains/products/router.py` → `Product` ORM 写入。

## Step 9：手动爬一次

回到 **Products** 列表，找到刚加的商品行，点 **Crawl Now**。

**你应该立刻看到**：

- 列表里 `Last price` 出现一个数字
- `Crawl logs` 标签页多一条 `SUCCESS` 记录

第一次爬不到价的可能原因：

| 现象                       | 原因              | 修复                                                     |
| -------------------------- | ----------------- | -------------------------------------------------------- |
| 一直 `PENDING`             | Worker 没起来     | 看 `backend/logs/crawler-worker.log` 末尾                |
| `ERROR: CDP not reachable` | JD/淘宝需要登录态 | 见 Step 10                                               |
| `ERROR: timeout 90s`       | 网络慢 / 反爬     | 重试一次，或见 [howto-debug-crawl](howto-debug-crawl.md) |

## Step 10：让 JD / 淘宝能登录（CDP 模式）

京东和淘宝页面需要登录态，Playwright 用一个**已登录的 Edge 远程实例**更稳：

```powershell
# 1. 用调试模式启动 Edge（端口 9222）
"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --remote-debugging-port=9222
# 2. 在这个浏览器里手动登录京东、淘宝
# 3. 在项目根 .env 添加：
#    CDP_ENABLED=true
#    CDP_URL=http://127.0.0.1:9222
# 4. 重启 start_server.ps1
```

详细反爬策略见 [explanation-anti-bot](explanation-anti-bot.md)。

## Step 11：设置降价告警

1. 商品详情页 → **Alerts** 标签
2. **Add Alert**
3. 阈值填 `5.0`（5%）
4. Active 勾上

这调用 `POST /api/v1/alerts`。

## Step 12：触发降价（验证通知）

最简单的办法：把商品的 `last_price` 改低（直接在数据库里 update 一下 price_history），然后再爬一次。

或者，把告警阈值改到 `0.1`（0.1%），再爬一次基本就会触发。

期望：

- 飞书群收到一条消息：`Price Drop Alert: <title> ... Drop: 5.0% ...`
- 数据库 `products_alerts.last_notified_at` 被更新
- 24 小时内不会重复通知（防抖）

## 你已经走通了

到这里你已经完整跑通：

- 多用户 Cookie 认证
- 商品域 CRUD
- 平台适配器（adapter 模式）
- 持久化任务 + 独立 worker 进程
- 降价阈值告警 + 飞书 Webhook

接下来可以看：

- [tutorial-job-monitoring](tutorial-job-monitoring.md) — 把职位监控也跑通
- [tutorial-smart-home](tutorial-smart-home.md) — 接入 Home Assistant
- [howto-cron-schedule](howto-cron-schedule.md) — 把「手动爬」换成「定时爬」
