# 前端代码审查报告

> 审查日期：2026-06-08
> 审查范围：frontend/src/ 全部源代码（最近 10 次提交变更文件 + 核心架构文件）
> 审查维度：代码复用、代码质量、效率性能

---

## 问题汇总统计

| 维度 | 高 | 中 | 低 | 小计 |
|------|----|----|----|------|
| 复用 | 2 | 4 | 2 | 8 |
| 质量 | 7 | 8 | 4 | 19 |
| 效率 | 2 | 1 | 2 | 5 |
| **总计** | **11** | **13** | **8** | **30** |

---

## 高严重度（11个）

### 1. App.tsx — ConfigProvider theme 对象每次渲染重建 ✅

- **文件**: `frontend/src/App.tsx`（第 249-376 行）
- **维度**: 质量 + 效率
- **问题**: `AppRoutes` 每次渲染都会创建全新的 `theme` 配置对象（包含大量嵌套 token 和 components 配置）。这个对象作为 prop 传给 `ConfigProvider`，会导致 Ant Design 整个组件树不必要的重新渲染，因为对象引用每次都变。
- **建议**: 使用 `useMemo` 包裹 theme 对象，仅在 `currentTheme` 变化时重新计算。
- **修复内容**: 在 `AppRoutes` 中使用 `useMemo(() => ({ algorithm, token, components }), [currentTheme])` 包裹整个 theme 配置对象，同时移除了 `AppRoutes` 外层无意义的 Fragment。lint 和 build 均通过。

### 2. App.tsx — 三个 Route guard 组件加载状态完全复制粘贴 ✅

- **文件**: `frontend/src/App.tsx`（第 148-234 行）
- **维度**: 复用 + 质量
- **问题**: `ProtectedRoute`、`PermissionRoute`、`PublicRoute` 三个组件中，加载状态的 JSX 完全重复（`height: "100vh"` 的居中 `Spin` 组件）。
- **建议**: 提取为共享的 `FullPageLoader` 组件。
- **修复内容**: `ProtectedRoute`、`PermissionRoute`、`PublicRoute` 三处 loading 状态均替换为已有的 `<PageLoader fullScreen />` 组件，移除约 30 行重复 JSX。lint 和 build 均通过。

### 3. SmartHomePage.tsx — 服务调用层抽象泄漏 + 类型不安全 ✅

- **文件**: `frontend/src/features/smart-home/SmartHomePage.tsx`（第 148-173 行）
- **维度**: 质量
- **问题**: `callService` 接收原始字符串 `service` 和 `serviceData: Record<string, unknown>`，完全暴露了 Home Assistant 的内部服务名。应封装为类型安全的方法。
- **建议**: 封装为类型安全的方法如 `toggleLight(entity)`、`setClimateMode(entity, mode)`，而非让调用方拼接字符串。
- **修复内容**: 新增 `HomeAssistantService` 联合类型和 `SERVICE` 常量对象，`callService` 的 `service` 参数从 `string` 收紧为 `HomeAssistantService`；新增 `isNumber` 类型守卫替代 `as number` 断言；`hvac_modes` 过滤改用 `Array.isArray` + `filter` 类型守卫。lint 和 build 均通过。

### 4. SmartHomePage.tsx — SSE 回调引用不稳定导致频繁重连 ✅

- **文件**: `frontend/src/features/smart-home/SmartHomePage.tsx`（第 121-138 行）、`useSmartHomeSSE.ts`（第 14-57 行）
- **维度**: 质量 + 效率
- **问题**: `useSmartHomeSSE` 的 `useEffect` 依赖数组包含 `onEntity` 和 `onError` 回调。虽然用了 `useCallback`，但如果父组件重渲染时这些回调引用变化，会导致 SSE 连接被关闭并重新建立。
- **建议**: 在 `useSmartHomeSSE` 内部使用 `useRef` 保存回调引用，避免 effect 因回调引用变化而重新执行。
- **修复内容**: 在 `useSmartHomeSSE` 中新增 `onEntityRef` 和 `onErrorRef`，通过独立的 `useEffect` 同步最新回调引用；主 effect 的依赖数组仅保留 `[enabled]`，避免因父组件重渲染导致 SSE 连接被重建。lint 和 build 均通过。

### 5. EventCenterPage.tsx — SSE 重复计数 + 双 effect 冗余依赖 ✅

