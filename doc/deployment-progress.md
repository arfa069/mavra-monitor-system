# 部署进度记录

> 记录当前把 `mavra-monitor-system` 部署到 `192.168.1.13` Termux 手机服务器的进度。
> 这是一份阶段记录，重点回答“做了什么”和“结果如何”。

## 当前结论

后端已经在手机服务器上跑起来，并且通过健康检查验证成功。
Flutter 前端和 Next.js 公共博客也都已经部署到手机服务器上，并能通过浏览器正常打开。

## 前端构建与运行

### Flutter 主前端

构建命令（Windows）：

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/frontend
flutter build web --dart-define=API_BASE_URL=/api/v1
```

运行命令（Termux，建议放进 `tmux` 常驻）：

```bash
tmux new-session -d -s mavra-frontend 'cd /data/data/com.termux/files/home/apps/mavra-monitor-system/frontend/build/web && python -m http.server 3000 --bind 0.0.0.0'
```

### Next.js 公共博客

构建命令（Windows）：

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system/blog-frontend
npm ci
$env:BLOG_PUBLIC_BASE_URL="http://192.168.1.13:3001"
$env:BLOG_API_BASE_URL="http://127.0.0.1:8000/api/v1"
$env:BLOG_BACKEND_ORIGIN="http://127.0.0.1:8000"
$env:NEXT_PUBLIC_BLOG_BASE_URL="http://192.168.1.13:3001"
npm run build
```

运行命令（Termux，建议放进 `tmux` 常驻）：

```bash
cd /data/data/com.termux/files/home/apps/mavra-monitor-system/blog-frontend
cp -r .next/static .next/standalone/.next/
if [ -d public ]; then cp -r public .next/standalone/; fi
tmux new-session -d -s mavra-blog 'cd /data/data/com.termux/files/home/apps/mavra-monitor-system/blog-frontend/.next/standalone && env NODE_ENV=production HOSTNAME=0.0.0.0 PORT=3001 BLOG_PUBLIC_BASE_URL=http://192.168.1.13:3001 BLOG_API_BASE_URL=http://127.0.0.1:8000/api/v1 BLOG_BACKEND_ORIGIN=http://127.0.0.1:8000 NEXT_PUBLIC_BLOG_BASE_URL=http://192.168.1.13:3001 node server.js'
```

说明：

- 博客刚开始只跑通了 HTML，`/_next/static/...` 一度返回 404。
- 现已把 `.next/static` 补进 `standalone` 运行目录，所以样式和脚本都能正常加载。

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
   - 博客使用 `npm run build` 后在 `standalone` 目录运行 `node .next/standalone/server.js`
   - 博客静态资源需要同步到 `.next/standalone/.next/static`

## 结果

- 健康检查返回：`{"status":"healthy"}`
- Uvicorn 日志显示应用启动完成
- PostgreSQL 和 Redis 连接正常
- 当前后端服务已在远端常驻运行
- Flutter Web 构建产物已上传到手机服务器
- 前端静态站点可通过 `http://192.168.1.13:3000` 访问
- 后端已放行 `http://192.168.1.13:3000` 的 CORS 来源
- Next.js 博客已在手机服务器上构建并启动
- 博客可通过 `http://192.168.1.13:3001/blog` 访问
- 后端已放行 `http://192.168.1.13:3001` 的 CORS 来源
- 博客的 CSS 和 JS 静态资源现在可以正常加载，不再出现 `/_next/static` 404

## 说明

- 本地 Windows 仓库已经恢复干净，没有保留这些 Termux 兼容改动。
- 远端手机服务器保留的是能正常启动的部署版本，用于当前在线服务。

## 下一步

前端部署已经完成，下一步可以继续做：

1. 验证登录、首页、博客列表和文章详情页的实际交互。
2. 如果后续需要，还可以把手机端静态站改成更正式的反代或常驻脚本。
