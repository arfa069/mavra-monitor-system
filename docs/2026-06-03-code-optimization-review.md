# 代码优化与质量审查计划

**日期：** 2026-06-03
**状态：** 已审查，首批建议已实施
**审查结论：** 本文档列出的优化点大多与当前源码一致，但不同事项的风险和收益差异很大。应优先修复正确性问题，再处理配置解耦和低风险清理；产品爬取并发属于中风险重构，不能按简单 `asyncio.gather` 直接落地。

本文档整理了针对 **前端 (React/TypeScript)** 和 **后端 (FastAPI/Python)** 代码库中发现的优化项、反模式、潜在的并发拦截器 Bug 以及代码坏味道。每项均补充优先级、实施风险和建议验证方式，作为后续重构蓝图。

## 实施记录

2026-06-03 首批实施完成：前端 401 refresh 队列保存各自请求 config 且标记 `_retry`；AuthContext callbacks 和 Provider value 已 memoized；`urlConfigMap` 移到模块级；冗余 `current_user` 判断已清理；CORS、crawler headless、product crawl concurrency 已配置化并补充定向测试。

## 优先级总览

| 优先级 | 项目 | 性质 | 建议处理方式 |
| --- | --- | --- | --- |
| P0 | 前端 401 刷新队列重试 Bug | 正确性 Bug | 立即修复并补单元/集成测试 |
| P1 | AuthContext value 引用不稳定 | 性能/渲染控制 | 小范围修复，补渲染或 hook 行为验证 |
| P2 | CORS allowed origins 硬编码 | 配置解耦 | 配置化并补 settings 解析测试 |
| P2 | Playwright headless 硬编码 | 调试便利性 | 配置化并补默认值测试 |
| P2 | 冗余 `current_user` 判断 | 代码整洁 | 分批删除，跑后端路由测试 |
| P2/P3 | 产品爬取串行执行 | 性能/架构 | 先设计并发策略，再实施 |
| P3 | `urlConfigMap` 组件内静态对象 | 微优化 | 顺手处理即可 |

---

## 1. 前端优化项 (React/TypeScript)

### A. 拦截器并发 401 刷新重试 Bug (正确性与反模式)

* **目标文件：** [`../frontend/src/shared/api/client.ts`](../frontend/src/shared/api/client.ts)
* **优先级：** P0
* **风险等级：** 中。触碰全局 API 客户端，会影响所有鉴权请求。

#### 问题描述

在当前的 Token 自动刷新机制中，当多个请求同时失效触发 401 错误时，只有第一个请求会启动 refresh，其余请求会被推入 `failedQueue`。但当前队列只保存 `resolve/reject`，没有保存各自的请求配置：

```typescript
failedQueue.push({ resolve, reject });
```

刷新成功后的重试循环会把所有排队请求都用触发 refresh 的那个 `originalRequest` 重新发送：

```typescript
failedQueue.forEach(({ resolve, reject }) => {
  api(originalRequest).then(resolve).catch(reject);
});
```

这会导致其他被挂起的独立请求，例如不同 URL、参数、请求体，被错误替换成同一个请求，实际表现为同一个接口被重复发送 N 次。

#### 解决方案

保存每个排队请求自己的 config，并在刷新成功后按各自 config 重试。排队前也应标记 `_retry = true`，避免刷新后同一请求再次 401 时形成二次 refresh 风暴。

```typescript
import type { InternalAxiosRequestConfig } from "axios";

type RetryableConfig = InternalAxiosRequestConfig & { _retry?: boolean };

interface FailedRequest {
  resolve: (value: unknown) => void;
  reject: (reason: unknown) => void;
  config: RetryableConfig;
}

let failedQueue: FailedRequest[] = [];

// 在响应拦截器内先保护 err.config
if (!err.config) {
  return Promise.reject(err);
}

const originalRequest = err.config as RetryableConfig;

if (isRefreshing) {
  originalRequest._retry = true;
  return new Promise((resolve, reject) => {
    failedQueue.push({ resolve, reject, config: originalRequest });
  });
}

// 刷新成功后
failedQueue.forEach(({ resolve, reject, config }) => {
  api(config).then(resolve).catch(reject);
});
failedQueue = [];
```

