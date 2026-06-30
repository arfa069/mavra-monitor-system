# 前端架构文档

## 1. 技术栈概览

| 层级        | 技术选型                                                                                   |
| ----------- | ------------------------------------------------------------------------------------------ |
| 语言        | Dart (sdk: `^3.12.2`)                                                                      |
| 框架        | Flutter                                                                                    |
| 路由        | GoRouter (v17.3.0+)                                                                        |
| 状态管理    | ChangeNotifier / Riverpod + Repository 模式                                                |
| HTTP 客户端 | Dio + OpenAPI Generator CLI 生成的 Dart Dio Client (作为独立 package 引入)                 |
| 主题与样式  | Material 3 + 自定义 `MavraTheme` 配置                                                      |
| 字体        | Noto Sans SC (正文) + Noto Serif SC (Today Display/标题) + JetBrains Mono (数据表格与代码) |
| 布局模式    | 响应式自适应布局 (Web/Windows 侧边导航 + 移动端底部导航/More 面板)                         |
| 平台编译    | Web (静态页面/单页应用), Windows (原生可执行程序), Android (APK), iOS (待验证)             |

## 2. 项目结构

```
frontend/
├── assets/                  # 静态资源（本地字体 Roboto / 矢量图形）
├── lib/
│   ├── app/                 # 应用核心入口与全局配置
│   │   ├── mavra_app.dart   # Flutter 根 App Widget (MaterialApp)
│   │   ├── router.dart      # GoRouter 路由树定义与认证/权限守卫
│   │   └── app_shell.dart   # 响应式全局外壳 (MavraShell)
│   ├── core/                # 共享核心基础库
│   │   ├── api/             # API 网络请求封装与生成的客户端
│   │   │   ├── api_client.dart          # 共享基础 Dio 配置与拦截器
│   │   │   ├── authenticated_mavra_api.dart # 包含会话恢复与无感刷新的 API 封装
│   │   │   └── generated/               # OpenAPI Generator 生成的 API Client package
│   │   ├── auth/            # 全局用户认证上下文
│   │   │   ├── auth_repository.dart     # 账户存取库接口与实现
│   │   │   └── auth_controller.dart     # 状态管理控制器 (ChangeNotifier)
│   │   ├── config/          # 应用全局配置环境变量
│   │   ├── errors/          # 自定义网络与业务异常定义
│   │   ├── files/           # 跨平台文件导入导出/选择器适配
│   │   ├── platform/        # 运行期平台能力探测
│   │   ├── realtime/        # SSE 实时通信流适配接口
│   │   ├── theme/           # 视觉设计系统 tokens (Color, Typography, Density)
│   │   └── widgets/         # 全局复用 UI 组件 (FilterBar, ConfirmationDialog, ErrorView等)
│   ├── features/            # Feature-First 业务功能模块
│   │   ├── admin/           # 用户管理、审计日志与 RBAC 权限矩阵
│   │   ├── alerts/          # 告警设置
│   │   ├── analytics/       # 趋势图表与 KPI 统计页面
│   │   ├── auth/            # 登录、注册、微信 OAuth 回调、个人 Profile 修改
│   │   ├── blog/            # 博客富文本编辑器与文章管理
│   │   ├── events/          # 审计与系统事件查看器
│   │   ├── jobs/            # 职位搜索配置、爬虫 Profile 管理、简历管理、LLM 匹配
│   │   ├── products/        # 商品列表、批量导入导出、手动爬取、价格历史趋势
│   │   ├── schedule/        # 定时爬取 Cron 编辑器与参数设置
│   │   ├── settings/        # 飞书 Webhook 与全局配置
│   │   ├── smart_home/      # Home Assistant 连接测试与实体控制
│   │   └── today/           # "今日摘要" 核心首屏与关注项队列
│   ├── visual_qa/           # 视觉 QA 测试用 Dummy App
│   ├── main.dart            # 生产环境入口文件
│   └── main_visual_qa.dart  # 视觉测试环境入口文件
├── test/                    # 单元测试与 Widget 测试目录
└── integration_test/        # 跨平台冒烟与平台能力集成测试目录
```

