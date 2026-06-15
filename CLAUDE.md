# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 提供代码库操作指南。

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **mavra-monitor-system** (10669 symbols, 19368 relationships, 300 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

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

## 项目快照

Mavra 做价格监控（淘宝/京东/亚马逊）、职位监控（Boss/51job/猎聘）和
Home Assistant 智能家居控制。后端是 FastAPI + PostgreSQL/Redis +
Playwright/curl_cffi；前端是 React/Vite/TypeScript/Ant Design。
业务 API 只使用 `/api/v1`，根路径和 `/v1` 业务别名应返回 404。主应用首页是
`/today`。

## 文件定位

| 领域 | 文件 |
| --- | --- |
| 后端应用/路由 | `backend/app/main.py`, `backend/app/domains/*/router.py` |
| 爬取/Profile 运行期 | `backend/app/domains/crawling/*`, `backend/app/platforms/*`, `backend/app/workers/crawler.py` |
| 职位功能 | `backend/app/domains/jobs/*`, `frontend/src/features/jobs/*` |
| 智能家居 | `backend/app/domains/smart_home/*`, `backend/app/schemas/smart_home.py`, `frontend/src/features/smart-home/*` |
| 认证/RBAC | `backend/app/core/security.py`, `backend/app/core/permissions.py`, `frontend/src/shared/contexts/AuthContext.tsx`, `doc/permission-architecture.md` |
| 前端壳/API | `frontend/src/App.tsx`, `frontend/src/shared/api/*`, `frontend/src/shared/api/generated/*` |
| 文档 | `doc/` 放当前架构/教程/参考；`docs/` 放计划和阶段报告 |

做 UI 前先读 `doc/DESIGN.md`。只有明确需要手动 UI/爬取验证时，才使用
`backend/tests/manual_verification_checklist.md`。

## 常用命令

在 Windows PowerShell 运行。后端命令优先通过 `uv run --extra dev` 进入
`backend/.venv`，不要裸跑 `python` / `pytest` / `ruff`，避免走到全局 Python
或 Anaconda shim。

```powershell
# 后端
cd C:/Users/arfac/Documents/mavra-monitor-system/backend
uv sync --extra dev
uv run --extra dev python -m ruff check .
uv run --extra dev python -m pytest

# 前端
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
npm run lint
npm run test:unit
npm run build
npm run test:e2e

# 博客前端
cd C:/Users/arfac/Documents/mavra-monitor-system/blog-frontend
npm test
npm run build
```

`scripts/start_server.ps1` 会清理端口并启动后端、前端和 crawler worker。它只用于
明确需要本地全栈运行的场景，不是默认验证命令。

## 工作规则

- 改代码前遵循项目 skill 流程；适用时加载 `karpathy-guidelines`。
- 没有实际命令或浏览器证据，不要声称完成或通过。
- 除非用户明确要求 live 验证，不要运行真实爬取、Profile 登录/测试/导入/导出、worker、职位匹配或 Home Assistant 控制。
- 不要手动编辑 `profiles/{key}`，也不要在同一 profile 上并行跑两个会话。
- Windows 上不要用 `uvicorn --reload`，它会破坏 Playwright 子进程。
- 不要在日志、事件或报告中泄露 cookie、token、webhook 等密钥。
- 时间使用感知时区 UTC：`datetime.now(timezone.utc)`；价格使用 `Decimal`。
- 认证是 Cookie 优先：`pm_access_token`, `pm_refresh_token`, `pm_csrf_token`；脚本可用 Bearer 兜底。
- 保存 Home Assistant token 前必须配置 `SMART_HOME_SECRET_KEY`。

## API 契约与 Orval

后端 OpenAPI 是唯一 API 契约。普通 JSON 前端请求必须使用 Orval 生成代码。

1. 修改 FastAPI route/schema/`response_model` 和后端测试。
2. 运行 `uv run --project backend --extra dev python scripts/export_openapi.py`。
3. 运行 `cd frontend; npm run api:generate`。
4. 前端通过 `frontend/src/shared/api/generated/` 适配；wrapper 可以做数据归一化、轮询、缓存失效或 UI 映射，但不能手写 Axios。
5. 运行 `uv run --project backend --extra dev python scripts/check_api_contract.py` 和 `cd frontend; npm run api:check-usage`。
6. 同一提交必须包含后端改动、`frontend/openapi.json`、生成客户端、前端适配和测试。

URL 所有权：

- OpenAPI/Orval 保留规范 `/api/v1/...` 路径。
- `frontend/src/shared/api/mutator.ts` 只截断一次 `/api/v1`。
- `frontend/src/shared/api/client.ts` 是唯一拥有 `baseURL=/api/v1` 的地方。
- Vite 和生产反代必须原样转发 `/api/v1/...`。

只有这些传输可以绕过普通 Orval JSON 客户端：

- SSE/EventSource 流。
- Blob 导出：`frontend/src/features/jobs/api/profileBackupExport.ts`。
- OAuth 302 callback。
- 非业务资源：`/health`, `/health/detailed`, `/blog-media/{file_name}`。

红线：不要手改 `frontend/src/shared/api/generated/`；不要在 feature 层新增`api.get/post/put/patch/delete`；不要用 `as any` 或 `as unknown as` 掩盖类型漂移，应修 schema 或写显式 normalizer。
