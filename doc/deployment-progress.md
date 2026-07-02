# 部署进度记录

> 记录当前把 `mavra-monitor-system` 部署到 `192.168.1.13` Android/Termux 服务器的进度。
> 这是一份阶段记录，重点回答“做了什么”和“结果如何”。

## 当前部署记录

Termux CD 已经跑通完整链路。最新验证不是只跑部署脚本，而是 GitHub Actions 从
构建 Flutter Web 和 Blog artifact 开始，经过 Windows self-hosted runner 下载
artifact、上传到 Termux、远端解包部署、重启服务和健康检查，整条链路自然完成。

最新成功记录：

```text
GitHub Actions run: 28562301546
Run result: completed / success
Deploy job: Deploy Termux completed / success
Deploy job id: 84682715543
Deploy sha: 59d83e8d12003e95e65591c1e82e00fcf6a1aebb
```

部署日志中的关键结果：

```text
[INFO] Uploading GitHub-built artifacts to Termux via temporary Termux HTTP receiver.
[INFO] Updating source from runner-provided Git bundle
[INFO] Verifying deploy artifact hashes
[OK] Backend health check passed
[OK] Frontend root health check passed
[OK] Blog health check passed
[OK] Deployed 59d83e8d12003e95e65591c1e82e00fcf6a1aebb
```

当前仍需关注的主要问题是速度：这次 `Deploy to Termux` step 从
`2026-07-02T03:08:19Z` 跑到 `2026-07-02T03:25:21Z`，约 17 分钟 2 秒。
瓶颈主要在 Windows runner 向 Termux 上传两个构建 artifact。当前已经有
artifact hash 校验和远端缓存，但本轮没有命中复用，说明后续应优先改成按
构建输入或路径判断复用，而不是只依赖最终 tarball hash。

## Termux CD

当前 CD 全链路是：

1. main push 触发 CI。Deploy Termux 只在 push main 时跑，并且等这些必需 job 成功：Backend lint/tests/compile、API contract、Flutter Web fast PR、Blog tests/build。见 [.github/workflows/ci.yml (line 363)](C:/Users/arfac/Documents/mavra-monitor-system/.github/workflows/ci.yml:363)。

2. GitHub hosted runner 构建产物。Flutter Web 构建成 termux-frontend-web artifact；Blog 构建成 termux-blog-build artifact。Deploy job 再在 Windows self-hosted runner 下载这两个 artifact。见 [.github/workflows/ci.yml (line 384)](C:/Users/arfac/Documents/mavra-monitor-system/.github/workflows/ci.yml:384)。

3. Windows self-hosted runner 负责连接 Termux 服务器。scripts/deploy_termux_from_runner.ps1 写入临时 SSH key/known_hosts，上传远端部署脚本，检查远端当前 Git SHA，并按需要生成 `source.bundle`。如果远端还不是本次 SHA，runner 会上传这个 Git bundle，让 Termux 服务器从本地 bundle 更新源码，避免手机端依赖 `github.com` 出网。

4. artifact 传输方式。Deploy job 下载 GitHub 构建好的 artifact 后，runner 会写入 `artifact-sha256.txt`，先尝试从 Termux 远端 artifact cache 复用；没有命中时，默认在 Termux 上启动临时 HTTP receiver，再通过 HTTP PUT 把 `frontend-web.tar.gz`、`blog-standalone.tar.gz`、`blog-static.tar.gz` 等包上传到 `.deploy/incoming/<git-sha>/`。这次完整链路验证实际走的是 receiver 模式，并在部署后写入了 3 个 cache 文件。

5. Termux 远端执行真正部署。scripts/deploy_termux_remote.sh 会检查远端 tracked 文件不能脏，优先确认当前源码是否已经是本次 SHA；否则从 `source.bundle` fetch；缺少 bundle 时才回退到 GitHub fetch。随后解压 artifact、备份旧前端和 Blog、可选 pg_dump、复制新产物、执行 alembic upgrade head。见 [deploy_termux_remote.sh](C:/Users/arfac/Documents/mavra-monitor-system/scripts/deploy_termux_remote.sh)。