各业务 Feature 内部遵循 **Domain-Driven Design (DDD)** 的三层划分方式：

- `domain/`：业务模型定义 (models) 与 Feature 级抽象 Repository 接口。
- `data/`：对接生成的后端客户端，实现 Repository 接口，做数据归一化、持久化、定时轮询等。
- `presentation/`：具体的 Page / Widget 视图，以及视图关联的控制器。

## 3. 路由与安全守卫 (router.dart)

路由由 `GoRouter` 进行集中管理，实现了认证与权限的 UX 级拦截保护。

### 3.1 路由结构划分

- **公开路由**：无需登录即可访问，例如 `/login` (登录)、`/register` (注册)、`/auth/wechat/callback` (微信 OAuth 回调)。
- **保护外壳路由 (ShellRoute)**：所有已认证的受保护页面，都嵌套在全局 `MavraShell` (全局布局外壳) 内，共享相同的导航栏与头部，包括：
  - `/today` (今日)
  - `/dashboard` (数据看板/分析)
  - `/events` (事件中心)
  - `/jobs` (职位监控)
  - `/products` (商品监控)
  - `/schedule` (定时调度)
  - `/smart-home` (智能家居)
  - `/profile` (个人信息)
  - `/settings` (应用配置)
  - `/admin/users` (用户管理)
  - `/admin/audit-logs` (审计日志)
  - `/admin/blog` (博客写作)

### 3.2 路由重定向与守卫

`GoRouter` 接收 `AuthController` 作为 `refreshListenable`。当认证状态发生变化时，会触发重定向校验：

1. **未认证拦截**：用户未登录且尝试访问非公开路由时，重定向到 `/login`。如果带有 fragment 目标路由（例如 `#/products`），会在登录成功后跳转到该目标。
2. **已认证重定向**：用户已登录且访问 `/login` 或 `/register` 时，自动重定向到 `/today` 或 fragment 指定的目标。

### 3.3 细粒度权限控制

对于具有高权限要求的后台管理端页面，路由使用 `_permissionPage` 包装：

```dart
GoRoute(
  path: '/admin/users',
  builder: (context, state) => _permissionPage(
    authController,
    'user:read', // 目标所需权限
    AdminUsersPage(repository: adminRepository),
  ),
)
```

若 `authController.hasPermission` 校验失败，该路由将不渲染目标页面，而是渲染 `PermissionDeniedPage` 提示缺失的权限，并提供回退到 `/today` 的按钮。

## 4. 全局状态管理

应用不依赖复杂的重量级状态管理框架，主要采用 Repository 接口存取数据，配合 Flutter 基础机制实现响应：

### 4.1 用户认证状态 (auth_controller.dart)

`AuthController` 继承自 `ChangeNotifier`，是全局认证的单一真相来源：

- 维护 `isAuthenticated`、`currentUser` (包含 username, role, permissions) 等关键变量。
- **启动恢复 (Session Restore)**：Web 端由浏览器自动携带 HttpOnly Cookie，并在需要时通过 refresh Cookie 恢复会话；原生 Windows/Android/iOS 端从平台安全存储读取会话，先校验本地过期时间，过期则调用 `POST /api/v1/auth/refresh` 轮换令牌。refresh 失败或本地会话无效时会通过调用 `authRepository.logout()` 清除本地会话状态，并触发路由回到 `/login`。
- **权限判定**：暴露 `hasPermission`、`hasAnyPermission` 等方法，在 UI 层级控制各种操作性按钮（如 "Crawl Now"、"Save"）的启用与禁用状态。

### 4.2 业务数据流动模式

- 界面在初始化时调用 Feature Repository 的 `Future` 获取静态/分页数据。
- 数据变化（例如保存修改、删除）由控制器或 Widget 里的 `StatefulWidget` 局部管理状态，执行完成后手动刷新 Repository 并重绘视图。
- 手动爬取任务（商品 / 职位）运行周期长，采用后台**异步轮询任务状态**的交互模式，轮询完毕后整体回调数据流。

