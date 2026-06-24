# 认证授权设计：Cookie-first / JWT / CSRF / RBAC / ACL

> 解释**为什么**这套认证是这种形状，以及它换来 / 牺牲了什么。
> 适用：所有要改认证或加权限的人。

## 一句话

> 我们用 **Cookie-first + 短 access JWT + 长 refresh + RBAC + 资源 ACL + 审计**这套「政府级」组合，是因为这系统要管**多用户 + 真实凭证（HA token）+ 受限资源（爬虫 profile）**。

## 为什么不只用一个角色判断

| 阶段       | 模型                                       | 失败                                          |
| ---------- | ------------------------------------------ | --------------------------------------------- |
| v1         | `users.role` 字符串（user/admin）          | 想给某个用户「只能看商品 42、不能改」就改不了 |
| v2         | + 资源 ACL（`users_resource_permissions`） | 资源多时性能差，但场景只有几十个资源，OK      |
| v3（现在） | + DB RBAC 矩阵                             | 改权限不用改代码，热改生效                    |

三层并存是因为它们解决不同问题：

```text
认证（auth）           → "你是谁？"        Cookie/JWT
角色（role）           → "你能做哪类事？"   super_admin
权限（permission）     → "你能做哪些动作？" product:read
资源 ACL               → "你能动这个资源？" users_resource_permissions
```

`admin` 角色自动带 `user:read` / `user:manage` / `config:read` / `config:write` / `smart_home:*`；但**不带** `product:*` —— admin 不应该能替人改商品。

## Cookie-first vs Bearer

|              | Cookie                            | Bearer                       |
| ------------ | --------------------------------- | ---------------------------- |
| 前端         | `withCredentials: true` 自动带    | 手动存 localStorage / memory |
| CSRF 风险    | **有**（必须配 CSRF token）       | 无（同源策略兜底）           |
| XSS 偷 token | 偷不到（HttpOnly）                | 偷得到                       |
| 跨域         | CORS preflight + credentials 复杂 | 简单                         |
| 脚本友好     | 需要 cookie jar                   | 简单 `Authorization` 头      |

我们选 Cookie-first 是因为：

1. 系统有**前端 UI**（Flutter UI），登录一次一直用，refresh 走 cookie 不打扰用户
2. 真实凭证（HA token）必须**前端永远拿不到**，所以即便选 Bearer 也要走 cookie 形式
3. 跨域只在 localhost ↔ 127.0.0.1 之间，简单

代价：

- CSRF 防护是必做的（`X-CSRF-Token` 头）
- 跨域部署更复杂（`CORS_ALLOW_CREDENTIALS=true` + 显式 origins）
- 浏览器禁了 third-party cookie 后某些场景登不上

## Access JWT 15 分钟

| 寿命            | 取舍                                         |
| --------------- | -------------------------------------------- |
| 5 分钟          | 频繁 refresh，UX 差；UX 不在乎安全的反而能忍 |
| 15 分钟（现在） | refresh 频率可接受；token 泄露窗口可控       |
| 1 小时          | 泄露窗口太大；HA token 关联时风险高          |
| 24 小时         | 几乎等于永不过期；不如直接用 session         |

选 15 分钟是因为**多用户 + 强凭证**这个场景，泄露窗口必须小。15 分钟在 UI 上「无感」（后台静默 refresh），但攻击者拿到 access token 只能用 15 分钟。

## Refresh Token Rotation

```text
登录:   服务端生成 refresh token，存 SHA-256 哈希到 DB
刷新:   POST /api/v1/auth/refresh
        校验哈希匹配 → 撤销旧 token → 生成新 token → 写新哈希
        客户端 Set-Cookie 拿新的三类 cookie
```

**Rotation 意味着**：refresh token 一旦被攻击者用过，原 token 立刻失效。`/api/v1/auth/refresh` 端点会同时把**所有 session**里相同指纹的 token 也撤销（防并发滥用）。

**为什么不存 refresh token 明文**

数据库泄露时哈希不可逆。明文 → 直接能用。哈希 + SHA-256 是工业级标准（GitHub / Google 都这样做）。

## CSRF

Cookie 自动带 → 跨站请求会带 → 攻击者可以在别的网站用 `<form action="https://yourapi.com/api/v1/auth/logout">` 偷你的 cookie。

**对策**：

- 不安全方法必须带 `X-CSRF-Token` 头
- token 存在**非 HttpOnly** cookie（前端能读）
- 后端比较 cookie 值与头值

