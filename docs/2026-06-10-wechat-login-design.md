Date: 2026-06-10
Status: Approved for planning
Project: Mavra Monitor System

# 微信登录模块设计

## 背景

当前仓库已经具备微信登录后端基础能力：

- 后端已有 `GET /auth/wechat/qr`
- 后端已有 `GET /auth/wechat/callback`
- 后端已有 `POST /auth/wechat/bind`
- 后端已有 `POST /auth/wechat/register`
- 用户表已有 `wechat_openid`、`wechat_union_id`、`wechat_bind_at`

但前端登录页当前仍是禁用态 `WeChat Login (Coming Soon)`，整条网页登录链路尚未对用户开放。

本设计的目标不是从零设计微信认证，而是在现有后端契约基础上，把“登录页入口 -> 扫码 -> 回调 -> 绑定/注册 -> 正式登录”补成一个可交付的完整产品流程。

## 本次确认过的产品决策

以下决策已在 brainstorming 阶段确认：

1. 本次优先交付完整微信登录链路，不只做占位 UI。
2. 扫码后若微信号未绑定，必须在同一落地流程里同时提供：
   - 绑定已有账号
   - 注册新账号
3. 微信登录入口放在现有登录页内，采用“页内展开微信登录区域”，不跳独立登录页。
4. 扫码体验采用官方网页登录式自动回调，不要求用户手动点击“我已确认登录”。
5. 微信注册新账号使用 `用户名 + 邮箱 + 密码`。
6. 微信回调最终落到前端专用路由，由前端继续承接成功态、未绑定态和错误态。

## 目标

- 在登录页内开放可用的微信登录入口
- 支持扫码后自动进入回调流程
- 已绑定微信号可直接登录并恢复正式 cookie 登录态
- 未绑定微信号可在同一流程中选择绑定已有账号或注册新账号
- 整体流程兼容当前 cookie-first 鉴权方案
- 支持前端单测、E2E 和后端契约测试，且不依赖真实微信环境

## 非目标

- 不在本次设计中引入真实微信自动化测试
- 不在本次设计中改造移动端、小程序端或 App 内微信登录
- 不在本次设计中引入新的第三方身份体系
- 不在本次设计中重做普通用户名密码登录流程

## 方案对比

### 方案 A：SPA 主导 + 前端专用回调路由

这是本次选定方案。

- 登录页负责入口与二维码展示
- 后端回调负责 OAuth 真相和正式 cookie 写入
- 前端专用 callback 路由负责分流：
  - success
  - unbound
  - error

优点：

- 最贴合当前 React SPA + `AuthContext` 结构
- 未绑定分流最自然
- 测试边界清晰
- 后续补文案、交互、埋点都容易

代价：

- 前端需要补一层公开认证状态机
- 后端回调需要改成面向浏览器重定向，而不是直接返回 JSON

### 方案 B：所有状态都收敛到 `/login`

- 后端最终都跳回 `/login`
- 登录页同时承担普通登录、二维码展示、回调结果、绑定、注册

缺点：

- 登录页会变得过重
- URL 状态和来源页恢复更脆弱
- 出错和回流逻辑不易维护

### 方案 C：后端结果页主导

- 后端 callback 自己渲染成功/失败/绑定页面
- 前端仅保留入口按钮

缺点：

- 与当前 SPA 鉴权和页面结构不一致
- 体验割裂
- 长期维护成本更高

## 选定方案

采用方案 A：`登录页内入口 + 前端专用 callback 路由 + 后端负责认证真相源`。

## 用户流程

### 已绑定用户

1. 用户进入 `/login`
2. 点击“微信登录”
3. 登录页展开微信登录区域并展示二维码
4. 用户扫码并在微信内确认
5. 微信回调到后端 `/auth/wechat/callback`
6. 后端完成身份交换、识别已绑定用户、写入正式认证 cookie
7. 后端 `302` 到前端 `/auth/wechat/callback?status=success&next=...`
8. 前端 callback 页恢复 `getMe()` 登录态
9. 前端跳转到 `next` 或默认 `/today`

### 未绑定用户

1. 用户进入 `/login`
2. 点击“微信登录”
3. 登录页展开微信登录区域并展示二维码
4. 用户扫码并在微信内确认
5. 微信回调到后端 `/auth/wechat/callback`
6. 后端识别该微信号尚未绑定，生成短期 `temp_token`
7. 后端 `302` 到前端 `/auth/wechat/callback?status=unbound&next=...#temp_token=...`
8. 前端 callback 页读取 hash 中的 `temp_token`，立刻清理地址栏
9. 前端展示双路径：
   - 绑定已有账号
   - 注册新账号
