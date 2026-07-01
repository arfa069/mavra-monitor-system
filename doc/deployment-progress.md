# 部署进度记录

> 记录当前把 `mavra-monitor-system` 部署到 `192.168.1.13` Termux 手机服务器的进度。
> 这是一份阶段记录，重点回答“做了什么”和“结果如何”。

## 当前结论

后端已经在手机服务器上跑起来，并且通过健康检查验证成功。
Flutter 前端和 Next.js 公共博客也都已经部署到手机服务器上，并能通过浏览器正常打开。
Flutter 主前端已切回 hash 路由，并由 Nginx 接管 3000 端口，把 `/api/v1` 反代到后端，避免静态托管下登录 POST 落到文件服务器返回 501。
博客也已经并入同一个 Nginx 入口，`/blog`、`/_next`、`/blog-media`、`/robots.txt` 和 `/sitemap.xml` 都由 3000 统一对外提供。
GitHub Actions 到 Termux 的 CD 方案也已经落到仓库：当 `main` 上六个质量门都通过后，会由局域网内的 Windows 自托管 runner 构建 Flutter Web 和博客，并通过 SSH 上传到手机服务器后执行远端部署脚本。

## Termux CD

### GitHub 环境配置

新增的 GitHub Actions 部署环境如下：

```text
Environment: production-termux
Runner labels: self-hosted, Windows, mavra-deploy
Variables:
  TERMUX_HOST=192.168.1.13
  TERMUX_PORT=8022
  TERMUX_USER=u0_a323
  TERMUX_APP_DIR=/data/data/com.termux/files/home/apps/mavra-monitor-system
  TERMUX_KNOWN_HOSTS=<ssh-keyscan result for 192.168.1.13:8022>
Secrets:
  TERMUX_SSH_KEY=<deployment private key>
```

说明：

- 触发条件是 `push` 到 `main`。
- `deploy-termux` 必须等待 `lint`、`test`、`compile`、`api-contract`、`flutter-web-fast`、`blog` 六个任务全部通过。
- 部署使用 `production-termux` 环境串行执行，不会取消正在进行中的上一次生产部署。

### 构建与发布链路

当前 CD 链路分两段：

1. Windows 自托管 runner 本地构建：
   - `frontend`: `flutter build web --dart-define=API_BASE_URL=/api/v1`
   - `blog-frontend`: `npm ci && npm run build`
2. 构建完成后，把产物上传到远端：
   - `frontend/build/web`
   - `blog-frontend/.next/standalone`
   - `blog-frontend/.next/static`
   - `blog-frontend/public`（如果存在）

远端真正替换线上目录前，会先把上传内容放到：

```text
.deploy/incoming/<git-sha>
```

### 回滚边界

如果上传后的静态产物替换完成，但后续迁移、重启或健康检查失败，远端脚本会恢复上一版 Flutter Web 和博客静态产物，再重新拉起服务。

数据库迁移不会自动回滚；如需手动恢复，请使用：

```text
.deploy/backups/<timestamp>-<git-sha>/database.sql
```

也就是说：

- 静态站点资源支持自动回退；
- 数据库只保留 `pg_dump` 备份，需要人工决定是否恢复。

## 前端构建与运行

### Flutter 主前端

构建命令（Windows）：

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
flutter build web --dart-define=API_BASE_URL=/api/v1
```

运行命令（Termux，Nginx 接管 3000）：

```bash
nginx -t
nginx
```

Nginx 配置文件位于：

```text
/data/data/com.termux/files/usr/etc/nginx/nginx.conf
```

当前这份配置让 3000 端口直接提供 Flutter Web 静态文件，并把 `/api/v1/` 反代到 `127.0.0.1:8000`，所以登录请求会到真正的后端，而不是打到静态文件服务器。

## Nginx 接管

手机服务器上的 Nginx 已经从默认配置切到统一入口模式，配置文件位于：

```text
/data/data/com.termux/files/usr/etc/nginx/nginx.conf
```

当前部署方式是：

- `3000` 作为公网入口
- `/` 提供 Flutter Web
- `/api/v1/` 反代到后端 `127.0.0.1:8000`
- `/blog`、`/_next`、`/blog-media`、`/robots.txt`、`/sitemap.xml` 反代到博客服务链路

这一步替换了原先的 `python -m http.server 3000` 静态托管，所以现在登录 POST 不会再命中静态文件服务器。

## 手机一键启动

手机上的常用启动方式已经整理成脚本：

```bash
cd ~/apps/mavra-monitor-system
bash scripts/start_termux_stack.sh
```

这个脚本会：

- 用 `tmux` 启动 Redis
- 用 `tmux` 启动 PostgreSQL
- 用 `tmux` 启动后端 `uvicorn`
- 用 `tmux` 启动 Next.js 博客
- 校验并重载 Nginx

说明：

- Flutter 主前端不是独立常驻进程，它是静态构建产物，由 Nginx 直接提供。
- 如果 Flutter 或博客的构建产物缺失，脚本会提前报错并提示先在 Windows 上重新构建。

### Next.js 公共博客

构建命令（Windows）：

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/blog-frontend
npm ci
$env:BLOG_PUBLIC_BASE_URL="http://192.168.1.13:3000"
$env:BLOG_API_BASE_URL="http://127.0.0.1:8000/api/v1"
$env:BLOG_BACKEND_ORIGIN="http://127.0.0.1:8000"
$env:NEXT_PUBLIC_BLOG_BASE_URL="http://192.168.1.13:3000"
npm run build
```

