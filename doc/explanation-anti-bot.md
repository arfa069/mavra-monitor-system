# 反爬设计：每个平台为什么这么打

> 解释淘宝 / 京东 / 亚马逊 / Boss / 51job / 猎聘**为什么**走不同栈，而不是统一 Playwright。
> 适用：所有改爬虫的人。

## 一句话原则

> **我们不冒充浏览器，我们冒充「一个真实的、带着有效 cookie 的用户」**。

反爬检测分三层：

```text
L1: HTTP 指纹（TLS、Header 顺序、HTTP/2 指纹）    → curl_cffi 模拟
L2: 浏览器指纹（navigator、canvas、字体、WebGL）   → Playwright / CDP
L3: 行为指纹（点击轨迹、停留时间、滚动）          → 随机延迟
```

每个平台启用其中几层。

| 平台   | 检测层              | 我们的对策                                                           |
| ------ | ------------------- | -------------------------------------------------------------------- |
| 淘宝   | L1 + L3             | 淘宝 OpenCLI 子进程 + 随机延迟；反爬严重时回退 CDP                   |
| 京东   | L1 + L2 + L3        | CDP 模式 + `domcontentloaded` + 4-6s 停留                            |
| 亚马逊 | L1                  | Launch 模式 Playwright + `ENABLE_AUTOMATION=false`                   |
| Boss   | L1 + L3             | `curl_cffi` 模拟 Chrome TLS + 串行 + 长延迟 + CloakBrowser 刷 cookie |
| 51job  | L1                  | `curl_cffi` 纯 HTTP                                                  |
| 猎聘   | L1 + Challenge 验证 | `curl_cffi` + Windows DPAPI 解 Chromium cookie + 5-10s 详情延迟      |

## 京东：CDP 模式

```text
[Edge 浏览器，--remote-debugging-port=9222]  ← 用户手动登录
        ↑
        │  CDP 协议复用同一会话
        ▼
[Playwright.connect_over_cdp]
        ↓
[Adapter 用真实 cookie 访问]
```

### 为什么不用 Playwright launch

京东的 anti-bot 检查：

- `navigator.webdriver`（默认 `true`）
- 字体反爬（动态生成）
- Cookie 严格校验 referer
- 部分页面强制要求「已登录」

CDP 模式下用的是用户**手动登录的 Edge**，cookie 真实、指纹真实，京东看不到 `webdriver` 标志。

### 安全护栏

`app/core/cdp_security.py:check_cdp_url()` 拒绝非本地 CDP 端点（`CDP_ALLOW_NON_LOCAL=false`）。这避免暴露公网的 CDP 端口（默认未鉴权）被外部接管。

## 淘宝：OpenCLI 子进程

`app/platforms/taobao_opencli.py` 调 `opencli`（淘宝内部 CLI）作为子进程，**而不是**用 Playwright 抓 HTML。

优势：

- 跳过 HTML 解析（淘宝的页面大量动态渲染 + 反爬）
- OpenCLI 内部走淘宝自家协议，风控识别概率低
- 失败原因更明确（CLI 返回码）

劣势：

- 依赖 OpenCLI 安装（见 [tutorial-getting-started](tutorial-getting-started.md) Step 1）
- 子进程管理 + Windows 上 `--reload` 不能用（已 ban 掉）

## Boss：CloakBrowser + curl_cffi

Boss 是最难打的平台之一：

```text
[刷 cookie]  CloakBrowser 打开已登录 profile
                  ↓
              读 .zhipin.com 域 cookie
                  ↓
[发请求]  curl_cffi.impersonate("chrome124")
              ↓
          带 cookie + 真实 Chrome TLS 指纹
              ↓
[响应]  code 36/37/38 → 反爬拒绝 → 回到刷 cookie
```

### 为什么不让 Playwright 做全部

- Boss 检测到 Playwright 自动化会在 `about:blank` 重定向卡住
- 每次都打开浏览器太重（200 个职位 = 200 次浏览器会话）
- Boss 反爬对**请求间隔**敏感，串行比并发更安全

### Cookie 刷新策略

```python
# 简化
if response.code in (36, 37, 38):
    refresh_cookie()
    retry_current_request()
```

`BossCloakExperimentalAdapter` 跑详细 JSONL 日志：

```json
{"event": "cookie_refresh", "trigger_status": 36, "elapsed": 1.2}
{"event": "list_page", "page": 3, "items": 30, "elapsed": 4.1}
{"event": "detail", "job_id": "abc", "elapsed": 2.5}
```

看 `backend/logs/boss_cloak_adapter_<时间戳>.jsonl` 排查风控频率。

### 验证基线

2026-05-25 真实运行：广州 `IT服务台` 200 个职位、589.57s 完成，详情 / 地址 100% 填充。

## 猎聘：Windows DPAPI 解 Chromium cookie

猎聘的 detail 页面有 Challenge 验证：普通请求会被卡一个 JS 校验页。

### 我们的打法

1. 搜索 API：`api-c.liepin.com/api/com.liepin.searchfront4c.pc-search-job`（无 Challenge）
2. 详情页：先 GET 一次搜索页拿 cookie，**再用 curl_cffi 拿 detail HTML**
3. **Windows 上**：profile 目录里 Chromium 的 cookie 是用 DPAPI 加密的，**用 Windows API 解密**直接拿 cookie 值注入请求，跳过 Challenge 验证，**不打开浏览器**

### 为什么 Windows 限定

`crypt_unprotect` 是 Windows API，Linux 上要跑 Chromium 走 NSS 库（更复杂）。目前生产目标是 Windows，Linux 上退化为「不绑 profile」。

### 限速

5-10 秒随机延迟进 detail 是硬编码在 adapter 里的，**别动**。动一下当天触发 Challenge。

## 51job：最简单

纯 curl_cffi，理由：

- HTML 体积适中，5KB-50KB
- 风控弱，主要 L1
- 详情页无 Challenge
- `impersonate="chrome124"` 就够

## 亚马逊：Playwright launch

亚马逊检测比京东弱（英文区），但 L2 严格：

- 强制 `navigator.webdriver = false`
- 关闭 `AutomationControlled` blink 特征
- 单进程启动 Playwright：`browser_context = await browser.new_context(...)` 改 `geolocation` / `locale`

## 共同设计

### 随机延迟

- 列表请求：2-5s
- 详情请求：2-3s（Boss）/ 5-10s（猎聘）
- 不用 `uniform(2, 5)`，用 `random.uniform` + 偶尔 `sleep(7-10)` 模拟真人

### 失败重试

`tenacity` 装饰，3 次指数退避（1s / 2s / 4s），不成功就标 `error` 不无限重试（避免重试风暴）

### 失败信号

| 信号                         | 我们做什么              |
| ---------------------------- | ----------------------- |
| HTTP 403 / Challenge         | 刷 cookie / 换 profile  |
| 频繁 cookie 刷新             | 退避 + 报警             |
| 连续 N 个职位 description 空 | 强制切 profile          |
| `ECONNREFUSED`               | 退避后重试，不刷 cookie |

## 详见

- [explanation-crawler-architecture](explanation-crawler-architecture.md) — 整体架构
- [tutorial-job-monitoring](tutorial-job-monitoring.md) — Boss 跑通
- [howto-boss-profile](howto-boss-profile.md) — profile 池管理
- [howto-debug-crawl](howto-debug-crawl.md) — 风控排查
- [reference-config](reference-config.md) § 爬虫 / Boss / 猎聘变量