6. Termux 重启服务。scripts/start_termux_stack.sh 加载生产 .env，确认 Redis/PostgreSQL，就用 tmux 启动 backend、blog，并 reload/确认 Nginx；Flutter Web 由 Nginx 作为静态文件提供。见 [start_termux_stack.sh (line 15)](C:/Users/arfac/Documents/mavra-monitor-system/scripts/start_termux_stack.sh:15)。

7. 健康检查和回滚。部署后依次检查 backend /health、前端 /、Blog /blog；任一失败就恢复备份的静态产物并重启栈。全部通过才输出 [OK] Deployed <sha>。见 [deploy_termux_remote.sh (line 420)](C:/Users/arfac/Documents/mavra-monitor-system/scripts/deploy_termux_remote.sh:420)。

注：推送时跳过的重型 smoke。Android build and smoke、Windows build and smoke 当前只在 schedule 或 workflow_dispatch 触发，push main 的 CD 链路会跳过它们；这次 run 中两者均为 skipped，符合预期。工作流也配置了 Markdown / `doc/` / `docs/` docs-only 跳过，纯文档提交不应触发 CI/CD。

## 前端构建

### Flutter 主前端

构建:

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
flutter build web --dart-define=API_BASE_URL=/api/v1
```

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

## 部署方式

### Flutter 主前端部署

运行命令（Termux，Nginx 接管 3000）：

```bash
nginx -t
nginx
```

Nginx 配置文件：

```text
/data/data/com.termux/files/usr/etc/nginx/nginx.conf
```

注：当前这份配置让 3000 端口直接提供 Flutter Web 静态文件，并把 `/api/v1/` 反代到 `127.0.0.1:8000`，所以登录请求会到真正的后端。

当前部署方式是：

- `3000` 作为公网入口
- `/` 提供 Flutter Web
- `/api/v1/` 反代到后端 `127.0.0.1:8000`
- `/blog`、`/_next`、`/blog-media`、`/robots.txt`、`/sitemap.xml` 反代到博客服务链路

### Next.js 公共博客部署

运行命令：

```bash
cd /data/data/com.termux/files/home/apps/mavra-monitor-system/blog-frontend
cp -r .next/static .next/standalone/.next/
if [ -d public ]; then cp -r public .next/standalone/; fi
tmux new-session -d -s mavra-blog 'cd /data/data/com.termux/files/home/apps/mavra-monitor-system/blog-frontend/.next/standalone && env NODE_ENV=production HOSTNAME=0.0.0.0 PORT=3001 BLOG_PUBLIC_BASE_URL=http://192.168.1.13:3000 BLOG_API_BASE_URL=http://127.0.0.1:8000/api/v1 BLOG_BACKEND_ORIGIN=http://127.0.0.1:8000 NEXT_PUBLIC_BLOG_BASE_URL=http://192.168.1.13:3000 node server.js'
```

## 一键启动脚本

手机上常用启动脚本：

```bash
cd ~/apps/mavra-monitor-system
bash scripts/start_termux_stack.sh
```

脚本内容：

- 用 `tmux` 启动 Redis
- 用 `tmux` 启动 PostgreSQL
- 用 `tmux` 启动后端 `uvicorn`
- 用 `tmux` 启动 Next.js 博客
- 校验并重载 Nginx，让 Nginx 提供 Flutter Web 静态文件和统一入口反代

## 如何验证

- PostgreSQL 和 Redis 连接正常
- Termux 远端仓库 HEAD 是 `59d83e8d12003e95e65591c1e82e00fcf6a1aebb`
- `tmux ls` 中存在 `mavra-backend`、`mavra-blog`、`postgresql`、`redis`
- 后端健康检查：`GET http://127.0.0.1:8000/health` 返回 `200 OK`
- 统一入口首页：`GET http://192.168.1.13:3000/` 返回 `200 OK`
- Blog 首页：`GET http://192.168.1.13:3000/blog` 返回 `200 OK`
- Blog API：`GET http://192.168.1.13:3000/api/v1/blog/posts?limit=1` 返回 `200 OK`
- Blog 的 CSS、JS、`robots.txt`、`sitemap.xml` 继续由统一入口提供
