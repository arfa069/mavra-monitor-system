# 前端架构文档

## 1. 技术栈概览

| 层级        | 技术选型                                                                                            |
| ----------- | --------------------------------------------------------------------------------------------------- |
| 语言        | TypeScript                                                                                          |
| 构建工具    | Vite                                                                                                |
| UI 框架     | React 18 + Ant Design 5                                                                             |
| 路由        | React Router DOM v6                                                                                 |
| 状态管理    | React Context（AuthContext）+ TanStack React Query                                                  |
| HTTP 客户端 | Orval generated client + Axios mutator                                                              |
| CSS         | CSS Design Tokens + Ant Design token + `components.css` 全局覆盖                                    |
| 字体        | General Sans（标题）+ DM Sans（正文）+ Geist（表格数字）+ JetBrains Mono（标签/代码）+ CSS 变量系统 |
| 图标        | Ant Design Icons（线性风格）                                                                        |
| 设计系统    | Figma 营销风格（黑白核心 + 马卡龙色块 + 胶囊按钮）                                                  |

## 2. 项目结构

```
frontend/src/
├── features/                # feature-first 业务模块
│   ├── auth/
│       ├── LoginPage.tsx    # 登录页
│       ├── RegisterPage.tsx # 注册页
│       ├── ProfilePage.tsx  # 个人资料页
│       └── api/auth.ts      # 认证 API client
│   ├── admin/
│       ├── AdminUsersPage.tsx # 用户、角色、资源权限管理
│       ├── AdminAuditLogsPage.tsx # 审计日志页
│       ├── api/admin.ts     # 管理端 API client
│       └── hooks/useAdmin.ts # RBAC 和资源权限 hooks
│   ├── alerts/
│       ├── api/alerts.ts    # 告警 API client
│       └── hooks/useAlerts.ts # 告警 query/mutation hooks
│   ├── dashboard/
│       ├── DashboardPage.tsx # Dashboard 页面编排
│       ├── components/      # Dashboard KPI / 图表组件
│       ├── hooks/           # Dashboard SSE / trends hooks
│       └── types.ts         # Dashboard 业务类型
│   ├── events/
│       ├── EventCenterPage.tsx # 事件中心页面编排
│       ├── api/events.ts    # 事件中心 API 与 SSE URL helper
│       └── types.ts         # EventCenter 业务类型
│   ├── smart-home/
│       ├── SmartHomePage.tsx # Home Assistant 页面编排
│       ├── api/smartHome.ts  # Home Assistant API client
│       ├── hooks/useSmartHomeSSE.ts # 实时状态 SSE hook
│       └── types.ts          # Home Assistant 业务类型
│   ├── products/
│       ├── ProductsPage.tsx # 商品管理页编排
│       ├── api/             # 商品 CRUD 与商品爬取 API client
│       ├── components/      # 商品表单、批量导入、价格趋势弹窗
│       ├── hooks/           # 商品列表、历史、爬取日志与 Crawl Now hooks
│       └── types.ts         # 商品 feature 类型入口
│   ├── jobs/
│       ├── JobsPage.tsx     # 职位管理页编排
│       ├── api/             # 职位、简历、匹配分析 API client
│       ├── components/      # 搜索配置、Profile 管理、职位列表、详情抽屉、简历、匹配结果
│       ├── hooks/           # 职位配置、Profile、职位列表、爬取、简历、匹配 hooks
│       └── types.ts         # 职位 feature 类型入口
│   ├── schedule/
│       ├── ScheduleConfigPage.tsx # 商品/职位定时配置页
│       ├── components/CronGenerator.tsx
│       └── hooks/useScheduleConfig.ts
│   └── settings/
│       ├── SettingsPage.tsx # 账号设置页
│       └── api/config.ts    # 用户配置与 scheduler status API
├── shared/
│   ├── api/client.ts        # 共享 Axios 实例（拦截器 + 错误处理）
│   ├── api/mutator.ts       # Orval 自定义 mutator，桥接 generated client
│   ├── api/generated/       # OpenAPI/Orval 生成代码，不手改
│   ├── components/          # 全局布局、主题、过渡、权限标识组件
│   ├── contexts/
│       └── AuthContext.tsx  # 全局认证上下文（用户状态 + 权限）
│   ├── hooks/               # 通用 UI hooks
│   └── types/               # 通用权限、用户、动效类型
├── styles/                  # Figma 设计系统
│   ├── design-tokens.css   # CSS 变量（颜色/排版/间距/圆角 token）
│   └── components.css       # Ant Design 组件全局覆盖（Figma 风格）
├── App.tsx                  # 根组件 + 路由配置
├── main.tsx                 # 入口文件
└── index.css                # 全局样式（导入 design-tokens + components）
```