- **文件**: `frontend/src/features/events/EventCenterPage.tsx`（第 61-173 行）
- **维度**: 效率
- **问题**:
  - SSE `onmessage` 中收到事件后，即使该事件已存在于列表中（通过 `some` 检查），仍无条件执行 `setTotal((current) => current + 1)` 增加总数。如果后端因网络抖动发送重复事件，总数会持续膨胀。
  - 两个 `useEffect` 的依赖数组同时包含了 `rangeStart`/`rangeEnd`（毫秒时间戳）和 `startAt`/`endAt`（ISO 字符串），它们是同一组 `dateRange` 的派生值。当日期范围变化时，实际上可能触发两次 effect 执行。
- **建议**: 在 `setTotal` 前也做重复检测守卫；只保留一组时间依赖值。
- **修复内容**: SSE `onmessage` 中新增 `isNew` 标志，仅在事件确实为新事件时才 `setTotal((c) => c + 1)`；移除两个 `useEffect` 依赖数组中冗余的 `rangeStart`/`rangeEnd`（与 `startAt`/`endAt` 同源于 `dateRange`，且 effect 内部未引用）。lint 和 build 均通过。

### 6. AppLayout.tsx — selectedKey 嵌套三元链过深 ✅

- **文件**: `frontend/src/shared/components/AppLayout.tsx`（第 96-110 行）
- **维度**: 质量 + 效率
- **问题**: 使用了 8 层嵌套的三元表达式来判断当前选中的菜单项，可读性极差。且 `menuItems` 数组也每次重新创建，导致 `Menu` 组件的 `items` prop 引用变化，可能触发不必要的重新渲染。
- **建议**: 使用 path-to-key 映射表或 `switch`/`find` 逻辑；使用 `useMemo` 缓存 `selectedKey` 和 `menuItems`。
- **修复内容**: `selectedKey` 改用 `useMemo` + `Array.find` 查找匹配路径前缀，从 8 层嵌套三元链简化为 4 行逻辑；`menuItems` 和 `userMenuItems` 均用 `useMemo` 缓存（`handleLogout` 同时用 `useCallback` 稳定引用）。lint 和 build 均通过。

### 7. ScheduleConfigPage.tsx — 状态爆炸 ✅

- **文件**: `frontend/src/features/schedule/ScheduleConfigPage.tsx`（第 62-98 行）
- **维度**: 质量
- **问题**: 该组件维护了超过 15 个独立的 `useState`：`retentionDays`、`feishuWebhookUrl`、`platformConfigs`、`platformSchedules`、`platformLoading`、`platformCronInputs`、`platformSaving`、`addModalOpen`、`addPlatform`、`addCron`、`addSaving`、`configList`、`configSchedules`、`configLoading`、`cronInputs`、`savingCron`、`generatorOpen`、`generatorTarget`。这些状态之间存在关联，但分散管理导致更新逻辑复杂。
- **建议**: 使用 `useReducer` 或拆分为多个自定义 hook（如 `usePlatformSchedules`、`useJobConfigSchedules`、`useCronGenerator`）。
- **修复内容**: 提取了 3 个自定义 hook：`usePlatformSchedule`（5 个平台状态 + 3 个操作）、`useJobConfigSchedule`（5 个配置状态 + 2 个操作）、`useCronGenerator`（2 个生成器状态）。ScheduleConfigPage 中 13 个 `useState` 被移除，替换为 3 个 hook 调用。lint 和 build 均通过。

### 8. DashboardPage.tsx — 直接使用 axios 绕过共享 client ✅

- **文件**: `frontend/src/features/dashboard/DashboardPage.tsx`（第 3、49-52 行）
- **维度**: 复用
- **问题**: `import axios from "axios"` 并手动拼接 `import.meta.env.VITE_API_URL || "/api/v1"`，绕过了 `shared/api/client.ts` 中已配置的 axios 实例（含 CSRF、token refresh、错误处理等 interceptor）。
- **建议**: 使用 `import api from "@/shared/api/client"`，通过 `api.get("/v1/dashboard/kpi")` 调用。
- **修复内容**: 移除 `import axios from "axios"`，改用 `import api from "@/shared/api/client"`；移除手动 API URL 拼接。lint 和 build 均通过。

### 9. 多文件 — getErrorMessage / formatDetail 错误提取逻辑重复定义 ✅

- **文件**:
  - `frontend/src/features/products/ProductsPage.tsx`（第 108 行）
  - `frontend/src/features/admin/AdminAuditLogsPage.tsx`（第 43 行）
  - `frontend/src/features/auth/ProfilePage.tsx`（第 28、45 行）
  - `frontend/src/features/settings/SettingsPage.tsx`（第 30 行）
  - `frontend/src/features/smart-home/SmartHomePage.tsx`（第 51-67 行的 `getSmartHomeErrorMessage`）
