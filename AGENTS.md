# PROJECT KNOWLEDGE BASE

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **mavra-monitor-system** (10672 symbols, 19289 relationships, 300 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/mavra-monitor-system/context` | Codebase overview, check index freshness |
| `gitnexus://repo/mavra-monitor-system/clusters` | All functional areas |
| `gitnexus://repo/mavra-monitor-system/processes` | All execution flows |
| `gitnexus://repo/mavra-monitor-system/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->

## 概述 (OVERVIEW)

淘宝、京东、亚马逊价格监控 + Boss/51job/猎聘职位监控 + Home Assistant 智能家居控制。后端 FastAPI + PostgreSQL/Redis + Playwright/curl_cffi/CloakBrowser；前端 React/Vite/TypeScript/Ant Design + Figma Design System。

## 目录结构 (STRUCTURE)

```
mavra-monitor-system/
├── backend/                    # FastAPI, SQLAlchemy, 爬虫, worker, 测试
│   ├── app/main.py             # FastAPI 应用 + lifespan + 路由挂载
│   ├── app/domains/            # 业务领域: 爬取/职位/商品/认证/管理员/智能家居/...
│   ├── app/platforms/          # 淘宝/京东/亚马逊/Boss/51job/猎聘适配器
│   └── tests/                  # pytest 单元/集成/回归测试
├── frontend/                   # Vite React 应用
│   ├── src/App.tsx             # 路由/布局/主题组合
│   ├── src/features/           # 功能优先模块
│   ├── src/shared/             # API 客户端, 认证上下文, 布局, 共享类型
│   └── tests/e2e/              # Playwright E2E 规范
├── doc/                        # 实时架构/设计文档
├── docs/                       # 实施计划和历史计划
├── scripts/start_server.ps1    # 本地后端/前端/worker 启动脚本
└── profiles/                   # 运行时浏览器配置文件；请勿手动编辑
```

## 文件寻址 (WHERE TO LOOK)

| 任务 (Task)            | 位置 (Location)                                                                                           | 备注 (Notes)                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| 后端路由/生命周期管理   | `backend/app/main.py`, `backend/app/domains/*/router.py`                                                  | 业务路由仅挂载于 `/api/v1`；根路径和 `/v1` legacy 路径返回 `404`                                      |
| 商品爬取               | `backend/app/domains/crawling`, `backend/app/platforms`                                                   | 使用 Playwright/CDP/对浏览器配置敏感                                                                 |
| 职位爬取               | `backend/app/domains/jobs`, `backend/app/platforms`                                                       | Boss 使用 CloakBrowser cookie 刷新 + `curl_cffi`；猎聘支持 Chromium 浏览器配置 cookie 加载            |
| 智能家居               | `backend/app/domains/smart_home`, `backend/app/models/smart_home.py`, `backend/app/schemas/smart_home.py` | Home Assistant 配置, 实体控制, SSE 扇出, 加密 token 存储                                             |
| 身份验证/RBAC          | `backend/app/core/security.py`, `backend/app/core/permissions.py`, `doc/permission-architecture.md`       | Cookie 优先 + Bearer 回退                                                                            |
| 前端路由               | `frontend/src/App.tsx`                                                                                    | 根路径重定向到 `/jobs`                                                                               |
| 前端 API/身份验证       | `frontend/src/shared/api/client.ts`, `frontend/src/shared/contexts/AuthContext.tsx`                       | Axios 注入 CSRF 并刷新 401                                                                           |
| 设计决策               | `doc/DESIGN.md`, `frontend/src/styles/`                                                                   | 更改 UI 前必须阅读                                                                                   |
| 手动 QA                | `backend/tests/manual_verification_checklist.md`                                                          | 浏览器用于验证 UI/爬取触发更改的凭证                                                                  |

## 代码分布图 (CODE MAP)

| 区域 (Area)       | 关键文件 (Key files)                                                                             | 作用 (Role)                                           |
| ----------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| 应用引导          | `backend/app/main.py`, `frontend/src/main.tsx`                                                   | 后端 lifespan/路由设置；React Query 提供商             |
| 爬虫运行期        | `backend/app/domains/crawling/task_runner.py`, `task_store.py`, `backend/app/workers/crawler.py` | 持久化任务执行及 worker 循环                          |
| 浏览器配置池      | `backend/app/domains/crawling/profile_pool.py`, `browser_manager.py`                             | 数据库租约 + 浏览器会话生命周期                       |
| 平台适配器        | `backend/app/platforms/*.py`                                                                     | 商品/职位平台提取和反爬处理                           |
| 职位领域          | `backend/app/domains/jobs/*`, `llm/*`                                                            | 职位配置, 爬取, 通知, 简历匹配                         |
| 前端职位          | `frontend/src/features/jobs/*`                                                                   | 最大的 UI 功能：职位、配置、简历、匹配                 |
| 共享前端          | `frontend/src/shared/*`                                                                          | 认证、API、布局、动画/主题原语                         |
| 共享工具          | `backend/app/utils/*.py`                                                                         | URL 标准化、薪资解析、请求辅助函数                    |
| 共享核心          | `backend/app/core/*.py`                                                                          | JSON 工具、Redis 客户端、会话、事件流                 |

## 常用命令 (COMMANDS)
在 Windows 上通过 PowerShell 运行 shell/测试/检查 (lint) 命令。

项目启动命令： **脚本会先清理所有占用启前端、后端和worker端口的进程，同时启动他们**
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"

后端：
```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; pip install -e ."
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; alembic upgrade head"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; pytest"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; ruff check ."
```

前端：
```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run lint"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run build"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; $env:E2E_BASE_URL='http://localhost:3000'; npx playwright test tests/e2e/ --project=chromium"
```

## 设计系统 (DESIGN SYSTEM)

- 在做出任何 UI 或视觉决定之前，请阅读 `doc/DESIGN.md`。
- 未经明确批准，不得偏离 `doc/DESIGN.md` 的设计系统。
- UI QA 必须指出任何与 `doc/DESIGN.md` 不符的地方。

## 规约 (CONVENTIONS)

- 代码实现或更改之前应加载 `karpathy-guidelines` 技能。
- 代码实现或更改之后应执行‘项目启动命令’重启所有服务。
- 项目默认测试用户为：`default` / `Adminf8869!@`。
- 本地启动器使用后端端口 `8000`，前端端口 `3000`，worker 使用 `python -m app.workers.crawler --kind all`。
- 使用感知时区的 UTC 时间戳：`datetime.now(timezone.utc)`。
- 使用 `Decimal` 比较价格。
- 浏览器身份验证采用 Cookie 优先策略 (`pm_access_token`, `pm_refresh_token`, `pm_csrf_token`)；脚本可以使用 Bearer 作为备用方案。
- 前端 API 模块使用 `/api/v1`；Vite 代理将浏览器请求的 `/api/v1/...` 原样转发给后端，不重写路径。
- 运行时配置：`ALLOWED_ORIGINS` CONTROLS CORS 跨域源 (逗号分隔或 JSON 列表)，`CRAWLER_HEADLESS=false` 会在本地调试时以可见窗口形式打开 Playwright/配置浏览器，`PRODUCT_CRAWL_CONCURRENCY` 限制了单个 worker 任务内的商品爬取并发量 (默认/最小为 `1`)。
- 在保存 Home Assistant token 之前必须设置 `SMART_HOME_SECRET_KEY`；智能家居路由使用 `smart_home:read`, `smart_home:control` 和 `smart_home:configure` 权限。

## 不要做 (ANTI-PATTERNS)

- 不要在 Windows 上使用 `uvicorn --reload`；这会破坏 Playwright 子进程的处理。
- 不要手动重命名/复制/删除 `profiles/{key}`。
- 不要同时在同一个配置目录上运行两个爬取/登录会话。
- 不要在日志或事件负载中泄露 cookie、token、webhook 或安全字段。
- 不要声称已通过验证，除非命令/浏览器检查实际运行完毕。

## API 契约与 ORVAL 工作流 (API CONTRACT & ORVAL WORKFLOW)

**关键规则：绝对不要在前端手动编写 AXIOS 请求或 TYPESCRIPT API 接口。**
我们使用 `Orval` 实现端到端类型安全 (End-to-End Type Safety)。当您需要添加或修改 API 功能时，您**必须**遵循以下确切顺序：

1. **后端优先 (Backend First)**：修改 FastAPI 路由和 Pydantic 模式 (schemas)。
2. **导出 OpenAPI (Export OpenAPI)**：运行脚本导出最新的 OpenAPI 架构：
   `powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system; python scripts/export_openapi.py"`
3. **生成前端客户端 (Generate Frontend Client)**：运行 Orval 生成器：
   `powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run api:generate"`
4. **运行静态校验 (Run Verification)**：
   - 校验 API 契约漂移：在根目录运行 `python scripts/check_api_contract.py`
   - 校验前端 Axios/api 直接调用限制：在 `frontend/` 目录运行 `npm run api:check-usage`
5. **使用生成客户端 (Use Generated Client)**：普通 HTTP 请求使用 `frontend/src/shared/api/generated/` 中的生成函数、React Query hooks 或 query options。业务 wrapper 可以保留轮询、缓存失效和 UI 数据映射，但不得重新手写 Axios 请求或用 `any`/`unknown` 断言覆盖生成类型。
6. **Git 提交 (Git Commit)**：提交时必须同时包含修改的后端文件**以及**新生成的前端 `generated` 目录。

### URL 所有权规则 (URL Ownership Rule)
- FastAPI 和 OpenAPI 暴露规范的 `/api/v1` 路径。
- 生成的 API URLs 包含 `/api/v1`。
- Mutator 中的 `customInstance` 必须在调用共享 Axios 客户端之前截断且仅截断一次 `/api/v1` 前缀，以避免与 Axios `baseURL=/api/v1` 重复；浏览器最终请求仍是完整的 `/api/v1/...`。
- 共享 Axios 客户端是唯一拥有浏览器请求 `baseURL`（即 `/api/v1`）的地方。
- Vite 和生产反向代理必须原样转发 `/api/v1/...`，不得剥离 `/api` 或 `/api/v1`。
- 任何生成的非规范 URL（不以 `/api/v1/` 开头且不是规范路径）都必须直接抛出异常，防止无声请求至错误路径。

### 特殊传输协议策略 (Special Transport Policy)
以下特殊接口不在生成的 Orval 客户端中处理，必须保留独立的定制传输适配器/手写客户端：
- **EventSource / SSE**：`/api/v1/events/stream`, `/api/v1/dashboard/events`, `/api/v1/smart-home/entities/stream`（走手写的 SSE 适配器）
- **二进制下载 (Blob Export)**：`/api/v1/crawl-profiles/{profile_key}/export`（仅 `frontend/src/features/jobs/api/profileBackupExport.ts` 使用手写 Axios；profile 导入使用 Orval）
- **OAuth 302 重定向**：`/api/v1/auth/wechat/callback`
- **公共资源或非规范路径**：`/health`, `/health/detailed`, `/blog-media/{file_name}`