## 3. 入口与路由（App.tsx）

根组件结构：

```tsx
<AuthProvider>
  {/* 全局认证上下文 */}
  <QueryClientProvider>
    {/* 全局 React Query */}
    <ConfigProvider>
      {/* Ant Design 主题配置 */}
      <BrowserRouter>
        <Routes>
          <PublicRoute>
            <LoginPage />
          </PublicRoute>
          <PublicRoute>
            <RegisterPage />
          </PublicRoute>
          <ProtectedRoute>
            <AppLayout>
              <DashboardPage />
              <EventCenterPage />
              <JobsPage />
              <ProductsPage />
              <ScheduleConfigPage />
              <SmartHomePage />
              <SettingsPage />
              <ProfilePage />
            </AppLayout>
          </ProtectedRoute>
          <PermissionRoute permission="user:read">
            <AppLayout>
              <AdminUsersPage />
              <AdminAuditLogsPage />
            </AppLayout>
          </PermissionRoute>
        </Routes>
      </BrowserRouter>
    </ConfigProvider>
  </QueryClientProvider>
</AuthProvider>
```

**路由守卫：**

- `ProtectedRoute` — 未登录重定向到 `/login`，登录后自动跳转首页
- `PublicRoute` — 已登录用户访问自动跳转 `/jobs`
- `PermissionRoute` — 已登录但权限不足时重定向到 `/jobs`
- 根路径 `/` 和未知路径 `*` 重定向到 `/jobs`

**Ant Design 主题配置（ConfigProvider）：**

- 主色：`#000000`（黑色）
- 背景色：`#ffffff`（白色 canvas）
- 圆角：50px（胶囊按钮）/ 8px（输入框）/ 24px（卡片）
- 字体大小：16px
- 字体：`'Inter', 'SF Pro Display', system-ui`
- 组件级 token：Button borderRadius: 50, Input borderRadius: 8, Table borderRadius: 24, Card borderRadius: 24

**设计系统 CSS 变量（src/styles/design-tokens.css）：**

| Token                  | 值        | 用途                |
| ---------------------- | --------- | ------------------- |
| `--color-primary`      | `#000000` | 主 CTA / 标题       |
| `--color-canvas`       | `#ffffff` | 页面背景            |
| `--color-hairline`     | `#e6e6e6` | 边框                |
| `--color-surface-soft` | `#f7f7f5` | 软表面（侧栏/色块） |
| `--color-block-lime`   | `#dceeb1` | 商品页/定时配置标题 |
| `--color-block-cream`  | `#f4ecd6` | 职位页/个人信息标题 |
| `--color-block-navy`   | `#1f1d3d` | 深色块              |
| `--radius-pill`        | `50px`    | 胶囊按钮            |
| `--radius-lg`          | `24px`    | 卡片/色块           |

**字体 Token（2026-05-11 从营销风调小到后台管理标准）：**

| Token                    | 值     | 用途                |
| ------------------------ | ------ | ------------------- |
| `--font-size-headline`   | `20px` | 页面标题            |
| `--font-size-body`       | `14px` | 正文（原 18px）     |
| `--font-size-body-sm`    | `13px` | 小号正文（原 16px） |
| `--font-size-button`     | `14px` | 按钮文字（原 20px） |
| `--font-size-link`       | `14px` | 链接（原 20px）     |
| `--font-size-card-title` | `16px` | 卡片标题（原 24px） |

## 4. 状态管理

