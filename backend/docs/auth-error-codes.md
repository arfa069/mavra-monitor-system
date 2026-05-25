# 认证 API 错误码说明

本文档详细说明了认证 API 的错误响应格式和错误码含义。

## 错误响应格式

所有认证 API 的错误响应都遵循以下 JSON 格式：

```json
{
  "detail": "错误描述信息"
}
```

## HTTP 状态码

### 2xx 成功状态码

| 状态码 | 含义    | 说明                                 |
| ------ | ------- | ------------------------------------ |
| 200    | OK      | 请求成功（登录、登出、获取用户信息） |
| 201    | Created | 资源创建成功（用户注册）             |

### 4xx 客户端错误状态码

| 状态码 | 含义                 | 说明         | 可能原因                             |
| ------ | -------------------- | ------------ | ------------------------------------ |
| 400    | Bad Request          | 请求格式错误 | 注册时用户名或邮箱已被占用           |
| 401    | Unauthorized         | 认证失败     | 用户名或密码错误、Token 无效或已过期 |
| 422    | Unprocessable Entity | 参数验证失败 | 请求参数不符合要求                   |
| 429    | Too Many Requests    | 请求过于频繁 | 连续登录失败导致账户被锁定           |

## 详细错误说明

### 400: 用户名或邮箱已注册

**触发条件：** 注册时提供的用户名或邮箱与已有用户重复

**请求示例：**

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "existing_user", "email": "test@example.com", "password": "123456"}'
```

**响应示例：**

```json
{
  "detail": "用户名已注册"
}
```

或

```json
{
  "detail": "邮箱已注册"
}
```

**解决方案：** 使用不同的用户名或邮箱进行注册

---

### 401: 认证失败

**触发条件：** 用户名或密码错误、Cookie 缺失、Token 无效或已过期、refresh token 无效或会话已失效

#### 场景 1: 登录时用户名或密码错误

**请求示例：**

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "wrong_password"}'
```

**响应示例：**

```json
{
  "detail": "用户名或密码错误"
}
```

#### 场景 2: Cookie 缺失、Token 无效或已过期

**请求示例：**

```bash
curl -X GET http://localhost:8000/auth/me
```

**响应示例：**

```json
{
  "detail": "认证失败：未提供登录凭证"
}
```

或

```json
{
  "detail": "认证失败：Token 无效或已过期"
}
```

**解决方案：**

- 登录失败：请检查用户名和密码是否正确
- Access Token 过期：浏览器端应先调用 `POST /auth/refresh` 轮换 Cookie；refresh 失败后重新登录
- API 脚本：可使用 legacy `Authorization: Bearer <token>` fallback，但浏览器端不再从 localStorage 管理 bearer token

#### 场景 3: Refresh Token 无效或已过期

**请求示例：**

```bash
curl -X POST http://localhost:8000/auth/refresh
```

**响应示例：**

```json
{
  "detail": "未提供刷新令牌"
}
```

或

```json
{
  "detail": "刷新令牌无效或已过期"
}
```

**解决方案：** 重新登录。`/auth/refresh` 依赖 HttpOnly `pm_refresh_token` Cookie，不要求 `X-CSRF-Token`。

---

### 403: CSRF 验证失败

**触发条件：** 已登录用户发起 POST/PATCH/PUT/DELETE 等不安全方法时，缺少 `pm_csrf_token` Cookie、缺少 `X-CSRF-Token` 请求头，或二者不一致。

**响应示例：**

```json
{
  "detail": "CSRF 验证失败：请求被拒绝"
}
```

**解决方案：** 前端从可读的 `pm_csrf_token` Cookie 读取值，并在不安全方法请求头中发送 `X-CSRF-Token`。安全方法 GET/HEAD/OPTIONS 不需要 CSRF；`POST /auth/refresh` 也不需要 CSRF。

### 422: 参数验证失败

**触发条件：** 请求参数不符合验证规则

#### 场景 1: 用户名格式错误

**请求示例：**

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "ab", "email": "test@example.com", "password": "123456"}'
```

**响应示例：**

```json
{
  "detail": "Validation error",
  "errors": [...]
}
```

#### 场景 2: 邮箱格式错误

**请求示例：**

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "email": "invalid_email", "password": "123456"}'
```

**响应示例：**

```json
{
  "detail": "邮箱格式错误"
}
```

#### 场景 3: 密码太短

**请求示例：**

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "email": "test@example.com", "password": "123"}'
```

**响应示例：**

```json
{
  "detail": "密码必须至少6位"
}
```

**参数验证规则：**
| 字段 | 规则 |
|------|------|
| username | 3-50字符，只能包含字母、数字、下划线和连字符 |
| email | 有效的邮箱格式 |
| password | 6-100字符 |

**解决方案：** 根据错误提示修改请求参数

---

### 429: 请求过于频繁（账户锁定）

**触发条件：** 连续5次登录失败后，账户被锁定15分钟

**请求示例：**

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "wrong_password"}'
```

**响应示例：**

```json
{
  "detail": "登录尝试次数过多，请 15 分钟后再试"
}
```

**解决方案：**

- 等待15分钟后重试
- 如果忘记密码，请联系管理员重置密码

## 错误码速查表

| 状态码 | detail 字段值                     | 含义                | 解决方案                        |
| ------ | --------------------------------- | ------------------- | ------------------------------- |
| 400    | 用户名已注册                      | 用户名已被占用      | 使用其他用户名                  |
| 400    | 邮箱已注册                        | 邮箱已被占用        | 使用其他邮箱                    |
| 401    | 用户名或密码错误                  | 登录凭证不正确      | 检查用户名和密码                |
| 401    | 认证失败：未提供登录凭证          | 缺少 access Cookie  | 登录或 refresh                  |
| 401    | 认证失败：Token 无效或已过期      | Access Token 过期   | 调用 `/auth/refresh` 或重新登录 |
| 401    | 未提供刷新令牌                    | 缺少 refresh Cookie | 重新登录                        |
| 401    | 刷新令牌无效或已过期              | Refresh Token 失效  | 重新登录                        |
| 401    | 用户不存在或已被禁用              | 用户被禁用或不存在  | 联系管理员                      |
| 403    | CSRF 验证失败：请求被拒绝         | CSRF 校验失败       | 携带正确 `X-CSRF-Token`         |
| 422    | 密码必须至少6位                   | 密码长度不足        | 使用更长的密码                  |
| 422    | 邮箱格式错误                      | 邮箱格式不正确      | 使用有效的邮箱格式              |
| 429    | 登录尝试次数过多，请 X 分钟后再试 | 账户被锁定          | 等待锁定解除                    |

## 开发建议

### 客户端错误处理

建议前端在处理认证错误时：

1. **显示友好的错误消息**：将 `detail` 字段的值展示给用户
2. **区分不同错误类型**：根据状态码和错误信息进行不同处理
3. **实现重试逻辑**：
   - 401 错误：除登录和初始化 `/auth/me` 外，先尝试 `POST /auth/refresh`；失败后引导用户重新登录
   - 429 错误：显示倒计时并禁止登录按钮

### 示例代码

```typescript
// 前端错误处理示例
async function login(username: string, password: string) {
  try {
    const response = await fetch("/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: JSON.stringify({ username, password }),
    });

    if (response.ok) {
      const data = await response.json();
      return { success: true };
    }

    const error = await response.json();

    if (response.status === 429) {
      return { success: false, error: "账户已被锁定，请稍后再试" };
    }

    return { success: false, error: error.detail };
  } catch (e) {
    return { success: false, error: "网络错误" };
  }
}
```