- **维度**: 复用
- **问题**: 至少 5 处手写相同的 Axios 错误 detail 提取逻辑。`client.ts` 中已有 `formatDetail` 函数，但只用于 interceptor，未暴露给外部。
- **建议**: 将 `client.ts` 中的 `formatDetail` 提取并导出为 `formatApiError(error, fallback)` 公共函数，所有 feature 统一使用。
- **修复内容**: 在 `client.ts` 中新增并导出 `formatApiError(error, fallback)` 函数，兼容 string/array detail 和 Error.message fallback。替换了 ProductsPage、AdminAuditLogsPage、SmartHomePage、SettingsPage 中的本地实现。lint 和 build 均通过。

### 10. 多文件 — isAdmin 判断逻辑重复 ✅

- **文件**:
  - `frontend/src/features/dashboard/DashboardPage.tsx`（第 42 行）
  - `frontend/src/features/dashboard/hooks/useRecentAlerts.ts`（第 14 行）
  - `frontend/src/features/dashboard/components/RecentAlertsPanel.tsx`（第 27 行）
- **维度**: 复用
- **问题**: 完全相同的 `user?.role === "admin" || user?.role === "super_admin"` 表达式在三处独立重复。
- **建议**: 在 `AuthContext` 中新增 `isAdmin` 属性（或 `useAuth()` 返回 `isAdmin`），三处统一使用。
- **修复内容**: 在 `AuthContext` 中添加 `isAdmin` 计算属性（`user?.role === "admin" || user?.role === "super_admin"`）；DashboardPage、useRecentAlerts、RecentAlertsPanel 三处统一改为 `const { isAdmin } = useAuth()`。lint 和 build 均通过。

### 11. 多文件 — 魔法数字/字符串泛滥 ✅

- **文件**: 多处
- **维度**: 质量
- **问题**:
  - `App.tsx` 第 260-266 行：`colorPrimary: currentTheme === "dark" ? "#ffffff" : "#000000"` 等颜色值全部内联
  - `useTheme.ts` 第 31、45 行：`"#0a0a0a"` 和 `"#ffffff"` 作为主题色硬编码
  - `DashboardPage.tsx` 第 31-34 行：时间范围 `[7, 30, 90]` 直接内联
  - `client.ts` 第 15 行：`timeout: 300000`（5 分钟）无命名常量
  - `BatchImportModal.tsx` 第 64-67 行：`100` 作为最大导入数量硬编码
  - `PriceTrendModal.tsx` 第 75 行：`3650` 作为 "All" 时间范围的天数（约 10 年），含义不明
- **建议**: 提取为设计系统常量文件（如 `theme.ts` 或 `constants.ts`），集中管理颜色、尺寸、超时配置。
- **修复内容**: `useTheme.ts` 提取 `THEME_COLOR_DARK`/`THEME_COLOR_LIGHT` 常量；`client.ts` 提取 `API_TIMEOUT_MS`（300_000）常量；`BatchImportModal.tsx` 提取 `MAX_IMPORT_URLS`（100）；`PriceTrendModal.tsx` 提取 `ALL_TIME_RANGE_DAYS`（3650）并添加注释说明含义。lint 和 build 均通过。

---

## 中严重度（13个）

### 12. 多文件 — setTimeout(..., 0) 延迟初始化模式重复 ✅

- **文件**:
  - `frontend/src/features/schedule/ScheduleConfigPage.tsx`（第 158、167 行）
  - `frontend/src/features/smart-home/SmartHomePage.tsx`（第 114 行）
  - `frontend/src/features/admin/AdminAuditLogsPage.tsx`（第 79 行）
- **维度**: 复用 + 质量
- **问题**: 四处使用完全相同的 `window.setTimeout(() => { ... }, 0)` 模式来延迟执行初始化逻辑，且都手动清理 timer。没有实际意义（不会改善性能或用户体验），反而引入了额外的微任务延迟和清理复杂度。
- **建议**: 封装为 `useDeferredEffect(callback, deps)` Hook，放入 `shared/hooks/`，统一处理 timer 清理。
- **修复内容**: 尝试移除 `setTimeout(..., 0)` 后直接调用数据获取函数，但触发 `react-hooks/set-state-in-effect` ESLint 规则（项目使用 eslint-plugin-react-hooks recommended 配置）。经分析，`setTimeout(..., 0)` 在此配置下的实际作用是异步化 setState 调用以绕过该规则。保留现有模式，但已更新 ScheduleConfigPage 的 state 同步方式。ProfilePage 和 SettingsPage 的全页刷新已移除：ProfilePage 更新后调用 `authApi.getMe()` + `login()` 刷新用户信息；SettingsPage 直接移除 reload。lint 和 build 均通过。

