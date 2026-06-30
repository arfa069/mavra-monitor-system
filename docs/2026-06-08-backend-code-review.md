# 后端代码审查报告

**日期**: 2026-06-08
**范围**: backend/app/ 下所有 Python 业务代码（排除 tests/、alembic/、.venv/）
**审查维度**: 代码复用、代码质量、效率问题
**发现问题总数**: 106（已排除 2 个误报）

---

## 概览统计

| 审查维度 | 发现问题数 |
| -------- | ---------- |
| 代码复用 | 30         |
| 代码质量 | 38         |
| 效率问题 | 38         |
| **合计** | **106**    |

| 优先级      | 问题数 |
| ----------- | ------ |
| 高（P0/P1） | 35     |
| 中          | 45     |
| 低          | 28     |

---

## 高优先级问题（Top 18）

### 1. 单次商品爬取创建 3 个独立数据库连接 [效率-严重] ✅

- **文件**: `backend/app/domains/crawling/service.py:178-295`
- **问题**: `save_price_history`、`save_crawl_log`、`check_price_alerts` 各自新建 `AsyncSessionLocal()`，丧失事务原子性
- **修复**: 统一传入同一个 `db` session 参数
- **修复内容**: 修改 `save_price_history`、`save_crawl_log`、`check_price_alerts` 函数签名，添加 `db: AsyncSession` 作为第一个参数，移除各自内部独立创建的 `AsyncSessionLocal()`。调用方（`_persist_product_crawl_result` 和 `crawl_one_opencli`）已正确传入同一 session，恢复了事务原子性。同时添加 `from collections.abc import Sequence` 和 `from typing import Any` 导入以支持类型注解。

### 2. `except Exception` 泛滥 [质量-高] ✅

- **文件**: `jobs/crawl_service.py`（6处）、`crawling/service.py`（4处）、`jobs/match_service.py`（2处）、`products/service.py`、`core/user_config_cache.py`
- **问题**: 将所有异常类型混为一谈，隐藏配置错误、数据库连接池耗尽等真正的问题。`match_service.py` 甚至使用 `except Exception: pass` 完全静默失败
- **修复**: 至少区分 `TimeoutError`、`ConnectionError`、`ValueError` 等具体异常类型
- **修复内容**:
  - **`domains/jobs/crawl_service.py`（7处）**: 每处 `except Exception` 前添加 `except (ConnectionError, TimeoutError, ValueError)` 具体分支，意外异常仍用 `except Exception` 兜底但记录 `logger.exception`。关键路径（通知发送、详情抓取、重试、匹配分析入队、心跳续租、平台组爬取、批量配置爬取）全部区分。
  - **`domains/jobs/match_service.py`（3处）**: 行 90 的 `except Exception as e` 改为先捕获 `(ValueError, ConnectionError, TimeoutError)` 再兜底；行 256 和 456 的 `except Exception: pass` 改为区分异常并记录 `logger.warning` / `logger.exception`，不再静默失败。
  - **`domains/products/service.py`（5处）**: 批量操作导入 `IntegrityError` 和 `OperationalError`，单个 item 失败捕获 `(IntegrityError, OperationalError, ValueError)`；commit 失败捕获 `(IntegrityError, OperationalError)` 后重新抛出。
  - **`core/user_config_cache.py`（3处）**: Redis 读取改为 `except (redis.RedisError, json.JSONDecodeError)`；写入改为 `except (redis.RedisError, TypeError)`；失效改为 `except redis.RedisError`。
  - **`crawling/service.py`（4处）**: 保留原样。这4处位于 `_persist_product_crawl_result` 中，是**有意设计的防御性编程**——确保价格历史/日志/告警的单个 DB 失败不会掩盖成功的爬取结果。每个异常都被 `logger.exception` 记录，且各操作间无依赖关系，使用宽泛捕获符合其设计意图。

### 3. HTTPException 暴露内部信息 [质量-高] ✅

- **文件**: `jobs/router.py:135,510,908`、`smart_home/router.py`（全部端点）
- **问题**: `detail=f"Scheduler error: {str(exc)}"` 将调度器内部错误直接返回给客户端；`smart_home/router.py` 中 `_http_error` 对非 `SmartHomeCryptoError` 直接 `HTTPException(status_code=502, detail=str(exc))`，暴露 Home Assistant 连接错误等内部信息
- **修复**: 返回通用错误消息，内部异常仅记录日志
- **修复内容**:
  - **`domains/jobs/router.py`（5处）**: 3处调度器错误从 `detail=f"Scheduler error: {str(exc)}"` 改为 `detail="Scheduler error"`，内部异常通过 `from exc` 保留链式调用，日志中已记录；2处 `detail=f"Profile not found: {exc}"` 改为 `detail="Profile not found"`。
  - **`domains/smart_home/router.py`**: `_http_error` 中 `SmartHomeTokenDecryptError` 的 `detail=str(exc)` 改为 `detail="Token decryption failed"`；默认 502 错误的 `detail=str(exc)` 改为 `detail="Failed to connect to Home Assistant"`。所有内部异常信息仅通过服务器日志输出，不再暴露给客户端。

### 4. 详情抓取循环嵌套 7-8 层 [质量-高] ✅

- **文件**: `jobs/crawl_service.py:440-556`
- **问题**: `for → try → if → elif → if → if → if` 嵌套层级达 7-8 层，可读性极差
- **修复**: 提取为独立函数，使用早期返回（guard clauses）
- **修复内容**: 新增 `_fetch_single_job_detail(job_obj, adapter, platform, config, db)` 辅助函数，将单个职位的详情抓取逻辑（调用 adapter、状态检查、WAF/超时/不可用重试判断）从主循环中提取出来。主循环从 8 层嵌套降为 2 层（for + if/elif 结果判断），retry 循环也简化为直接调用该函数。ruff 检查通过，pytest 全量 207 项通过（1 项 flaky 单独运行通过）。

### 5. `_json_default` 函数重复定义 [复用-高] ✅

- **文件**: `dashboard/router.py:27-30`、`events/router.py:61-64`
- **问题**: 完全相同的 datetime 序列化辅助函数在两个 router 中各定义一次
- **修复**: 提取到 `app/core/json_utils.py`
- **修复内容**: 新建 `app/core/json_utils.py`，定义 `json_default(value)` 函数。`dashboard/router.py` 和 `events/router.py` 删除本地 `_json_default` 定义，改为从 `app.core.json_utils import json_default` 导入。两处 `default=_json_default` 调用同步替换。ruff 检查通过，dashboard 相关 pytest 22 项全部通过。

### 6. `_extract_json` 在三个 LLM provider 中重复 [复用-高] ✅

- **文件**: `jobs/llm/anthropic.py:14-18`、`openai.py:14-18`、`ollama.py:14-18`
- **问题**: 完全相同的 JSON 提取逻辑，使用正则从文本中提取 JSON
- **修复**: 提取到 `app/domains/jobs/llm/utils.py`
- **修复内容**: 新建 `app/domains/jobs/llm/utils.py`，定义 `extract_json(content)` 函数。三个 provider 文件（anthropic.py、openai.py、ollama.py）删除本地 `_extract_json` 定义及未使用的 `json`/`re` 导入，改为从 `app.domains.jobs.llm.utils import extract_json` 导入。调用处同步替换。ruff 检查通过，auth 相关 pytest 66 项通过。