10. 用户提交任一表单成功后，后端写入正式认证 cookie
11. 前端更新登录态并跳转到 `next` 或默认 `/today`

### 失败用户

1. 用户扫码后回调出现错误
2. 后端统一 `302` 到前端 callback 页错误态
3. 前端显示可理解错误信息
4. 用户可重新获取二维码或返回普通登录

## 架构设计

### 前端职责

前端负责：

- 登录页内微信入口展示
- 二维码展示与扫码说明
- 微信 callback 结果分流
- 未绑定状态下的绑定/注册表单
- 正式登录态恢复后的导航跳转

前端不负责：

- 自己判断微信登录是否真正成功
- 自己持久化第三方身份信息
- 保存长期凭证

### 后端职责

后端负责：

- 生成微信登录 URL 与 state
- 校验 state
- 向微信交换 code
- 识别 openid 是否已绑定
- 生成未绑定短期 token
- 写入正式认证 cookie
- 把浏览器重定向回前端 callback 路由

后端仍是认证真相源。

## 前端设计

### 新增或调整的页面与组件

#### 1. `LoginPage`

在现有登录页中新增 `WeChatLoginPanel` 区域：

- 默认收起
- 点击微信登录按钮后展开
- 展开后展示：
  - 二维码区域
  - 扫码说明
  - 加载态
  - 配置未启用提示
  - 返回普通登录入口

设计约束：

- 仍保留当前账号密码登录表单
- 不跳转独立页面
- 不弹新窗口

#### 2. `WeChatAuthCallbackPage`

新增公开路由页面，例如：

- `/auth/wechat/callback`

职责：

- 解析 `status`
- 解析 `next`
- 从 hash 读取 `temp_token`
- 立刻清理地址栏中的敏感片段
- 根据状态渲染：
  - success
  - unbound
  - error

此页面是“流程编排页”，不是新的品牌登录首页。

#### 3. `WeChatBindForm`

字段：

- `username`
- `password`

提交到：

- `POST /api/v1/auth/wechat/bind`

成功后：

- 直接建立正式登录态
- 回到目标页面

#### 4. `WeChatRegisterForm`

字段：

- `username`
- `email`
- `password`
- `password_confirm`

提交到：

- `POST /api/v1/auth/wechat/register`

规则：

- 前端复用现有强密码文案和校验体验
- 后端仍是最终校验源

#### 5. `authApi`

新增微信相关 API 方法：

- `getWeChatQr(next?)`
- `bindWeChat(data)`
- `registerWithWeChat(data)`

必要时新增统一的回调结果解析辅助函数，但不把 `temp_token` 落盘到 `localStorage` 或 `sessionStorage`。

### 前端状态机

前端流程拆分为四个核心状态：

#### `idle`

- 普通登录表单可见
- 微信登录区域默认未展开

#### `qr-ready`

- 微信登录区域展开
- 成功拿到二维码登录 URL
- 用户等待扫码

#### `wechat-callback`

- 用户已扫码
- 浏览器已回到前端 callback 页
- 页面根据回流参数执行分流

#### `wechat-unbound`

- 微信号未绑定
- 同页提供：
  - 绑定已有账号
  - 注册新账号

## 后端设计

### 保留现有接口

保留以下现有业务能力：

- `GET /auth/wechat/qr`
- `GET /auth/wechat/callback`
- `POST /auth/wechat/bind`
- `POST /auth/wechat/register`

外部前端经由 `/api/v1/...` 访问。

### `/auth/wechat/qr`

此接口继续由后端生成微信扫码登录所需入口，但新增一个可选参数：

- `next`

用途：

- 表示登录成功后前端希望回到哪个站内页面

要求：

- 仅允许站内相对路径
- 非法值统一降级到 `/today`

### `state` 结构升级

当前内存态仅保存时间戳，不足以承接前端回流。

建议升级为结构化缓存，至少包含：

- `issued_at`
- `next`
- `source`

约束：

- 10 分钟有效
- 单次消费
- 回调成功或失败后都应销毁

### `/auth/wechat/callback`

当前 callback 更偏 API 返回，本次改为“浏览器回流协调器”。

职责：

1. 校验 `state`
2. 向微信交换 `code`
3. 获取 `openid`
4. 判断是否已绑定
5. 已绑定时写正式认证 cookie
6. 未绑定时生成短期 `temp_token`
7. 统一 `302` 回前端 callback 路由

### 新增配置

新增前端回调展示地址配置：

- `WECHAT_FRONTEND_CALLBACK_URL`

示例：

- `http://localhost:3000/auth/wechat/callback`

分工：

- 微信平台登记的回调地址仍然是后端 callback
- 用户浏览器最终落地地址是前端 callback

## 回调协议

