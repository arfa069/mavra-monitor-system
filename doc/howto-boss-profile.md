# How to 给 Boss / 51job / 猎聘配置爬虫 Profile

> 任务：登录一次爬虫 profile，让该平台后续的爬取走真实登录态。
> 适用：所有职位监控平台。

## 核心概念：Profile = 一个浏览器目录

一个 profile 是一个**完整 Chromium 用户目录**（含 cookie / localStorage / indexedDB）。每个 profile 同时只能被一个爬虫任务占用 —— 这是反爬和避免登录态冲突的硬性约束。

Profile 目录在 `profiles/<profile_key>/`，**已 gitignore**。

## 适用平台

| 平台      | 用不用 Profile | 怎么用                                                 |
| --------- | -------------- | ------------------------------------------------------ |
| Boss 直聘 | **必须**       | CloakBrowser 刷 cookie + `curl_cffi` 详情              |
| 51job     | 不必须         | 纯 `curl_cffi` HTTP                                    |
| 猎聘      | 推荐           | Windows 下用 DPAPI 解密 Chromium cookie 绕过 Challenge |

## 步骤

### 1. 创建一个 profile

前端 → **Jobs** → **Profiles** 标签 → 右上 **New Profile**：

- Name：`boss-gz`（kebab-case，不要空格）
- 用途：备注一下是给哪个平台 / 城市用

API：

```bash
curl -X POST http://localhost:8000/api/v1/crawl-profiles \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{"profile_key": "boss-gz", "description": "广州 / IT 服务台"}'
```

### 2. 打开登录会话

前端：profile 行 → **Login Session** → 弹一个浏览器窗口，手动扫码 / 短信登录。

API：

```bash
curl -X POST http://localhost:8000/api/v1/crawl-profiles/boss-gz/login-session \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt
```

注意：这一步**真的会开一个浏览器**，要看到「登录成功」再关闭。

### 3. 把 profile 绑到 job config

前端 → **Jobs** → **Configs** 标签 → 选 config → 改 Profile 字段 → 保存。

或者创建时直接指定 `profile_key=boss-gz`。

### 4. 验证

跑一次爬取，期望：

- `backend/logs/boss_cloak_adapter_<时间戳>.jsonl` 里 `cookie_refresh` 事件**很少**（只偶尔一次）
- `description` / `address` 都有内容
- 没有「风控」错误

如果 `cookie_refresh` 频率高（每分钟多次），profile 没真正登录上，回 Step 2。

## 多 profile 池

想让爬取并发更高？开多个 profile：

```text
profiles/
├── default/        # 第一次自动创建
├── boss-gz-1/
├── boss-gz-2/
└── boss-sz-1/
```

每个 job config 选不同 profile。`JobConfigScheduler` 会按 `(platform, profile_key)` 分流：**同 profile 串行，跨 profile 并行**。

## 复制 / 备份 / 还原

| 操作           | API                                                                      | 说明                                              |
| -------------- | ------------------------------------------------------------------------ | ------------------------------------------------- |
| 复制           | `POST /api/v1/crawl-profiles/{key}/copy`，body `{"new_key":"boss-gz-2"}` | Windows 风格追加 `-copy` / `-copy-2`              |
| 重命名         | `POST /api/v1/crawl-profiles/{key}/rename`，body `{"new_key":"..."}`     | **同步改** job config / cron 引用的 `profile_key` |
| 导出           | `POST /api/v1/crawl-profiles/{key}/export`                               | 加密 zip，仅 admin                                |
| 导入           | `POST /api/v1/crawl-profiles/import` (multipart)                         | 加密 zip，仅 admin                                |
| 释放过期 lease | `POST /api/v1/crawl-profiles/{key}/release-stale`                        | worker 崩了卡住时用                               |
| 删除           | `DELETE /api/v1/crawl-profiles/{key}`                                    | 必须 idle 且无引用                                |

## 失败兜底

| 现象                              | 原因                    | 修复                                   |
| --------------------------------- | ----------------------- | -------------------------------------- |
| Login Session 弹不出来            | Python 子进程被防火墙拦 | 关 Windows Defender 实时保护或加白名单 |
| profile 状态一直 `locked`         | 上一个 worker 没释放    | `POST /release-stale`                  |
| 同一时间两个任务都用 `default`    | 没建多 profile          | 复制出 `default-2` 给第二个 config     |
| 手动改 `profiles/default/` 文件名 | 引用全断                | 严禁，用 **Rename** API                |

## 详见

- [tutorial-job-monitoring](tutorial-job-monitoring.md) — 端到端
- [explanation-anti-bot](explanation-anti-bot.md) — 为什么走 profile 池
- [explanation-crawler-architecture](explanation-crawler-architecture.md) — 任务持久化 + lease 心跳