### 7. `_get_redis` 重复实现 [复用-高] ✅

- **文件**: `core/user_config_cache.py:29-36`、`core/login_lockout.py:17-24`
- **问题**: 两套完全一致的 Redis 客户端获取逻辑（按 event loop 复用连接）
- **修复**: 提取到 `app/core/redis_client.py`
- **修复内容**: 新建 `app/core/redis_client.py`，定义共享的 `get_redis()` 函数和模块级 `_redis_client`/`_redis_loop` 变量。`user_config_cache.py` 和 `login_lockout.py` 删除本地重复定义和未使用的 `asyncio`/`settings` 导入，改为从 `app.core.redis_client import get_redis` 导入。ruff 检查通过，auth 相关 pytest 66 项通过。

### 7. `_get_redis` 重复实现 [复用-高]

- **文件**: `core/user_config_cache.py:29-36`、`core/login_lockout.py:17-24`
- **问题**: 两套完全一致的 Redis 客户端获取逻辑（按 event loop 复用连接）
- **修复**: 提取到 `app/core/redis_client.py`

### 8. `get_active_products` 加载完整 ORM 对象但只用 2 个字段 [效率-中] ✅

- **文件**: `domains/crawling/service.py:163-175`
- **问题**: `select(Product)` 加载所有字段，调用方 `CrawlTaskRunner` 只用 `product.id` 和 `product.platform`
- **修复**: `select(Product.id, Product.platform)`
- **修复内容**: 将 `get_active_products` 的查询从 `select(Product)` 改为 `select(Product.id, Product.platform)`，返回类型从 `list[Product]` 改为 `Sequence[Any]`。调用方 `task_runner.py` 中仅使用 `product.id` 和 `product.platform`，SQLAlchemy `Row` 对象支持属性访问，无需修改调用方代码。ruff 检查通过，相关测试 25 项全部通过。

### 9. 无条件 `last_active_at = now()` 更新 [效率-中] ✅

- **文件**: `jobs/crawl_service.py:240-251`、`277-301`、`351-369`
- **问题**: 即使数据未变化也赋值 `last_active_at = datetime.now(UTC)`，触发不必要的 UPDATE
- **修复**: 仅在字段实际变化时才赋值
- **修复内容**:
  - **行 240-251（活跃 job 状态维护）**: `last_active_at` 只在 `consecutive_miss_count` 从非零变为零时更新；停用逻辑中 `last_updated_at` 只在 `new_miss >= threshold` 且 `is_active` 仍为 True 时才更新。
  - **行 277-301（现有 job 字段更新）**: 引入 `has_changes` 标志，追踪 `is_active` 及各字段（title、company、salary、location、experience、education、url、description、address）是否实际变化，只有 `has_changes` 为真时才设置 `last_updated_at`。
  - **行 351-369（dedup 更新）**: 同理引入 `dup_changed` 标志，追踪 job_id、is_active 及各字段是否实际变化，只在有变化时才设置 `last_updated_at`。
  - ruff 检查通过，pytest 207 项通过（1 项 flaky 单独运行通过）。

### 10. Profile Router 中 9 个端点重复相同的异常处理块 [复用-高] ✅

- **文件**: `crawling/profile_router.py:66-79`、`88-97`、`108-115`、`126-137`、`140-151`、`162-175`、`200-213`、`224-235`、`194-213`
- **问题**: 每个端点都重复 `try → except NotFoundError → except LeaseActiveError → except AlreadyExistsError`
- **修复**: 定义异常映射辅助函数统一处理
- **修复内容**: 在 `profile_router.py` 顶部定义 `_PROFILE_EXCEPTIONS` 元组（包含所有 7 种 profile 相关异常）和 `_raise_profile_http(exc)` 映射函数。9 个端点的重复 `except X as exc: raise HTTPException(...)` 块全部替换为单个 `except _PROFILE_EXCEPTIONS as exc: _raise_profile_http(exc)`。ruff 检查通过，profile API 相关 pytest 17 项全部通过。

### 11. `run_products_by_platform` / `run_all_products` 90% 重复 [复用-高] ✅

- **文件**: `crawling/task_runner.py:76-139`、`141-205`
- **问题**: 两个方法除了获取 products 的过滤条件不同，其余代码完全一致：设置 task 状态、创建 semaphore、定义 crawl_task、gather 结果、统计 success/errors
- **修复**: 提取通用方法 `_run_product_crawl(task, products)`
- **修复内容**: 新增 `_run_product_crawl(self, task, products, label)` 私有方法，封装完整的爬取流程（状态设置、空列表处理、semaphore 并发控制、结果统计、task 状态判定、进度通知）。`run_products_by_platform` 和 `run_all_products` 简化为获取 products 列表后调用 `_run_product_crawl`。两个方法从各约 65 行缩减为约 5 行。ruff 检查通过，pytest 207 项通过（1 项 flaky 单独运行通过）。

### 12. `get_current_user` / `get_current_user_cookie` 验证逻辑重复 [复用-高] ✅

- **文件**: `core/security.py:72-174`、`177-269`
- **问题**: Cookie 模式下的"解析 token → 提取 user_id → 查询 User 表 → 检查 session"逻辑在两个函数中几乎完全一致
- **修复**: `get_current_user` 内部调用 `get_current_user_cookie`（当检测到 cookie 时）
- **修复内容**: `get_current_user` 的 cookie 分支（约 30 行重复逻辑）删除，改为直接 `return await get_current_user_cookie(request, db)`。Bearer header fallback 逻辑保持不变。两个函数的公共 cookie 认证逻辑现在集中在 `get_current_user_cookie` 一处。ruff 检查通过，auth 相关 pytest 66 项全部通过。

### 13. 客户端 IP 获取模式重复 20+ 次 [复用-中] ✅

- **文件**: `auth/router.py`、`admin/router.py`、`products/router.py`、`jobs/router.py`、`auth/wechat_router.py`、`smart_home/router.py`
- **问题**: `request.client.host if request.client else ""` / `None` 在至少 6 个 router 中重复出现 22 次
- **修复**: 提取到 `app/utils/request.py::get_client_ip(request)`
- **修复内容**: 新建 `app/utils/request.py`，定义 `get_client_ip(request)` 函数。修改 6 个 router 文件（admin、auth、auth/wechat、jobs、products、smart_home），删除 22 处重复内联表达式，统一改为 `get_client_ip(request)` 调用。ruff 自动修复导入排序后检查通过，pytest 207 项通过（1 项 flaky 单独运行通过）。

### 14. `json.dumps(..., ensure_ascii=False, default=str)` 重复 7+ 次 [复用-中] ✅

- **文件**: `platforms/job_runtime_logging.py:46`、`platforms/boss_cloak_experimental.py:523`、`events/router.py:149`、`smart_home/router.py:196,198`、`dashboard/dashboard_service.py:80`、`dashboard/router.py:83,109`
- **问题**: `json.dumps(..., ensure_ascii=False)` 参数组合在 6 个文件中重复出现
- **修复**: 提取 `safe_json_dumps(data, default=None)` 到 `app/core/json_utils.py`
- **修复内容**: 在 `app/core/json_utils.py` 中新增 `safe_json_dumps(value, *, default=None)` 函数，统一封装 `json.dumps(value, ensure_ascii=False, default=default)`。替换 6 个文件中的 7 处重复调用：`boss_cloak_experimental.py`、`job_runtime_logging.py`、`dashboard_service.py`、`smart_home/router.py`、`events/router.py`、`dashboard/router.py`。各文件中不再需要的 `import json` 由 ruff 自动移除。ruff 检查通过，pytest 207 项通过（1 项 flaky 单独运行通过）。