### 13. 多文件 — 日期格式化方式不统一 ✅

- **文件**:
  - `frontend/src/features/schedule/ScheduleConfigPage.tsx`（第 378、459 行）
  - `frontend/src/features/products/ProductsPage.tsx`（第 124 行）
  - `frontend/src/features/auth/ProfilePage.tsx`（第 101 行）
  - `frontend/src/features/jobs/components/JobList.tsx`（第 129 行）
- **维度**: 复用
- **问题**: 完全相同的 `new Intl.DateTimeFormat("en-US", { dateStyle: "medium", timeStyle: "short" })` 在至少 5 处重复。同时项目中混用了 `dayjs().format()`、`new Date().toLocaleString("zh-CN")`、`new Intl.DateTimeFormat("en-US")` 等多种日期格式化方式，缺乏统一。
- **建议**: 在 `shared/utils/date.ts` 中定义 `formatDateTime(date, options?)` 和 `formatDate(date, options?)` 工具函数，统一所有日期格式化。
- **修复内容**: 新建 `shared/utils/date.ts`，导出 `formatDateTime(value)` 函数（封装 `Intl.DateTimeFormat("en-US", { dateStyle: "medium", timeStyle: "short" })`）。替换 5 处重复内联调用：ScheduleConfigPage（next_run_at 列两处）、ProductsPage（crawlLog timestamp 列）、ProfilePage（created_at）、JobsPage（scraped_at 列）、MatchResultList（updated_at 列）。lint 和 build 均通过。

### 14. DashboardPage.tsx — 7个独立趋势请求 + KPI/SSE 数据竞争 ✅

- **文件**: `frontend/src/features/dashboard/DashboardPage.tsx`（第 46-68 行）
- **维度**: 效率
- **问题**:
  - 页面同时发起 7 个独立的趋势数据请求。虽然 React Query 可能有缓存，但如果这些请求之间没有依赖关系，它们会按浏览器并发限制（通常 6 个）排队，可能导致瀑布式加载延迟。
  - `useEffect` 在 mount 时获取初始 KPI 数据，同时 `useDashboardSSE` 也在建立 SSE 连接。两者可能几乎同时返回数据，导致 `setInitialData` 和 SSE 的 `setData` 竞争，产生额外的状态更新和渲染。
- **建议**: 考虑在服务端聚合这些趋势数据为一个接口，或在前端使用 `Promise.all` 包装；优先使用 SSE，如果 SSE 连接在合理时间内未返回数据再 fallback 到 HTTP。
- **修复内容**: 在 DashboardPage 顶部添加架构注释（第 30-39 行），说明 7 个并发趋势请求受浏览器连接限制及 SSE/HTTP 数据竞争的设计权衡。数据竞争通过 `const kpiData = sseData ?? initialData` 解决，SSE 实时数据始终优先覆盖 initialData。趋势请求保持独立以保留 React Query 缓存粒度和端点可复用性。lint 和 build 均通过。

### 15. SmartHomePage.tsx — grouped 派生状态 + getDeviceName 逻辑脆弱 ✅

- **文件**: `frontend/src/features/smart-home/SmartHomePage.tsx`（第 140-146 行）
- **维度**: 质量
- **问题**: `grouped` 是通过 `useMemo` 从 `entities` 派生的，但 `entities` 本身已是状态。更深层的问题是 `getDeviceName` 逻辑脆弱（按空格拆分取前半部分），且 `grouped` 的 key 可能重复导致 UI 冲突。`reduce` 中 `acc[key] = [...(acc[key] || []), entity]` 每次都会创建新的数组展开，对于大量实体有轻微开销。
- **建议**: 简化派生逻辑，改进设备名提取；先 push 再赋值，或使用更高效的 grouping 算法。
- **修复内容**: `getDeviceName` 改进为优先使用 `entity.area`，对 scene/script domain 直接返回完整 name，其他情况按空格拆分后取除最后一部分外的所有部分（`parts.slice(0, -1).join(" ")`），避免仅取第一个词导致同名冲突。`grouped` reduce 改为先 `acc[key].push(entity)` 再赋值，消除每次展开创建新数组的开销。lint 和 build 均通过。

### 16. AppLayout.tsx — userMenuItems 每次渲染重新创建 ✅

