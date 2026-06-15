# Flutter Full Replacement Design

## 目标

将现有 React/Vite 前端全量替换为 Flutter 前端。新前端一次性覆盖
Web、Android、iOS 和 Windows App，不保留 React 与 Flutter 的长期并存入口。

这次迁移不是逐页翻译 React 代码，而是一次大版本重建：

- 使用 Flutter 作为唯一前端技术栈。
- 四端共用核心业务代码和设计语言。
- 后端配合改造为 Token-first 鉴权。
- UI 全量重设计，不要求复刻 Ant Design 页面。
- 功能覆盖现有 React 前端的全部业务能力。

## 已确认决策

- 平台目标：Web、Android、iOS、Windows。
- 迁移策略：大爆炸替换，最终不保留 React 运行时入口。
- 后端策略：允许配合 Flutter 调整 API 和认证契约。
- 鉴权策略：Token-first，Flutter 请求使用 Bearer token。
- UI 策略：全量重设计。
- 体验取向：核心页手机优先，后台和管理页 Web/Windows 优先。

## 非目标

- 不做 React 与 Flutter 双前端长期并存。
- 不按旧 React 文件逐个翻译。
- 不改变业务 API 的主路径前缀，业务接口仍属于 `/api/v1`。
- 不在迁移中触发真实爬取、Profile 登录、职位匹配或 Home Assistant 控制作为默认验证。

## 总体架构

`frontend/` 替换为 Flutter 工程，包含四端平台目录：

```text
frontend/
  lib/
    app/
    core/
      api/
      auth/
      config/
      errors/
      files/
      platform/
      realtime/
      routing/
      theme/
      widgets/
    features/
      today/
      products/
      jobs/
      schedule/
      smart_home/
      events/
      alerts/
      admin/
      blog/
      settings/
      analytics/
  test/
  integration_test/
  android/
  ios/
  web/
  windows/
```

`core/` 放跨业务基础设施，`features/` 按业务域拆分。每个复杂 feature 内部使用
`data/`、`domain/`、`presentation/` 三层：

- `data/`：API client、DTO、repository 实现。
- `domain/`：业务模型、权限判断、用例封装。
- `presentation/`：页面、组件、状态 provider、平台布局。

平台差异集中放在 `core/platform`，避免文件选择、下载、深链、窗口能力等逻辑散落在业务页面。

## 技术栈

- 状态管理：Riverpod。
- 路由：go_router。
- HTTP：Dio。
- API 模型：OpenAPI 生成 Dart client，必要时通过显式 normalizer 转成 UI 模型。
- 安全存储：flutter_secure_storage，并在 Windows 上验证 Credential Manager 或对应实现。
- 文件能力：集中封装上传、下载、文件选择和保存位置。
- 实时能力：优先 SSE；单端不稳定时可降级为轮询或 WebSocket。
- 图表：封装在 analytics/dashboard feature 内，选择 Flutter 原生图表方案。
- 富文本：Blog Admin 单独评估编辑器，优先保证可维护和跨端稳定。
- 测试：unit test、widget test、integration test 分层；Web 和 Windows 必须有冒烟测试。

## 后端/API 改造

### Token-first Auth

新增或调整登录、注册、刷新和会话接口，使 Flutter 四端统一使用：

```text
Authorization: Bearer <access_token>
```

登录响应至少包含：

- `access_token`
- `refresh_token`
- token 过期时间
- 当前用户摘要
- 角色和权限摘要

Access token 短期有效，refresh token 长期有效并支持轮换。Flutter API client 遇到
401 自动刷新；刷新失败时统一清理本地 session 并跳转登录。

Cookie/CSRF 可以暂时保留给旧兼容或脚本，但不再是 Flutter 前端主路径。

### 微信登录

微信登录要从现有 Web callback 扩展为四端可用：

- Flutter Web callback URL。
- Android/iOS deep link。
- Windows custom URI scheme 或本地 loopback callback。
- 未绑定账号时的绑定和注册流程。

回调结果不再依赖浏览器 hash/temp token 的单一路径，应返回 Flutter 客户端可安全消费的短期授权结果。

### OpenAPI 和 Dart Client

后端 OpenAPI 继续作为唯一 API 契约。迁移后 CI 需要包含：

- 导出 OpenAPI。
- 生成 Dart client。
- 检查 Dart client 与后端契约一致。
- 检查普通 JSON 业务调用不绕过生成 client。

现有 Orval/TypeScript 生成链路在 React 删除后移除。

### SSE 和实时事件

Dashboard、Smart Home、Events 的实时流需要支持 Bearer token。首选保留 SSE，以减少后端重写。
如果 Flutter Web 或 Windows 的 SSE 稳定性不足，允许只对问题平台降级为轮询或 WebSocket。

### 文件上传下载

以下能力必须四端可用：

- 简历 PDF 上传。
- Profile backup 导入导出。
- 博客图片上传。
- 商品批量导入。
- 下载文件名和 content-type 处理。

后端错误体统一返回 `code`、`message`、`details`、`trace_id`，方便 Flutter 做 toast、表单错误和诊断展示。

## 功能覆盖范围

Flutter 必须覆盖现有 React 前端全部业务能力。

