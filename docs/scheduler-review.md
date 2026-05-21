# Price-Monitor 定时调度系统 Code Review 报告

> **Review 日期**: 2026-05-21
> **Review 范围**: `backend/app/services/scheduler_job.py`, `backend/app/services/scheduler_service.py`, `backend/app/routers/jobs.py`, `backend/app/routers/products.py`, `backend/app/main.py`, `backend/app/models/job.py`, `backend/app/models/product.py`, 相关 Schema 与测试
> **Reviewer**: Claude Code

---

## 1. 执行摘要

Price-Monitor 项目当前包含**两套独立的定时调度子系统**，均基于 APScheduler 的 `AsyncIOScheduler`：

| 子系统           | 调度粒度                               | 核心管理类             | 数据模型                                                     |
| ---------------- | -------------------------------------- | ---------------------- | ------------------------------------------------------------ |
| **职位爬取调度** | 每个 `JobSearchConfig` 独立配置 cron   | `JobConfigScheduler`   | `JobSearchConfig` 表内嵌 `cron_expression`/`cron_timezone`   |
| **商品爬取调度** | 每个 `user_id + platform` 组合独立配置 | `ProductCronScheduler` | `ProductPlatformCron` 独立表，`(user_id, platform)` 联合唯一 |

**总体评价**：架构演进方向正确——从早期全局统一的 `User.job_crawl_cron` 演进为今天的 per-config / per-platform 精细化调度，让不同职位搜索和不同电商平台可以差异化定时策略。APScheduler 与 FastAPI `lifespan` 的集成遵循了标准模式，启动时通过 `sync_all()` 从数据库重建 job，天然支持无状态部署。

**但实现层面存在 7 个值得关注的问题**，其中 2 个为高严重程度，可能在生产环境中引发功能性故障或资源耗尽。

---

## 2. 发现的问题

### 2.1 `_crawl_tasks` 全局字典无清理机制 —— 内存泄漏

| 属性         | 内容                                                                                                                                 |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| **位置**     | `backend/app/services/scheduler_service.py:52`                                                                                       |
| **严重程度** | **高**                                                                                                                               |
| **影响**     | 所有爬取任务（cron 触发 + 手动触发）的结果被永久保存在内存中。随着运行时间累积，字典无限增长，最终可能导致进程 OOM。                 |
| **代码片段** | `python _crawl_tasks: dict[str, CrawlTask] = {}`                                                                                     |
| **复现估算** | 若每天触发 20 次爬取任务，一年累积约 7300 个 `CrawlTask` 对象；每个对象可能携带 `details` 列表（含大量爬取结果），内存占用不可忽略。 |

**根因分析**：`create_task()` 将任务放入字典，但任务完成后（无论成功/失败）没有任何淘汰逻辑。这是典型的"只写不删"内存累积模式。

---

### 2.2 `JobConfigScheduler.sync_all()` 硬编码 `user_id == 1`

| 属性         | 内容                                                                                                                                                                    |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **位置**     | `backend/app/services/scheduler_job.py:74`                                                                                                                              |
| **严重程度** | **高**                                                                                                                                                                  |
| **影响**     | 系统重启后，仅用户 ID 为 1 的职位 cron 配置会被加载到 APScheduler。若系统启用多用户，其他用户的职位定时任务在重启后将永远不会被触发，配置在数据库中存在但调度器不知情。 |
| **代码片段** | `python result = await db.execute( select(JobSearchConfig).where( JobSearchConfig.cron_expression.isnot(None), JobSearchConfig.user_id == 1,  # <-- 硬编码 ) )`         |
| **对比**     | `ProductCronScheduler.sync_all()` 已正确移除用户过滤，支持全量用户。这说明职位调度器在多用户演进中被遗漏。                                                              |

**根因分析**：项目早期为单用户系统（`user_id = 1` 硬编码），在商品爬取侧的多用户重构（`ProductCronScheduler` + `(user_id, platform)` 联合唯一约束 + 测试覆盖）中，`JobConfigScheduler` 被遗漏。

---

### 2.3 Cron 表达式缺少格式校验