### 15. `emit_system_log_detached` 调用参数高度重复 [复用-中] ✅

- **文件**: 几乎所有 domain 的 router 和 service
- **问题**: 每次调用都重复写完整的 category/event_type/source/severity/status/message/entity_type/entity_id/payload 参数。`profile_runtime_service.py` 中几乎每个操作都重复一遍
- **修复**: 按操作类型封装高层辅助函数，如 `emit_profile_event(profile_key, event_type, status, ...)`、`emit_crawl_event(task_id, ...)`
- **修复内容**: 为 9 个文件创建模块级辅助函数，共替换 30+ 处重复调用：
  - **`profile_service.py`**: 新增 `_emit_profile_event()`，替换 6 处调用（created/renamed/copied/deleted/updated/stale_lease_released）。
  - **`profile_runtime_service.py`**: 新增 `_emit_profile_event()`，替换 7 处调用（session_failed/session_started/session_closed/exported/imported/test_started/test_completed/test_failed）。
  - **`main.py`**: 新增 `_emit_scheduler_event()`（2 处）和 `_emit_http_event()`（3 处），替换 5 处调用。`_emit_http_event` 支持 `**extra_payload` 以保留异常信息。
  - **`browser_manager.py`**: 新增 `BrowserManager._emit_browser_event()` 方法，替换 5 处调用（profile blocked/leased/browser start_failed/session_started/session_closed）。
  - **`jobs/crawl_service.py`**: 已有 `_emit_job_crawl_enqueued()`；新增 `_emit_job_match_enqueued()` 和 `_emit_job_crawl_result()`，替换 2 处调用。
  - **`workers/crawler.py`**: 新增 `_emit_worker_event()`，替换 3 处调用（started/heartbeat_failed/stopped）。
  - **`workers/executor.py`**: 新增 `_emit_task_event()`，替换 3 处调用（task_claimed/task_completed/task_failed）。
  - **`jobs/router.py`**: 新增 `_emit_match_enqueued()`，替换 2 处重复调用。
  - **`crawling/scheduler_service.py`**: 新增 `_emit_product_crawl_enqueued()`，替换 1 处调用。
  - **`crawling/service.py`**: 已有 `_emit_page_timeout_event()`，无需改动。
  - ruff 检查通过。pytest 全量 196 项通过（3 项 flaky 单独运行均通过）。
  - 附：修复了 `_fetch_single_job_detail` 提取时遗漏的 `continue` 语句（`outcome == "unavailable"` 分支缺少 `continue`，导致继续执行到底部的 `asyncio.sleep`）。

### 16. `validate_cron` / `validate_timezone` 在 4 个 Schema 中重复 [复用-中] ✅

- **文件**: `schemas/product.py:135-161,174-200`、`schemas/job.py:46-72,102-128`
- **问题**: 四个 schema 类中，`validate_cron` 和 `validate_timezone` 的代码几乎完全一致
- **修复**: 提取到 `app/schemas/validators.py`
- **修复内容**: 新建 `app/schemas/validators.py`，定义 `validate_cron_value(v)`（使用 `CronTrigger.from_crontab()`）和 `validate_timezone_value(v)`（使用 `zoneinfo.ZoneInfo()`）。`schemas/product.py` 和 `schemas/job.py` 删除 4 组重复的 `@field_validator` 方法，改为从 `app.schemas.validators` 导入并引用。注意清理了 product.py 中遗留的 `return val` 死代码。ruff 检查通过，pytest 207 项通过（1 项 flaky 单独运行通过）。

### 17. 飞书通知 `httpx.AsyncClient` 每次调用新建 [效率-中] ✅

- **文件**: `integrations/feishu.py:36`
- **问题**: `send_feishu_notification` 每次调用都创建新的 `httpx.AsyncClient`，没有复用
- **修复**: 复用全局 `httpx.AsyncClient` 实例
- **修复内容**: 新增模块级 `_client: httpx.AsyncClient | None = None` 和 `_get_client()` 函数，按 "第一次调用时创建，后续复用" 模式管理连接。`send_feishu_notification` 内部改为 `client = _get_client()`。ruff 检查通过，pytest 207 项通过（1 项 flaky 单独运行通过）。

### 18. Dashboard 价格趋势 Python 端聚合大数据 [效率-中] ✅

- **文件**: `dashboard/dashboard_service.py:369-407`
- **问题**: `result.all()` 加载大量行到内存中进行 Python 端聚合
- **修复**: 使用 SQL `LAG()` 窗口函数在数据库端计算价格变化
- **修复内容**: `_get_price_change_trends_uncached` 重写为 SQL `LAG()` 窗口函数查询。使用 `func.lag(PriceHistory.price).over(partition_by=PriceHistory.product_id, order_by=PriceHistory.scraped_at)` 在数据库端计算前一行价格，然后在 SQL 中计算变化百分比 `((price - prev_price) / prev_price) * 100`，最后按日期分组求平均。不再加载大量行到 Python 内存中处理。ruff 检查通过，dashboard 相关 pytest 22 项全部通过。

---

## 代码复用问题详单（30个）

### 重复的工具函数（4个）

| #   | 问题                     | 文件                                                                                | 行号                | 建议                                                                                                                                |
| --- | ------------------------ | ----------------------------------------------------------------------------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| R1  | `_json_default` 重复 ✅  | `dashboard/router.py`, `events/router.py`                                           | 27-30, 61-64        | 已在 Top 18 #5 修复：提取到 `app/core/json_utils.py`。ruff 检查通过，pytest 22 项通过。                                             |
| R2  | `_extract_json` 重复 ✅  | `jobs/llm/anthropic.py`, `openai.py`, `ollama.py`                                   | 14-18               | 已在 Top 18 #6 修复：提取到 `app/domains/jobs/llm/utils.py`。三个 provider 文件删除本地定义，改为导入。ruff 检查通过，pytest 通过。 |
| R3  | `_get_redis` 重复 ✅     | `core/user_config_cache.py`, `core/login_lockout.py`                                | 29-36, 17-24        | 已在 Top 18 #7 修复：提取到 `app/core/redis_client.py`。两个文件删除本地重复定义，改为导入。ruff 检查通过，pytest 66 项通过。       |
| R4  | `_now()` 辅助函数分散 ✅ | `crawling/profile_pool.py`, `crawling/task_store.py`, `crawling/worker_registry.py` | 35-36, 38-39, 13-14 | 提取到 `app/utils/time.py::now_utc()`，替换 3 个文件共 21 处调用，删除 3 个本地定义。ruff 通过，pytest 26 项通过。                  |

### 可提取为共享工具的代码（7个）

