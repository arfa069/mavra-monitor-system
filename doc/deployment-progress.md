# 部署进度记录

> 记录当前把 `mavra-monitor-system` 部署到 `192.168.1.13` Termux 手机服务器的进度。
> 这是一份阶段记录，重点回答“做了什么”和“结果如何”。

## 当前结论

后端已经在手机服务器上跑起来，并且通过健康检查验证成功。

## 已完成的事情

1. 通过 SSH 连上手机服务器：
   - `ssh -p 8022 u0_a323@192.168.1.13`
2. 确认远端仓库位置：
   - `~/apps/mavra-monitor-system`
3. 把 Windows 端 `.env` 同步到远端后端目录。
4. 在 Termux 上补齐后端运行所需的 Python / 系统依赖。
5. 处理了 Termux 环境下的兼容问题：
   - `pydantic-core` 需要显式 `ANDROID_API_LEVEL=31`
   - `zoneinfo` 缺少时区数据，补装了 `tzdata`
   - `nh3` 在 Termux / Python 3.13 上有 ABI 导入问题，部署侧改成了纯 Python HTML 清洗方案
6. 启动后端服务：
   - `python -m uvicorn app.main:app --host 0.0.0.0 --port 8000`
7. 用健康检查验证：
   - `GET /health`

## 结果

- 健康检查返回：`{"status":"healthy"}`
- Uvicorn 日志显示应用启动完成
- PostgreSQL 和 Redis 连接正常
- 当前后端服务已在远端常驻运行

## 说明

- 本地 Windows 仓库已经恢复干净，没有保留这些 Termux 兼容改动。
- 远端手机服务器保留的是能正常启动的部署版本，用于当前在线服务。

## 下一步

下一步部署前端 Flutter 项目：

1. 确认前端部署方式，是本机 Web 静态托管，还是继续通过 Termux 提供服务。
2. 配好前端 `API_BASE_URL` 指向当前后端。
3. 构建 Flutter 前端并上传到手机服务器。
4. 用浏览器访问前端页面，确认能正常打开、登录并调用后端 API。
