# 爬取系统生产化 TODO

日期：2026-05-25

关联计划：

- [Phase 1 implementation plan](2026-05-25-crawler-production-phase1-implementation-plan.md)
- [Phase 2 implementation plan](2026-05-26-crawler-production-phase2-implementation-plan.md)

## 状态说明

- `todo`：尚未开始。
- `doing`：正在实现。
- `blocked`：被环境、依赖或决策阻塞。
- `done`：已实现并完成验证。

## 阶段总览

| 阶段 | 状态 | 主要输出 | 备注 |
| --- | --- | --- | --- |
| Phase 1 | done | `CrawlTaskRunner`、profile 路径简化、安全检查 | 已实现；review 修复已完成，待提交 |
| Phase 2 | done | `crawl_tasks`、`crawl_profiles`、DB Profile Pool、profile lease | task 和 lease 持久化完成；review 修复与真实联调已完成，匹配分析仍走内存 registry |
| Phase 3 | done | Boss/51job/猎聘生产化策略 | 先职位后商品 |
| Phase 4 | todo | 商品 profile 化、受控 browser manager | CDP 优化重点 |
| Phase 5 | todo | 独立 crawler worker | 任务量增长后启动 |

## Phase 1：任务执行边界和生产安全底座

| 任务 | 状态 | 验收 |
| --- | --- | --- |
| 新增 `CrawlTaskRunner`，统一商品和职位执行入口 | done | 手动和定时爬取都可通过 runner 执行 |
| FastAPI 手动触发先创建任务，再调用 runner | done | 原接口响应兼容，Event Center 正常 |
| APScheduler 定时触发先创建任务，再调用 runner | done | 定时职位和商品任务行为不变 |
| 增加 profile 默认路径 | done | profile 自动解析到项目根 `profiles/{key}`，不再依赖环境变量 |
| 定义 Profile Pool / Profile Lease 接口 | done | 第一阶段可先单机锁实现 |
| adapter profile path 改由配置或 Profile Pool 注入 | done | Boss、51job adapter 不再各自写死路径 |
| 增加 CDP 端口安全检查 | done | 发现非 localhost 监听时阻止启动或告警 |
| 增加日志脱敏 filter | done | cookie/token/webhook/security 字段不进日志 |
| 增加 profile 状态 Event Center 事件 | todo | login_required/cooling_down 等状态可见 |

## Phase 2：持久化任务和 Profile Pool

Profile 规则：一个 profile 可以保存多个平台登录态，但同一时刻只能被一个爬取任务占用；任务只跑一个平台。Phase 2 使用 DB `SELECT ... FOR UPDATE` 行锁实现原子租约，不使用 Redis。

| 任务 | 状态 | 验收 |
| --- | --- | --- |
| 新增 `crawl_tasks` 数据模型和迁移 | done | pending/running/completed/failed 状态可持久化，含 JSONB details/payload、lease 字段 |
| 新增 `crawl_profiles` 数据模型和迁移 | done | profile 状态、路径、lease owner/task_id/until 可管理 |
| 手动触发写入 `crawl_tasks` | done | 商品和职位手动爬取写入持久表；job all-crawl 创建 parent `job_all` + child `job_platform` |
| APScheduler 写入 `crawl_tasks` | done | 定时商品（product_platform）和职位（job_config）爬取写入持久表并更新进度 |
| runner 支持领取 pending task | todo | 当前 runner 由调用方直接启动，非 worker pull 模式；Phase 5 独立 worker 再实现 |
| profile lease 改为 DB lock | done | `DatabaseProfilePool` 使用 `SELECT ... FOR UPDATE` 原子获取，含 `_get_or_create_profile_for_update` 处理并发创建竞争 |
| 前端任务状态查询切到持久任务表 | done | 商品 `/crawl/status/{task_id}` 和 `/crawl/result/{task_id}`、职位 `/jobs/crawl/status/{task_id}` 和 `/jobs/crawl/result/{task_id}` 均从 `crawl_tasks` 读取 |
| running 超时恢复策略 | done | 启动时 `recover_crawler_runtime_state()` 标记过期 running 任务为 `failed`（reason: worker_restarted）并释放过期 profile lease |
| 心跳续期 | done | `task_store.renew_task_lease()` 更新 heartbeat_at/lease_until；`profile_pool.renew()` 更新 lease_until/last_used_at；职位手动/定时/全量子任务持有 profile lease 时均会续期 |

**Phase 2 review follow-up（2026-05-26）**