### Auth / Account

登录、注册、退出、Token 刷新、个人资料、权限加载、微信登录、微信绑定、微信注册回调。

### Today

作为第一屏。手机端展示今日摘要、注意事项队列、模块健康状态和最近动作。Web/Windows 扩展为多栏布局。

### Products / Price Monitor

商品列表、价格历史、批量导入、平台配置、爬取日志、价格规则、手动任务入口。Web/Windows 使用高密度表格；手机端使用列表和详情页。

### Jobs

职位列表、搜索配置、简历管理、PDF 上传、匹配结果、Profile 备份导入导出、运行日志。Jobs 是迁移高风险模块，必须有独立 parity checklist。

### Schedule

商品和职位定时任务、Cron 生成、启停状态、调度器健康状态。

### Smart Home

Home Assistant 配置、实体列表、服务调用、实时状态流。手机端更像控制面板；Web/Windows 保留管理型列表和详情能力。

### Events / Alerts / Analytics

事件中心、提醒列表、趋势图、KPI、最近告警。原 Dashboard 可以被重设计为 Analytics，但数据能力不能减少。

### Admin

用户管理、权限矩阵、审计日志。Web/Windows 提供完整体验；手机端可做轻量布局，但不能完全不可用。

### Blog Admin

文章管理、内容编辑、图片上传。富文本能力允许改为 Markdown 或结构化编辑器，只要能覆盖实际发布工作流。

### Settings

用户配置、系统配置、主题、通知偏好、API 环境、平台权限状态。

## UI 和交互原则

- 核心体验手机优先：Today、提醒、事件、智能家居快捷控制。
- 管理体验桌面优先：Admin、Jobs、Products、Schedule、Blog。
- Web/Windows 使用侧边导航、多栏布局、高密度表格。
- Android/iOS 使用底部导航、列表详情 drill-down、适合触控的操作密度。
- 视觉语言可以延续 Mavra 的温暖、安静、私人助手方向，但不受 Ant Design 限制。
- 所有页面必须有 loading、empty、error、permission denied 状态。

## 实施策略

虽然最终是大爆炸替换，内部实施仍按阶段推进：

1. 冻结现有 React 功能清单，生成 parity checklist。
2. 完成后端 Token-first、微信回调、Bearer SSE、文件错误格式和权限摘要改造。
3. 将 `frontend/` 替换为 Flutter 工程。
4. 完成 Flutter 基座：路由、主题、API client、token 刷新、安全存储、错误处理、文件能力、实时流、平台适配和测试框架。
5. 按模块实现：Auth、Today、Events/Alerts、Products、Jobs、Schedule、Smart Home、Admin、Blog、Settings、Analytics。
6. 四端验收通过后删除 React/Vite/npm/AntD/Orval 前端链路。
7. 更新 AGENTS、README、CI 和部署文档。

## 验收标准

### Web

- 能构建生产 Web 产物。
- 登录、刷新、退出、权限路由可用。
- 所有主要路由可访问。
- 上传下载、SSE、表格操作可用。

### Android/iOS

- 登录和 token 刷新可用。
- 微信 deep link 或替代登录回调可用。
- Today、事件、提醒、智能家居核心路径可用。
- 文件选择和上传可用。

### Windows

- 能构建 Windows App。
- 登录、退出、token 安全存储可用。
- 窗口缩放和桌面布局稳定。
- 文件上传下载可用。
- SSE 或降级实时方案可用。

### 后端和契约

- Token auth、refresh token 轮换和登出失效有测试。
- OpenAPI 导出成功。
- Dart client 生成成功。
- 契约检查通过。
- `/api/v1` 仍是业务 API 主路径。

## 风险和降级方案

### 迁移期前端不可用

大爆炸替换会有一段时间无法依赖 React 前端。降级方案是保留完整 parity checklist 和验收脚本，只在 Flutter 通过验收后删除旧链路。

### Token-first 改造影响安全模型

Bearer token 替代 Cookie/CSRF 是安全边界变化。必须增加 refresh token 轮换、失效、设备会话和权限加载测试。

### Flutter Web 后台体验不足

表格、编辑器和复杂表单可能不如 React/AntD 成熟。高密度管理页面需要桌面专用组件，Blog 编辑器允许采用 Markdown 或结构化编辑。

### 四端平台能力差异

文件、下载、深链、窗口和安全存储差异必须集中在 `core/platform`。业务模块只依赖统一接口。

### SSE 稳定性

如某个平台 SSE 不稳，允许该平台使用轮询或 WebSocket fallback，不能阻塞其他平台。

### 功能遗漏

全量重设计最容易漏功能。每个 feature 必须有 React parity checklist，验收时逐项勾选。

## 完成定义

迁移完成必须满足：

- React/Vite 前端运行时入口已移除。
- Flutter Web、Android、iOS、Windows 均可构建。
- 所有现有业务模块在 Flutter 中有可用替代。
- 后端 Token-first 鉴权和 OpenAPI/Dart client 生成链路已进入 CI。
- 文档中的开发、测试、构建命令与真实项目一致。
- 验收报告明确列出四端通过项、未覆盖项和替代方案。
