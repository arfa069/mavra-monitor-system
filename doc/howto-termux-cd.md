# howto-termux-cd

> 说明如何把 GitHub Actions 持续部署接到局域网内的 Termux 手机服务器。

## 目标

当前方案的目标是：

- 不把手机服务器暴露到公网；
- 继续沿用现有 GitHub Actions 质量门；
- 只有 `main` 上通过质量门的提交，才会自动发布到 `192.168.1.13:3000`。

## GitHub 侧准备

先在仓库里配置一个环境：

```text
Environment: production-termux
```

然后确认 Windows 自托管 runner 已经在线，并带有这些 labels：

```text
self-hosted
Windows
mavra-deploy
```

环境变量和 Secrets 需要配置为：

```text
Variables:
  TERMUX_HOST=192.168.1.13
  TERMUX_PORT=8022
  TERMUX_USER=u0_a323
  TERMUX_APP_DIR=/data/data/com.termux/files/home/apps/mavra-monitor-system
  TERMUX_KNOWN_HOSTS=<ssh-keyscan result for 192.168.1.13:8022>

Secrets:
  TERMUX_SSH_KEY=<deployment private key>
```

注意：

- `TERMUX_KNOWN_HOSTS` 应直接保存 `ssh-keyscan` 的结果，用来固定主机指纹。
- `TERMUX_SSH_KEY` 只放 GitHub Secret，不写进仓库或脚本。

## Runner 要做什么

`deploy-termux` 任务只会在以下条件同时成立时执行：

- 事件是 `push`
- 分支是 `main`
- 六个前置任务都成功：
  - `lint`
  - `test`
  - `compile`
  - `api-contract`
  - `flutter-web-fast`
  - `blog`

通过后，Windows runner 会执行：

```powershell
./scripts/deploy_termux_from_runner.ps1
```

这个脚本会：

1. 写入临时 SSH key 和 `known_hosts` 到 runner 临时目录；
2. 下载 GitHub Actions 已经构建好的 Flutter Web / Blog artifact；
3. 通过 `scp` 把压缩包和远端部署脚本上传到手机服务器的 `.deploy/incoming/<sha>`；
4. 通过 `ssh` 调用 `.deploy/incoming/<sha>/deploy_termux_remote.sh <sha>`；
6. 删除本地临时 SSH 文件。

## 手机服务器要做什么

远端部署脚本的职责是：

1. 检查目标 SHA 是否存在；
2. 拒绝覆盖有未提交改动的远端仓库；
3. `git fetch origin main` 并切到精确的 commit；
4. 解压并校验上传的 `tar.gz` 产物齐全；
5. 备份数据库和现有静态产物到 `.deploy/backups/<timestamp>-<sha>`；
6. 替换 Flutter Web / Blog 产物；
7. 运行 `python -m alembic upgrade head`；
8. 重启 `mavra-backend` 和 `mavra-blog`，再调用 `scripts/start_termux_stack.sh`；
9. 检查：
   - `http://127.0.0.1:8000/health`
   - `http://127.0.0.1:3000/`
   - `http://127.0.0.1:3000/blog`
   - `nginx -t`
   - `tmux ls`

## 回滚说明

如果健康检查失败，脚本会自动恢复上一个版本的：

- Flutter Web 构建产物
- Blog standalone 产物
- Blog static 产物
- `public` 目录（如果之前存在）

数据库迁移不会自动 downgrade。

如果迁移后需要人工恢复，请根据备份目录里的 `database.sql` 自行处理：

```text
.deploy/backups/<timestamp>-<sha>/database.sql
```

## 日常排查

如果自动部署失败，优先看这几类问题：

1. GitHub 环境变量或 Secret 缺失。
2. 自托管 runner 不在线，或没有 `mavra-deploy` label。
3. 手机 SSH 主机指纹变化，但 `TERMUX_KNOWN_HOSTS` 还是旧值。
4. 远端仓库有未提交改动，被脚本主动拦截。
5. 远端迁移或健康检查失败，触发静态产物回滚。
6. incoming 目录里的压缩包缺失或解压失败。

## 本地静态检查

改完脚本后，可在本地先做最窄验证：

```powershell
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy_termux_from_runner.ps1 -DryRun
bash -n scripts/deploy_termux_remote.sh
rg -n "deploy-termux|production-termux|mavra-deploy|TERMUX_SSH_KEY|concurrency|cancel-in-progress" .github/workflows/ci.yml
```