#### 验证建议

* 补一个 API client 单元测试：并发发出 `/a`、`/b`、`/c` 三个请求，均先返回 401，refresh 成功后确认分别重试原始 URL。
* 覆盖 refresh 失败路径：所有 queued promise 都 reject，且跳转登录页逻辑只触发一次。
* 运行前端 lint/build：`npm run lint`、`npm run build`。

---

### B. Auth 上下文方法和 value 引用不稳定 (性能优化)

* **目标文件：** [`../frontend/src/shared/contexts/AuthContext.tsx`](../frontend/src/shared/contexts/AuthContext.tsx)
* **优先级：** P1
* **风险等级：** 低。主要影响上下文值引用，不应改变业务行为。

#### 问题描述

`AuthProvider` 内部定义的 `login`、`logout`、`hasPermission`、`hasAnyPermission`、`hasAllPermissions` 每次渲染都会创建新函数。同时 Provider 的 `value={{ ... }}` 也会在每次渲染创建新对象，导致所有消费 `AuthContext` 的组件更容易发生不必要的重渲染。

仅给方法加 `useCallback` 不完整；必须同时用 `useMemo` 缓存整个 context value。

#### 解决方案

```typescript
const login = useCallback((userData: User) => {
  setUser(userData);
}, []);

const logout = useCallback(async () => {
  try {
    await authApi.logout();
  } catch {
    // Best-effort: cookies cleared server-side
  }
  setUser(null);
}, []);

const hasPermission = useCallback(
  (permission: Permission) => Boolean(user?.permissions?.includes(permission)),
  [user?.permissions]
);

const hasAnyPermission = useCallback(
  (permissions: Permission[]) => permissions.some((permission) => hasPermission(permission)),
  [hasPermission]
);

const hasAllPermissions = useCallback(
  (permissions: Permission[]) => permissions.every((permission) => hasPermission(permission)),
  [hasPermission]
);

const value = useMemo(
  () => ({
    user,
    isLoading,
    isAuthenticated: Boolean(user),
    login,
    logout,
    hasPermission,
    hasAnyPermission,
    hasAllPermissions,
  }),
  [
    user,
    isLoading,
    login,
    logout,
    hasPermission,
    hasAnyPermission,
    hasAllPermissions,
  ]
);
```

Provider 使用 `value={value}`。

#### 验证建议

* 运行 `npm run lint` 和 `npm run build`。
* 若已有 React 测试设施，可补一个轻量测试确认 login/logout 权限判断行为不变。

---

### C. 组件内声明内联静态配置 (微优化)

* **目标文件：** [`../frontend/src/features/jobs/components/JobConfigForm.tsx`](../frontend/src/features/jobs/components/JobConfigForm.tsx)
* **优先级：** P3
* **风险等级：** 极低。

#### 问题描述

`urlConfigMap` 是静态映射，但定义在 `JobConfigForm` 组件内部：

```typescript
const urlConfigMap = {
  boss: { ... },
  "51job": { ... },
  liepin: { ... },
} as const;
```

每次组件渲染都会重新创建该对象。该问题影响很小，但移动到模块顶层能减少无意义分配，也让配置意图更清晰。

#### 解决方案

将 `urlConfigMap` 移到组件外部，例如：

```typescript
const URL_CONFIG_MAP = {
  boss: {
    label: "Boss Search URL",
    placeholder: "https://www.zhipin.com/web/geek/job?query=frontend",
  },
  "51job": {
    label: "51job Search URL",
    placeholder: "https://we.51job.com/pc/search?keyword=python&searchType=2",
  },
  liepin: {
    label: "Liepin Search URL",
    placeholder: "https://www.liepin.com/zhaopin/?key=python&dqs=020&currentPage=0",
  },
} as const;
```

