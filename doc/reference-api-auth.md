# 认证 / Admin API 参考

> 完整端点签名、Cookie / CSRF 流程、强密码策略、错误码。

## 通用约定

| 项            | 值                                                                        |
| ------------- | ------------------------------------------------------------------------- |
| 路由前缀      | `/api/v1`（业务）、`/auth/*`（无前缀，迁移期兼容）                        |
| 认证方式      | Cookie-first，HttpOnly；脚本可用 `Authorization: Bearer <access_token>`   |
| 不安全方法    | `POST` / `PATCH` / `PUT` / `DELETE` 必须带 `X-CSRF-Token` 头              |
| Access JWT    | 15 分钟，HS256，存于 `pm_access_token`                                    |
| Refresh Token | 14 天，opaque token，DB 存 `users_sessions.refresh_token_hash`（SHA-256） |
| 强密码        | ≥10 位、含大小写数字特殊字符（同步用于注册 / 改密 / 微信绑定）            |
| 登录锁定      | 5 次失败 → 锁 15 分钟（Redis 计数）                                       |
| 会话上限      | 每用户 5 个活跃 session                                                   |
| 软删除        | `users.deleted_at IS NOT NULL` → 拒绝所有 `get_current_user`              |

---

## 认证端点

### `POST /api/v1/auth/register`

**权限**：公开

**请求体**

| 字段       | 类型   | 必填 | 校验      |
| ---------- | ------ | ---- | --------- |
| `username` | string | ✅   | 3-50 字符 |
| `email`    | string | ✅   | RFC 5322  |
| `password` | string | ✅   | 强密码    |

**响应**（201）：User JSON（不含 `hashed_password`）

副作用：

- `users` 表新增
- 角色默认 `user`（系统表里 seed 的）

### `POST /api/v1/auth/login`

**权限**：公开（5 次失败锁 15 分钟）

**请求体**

```json
{ "username": "bob", "password": "BobPass1234!" }
```

**响应**（200）：

```json
{
  "id": 1,
  "username": "bob",
  "email": "bob@example.com",
  "role": "user",
  "permissions": ["product:read", "product:write", ...],
  "is_active": true
}
```

副作用（`Set-Cookie` 头）：

| Cookie             | HttpOnly | SameSite | 寿命  | 用途                    |
| ------------------ | -------- | -------- | ----- | ----------------------- |
| `pm_access_token`  | ✅       | Lax      | 15min | JWT                     |
| `pm_refresh_token` | ✅       | Lax      | 14d   | Opaque，DB 存哈希       |
| `pm_csrf_token`    | ❌       | Lax      | 14d   | 必须原样回 X-CSRF-Token |

### `POST /api/v1/auth/refresh`

**权限**：依赖 `pm_refresh_token` Cookie

**响应**（200）：新的 User JSON + **轮换后的** 三 Cookie。

**注意**：refresh 后旧 refresh token **立即失效**（rotated）。

### `POST /api/v1/auth/logout`

**权限**：已登录 + CSRF

清三类 Cookie + DB 软删 session。

### `GET /api/v1/auth/me`

返回当前 User JSON，含完整 `permissions[]`。

### `PATCH /api/v1/auth/me`

更新 `email` / 用户偏好（非密码）。

### `POST /api/v1/auth/me/password`

**请求体**：

```json
{ "current_password": "...", "new_password": "..." }
```

新密码走强密码校验。

### `GET /api/v1/auth/sessions`

列出当前用户的活跃 session（5 个上限）。

### `DELETE /api/v1/auth/sessions/{id}`

撤销指定 session（不能撤销自己当前 session 的最后一个，否则会要求重新登录）。

### `GET /api/v1/auth/me/login-history`

最近 N 条登录记录（含 IP / 设备 / 成功失败）。

---

## 微信 OAuth（可选）

启用条件：`WECHAT_LOGIN_ENABLED=true`（`.env` 配 `WECHAT_APP_ID` / `WECHAT_APP_SECRET`）。

| 方法 | 端点                    | 说明                    |
| ---- | ----------------------- | ----------------------- |
| GET  | `/auth/wechat/qr`       | 生成二维码 + state      |
| GET  | `/auth/wechat/callback` | 微信回调后重定向前端    |
| POST | `/auth/wechat/bind`     | 用临时 token 绑定已有账号 |
| POST | `/auth/wechat/register` | 用微信 + 强密码创建账号 |

补充约定：

