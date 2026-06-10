# SSE 实时通道：Dashboard / Events / Smart Home 三条流为什么分开

> 解释**为什么**有三条 SSE 通道，以及它们各自推送什么。
> 适用：所有要碰前端实时刷新的人。

## 一句话

> **三条 SSE 通道各自独立、互不耦合**，因为它们的**消费方、刷新频率、权限粒度**都不同。

| 通道          | 路径                                     | 消费方                      | 推送频率                            | 权限              |
| ------------- | ---------------------------------------- | --------------------------- | ----------------------------------- | ----------------- |
| Dashboard KPI | `GET /api/v1/dashboard/events`           | `DashboardPage` 顶部 KPI 卡 | 价格 / 告警变更时                   | 任何已登录        |
| Event Center  | `GET /api/v1/events/stream`              | `EventCenterPage` 全表      | 任何 audit / system / platform 事件 | 任何已登录        |
| Smart Home    | `GET /api/v1/smart-home/entities/stream` | `SmartHomePage` 实体卡片    | HA 推送的状态变更（毫秒级）         | `smart_home:read` |

## 为什么三条而不是一条

- **权限不同**：Event Center 任何登录用户都能看，Smart Home 要 `smart_home:read`。一条流无法差异化鉴权。
- **节流不同**：Dashboard KPI 关心「最近一次变化」，Event Center 关心「所有事件」；合并后没法独立 backpressure。
- **前端消费不同**：Smart Home 走 HA 自己的 WebSocket → 我们的 SSE 中转；KPI 走后端聚合；Event Center 走 `system_log` 表。**三套数据源**不能合并到一个发送器。
- **失败隔离**：一条流崩了不会拖死其他。

## 通用机制

### 服务端

```python
# app/core/event_stream.py  (示意)
class SSEManager:
    def __init__(self):
        self._subscribers: dict[str, set[asyncio.Queue]] = defaultdict(set)

    async def publish(self, channel: str, event: dict):
        for q in self._subscribers[channel]:
            await q.put(event)

    async def subscribe(self, channel: str) -> AsyncIterator[dict]:
        q = asyncio.Queue(maxsize=100)
        self._subscribers[channel].add(q)
        try:
            while True:
                yield await q.get()
        finally:
            self._subscribers[channel].discard(q)
```

每个 HTTP 请求独立订阅一个 `asyncio.Queue`，连接断开时清理。

### 客户端

```typescript
const es = new EventSource("/api/v1/dashboard/events", {
  withCredentials: true,
});
es.onmessage = (e) => {
  const data = JSON.parse(e.data);
  // 局部 setState，不重渲染整个页面
};
```

`EventSource` 自动重连，**不用**手动 reconnect。

## 三条通道细节

### 1. Dashboard KPI

**推送**：

```json
{
  "type": "kpi_update",
  "data": {
    "active_products": 42,
    "active_jobs": 8,
    "today_alerts": 3,
    "last_crawl_at": "2026-06-10T08:00:00Z"
  }
}
```

**触发**：

- 商品价格历史写入后
- 告警触发后
- 爬虫任务状态变化后
- 频率：分钟级（聚合后推）

**前端**：

- `useDashboardSSE` 维护一个 `Map<cardId, value>`
- 收到增量 → `qc.setQueryData('dashboard-kpi', ...)` React Query 内部触发组件 re-render

### 2. Event Center

**推送**：

```json
{
  "id": 12345,
  "level": "warning",
  "category": "crawl",
  "message": "Boss profile cookie refresh exceeded threshold",
  "details": { "***REDACTED***": "..." },
  "created_at": "2026-06-10T08:00:00Z"
}
```

**触发**：

- 任何写 `system_logs` 或 `users_audit_logs` 的代码路径

**前端**：

- 全表 list 增量追加
- 抽屉详情：点开再 GET 详情

### 3. Smart Home

**推送**：

```json
{
  "entity_id": "light.living_room",
  "state": "on",
  "attributes": { "brightness": 255, "color_temp": 300 },
  "last_changed": "2026-06-10T08:00:00Z"
}
```

**触发**：

- HA 通过 WebSocket 推 `state_changed` 事件
- 后端订阅 HA WebSocket → 转成 SSE

**前端**：

- 实体卡片立即反映状态变化
- 不需要 GET 详情

## 反压 / 限流

| 通道          | 反压策略                              |
| ------------- | ------------------------------------- |
| Dashboard KPI | 60s 至少一次（聚合窗口）              |
| Event Center  | 全量推，前端 list 限 1000 条          |
| Smart Home    | 同一 entity_id 100ms 合并（前端去重） |

为什么 Smart Home 不在后端去重：

- 后端不知道前端关心哪些 entity
- HA 推送频率高（设备状态变化、传感器数据），后端去重会丢关键事件
- 100ms 合并在前端用 `useRef<Set<entityId>>` 即可，开销低

## 鉴权

SSE 是 `GET` 请求，**不带 body**。后端用普通 `Depends(get_current_user)` 鉴权即可。

CSRF 不用（SSE 是 GET）。

跨域：SSE 用 `EventSource` 不支持自定义 header，所以 `withCredentials: true` 是唯一带 cookie 方式。**CORS 必须 `Access-Control-Allow-Credentials: true`** + 显式 origin。

## 重连

`EventSource` 自动重连，**但重连后不会重放历史**。所以：

- 短暂断开（< 30s）→ 没事，前端本地状态还在
- 长断开 → 前端调一次 REST `GET /events?since=<last_id>` 拉增量

这条逻辑在 `useDashboardSSE` / `useSmartHomeSSE` 内。

## 失败兜底

| 现象                               | 原因                           | 修复                               |
| ---------------------------------- | ------------------------------ | ---------------------------------- |
| SSE 连接一直断开                   | 反向代理超时（nginx 默认 60s） | 配 `proxy_read_timeout 3600s`      |
| 浏览器 DevTools 看不到 EventSource | HTTPS 下 Mixed Content         | 全站 HTTPS                         |
| 重连风暴                           | 后端崩了                       | 后端起得来就能恢复，前端限重连间隔 |

## 详见

- [tutorial-smart-home](tutorial-smart-home.md) — Smart Home SSE 的实际用法
- [reference-api-products](reference-api-products.md) § Dashboard
- [explanation-auth-rbac](explanation-auth-rbac.md) — 为什么 SSE 是 GET 鉴权简单
