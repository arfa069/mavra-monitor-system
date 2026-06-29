# 环境变量 / 配置参考

> `.env` 完整字段、所有合法值、默认值、运行时生效条件。
> 加载机制：`pydantic-settings` + `app/config.py` 的 `Settings` 类。

## 必填项

如果缺了，启动时**直接拒绝**：

| 变量                    | 说明                         | 示例                                                                                        |
| ----------------------- | ---------------------------- | ------------------------------------------------------------------------------------------- |
| `DATABASE_URL`          | PostgreSQL 异步连接          | `postgresql+asyncpg://<user>:<password>@<host>:5432/pricemonitor`                           |
| `REDIS_URL`             | Redis 连接                   | `redis://localhost:6379/0`                                                                  |
| `FEISHU_WEBHOOK_URL`    | 默认飞书 webhook             | `https://open.feishu.cn/open-apis/bot/v2/hook/<your-key>`                                   |
| `SMART_HOME_SECRET_KEY` | Fernet key（32 字节 base64） | `uv run --project backend --extra dev python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"` |
| `ALLOWED_ORIGINS`       | CORS 来源                    | `http://localhost:3000,http://127.0.0.1:3000,http://localhost:3001,http://127.0.0.1:3001` 或 JSON list |

> `FEISHU_WEBHOOK_URL` 在 user 级 PATCH 后**会被覆盖**；`ALLOWED_ORIGINS` 必须在启动时存在。

## 数据库 / 缓存

| 变量              | 默认   | 说明                      |
| ----------------- | ------ | ------------------------- |
| `DATABASE_URL`    | —      | 必填，asyncpg 驱动        |
| `DB_POOL_SIZE`    | `5`    | SQLAlchemy 池大小         |
| `DB_MAX_OVERFLOW` | `10`   | 超出 pool_size 的临时连接 |
| `DB_POOL_TIMEOUT` | `30`   | 池等连接的秒数            |
| `DB_POOL_RECYCLE` | `1800` | 30 分钟回收               |
| `REDIS_URL`       | —      | 必填                      |
| `REDIS_PASSWORD`  | 空     | 与 URL 二选一             |
| `REDIS_DB`        | `0`    | 逻辑库                    |

## 爬虫

| 变量                               | 默认                    | 说明                                        |
| ---------------------------------- | ----------------------- | ------------------------------------------- |
| `CDP_ENABLED`                      | `false`                 | 商品 / JD 走远程 Edge                       |
| `CDP_URL`                          | `http://127.0.0.1:9222` | 远程浏览器 DevTools 端口                    |
| `CDP_ALLOW_NON_LOCAL`              | `false`                 | **安全**！防止远端 CDP 注入                 |
| `CRAWLER_HEADLESS`                 | `true`                  | `false` 时可见 Playwright，便于调试         |
| `PRODUCT_CRAWL_CONCURRENCY`        | `1`                     | 单 worker 任务内的并发，**最小 1**（反爬）  |
| `CRAWLER_INLINE_EXECUTION_ENABLED` | `false`                 | `true` 时爬虫在 API 进程内同步跑（仅开发）  |
| `CRAWL_PROXY_ENABLED`              | `false`                 | 全局代理                                    |
| `CRAWL_PROXY_URL`                  | 空                      | `http://<user>:<password>@<host>:<port>`    |
| `JD_COOKIE_FALLBACK_ENABLED`       | `false`                 | JD 紧急 cookie 注入，**默认禁用**           |
| `JD_COOKIE`                        | 空                      | 仅 `JD_COOKIE_FALLBACK_ENABLED=true` 时使用 |

## Boss 职位爬取

| 变量                           | 默认               | 说明                      |
| ------------------------------ | ------------------ | ------------------------- |
| `BOSS_CLOAK_PROFILE_DIR`       | `profiles/default` | CloakBrowser profile 路径 |
| `BOSS_CLOAK_REQUEST_DELAY_MIN` | `2.0`              | 列表请求最小延迟（秒）    |
| `BOSS_CLOAK_REQUEST_DELAY_MAX` | `5.0`              | 列表请求最大延迟          |
| `BOSS_CLOAK_DETAIL_DELAY_MIN`  | `2.0`              | 详情请求最小延迟          |
| `BOSS_CLOAK_DETAIL_DELAY_MAX`  | `3.0`              | 详情请求最大延迟          |