| 属性         | 内容                                                                                                                                                                                                                                                         |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| **位置**     | `backend/app/schemas/job.py:26-27`, `backend/app/schemas/product.py:123-124`                                                                                                                                                                                 |
| **严重程度** | 中                                                                                                                                                                                                                                                           |
| **影响**     | 用户提交无效 cron 表达式（如 `"每分钟"` 或 `"* *"`）时，Pydantic 校验通过，直到 APScheduler 的 `CronTrigger.from_crontab()` 执行时才抛出异常。由于调度器同步逻辑在路由层没有 try/except 包裹，这会导致 API 返回 500 而非 400，用户体验差且增加错误日志噪音。 |
| **代码片段** | `python cron_expression: str                                                                                                                                                                                                                                 | None = Field(default=None, max_length=100)` —— 仅有长度限制，无格式校验。 |

---

### 2.4 调度器同步存在崩溃窗口

| 属性         | 内容                                                                                                                                                                                                                                                  |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **位置**     | `backend/app/routers/jobs.py:111-114`, `backend/app/routers/jobs.py:450-457`, `backend/app/routers/products.py:207-216` 等                                                                                                                            |
| **严重程度** | 中                                                                                                                                                                                                                                                    |
| **影响**     | 路由处理流程为：先 `db.commit()` 写入数据库，再调用 `scheduler.add_job()` 注册调度。如果进程在这两步之间崩溃，数据库中已写入 cron 配置但 APScheduler 未注册。虽然重启后 `sync_all()` 会恢复，但在高可用场景下这是一个短暂的"配置存在但永不触发"窗口。 |
| **代码片段** | `python await db.commit() await db.refresh(config) # <-- 崩溃窗口 if config.cron_expression: scheduler.add_job(...)  # 若此处进程崩溃，调度丢失`                                                                                                      |

---

### 2.5 `get_next_run_times()` 返回机器格式的 cron 表达式

| 属性         | 内容                                                                                                                                                                           |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **位置**     | `backend/app/services/scheduler_job.py:96`, `backend/app/services/scheduler_job.py:205`                                                                                        |
| **严重程度** | 中                                                                                                                                                                             |
| **影响**     | API 返回的 `cron_expression` 字段形如 `cron[month='*', day='*', day_of_week='*', hour='6', minute='0']`，而非用户输入的 `0 6 * * *`。前端 `/schedule` 页面展示时会让用户困惑。 |
| **代码片段** | `python "cron_expression": str(job.trigger),`                                                                                                                                  |

---

### 2.6 浏览器清理逻辑粗暴且吞异常

| 属性         | 内容                                                                                                                                                                                                          |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **位置**     | `backend/app/services/scheduler_service.py:332-340`                                                                                                                                                           |
| **严重程度** | 低                                                                                                                                                                                                            |
| **影响**     | `_cleanup_all_shared_browsers()` 无条件关闭所有平台（淘宝/京东/亚马逊）的共享浏览器，即使本次爬取仅涉及一个平台。更严重的是 `except Exception: pass` 吞掉了所有异常，可能掩盖浏览器资源泄漏或关闭失败的信号。 |
| **代码片段** | `python for adapter_class in [TaobaoAdapter, JDAdapter, AmazonAdapter]: try: await adapter_class._close_shared_browser() except Exception: pass`                                                              |

---

### 2.7 两套调度器代码高度重复

| 属性         | 内容                                                                                                                                                                                      |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **位置**     | `backend/app/services/scheduler_job.py` 中 `JobConfigScheduler` 和 `ProductCronScheduler`                                                                                                 |
| **严重程度** | 低                                                                                                                                                                                        |
| **影响**     | 两个类拥有几乎完全一致的方法签名和实现逻辑（`add_job` / `remove_job` / `sync_all` / `get_next_run_times`），仅 job ID 生成规则和 `sync_all` 的查询条件不同。违反 DRY 原则，增加维护成本。 |

---

## 3. 改进建议

### 3.1 短期修复（建议立即实施）

#### 修复 1：移除 `sync_all()` 中的硬编码用户过滤