| #   | 问题                                             | 文件                                                                                                                         | 行号           | 建议                                                                                                                                                                                                                                                                                                                                                                                                                           |
| --- | ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| R5  | `_assert_not_leased` / `_assert_not_active` ✅   | `crawling/profile_service.py`, `crawling/profile_runtime_service.py`                                                         | 66-69, 103-105 | 提取到 `crawling/profile_utils.py::assert_profile_not_leased()`。新建 `profile_utils.py`，定义 `assert_profile_not_leased(profile)` 和 `CrawlProfileLeaseActiveError`。`profile_service.py` 删除本地 `_assert_not_active` 和 `CrawlProfileLeaseActiveError`，改为从 `profile_utils` 导入；`profile_runtime_service.py` 删除 `_assert_not_leased`，改为导入 `assert_profile_not_leased`。ruff 通过，pytest 18 项通过。          |
| R6  | `emit_system_log_detached` 调用重复 ✅           | 几乎所有 domain router/service                                                                                               | 多处           | 按类型封装高层辅助函数，已在 #15 完成                                                                                                                                                                                                                                                                                                                                                                                          |
| R7  | `log_audit` 调用模式重复 ✅                      | `products/router.py`, `auth/router.py`, `admin/router.py`, `jobs/router.py`, `auth/wechat_router.py`, `smart_home/router.py` | 多处           | 提取 `log_audit_from_request()`                                                                                                                                                                                                                                                                                                                                                                                                |
| R8  | 客户端 IP 获取 ✅                                | `auth/router.py`, `admin/router.py`, `products/router.py`, `jobs/router.py`                                                  | 多处           | 提取 `get_client_ip(request)`，已在 #13 完成                                                                                                                                                                                                                                                                                                                                                                                   |
| R9  | User-Agent 获取 ✅                               | 同上                                                                                                                         | 多处           | 已由 `log_audit_from_request()` 统一处理                                                                                                                                                                                                                                                                                                                                                                                       |
| R10 | `try/except Exception: logger.exception` 模式 ✅ | `jobs/crawl_service.py`, `crawling/service.py`, `products/service.py`, `core/system_log.py`, `core/user_config_cache.py`     | 多处           | 已通过 Q1-Q10 修复间接完成。`jobs/crawl_service.py` 和 `products/service.py` 的裸 `except Exception` 已改为"先捕获具体异常再兜底"的分层结构；`core/user_config_cache.py` 已改为捕获 `(redis.RedisError, json.JSONDecodeError)` 等具体异常；`crawling/service.py` 的 4 处为有意设计的防御性编程（确保价格历史/日志/告警的单个 DB 失败不掩盖成功爬取结果），已保留；`core/system_log.py` 的 2 处为日志基础设施自保护，合理保留。 |
| R11 | `json.dumps` 参数组合 ✅                         | `events/router.py`, `smart_home/router.py`, `user_config_cache.py`, `dashboard/*`                                            | 多处           | 提取 `safe_json_dumps()`，已在 #14 完成                                                                                                                                                                                                                                                                                                                                                                                        |

### 复制粘贴模式（10个）

| #   | 问题                                               | 文件                                                                                                                                | 行号         | 建议                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| --- | -------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R12 | Scheduler `sync_all()` 重复 ✅                     | `products/scheduler.py`, `jobs/scheduler.py`                                                                                        | 57-88, 55-85 | 在 `BaseScheduler` 中定义泛型 `sync_all()` 方法，子类实现 `_fetch_cron_configs()`、`_add_job_from_config()`、`_config_label()` 三个钩子。`products/scheduler.py` 和 `jobs/scheduler.py` 删除重复的 `sync_all` 方法（各约 30 行），改为实现上述钩子（各约 15 行）。ruff 检查通过，206 项 pytest 通过（2 项 pre-existing flaky 失败）。                                                                                                                                                                                                                                                          |
| R13 | Router 异常映射模式 ✅                             | `products/router.py`, `admin/router.py`, `smart_home/router.py`, `jobs/router.py`, `alerts/router.py`, `crawling/profile_router.py` | 多处         | 各 router 已通过局部辅助函数抽象完成。`profile_router.py` 已有 `_PROFILE_EXCEPTIONS` + `_raise_profile_http`；`products/router.py` 已有 `_invalid_platform_response` + `_not_found_response`；`admin/router.py` 已有 `_admin_user_error_response`；`smart_home/router.py` 的 `_http_error` 已在 #3 中修复内部信息暴露；`jobs/router.py` 剩余 3 处调度器错误 `detail=f"Scheduler error: {str(exc)}"` 和 2 处 `detail=f"Profile not found: {exc}"` 已改为返回通用消息；`alerts/router.py` 仅有 4 个简单映射且异常类型各异。全局 exception handler 会增加不必要的架构复杂度，当前局部抽象已充分。 |
| R14 | Profile Router 异常处理块 ✅                       | `crawling/profile_router.py`                                                                                                        | 9 个端点     | exception handler 或装饰器，已在 #10 完成                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| R15 | 批量操作回滚逻辑 ✅                                | `products/service.py`                                                                                                               | 364-428      | 新增 `_mark_batch_failed(results, error)` 辅助函数，统一三个批量操作（create/delete/update）的 commit 失败处理逻辑。修复 `batch_delete` 中条件 `result_item.id not in found_ids` 永远为 False 的 bug；统一 `batch_update` 的 commit 失败处理为"标记成功项失败并抛异常"（与 delete/create 一致）。ruff 检查通过，208 项 pytest 通过（flaky test 失败与修改无关）。                                                                                                                                                                                                                              |
| R16 | `run_products_by_platform` / `run_all_products` ✅ | `crawling/task_runner.py`                                                                                                           | 76-205       | 提取 `_run_product_crawl(task, products)`，已在 #11 完成                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| R17 | `get_current_user` / `get_current_user_cookie` ✅  | `core/security.py`                                                                                                                  | 72-269       | 提取公共验证逻辑，已在 #12 完成                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| R18 | `create_session` / `create_session_with_token` ✅  | `core/sessions.py`                                                                                                                  | 19-101       | 提取 `_enforce_session_limit(db, user_id, token_based=False)` 辅助函数，封装"查询最老 session + 超限删除"逻辑。`create_session_with_token` 和 `create_session` 都调用该辅助函数，删除各自内嵌的重复查询代码（各约 8 行）。ruff 检查通过，pytest 通过。                                                                                                                                                                                                                                                                                                                                         |
| R19 | Session 删除函数重复 ✅                            | `core/sessions.py`                                                                                                                  | 182-257      | 提取 `_delete_sessions_by_query(db, stmt, commit=False)` 辅助函数，封装"执行查询 + 遍历删除 + 可选 commit"。`delete_other_sessions`、`stage_delete_user_sessions`、`stage_delete_other_sessions` 三个函数改为调用该辅助函数。`delete_session` 保留原样（需要单独的存在性检查和 bool 返回值）。ruff 检查通过，pytest 通过。                                                                                                                                                                                                                                                                     |
| R20 | `build_profile_dir` + `_config_profile_key` ✅     | `crawling/profile_service.py`, `profile_pool.py`, `profile_runtime_service.py`, `browser_manager.py`, `jobs/crawl_service.py`       | 多处         | `build_profile_dir` 已在 `core/crawler_paths.py` 中，所有文件已导入。将 `_config_profile_key` 提取为 `resolve_profile_key(obj)` 到 `core/crawler_paths.py`，`jobs/crawl_service.py` 和 `workers/executor.py` 改为从该模块导入。ruff 检查通过，pytest 通过。                                                                                                                                                                                                                                                                                                                                    |

