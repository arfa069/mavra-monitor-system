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

| #   | 问题                  | 文件                                                 | 行号         | 建议                          |
| --- | --------------------- | ---------------------------------------------------- | ------------ | ----------------------------- |
| R1  | `_json_default` 重复  | `dashboard/router.py`, `events/router.py`            | 27-30, 61-64 | 提取到 `core/json_utils.py`   |
| R2  | `_extract_json` 重复  | `jobs/llm/anthropic.py`, `openai.py`, `ollama.py`    | 14-18        | 提取到 `jobs/llm/utils.py`    |
| R3  | `_get_redis` 重复     | `core/user_config_cache.py`, `core/login_lockout.py` | 29-36, 17-24 | 提取到 `core/redis_client.py` |
| R4  | `_now()` 辅助函数分散 ✅ | `crawling/profile_pool.py`, `crawling/task_store.py`, `crawling/worker_registry.py` | 35-36, 38-39, 13-14 | 提取到 `app/utils/time.py::now_utc()`，替换 3 个文件共 21 处调用，删除 3 个本地定义。ruff 通过，pytest 26 项通过。 |

### 可提取为共享工具的代码（7个）

| #   | 问题                                          | 文件                                                                                                                     | 行号           | 建议                                        |
| --- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | -------------- | ------------------------------------------- |
| R5  | `_assert_not_leased` / `_assert_not_active` ✅ | `crawling/profile_service.py`, `crawling/profile_runtime_service.py`                                                     | 66-69, 103-105 | 提取到 `crawling/profile_utils.py::assert_profile_not_leased()`。新建 `profile_utils.py`，定义 `assert_profile_not_leased(profile)` 和 `CrawlProfileLeaseActiveError`。`profile_service.py` 删除本地 `_assert_not_active` 和 `CrawlProfileLeaseActiveError`，改为从 `profile_utils` 导入；`profile_runtime_service.py` 删除 `_assert_not_leased`，改为导入 `assert_profile_not_leased`。ruff 通过，pytest 18 项通过。 |
| R6  | `emit_system_log_detached` 调用重复           | 几乎所有 domain router/service                                                                                           | 多处           | 按类型封装高层辅助函数                      |
| R7  | `log_audit` 调用模式重复 ✅                   | `products/router.py`, `auth/router.py`, `admin/router.py`, `jobs/router.py`, `auth/wechat_router.py`, `smart_home/router.py` | 多处           | 提取 `log_audit_from_request()`             |
| R8  | 客户端 IP 获取                                | `auth/router.py`, `admin/router.py`, `products/router.py`, `jobs/router.py`                                              | 多处           | 提取 `get_client_ip(request)`               |
| R9  | User-Agent 获取                               | 同上                                                                                                                     | 多处           | 提取 `get_user_agent(request, max_len=512)` |
| R10 | `try/except Exception: logger.exception` 模式 | `jobs/crawl_service.py`, `crawling/service.py`, `products/service.py`, `core/system_log.py`, `core/user_config_cache.py` | 多处           | 提取装饰器 `defensive_call()`               |
| R11 | `json.dumps` 参数组合                         | `events/router.py`, `smart_home/router.py`, `user_config_cache.py`, `dashboard/*`                                        | 多处           | 提取 `safe_json_dumps()`                    |

### 复制粘贴模式（10个）

| #   | 问题                                            | 文件                                                                                                                                | 行号         | 建议                                              |
| --- | ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------------ | ------------------------------------------------- |
| R12 | Scheduler `sync_all()` 重复                     | `products/scheduler.py`, `jobs/scheduler.py`                                                                                        | 57-88, 55-85 | 在 `BaseScheduler` 中定义泛型方法                 |
| R13 | Router 异常映射模式                             | `products/router.py`, `admin/router.py`, `smart_home/router.py`, `jobs/router.py`, `alerts/router.py`, `crawling/profile_router.py` | 多处         | 全局 FastAPI exception handler                    |
| R14 | Profile Router 异常处理块                       | `crawling/profile_router.py`                                                                                                        | 9 个端点     | exception handler 或装饰器                        |
| R15 | 批量操作回滚逻辑                                | `products/service.py`                                                                                                               | 364-428      | 提取 `batch_execute()` 框架                       |
| R16 | `run_products_by_platform` / `run_all_products` | `crawling/task_runner.py`                                                                                                           | 76-205       | 提取 `_run_product_crawl(task, products)`         |
| R17 | `get_current_user` / `get_current_user_cookie`  | `core/security.py`                                                                                                                  | 72-269       | 提取公共验证逻辑                                  |
| R18 | `create_session` / `create_session_with_token`  | `core/sessions.py`                                                                                                                  | 19-101       | `create_session_with_token` 调用 `create_session` |
| R19 | Session 删除函数重复                            | `core/sessions.py`                                                                                                                  | 182-257      | 提取 `_delete_sessions(stmt, db, commit)`         |
| R20 | `build_profile_dir` + `_config_profile_key`     | `crawling/profile_service.py`, `profile_pool.py`, `profile_runtime_service.py`, `browser_manager.py`, `jobs/crawl_service.py`       | 多处         | 提取到 `core/crawler_paths.py`                    |

