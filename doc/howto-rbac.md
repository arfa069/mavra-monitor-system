# How to 配置 RBAC 角色和资源权限

> 任务：给同事开一个「只能看商品，不能改智能家居」的账户。
> 适用：多用户环境下的权限细分。

## 角色 vs 资源权限

| 维度 | 角色                                          | 资源权限                                    |
| ---- | --------------------------------------------- | ------------------------------------------- |
| 粒度 | 粗（user / admin / super_admin）              | 细（按资源 ID）                             |
| 改法 | super_admin 改 `users_roles_permissions` 矩阵 | 任意 admin 调 `/admin/resource-permissions` |
| 适用 | 系统级能力（能否改 RBAC、能否看审计）         | 数据级（能否改某个具体商品 / 简历）         |

99% 的场景只用资源权限。角色默认三档就够。

## 默认角色

| 角色          | 拿到的能力                                                    |
| ------------- | ------------------------------------------------------------- |
| `user`        | 自己 CRUD 商品/职位/告警 / 调爬取 / 看自己日志 / 控制智能家居 |
| `admin`       | 上面全部 + 用户管理 + 审计日志 + 智能家居配置                 |
| `super_admin` | 上面全部 + 改角色权限矩阵 + 调全部配置                        |

详见 [doc/permission-architecture.md](permission-architecture.md) 的「权限矩阵」。

## 步骤 1：建一个用户

前端 → **Admin** → **Users** → 右上 **+ Add User**：

- Username：`bob`
- Email：`bob@example.com`
- Password：`BobPass1234!`（满足强密码策略）
- Role：`user`

API：

```bash
curl -X POST http://localhost:8000/api/v1/admin/users \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{
    "username": "bob",
    "email": "bob@example.com",
    "password": "BobPass1234!",
    "role": "user"
  }'
```

权限要求：`user:manage`（admin / super_admin）。

## 步骤 2：调整角色矩阵（仅 super_admin）

前端 → **Admin** → **Users** → 选 `user` 角色 → 勾掉 `smart_home:control` → Save。

API：

```bash
curl -X PATCH http://localhost:8000/api/v1/admin/roles/user/permissions \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{
    "add": [],
    "remove": ["smart_home:control"]
  }'
```

权限要求：`rbac:manage`（仅 super_admin）。

> 这个改动会**影响所有**当前是 `user` 角色的用户，包括你刚建的 bob。

## 步骤 3：资源级权限

场景：bob 平时不能改你的商品（默认 user 隔离），但你想让他改商品 id=42。

```bash
curl -X POST http://localhost:8000/api/v1/admin/resource-permissions \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt \
  -d '{
    "subject_id": 2,
    "resource_type": "product",
    "resource_id": "42",
    "permission": "edit"
  }'
```

- `subject_id`：被授权的用户 ID（bob）
- `resource_type` ∈ `product` / `job` / `user`
- `permission` ∈ `read` / `edit` / `manage`

## 步骤 4：撤销

```bash
curl -X DELETE http://localhost:8000/api/v1/admin/resource-permissions/7 \
  -H "X-CSRF-Token: <csrf>" -b cookies.txt
```

资源权限的 ID 来自 `GET /api/v1/admin/resource-permissions` 的列表。

## 边界保护

这些保护是后端硬编码的，不能通过改 RBAC 矩阵绕过：

| 谁          | 不能                                  |
| ----------- | ------------------------------------- |
| admin       | 创建 / 修改 / 删除 super_admin        |
| super_admin | 删除自己 / 删最后一个活跃 super_admin |

见 [doc/permission-architecture.md](permission-architecture.md)「角色边界保护」一节。

## 审计

所有用户管理 / 资源权限 / 角色矩阵改动都会写 `users_audit_logs`：

```bash
curl -b cookies.txt 'http://localhost:8000/api/v1/admin/audit-logs?limit=20'
```

敏感字段（password / token / webhook）被替换为 `***REDACTED***`。

## 失败兜底

| 现象                  | 原因             | 修复                      |
| --------------------- | ---------------- | ------------------------- |
| 403 Permission denied | 角色缺该权限     | 调角色矩阵或加资源权限    |
| 422 密码不满足强度    | 10 位 + 四类字符 | 改密码                    |
| 不能改 super_admin    | 角色边界         | 找另一个 super_admin 改   |
| 资源权限不生效        | 缓存             | 等 30s（Redis cache TTL） |

## 详见

- [explanation-auth-rbac](explanation-auth-rbac.md) — 为什么用三层模型
- [reference-api-auth](reference-api-auth.md) — 完整认证 + admin API
- [doc/permission-architecture.md](permission-architecture.md) — 完整权限矩阵