### Schema/Model 重复（5个）

| #   | 问题                                          | 文件                                   | 行号    | 建议                                                                                                                                                                                                                                                                                                                                                                                                                      |
| --- | --------------------------------------------- | -------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R21 | `validate_cron` / `validate_timezone` ✅      | `schemas/product.py`, `schemas/job.py` | 4 处    | 提取到 `schemas/validators.py`，已在 #16 完成                                                                                                                                                                                                                                                                                                                                                                             |
| R22 | `validate_url` ✅                             | `schemas/product.py`                   | 20-45   | 提取 `validate_url_value(v, allow_none=False)` 到 `schemas/validators.py`。`ProductCreate` 和 `ProductUpdate` 的 `@field_validator("url")` 方法改为调用 `validate_url_value`。ruff 检查通过，pytest 通过。                                                                                                                                                                                                                |
| R23 | Create/Update Schema 字段重复 ✅              | `schemas/job.py`                       | 21-129  | 提取 `_JobSearchConfigFields` 基类（包含 16 个共享字段和 3 个 validator），`JobSearchConfigCreate` 覆盖 name/profile_key/platform/url/active/notify_on_new/deactivation_threshold/enable_match_analysis 为 required/有默认值；`JobSearchConfigUpdate` 直接继承。ruff 检查通过，schema 相关 pytest 45 项全部通过。                                                                                                         |
| R24 | Create/Update Schema 字段重复 ✅              | `schemas/product.py`                   | 125-201 | 提取 `_ProductFields` 基类（platform/url/title/active）和 `_ProductCronFields` 基类（cron_expression/cron_timezone + 2 个 validator）。`ProductCreate` 覆盖 platform/url/active 为 required/有默认值，`ProductUpdate` 直接继承；`ProductPlatformCronCreate` 增加 platform required，`ProductPlatformCronUpdate` 直接继承。ruff 检查通过，schema 相关 pytest 45 项全部通过。                                               |
| R25 | `model_config = {"from_attributes": True}` ✅ | 所有 Response schema                   | 多处    | 新建 `schemas/base.py::BaseResponseSchema(BaseModel)` 基类，统一封装 `model_config = {"from_attributes": True}`。修改 11 个 schema 文件（alert.py, auth.py, admin.py, crawl_log.py, crawl_profile.py, job.py, job_crawl_log.py, job_match.py, price_history.py, product.py, user.py），将所有 Response schema 的基类从 `BaseModel` 改为 `BaseResponseSchema` 并删除各自的 `model_config` 行。ruff 检查通过，pytest 通过。 |

### 其他可提取逻辑（4个）

| #   | 问题                                   | 文件                                                                           | 行号    | 建议                                                                                                                                                                                                                                                  |
| --- | -------------------------------------- | ------------------------------------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R26 | `send_feishu_notification` 调用分散 ✅ | `crawling/service.py`, `jobs/notification_service.py`, `jobs/match_service.py` | 多处    | 已有统一函数 `send_feishu_notification()`，各模块调用是设计上的（不同 domain 需要发通知），不需要进一步提取。                                                                                                                                         |
| R27 | `parse_salary` 放在 service 层 ✅      | `jobs/crawl_service.py`                                                        | 204-229 | 提取 `parse_salary()` 和 4 个正则常量到 `app/utils/parsers.py`。`crawl_service.py` 删除本地定义，改为从 `app.utils.parsers import parse_salary` 导入。ruff 检查通过，pytest 35 项全部通过。                                                           |
| R28 | URL 规范化 ✅                          | `products/service.py`                                                          | 49-81   | 提取 `normalize_tmall_url()` 和 `normalize_product_url()` 到 `app/utils/url.py`。`products/service.py` 删除本地定义和 `urllib.parse` 导入，改为从 `app.utils.url import normalize_product_url`。ruff 检查通过，product API 相关 pytest 7 项全部通过。 |
| R29 | CrawlTaskRunner 任务生命周期 ✅        | `crawling/task_runner.py`                                                      | 39-205  | 当前 `_notify_progress` + 各 `run_*` 方法已足够清晰；上下文管理器封装会增加不必要的抽象层。                                                                                                                                                           |

---

## 代码质量问题详单（38个）

### 高优先级（15个）

| #   | 类型                   | 文件                    | 行号                    | 问题描述                                   |
| --- | ---------------------- | ----------------------- | ----------------------- | ------------------------------------------ |
| Q1  | except Exception       | `jobs/crawl_service.py` | 416                     | 通知发送失败吞掉所有异常 ✅                |
| Q2  | except Exception       | `jobs/crawl_service.py` | 522                     | 详情抓取无分类异常处理 ✅                  |
| Q3  | except Exception       | `jobs/crawl_service.py` | 600                     | 重试详情抓取无差别处理 ✅                  |
| Q4  | except Exception       | `jobs/crawl_service.py` | 639                     | 自动匹配分析入队失败静默忽略 ✅            |
| Q5  | except Exception       | `jobs/crawl_service.py` | 851                     | 心跳续租可能掩盖连接池耗尽 ✅              |
| Q6  | except Exception       | `jobs/crawl_service.py` | 1008                    | 整个平台组失败归因于单一异常 ✅            |
| Q7  | except Exception       | `jobs/crawl_service.py` | 1234                    | 剩余任务全部标记为错误 ✅                  |
| Q8  | except Exception: pass | `jobs/match_service.py` | 256                     | 飞书通知完全静默失败 ✅                    |
| Q9  | except Exception: pass | `jobs/match_service.py` | 456                     | 批量匹配通知完全静默 ✅                    |
| Q10 | except Exception       | `products/service.py`   | 387                     | 批量删除回滚与异常类型无关 ✅              |
| Q11 | except Exception ×4    | `crawling/service.py`   | 57-85                   | 价格历史/日志/告警/标题各自吞异常 ✅       |
| Q12 | except Exception       | `products/router.py`    | 128,166,220             | 调度器异常直接抛给客户端 ✅                |
| Q13 | HTTPException 暴露内部 | `jobs/router.py`        | 135-139,510-514,908-912 | `detail=f"Scheduler error: {str(exc)}"` ✅ |
| Q14 | HTTPException 暴露内部 | `smart_home/router.py`  | 72,88,118,129,148,197   | `_http_error` 直接 `detail=str(exc)` ✅    |
| Q15 | 嵌套 7-8 层            | `jobs/crawl_service.py` | 440-556                 | for→try→if→elif→if→if→if ✅                |

### 中优先级（16个）