### 4.1 认证状态（AuthContext.tsx）

```tsx
interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (user: User) => void;
  logout: () => void;
  hasPermission: (permission: Permission) => boolean;
  hasAnyPermission: (permissions: Permission[]) => boolean;
  hasAllPermissions: (permissions: Permission[]) => boolean;
}
```

前端使用 AuthContext 暴露的 `hasPermission()` / `hasAnyPermission()` / `hasAllPermissions()` 进行 UX 级别权限控制。`user.role` 仅用于展示和少数角色边界提示；菜单、路由、按钮和只读态以 `user.permissions` 为准。`AuthProvider` memoizes callbacks and the Provider value to keep context references stable across unrelated renders.

**认证方式**：HttpOnly Cookie 传递 access/refresh token。前端不管理 token 字符串。初始化时通过 `GET /api/v1/auth/me` 验证登录状态（Cookie 自动携带）。

**登出流程**：

1. 调用 `POST /api/v1/auth/logout`，后端清除 Cookie 并删除 session
2. 重置 `user` 状态
3. 跳转到 `/login`

### 4.2 服务端状态（React Query）

业务数据通过 TanStack React Query 管理。已拆分的 feature 在各自 `features/*/hooks` 中维护 query/mutation hooks；`hooks/api.ts` 已删除，避免继续形成新的共享热点文件。业务页面和 feature 内部组件从本 feature 的 `types.ts` 导入类型，跨 feature 只通过对方 `index.ts` 暴露的稳定入口或共享基础设施导入。

| Hook                                    | 用途              | 缓存策略               |
| --------------------------------------- | ----------------- | ---------------------- |
| `features/products/useProducts()`       | 商品列表 + 分页   | `staleTime: 10s`       |
| `features/jobs/useJobs()`               | 职位列表 + 分页   | `staleTime: 30s`       |
| `features/smart-home/useSmartHomeSSE()` | 实时实体状态流    | SSE 连接保持           |
| `features/jobs/useJobConfigs()`         | 职位搜索配置列表  | 无持久化               |
| `features/jobs/useCrawlProfiles()`      | 爬虫 profile 列表 | 无持久化               |
| `features/jobs/useMatchResults()`       | LLM 匹配结果      | 无持久化               |
| `features/products/useCrawlLogs()`      | 商品爬取日志      | `refetchInterval: 60s` |
| `features/jobs/useResumes()`            | 用户简历列表      | 无持久化               |
| `features/schedule/useScheduleConfig()` | 用户配置          | 无持久化               |

**Mutation 后自动失效**：`useMutation` 的 `onSuccess` 回调中调用 `qc.invalidateQueries` 刷新相关缓存。

## 5. API 封装层

### 5.1 Axios 实例（api/client.ts）

```ts
const api = axios.create({
  baseURL: API_BASE_URL, // 业务模块统一使用相对路径，baseURL 来自 @/shared/api/base
  timeout: 300000, // 5 分钟超时（爬取操作耗时长）
  withCredentials: true,
});
```

**请求拦截器**：Axios 自动携带凭据（`withCredentials: true`），不安全方法（POST/PATCH/PUT/DELETE）自动注入 `X-CSRF-Token` 请求头（从 `pm_csrf_token` Cookie 读取）。

**401 自动刷新**：响应拦截器检测 401 时，自动调用 `POST /api/v1/auth/refresh` 刷新 access token。并发 401 期间只有第一个请求触发 refresh，其余请求进入 `failedQueue` 并保存各自 the Axios config；刷新成功后按原请求逐个重试。排队请求入队前标记 `_retry`，避免刷新风暴。失败后重定向到 /login。排除 `/api/v1/auth/login` 和 `/api/v1/auth/me` 的刷新循环，避免未登录初始化时反复 refresh/redirect。

**响应拦截器**：

- `401` — 除登录和初始化 `/api/v1/auth/me` 外，尝试 refresh；refresh 失败后重定向到 `/login`
- `>= 500` — 全局错误提示（notification.error）
- `>= 400` — 从 `response.data.detail` 提取错误信息
- `ECONNABORTED` / 无响应 — 超时提示（notification.warning）

