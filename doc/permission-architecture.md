# 权限架构

> 最后更新：2026-05-23（project-refactor API v1 / feature 拆分后）

## 概览

价格监控系统使用三层权限模型：**认证 → 数据库 RBAC → 资源级 ACL**，加上**审计日志**作为可追溯性保障。运行时业务权限由 `users_roles`、`users_permissions`、`users_roles_permissions` 三张表作为单一真相来源；`users.role` 保存用户当前角色名。

## 角色

| 角色       | 标识          | 用途                                     |
| ---------- | ------------- | ---------------------------------------- |
| 普通用户   | `user`        | 默认注册角色，可操作自己的商品/职位/爬取 |
| 管理员     | `admin`       | 用户管理、审计日志查看；不能执行爬取     |
| 超级管理员 | `super_admin` | 全部权限，包括调度配置                   |

## 权限矩阵

来源：[`backend/app/core/permissions.py`](../backend/app/core/permissions.py)

| 权限                 | user | admin | super_admin |
| -------------------- | :--: | :---: | :---------: |
| `user:read`          |  ❌  |  ✅   |     ✅      |
| `user:manage`        |  ❌  |  ✅   |     ✅      |
| `user:delete`        |  ❌  |  ✅   |     ✅      |
| `crawl:execute`      |  ✅  |  ❌   |     ✅      |
| `crawl:read_logs`    |  ✅  |  ✅   |     ✅      |
| `schedule:read`      |  ✅  |  ✅   |     ✅      |
| `schedule:configure` |  ❌  |  ❌   |     ✅      |
| `config:read`        |  ❌  |  ✅   |     ✅      |
| `config:write`       |  ✅  |  ✅   |     ✅      |
| `product:read`       |  ❌  |  ❌   |     ✅      |
| `product:write`      |  ❌  |  ❌   |     ✅      |
| `product:delete`     |  ❌  |  ❌   |     ✅      |
| `job:read`           |  ❌  |  ❌   |     ✅      |
| `job:write`          |  ❌  |  ❌   |     ✅      |
| `job:delete`         |  ❌  |  ❌   |     ✅      |
| `rbac:read`          |  ❌  |  ❌   |     ✅      |
| `rbac:manage`        |  ❌  |  ❌   |     ✅      |

## 端点 → 权限映射

除 `/health` 外，前端主调用路径使用 `/api/v1/*`。后端在迁移期仍保留 legacy 路由兼容层；权限语义以 `/api/v1` 主路径为准。

### 认证 (`app.domains.auth.router`)

| 端点                  | 依赖                       |
| --------------------- | -------------------------- |
| `POST /api/v1/auth/register` | 公开                       |
| `POST /api/v1/auth/login`    | 公开（5 次失败锁 15 分钟） |
| `POST /api/v1/auth/logout`   | `get_current_user`         |
| `GET /api/v1/auth/me`        | `get_current_user`         |
| `GET /api/v1/auth/sessions`  | `get_current_user`         |

### 用户管理 (`app.domains.admin.router`)

| 端点                                         | 权限          |
| -------------------------------------------- | ------------- |
| `GET /api/v1/admin/users`                           | `user:read`   |
| `POST /api/v1/admin/users`                          | `user:manage` |
| `GET /api/v1/admin/users/{id}`                      | `user:read`   |
| `PATCH /api/v1/admin/users/{id}`                    | `user:manage` |
| `DELETE /api/v1/admin/users/{id}`                   | `user:delete` |
| `GET /api/v1/admin/audit-logs`                      | `user:read`   |
| `POST /api/v1/admin/resource-permissions`           | `user:manage` |
| `GET /api/v1/admin/resource-permissions`            | `user:read`   |
| `PATCH /api/v1/admin/resource-permissions/{id}`     | `user:manage` |
| `DELETE /api/v1/admin/resource-permissions/{id}`    | `user:manage` |
| `GET /api/v1/admin/roles/permissions`               | `rbac:read`   |
| `PATCH /api/v1/admin/roles/{role_name}/permissions` | `rbac:manage` |

### 商品 (`app.domains.products.router`)

