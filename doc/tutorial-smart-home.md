# 入门：接 Home Assistant，控制一个灯

> 适用读者：第一次在 mavra-monitor-system 里接 Home Assistant 的人。
> 目标：15 分钟内从前端点亮一盏智能灯。

## 背景

mavra-monitor-system 的智能家居模块是**只读 + 调服务**的轻量封装：所有设备状态、自动化、复杂流程仍在 Home Assistant 里管理，本系统只负责「看 + 触发」。实体状态通过 SSE 实时推送，命令通过 REST 调 Home Assistant service。

## Step 1：先有 Home Assistant

本机或局域网有一台 Home Assistant 跑着。记下：

- Base URL：`http://homeassistant.local:8123`（或 `http://192.168.1.10:8123`）
- 一个长期 Access Token（在 HA 用户档案 → Long-Lived Access Tokens 里创建）

## Step 2：填好 .env

项目根 `.env` 加：

```env
# Fernet 密钥（用来加密你存到数据库的 HA token）
# 生成：python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
SMART_HOME_SECRET_KEY=<your-fernet-key>
```

> **必须填**，否则 `PUT /api/v1/smart-home/config` 会拒绝保存，错误 `400 Empty SMART_HOME_SECRET_KEY`。
>
> 注意：换 / 丢这个 key 会让旧存的 HA token 全部解不开，**等于强制重连**。

## Step 3：重启后端

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"
```

## Step 4：前端填配置

1. 浏览器 → **Smart Home** 页
2. 填：
   - Base URL：`http://homeassistant.local:8123`
   - Access Token：粘刚才那个 long-lived token
3. 点 **Test Connection** — 成功后按钮变绿
4. 点 **Save**

后端做的事：

- `PUT /api/v1/smart-home/config` → Fernet 加密 token → 写 `smart_home_configs` 表
- 返回时只回 base_url 和连通性，不回 token

## Step 5：刷新实体列表

保存后前端会自动 `GET /api/v1/smart-home/entities` 拉所有 `light.` / `switch.` / `sensor.` 等实体。

你应该看到一长串实体卡片（HA 默认会把所有 entity 暴露出来）。

## Step 6：开一个灯

找 `light.xxx`，点卡片上的 **ON** 按钮。

调用栈：

- 前端 `POST /api/v1/smart-home/services/call`，body `{ "entity_id": "light.living_room", "service": "turn_on", "service_data": {} }`
- 后端 `app/domains/smart_home/router.py` → `HomeAssistantClient.call_service()` → HA WebSocket / REST
- 权限检查：`smart_home:control`

成功后：

- 灯物理上亮
- 卡片状态从 `off` 变 `on`（SSE 推送，1-2 秒延迟）
- `audit_logs` 表多一条 `smart_home.entity.control`

## Step 7：看实时状态流

整个 `/smart-home` 页面已经在订阅 `GET /api/v1/smart-home/entities/stream`（SSE）。任何 HA 端的自动化（人体感应、定时、其它 App 切换）都会实时反映到前端卡片上。

SSE 的实现细节见 [explanation-sse-realtime](explanation-sse-realtime.md)。

## 常见坑

| 现象                   | 原因                          | 修复                                                              |
| ---------------------- | ----------------------------- | ----------------------------------------------------------------- |
| Test Connection 一直红 | HA base URL 不通 / token 无效 | 浏览器开 HA 自己的 UI 验一下                                      |
| Save 后 token 没了     | 没人告诉过你有加密，DB 是密文 | 用 `pg_dump smart_home_configs` 看 `encrypted_token` 列是不是密文 |
| 点 ON 没反应           | 权限不够                      | 看 `users_permissions` 表当前 user 有没有 `smart_home:control`    |
| 实体列表空             | HA 没暴露 entity              | HA 端用户档案 → 勾上「Advanced Mode」才能看到 `entity_registry`   |

## 你已经走通了

- Smart Home 的 Fernet 加密
- 实体列表拉取
- 调 HA service
- 实时状态 SSE

## 下一步

- [reference-api-products](reference-api-products.md) 的 Smart Home 段 — 看完整 API
- [explanation-sse-realtime](explanation-sse-realtime.md) — 三种 SSE 通道的差异
- [howto-rbac](howto-rbac.md) — 让某个用户不能控制设备（只读）