### 5.2 API 模块与 Orval 自动生成

为了确保前后端完全的类型安全（End-to-End Type Safety），我们强制使用 `Orval` 自动生成 API 函数、React Query Hooks 和类型，**禁止**手动编写 `axios.get/post` 调用代码（特殊例外见下文）。

**API 自动生成工作流：**

1. 后端修改 FastAPI routes 和 Pydantic schemas。
2. 在项目根目录运行 `uv run --project backend --extra dev python scripts/export_openapi.py` 导出 `openapi.json`。
3. 在 `frontend/` 目录运行 `npm run api:generate` 生成代码。
4. 运行契约和使用规范检查：
   - 在根目录运行 `uv run --project backend --extra dev python scripts/check_api_contract.py` 确保生成物与 openapi 契约无漂移。
   - 在 `frontend/` 目录运行 `npm run api:check-usage` 确保业务代码中无非法的手写 Axios/api 直接调用。
5. 普通 HTTP 请求使用 `src/shared/api/generated/` 中的生成函数、React Query Hooks 或 query options。业务 wrapper 仅保留轮询、缓存失效、稳定 query key 和 UI 数据映射。

自动生成的函数和 Hooks 通过自定义 Mutator (`src/shared/api/mutator.ts`) 桥接到全局 Axios 实例，自动继承现有的请求拦截器、CSRF 附加逻辑和 401 无感刷新机制。

**URL 与所有权规则：**
- 生成的 endpoints 中会包含 `/api/v1`。
- 自定义 Mutator `customInstance` 在接收到配置后，会截断且仅截断一次 `/api/v1` 前缀，以配合 Axios `baseURL=/api/v1`；浏览器最终请求仍为完整的 `/api/v1/...`。
- 非规范路径（不以 `/api/v1` 开头）一律抛出错误，防止非预期调用。
- Vite 与生产反向代理原样转发浏览器的 `/api/v1/...` 请求，不执行路径重写。

**特殊传输协议策略 (Special Transports)：**
以下操作由于传输通道、生命周期或二进制数据流的特殊性，需继续使用手写或专用的传输适配器，不受 Orval 控制：
- **EventSource (SSE 实时流)**：走独立 SSE 适配器（`/api/v1/events/stream`, `/api/v1/dashboard/events`, `/api/v1/smart-home/entities/stream`）。
- **二进制备份下载 (Blob Export)**：`/api/v1/crawl-profiles/{profile_key}/export`（手写 Axios 适配器仅位于 `frontend/src/features/jobs/api/profileBackupExport.ts`；profile 导入使用 Orval 生成函数）。
- **WeChat OAuth 回调 302**：`/api/v1/auth/wechat/callback`。
- **公共资源与探针**：`/health`, `/health/detailed`, `/blog-media/{file_name}`。

业务 API 统一走 `/api/v1`。Axios `baseURL` 保持 `/api/v1`（包含子应用）。开发和生产环境的反向代理直接转发 `/api/v1/...`，不作任何路径前缀重写。直接访问后端时只支持 `/api/v1/...` 作为主入口。商品爬取的前端新路径为 `/api/v1/crawl/*`，旧后端兼容路径 `/products/crawl/*` 被移除。

**Vite 代理配置**（vite.config.ts）：

```ts
server: {
  proxy: {
    '/api': {
      target: 'http://127.0.0.1:8000',
      changeOrigin: true,
    },
  },
}
```

## 6. 页面架构

### 6.1 商品管理页（ProductsPage.tsx）

**功能模块：**

- 商品列表（Table）：支持平台/状态/关键词筛选，分页，批量选择
- 新增/编辑商品（ProductFormModal）：表单 + 告警设置
- 批量导入（BatchImportModal）：Excel/CSV 格式解析
- 批量操作：删除、启用、停用
- 手动爬取：触发 `POST /api/v1/crawl/crawl-now`，轮询任务状态
- 价格趋势（PriceTrendModal）：展示 `GET /api/v1/products/{id}/history`
- 爬取日志：最近 10 条记录（60s 自动刷新）
- **翻页自动回退**：批量删除后若当前页为空，自动回退到上一页