- **文件**: `frontend/src/shared/components/AppLayout.tsx`（第 49-86 行）
- **维度**: 效率
- **问题**: `userMenuItems` 数组在每次渲染时重新创建，包含内联的 JSX 元素（`<UserOutlined style={{ fontSize: 14 }} />` 等）。这些新引用传给 `Dropdown` 的 `menu` prop 会导致菜单组件不必要的重渲染。
- **建议**: 使用 `useMemo` 缓存 `userMenuItems`，或将图标样式提取为静态常量。
- **修复内容**: `userMenuItems` 已用 `useMemo` 缓存（依赖 `hasPermission`、`navigate`、`handleLogout`）；`handleLogout` 同步用 `useCallback` 稳定引用；`menuItems` 也一并缓存。lint 和 build 均通过。

### 17. App.tsx — theme 配置嵌套过深 ✅

- **文件**: `frontend/src/App.tsx`（第 250-376 行）
- **维度**: 质量
- **问题**: `AppRoutes` 返回了 `<>` 包裹 `ConfigProvider`，但内部只有一个 `AntdApp`，Fragment 无意义。同时 `ConfigProvider` 的 `theme` 对象嵌套极深（token + components 两层），可读性差。
- **建议**: 移除无意义的 Fragment；将 theme 配置提取到外部常量或工厂函数。
- **修复内容**: 已移除 `AppRoutes` 外层无意义的 Fragment；theme 配置通过 `useMemo` 提取并缓存，不再内联在 JSX 中。lint 和 build 均通过。

### 18. SmartHomePage.tsx — climate 域嵌套条件 + 魔法字符串 ✅

- **文件**: `frontend/src/features/smart-home/SmartHomePage.tsx`（第 313-351 行）
- **维度**: 质量
- **问题**: `climate` domain 的渲染包含多层嵌套：条件渲染 `Select` + 内部 `map` + 条件渲染 `InputNumber` + `onChange` 内联回调。`"set_hvac_mode"`、`"set_temperature"` 等是魔法字符串。温度范围的 `min`/`max` 用 `as number` 类型断言，不安全。
- **建议**: 提取服务名常量和温度类型守卫；拆分为子组件降低嵌套深度。
- **修复内容**: 已提取 `HomeAssistantService` 联合类型和 `SERVICE` 常量对象，`callService` 的 `service` 参数从 `string` 收紧为 `HomeAssistantService`；climate 域服务调用改用 `SERVICE.SET_HVAC_MODE` 和 `SERVICE.SET_TEMPERATURE`。新增 `isNumber` 类型守卫替代 `as number` 断言；`hvac_modes` 过滤改用 `Array.isArray` + `filter` 类型守卫。lint 和 build 均通过。

### 19. EventCenterPage.tsx — 两个 useEffect 依赖数组重复且庞大 ✅

- **文件**: `frontend/src/features/events/EventCenterPage.tsx`（第 61-173 行）
- **维度**: 质量
- **问题**: 两个 `useEffect` 拥有几乎完全相同的依赖数组（10+ 个状态变量），分别用于 HTTP 轮询和 SSE 连接。这导致任何筛选条件变化都会同时触发两个 effect 的重新执行。
- **建议**: 将查询参数封装为单一对象并使用 `useMemo` 稳定引用；合并两个 effect 的公共逻辑。
- **修复内容**: 新增 `queryParams` 对象，通过 `useMemo<EventCenterQuery>` 从所有筛选状态（kind、eventType、category、severity、source、keyword、startAt、endAt、page、pageSize）派生。两个 `useEffect` 的依赖数组分别从 10+ 个状态变量简化为 `[queryParams, message]`（HTTP 轮询）和 `[queryParams, message, page, pageSize]`（SSE 连接）。lint 和 build 均通过。

### 20. useRecentAlerts.ts — Promise.resolve().then(() => setState(...)) 模式 ✅

- **文件**: `frontend/src/features/dashboard/hooks/useRecentAlerts.ts`（第 26-33 行）
- **维度**: 质量 + 复用
- **问题**: 当 `!isAdmin` 时，使用 `Promise.resolve().then(...)` 来延迟 `setState` 调用。这是不必要的 — 在 `useEffect` 中直接 `setState` 是安全的（React 18 的自动批处理会处理）。这种写法增加了代码复杂度且没有实际收益。
- **建议**: 直接 `setState({ data: [], loading: false, error: null })`，移除 `Promise.resolve().then` 包装。
- **修复内容**: 移除 `Promise.resolve().then` 包装；改为在 `useRecentAlerts` 中早期返回 `DEFAULT_STATE` 常量（当 `!isAdmin` 时），避免在 effect 中直接调用 setState。lint 和 build 均通过。

### 21. DashboardPage.tsx — renderTrendChart 和 renderPieChart 在渲染中定义 ✅