详见 [explanation-anti-bot](explanation-anti-bot.md)。

## 猎聘

| 变量                      | 默认   | 说明                               |
| ------------------------- | ------ | ---------------------------------- |
| `LIEPIN_PROFILE_DIR`      | 空     | 可选；Windows 下走 DPAPI 解 cookie |
| `LIEPIN_DETAIL_DELAY_MIN` | `5.0`  | 详情延迟（防 Challenge）           |
| `LIEPIN_DETAIL_DELAY_MAX` | `10.0` |                                    |

## LLM（职位匹配）

| 变量              | 默认              | 说明                                          |
| ----------------- | ----------------- | --------------------------------------------- |
| `LLM_PROVIDER`    | `minimax`         | `minimax` / `anthropic` / `openai` / `ollama` |
| `LLM_API_KEY`     | 空                | provider 需要的 key                           |
| `LLM_BASE_URL`    | 空                | Ollama / 自定义代理用                         |
| `LLM_MODEL`       | `MiniMax-Text-01` | 实际模型名                                    |
| `LLM_TEMPERATURE` | `0.2`             | 评分一致性优先                                |
| `LLM_MAX_TOKENS`  | `1024`            | 匹配结果解释上限                              |

## 认证 / Cookie / JWT

| 变量                          | 默认                               | 说明                                                      |
| ----------------------------- | ---------------------------------- | --------------------------------------------------------- |
| `JWT_SECRET`                  | 启动时随机生成（**生产必须显式**） | HS256 密钥                                                |
| `JWT_ALGORITHM`               | `HS256`                            |                                                           |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `15`                               | access JWT 寿命                                           |
| `SESSION_IDLE_TIMEOUT_MINUTES` | `60`                              | session 空闲过期窗口                                      |
| `REFRESH_TOKEN_EXPIRE_DAYS`   | `14`                               | session 绝对上限；refresh 不延长这个上限                  |
| `COOKIE_SECURE`               | `false`                            | 生产 `true`，开发 `false`（否则 localhost cookie 写不进） |
| `COOKIE_SAMESITE`             | `lax`                              |                                                           |
| `COOKIE_DOMAIN`               | 空                                 | 跨子域用                                                  |
| `COOKIE_ACCESS_NAME`          | `pm_access_token`                  |                                                           |
| `COOKIE_REFRESH_NAME`         | `pm_refresh_token`                 |                                                           |
| `COOKIE_CSRF_NAME`            | `pm_csrf_token`                    |                                                           |
| `PASSWORD_MIN_LENGTH`         | `10`                               | 强密码最小长度                                            |
| `LOGIN_LOCKOUT_THRESHOLD`     | `5`                                | 失败 N 次锁                                               |
| `LOGIN_LOCKOUT_MINUTES`       | `15`                               | 锁多久                                                    |
| `MAX_SESSIONS_PER_USER`       | `5`                                | session 上限                                              |

## 微信 OAuth

| 变量                   | 默认    | 说明         |
| ---------------------- | ------- | ------------ |
| `WECHAT_LOGIN_ENABLED` | `false` | 启用微信登录 |
| `WECHAT_APP_ID`        | 空      |              |
| `WECHAT_APP_SECRET`    | 空      |              |
| `WECHAT_REDIRECT_URI`  | 空      | 回调 URL     |
| `WECHAT_FRONTEND_CALLBACK_URL` | `http://localhost:3000/auth/wechat/callback` | 前端微信回流展示页 |

## 数据保留

| 变量                       | 默认  | 说明                                                        |
| -------------------------- | ----- | ----------------------------------------------------------- |
| `DATA_RETENTION_DAYS`      | `365` | 用户级 `data_retention_days` 默认；cleanup 不会删超过此值的 |
| `CRAWL_LOG_RETENTION_DAYS` | `90`  | 爬虫日志单独保留                                            |

