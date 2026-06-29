# How to 在本机运行爬虫并写入手机 PostgreSQL

> 适用场景：手机服务器已经部署 Mavra，手机前端和手机后端负责创建爬取任务；本机负责真正执行商品和职位爬取，并把结果写回手机服务器上的 PostgreSQL。

## 结论

推荐链路是：

```text
手机前端 -> 手机 FastAPI -> 手机 PostgreSQL(crawl_tasks)
                                      ^
                                      |
本机 crawler worker -- SSH 隧道 -------+
```

手机前端不会直接调用本机。它仍然调用手机后端；本机 worker 只通过数据库领取任务、写回任务状态和爬取结果。

## 手机端准备

在手机 Termux 上启动生产服务：

```bash
cd ~/apps/mavra-monitor-system
bash scripts/start_termux_stack.sh
```

手机端应保留：

- PostgreSQL
- Redis
- FastAPI
- Nginx
- Flutter Web 静态站
- Next.js 博客
- FastAPI 进程内的 APScheduler

手机端不要再启动 crawler worker。若存在 `python -m app.workers.crawler` 的 tmux 会话或进程，先停掉它，避免两端争抢同一 profile。

## 本机启动

不要用 `scripts/start_server.ps1` 连接手机生产库。这个脚本会启动本机 FastAPI、APScheduler 和 crawler worker；如果它连到手机 PostgreSQL，可能重复入队并争抢任务。

本机依赖先确认：

- Python 后端依赖已安装。
- 商品爬取需要 OpenCLI 可用。
- 京东/淘宝 OpenCLI 依赖浏览器 Bridge 扩展连接；若未连接，任务会被领取但商品爬取会写入失败日志。
- 职位爬取需要本机对应 `profiles/{profile_key}` 已登录。

使用专用脚本：

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system
./scripts/start_phone_crawler_worker.ps1
```

脚本默认连接 `u0_a323@192.168.1.13`。如果本机 Python 可导入 `paramiko`，脚本会在同一个窗口里提示输入 SSH 密码，自动建立 SSH 隧道，然后启动 worker。

数据库连接默认通过 SSH 从手机部署目录的 `.env` 或 `backend/.env` 读取 `DATABASE_URL`，并自动把 host/port 改成 `127.0.0.1:15432`。默认手机部署目录是 `~/apps/mavra-monitor-system`，可用 `PHONE_REMOTE_PROJECT_ROOT` 覆盖。本机 `.env` 只作为兜底，不作为生产凭据来源。

脚本默认建立：

```text
127.0.0.1:15432 -> 手机 127.0.0.1:5432
```

脚本只在当前 PowerShell 进程内设置：

- `DATABASE_URL`
- `PRICE_MONITOR_PROFILE_ROOT`

真实 PostgreSQL 密码不要写进文档或仓库。若不想使用 `.env`，也可只在当前终端临时设置：

```powershell
$env:PHONE_DATABASE_URL = "postgresql+asyncpg://<user>:<password>@127.0.0.1:15432/<database>"
./scripts/start_phone_crawler_worker.ps1
```

如果本机没有 `paramiko`，脚本会退回 OpenSSH。此时手机 SSH 需要密码登录时，隐藏隧道进程不能交互输入密码，可以先在另一个 PowerShell 窗口手动开隧道：

```powershell
ssh -o ExitOnForwardFailure=yes -N -L 127.0.0.1:15432:127.0.0.1:5432 -p 8022 <termux-user>@<phone-ip>
```

然后在本仓库启动 worker：

```powershell
./scripts/start_phone_crawler_worker.ps1 -UseExistingTunnel
```

## 参数

常用参数：

- `-Kind all`：默认，领取商品、职位和分析任务。
- `-Kind product`：只领取商品任务。
- `-Kind job`：只领取职位任务。
- `-Platform jd`：只领取指定平台任务，可重复传入。
- `-SshTarget <user@host>`：覆盖默认手机 SSH 地址。
- `-Concurrency 1`：默认值。反爬敏感场景不要调高。
- `-Once`：只领取一轮任务，适合空跑或验收。
- `-UseExistingTunnel`：复用已经手动建立的 SSH 隧道。

## 前端怎么控制本机爬取

在手机前端点击商品或职位爬取后：

1. 手机前端请求手机 FastAPI。
2. 手机 FastAPI 往手机 PostgreSQL 写 `crawl_tasks`。
3. 本机 worker 通过 SSH 隧道从同一个 `crawl_tasks` 表抢 pending 任务。
4. 本机执行 OpenCLI、浏览器或 HTTP 爬取。
5. 本机把结果写回手机 PostgreSQL。
6. 手机前端通过状态接口、列表刷新或事件中心查看结果。

## 边界情况

SSH 隧道断开：

- worker 会停止续约或写库失败。
- 手机端可能短时间显示任务 running。
- `lease_until` 过期后，恢复逻辑会把过期任务标为失败，或后续由人工重新触发。

手机 PostgreSQL 未监听 TCP：

- 不要开放局域网直连。
- 优先只启用 PostgreSQL loopback TCP，继续通过 SSH 隧道访问。
- 如果 loopback TCP 也不可用，先停在连接层排查，不改应用代码绕过数据库。

手机端 worker 未停：

- PostgreSQL 行锁能避免同一任务被两个 worker 同时领取。
- 但同一 `profile_key` 会在手机和本机之间轮流占用，登录态路径会混乱。
- 推荐手机端不跑 worker；若必须并行，按 `--kind`、`--platform` 或不同 `profile_key` 明确拆分。

本机 profile 不存在或未登录：

- 商品 OpenCLI 任务可能仍可执行。
- 职位任务可能因为登录态缺失失败。
- 验收职位任务前，确认本机 `profiles/{profile_key}` 已登录对应平台。

远端 `crawl_profiles.profile_dir` 变成 Windows 路径：

- 单本机 worker 模式下可以接受，因为执行者就是本机。
- 如果未来恢复手机 worker，先修正 profile 归属，或让不同机器使用不同 `profile_key`。

本机和手机代码版本不一致：

- worker 使用本机代码写手机数据库。
- 启动前确认本机代码和手机部署版本兼容；涉及 schema 改动时，先在手机端完成 Alembic 迁移。

实时事件不可完全跨进程：

- worker 会写 `system_logs` 和任务状态，刷新或轮询能看到结果。
- 当前 SSE broker 是进程内内存对象，本机 worker 的实时事件不会直接推到手机后端已有连接。
- 如需秒级跨机器实时推送，后续再引入 Redis pub/sub 或数据库轮询。

## 验收

空跑：

```powershell
./scripts/start_phone_crawler_worker.ps1 -UseExistingTunnel -Once
```

商品验收：

1. 在手机前端触发一个商品爬取。
2. 确认任务被本机 worker 领取。
3. 确认手机端列表出现新价格或新爬取日志。

职位验收：

1. 确认本机对应 `profile_key` 已登录。
2. 在手机前端触发一个职位配置爬取。
3. 确认手机端岗位列表或职位爬取日志更新。

安全检查：

- 不提交真实 `DATABASE_URL`。
- 不提交 SSH 密码、JWT、webhook、cookie。
- 只在终端环境变量或交互输入里提供真实凭据。