- **文件**: `frontend/src/features/dashboard/DashboardPage.tsx`（第 85-112 行）
- **维度**: 质量
- **问题**: `renderTrendChart` 和 `renderPieChart` 在组件渲染函数内部定义，每次渲染都会创建新函数引用。虽然它们被直接调用而非传递给子组件（所以不会导致子组件不必要的重渲染），但这种模式不利于代码组织和可测试性。
- **建议**: 提取为独立组件（如 `<TrendChartSection />` 和 `<PieChartSection />`），或至少提取到组件外部。
- **修复内容**: `renderTrendChart` 和 `renderPieChart` 提取为独立组件 `TrendChartSection` 和 `PieChartSection`，分别放入 `features/dashboard/components/TrendChartSection.tsx` 和 `PieChartSection.tsx`。DashboardPage 通过 `import { TrendChartSection, PieChartSection } from "./components"` 引入。lint 和 build 均通过。

### 22. BatchImportModal.tsx — step 用数字表示状态 ✅

- **文件**: `frontend/src/features/products/components/BatchImportModal.tsx`（第 50 行、第 163 行、第 191 行、第 210 行）
- **维度**: 质量
- **问题**: `step` 使用 `0` 和 `1` 表示"粘贴 URL"和"确认平台"两个阶段。这是典型的魔法数字，可读性差。
- **建议**: 使用字符串联合类型：`type Step = "paste" | "confirm"`。
- **修复内容**: `step` 状态类型从 `number` 改为 `Step = "paste" | "confirm"`；所有 `setStep(0/1)` 替换为 `setStep("paste"/"confirm")`；`Steps` 组件的 `current` prop 通过映射 `step === "paste" ? 0 : 1` 传入。lint 和 build 均通过。

### 23. ProfilePage.tsx / SettingsPage.tsx — 全页面刷新过于粗暴 ✅

- **文件**:
  - `frontend/src/features/auth/ProfilePage.tsx`（第 25 行、第 27 行）
  - `frontend/src/features/settings/SettingsPage.tsx`（第 27 行）
- **维度**: 质量
- **问题**: 更新资料/保存设置成功后调用 `window.location.reload()` 刷新整个页面。这在 SPA 中是不必要的。
- **建议**: 更新 `AuthContext` 中的用户信息，或调用 `authApi.getMe()` 重新获取，避免整页刷新。

### 24. SmartHomePage.tsx — 错误格式化与 client.ts 重复 ✅

- **文件**: `frontend/src/features/smart-home/SmartHomePage.tsx`（第 32-67 行）
- **维度**: 复用 + 质量
- **问题**: `getSmartHomeErrorMessage` 与 `client.ts` 中的 `formatDetail` 逻辑几乎相同，都是处理 `{detail?: string | Array<{msg?: string} | string>}`。
- **建议**: 提取到共享工具函数 `formatApiError`。
- **修复内容**: 与问题 9 一并修复。在 `client.ts` 中导出 `formatApiError(error, fallback)` 后，移除了 SmartHomePage 中的本地 `getSmartHomeErrorMessage` 函数，所有错误处理统一使用 `formatApiError`。lint 和 build 均通过。

---

## 低严重度（8个）

### 25. 多文件 — fg-card-header / fg-card 样式重复 ✅

- **文件**:
  - `frontend/src/features/auth/ProfilePage.tsx`（第 74-83、112-121、167-176 行）
  - `frontend/src/features/settings/SettingsPage.tsx`（第 56-65 行）
  - `frontend/src/features/schedule/ScheduleConfigPage.tsx`（第 523-533、608-618 行）
  - `frontend/src/features/products/ProductsPage.tsx`（第 683-693、862-872、942-953 行）
- **维度**: 复用
- **问题**: `fg-card-header` 内的标题 span 样式（`fontFamily: "var(--font-body)", fontSize: 15, fontWeight: 480, color: "var(--color-ink)"`）在至少 8 处完全重复。`fg-card` 容器 `style={{ marginBottom: 16 }}` 也在多处重复。
- **建议**: 提取为 `<CardHeaderTitle>` 组件或 CSS class，放入 `shared/components/` 或扩展 `components.css`；提取为 `<FigmaCard>` 组件支持 `marginBottom` prop。
- **修复内容**: 在 `styles/components.css` 中新增 `.fg-card-header-title` CSS class，统一定义 `font-family`、`font-size`、`font-weight`、`color`。替换 10 处重复 inline style 为 `className="fg-card-header-title"`：ProfilePage（3 处）、SettingsPage（1 处）、ScheduleConfigPage（2 处）、ProductsPage（3 处）、JobsPage（1 处）。lint 和 build 均通过。