| 端点                                       | 权限                 |
| ------------------------------------------ | -------------------- |
| `/api/v1/products` 商品 CRUD（增删改查）                      | `get_current_user`   |
| `POST /api/v1/products/cron-configs`              | `schedule:configure` |
| `PATCH /api/v1/products/cron-configs/{platform}`  | `schedule:configure` |
| `DELETE /api/v1/products/cron-configs/{platform}` | `schedule:configure` |

### 职位 (`app.domains.jobs.router`)

| 端点                               | 权限                 |
| ---------------------------------- | -------------------- |
| `/api/v1/jobs` 职位/简历/匹配 CRUD                | `get_current_user`   |
| `POST /api/v1/jobs/crawl-now`             | `crawl:execute`      |
| `POST /api/v1/jobs/crawl-now/{config_id}` | `crawl:execute`      |
| `PATCH /api/v1/jobs/configs/{id}/cron`    | `schedule:configure` |

### 爬取 (`app.domains.crawling.router`)

| 端点                    | 权限               |
| ----------------------- | ------------------ |
| `POST /api/v1/crawl/crawl-now` | `crawl:execute`    |
| `POST /api/v1/crawl/cleanup`   | `crawl:execute`    |
| `GET /api/v1/crawl/logs` 等    | `get_current_user` |

### 配置 (`app.domains.config.router`)

| 端点            | 权限           |
| --------------- | -------------- |
| `GET /api/v1/config`   | `config:read`  |
| `POST /api/v1/config`  | `config:write` |
| `PATCH /api/v1/config` | `config:write` |

### 系统 (`main.py` / `app.domains.scheduling.router`)

| 端点                    | 权限                                   |
| ----------------------- | -------------------------------------- |
| `GET /health`                    | 公开（仅返回 status）                  |
| `GET /api/v1/scheduler/status`   | `require_role("admin", "super_admin")` |

## Token 策略

- **算法**: HS256
- **过期**: 60 分钟（常量 `ACCESS_TOKEN_EXPIRE_MINUTES`，登录接口复用此常量）
- **登录失败**: 5 次失败锁 15 分钟（Redis 计数）
- **会话上限**: 每用户最多 5 个活跃 session
- **软删除即时失效**: `get_current_user` 检查 `deleted_at IS NULL`

## 角色边界保护

`admin` 角色不能：

- 创建 `super_admin` 用户
- 修改 `super_admin` 用户
- 删除 `super_admin` 用户

`super_admin` 不能：

- 删除自己
- 删除/禁用最后一个活跃的 `super_admin`

## 审计日志

`users_audit_logs` 表记录所有敏感操作。敏感字段（password / token / webhook_url）会被替换为 `***REDACTED***`。

记录的操作：

- `user.register`, `user.create`, `user.update`, `user.delete`
- `auth.login`, `auth.logout`, `user.password_change`
- `rbac.role_permissions_update`

仅 `user:read` 权限可查询审计日志。

## 前端路由守卫

| 守卫              | 保护范围                                                   | 行为                          |
| ----------------- | ---------------------------------------------------------- | ----------------------------- |
| `ProtectedRoute`  | `/jobs`, `/products`, `/schedule`, `/profile`, `/settings` | 未登录 → `/login`             |
| `PermissionRoute` | `/admin/users`, `/admin/audit-logs`                        | 无 `user:read` 权限 → `/jobs` |
| `PublicRoute`     | `/login`, `/register`                                      | 已登录 → `/jobs`              |

> 前端守卫仅做 UX 级别保护，**真正的安全边界在后端 API**。

## 两个授权 helper 的分工

| Helper                     | 来源                      | 适用场景                                 |
| -------------------------- | ------------------------- | ---------------------------------------- |
| `require_permission(name)` | `app/core/permissions.py` | 业务端点；运行时查询 DB RBAC 表          |
| `require_role(*roles)`     | `app/core/security.py`    | 运维型端点和少数 role-string UI/系统视图 |

新业务端点优先使用 `require_permission`，权限通过 DB RBAC 表管理；`require_role` 仅在不希望污染权限矩阵的纯运维场景使用。
