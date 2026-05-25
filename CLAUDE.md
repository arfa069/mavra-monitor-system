# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 提供代码库操作指南。

<!-- gitnexus:start -->

# GitNexus — Code Intelligence

This project is indexed by GitNexus as **price-monitor** (6134 symbols, 11526 relationships, 222 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

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

| Resource                                       | Use for                                  |
| ---------------------------------------------- | ---------------------------------------- |
| `gitnexus://repo/price-monitor/context`        | Codebase overview, check index freshness |
| `gitnexus://repo/price-monitor/clusters`       | All functional areas                     |
| `gitnexus://repo/price-monitor/processes`      | All execution flows                      |
| `gitnexus://repo/price-monitor/process/{name}` | Step-by-step execution trace             |

## CLI

| Task                                         | Read this skill file                                        |
| -------------------------------------------- | ----------------------------------------------------------- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md`       |
| Blast radius / "What breaks if I change X?"  | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?"             | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md`       |
| Rename / extract / split / refactor          | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md`     |
| Tools, resources, schema reference           | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md`           |
| Index, status, clean, wiki CLI commands      | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md`             |

<!-- gitnexus:end -->

# 执行任何命令前必读⚠️

在运行任何 shell / test / lint 命令之前，**必须**先查看本文件第 3 节的"常用命令"，
确认正确的执行方式。默认不在 PATH 中的工具，必须通过 `powershell.exe` 调用。

## 1.始终加载Karpathy编码准则⚠️

Always load the `karpathy-guidelines` skill when coding.

## 2.项目概览

淘宝、京东、亚马逊价格监控系统 + Boss/51job/猎聘职位搜索监控。商品页面通过 Playwright 抓取；职位平台优先通过 `curl_cffi`/HTTP API 抓取，记录价格/职位历史，降价或新职位时通过飞书 Webhook 发送通知。

**技术栈**：Python 3.11+ · FastAPI · PostgreSQL (async SQLAlchemy) · Redis · Playwright · 飞书 Webhook
**前端**：React + Vite + TypeScript + Ant Design + Figma Design System（黑白核心 + 马卡龙色块 + 胶囊按钮）

## 3.常用命令

### 安装依赖

powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pip install -e ."

### 运行数据库迁移

powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; alembic upgrade head"

### 启动前端服务器和后端服务器 **前端端口3000，后端8000**

powershell.exe -Command "cd C:/Users/arfac/price-monitor; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"

### 运行测试

powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest"

### 代码检查

powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check ."

## 4.后端架构

→ 详见 doc/backend-architecture.md
→ 权限架构详见 doc/permission-architecture.md

## 5.前端架构

→ 详见 doc/frontend-architecture.md

## 6.关键约定

- user_id 硬编码为 1（单用户系统）已添加多用户认证，原有 user_id=1 硬编码仍适用于商品/职位爬取
- 系统的测试用户: default123 密码:123456
- 所有时间戳字段使用 UTC 时区（`datetime.now(timezone.utc)`）
- 价格比较使用 Decimal 避免浮点误差
- LLM provider 通过 `LLMProviderFactory` 切换，支持 Anthropic/OpenAI/Ollama

## 7.本地开发及验证流程

- 默认闭环：改动 → 检查/构建 → 重启服务 → 真实验证 → 报告证据。
- 命令执行前先看第 3 节，Windows 下优先使用 `powershell.exe -Command "..."`。
- 后端改动：运行相关 `pytest`；影响共享逻辑/权限/调度/爬虫/模型时运行完整 `pytest` 和 `ruff check .`。
- 前端改动：运行相关检查；提交前默认运行 `npm run lint` 和 `npm run build`。
- 涉及 UI/路由/弹窗/下拉/表单/权限/爬取触发时，必须启动前后端并用浏览器真实验证。
- 涉及商品/JD 爬虫登录态时，必须确认 Edge CDP 可用：`http://127.0.0.1:9222/json/version` 返回 `webSocketDebuggerUrl`。
- Boss 职位爬取默认走 `BossCloakExperimentalAdapter`，不再走 Edge CDP；验证前确认用户已在 `~/.cloakbrowser/profiles/boss-test` 对应 CloakBrowser profile 登录 Boss。
- Boss 真实运行日志写入 `backend/logs/boss_cloak_adapter_<timestamp>.jsonl`（已 gitignore）；排查风控、耗时和详情完整性时先看该文件。
- 京东/淘宝等商品强反爬流程仍默认用已登录的 Edge CDP 专用浏览器验证。
- 无法执行的验证必须说明原因；未实际执行的检查不得声称通过。

## 8. Design System

- 未经用户明确批准，不得偏离设计系统。
- 在做任何视觉或 UI 决策前，必须先阅读 `DESIGN.md`。
- 字体、颜色、间距、组件风格和整体美学方向均以 `DESIGN.md` 为准。
- 进行 UI 审查或 QA 时，必须指出任何不符合 `DESIGN.md` 的实现。