**状态管理模式：** 组件内 `useState` 管理 UI 状态，React Query 管理服务端数据。

### 6.2 职位管理页（JobsPage.tsx）

**Tab 结构：**

- `configs` Tab：搜索配置列表 + 职位列表
- `profiles` Tab（显示为 `Profiles Management`，位于 Search Config 右侧）：爬虫 profile 列表、创建、改名、复制、删除、状态更新、登录浏览器、测试、导入/导出、释放过期租约
- `resume` Tab：简历管理器
- `matches` Tab：匹配结果列表

**核心功能：**

- 搜索配置 CRUD + `profile_key` 选择 + 手动触发爬取
- Profile 管理：调用 `/api/v1/crawl-profiles` 管理 `available/login_required/disabled` 状态、过期 lease、登录浏览器、测试、导入/导出，以及安全的 rename/copy/delete
- 职位列表：关键词/公司在客户端筛选，分页
- 匹配分数展示：`MatchResultList` 中取最高分
- 详情抽屉（JobDrawer）：展示职位完整信息

### 6.3 定时配置页（ScheduleConfigPage.tsx）

**两个表格：**

- 商品抓取定时：per-platform Cron 配置（淘宝/京东/亚马逊）
- 职位抓取定时：per-config Cron 配置

**功能：**

- Cron 表达式输入 + 实时格式校验（5 段 crontab）
- 下次执行时间展示（来自 `/products/cron-schedules` 和 `/jobs/scheduler/job-configs`）
- 飞书 Webhook URL 配置
- 数据保留天数配置

### 智能家居页（SmartHomePage.tsx）

**核心功能：**

- Home Assistant 连接配置查看、保存和连通性测试
- 实体列表展示、区域与状态过滤、服务调用
- SSE 实时状态推送与断线提示
- 配置编辑仅对 `smart_home:configure` 可见，实体控制依赖 `smart_home:control`

### 6.4 登录/注册页（Login.tsx / Register.tsx）

**设计风格：Figma 营销风格左右分栏**

- 左侧品牌面板：白色背景，logo + 超大 display 标题（Inter 340 字重 + 负字间距）+ feature chips（JetBrains Mono）
- 装饰色块：`#dceeb1` lime（登录页）/ `#c5b0f4` lilac（注册页），定位在面板右侧边缘
- 右侧表单面板：`#f7f7f5` 浅灰背景，白色圆角卡片（24px 边框半径），黑色胶囊提交按钮
- 移动端（< 768px）：左右分栏 → 上下布局，装饰色块隐藏
- 公开路由，注册/登录成功后调用 `login(userData)` 写入 AuthContext

## 7. 组件设计

### 7.1 AppLayout（布局组件）

**设计风格：Figma 营销风格**

**桌面端：**

- Header（固定顶部，白色背景，56px 高）：Logo（黑色方块 + 文字）+ 刷新按钮 + 用户下拉菜单
- Sider（固定左侧，`#f7f7f5` 浅灰背景，`border-radius: 0 24px 24px 0`，可折叠）：导航菜单，选中态为黑色填充
- Content（白色背景）：页面内容
- Footer（固定底部，白色背景，JetBrains Mono 版权文字）：版本信息

**移动端（< 768px）：**

- 汉堡菜单触发侧边 Drawer 替代 Sider（`#f7f7f5` 背景）
- Content 区域宽度 100%，无圆角/阴影

**导航菜单：**

- `/jobs` — 职位管理（TeamOutlined）
- `/products` — 商品管理（ShoppingCartOutlined）
- `/schedule` — 定时配置（ScheduleOutlined）
- `/smart-home` — 智能家居（HomeOutlined）
- `/profile` — 个人信息（UserOutlined）
- `/settings` — 账号设置（SettingOutlined）
- `/admin/users` — 用户管理（TeamOutlined，仅 admin/super_admin）
- `/admin/roles` — 角色权限矩阵（仅 super_admin 可见）

### 7.2 业务组件

