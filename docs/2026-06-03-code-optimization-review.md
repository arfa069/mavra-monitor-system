# 代码优化与质量审查计划

**日期：** 2026-06-03  
**状态：** 已归档与提议中

本文档整理了针对 **前端 (React/TypeScript)** 和 **后端 (FastAPI/Python)** 代码库中发现的优化项、反模式、潜在的并发拦截器 Bug 以及代码坏味道。提供了具体的优化背景、代码痛点及相应的解决方案，作为接下来代码重构的指导蓝图。

---

## 1. 前端优化项 (React/TypeScript)

### A. 拦截器并发 401 刷新重试 Bug (正确性与反模式)
* **目标文件：** [`frontend/src/shared/api/client.ts`](file:///C:/Users/arfac/Documents/mavra-monitor-system/frontend/src/shared/api/client.ts)
* **问题描述：** 
  在当前的 Token 自动刷新机制中，当有多个请求同时失效触发 401 错误时，它们都会被推入 `failedQueue` 队列等待刷新完毕。但在刷新成功后的重试循环中，所有排队请求都使用了*触发刷新*的那一个请求配置 (`originalRequest`) 进行重新请求：
  ```typescript
  failedQueue.forEach(({ resolve, reject }) => {
    api(originalRequest).then(resolve).catch(reject);
  });
  ```
  这会导致其他被挂起的独立请求（如不同的接口 URL、参数或提交数据）的具体配置完全被丢弃，反而把同一个触发刷新的请求重复发送了 $N$ 次。
* **优化与解决方案：**
  修改 `failedQueue` 的数据类型，将每个被挂起请求的独立 `config` 显式保存下来，并在重试时传入各自的配置：
  ```typescript
  interface FailedRequest {
    resolve: (value: unknown) => void;
    reject: (reason: unknown) => void;
    config: AxiosError["config"];
  }
  
  // 拦截器内部挂起请求时
  if (isRefreshing) {
    return new Promise((resolve, reject) => {
      failedQueue.push({ resolve, reject, config: originalRequest });
    });
  }
  
  // 刷新成功重新执行队列时
  failedQueue.forEach(({ resolve, reject, config }) => {
    api(config).then(resolve).catch(reject);
  });
  ```

### B. Auth 上下文方法的引用不稳定 (性能优化)
* **目标文件：** [`frontend/src/shared/contexts/AuthContext.tsx`](file:///C:/Users/arfac/Documents/mavra-monitor-system/frontend/src/shared/contexts/AuthContext.tsx)
* **问题描述：** 
  在 `AuthProvider` 组件内部定义的鉴权相关辅助方法（`login`、`logout`、`hasPermission`、`hasAnyPermission`、`hasAllPermissions`）由于没有使用 `useCallback` 进行包裹缓存，导致在组件每次发生渲染时都会创建新的引用。这会破坏上下文对象的引用一致性，触发所有消费了该上下文的子组件或 Hook 进行不必要的重新渲染。
* **优化与解决方案：**
  使用 `useCallback` 包裹缓存这些方法，并合理声明它们的依赖项：
  ```typescript
  const login = useCallback((userData: User) => {
    setUser(userData);
  }, []);

  const logout = useCallback(async () => {
    try {
      await authApi.logout();
    } catch {
      // 容错处理
    }
    setUser(null);
  }, []);

  const hasPermission = useCallback((permission: Permission) =>
    Boolean(user?.permissions?.includes(permission)), [user]);
  ```

### C. 组件内声明内联静态配置 (性能优化)
* **目标文件：** [`frontend/src/features/jobs/components/JobConfigForm.tsx`](file:///C:/Users/arfac/Documents/mavra-monitor-system/frontend/src/features/jobs/components/JobConfigForm.tsx)
* **问题描述：**
  表单中用到的 `urlConfigMap` 静态映射配置定义在 `JobConfigForm` 组件的内部：
  ```typescript
  const urlConfigMap = {
    boss: { ... },
    "51job": { ... },
    liepin: { ... },
  } as const;
  ```
  这导致了组件每次被调用重新渲染时，都在堆内存中重新为该配置项进行内存分配，产生额外的垃圾回收开销。
* **优化与解决方案：**
  将 `urlConfigMap` 移动到组件函数外部，定义为模块顶级常数。

---

## 2. 后端优化项 (FastAPI/Python)

### A. 冗余的身份验证和鉴权判断 (代码整洁)
* **目标文件：**
  - [`backend/app/domains/alerts/router.py`](file:///C:/Users/arfac/Documents/mavra-monitor-system/backend/app/domains/alerts/router.py)
  - [`backend/app/domains/crawling/router.py`](file:///C:/Users/arfac/Documents/mavra-monitor-system/backend/app/domains/crawling/router.py)
  - [`backend/app/domains/jobs/router.py`](file:///C:/Users/arfac/Documents/mavra-monitor-system/backend/app/domains/jobs/router.py)
  - [`backend/app/domains/products/router.py`](file:///C:/Users/arfac/Documents/mavra-monitor-system/backend/app/domains/products/router.py)
* **问题描述：**
  多个 API 路由端点在通过 `current_user: User = Depends(get_current_user)` 获取当前用户后，都紧跟了类似如下的代码：
  ```python
  if not current_user:
      raise HTTPException(status_code=401, detail="请先登录")
  ```
  实际上，`Depends(get_current_user)` 依赖注入在检测到 Token 无效或用户不存在时，已在内部直接抛出 HTTP 401 异常终止请求流，保证了凡是能够进入端点内部的 `current_user` 变量绝不可能为 `None`。因此，端点函数里的这几行判断属于冗余死代码。
* **优化与解决方案：**
  删除所有端点函数内不必要的 `if not current_user` 判断，直接安全地调用 `current_user`。

### B. 允许跨域源的硬编码 (配置解耦与最佳实践)
* **目标文件：** [`backend/app/main.py`](file:///C:/Users/arfac/Documents/mavra-monitor-system/backend/app/main.py)
* **问题描述：**
  用于 CORS 跨域中间件的 `_ALLOWED_ORIGINS` 域列表直接硬编码写死在 `main.py` 中：
  ```python
  _ALLOWED_ORIGINS = [
      "http://localhost:3000",
      "http://127.0.0.1:3000",
  ]
  ```
  这为后续将前后端容器化部署或者跨局域网多环境联调带来了麻烦，每次变更都必须修改代码。
* **优化与解决方案：**
  在配置系统 `backend/app/config.py` 中添加 `allowed_origins` 配置字段：
  ```python
  allowed_origins: list[str] = ["http://localhost:3000", "http://127.0.0.1:3000"]
  ```
  并在 `main.py` 启动逻辑里加载该配置：
  ```python
  app.add_middleware(
      CORSMiddleware,
      allow_origins=settings.allowed_origins,
      ...
  )
  ```

### C. 顺序爬取性能瓶颈 (并发与性能优化)
* **目标文件：** [`backend/app/domains/crawling/task_runner.py`](file:///C:/Users/arfac/Documents/mavra-monitor-system/backend/app/domains/crawling/task_runner.py)
* **问题描述：**
  多商品爬取任务（如按平台爬取或全网批量更新商品价格）在后端当前是以顺序遍历的方式来执行的：
  ```python
  for product in products:
      result = await crawling_service.crawl_one_opencli(...)
  ```
  由于单次 OpenCLI 调用（执行 CDP 浏览器加载、重定向校验等防反爬策略）需要耗费 10 到 20 秒左右，如果待爬取商品较多（例如几十个），采用串行循环会使整个定时任务或手动 Crawl Task 长时间挂起甚至超出进程的最大执行限时。
* **优化与解决方案：**
  采用并发限流方案，使用 `asyncio.Semaphore` 信号量来控制安全上限的并发运行，同时配合 `asyncio.gather` 并行发出爬虫请求，既大幅压缩整体耗时，又防止因瞬间请求过多引发防反爬封禁：
  ```python
  sem = asyncio.Semaphore(3)  # 控制最多同时存在3个并发浏览器爬虫
  
  async def crawl_with_semaphore(prod):
      async with sem:
          return await crawling_service.crawl_one_opencli(
              product_id=prod.id, platform=prod.platform
          )
          
  results = await asyncio.gather(*(crawl_with_semaphore(p) for p in products), return_exceptions=True)
  ```

### D. Playwright 无头模式参数的硬编码 (配置解耦与调试便利性)
* **目标文件：** [`backend/app/domains/crawling/browser_manager.py`](file:///C:/Users/arfac/Documents/mavra-monitor-system/backend/app/domains/crawling/browser_manager.py)
* **问题描述：**
  浏览器页面管理器在调用持久化浏览器上下文时硬编码了 `headless=True`。这导致开发人员在本地进行端对端反爬逻辑测试、验证 Cookie 有效性时，无法将其关闭以实时观看浏览器自动化的行为表现。
* **优化与解决方案：**
  在配置系统 `Settings` (`config.py`) 中加入 `crawler_headless: bool = True` 配置参数，并将硬编码替换为：
  ```python
  headless=settings.crawler_headless
  ```