### Schema/Model 重复（5个）

| #   | 问题                                       | 文件                                   | 行号    | 建议                           |
| --- | ------------------------------------------ | -------------------------------------- | ------- | ------------------------------ |
| R21 | `validate_cron` / `validate_timezone`      | `schemas/product.py`, `schemas/job.py` | 4 处    | 提取到 `schemas/validators.py` |
| R22 | `validate_url`                             | `schemas/product.py`                   | 20-45   | 提取通用函数                   |
| R23 | Create/Update Schema 字段重复              | `schemas/job.py`                       | 21-129  | 定义 `JobSearchConfigBase`     |
| R24 | Create/Update Schema 字段重复              | `schemas/product.py`                   | 125-201 | 定义基础类                     |
| R25 | `model_config = {"from_attributes": True}` | 所有 Response schema                   | 多处    | 定义 `BaseResponseSchema` 基类 |

### 其他可提取逻辑（4个）

| #   | 问题                                | 文件                                                                           | 行号    | 建议                        |
| --- | ----------------------------------- | ------------------------------------------------------------------------------ | ------- | --------------------------- |
| R26 | `send_feishu_notification` 调用分散 | `crawling/service.py`, `jobs/notification_service.py`, `jobs/match_service.py` | 多处    | 定义通知模板                |
| R27 | `parse_salary` 放在 service 层      | `jobs/crawl_service.py`                                                        | 153-182 | 提取到 `utils/parsers.py`   |
| R28 | URL 规范化                          | `products/service.py`                                                          | 49-81   | 提取到 `utils/url.py`       |
| R29 | CrawlTaskRunner 任务生命周期        | `crawling/task_runner.py`                                                      | 39-205  | 使用上下文管理器/装饰器封装 |

---

## 代码质量问题详单（38个）

### 高优先级（15个）

| #   | 类型                   | 文件                    | 行号                    | 问题描述                                |
| --- | ---------------------- | ----------------------- | ----------------------- | --------------------------------------- |
| Q1  | except Exception       | `jobs/crawl_service.py` | 416                     | 通知发送失败吞掉所有异常                |
| Q2  | except Exception       | `jobs/crawl_service.py` | 522                     | 详情抓取无分类异常处理                  |
| Q3  | except Exception       | `jobs/crawl_service.py` | 600                     | 重试详情抓取无差别处理                  |
| Q4  | except Exception       | `jobs/crawl_service.py` | 639                     | 自动匹配分析入队失败静默忽略            |
| Q5  | except Exception       | `jobs/crawl_service.py` | 851                     | 心跳续租可能掩盖连接池耗尽              |
| Q6  | except Exception       | `jobs/crawl_service.py` | 1008                    | 整个平台组失败归因于单一异常            |
| Q7  | except Exception       | `jobs/crawl_service.py` | 1234                    | 剩余任务全部标记为错误                  |
| Q8  | except Exception: pass | `jobs/match_service.py` | 256                     | 飞书通知完全静默失败                    |
| Q9  | except Exception: pass | `jobs/match_service.py` | 456                     | 批量匹配通知完全静默                    |
| Q10 | except Exception       | `products/service.py`   | 387                     | 批量删除回滚与异常类型无关              |
| Q11 | except Exception ×4    | `crawling/service.py`   | 57-85                   | 价格历史/日志/告警/标题各自吞异常       |
| Q12 | except Exception       | `products/router.py`    | 128,166,220             | 调度器异常直接抛给客户端                |
| Q13 | HTTPException 暴露内部 | `jobs/router.py`        | 135-139,510-514,908-912 | `detail=f"Scheduler error: {str(exc)}"` |
| Q14 | HTTPException 暴露内部 | `smart_home/router.py`  | 72,88,118,129,148,197   | `_http_error` 直接 `detail=str(exc)`    |
| Q15 | 嵌套 7-8 层            | `jobs/crawl_service.py` | 440-556                 | for→try→if→elif→if→if→if                |

### 中优先级（16个）