**文件**: `backend/app/services/scheduler_job.py`

```python
# 修改前
result = await db.execute(
    select(JobSearchConfig).where(
        JobSearchConfig.cron_expression.isnot(None),
        JobSearchConfig.user_id == 1,  # 移除此行
    )
)

# 修改后
result = await db.execute(
    select(JobSearchConfig).where(
        JobSearchConfig.cron_expression.isnot(None),
    )
)
```

#### 修复 2：给 `_crawl_tasks` 添加容量上限与 TTL

**文件**: `backend/app/services/scheduler_service.py`

```python
MAX_RETAINED_TASKS = 1000

def create_task(...) -> CrawlTask:
    ...
    _crawl_tasks[task_id] = task
    # 容量淘汰
    while len(_crawl_tasks) > MAX_RETAINED_TASKS:
        oldest = min(_crawl_tasks, key=lambda k: _crawl_tasks[k].created_at)
        del _crawl_tasks[oldest]
    return task
```

> 更进一步可引入 TTL：在 `get_task()` 或后台任务中定期扫描并删除 `created_at` 超过 24 小时的已完成的任务。

#### 修复 3：在 Schema 层添加 cron 表达式格式校验

**文件**: `backend/app/schemas/job.py` 和 `backend/app/schemas/product.py`

```python
from apscheduler.triggers.cron import CronTrigger
from pydantic import field_validator

class JobSearchConfigCreate(BaseModel):
    ...

    @field_validator("cron_expression")
    @classmethod
    def validate_cron(cls, v: str | None) -> str | None:
        if v is None:
            return v
        try:
            CronTrigger.from_crontab(v.strip())
        except ValueError as exc:
            raise ValueError(f"无效的 cron 表达式: {exc}")
        return v.strip()
```

#### 修复 4：在 `get_next_run_times()` 中返回用户原始的 cron 表达式

**文件**: `backend/app/services/scheduler_job.py`

在 `add_job()` 时通过 `job.kwargs` 或自定义属性保存原始表达式：

```python
self._scheduler.add_job(
    crawl_single_config,
    trigger=CronTrigger.from_crontab(cron_expression, timezone=tz),
    id=job_id,
    kwargs={"config_id": config_id, "_raw_cron": cron_expression},
)
```

然后在 `get_next_run_times()` 中读取 `job.kwargs.get("_raw_cron")` 返回。

---

### 3.2 中期重构（建议排入下个迭代）

#### 重构 1：抽象调度器基类

提取 `BaseCronScheduler` 基类，封装公共的 `add_job`/`remove_job` 逻辑：

```python
class BaseCronScheduler:
    def __init__(self, scheduler) -> None:
        self._scheduler = scheduler

    def add_job(self, job_id: str, func, trigger, *, kwargs: dict | None = None) -> None:
        ...

    def remove_job(self, job_id: str) -> None:
        ...

class JobConfigScheduler(BaseCronScheduler):
    JOB_ID_PREFIX = "job_config_cron_"
    # 仅保留 job_id 生成和 sync_all 的查询差异

class ProductCronScheduler(BaseCronScheduler):
    JOB_ID_PREFIX = "product_cron_"
```

#### 重构 2：统一 cron 修改的权限校验

当前职位 cron 可通过两个入口修改：

- `PATCH /jobs/configs/{id}` —— 要求 `super_admin`
- `PATCH /jobs/configs/{id}/cron` —— 要求 `require_permission("schedule:configure")`

建议统一为 `require_permission("schedule:configure")`，并在前端根据用户角色控制入口显隐，而非在后端用不同权限拦截。

#### 重构 3：改进浏览器清理策略

```python
async def _cleanup_shared_browsers(platforms_used: set[str] | None = None) -> None:
    adapters = {"taobao": TaobaoAdapter, "jd": JDAdapter, "amazon": AmazonAdapter}
    targets = platforms_used or set(adapters.keys())
    for platform in targets:
        try:
            await adapters[platform]._close_shared_browser()
        except Exception as exc:
            logger.warning("Failed to close %s browser: %s", platform, exc)
```

---

### 3.3 长期架构（建议规划）