## 5. API 封装与客户端生成

为了确保前后端类型安全 (End-to-End Type Safety)，系统使用自动化工具生成 API 客户端，并对其进行网络拦截器包装。

### 5.1 客户端生成工作流

1. **导出 OpenAPI 契约**：在后端修改 API Schema 后，在项目根目录运行 `uv run --project backend --extra dev python scripts/export_openapi.py` 导出 `openapi.json`。
2. **生成 Dart 客户端**：在根目录运行 `./scripts/generate_dart_client.ps1`。该脚本读取 `openapi-generator-config.yaml` 配置，调用 `@openapitools/openapi-generator-cli` 生成以 `Dio` 为底层的 Dart SDK 客户端 package (输出到 `lib/core/api/generated` 并在宿主 `pubspec.yaml` 中以本地 path 形式引用)。

> **红线**：严禁手动修改 `lib/core/api/generated/` 内部代码。每次修改后端 Schema 后必须运行脚本重新生成，确保完全契约一致。

### 5.2 Cookie 与无感刷新拦截器 (api_client.dart)

网络层在 Dio 中嵌入了复杂的拦截器链：

1. **CSRF 防护**：对于不安全方法 (POST/PATCH/PUT/DELETE)，请求拦截器会从本地 Cookie (如果是 Web) 读取 `pm_csrf_token` 并注入到 HTTP Header `X-CSRF-Token` 中。
2. **401 无感刷新 (Auto-Refresh)**：当响应返回 401 且不是登录接口时，Dio 响应拦截器将拦截当前请求，首先静默调用 `POST /api/v1/auth/refresh`。
   - 刷新成功：自动保存最新的 Token 或更新 Cookie，并使用原始配置重新发起此前失败的网络请求，对用户端完全透明。
   - 刷新期间的并发 401 请求：会自动进入待重试队列 (`failedQueue`)，刷新完成后统一重试，避免多次重复请求刷新接口。
   - 刷新失败：调用 `authRepository.logout()` 清除本地会话状态，并重定向到 `/login`。

## 6. 响应式布局设计 (MavraShell)

应用需要在 Web 端（大屏、宽屏）、Windows 桌面端以及 Android 移动端（窄屏、手势操作）提供一致且适宜的交互体验。

- **大屏自适应 (宽屏 >= 1024px)**：`MavraShell` 显示固定顶部 AppBar 与左侧 Side Navigation Rail（侧边栏文字标签展开）。
- **中屏自适应 (768px <= 宽屏 < 1024px)**：Sider Navigation 折叠成仅图标导轨模式，腾出最大视口宽度用于呈现密集数据表格。
- **窄屏/移动端 (宽屏 < 768px)**：
  - 左侧侧栏折叠，转换为顶部汉堡菜单唤出 Drawer 抽屉，或底部 Bottom Navigation Bar 常用 5 栏跳转。
  - 数据表格降级为单列卡片流式滚动，支持横向划动触发详细属性 Bottom Sheet。
  - 大量长表单（例如搜索配置、用户管理）由 Modal 弹窗在移动端自动转换为全屏 Bottom Sheet 交互，方便拇指触达。

## 7. 定时轮询与 SSE 实时数据

- 对于告警变动、Dashboard KPI 统计，应用默认根据平台能力检测进行处理：
  - 在支持 SSE (Server-Sent Events) 的平台（如 Web 和 Android）上，`RealtimeClient` 通过长连接监听 `/api/v1/dashboard/events` 等流，实时更新前台局部值。
  - 在不支持或受限平台（如 Windows 某些沙盒网络），自动降级为定时的短轮询 (`PollingRealtimeClient`)。
- Smart Home 实体变化数据通过 `/api/v1/smart-home/entities/stream` 流进行中转推送，在 `smart_home_page.dart` 中建立局部 Stream 订阅，一旦捕获变更，毫秒级更新对应设备的卡片状态。