| #   | 类型              | 文件                    | 行号      | 问题描述                                          |
| --- | ----------------- | ----------------------- | --------- | ------------------------------------------------- |
| Q16 | 不必要的注释      | `jobs/crawl_service.py` | 216-217   | 函数名已自解释                                    |
| Q17 | 不必要的注释      | `jobs/crawl_service.py` | 328-329   | 代码已清晰表达                                    |
| Q18 | 不必要的注释      | `jobs/crawl_service.py` | 269       | 变量名已自解释                                    |
| Q19 | 不必要的注释      | `jobs/crawl_service.py` | 225-228   | 完全冗余注释                                      |
| Q20 | 魔法数字          | `jobs/crawl_service.py` | 35        | `DETAIL_COOKIE_FAILURE_COOLDOWN_LIMIT = 2` 无依据 |
| Q21 | 魔法数字          | `jobs/crawl_service.py` | 38        | `DETAIL_FETCH_TIMEOUT_SECONDS = 15.0` 无依据      |
| Q22 | 魔法数字          | `jobs/crawl_service.py` | 39        | `DETAIL_WAF_BLOCK_LIMIT = 1` 无依据               |
| Q23 | 魔法数字          | `jobs/crawl_service.py` | 40        | `DETAIL_TIMEOUT_LIMIT = 3` 无依据                 |
| Q24 | 魔法数字          | `jobs/crawl_service.py` | 1005,1231 | `random.uniform(3, 6)` 延迟无说明                 |
| Q25 | 魔法数字          | `platforms/base.py`     | 229,264   | `asyncio.timeout(90)` 无依据                      |
| Q26 | 缺少类型注解      | `jobs/match_service.py` | 66        | `task` 和 `db` 无类型                             |
| Q27 | 缺少类型注解      | `jobs/match_service.py` | 95        | `task`、`db`、`progress_callback` 无类型          |
| Q28 | 缺少类型注解      | `jobs/crawl_service.py` | 1022      | `crawl_single_config_background` 参数不完整       |
| Q29 | 缺少类型注解      | `jobs/crawl_service.py` | 1100      | `progress_callback` 无类型                        |
| Q30 | 深层嵌套 with/try | `jobs/crawl_service.py` | 971-1008  | try→async with→async with→for→try 5层             |
| Q31 | 深层嵌套 with/try | `jobs/crawl_service.py` | 1196-1238 | try→async with→async with→for 4层                 |

### 低优先级（7个）

| #   | 类型       | 文件                    | 行号        | 问题描述                                             |
| --- | ---------- | ----------------------- | ----------- | ---------------------------------------------------- |
| Q32 | 命名不一致 | `jobs/crawl_service.py` | 203-205     | `total_scraped` 参数传入后未被使用                   |
| Q33 | 命名不一致 | `jobs/crawl_service.py` | 745-756     | `_lock_already_held` 下划线前缀暴露为公共参数        |
| Q34 | 命名不一致 | `jobs/crawl_service.py` | 1008        | 错误键名不统一（`"error"` vs `"reason"`）            |
| Q35 | 命名不一致 | `jobs/match_service.py` | 90          | `e` 与其他文件的 `exc` 风格不一致                    |
| Q36 | 命名不一致 | `products/service.py`   | 357,382,387 | `except Exception as exc` 与 `except Exception` 混用 |
| Q37 | 命名不一致 | `crawling/service.py`   | 150         | 同上，`as exc` 与裸 except 混用                      |

---

## 效率问题详单（40个）

### 同步阻塞混入异步代码（2个）

| #   | 文件                     | 行号     | 问题描述                               | 影响             |
| --- | ------------------------ | -------- | -------------------------------------- | ---------------- |
| E1  | `platforms/job51.py`     | 312      | `time.sleep(random.uniform(2.0, 4.0))` | 可能阻塞事件循环 |
| E2  | `platforms/cdp_utils.py` | 26,39,93 | `json.loads/dumps` 大 JSON 阻塞        | 事件循环阻塞     |

### 串行 I/O 操作（4个）

| #   | 文件                    | 行号      | 问题描述                      | 建议                  |
| --- | ----------------------- | --------- | ----------------------------- | --------------------- |
| E3  | `jobs/crawl_service.py` | 990-1007  | 多个 platform_configs 串行    | `asyncio.gather` 并行 |
| E4  | `jobs/crawl_service.py` | 1205-1231 | 同 profile 内 config_ids 串行 | 有限并发              |
| E5  | `jobs/match_service.py` | 157-226   | LLM 批次间串行                | 全局 Semaphore        |
| E6  | `jobs/match_service.py` | 397-435   | 同上                          | 全局 Semaphore        |

### 数据库连接管理（6个）