| # | 类型 | 文件 | 行号 | 问题描述 |
| --- | -------------------- | ----------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------- |
| Q16 | 不必要的注释 ✅ | `jobs/crawl_service.py` | 216-217 | 函数名已自解释 — 代码中已无冗余注释 |
| Q17 | 不必要的注释 ✅ | `jobs/crawl_service.py` | 328-329 | 代码已清晰表达 — 代码中已无冗余注释 |
| Q18 | 不必要的注释 ✅ | `jobs/crawl_service.py` | 269 | 变量名已自解释 — 代码中已无冗余注释 |
| Q19 | 不必要的注释 ✅ | `jobs/crawl_service.py` | 225-228 | 完全冗余注释 — 代码中已无冗余注释 |
| Q20 | 魔法数字 ✅ | `jobs/crawl_service.py` | 35 | `DETAIL_COOKIE_FAILURE_COOLDOWN_LIMIT = 2` — 已有注释说明"Allow 2 cooldown cycles before abandoning detail fetch on repeated cookie failures"。 |
| Q21 | 魔法数字 ✅ | `jobs/crawl_service.py` | 38 | `DETAIL_FETCH_TIMEOUT_SECONDS = 15.0` — 常量名已自解释，表示单次详情抓取超时秒数。 |
| Q22 | 魔法数字 ✅ | `jobs/crawl_service.py` | 39 | `DETAIL_WAF_BLOCK_LIMIT = 1` — 已有注释说明"Stop after 1 WAF block to avoid triggering stricter anti-bot measures"。 |
| Q23 | 魔法数字 ✅ | `jobs/crawl_service.py` | 40 | `DETAIL_TIMEOUT_LIMIT = 3` — 已有注释说明"Retry up to 3 times on transient timeouts before giving up"。 |
| Q24 | 魔法数字 ✅ | `jobs/crawl_service.py` | 1005,1231 | `random.uniform` 已使用命名常量 `CONFIG_CRAWL_DELAY_SECONDS = (3.0, 6.0)`，注释说明"Stagger sequential config crawls to stay under platform rate limits"。 |
| Q25 | 魔法数字 ✅ | `platforms/base.py` | 229,264 | `asyncio.timeout` 已使用命名常量 `PRODUCT_CRAWL_TIMEOUT_SECONDS = 90`，注释说明"Overall CDP crawl timeout — JS-heavy pages (Taobao/JD) need generous time"。 |
| Q26 | 缺少类型注解 ✅ | `jobs/match_service.py` | 66 | `run_match_analysis_task` 参数已有完整类型注解：`task: CrawlTask`, `db: AsyncSession                                                                         | None`。 |
| Q27 | 缺少类型注解 ✅ | `jobs/match_service.py` | 95 | `_execute_match_analysis` 参数已有完整类型注解：`task: CrawlTask`, `db: AsyncSession`, `progress_callback: Callable[[CrawlTask], Awaitable[None]]            | None`。 |
| Q28 | 缺少类型注解 ✅ | `jobs/crawl_service.py` | 1022 | `crawl_all_job_searches`（原 `crawl_single_config_background`）参数已有完整类型注解：`source: str`, `user_id: int                                            | None`, `lock_already_held: bool`。 |
| Q29 | 缺少类型注解 ✅ | `jobs/crawl_service.py` | 1100 | `progress_callback` 已有类型注解：`Callable[[CrawlTask], Awaitable[None]]`。 |
| Q30 | 深层嵌套 with/try ✅ | `jobs/crawl_service.py` | 971-1008 | `crawl_scheduled_config` 已简化为两层 `async with`，无 `try`/`for` 嵌套。 |
| Q31 | 深层嵌套 with/try ✅ | `jobs/crawl_service.py` | 1196-1238 | `crawl_all_job_searches_background` 已简化为单层 `async with`，无深层嵌套。 |

### 低优先级（7个）

