# 入门：监控一份 Boss 直聘的职位列表

> 适用读者：想跑通职位监控、第一次接触 `curl_cffi` / CloakBrowser 反爬的人。
> 目标：让 `广州 / IT 服务台` 这类搜索条件下的新职位，30 分钟内出现在飞书群里。

## 为什么职位和商品走两套技术栈

商品页面是「登录一次、循环爬列表」，用 Playwright + 浏览器实例合理；Boss 是「每次请求都要带不同的 Cookie 指纹」，普通浏览器会被识别，因此走 `curl_cffi` 模拟 Chrome TLS 指纹，CloakBrowser 只用来**刷一次 cookie**。

详见 [explanation-anti-bot](explanation-anti-bot.md)。

## Step 1：起服务（同上一个教程）

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"
```

确保 worker 也起来了（日志：`backend/logs/crawler-worker.log`），否则职位任务没人抢。

## Step 2：准备 Boss 的浏览器 profile

Boss 需要一个**已登录**的 CloakBrowser profile，路径在项目根 `profiles/default/`。

```powershell
# 第一次：手动用 CloakBrowser 登录 Boss
# 项目里已经提供了一个开 profile 的入口（前端 /jobs → Profiles Management → Login Session）
# 或调用 API：
curl -X POST http://localhost:8000/api/v1/crawl-profiles/default/login-session \
  -H "X-CSRF-Token: <your-csrf>" -b cookies.txt
```

这一步会**真的弹一个浏览器窗口**，手动扫码 / 短信登录一次。profile 文件夹被 `.gitignore` 忽略，**不要手动重命名**。

如果你想用自定义 profile 名字：

1. 前端 → **Jobs** → **Profiles** 标签 → 右上 **New Profile**
2. 名字 `boss-gz-1`（用 `-` 分隔，不要有空格）
3. 然后在它上面点 **Login Session** 登录

## Step 3：创建职位搜索配置

1. 前端 → **Jobs** → **Configs** 标签
2. **Add Config**
3. 填：
   - Name：`广州 IT 服务台`
   - URL：从 Boss 搜索结果页直接复制（形如 `https://www.zhipin.com/web/geek/job?query=IT%E6%9C%8D%E5%8A%A1%E5%8F%B0&city=101280100`）
   - Profile：选 Step 2 那个 `default` 或 `boss-gz-1`
   - Active：勾上
   - Notify on new：勾上
4. 保存

后端会写一行到 `jobs_search_configs`。

## Step 4：手动爬一次

列表里点 **Crawl Now**。应该看到：

- 该 config 的 `last_crawled_at` 更新
- 列表出 30 条新职位（每页 30）
- 点击进入职位详情时，`description` 和 `address` 应已填充（不是空）

**如果 description 是空**：多半是 profile 没登录上，爬详情时被风控拦了。

**怎么排查**：

```bash
# 1. 看 worker 实时日志
tail -f backend/logs/crawler-worker.log

# 2. 看 Boss 专属 JSONL
ls -lt backend/logs/boss_cloak_adapter_*.jsonl | head -1
# 然后翻里面的 cookie_refresh 事件
```

`cookie_refresh` 事件多了说明 profile cookie 频繁失效，回 Step 2 重登录。

## Step 5：触发新职位通知

Boss 是基于 `first_seen_at` 判定「新职位」的。模拟新职位最简单的办法：

1. 选一个不在当前职位表里的搜索词（例如换一个 query）
2. 爬一次，**新出现的行会触发 webhook**
3. 飞书群收到 `New Job Alert: <title> @ <company> ...`

调小阈值没用，**新职位通知只看 first_seen_at**。

## Step 6：给这份 config 设置每天 9 点的 cron

前端 → **Schedule** 页 → 找到这份 config 行 → 输入 `0 9 * * *` → Save。

后端 `PATCH /api/v1/jobs/configs/{id}/cron` 写入 `cron_expression` / `cron_timezone`，`JobConfigScheduler` 在下一次启动 / cron sync 时注册 APScheduler job `job_config_cron_{id}`。

定时机制详见 [explanation-scheduler](explanation-scheduler.md)。

## 走通后你能学到什么

- 平台适配器的两套实现（Playwright vs `curl_cffi`）
- profile 池的 lease 心跳机制（同一时刻一个 profile 只能被一个 task 占用）
- Boss 专属 JSONL 日志怎么排查风控
- 持久化任务 + 独立 worker 进程模型（`crawl_tasks` 表 + `app.workers.crawler`）

## 下一步

- [howto-boss-profile](howto-boss-profile.md) — 多 profile 池、profile 备份
- [howto-cron-schedule](howto-cron-schedule.md) — 全部 cron 配置
- [explanation-anti-bot](explanation-anti-bot.md) — 完整反爬设计
