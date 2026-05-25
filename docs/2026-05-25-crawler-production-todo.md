# 爬取系统生产化 TODO

日期：2026-05-25

关联计划：[2026-05-25-crawler-production-refactor-plan.md](2026-05-25-crawler-production-refactor-plan.md)

## 状态说明

- `todo`：尚未开始。
- `doing`：正在实现。
- `blocked`：被环境、依赖或决策阻塞。
- `done`：已实现并完成验证。

## 阶段总览

| 阶段 | 状态 | 主要输出 | 备注 |
| --- | --- | --- | --- |
| Phase 1 | done | `CrawlTaskRunner`、profile 路径简化、安全检查 | 已完成并合并到 main |
| Phase 2 | todo | `crawl_tasks`、Profile Pool、profile lease | 为独立 worker 做准备 |
| Phase 3 | todo | Boss/51job/猎聘生产化策略 | 先职位后商品 |
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

| 任务 | 状态 | 验收 |
| --- | --- | --- |
| 新增 `crawl_tasks` 数据模型和迁移 | todo | pending/running/completed/failed 状态可持久化 |
| 新增 `crawl_profiles` 数据模型和迁移 | todo | profile 状态、路径、lease 信息可管理 |
| 手动触发写入 `crawl_tasks` | todo | API 不直接依赖内存 task registry |
| APScheduler 写入 `crawl_tasks` | todo | 定时任务可重启恢复 |
| runner 支持领取 pending task | todo | 同一任务不会被重复执行 |
| profile lease 改为 DB 或 Redis lock | todo | 多进程不抢同一个 profile |
| 前端任务状态查询切到持久任务表 | todo | 刷新页面后仍可看到任务状态 |
| running 超时恢复策略 | todo | worker/进程中断后任务可失败或重试 |

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
| 猎聘默认关闭 CDP fallback | todo | 正常路径不打开浏览器 |
| 猎聘 HTTP 失败分类 | todo | XSRF、challenge、空结果、详情失败可区分 |
| 猎聘 JSONL 日志 | todo | 与 Boss/51job 日志字段对齐 |

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

