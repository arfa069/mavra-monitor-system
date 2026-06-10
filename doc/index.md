# Mavra Monitor System — 文档索引

> 本目录是面向用户（开发者 / 运维 / 产品）的 **Diataxis** 文档。
> 已有 `backend-architecture.md` / `frontend-architecture.md` / `permission-architecture.md` / `DESIGN.md` 是面向贡献者的内部架构说明，**二者不重复**。

## 项目一句话

跟踪淘宝 / 京东 / 亚马逊商品价格、Boss 直聘 / 51job / 猎聘的职位新动态，接 Home Assistant 控制智能家居；降价或新职位时通过飞书 Webhook 推送通知。

## 四象限 × 五大子系统

| 子系统                 | Tutorial                                                | How-to                                                                                                                                    | Reference                                                                                | Explanation                                                                                                                |
| ---------------------- | ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **入门 / 全栈**        | [tutorial-getting-started](tutorial-getting-started.md) | —                                                                                                                                         | —                                                                                        | —                                                                                                                          |
| **商品价格监控**       | (↑)                                                     | [howto-add-product](howto-add-product.md)、[howto-feishu-webhook](howto-feishu-webhook.md)、[howto-cron-schedule](howto-cron-schedule.md) | [reference-api-products](reference-api-products.md)                                      | [explanation-crawler-architecture](explanation-crawler-architecture.md)、[explanation-anti-bot](explanation-anti-bot.md)   |
| **职位搜索监控**       | [tutorial-job-monitoring](tutorial-job-monitoring.md)   | [howto-boss-profile](howto-boss-profile.md)                                                                                               | [reference-api-jobs](reference-api-jobs.md)                                              | [explanation-anti-bot](explanation-anti-bot.md)                                                                            |
| **Home Assistant**     | [tutorial-smart-home](tutorial-smart-home.md)           | —                                                                                                                                         | [reference-api-products](reference-api-products.md)（smart-home 段）                     | [explanation-sse-realtime](explanation-sse-realtime.md)                                                                    |
| **认证 / 授权 / 审计** | —                                                       | [howto-rbac](howto-rbac.md)                                                                                                               | [reference-api-auth](reference-api-auth.md)                                              | [explanation-auth-rbac](explanation-auth-rbac.md)                                                                          |
| **调度 / 运维**        | —                                                       | [howto-debug-crawl](howto-debug-crawl.md)、[howto-deploy-worker](howto-deploy-worker.md)                                                  | [reference-config](reference-config.md)、[reference-data-model](reference-data-model.md) | [explanation-scheduler](explanation-scheduler.md)、[explanation-crawler-architecture](explanation-crawler-architecture.md) |

## 按角色推荐阅读路径

### 第一次接触项目

1. [tutorial-getting-started](tutorial-getting-started.md) — 启动服务、添加商品、收到降价通知的完整一遍
2. [tutorial-job-monitoring](tutorial-job-monitoring.md) — 跑通职位监控
3. [tutorial-smart-home](tutorial-smart-home.md) — 接 Home Assistant

### 后端开发者（改爬虫 / 改 API）

- [reference-api-products](reference-api-products.md)、[reference-api-jobs](reference-api-jobs.md)、[reference-api-auth](reference-api-auth.md) — 接口定义
- [reference-data-model](reference-data-model.md) — 表结构
- [explanation-crawler-architecture](explanation-crawler-architecture.md) — 为什么是 adapter + worker 进程模型
- [explanation-anti-bot](explanation-anti-bot.md) — 反爬策略的来龙去脉

### 前端开发者（改 UI / 接新 API）

- [reference-config](reference-config.md) — 端口、代理、API base URL
- [explanation-sse-realtime](explanation-sse-realtime.md) — 三个 SSE 通道的差异
- [`doc/frontend-architecture.md`](frontend-architecture.md) — 内部架构（feature-first / 设计系统）

### 运维 / 部署

- [reference-config](reference-config.md) — 完整环境变量
- [howto-deploy-worker](howto-deploy-worker.md) — 独立 worker 进程
- [howto-debug-crawl](howto-debug-crawl.md) — 排查爬虫失败

### 安全 / 权限审计

- [howto-rbac](howto-rbac.md) — 角色与资源权限
- [reference-api-auth](reference-api-auth.md) — Cookie / CSRF / Refresh
- [explanation-auth-rbac](explanation-auth-rbac.md) — 三层模型的设计取舍

## 相关文档（不在本目录）

- [`README.md`](../README.md) — 项目入口、Quick Start、API 表格
- [`ARCHITECTURE.md`](../ARCHITECTURE.md) — 顶层架构图与数据模型
- [`AGENTS.md`](../AGENTS.md) — 仓库导航、命令、约定
- [`doc/backend-architecture.md`](backend-architecture.md) — 后端架构详述
- [`doc/frontend-architecture.md`](frontend-architecture.md) — 前端架构详述
- [`doc/permission-architecture.md`](permission-architecture.md) — 权限矩阵端点映射
- [`doc/DESIGN.md`](DESIGN.md) — 设计系统