| 组件                | 类型   | 说明                                                                                        |
| ------------------- | ------ | ------------------------------------------------------------------------------------------- |
| `ProductFormModal`  | 弹窗   | 新增/编辑商品，支持告警配置                                                                 |
| `BatchImportModal`  | 弹窗   | 批量导入，URL 去重检测                                                                      |
| `PriceTrendModal`   | 弹窗   | 价格历史折线图展示                                                                          |
| `JobConfigList`     | 列表   | 搜索配置列表 + 爬取触发                                                                     |
| `JobConfigForm`     | 表单   | 新增/编辑搜索配置                                                                           |
| `ProfileManagement` | 面板   | 爬虫 profile 创建、改名、复制、删除、状态更新、登录浏览器、测试、导入/导出、过期 lease 释放 |
| `JobList`           | 列表   | 职位列表 + 筛选 + 分页                                                                      |
| `JobDrawer`         | 抽屉   | 职位详情（侧滑展示）                                                                        |
| `MatchResultList`   | 列表   | 匹配结果 + 分数筛选                                                                         |
| `ResumeManager`     | 管理器 | 简历 CRUD                                                                                   |

## 8. 类型定义

`frontend/src/types/index.ts` 已删除，避免继续形成跨域类型热点文件。类型按所有权拆分：

- `frontend/src/shared/types/permissions.ts`：权限枚举和 `PermissionLevel`。
- `frontend/src/shared/types/user.ts`：认证用户基础结构。
- `frontend/src/shared/types/motion.ts`：全局动效速度 `MotionSpeed`。
- `frontend/src/features/*/types.ts`：各 feature 自己的业务 DTO、表单值和响应类型。

业务 feature 内部优先从本 feature 的 `types.ts` 导入类型；跨 feature 复用只通过对方 `index.ts` 暴露的稳定入口或 `shared/types`。`MotionSpeed` 不是业务类型，归入 `shared/types/motion.ts`，由主题和过渡组件、设置页类型入口复用。

## 9. 关键交互模式

### 9.1 爬取任务轮询

手动爬取采用后台轮询模式：

```ts
// useCrawlNow 中实现
const response = await crawlApi.crawlNow();
const taskId = response.data.task_id;
for (let attempts = 0; attempts < 60; attempts++) {
  await new Promise((resolve) => setTimeout(resolve, 3000)); // 3s 间隔
  const status = await crawlApi.getStatus(taskId);
  if (status === "completed") {
    const result = await crawlApi.getResult(taskId);
    return result;
  }
}
```

职位爬取同样使用轮询（`useCrawlAllJobs`、`useCrawlSingleJob`）。

### 9.2 批量操作结果处理

批量操作返回 `BatchOperationResult[]`，展示成功/失败统计，失败项显示具体错误信息：

```ts
const successCount = results.filter(r => r.success).length
const failedItems = results.filter(r => !r.success)
message.success(`${action}: ${successCount} 项成功`)
if (failedItems.length > 0) {
  notification.error({ message: `${failedItems.length} 项失败`, description: ... })
}
```

### 9.3 分页自动回退

批量删除后若当前页为空，自动回退到上一页：

```ts
const shouldGoPrev = page > 1 && productItems.length === 1;
deleteMutation.mutate(id, {
  onSuccess: () => {
    if (shouldGoPrev) setPage((p) => Math.max(1, p - 1));
  },
});
```

## 10. 移动端响应式适配

**断点：** `MOBILE_BREAKPOINT = 768px`

| 桌面端                        | 移动端               |
| ----------------------------- | -------------------- |
| 固定 Sider                    | 汉堡菜单 + Drawer    |
| 刷新按钮在 Header             | 刷新按钮在 Drawer 内 |
| Content 有圆角/阴影           | Content 无圆角/阴影  |
| Sider 宽度 180px（折叠 60px） | Drawer 宽度 220px    |

## 11. 启动命令

```bash
# 安装依赖
cd frontend && npm install

# 开发环境
npm run dev          # 启动 Vite Dev Server（端口 3000）

# 生产构建
npm run build
npm run preview      # 预览构建结果
```