- 旧 lease 已不能释放或续期新任务持有的同名 profile，避免过期任务误伤新任务。
- 定时职位爬取已与手动职位爬取一致，进入 `DatabaseProfilePool` lease 后再执行 runner。
- 全量职位爬取的 `job_platform` 子任务失败会写回持久任务表，父任务在存在子平台错误时标记为 `failed`，不再误报 completed。
- 已完成验证：后端完整 `pytest -q` 为 `519 passed, 21 skipped`；后端 E2E `tests/test_e2e_crawl_flow.py` 为 `3 passed`；前端真实浏览器联调完成默认账号登录、Jobs 页、`/api/v1/auth/me`、`/api/v1/jobs/configs` 和 Event Center 页面验证。

## Phase 3：职位平台生产化

| 任务 | 状态 | 验收 |
| --- | --- | --- |
| Boss 接入 Profile Pool | todo | profile path 由 lease 注入 |
| Boss 多 profile 并行 | todo | 两个 config 可用两个 profile 同时跑 |
| Boss anti-bot code 统一分类 | todo | 36/37/38 触发 session refresh 事件 |
| Boss profile login_required 状态 | todo | 多次刷新失败后暂停任务并告警 |
| 51job 接入 Profile Pool | todo | 不再依赖 adapter 默认 profile path |
| 51job JSONL 日志 | todo | 记录 crawl_start/list_page/waf/crawl_finish |
| 51job WAF 熔断 | todo | 多次 WAF 后快速停止，不空转 |
| 51job HTTP 下沉实验 | todo | 输出成功率、耗时、WAF 命中率 |
| 猎聘默认关闭 CDP fallback | done | `_crawl_via_cdp` 和 `_crawl_detail_via_cdp` 已移除；正常路径不打开浏览器 |
| 猎聘 HTTP 失败分类 | done | `classify_liepin_failure` 区分 XSRF、challenge、空结果、详情失败 |
| 猎聘 JSONL 日志 | done | 与 Boss/51job 日志字段对齐 |

**Phase 3 verification (2026-05-26)**

- `profile_key` added to `JobSearchConfig` model, schemas, migration, and service validation.
- Profile management API (`/v1/crawl-profiles`) with list/create/update/release-stale endpoints.
- Profile management UI with React Query hooks, profile select in config form, and Profiles tab on Jobs page.
- `JobCrawlRuntimeContext` dataclass passes `profile_dir` and metadata into all platform adapters.
- Single and scheduled crawls resolve `profile_key` from config; full crawl groups child tasks by `(platform, profile_key)`.
- Shared `JobRuntimeJsonlLogger` writes JSONL events for Boss, 51job, and Liepin.
- Boss: `classify_boss_failure` maps anti-bot codes 36/37/38; `_profile_failure_category` detects repeated cookie refresh failures.
- 51job: `classify_51job_response` detects WAF HTML responses; WAF fuse stops after 2 hits; `run_http_experiment` returns success rate, WAF hit rate, and elapsed time.
- Liepin: CDP fallback (`_crawl_via_cdp`, `_crawl_detail_via_cdp`) removed; `classify_liepin_failure` maps XSRF, challenge, and HTTP errors; JSONL events emitted.
- Backend targeted tests: 65 passed (1 DB-password-dependent skipped).
- Backend lint: all modified files pass `ruff check`.
- Frontend lint and build: pass.

## Phase 4：商品爬取改造

| 任务 | 状态 | 验收 |
| --- | --- | --- |
| 建立 Product Profile Pool | todo | jd/taobao/amazon 各自 profile |
| 新增 BrowserManager | todo | 可按 profile 启动 persistent context |
| 限制单 profile page 数 | todo | 超限任务排队或失败 |
| 浏览器 watchdog | todo | 超时或崩溃后可回收进程 |
| 京东改为 profile 登录态优先 | todo | 不依赖人工预先打开 Edge CDP |
| `JD_COOKIE` 降级为 fallback | todo | 生产默认不要求明文 cookie |
| 淘宝/天猫独立 profile | todo | 低并发、长间隔策略生效 |
| 亚马逊 HTTP 快路径评估 | todo | 记录可行性和失败原因 |

## Phase 5：独立 Crawler Worker 化

| 任务 | 状态 | 验收 |
| --- | --- | --- |
| 新增 `python -m app.workers.crawler` 入口 | todo | worker 可独立启动 |
| worker 领取 `crawl_tasks` | todo | API 不执行爬虫 |
| worker 心跳 | todo | 可识别 worker 存活状态 |
| worker 崩溃恢复 | todo | lease 超时任务可失败或重试 |
| 按平台启动专用 worker | todo | 支持只跑 boss / jd 等 |
| APScheduler 只创建 task | todo | 调度器不直接执行爬虫 |
| 多 worker profile lease 验证 | todo | 不抢同一 profile |