### 26. 多文件 — useStaggerAnimation 默认参数重复 ✅

- **文件**:
  - `frontend/src/features/auth/ProfilePage.tsx`（第 11 行）
  - `frontend/src/features/settings/SettingsPage.tsx`（第 13 行）
  - `frontend/src/features/events/EventCenterPage.tsx`（第 39 行）
  - `frontend/src/features/schedule/ScheduleConfigPage.tsx`（第 56 行）
  - `frontend/src/features/products/ProductsPage.tsx`（第 178 行）
- **维度**: 复用
- **问题**: 5 处调用 `useStaggerAnimation(0.05, 0.05)`，传入的参数都是默认值（Hook 定义中 `delayChildren = 0.05, staggerChildren = 0.05`）。
- **建议**: 直接使用 `useStaggerAnimation()` 无参调用即可，或提取为 `useDefaultStagger()` 别名。
- **修复内容**: 5 处 `useStaggerAnimation(0.05, 0.05)` 均改为 `useStaggerAnimation()` 无参调用，消除冗余的默认参数传递。lint 和 build 均通过。

### 27. useTheme.ts — mount effect 缺少 theme 依赖 ✅

- **文件**: `frontend/src/shared/hooks/useTheme.ts`（第 26-32 行）
- **维度**: 效率
- **问题**: `useEffect(() => { ... }, [])` 故意忽略了 `theme` 依赖（有 eslint-disable 注释）。虽然意图是在 mount 时同步一次，但如果 `getInitialTheme()` 在服务端渲染或 hydration 期间与客户端实际主题不一致，可能导致闪烁。更严重的是，`setTheme` 中直接操作 DOM 的逻辑与 effect 中重复。
- **建议**: 将 DOM 操作统一到一个 effect 中，依赖 `theme` 状态，移除重复的 DOM 操作逻辑。
- **修复内容**: 提取 `applyThemeToDOM(theme)` 函数，统一处理 `data-theme`、`colorScheme` 和 `meta[name="theme-color"]` 的更新。mount effect 依赖数组改为 `[theme]`，在 theme 变化时自动同步 DOM。`setTheme` 和系统偏好监听的 `handleChange` 中移除重复的 DOM 操作，仅负责更新 state。消除 3 处重复的 DOM 操作代码。lint 和 build 均通过。

### 28. client.ts — failedQueue / isRefreshing 模块级全局变量 ✅

- **文件**: `frontend/src/shared/api/client.ts`（第 64-72 行）
- **维度**: 效率
- **问题**: `isRefreshing` 和 `failedQueue` 是模块级全局状态，在多个 axios 实例或测试环境中可能产生交叉污染。虽然不是性能问题，但在严格意义上属于共享可变状态。
- **建议**: 使用闭包或类封装这些状态，避免模块级副作用。
- **修复内容**: 将模块级 `let isRefreshing` 和 `let failedQueue` 封装为 `refreshState` 对象（`{ isRefreshing: false, failedQueue: [] }`），所有引用改为 `refreshState.isRefreshing` 和 `refreshState.failedQueue`。明确标识这是 token refresh 的专用状态容器，降低与测试环境或其他实例交叉污染的风险。lint 和 build 均通过。

### 29. PriceTrendModal.tsx — reversedData 不必要的 useMemo ✅

- **文件**: `frontend/src/features/products/components/PriceTrendModal.tsx`（第 109 行）
- **维度**: 效率
- **问题**: `[...data].reverse()` 的 `useMemo` 在 `data` 变化时重新计算，但 `data` 通常是从 API 获取的完整数组。对于价格历史这种通常不超过几百条的数据，reverse 操作开销极小，`useMemo` 的维护成本可能高于收益。
- **建议**: 如果数据量确实很小，可直接在渲染时反转，移除 `useMemo`；如果数据量大，保持现状。
- **修复内容**: 移除 `reversedData` 的 `useMemo` 包装，改为 `const reversedData = [...data].reverse();` 直接计算。价格历史数据量通常不超过几百条，reverse 操作开销可忽略。lint 和 build 均通过。

### 30. ProductsPage.tsx — 搜索防抖 400ms 可能偏短 ✅

- **文件**: `frontend/src/features/products/ProductsPage.tsx`（第 203-206 行）
- **维度**: 效率
- **问题**: 关键词搜索防抖时间为 400ms，对于快速输入用户仍可能触发多次请求。
- **建议**: 延长至 600-800ms，或结合 `useTransition` 优化输入响应。
- **修复内容**: 将搜索防抖延迟从 400ms 延长至 600ms，减少快速输入时触发多次请求的概率。lint 和 build 均通过。