## 调度 / Worker

| 变量                          | 默认            | 说明                    |
| ----------------------------- | --------------- | ----------------------- |
| `SCHEDULER_TIMEZONE`          | `Asia/Shanghai` | APScheduler 全局时区    |
| `WORKER_LEASE_RENEW_SECONDS`  | `15`            | heartbeat               |
| `WORKER_LEASE_EXPIRE_SECONDS` | `60`            | 过期后其他 worker 可抢  |
| `WORKER_LOG_LEVEL`            | `INFO`          | `worker` 包 logger 级别 |

## Smart Home

| 变量                             | 默认   | 说明                        |
| -------------------------------- | ------ | --------------------------- |
| `SMART_HOME_SECRET_KEY`          | —      | 必填；Fernet 32 字节 base64 |
| `SMART_HOME_CONNECT_TIMEOUT`     | `10`   | 测连通性 timeout            |
| `SMART_HOME_WEBSOCKET_RECONNECT` | `true` | SSE 断开自动重连            |

## Public Blog

| 变量                       | 默认                    | 说明                                      |
| -------------------------- | ----------------------- | ----------------------------------------- |
| `BLOG_PUBLIC_BASE_URL`     | `http://localhost:3001` | canonical、OG、JSON-LD 使用的公开站点根地址 |
| `BLOG_MEDIA_ROOT`          | `uploads/blog`          | 后端本地图片存储目录，相对 backend 目录解析 |
| `BLOG_MEDIA_PUBLIC_PREFIX` | `/blog-media`           | 公开媒体响应路径前缀                      |
| `BLOG_MEDIA_MAX_BYTES`     | `8388608`               | 单文件上传上限，默认 8MB                  |
| `BLOG_API_BASE_URL`        | `http://127.0.0.1:8000/api/v1` | Next.js 读取公开博客 API 的后端地址      |
| `BLOG_BACKEND_ORIGIN`      | `http://127.0.0.1:8000` | Next.js 本地 `/blog-media/*` rewrite 目标 |
| `NEXT_PUBLIC_BLOG_BASE_URL` | `http://localhost:3001` | Next.js 客户端公开 canonical base 覆盖值  |

## 系统

| 变量                     | 默认          | 说明                                     |
| ------------------------ | ------------- | ---------------------------------------- |
| `LOG_LEVEL`              | `INFO`        | uvicorn / app logger                     |
| `CORS_ALLOW_CREDENTIALS` | `true`        | Cookie 跨域必填                          |
| `ENV`                    | `development` | `development` / `staging` / `production` |
| `SENTRY_DSN`             | 空            | 启用 Sentry                              |

## 反模式

- ❌ 生产环境 `JWT_SECRET` 用启动时随机生成：每次重启所有 token 失效，强制所有人重新登录
- ❌ `CDP_ALLOW_NON_LOCAL=true`：远端 CDP 端口暴露给公网时整个系统被控
- ❌ `JD_COOKIE_FALLBACK_ENABLED=true` 但没换 cookie：风控几天内必触发
- ❌ `COOKIE_SECURE=true` 但走 `http://localhost`：浏览器不写 cookie，所有人登不上
- ❌ `LLM_PROVIDER=openai` 但没设 `LLM_BASE_URL`：调的是公网，可能被墙

## 校验

启动时 `app/config.py:Settings` 会：

1. 类型校验（Pydantic）
2. 必填项缺失 → `ValidationError`
3. `JWT_SECRET` 长度 ≥ 32
4. `SMART_HOME_SECRET_KEY` 是合法 Fernet key
5. `ALLOWED_ORIGINS` 是合法 URL 列表

不通过的项打印到 stderr，**进程退出码 1**。

## 详见

- [tutorial-getting-started](tutorial-getting-started.md) Step 3 — 最小可跑 .env
- [reference-data-model](reference-data-model.md) — 这些变量影响哪些表
- [explanation-auth-rbac](explanation-auth-rbac.md) — JWT / Cookie / CSRF 为什么这么设计