#### 验证建议

* 运行 `npm run lint` 和 `npm run build`。
* 手动确认新增/编辑职位配置时，平台切换后的 URL placeholder 仍正确。

---

## 2. 后端优化项 (FastAPI/Python)

### A. 冗余的身份验证判断 (代码整洁)

* **目标文件：**
  * [`../backend/app/domains/alerts/router.py`](../backend/app/domains/alerts/router.py)
  * [`../backend/app/domains/crawling/router.py`](../backend/app/domains/crawling/router.py)
  * [`../backend/app/domains/jobs/router.py`](../backend/app/domains/jobs/router.py)
  * [`../backend/app/domains/products/router.py`](../backend/app/domains/products/router.py)
* **优先级：** P2
* **风险等级：** 低到中。逻辑本身是死代码清理，但涉及路由较多，建议分批改。

#### 问题描述

多个 API 路由端点通过 `current_user: User = Depends(get_current_user)` 获取当前用户后，仍重复执行：

```python
if not current_user:
    raise HTTPException(status_code=401, detail="请先登录")
```

`get_current_user` 的返回类型是 `User`，并且在凭证缺失、token 无效、用户不存在、会话失效时会直接抛出 `HTTPException(401)`。因此能进入端点函数体时，`current_user` 不应为 `None`。

#### 解决方案

删除端点中的重复 `if not current_user`。如需保留语义，可引入统一依赖或 helper，但不要在每个端点重复写死判断。

需要注意：`products/router.py` 中存在 `_require_user(current_user: User | None) -> User` helper。如果所有调用方都已经使用 `Depends(get_current_user)`，也可考虑删除或收窄类型；如果有其他可选鉴权入口，则不要机械删除。

#### 验证建议

* 跑相关后端测试：`pytest backend/tests/test_alerts.py backend/tests/test_jobs_api.py backend/tests/test_api.py -q`。
* 至少覆盖未登录请求仍返回 401。

---

### B. 允许跨域源的硬编码 (配置解耦)

* **目标文件：** [`../backend/app/main.py`](../backend/app/main.py)、[`../backend/app/config.py`](../backend/app/config.py)
* **优先级：** P2
* **风险等级：** 低。注意环境变量解析格式。

#### 问题描述

CORS 中间件的 `_ALLOWED_ORIGINS` 在 `main.py` 中硬编码：

```python
_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
]
```

这会让容器化部署、局域网联调、多环境域名配置都必须改代码。

#### 解决方案

在 `Settings` 中增加配置项，并在 `main.py` 使用 `settings.allowed_origins`。

```python
allowed_origins: list[str] = ["http://localhost:3000", "http://127.0.0.1:3000"]
```

建议同时增加 validator，支持 JSON list 和逗号分隔两种环境变量写法，降低部署出错概率：

```python
@field_validator("allowed_origins", mode="before")
@classmethod
def parse_allowed_origins(cls, value):
    if isinstance(value, str):
        stripped = value.strip()
        if stripped.startswith("["):
            return value
        return [item.strip() for item in stripped.split(",") if item.strip()]
    return value
```

#### 验证建议

* 补 Settings 解析测试：默认值、JSON list、逗号分隔字符串。
* 跑后端基础测试和启动 smoke test。

---

### C. 顺序爬取性能瓶颈 (并发与架构)

* **目标文件：** [`../backend/app/domains/crawling/task_runner.py`](../backend/app/domains/crawling/task_runner.py)
* **优先级：** P2/P3
* **风险等级：** 中到高。涉及 worker、任务租约、OpenCLI/浏览器资源和反爬策略。

#### 问题描述

`run_products_by_platform` 和 `run_all_products` 当前都按顺序遍历商品：

```python
for product in products:
    result = await crawling_service.crawl_one_opencli(
        product_id=product.id, platform=product.platform
    )
```

