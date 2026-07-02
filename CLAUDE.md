# PROJECT KNOWLEDGE BASE

## 项目快照

Mavra 做价格监控（淘宝/京东/亚马逊）、职位监控（Boss/51job/猎聘）和
Home Assistant 智能家居控制。后端是 FastAPI + PostgreSQL/Redis +
OpenCLI + Firecrawl（商品爬取）/ curl_cffi（职位爬取）；主前端是 Flutter/Dart，
公共博客仍是 Next.js。业务 API 只使用 `/api/v1`，根路径和 `/v1` 业务别名应返回 404。
主应用首页是 `/today`。生产部署在 Termux 手机服务器（192.168.1.13:3000），
通过 GitHub Actions CD + Windows self-hosted runner 自动发布。

## 文件定位

| 领域                | 文件                                                                                                                                                            |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 后端应用/路由       | `backend/app/main.py`, `backend/app/domains/*/router.py`                                                                                                        |
| 爬取/Profile 运行期 | `backend/app/domains/crawling/*`, `backend/app/platforms/*`, `backend/app/workers/crawler.py`                                                                   |
| 职位功能            | `backend/app/domains/jobs/*`, `frontend/lib/features/jobs/*`                                                                                                    |
| 智能家居            | `backend/app/domains/smart_home/*`, `backend/app/schemas/smart_home.py`, `frontend/lib/features/smart_home/*`                                                   |
| 认证/RBAC           | `backend/app/core/security.py`, `backend/app/core/permissions.py`, `frontend/lib/core/auth/*`, `frontend/lib/features/auth/*`, `doc/permission-architecture.md` |
| 前端壳/API          | `frontend/lib/app/*`, `frontend/lib/core/api/*`, `frontend/lib/core/api/generated/*`                                                                            |
| 部署/CD             | `scripts/deploy_termux_from_runner.ps1`, `scripts/deploy_termux_remote.sh`, `scripts/start_termux_stack.sh`, `.github/workflows/ci.yml`                         |
| 文档                | `doc/` 放当前架构/教程/参考（含 `deployment-progress.md`, `howto-termux-cd.md`）；`docs/` 放计划和阶段报告                                                      |

做 UI 前先读 `doc/DESIGN.md`。只有明确需要手动 UI/爬取验证时，才使用`backend/tests/manual_verification_checklist.md`。

## 常用命令

在 Windows PowerShell 运行。后端优先使用 `uv run --extra dev python -m ...`
进入 `backend/.venv`；如果已手动激活 `.venv`，也要使用 `python -m pytest` /
`python -m ruff`，不要裸跑 `pytest` / `ruff`，避免走到 Anaconda shim 或全局包。

```powershell
# Python 后端
cd C:/Users/arfac/Documents/mavra-monitor-system/backend
uv run --extra dev python -m ruff check .
uv run --extra dev python -m pytest

# Flutter 前端
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
flutter pub get
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=/api/v1
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1

# 博客前端（Next.js，仍使用 npm；不是 Flutter 主前端）
cd C:/Users/arfac/Documents/mavra-monitor-system/blog-frontend
npm test
npm run build
```

`scripts/start_server.ps1` 会清理端口并启动后端、前端和 crawler worker。它只用于
明确需要本地全栈运行的场景，不是默认验证命令。

## 工作规则

- 改代码前遵循项目 skill 流程；适用时加载 `karpathy-guidelines`。
- 项目测试账户：default 密码： Adminf8869!@
- 没有实际命令或浏览器证据，不要声称完成或通过。
- 除非用户明确要求 live 验证，不要运行真实爬取、Profile 登录/测试/导入/导出、worker、职位匹配或 Home Assistant 控制。
- 不要手动编辑 `profiles/{key}`，也不要在同一 profile 上并行跑两个会话。
- Windows 上不要用 `uvicorn --reload`，它会破坏 Playwright 子进程。
- 不要在日志、事件或报告中泄露 cookie、token、webhook 等密钥。
- 时间使用感知时区 UTC：`datetime.now(timezone.utc)`；价格使用 `Decimal`。
- 认证是 Cookie 优先：`pm_access_token`, `pm_refresh_token`, `pm_csrf_token`；脚本可用 Bearer 兜底。
- 保存 Home Assistant token 前必须配置 `SMART_HOME_SECRET_KEY`。

## 测试流程

| 修改范围 | 测试重点 |  
| 前后端都修改代码 | 前端单元测试 -> 后端单元测试 -> 后端集成测试 -> API 接口测试 -> 前后端联调测试 -> E2E 测试 -> 回归测试 -> 验收测试 |
| 只修改前端代码 | 静态检查 / 构建检查 -> 前端单元测试 -> 组件测试 -> 页面交互测试 -> 接口 Mock 测试 -> 少量 E2E 核心流程测试 -> 前端回归测试 |
| 只修改后端代码 | 后端单元测试 -> 后端集成测试 -> API 接口测试 -> 数据库 / 权限 / 异常测试 -> 兼容旧前端字段测试 -> 少量 E2E 核心流程测试 -> 后端回归测试 |

## API 契约与 Dart OpenAPI Client

后端 OpenAPI 是唯一 API 契约。普通 JSON 前端请求必须使用生成的 Dart Dio
client，不要手写 HTTP 调用。

1. 修改 FastAPI route/schema/`response_model` 和后端测试。
2. 运行 `cd backend; uv run --extra dev python ../scripts/export_openapi.py`。
3. 运行 `cd ..; ./scripts/generate_dart_client.ps1`。
4. 前端通过 `frontend/lib/core/api/generated/` 适配；repository 可以做数据归一化、轮询、缓存失效或 UI 映射，但不能绕过 generated client。
5. 运行 `cd backend; uv run --extra dev python ../scripts/check_api_contract.py` 和 `uv run --extra dev python ../scripts/check_dart_api_usage.py`。
6. 同一提交必须包含后端改动、`frontend/openapi.json`、生成客户端、前端适配和测试。

URL 所有权：

- OpenAPI 和 Dart generated client 保留规范 `/api/v1/...` 路径。
- `frontend/lib/core/config/app_config.dart` 拥有默认 `API_BASE_URL`。
- `frontend/lib/core/api/api_client.dart` 是唯一拥有基础 Dio transport 的地方。
- Flutter Web 和生产反代必须原样转发 `/api/v1/...`。

只有这些传输可以绕过普通 Orval JSON 客户端：

- SSE/EventSource 流。
- Blob/文件导入导出：`frontend/lib/core/files/*`。
- OAuth 302 callback、移动端 deep link 或桌面 custom URI callback。
- 非业务资源：`/health`, `/health/detailed`, `/blog-media/{file_name}`。

红线：不要手改 `frontend/lib/core/api/generated/`；不要在 feature 层实例化原始
`Dio` 或拼接旧 `/v1` 业务路径；不要用类型逃逸掩盖 schema 漂移，应修 schema
或写显式 normalizer。