#### 架构升级 1：调度状态持久化

当前 APScheduler 的 job 仅存在于内存。若未来需要水平扩展（多实例部署），每个实例会独立触发，导致重复爬取。

**方案**：将 APScheduler 配置为使用 PostgreSQL 或 Redis 作为 `jobstore`：

```python
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore

scheduler = AsyncIOScheduler(
    timezone="UTC",
    job_defaults={"coalesce": True, "max_instances": 1},
    jobstores={
        "default": SQLAlchemyJobStore(engine=sync_engine)
    }
)
```

这样多个进程实例共享同一个 jobstore，天然避免重复触发。

#### 架构升级 2：将任务跟踪从内存迁移到 Redis/数据库

`_crawl_tasks` 的内存存储限制了多实例部署。建议将任务状态持久化到 Redis 或数据库，让任何实例都可以查询任何任务的状态。

#### 架构升级 3：引入任务队列替代部分定时调度

对于大规模爬取，可考虑将 APScheduler 作为"触发器"，实际执行通过 Celery / RQ / 自定义任务队列分发，实现：

- 失败自动重试
- 分布式执行
- 任务执行历史持久化

---

## 4. 架构洞察

### 洞察 1：架构演进方向正确，但遗留了过渡期痕迹

项目定时调度经历了清晰的演进路径：

```
全局统一 cron (User.job_crawl_cron)
    ↓
per-config / per-platform 独立 cron
    ↓
多用户隔离 (user_id 嵌入 job ID)
```

`ProductCronScheduler` 已完整走完了这条路径（联合唯一约束 + `user_id:platform` job ID + 测试覆盖）。但 `JobConfigScheduler.sync_all()` 中的 `user_id == 1` 就是那个未清理干净的"脚印"——它证明了职位爬取侧的多用户重构尚未完成。

> **启示**：架构演进时，要在代码库中搜索所有旧架构的标识（如硬编码的 `user_id == 1`、已废弃的字段名），用测试来锁定新契约，防止局部遗漏。

### 洞察 2：APScheduler + FastAPI Lifespan 是标准模式，但缺了关键拼图

`main.py` 中的集成是正确的：

- `lifespan` startup：`sync_all()` → `scheduler.start()`
- `lifespan` shutdown：`scheduler.shutdown(wait=True)`
- 调度器挂载到 `app.state`，供路由层访问

但缺少 `jobstore` 持久化配置，意味着当前架构**无法安全地进行水平扩展**。这是从单进程原型走向生产部署时必须补上的拼图。

> **启示**：在选择 APScheduler 时，尽早决定是否需要 jobstore 持久化。后期添加需要修改调度器初始化代码并处理存量 job 的迁移，成本高于早期规划。

### 洞察 3：`CrawlTask` 的异步模式意图正确，但存储层选错了

用"创建任务 → 后台执行 → 返回 task_id → 轮询进度"的异步模式处理耗时爬取操作，这个设计决策是正确的——它避免了 HTTP 长连接和超时问题。

但使用**无界内存字典**作为任务存储，让这个正确的设计背上了资源隐患。任何长期运行的服务中，"只写不读/只增不减"的内存存储都是定时炸弹。

> **启示**：在实现异步任务跟踪时，永远问自己两个问题：
>
> 1. 这个存储有容量上限吗？
> 2. 已完成的任务会在多久后被清理？
>
> 如果答案是否定的，原型阶段可以容忍，但进入生产前必须补上淘汰机制。

---

## 附录：问题严重程度定义

| 等级   | 定义                                             | 是否需要立即修复   |
| ------ | ------------------------------------------------ | ------------------ |
| **高** | 可能导致功能失效、数据丢失或资源耗尽             | 是                 |
| **中** | 影响用户体验、增加运维成本或在特定场景下引发故障 | 建议在下个迭代修复 |
| **低** | 代码异味、维护成本增加，但短期内不会引发可见故障 | 可在重构时顺带处理 |

---

_本报告基于对代码静态分析生成，未包含运行时性能数据。建议在实施修复后运行完整的 pytest 套件验证行为一致性。_