- `GET /api/v1/auth/wechat/qr` 支持可选 `next` 参数，但只接受站内相对路径；非法值会回退到 `/today`。
- `GET /api/v1/auth/wechat/callback` 不再直接给浏览器返回最终登录 JSON。
- 已绑定用户：后端写入认证 Cookie 后，302 跳转到 `/auth/wechat/callback?status=success&next=...`。
- 未绑定用户：302 跳转到 `/auth/wechat/callback?status=unbound&next=...#temp_token=...`。
- 错误场景：302 跳转到 `/auth/wechat/callback?status=error&reason=...`。
- `temp_token` 只用于当前绑定/注册流程，不落盘，不写入 `localStorage` / `sessionStorage`，也不通过 query 传播。

---

## Admin 端点

全部需要 CSRF + RBAC。

### 用户管理

| 方法   | 端点                       | 权限                      |
| ------ | -------------------------- | ------------------------- |
| GET    | `/api/v1/admin/users`      | `user:read`               |
| POST   | `/api/v1/admin/users`      | `user:manage`             |
| GET    | `/api/v1/admin/users/{id}` | `user:read`               |
| PATCH  | `/api/v1/admin/users/{id}` | `user:manage`             |
| DELETE | `/api/v1/admin/users/{id}` | `user:delete`（**软删**） |

`POST /admin/users` body：

```json
{
  "username": "alice",
  "email": "alice@example.com",
  "password": "AlicePass1234!",
  "role": "user" // user / admin；不能创建 super_admin
}
```

### 审计日志

| 方法 | 端点                       | 权限        |
| ---- | -------------------------- | ----------- |
| GET  | `/api/v1/admin/audit-logs` | `user:read` |

查询参数：`actor_id` / `action` / `from` / `to` / `limit` / `cursor`

记录的操作：

```text
user.register, user.create, user.update, user.delete
auth.login, auth.logout, user.password_change
rbac.role_permissions_update
smart_home.config.update, smart_home.entity.control
```

敏感字段（password / token / webhook）经 `app/core/log_redaction.py` 替换为 `***REDACTED***`。

### 资源权限

| 方法   | 端点                                      | 权限          |
| ------ | ----------------------------------------- | ------------- |
| GET    | `/api/v1/admin/resource-permissions`      | `user:read`   |
| POST   | `/api/v1/admin/resource-permissions`      | `user:manage` |
| PATCH  | `/api/v1/admin/resource-permissions/{id}` | `user:manage` |
| DELETE | `/api/v1/admin/resource-permissions/{id}` | `user:manage` |

`POST` body：

```json
{
  "subject_id": 2,
  "resource_type": "product",
  "resource_id": "42",
  "permission": "edit" // read / edit / manage
}
```

`resource_type` ∈ `product` / `job` / `user`

### 角色权限矩阵

| 方法  | 端点                                          | 权限                            |
| ----- | --------------------------------------------- | ------------------------------- |
| GET   | `/api/v1/admin/roles/permissions`             | `rbac:read`                     |
| PATCH | `/api/v1/admin/roles/{role_name}/permissions` | `rbac:manage`（仅 super_admin） |

`PATCH` body：

```json
{
  "add": ["config:read"],
  "remove": ["config:write"]
}
```

`role_name` ∈ `user` / `admin` / `super_admin`

---

## 错误码

完整表见 [`backend/docs/auth-error-codes.md`](../backend/docs/auth-error-codes.md)。

| 状态 | 含义                                      |
| ---- | ----------------------------------------- |
| 400  | 业务校验失败（密码不够强、cron 解析失败） |
| 401  | Cookie 缺失 / 过期 / Refresh 失败         |
| 403  | CSRF 失败 / RBAC 不足 / 跨用户访问        |
| 404  | 资源不存在 / 跨用户                       |
| 409  | 状态冲突（profile lease / 唯一键冲突）    |
| 422  | Pydantic 422（请求体 schema 不匹配）      |
| 429  | 登录失败 5 次锁 15 分钟                   |
| 5xx  | 后端故障                                  |

`detail` 字段兼容两种格式：

- string（业务错误）
- array of `{loc, msg, type}`（Pydantic 422）

前端 `formatApiError()` 在 [client.ts:57](../frontend/src/shared/api/client.ts) 处理两种。

---

## 401 自动刷新细节

前端 `shared/api/client.ts:102-154` 实现：

1. 拦截 401（非 login / me 端点）
2. 标记 `_retry` 防循环
3. 并发请求合并到 `failedQueue`，只发一次 refresh
4. refresh 成功 → 重放队列
5. refresh 失败 → 跳 `/login`

后端不感知。

## 详见

- [howto-rbac](howto-rbac.md) — 任务场景
- [explanation-auth-rbac](explanation-auth-rbac.md) — 三层模型设计取舍
- [doc/permission-architecture.md](permission-architecture.md) — 完整权限矩阵