| #   | 文件                       | 行号                    | 问题描述                             | 影响          |
| --- | -------------------------- | ----------------------- | ------------------------------------ | ------------- |
| E7  | `jobs/crawl_service.py`    | 220,758,785-808,833-856 | 心跳循环高频创建 session             | 连接池压力    |
| E8  | `crawling/service.py`      | 42-87,97-149            | 单次爬取 3 个独立 session            | 连接池/原子性 |
| E9  | `crawling/service.py`      | 178-295                 | `check_price_alerts` 内 3 个 session | 连接池压力    |
| E10 | `crawling/profile_pool.py` | 47,81,107,166,193,240   | lease 长时间持有连接                 | 连接池耗尽    |
| E11 | `database.py`              | -                       | 连接池配置可能不足                   | 性能/稳定性   |

### 重复的无操作更新（4个）

| #   | 文件                     | 行号                | 问题描述                             |
| --- | ------------------------ | ------------------- | ------------------------------------ |
| E12 | `jobs/crawl_service.py`  | 240-251             | 无条件设置 `last_active_at = now()`  |
| E13 | `jobs/crawl_service.py`  | 277-301             | 无条件设置 `last_updated_at = now()` |
| E14 | `jobs/crawl_service.py`  | 351-369             | dedup 无条件更新                     |
| E15 | `crawling/task_store.py` | 109,215,240,267,309 | 可能无条件更新所有字段               |

### 过于宽泛的操作（5个）

| #   | 文件                             | 行号    | 问题描述                             | 建议                 |
| --- | -------------------------------- | ------- | ------------------------------------ | -------------------- |
| E16 | `jobs/crawl_service.py`          | 230-236 | 加载所有活跃 job 仅检查 job_id       | 仅查询必要字段       |
| E17 | `jobs/crawl_service.py`          | 608-611 | 加载完整 UserResume 只用 `id`        | 仅查询 `id`          |
| E18 | `crawling/service.py`            | 245-251 | 加载完整 PriceHistory 只用 `price`   | 仅查询 `price`       |
| E19 | `crawling/service.py`            | 163-175 | 加载完整 Product 只用 `id, platform` | 仅查询两字段         |
| E20 | `dashboard/dashboard_service.py` | 369-407 | Python 端聚合大数据                  | SQL `LAG()` 窗口函数 |

### 不必要的存在性检查（3个）

| #   | 文件                    | 行号                | 问题描述                        |
| --- | ----------------------- | ------------------- | ------------------------------- |
| E21 | `jobs/match_service.py` | 503-509             | 先 SELECT 再 INSERT ON CONFLICT |
| E22 | `core/sessions.py`      | 37-45,82-89,117-124 | 先 SELECT 再 DELETE             |
| E23 | `products/service.py`   | 171-174             | 先查询再决定是否抛异常          |

### 内存泄漏风险（4个）

| #   | 文件                         | 行号    | 问题描述                               |
| --- | ---------------------------- | ------- | -------------------------------------- |
| E24 | `core/event_stream.py`       | 10-43   | 僵尸订阅者导致内存缓慢增长             |
| E25 | `smart_home/state_stream.py` | 14-72   | 未取消订阅导致集合增长                 |
| E26 | `workers/crawler.py`         | 124,272 | `active_tasks` 集合可能累积已完成 Task |
| E27 | `core/auth_cookies.py`       | -       | Cookie 缓存可能无界增长                |

### 热路径膨胀（3个）

| #   | 文件                        | 行号            | 问题描述                   | 建议               |
| --- | --------------------------- | --------------- | -------------------------- | ------------------ |
| E28 | `core/security.py`          | 107,147,160,248 | 每次请求查询数据库，无缓存 | 短期内存缓存       |
| E29 | `core/user_config_cache.py` | 45-95           | 缓存击穿时全部打到数据库   | 添加互斥锁         |
| E30 | `events/router.py`          | 125,149         | SSE 每次事件遍历所有订阅者 | 考虑 Redis Pub/Sub |

### 缺失的并发（4个）

| #   | 文件                             | 行号    | 问题描述                                         |
| --- | -------------------------------- | ------- | ------------------------------------------------ |
| E31 | `dashboard/dashboard_service.py` | 591-605 | 5 个薪资区间查询串行                             |
| E32 | `dashboard/dashboard_service.py` | 685-713 | product_result 和 job_result 串行                |
| E33 | `crawling/task_runner.py`        | 112,178 | `gather(return_exceptions=False)` 单失败整批取消 |

### 重复的计算（3个）

| #   | 文件                             | 行号                  | 问题描述                                  |
| --- | -------------------------------- | --------------------- | ----------------------------------------- |
| E34 | `jobs/crawl_service.py`          | 153-182               | `parse_salary` 每次调用重新编译正则       |
| E35 | `dashboard/dashboard_service.py` | 87-89,227-229,315-317 | 重复计算 `datetime.now(UTC).replace(...)` |
| E36 | `products/service.py`            | 116-125               | `total_pages` 重复计算（微小）            |

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