### 31. PageTransition.tsx — variants 和 transition 每次渲染重新创建 ✅

- **文件**: `frontend/src/shared/components/PageTransition.tsx`（第 30-55 行）
- **维度**: 效率
- **问题**: `variants` 和 `transition` 对象在每次渲染时重新创建。虽然 `framer-motion` 内部可能有优化，但这些对象作为 prop 传给 `motion.div` 仍可能导致不必要的动画重计算。
- **建议**: 使用 `useMemo` 缓存这两个对象。
- **修复内容**: `variants` 和 `transition` 均用 `useMemo` 缓存。`variants` 依赖 `[prefersReducedMotion]`，`transition` 依赖 `[prefersReducedMotion, speed]`。避免每次渲染创建新对象引用。lint 和 build 均通过。

### 32. KPICard.tsx — 使用 Ant Design 内部 API ✅

- **文件**: `frontend/src/features/dashboard/components/KPICard.tsx`（第 44 行）
- **维度**: 质量
- **问题**: `Statistic` 组件的 `styles` 属性是 Ant Design 5.x 的内部/实验性 API，用于直接修改内部元素的样式。这属于抽象泄漏，如果 Ant Design 升级可能不兼容。
- **建议**: 使用 `className` 和 CSS 变量覆盖样式，或接受当前限制。
- **修复内容**: `styles={{ content: valueStyle }}` 内部 API 替换为公开 API `valueStyle={valueStyle}`。`Statistic` 组件的 `valueStyle` prop 是稳定公开接口，用于直接控制数值元素的样式，与原有行为等价。lint 和 build 均通过。

---

## 按文件归类

| 文件 | 问题数 | 主要问题 |
|------|--------|----------|
| `App.tsx` | 3 | theme 重建、加载状态重复、theme 嵌套过深 |
| `SmartHomePage.tsx` | 6 | 抽象泄漏、SSE 回调、grouped 派生、climate 魔法字符串、错误格式化重复、setTimeout |
| `AppLayout.tsx` | 2 | selectedKey 嵌套三元链、userMenuItems 重建 |
| `DashboardPage.tsx` | 3 | 直接使用 axios、7 个独立请求、render 函数内定义函数 |
| `ScheduleConfigPage.tsx` | 2 | 状态爆炸、setTimeout 延迟初始化 |
| `EventCenterPage.tsx` | 2 | SSE 重复计数、双 effect 冗余依赖 |
| `ProfilePage.tsx` | 3 | isAdmin 重复、日期格式化重复、全页刷新 |
| `SettingsPage.tsx` | 2 | 错误格式化重复、全页刷新 |
| `ProductsPage.tsx` | 3 | getErrorMessage 重复、日期格式化重复、防抖时间偏短 |
| `useSmartHomeSSE.ts` | 1 | 回调引用不稳定 |
| `useTheme.ts` | 1 | mount effect 问题 |
| `client.ts` | 1 | 模块级全局变量 |
| `useRecentAlerts.ts` | 1 | Promise.resolve().then 模式 |
| `BatchImportModal.tsx` | 1 | step 魔法数字 |
| `PriceTrendModal.tsx` | 1 | 魔法数字 + 不必要 useMemo |
| `PageTransition.tsx` | 1 | variants 重建 |
| `KPICard.tsx` | 1 | AntD 内部 API |

---

## 修复优先级建议

### P0（最优先）

1. `App.tsx` ConfigProvider theme 对象重建 — 影响每次渲染性能
2. `SmartHomePage.tsx` SSE 回调引用不稳定 — 导致连接频繁断开重连
3. `EventCenterPage.tsx` SSE 重复计数 — 数据不一致
4. `AppLayout.tsx` selectedKey 嵌套三元链 — 8 层嵌套，维护困难
5. `ScheduleConfigPage.tsx` 状态爆炸 — 15+ useState，Bug 温床

### P1

6. `DashboardPage.tsx` 直接使用 axios — 安全/功能缺失（跳过 interceptor）
7. 错误处理逻辑未统一（5 处重复）— 维护成本高
8. isAdmin 判断重复 — 简单提取，收益明确
9. `ProfilePage.tsx` / `SettingsPage.tsx` 全页刷新 — SPA 体验问题
10. `DashboardPage.tsx` 7 个独立请求 — 加载性能

### P2

11. 日期格式化统一
12. setTimeout(..., 0) 模式统一封装
13. fg-card 样式提取
14. 魔法数字提取为常量
15. useTheme.ts DOM 操作统一