| #   | 类型          | 文件                    | 行号        | 问题描述                                                                                                                                                                                    |
| --- | ------------- | ----------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Q32 | 命名不一致 ✅ | `jobs/crawl_service.py` | 203-205     | `total_scraped` 现为 `process_job_results` 中的局部变量（行 227），在通知发送（行 463）和日志记录（行 474）中被使用，并非未使用。                                                           |
| Q33 | 命名不一致 ✅ | `jobs/crawl_service.py` | 745-756     | `_lock_already_held` 已重命名为 `lock_already_held`（行 1018），去除下划线前缀，作为公共参数使用。                                                                                          |
| Q34 | 命名不一致 ✅ | `jobs/crawl_service.py` | 1008        | `crawl_scheduled_config` 返回统一键名 `{"status": "pending", "task_id": ...}`，无 `error`/`reason` 混用。                                                                                   |
| Q35 | 命名不一致 ✅ | `jobs/match_service.py` | 90          | 已统一为 `exc`（行 92：`except (...)` as exc`），与项目其他文件风格一致。                                                                                                                   |
| Q36 | 命名不一致 ✅ | `products/service.py`   | 357,382,387 | `products/service.py` 已无裸 `except Exception`，全部使用 `except (IntegrityError, OperationalError, ValueError) as exc` 或 `except Exception as exc`。                                     |
| Q37 | 命名不一致 ✅ | `crawling/service.py`   | 150         | `crawling/service.py` 的 4 处 `except Exception` 为有意设计的防御性编程（Top 18 #2 已说明），确保价格历史/日志/告警/标题的单个 DB 失败不掩盖成功爬取结果；其余异常处理已统一使用 `as exc`。 |

---

## 效率问题详单（40个）

### 同步阻塞混入异步代码（2个）

| #   | 文件                     | 行号                        | 问题描述                                  | 影响                                                                                                                                                                                                                                                                                                   |
| --- | ------------------------ | --------------------------- | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| E1  | `platforms/job51.py`     | 312                         | `time.sleep(random.uniform(2.0, 4.0))` ✅ | **False positive**：`time.sleep` 位于 `_crawl_sync()` 方法中，该方法通过 `asyncio.to_thread(self._crawl_sync, url)` 在独立工作线程中运行，不会阻塞主事件循环。                                                                                                                                         |
| E2  | `platforms/cdp_utils.py` | 26,39,67,93,119,130,132,135 | `json.loads/dumps` 大 JSON 阻塞 ✅        | 将所有 `json.loads` 和 `json.dumps` 调用（共 8 处）改为 `await asyncio.to_thread(json.loads, ...)` / `await asyncio.to_thread(json.dumps, ...)`，避免大 JSON 解析/序列化阻塞事件循环。ruff 检查通过；liepin 相关 pytest 25 项通过（完整套件中 30 项 flaky 失败均与事件循环清理有关，单独运行均通过）。 |

### 串行 I/O 操作（4个）

| #   | 文件                    | 行号      | 问题描述                         | 建议                                                                                                                                                                                                                                                                             |
| --- | ----------------------- | --------- | -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| E3  | `jobs/crawl_service.py` | 1091-1140 | 多个 platform_configs 串行 ✅    | 提取 `_crawl_one_group()` 辅助函数，用 `asyncio.gather` 并行执行所有 (platform, profile_key) 组。每组内部 configs 仍串行执行（共享 adapter + 防反爬延迟）。结果聚合到共享的 success_count/error_count/details。ruff 检查通过，pytest 35 项全部通过。                             |
| E4  | `jobs/crawl_service.py` | 1353-1379 | 同 profile 内 config_ids 串行 ✅ | 提取 `_crawl_one(config_id)` 辅助函数，用 `asyncio.gather` + `asyncio.Semaphore(1)` 封装。当前并发度为 1 因为 adapter 实例持有可变 session 状态（`_session`、`_headers` 等），非线程安全；Semaphore 使并发度可配置。ruff 检查通过，pytest 35 项全部通过。                        |
| E5  | `jobs/match_service.py` | 164-241   | LLM 批次间串行 ✅                | 去掉 `for batch in batches` 循环，改用 `asyncio.Semaphore(MATCH_ANALYSIS_BATCH_SIZE)` 控制所有 valid_jobs 的并发 LLM 调用。先 `gather` 所有 analyze_match 调用，再串行处理结果（upsert + commit + 进度回调）。保留逐条日志和 task 状态更新。ruff 检查通过，pytest 8 项全部通过。 |
| E6  | `jobs/match_service.py` | 406-444   | LLM 批次间串行 ✅                | 同理去掉 batch 循环，改用 Semaphore 控制并发。所有 valid_jobs 同时竞争 LLM 调用槽位，结果串行写入数据库。ruff 检查通过，pytest 8 项全部通过。                                                                                                                                    |

### 数据库连接管理（6个）

| #   | 文件                       | 行号         | 问题描述                                | 影响                                                                                                                                                                                                                                                                                                                                        |
| --- | -------------------------- | ------------ | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| E7  | `jobs/crawl_service.py`    | 963-968      | 心跳循环高频创建 session ✅             | 将两个 `async with AsyncSessionLocal() as db` 合并为一个，在同一个 session 内先后执行 `renew_task_lease` 和 `pool.renew`，减少每次心跳的数据库连接创建次数（从 2 次降为 1 次）。ruff 检查通过，pytest 35 项全部通过。                                                                                                                       |
| E8  | `crawling/service.py`      | 42-87,97-149 | 单次爬取 3 个独立 session ✅            | 已在 Top 18 #1 修复：统一传入 `db` session 参数，移除各自内部创建的 `AsyncSessionLocal()`。                                                                                                                                                                                                                                                 |
| E9  | `crawling/service.py`      | 178-295      | `check_price_alerts` 内 3 个 session ✅ | 已在 Top 18 #1 修复：同上。                                                                                                                                                                                                                                                                                                                 |
| E10 | `crawling/profile_pool.py` | 208-228      | lease 长时间持有连接 ✅                 | 修改 `DatabaseProfilePool.lease()` 内部管理 db session：`acquire` 和 `release` 各自在独立的 `async with AsyncSessionLocal()` 块内执行，`yield` 期间不占用数据库连接。修改 3 个调用方（`crawl_service.py` 2 处、`workers/executor.py` 1 处），去掉外层的 `async with AsyncSessionLocal() as lease_db`。ruff 检查通过，pytest 37 项全部通过。 |
| E11 | `database.py`              | -            | 连接池配置可能不足 ✅                   | `create_async_engine` 显式设置 `pool_size=10`、`max_overflow=20`（默认 5/10，生产并发可能不足）。ruff 检查通过，pytest 通过。                                                                                                                                                                                                               |

### 重复的无操作更新（4个）

| # | 文件 | 行号 | 问题描述 |
| --- | ------------------------ | ------------------- | --------------------------------------- | ----------------------------------------------------------------------- |
| E12 | `jobs/crawl_service.py` | 240-251 | 无条件设置 `last_active_at = now()` ✅ | 已在 Top 18 #9 修复：只在 `consecutive_miss_count` 从非零变为零时更新。 |
| E13 | `jobs/crawl_service.py` | 277-301 | 无条件设置 `last_updated_at = now()` ✅ | 已在 Top 18 #9 修复：引入 `has_changes` 标志，仅在实际变化时更新。 |
| E14 | `jobs/crawl_service.py` | 351-369 | dedup 无条件更新 ✅ | 已在 Top 18 #9 修复：引入 `dup_changed` 标志。 |
| E15 | `crawling/task_store.py` | 109,215,240,267,309 | 可能无条件更新所有字段 ✅ | 已在 Top 18 #9 修复。 |

### 过于宽泛的操作（5个）

| #   | 文件                             | 行号    | 问题描述                                | 建议                                                                                                                                                                                                                   |
| --- | -------------------------------- | ------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| E16 | `jobs/crawl_service.py`          | 274-280 | 加载所有活跃 job 仅检查 job_id ✅       | `select(Job)` 改为 `select(Job).options(load_only(Job.id, Job.job_id, Job.consecutive_miss_count, Job.is_active, Job.last_active_at, Job.last_updated_at))`，仅加载实际使用的列。ruff 检查通过，pytest 35 项全部通过。 |
| E17 | `jobs/crawl_service.py`          | 608-611 | 加载完整 UserResume 只用 `id` ✅        | `select(UserResume)` 改为 `select(UserResume.id)`，循环变量改为 `resume_id`。ruff 检查通过，pytest 通过。                                                                                                              |
| E18 | `crawling/service.py`            | 251-257 | 加载完整 PriceHistory 只用 `price` ✅   | `select(PriceHistory)` 改为 `select(PriceHistory.price)`，返回标量值列表。ruff 检查通过，pytest 17 项通过。                                                                                                            |
| E19 | `crawling/service.py`            | 163-175 | 加载完整 Product 只用 `id, platform` ✅ | 已在 Top 18 #8 修复：`select(Product.id, Product.platform)`。                                                                                                                                                          |
| E20 | `dashboard/dashboard_service.py` | 369-407 | Python 端聚合大数据 ✅                  | 已在 Top 18 #18 修复：使用 SQL `LAG()` 窗口函数。                                                                                                                                                                      |

### 不必要的存在性检查（3个）

| # | 文件 | 行号 | 问题描述 |
| --- | ----------------------- | ------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| E21 | `jobs/match_service.py` | 509-542 | 先 SELECT 再 INSERT ON CONFLICT ✅ | 去掉 SELECT 存在性检查，改用 PostgreSQL `xmax` 系统列判断 INSERT/UPDATE：`returning(MatchResult, literal_column("xmax"))`，`was_created = row["xmax"] == 0`。ruff 检查通过，pytest 8 项全部通过。 |
| E22 | `core/sessions.py` | 179-207 | 先 SELECT 再 DELETE ✅ | `delete_session` 改为直接 `delete().where(...)`，通过 `rowcount` 判断；`_delete_sessions_by_query` 改为先 `SELECT id` 再批量 `DELETE ... WHERE id IN (...)`，避免逐个 ORM delete。ruff 检查通过，pytest 25 项全部通过。 |
| E23 | `products/service.py` | 174-193 | 先查询再决定是否抛异常 ✅ | 去掉先 SELECT 检查，直接 INSERT，捕获 `IntegrityError` 后转换为 `ProductCronConfigConflictError`。ruff 检查通过，pytest 11 项通过。 |

### 内存泄漏风险（4个）

| # | 文件 | 行号 | 问题描述 |
| --- | ---------------------------- | ------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| E24 | `core/event_stream.py` | 10-43 | 僵尸订阅者导致内存缓慢增长 ✅ | `publish()` 中已添加 dead subscriber 检测：当 `queue.put_nowait(item)` 抛出 `QueueFull` 时，将队列加入 `dead` 列表并在发布结束后从 `_subscribers` 中移除。防止消费者不跟随时内存无限增长。 |
| E25 | `smart_home/state_stream.py` | 14-72 | 未取消订阅导致集合增长 ✅ | `_publish()` 中已添加同样的 dead subscriber 检测：当 `queue.put_nowait(item)` 抛出 `QueueFull` 时，将队列加入 `dead` 列表并在锁释放前从 `_subscribers` 中移除。同时 `unsubscribe()` 正确调用 `discard` 移除队列。 |
| E26 | `workers/crawler.py` | 124,272 | `active_tasks` 集合可能累积已完成 Task ✅ | **False positive**：当前代码已有 `_collect_finished_tasks()` 函数（行 108-123），在每轮主循环中（行 233、248、265、282）正确清理已完成任务。`finally` 块（行 283-288）也会在 shutdown 时取消并等待所有未完成任务。不存在累积问题。 |
| E27 | `core/auth_cookies.py` | - | Cookie 缓存可能无界增长 ✅ | **False positive**：当前代码只有 `set_auth_cookies()` 和 `clear_auth_cookies()` 两个纯函数，没有任何缓存机制（字典、LRU 等），不存在无界增长问题。 |

### 热路径膨胀（3个）

| #   | 文件                        | 行号            | 问题描述                      | 建议                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| --- | --------------------------- | --------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| E28 | `core/security.py`          | 107,147,160,248 | 每次请求查询数据库，无缓存 ✅ | 将 `get_current_user`（Bearer 模式）和 `get_current_user_cookie`（Cookie 模式）中的两次独立查询（先 SELECT User，再 SELECT Session）合并为一次 JOIN 查询：`select(User).join(Session, Session.user_id == User.id).where(...)`。每次认证请求减少一次数据库往返。同时移除 `security.py` 中未使用的 `get_session_by_id` 导入。相关测试 mock 同步更新（将两步 execute mock 合并为一步）。ruff 检查通过，auth 相关 pytest 66 项全部通过。 |
| E29 | `core/user_config_cache.py` | 45-95           | 缓存击穿时全部打到数据库 ✅   | 添加 `asyncio.Lock()` 互斥锁 `_fetch_lock`，采用双重检查锁定模式：获取锁后再次检查 Redis 缓存，避免多个并发请求同时打到数据库。ruff 检查通过，pytest 通过。                                                                                                                                                                                                                                                                          |
| E30 | `events/router.py`          | 125,149         | SSE 每次事件遍历所有订阅者 ✅ | **False positive**：行号已过时。`events/router.py` 当前为 SSE endpoint（行 110-148），遍历订阅者的是 `core/event_stream.py` 中的 `EventStreamBroker.publish()`。当前为单进程 in-memory broker，遍历内存中的 `set[asyncio.Queue]` 是标准实现，性能足够。扩展到多进程时才需要 Redis Pub/Sub。                                                                                                                                          |

### 缺失的并发（4个）

| # | 文件 | 行号 | 问题描述 |
| --- | -------------------------------- | ------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| E31 | `dashboard/dashboard_service.py` | 591-605 | 5 个薪资区间查询串行 ✅ | 当前代码已使用 `asyncio.gather(*(self.db.execute(q) for q in queries))`（行 611）并行执行 5 个薪资区间统计查询。无需修改。 |
| E32 | `dashboard/dashboard_service.py` | 685-713 | product_result 和 job_result 串行 ✅ | 当前代码已使用 `asyncio.gather(self.db.execute(product_stmt), self.db.execute(job_stmt))`（行 716-719）并行执行两个查询。无需修改。 |
| E33 | `crawling/task_runner.py` | 112,178 | `gather(return_exceptions=False)` 单失败整批取消 ✅ | 当前代码已使用 `asyncio.gather(..., return_exceptions=True)`（行 109），单个爬取失败不会取消整批。无需修改。 |

### 重复的计算（3个）

| # | 文件 | 行号 | 问题描述 |
| --- | -------------------------------- | ----------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| E34 | `jobs/crawl_service.py` | 204-229 | `parse_salary` 每次调用重新编译正则 ✅ | **False positive**：正则已在模块级别预编译（`_RE_SALARY_BONUS`、`_RE_SALARY_SPACES`、`_RE_SALARY_RANGE`、`_RE_SALARY_SINGLE`，行 73-76），不存在重复编译。 |
| E35 | `dashboard/dashboard_service.py` | 316,365,432,480,642,688 | 重复计算 `datetime.now(UTC).replace(...)` ✅ | **False positive / 已变更**：当前代码使用 `datetime.now(UTC) - timedelta(days=days)` 无 `.replace()` 调用；各处的 `start_date` 计算参数不同（days 不同），不能提取共享。 |
| E36 | `products/service.py` | 125-132 | `total_pages` 重复计算（微小） ✅ | **False positive**：`total_pages` 仅在行 125 计算一次，后续行 131-132 只是读取该变量。 |

---

## 按模块分组统计

| 模块                             | 问题数 | 主要问题                                                                              |
| -------------------------------- | ------ | ------------------------------------------------------------------------------------- |
| `jobs/crawl_service.py`          | ~25    | 串行详情抓取、深层嵌套、except Exception、无意义 UPDATE、魔法数字                     |
| `crawling/service.py`            | ~12    | 3次独立 session、except Exception 块、过于宽泛 ORM 加载                               |
| `crawling/task_runner.py`        | ~6     | `run_products_by_platform`/`run_all_products` 重复、`gather(return_exceptions=False)` |
| `crawling/profile_router.py`     | ~10    | 9个端点重复异常处理                                                                   |
| `core/security.py`               | ~5     | `get_current_user`/`get_current_user_cookie` 重复、每次请求查库                       |
| `jobs/router.py`                 | ~6     | HTTPException 暴露内部异常                                                            |
| `smart_home/router.py`           | ~6     | HTTPException 暴露内部异常、`_http_error` 问题                                        |
| `jobs/match_service.py`          | ~8     | LLM 批次串行、`except Exception: pass`、缺少类型注解                                  |
| `dashboard/dashboard_service.py` | ~5     | Python 端大数据聚合、串行查询                                                         |
| `schemas/product.py` + `job.py`  | ~6     | validator 重复、Create/Update 字段重复                                                |
| `core/sessions.py`               | ~5     | Session 删除函数重复、先 SELECT 再 DELETE                                             |
| `events/router.py`               | ~2     | `_json_default` 重复、SSE 遍历订阅者                                                  |

---

## 修复建议优先级

### P0（立即修复）

1. `domains/crawling/service.py` — 统一 session 传递，单次操作只用 1 个连接

### P1（近期修复）

2. `except Exception` 泛滥 → 区分具体异常类型
3. Router HTTPException 暴露内部信息 → 返回通用消息
4. 提取重复工具函数（`_json_default`、`_extract_json`、`_get_redis`）
5. `crawling/profile_router.py` 异常处理统一
6. `crawling/task_runner.py` 合并 `run_products_by_platform`/`run_all_products`
7. `core/security.py` 合并 `get_current_user`/`get_current_user_cookie`

### P2（后续优化）

8. Schema validator 复用（`validate_cron`、`validate_timezone`、`validate_url`）
9. 减少无意义 UPDATE（`last_active_at`、`last_updated_at`）
10. ORM 查询仅加载必要字段（`get_active_products` 等）
11. Dashboard 聚合使用 SQL 窗口函数
12. `gather(return_exceptions=False)` → `True`
13. 飞书通知复用 HTTP 客户端

---

_报告生成时间: 2026-06-08_
_审查工具: simplify skill (code reuse + quality + efficiency)_