`POST /api/v1/auth/refresh` 例外（不要求 CSRF），因为它只依赖 `pm_refresh_token`（HttpOnly，攻击者读不到）。

## RBAC 表设计

```text
users_roles          (user/admin/super_admin)  枚举
users_permissions    (product:read 等)          枚举
users_roles_permissions   多对多
```

`require_permission("product:read")` 在请求时**实时查 DB**，而不是查 JWT 内嵌的 permissions。

为什么不用 JWT 内嵌：

- 改权限要等 token 过期（最长 15 分钟）
- 多机 session 同步复杂
- 业务方改权限后立刻生效是产品需求

代价：每个受保护请求都多一次 SQL。优化：Redis 缓存权限集 30s（`app/core/permissions.py:_permission_cache`），改 RBAC 矩阵后**等最多 30s** 生效。

## 资源 ACL

`users_resource_permissions`：

| 字段            | 含义                             |
| --------------- | -------------------------------- |
| `subject_id`    | 被授权用户                       |
| `resource_type` | `product` / `job` / `user`       |
| `resource_id`   | 资源 ID（**string** 以兼容跨域） |
| `permission`    | `read` / `edit` / `manage`       |

**作用**：A 用户的商品 B，A 自己能改。如果 admin 想让 C 也能改 B，授予 `edit` 而不是 `manage`（`manage` 是「转授权」能力）。

**为什么 `resource_id` 是 string**

商品 ID 是 int，但职位 ID 是 varchar，user ID 也是 int。用 string 抹平差异，省一张中间表。

## 强密码

2026-06 提交 `052158a1` 引入。规则：

- 长度 ≥ 10
- 同时含大小写 / 数字 / 特殊字符

### 为什么强制

- 单用户时期不需要（用户自己设）
- 多用户后**任何用户的弱密码**会泄露该用户**所有**真实凭证（HA token）
- bcrypt 是慢哈希但慢得不够，**没有强密码**兜底会大幅降低破解成本

**代价**：用户注册 / 改密时多一步约束。文档清楚就行。

## 登录失败锁定

5 次失败 → 锁 15 分钟（Redis 计数 `auth:lockout:<username>`）。

**为什么 5 / 15**

OWASP 推荐值。少 → 易被暴力；多 → 攻击者不锁，能用 30 次/分钟 × 24h 持续扫。

**为什么不 ban IP**

- 同一公司 / NAT 出口 IP 共享，ban IP 误伤大
- 锁账号 + 慢哈希已经够

## 审计

`users_audit_logs` + `system_logs`：

- 用户写操作（创建 / 改密 / RBAC 改动 / 资源授权）写 audit
- 平台事件（爬虫失败 / 飞书重试 / LLM 错误）写 system_log
- 都过 `app/core/log_redaction.py` 替换密码 / token / webhook

**为什么双通道**

- 审计是**谁做了什么**（业务），事件是**系统发生了什么**（运维）
- UI 也要分开（admin 看 audit，系统看 system_log）
- 性能影响：audit 写异步（不阻塞请求），system_log 同步（要立即可见）

## 边界保护

不能绕过 RBAC 矩阵的硬编码规则：

| 角色        | 限制                                            |
| ----------- | ----------------------------------------------- |
| admin       | 不能创建 / 改 / 删 super_admin                  |
| super_admin | 不能删自己、不能删 / 禁最后一个活跃 super_admin |

`app/domains/admin/router.py:_enforce_role_boundaries()` 强制。

## 取舍总结

| 我们选了         | 换来                 | 牺牲                       |
| ---------------- | -------------------- | -------------------------- |
| Cookie + 短 JWT  | 泄露窗口小、HttpOnly | CSRF 复杂度                |
| Refresh rotation | 一次泄露不蔓延       | 客户端要处理 401 刷新      |
| DB RBAC 实时查   | 改权限立即生效       | 每请求多一次 SQL（已缓存） |
| 资源 ACL         | 细粒度授权           | 跨资源类型时 API 不一致    |
| 强密码           | 数据库泄露成本高     | UX 麻烦                    |
| 5/15 锁定        | 防暴力               | 误锁风险（low）            |
| 双通道日志       | 业务 / 运维可分      | 存储 / 查询复杂度          |

## 详见

- [reference-api-auth](reference-api-auth.md) — 完整 API
- [doc/permission-architecture.md](permission-architecture.md) — 权限矩阵
- [howto-rbac](howto-rbac.md) — 任务场景