运行命令（Termux，建议放进 `tmux` 常驻）：

```bash
cd /data/data/com.termux/files/home/apps/mavra-monitor-system/blog-frontend
cp -r .next/static .next/standalone/.next/
if [ -d public ]; then cp -r public .next/standalone/; fi
tmux new-session -d -s mavra-blog 'cd /data/data/com.termux/files/home/apps/mavra-monitor-system/blog-frontend/.next/standalone && env NODE_ENV=production HOSTNAME=0.0.0.0 PORT=3001 BLOG_PUBLIC_BASE_URL=http://192.168.1.13:3000 BLOG_API_BASE_URL=http://127.0.0.1:8000/api/v1 BLOG_BACKEND_ORIGIN=http://127.0.0.1:8000 NEXT_PUBLIC_BLOG_BASE_URL=http://192.168.1.13:3000 node server.js'
```

说明：

- 博客刚开始只跑通了 HTML，`/_next/static/...` 一度返回 404。
- 现已把 `.next/static` 补进 `standalone` 运行目录，所以样式和脚本都能正常加载。
- 博客的公开基址也已经切到 `http://192.168.1.13:3000`，这样 canonical、sitemap 和媒体 URL 都跟统一入口一致。

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
8. 补齐前端构建与运行命令，并修复博客静态资源加载路径：
   - Flutter Web 使用 `flutter build web --dart-define=API_BASE_URL=/api/v1`
   - Flutter Web 回退到默认 hash 路由，刷新时不再依赖服务器回退规则
   - 博客使用 `npm run build` 后在 `standalone` 目录运行 `node .next/standalone/server.js`
   - 博客静态资源需要同步到 `.next/standalone/.next/static`

## 结果

- 健康检查返回：`{"status":"healthy"}`
- Uvicorn 日志显示应用启动完成
- PostgreSQL 和 Redis 连接正常
- 当前后端服务已在远端常驻运行
- Flutter Web 构建产物已上传到手机服务器
- 前端入口现在由 Nginx 提供，`http://192.168.1.13:3000` 可以正常打开 Flutter 页面
- `GET http://127.0.0.1:3000/` 返回 `200 OK`，响应头显示 `Server: nginx/1.31.2`
- `POST http://127.0.0.1:3000/api/v1/auth/login` 会返回后端的 `401 Unauthorized`，不再出现 `501 Unsupported method ('POST')`
- `GET http://127.0.0.1:3000/blog` 返回 `200 OK`
- `GET http://127.0.0.1:3000/_next/static/css/bd008b7ec1a52c96.css` 返回 `200 OK`
- `GET http://127.0.0.1:3000/robots.txt` 和 `GET http://127.0.0.1:3000/sitemap.xml` 都由博客服务返回
- 后端已放行 `http://192.168.1.13:3000` 的 CORS 来源
- Next.js 博客已在手机服务器上构建并启动
- 博客的公开入口现在并入 `http://192.168.1.13:3000/blog`
- 后端已放行 `http://192.168.1.13:3000` 的 CORS 来源
- 博客的 CSS 和 JS 静态资源现在可以正常加载，不再出现 `/_next/static` 404

## 说明

- 本地 Windows 仓库已经恢复干净，没有保留这些 Termux 兼容改动。
- 远端手机服务器保留的是能正常启动的部署版本，用于当前在线服务。

## 下一步

前端主站部署已经完成，下一步可以继续做：

1. 验证登录、首页、博客列表和文章详情页的实际交互。
2. 如果后续需要，还可以把手机端静态站改成更正式的反代或常驻脚本。