### 成功态

后端：

- 写入正式认证 cookie
- `302 -> /auth/wechat/callback?status=success&next=%2Ftoday`

前端：

- 调用 `getMe()`
- 恢复用户登录态
- 跳转到 `next`

### 未绑定态

后端：

- 生成短期 `temp_token`
- `302 -> /auth/wechat/callback?status=unbound&next=%2Ftoday#temp_token=...`

前端：

- 从 hash 读取 `temp_token`
- 立即 `replaceState` 清除地址栏中的 token
- 显示绑定/注册双路径表单

### 错误态

后端：

- `302 -> /auth/wechat/callback?status=error&reason=...`

推荐 reason code：

- `login_disabled`
- `state_expired`
- `oauth_failed`
- `wechat_identity_missing`
- `session_restore_failed`

前端：

- 根据 reason code 显示用户可理解提示
- 提供重试或返回登录页动作

## 错误处理

### 微信登录未启用

- `GET /api/v1/auth/wechat/qr` 返回 `503`
- 登录页微信面板展示“当前环境未启用微信登录”
- 普通登录路径不受影响

### state 无效或过期

- 后端不要停留在原始异常页
- 统一回前端 callback 错误态
- 前端提示“二维码已过期，请重新扫码”

### 微信 OAuth 交换失败

- 后端映射成稳定 reason code
- 前端不直接暴露原始第三方报文

### openid 缺失

- 视为微信身份信息获取失败
- 前端提示重新扫码

### `temp_token` 无效或过期

- 绑定/注册提交失败后，前端结束当前流程
- 引导用户重新扫码，不保留半残状态

### 表单提交失败

- 绑定失败：显示用户名/密码错误或账号不可用
- 注册失败：显示用户名冲突、邮箱冲突、密码强度失败等明确信息
- openid 冲突：提示该微信账号已绑定其他用户

### 成功回流但登录态恢复失败

- 前端不得假定登录成功
- 必须在 `getMe()` 成功后再导航
- 失败时显示“登录状态恢复失败，请重试”

## 安全与隐私边界

### `next` 限制

- 只允许站内相对路径
- 严禁开放重定向

### `temp_token` 使用方式

- 仅允许短期使用
- 仅放在 URL hash，不放 query
- 不写入 `localStorage`
- 不写入 `sessionStorage`

### 地址栏清理

- 前端 callback 页读取 `temp_token` 后，立刻执行 `history.replaceState`
- 防止 token 在截图、复制地址、浏览器历史中长期暴露

### 最小必要信息

前端流程中只处理：

- `status`
- `reason`
- `next`
- `temp_token`

前端不保存：

- `openid`
- 微信原始 token 返回体
- `app_secret`

### 自动化测试边界

- 不使用真实微信账号
- 不调用真实第三方登录
- 不在测试中写入真实凭证

## 测试策略

### 后端测试

覆盖以下场景：

- 微信登录禁用时二维码接口返回 503
- `next` 仅接受合法站内路径
- `state` 过期或重复消费
- callback 成功登录重定向
- callback 未绑定重定向
- callback 错误 reason 映射
- bind/register 成功后建立正式登录态

全部通过 mock 微信响应完成，不进行真实外网调用。

### 前端单元测试

覆盖以下场景：

- 登录页微信区域展开与收起
- 二维码获取成功、失败、未启用
- callback 页 `success / unbound / error` 分流
- `temp_token` 从 hash 读取并立即清理
- 绑定表单错误提示
- 注册表单错误提示
- 成功后跳转到 `next`

### 前端 E2E

在 Playwright 中覆盖模拟回流场景：

- `success`
- `unbound -> bind`
- `unbound -> register`
- `error`

E2E 只模拟本系统回流，不接真实微信扫码。

## 交付边界

完成本设计后的实现应至少交付：

- 登录页可用的微信登录入口
- 前端专用 callback 路由
- 未绑定时的绑定/注册双路径
- 后端 callback 浏览器重定向契约
- 对应单测与 E2E

## 验收标准

满足以下条件才能视为实现完成：

1. 用户可在 `/login` 页内启动微信登录
2. 已绑定用户扫码后可直接进入系统
3. 未绑定用户扫码后可在同一流程中绑定已有账号或注册新账号
4. 登录态恢复依赖真实 cookie 与 `/auth/me`，而不是前端假成功
5. 自动化验证不触发真实微信登录
6. 错误态具备明确回退路径

## 实施建议

下一步进入 implementation plan 时，建议拆为以下工作包：

1. 后端 callback 契约与配置调整
2. 前端登录页微信入口与二维码区域
3. 前端 callback 页与未绑定双路径流程
4. 单测与 E2E 补齐