如果单个 OpenCLI 调用耗时 10 到 20 秒，几十个商品会导致任务长时间运行。

#### 审查修正

原始建议使用 `asyncio.Semaphore + asyncio.gather` 的方向可以作为候选方案，但不应直接落地为局部改动。当前产品爬取已经接入持久化 `crawl_tasks` 和 crawler worker。runner 内部再并发会与 worker 层并发叠加，可能导致：

* 同一进程同时打开过多浏览器或 OpenCLI 子进程。
* 任务 heartbeat/lease 续期时间被拉长或进度持久化不及时。
* 单个平台并发访问过高，引发防反爬、封禁或 Cookie/Profile 争用。
* `details` 顺序、异常聚合和部分成功语义变复杂。

#### 建议方案

先做一个小设计，再实施。可选路线：

1. **worker 层并发优先**：把批量产品拆成多个 child crawl task，由 worker 池控制并发。这更符合现有任务系统。
2. **runner 层限流并发**：仅在确认 OpenCLI 和浏览器资源可承受时使用，并新增配置项，例如 `product_crawl_concurrency: int = 1`，默认保持串行。
3. **按平台/用户限流**：不同平台可配置不同并发，避免反爬策略一刀切。

如果先做 runner 层方案，至少应做到：

```python
sem = asyncio.Semaphore(settings.product_crawl_concurrency)

async def crawl_with_limit(product):
    async with sem:
        try:
            return await crawling_service.crawl_one_opencli(
                product_id=product.id,
                platform=product.platform,
            )
        except Exception as exc:
            return {
                "product_id": product.id,
                "status": "error",
                "reason": str(exc),
                "platform": product.platform,
            }

results = await asyncio.gather(*(crawl_with_limit(product) for product in products))
```

默认并发建议为 `1` 或 `2`，不要直接写死为 `3`。

#### 验证建议

* 补 `task_runner` 单元测试：全部成功、部分失败、全部失败、并发上限生效。
* 补 worker 租约/heartbeat 相关测试，确认长任务仍能续期。
* 手动压测小批量商品，观察 OpenCLI 进程数、浏览器资源、失败率和耗时。

---

### D. Playwright 无头模式参数硬编码 (配置解耦)

* **目标文件：** [`../backend/app/domains/crawling/browser_manager.py`](../backend/app/domains/crawling/browser_manager.py)、[`../backend/app/config.py`](../backend/app/config.py)
* **优先级：** P2
* **风险等级：** 低。

#### 问题描述

浏览器页面管理器调用持久化浏览器上下文时硬编码了 `headless=True`：

```python
context = await playwright.chromium.launch_persistent_context(
    str(profile_dir),
    headless=True,
    args=["--disable-blink-features=AutomationControlled"],
)
```

这导致本地调试 Cookie、登录态和反爬页面行为时无法切换为可视模式。

#### 解决方案

在配置系统中加入：

```python
crawler_headless: bool = True
```

并替换为：

```python
headless=settings.crawler_headless
```

#### 验证建议

* 补默认配置测试，确认未设置环境变量时仍为 headless。
* 手动设置 `CRAWLER_HEADLESS=false` 启动本地爬虫流程，确认浏览器可视化打开。

---

## 3. 实施顺序建议

1. **先修 P0：** 前端 401 refresh 队列 bug。该项是正确性问题，收益最高。
2. **再做低风险配置与清理：** AuthContext、CORS、crawler headless、冗余 `current_user` 判断。
3. **最后单独设计产品爬取并发：** 不建议和普通清理项混在一个 PR 中。
4. **`urlConfigMap` 微优化可与 JobConfigForm 相关改动顺手处理。**

## 4. 完成标准

每个实施 PR 至少应包含：

* 对应代码改动。
* 定向测试或构建/lint 结果。
* 对无法自动化验证的浏览器/爬虫行为给出手动验证记录。
* 不混入无关格式化或大面积重排，方便审查。
