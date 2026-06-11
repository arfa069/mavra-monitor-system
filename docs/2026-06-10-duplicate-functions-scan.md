# 重复函数检测报告

生成时间: 2026-06-10 17:22  
扫描范围: backend/app/ (158 个 .py, 758 函) + frontend/src/ (103 个 .ts/tsx, 157 函)  
方法: 提取 → LLM 分类(haiku)→ 按类别 opus 语义重复分析 → 合并报告

## 摘要

| 置信度   | 数量   | 行动         |
| -------- | ------ | ------------ |
| HIGH     | 22     | 建议立即合并 |
| MEDIUM   | 33     | 需进一步调查 |
| LOW      | 18     | 可选 review  |
| **合计** | **73** |              |

## 各批次统计

| 批次                        | groups | HIGH | MED | LOW |
| --------------------------- | ------ | ---- | --- | --- |
| dup-A-platform-utils        | 13     | 2    | 11  | 0   |
| dup-B-jobs-products         | 9      | 2    | 3   | 4   |
| dup-C-crawling-auth         | 12     | 4    | 5   | 3   |
| dup-D-infra-dashboard-smart | 17     | 7    | 7   | 3   |
| dup-E-alerts-frontend       | 22     | 7    | 7   | 8   |

---

## HIGH 置信度(建议立即合并)

### 批次 dup-A-platform-utils

### ✅ 返回带时区信息的当前 UTC datetime(模型字段默认值 / 通用时间工具) [已合并修复]

**修复详情:** 删除了 `models/base.py` 内部 `_utc_now` 实现，统一在 `TimestampMixin` 中引用 `app.utils.time:now_utc`。并在 `app/models/session.py` 中清理了遗存的 `_utc_now` 导入并更新了 defaults。

**批次:** dup-A-platform-utils | **置信度:** HIGH

**涉及函数:**

- `_utc_now` @ `models/base.py:10` — 模型内部私有函数,定义在 Base 同文件中,供 TimestampMixin 的 created_at/updated_at 用作 default 与 onupdate。
- `now_utc` @ `utils/time.py:7` — 公开工具函数,文档说明用于'模型默认值',实现为 datetime.now(UTC)。

**实现差异:** 两者实现完全相同(都是 datetime.now(UTC));仅模块路径、访问性(私有 \_ 前缀 vs 公开)和用途注释不同(模型列默认值 vs 通用时间工具)。

**建议:** **CONSOLIDATE** — 保留 `backend/app/utils/time.py:now_utc`。utils/time.py 已经是公共时间工具的集中点,删去 models/base.py 的 \_utc_now,改为 from app.utils.time import now_utc 并在 TimestampMixin 中 default=now_utc / onupdate=now_utc,避免两处维护同一份 UTC 时间逻辑。

---

### ✅ Pydantic schema 从 ORM User 行的 deleted_at 派生兼容字段 is_active [已合并修复]

**修复详情:** 抽取 `IsActiveFromDeletedAtMixin` 至新文件 `schemas/_common.py`，并将 `admin.py` 和 `auth.py` 的 Response Pydantic 类改为继承该 Mixin，移除了类中重复的 `derive_is_active` 校验逻辑。

**批次:** dup-A-platform-utils | **置信度:** HIGH

**涉及函数:**

- `derive_is_active` @ `schemas/admin.py:61` — model_validator(mode='before') 装饰的 classmethod:hasattr(data, 'deleted_at') 后 data.is_active = data.deleted_at is None,异常 try/except 静默。
- `derive_is_active` @ `schemas/auth.py:51` — 与 admin.py 中实现逐字符相同(同样 hasattr→赋值→try/except)。

**实现差异:** 代码字面完全相同,仅所属 Pydantic schema 类不同(AdminUserResponse vs 某个 Auth schema)。

**建议:** **CONSOLIDATE** — 保留 `backend/app/schemas/admin.py:derive_is_active`。两段函数体一字不差,应提取到 schemas/\_common.py(或类似共享模块)的 module-level 函数 / 可复用 validator,让 admin.py 和 auth.py 都引用同一份实现,避免一处改了另一处遗忘。

---

### 批次 dup-B-jobs-products

### ✅ 职位匹配推荐等级 case 排序表达式在 repository.py 中重复两次（强烈推荐=3、可以考虑=2、不太匹配=1） [已合并修复]

**修复详情:** 在 `app/domains/jobs/repository.py` 抽取模块级私有 helper `_recommendation_rank_case()`，对 `list_match_results` 与 `list_jobs` 两处硬编码的 case 排序表达式进行了合并和替换。

**批次:** dup-B-jobs-products | **置信度:** HIGH

**涉及函数:**

- `list_match_results` @ `domains/jobs/repository.py:123` — list_match_results 内 SQLAlchemy case() 硬编码三档推荐等级与数字映射,与 RECOMMENDATION_RANK 一致
- `list_jobs` @ `domains/jobs/repository.py:206` — list_jobs 末尾为查询最佳 match recommendation 又硬编码了完全相同的 case() 三档映射

**实现差异:** 两处 case 字符串完全一致,只有 ORDER BY 方向与是否参与 distinct 的差别,但 case 表达式本身字节级相同。

**建议:** **CONSOLIDATE** — 保留 `backend/app/domains/jobs/match_service.py 中的 RECOMMENDATION_RANK(模块级 dict,line 23)`。match_service.py 已经定义了 RECOMMENDATION_RANK = {"强烈推荐": 3, "可以考虑": 2, "不太匹配": 1};repository.py 应改用同一来源,或抽取到一个共享模块如 backend/app/domains/jobs/match_rank.py,避免字符串与数字再分叉。

---

### ✅ jobs/service 中 delete_job_config 与 remove_job_config 两个函数实现完全相同(都调用 repository.delete_job_config) [已合并修复]

**修复详情:** 彻底从 `jobs/service.py` 删除了冗余的 `remove_job_config` 包装函数，所有路由与调用均直接改为使用统一的 `delete_job_config` 函数。

**批次:** dup-B-jobs-products | **置信度:** HIGH

**涉及函数:**

- `delete_job_config` @ `domains/jobs/service.py:94` — 返回 (config, info) 元组,调用 repository.delete_job_config
- `remove_job_config` @ `domains/jobs/service.py:103` — 仅删除,不返回额外信息,同样调用 repository.delete_job_config

**实现差异:** delete_job_config 多返回一个包含 config.name 的 dict;remove_job_config 是纯删除(内部 delete 与 commit 都在 repository 里)。

**建议:** **CONSOLIDATE** — 保留 `delete_job_config (因为它携带信息,调用者可以忽略返回值)`。两个函数底层都走 repository.delete_job_config,差异仅在是否回传 config 信息。统一保留 delete_job_config(返回 (config, info)),删除 remove_job_config,所有调用方改用 delete_job_config(忽略 info)。

---

### 批次 dup-C-crawling-auth

### ✅ 按用户名/邮箱查询未删除用户（带可选 exclude_user_id 排除），跨 auth 与 admin 两个 repository 字面级重复 [已合并修复]

**修复详情:** 删除了 `auth/repository.py` 中的本地重复函数，统一从 `admin/repository.py` 导入更为通用的实现，消除了两处维护不同签名的问题。

**批次:** dup-C-crawling-auth | **置信度:** HIGH

**涉及函数:**

- `get_active_user_by_username` @ `domains/auth/repository.py:64` — 实现：select(User).where(username == ?, deleted*at.is*(None), id != exclude_user_id)；exclude_user_id 为必填关键字参数
- `get_active_user_by_email` @ `domains/auth/repository.py:77` — 实现：select(User).where(email == ?, deleted*at.is*(None), id != exclude_user_id)；exclude_user_id 为必填关键字参数
- `get_active_user_by_username` @ `domains/admin/repository.py:58` — 实现：与 auth 版本逻辑完全一致，但 exclude_user_id 改为可选（None 时不附加 id != 条件）
- `get_active_user_by_email` @ `domains/admin/repository.py:70` — 实现：与 auth 版本逻辑完全一致，exclude_user_id 同样改为可选

**实现差异:** 1) admin 版本用 and\_() 包裹 + exclude_user_id 可选，auth 版本硬编码 id != exclude_user_id。2) 命名相同、签名几乎相同。3) 唯一有意义的差异是 exclude_user_id 是否可省略——这不构成独立实现的理由，可以统一签名。

**建议:** **CONSOLIDATE** — 保留 `backend/app/domains/admin/repository.py::get_active_user_by_username（更宽松的签名，admin 已经有 4 个调用方，auth 的 update_profile / bind_wechat_openid / register_user 都能用）`。四个函数都是同一张 User 表的同一组条件；维护两套基本相同的查询既容易漂移（其中一处加了 deleted_at 过滤另一处忘加就有 bug），又增加认知负担。统一后让 auth/repository 改为导入 admin/repository 的实现，或下沉到 backend/app/domains/users/ 共享模块。auth 端的两处调用只需为 exclude_user_id 显式传 None 即可保持当前行为。

---

### ✅ 向数据库添加新用户并 commit/refresh——跨 auth 与 admin repository 的字面级复制 [已合并修复]

**修复详情:** 删除了 `auth/repository.py` 中的本地 `add_user` 函数，统一改为从 `admin/repository.py` 导入并共享相同的实现逻辑。

**批次:** dup-C-crawling-auth | **置信度:** HIGH

**涉及函数:**

- `add_user` @ `domains/auth/repository.py:90` — 实现：db.add(user) → 处理 isawaitable → commit → refresh → return。kwargs-only：\*, user: User
- `add_user` @ `domains/admin/repository.py:90` — 实现：与 auth 版本逐字一致，签名也完全相同（\*, user: User）

**实现差异:** 无——两个函数连 docstring 都没有，body 完全相同。这是纯粹的复制粘贴。

**建议:** **CONSOLIDATE** — 保留 `任一保留即可，倾向保留在 admin/repository.py（它已经持有更多 user 通用 CRUD，被 auth 反向依赖更合理）`。重复 add_user 让两个域各自维护一份相同的 SQLAlchemy 调用样板，任何一处调整（比如未来切换到 session.flush + 显式 commit）都要在两处同步。建议保留一份并让另一方改为 from app.domains.admin.repository import add_user。

---

### ✅ Cron 调度管理器（继承 BaseScheduler，按 ID+多键索引注册 cron 任务）——products 与 jobs 两个 scheduler.py 几乎字面级重复 [已合并修复]

**修复详情:** 提取通用的调度生命周期逻辑（添加、删除、获取下一次执行时间）至 `BaseScheduler` (`app/core/scheduler.py`)。`JobConfigScheduler` 和 `ProductCronScheduler` 继承该基类并只贡献薄方法，大幅简化了 scheduler 的体积。

**批次:** dup-C-crawling-auth | **置信度:** HIGH

**涉及函数:**

- `add_job` @ `domains/products/scheduler.py:18` — 实现：\_job_id 拼接 + CronTrigger.from_crontab + apscheduler.add_job（replace_existing, max_instances=1, kwargs=…）；空 cron 表达式时调用 remove_job
- `remove_job` @ `domains/products/scheduler.py:53` — 实现：\_remove_job_by_id(self.\_job_id(user_id, platform))
- `_fetch_cron_configs` @ `domains/products/scheduler.py:57` — 实现：async select(ProductPlatformCron).where(cron_expression.isnot(None))，返回 scalars().all()
- `_add_job_from_config` @ `domains/products/scheduler.py:71` — 实现：从 config 取出 user_id/platform/cron_expression/timezone 后调 self.add_job(...)
- `_config_label` @ `domains/products/scheduler.py:79` — 实现：返回 f'product platform cron config {user_id}:{platform}' 字符串
- `get_next_run_times` @ `domains/products/scheduler.py:82` — 实现：遍历 self.\_scheduler.get_jobs()，按 JOB_ID_PREFIX 过滤，partition 拆分 suffix，组装 dict
- `_job_id` @ `domains/products/scheduler.py:102` — 实现：return f'{PREFIX}{user_id}:{platform}'
- `add_job` @ `domains/jobs/scheduler.py:18` — 实现：与 products 版本逐字相同的 add_job 流程；唯一差异是 kwargs['config_id'] 单键 vs products 的 user_id+platform 双键
- `remove_job` @ `domains/jobs/scheduler.py:51` — 实现：与 products 版本逐字相同
- `_fetch_cron_configs` @ `domains/jobs/scheduler.py:55` — 实现：与 products 版本逐字相同，只是目标表换成 JobSearchConfig
- `_add_job_from_config` @ `domains/jobs/scheduler.py:69` — 实现：与 products 版本逐字相同，从 config 取出 config_id/cron_expression/timezone 后调 self.add_job
- `_config_label` @ `domains/jobs/scheduler.py:76` — 实现：返回 f'job config #{config_id}' 字符串
- `get_next_run_times` @ `domains/jobs/scheduler.py:79` — 实现：与 products 版本相同循环 + filter + 组装 dict，仅缺少可选 user_id 过滤（结构略简单）
- `_job_id` @ `domains/jobs/scheduler.py:93` — 实现：return f'{PREFIX}{config_id}'

**实现差异:** 1) jobs 是单键（config_id），products 是双键（user_id:platform）→ 体现在 \_job_id 字符串拼接上。2) jobs 不支持 user_id 过滤的 get_next_run_times。3) cron 触发的实际函数不同（crawl_scheduled_config vs crawl_products_by_platform）。其它流程（空 cron→remove_job、replace_existing=True、max_instances=1、kwargs 透传、logger.info 模板）逐字一致。

**建议:** **CONSOLIDATE** — 保留 `把通用 cron 注册/移除/next_run 逻辑下沉到 app/core/scheduler.py::BaseScheduler 的泛型 API（接受 key_parts: tuple、cron 触发函数 callable、配置查询 callable），让 JobConfigScheduler 与 ProductCronScheduler 只贡献 _fetch_cron_configs、_add_job_from_config、_config_label、_job_id 这四个薄方法。`。add_job / remove_job / get_next_run_times 都是同质 apscheduler 包装，重复实现意味着任何一处对 max_instances / replace_existing / 日志格式的优化都要在两处同步；典型多胞胎重复。

---

### ✅ 发送 crawl_profile 系统日志事件——profile_service 与 profile_runtime_service 各自维护一个 wrapper [已合并修复]

**修复详情:** 将 `_emit_profile_event` 统一集中在 `profile_service.py` 中，并在 `profile_runtime_service` 中直接导入复用。已同步修改测试中的 mock 靶标，防止测试挂起。

**批次:** dup-C-crawling-auth | **置信度:** HIGH

**涉及函数:**

- `_emit_profile_event` @ `domains/crawling/profile_service.py:22` — 实现：await emit_system_log_detached(category='runtime', source='crawler', entity_type='crawl_profile', entity_id=profile_key, …)
- `_emit_profile_event` @ `domains/crawling/profile_runtime_service.py:31` — 实现：与 profile_service 版本逐字一致，连默认值（severity='info', status='success'）都相同；唯一不同是 docstring 写 'for a profile runtime operation'

**实现差异:** 无函数体差异——两个模块各自的 \_emit_profile_event 完全一致，只是所在的 service 语境不同。

**建议:** **CONSOLIDATE** — 保留 `在 profile_service.py（或新建 app/domains/crawling/_events.py）保留一个 _emit_profile_event，另一个改为 from .profile_service import _emit_profile_event 或公开化后跨模块复用`。两个文件互相已经互引（profile_runtime_service 直接 import profile_service），抽到 profile_service 一处即可；同时也能给 browser_manager.\_emit_browser_event（语义几乎相同，仅 event_type 前缀不同）让出统一切入点。

---

### 批次 dup-D-infra-dashboard-smart

### ✅ token 哈希计算(用 SHA-256 对 token 字符串做确定性十六进制摘要),用于按 token 反查会话 [已合并修复]

**修复详情:** 将 `sessions.py`、`security.py` 及 `auth/repository.py` 中散落的多处内联哈希操作统一替换为调用 `app/core/tokens.py:hash_token()`，收拢哈希算法源头。

**批次:** dup-D-infra-dashboard-smart | **置信度:** HIGH

**涉及函数:**

- `hash_token` @ `core/tokens.py:115` — 规范化 helper,SHA-256 hexdigest,被 sessions.create_session/get_session_by_refresh_token/rotate_session_refresh_token 调用
- `create_session_with_token` @ `core/sessions.py:50` — legacy 创建,内联 hashlib.sha256(token.encode()).hexdigest() 重新实现 hash_token,应直接调用 hash_token
- `get_session_by_token` @ `core/sessions.py:227` — legacy 查询,内联 hashlib.sha256(token.encode()).hexdigest() 重新实现 hash_token,应直接调用 hash_token
- `delete_session_for_token` @ `domains/auth/repository.py:123` — 内联 hashlib.sha256(token.encode()).hexdigest(),应直接调用 app.core.tokens.hash_token
- `get_current_user` @ `core/security.py:116` — Bearer token 回退路径,内联 hashlib.sha256(token.encode()).hexdigest(),应直接调用 hash_token

**实现差异:** 所有 5 处都用相同一行 hashlib.sha256(token.encode()).hexdigest(),但 tokens.py 中已抽出 hash_token 为公共 helper。其余 4 处都是直接复制粘贴实现,行为完全一致(64 字符 hex 摘要)。

**建议:** **CONSOLIDATE** — 保留 `backend/app/core/tokens.py:hash_token`。hash_token 已是公开 helper,其余 4 处重复实现应改为 from app.core.tokens import hash_token 然后调用,消除 4 处 hashlib 散落使用,便于以后切换摘要算法时只改一处

---

### ❌ 删除用户会话(按 token 哈希匹配) [保持独立]

**保留理由:** 两者职责边界和入参机制不同。`delete_session` 处理 session 物理 ID 的删除与日志逻辑，而 `delete_session_for_token` 属于 auth domain 处理用户登出 token 审计和清空，物理上属于两个独立的业务模块，合并反而会破坏分层隔离。

**批次:** dup-D-infra-dashboard-smart | **置信度:** HIGH

**涉及函数:**

- `delete_session_for_token` @ `domains/auth/repository.py:120` — 直接 delete(Session).where(token_hash == ...),单条记录级删除,自动 commit
- `delete_session_for_token` @ `domains/auth/service.py:122` — 纯 passthrough:return await repository.delete_session_for_token(...),无业务附加值,只有一层无意义透传
- `delete_session` @ `core/sessions.py:179` — 按 session_id+user_id 删除,自动 commit,签名不同但都属于'删除会话'族

**实现差异:** auth.service.delete_session_for_token 是 repository 的纯透传,无业务逻辑。core.sessions.delete_session 走 session_id 路径,内部都是 delete().where().commit() 模式。两组同包不同名。

**建议:** **CONSOLIDATE** — 保留 `backend/app/domains/auth/repository.py:delete_session_for_token`。auth.service.delete_session_for_token 是无意义 passthrough,应直接删除让调用方走 repository;同时让 core.sessions.delete_session 和 auth.repository.delete_session_for_token 共享一个底层 delete_session_by(db, predicate, commit) 工具,避免 delete().where().commit() 在多处复制

---

### ❌ Pydantic field_validator 包装器,直接转发到 schemas/validators.py 的 value 函数 [保持独立]

**保留理由:** Pydantic v2 validation 要求校验器绑定在具体的 Schema 实体上作为 classmethod。虽然底层逻辑转发给共通函数，但包装器本身在不同类中是必不可少的类型强约束定义，无法物理合并。

**批次:** dup-D-infra-dashboard-smart | **置信度:** HIGH

**涉及函数:**

- `validate_cron` @ `schemas/job.py:50` — JobSearchConfigFields.validate_cron,直接 return validate_cron_value(v)
- `validate_cron` @ `schemas/job.py:109` — JobConfigCronUpdate.validate_cron,同上
- `validate_cron` @ `schemas/product.py:129` — \_ProductCronFields.validate_cron,同上
- `validate_timezone` @ `schemas/job.py:55` — validate_timezone_value(v) 包装
- `validate_timezone` @ `schemas/job.py:114` — JobConfigCronUpdate 第二个 validate_timezone 包装
- `validate_timezone` @ `schemas/product.py:134` — Product validate_timezone 包装

**实现差异:** 全部都是 @field_validator("cron_expression"|"cron_timezone") 装饰的 @classmethod,只做一行 return validators.validate_xxx_value(v),无任何额外逻辑。

**建议:** **INVESTIGATE** — 保留 `backend/app/schemas/validators.py:validate_cron_value / validate_timezone_value`。装饰器包装是 pydantic v2 的标准绑定形式,无法在不打破 schema 抽象的前提下合并;但 6 个 validate_xxx 方法都是机械转发,可考虑在 validators.py 提供 make_cron_validator()/make_timezone_validator() 工厂减少装饰样板;但若团队偏好显式可读,保留现状也可接受

---

### ✅ profile_key 字符串校验(strip + build_profile_dir 路径校验) [已合并修复]

**修复详情:** 删除了 `app/schemas/job.py` 中本地冗余的 `_validate_profile_key_value`，直接从 `app.schemas.crawl_profile` 导入并使用统一的 `validate_profile_key_value`。

**批次:** dup-D-infra-dashboard-smart | **置信度:** HIGH

**涉及函数:**

- `validate_profile_key_value` @ `schemas/crawl_profile.py:12` — strip + build_profile_dir 校验,标准实现
- `validate_profile_key` @ `schemas/crawl_profile.py:24` — CrawlProfileCreate 字段包装:return validate_profile_key_value(value)
- `validate_profile_key` @ `schemas/crawl_profile.py:39` — CrawlProfileRenameRequest 字段包装:同上
- `_validate_profile_key_value` @ `schemas/job.py:15` — 几乎逐行复制 crawl_profile.validate_profile_key_value,但加了 (value or "default") 兜底,这是唯一差异
- `validate_profile_key` @ `schemas/job.py:43` — JobSearchConfigFields 包装:\_validate_profile_key_value(v),与 crawl_profile 行为 99% 相同
- `validate_profile_key` @ `schemas/product.py:164` — ProductPlatformProfileBindingUpdate 包装:return validate_profile_key_value(value),import 自 crawl_profile

**实现差异:** crawl_profile 和 product 都 import 自同一个 helper(正确);job 单独搞了一个 \_validate_profile_key_value,差异只是 None→'default' 兜底;3 个 schema 的 field_validator 包装本身无逻辑差异。

**建议:** **CONSOLIDATE** — 保留 `backend/app/schemas/crawl_profile.py:validate_profile_key_value`。job.\_validate_profile_key_value 应删除并改为直接 import crawl_profile.validate_profile_key_value(将 None→'default' 兜底移入 helpers 层或保留在调用处);product 已经是正确用法,作为模板

---

### ✅ dashboard KPI 计算的“读缓存或执行 factory”模式 [已合并修复]

**修复详情:** 在 `DashboardService` 抽取通用缓存模板方法 `_cached_or_compute`。将 `calculate_user_kpi` 与 `calculate_system_kpi` 改写为直接调用该通用方法，彻底消除了手写的缓存读写/降级降噪骨架代码。

**批次:** dup-D-infra-dashboard-smart | **置信度:** HIGH

**涉及函数:**

- `calculate_user_kpi` @ `domains/dashboard/dashboard_service.py:51` — 手写的 read-cache-or-compute:cache_key → \_get_cached → 若 None 则 \_calculate_user_kpi_uncached + \_set_cached
- `calculate_system_kpi` @ `domains/dashboard/dashboard_service.py:219` — 和 calculate_user_kpi 一样的 5 行模式,只是 key 命名、TTL、uncached 函数不同
- `_get_cached_trend` @ `domains/dashboard/dashboard_service.py:763` — 已经是抽取出来的通用 factory:接受 key + factory,统一 \_get_cached → factory → \_set_cached

**实现差异:** calculate*user_kpi / calculate_system_kpi 仍是手写版,而 trend 系列的 9 个 get*\* 都已经统一走 \_get_cached_trend。两者行为一致:都是 cache key + JSON cache + 相同 TTL 模式 + 同样的 try/except 静默。

**建议:** **CONSOLIDATE** — 保留 `backend/app/domains/dashboard/dashboard_service.py:_get_cached_trend`。把 \_get_cached_trend 提升为通用 \_cached_or_compute(key, factory, ttl) → 让 calculate_user_kpi/calculate_system_kpi 直接调用,删除手写 5 行模板。需要把 model_validate(cached) 改为接受 schema 类型参数,或分别保留两个轻包装

---

### ✅ detached 系统日志事件发送(emit_system_log_detached 薄包装) [已合并修复]

**修复详情:** 在 `main.py` 等调用侧重构了冗余的日志事件包装。对 HTTP、Scheduler 等特定类型事件的 emitter 进行私有 helper 提取，降低了各处调用时硬编码 category 和 entity 的重复度。

**批次:** dup-D-infra-dashboard-smart | **置信度:** HIGH

**涉及函数:**

- `_emit_worker_event` @ `workers/crawler.py:41` — category='runtime', source='crawler_worker', entity_type='crawler_worker' 的 detach 包装
- `_emit_task_event` @ `workers/executor.py:24` — category='runtime', source='crawler_worker', entity_type='crawl_task' 的 detach 包装
- `_emit_scheduler_event` @ `main.py:96` — category='platform', source='app.startup'|'app.shutdown', entity_type='scheduler' 的 detach 包装
- `_emit_http_event` @ `main.py:109` — category='platform', source=path, entity_type='request' 的 detach 包装,参数最多

**实现差异:** 4 个 wrapper 都是 await emit_system_log_detached(category=..., event_type=..., source=..., severity=..., status=..., message=..., entity_type=..., entity_id=..., payload=...),固定预填了 category/source/entity_type 等域级默认值。

**建议:** **CONSOLIDATE** — 保留 `emit_system_log_detached`。应将 \_emit_xxx_event 抽到 app.core.system_log 下的 EventEmitter 协议:emit_worker_event(...), emit_task_event(...), emit_scheduler_event(...), emit_http_event(...),消除每个调用点都重复构造 category/source 的样板

---

### ❌ URL 校验(field_validator 包装 → validate_url_value) [保持独立]

**保留理由:** Pydantic 校验在 optional (可空) 与 required (必填) 的语义定义下存在物理差异，必须保留在各自的 schema 类中以配合 decorator 机制运行。

**批次:** dup-D-infra-dashboard-smart | **置信度:** HIGH

**涉及函数:**

- `validate_url` @ `schemas/product.py:33` — ProductCreate.validate_url,包装 validate_url_value(v),必填
- `validate_url` @ `schemas/product.py:41` — ProductUpdate.validate_url,包装 validate_url_value(v, allow_none=True),允许 None

**实现差异:** 两个 validate_url 都在 product.py,签名差异只是 allow_none 参数(必填 vs 可空)。field_validator 必须接收 cls+v,无办法合二为一,必须两个装饰器。

**建议:** **KEEP_SEPARATE**。Pydantic v2 强制要求 field_validator 方法签名,且必填/可空语义不同。两个方法只是机械包装,无法进一步简化

---

### 批次 dup-E-alerts-frontend

### ❌ 后端仓库层 CRUD - alerts repository 与 config repository 共享 add/update/get 模式 [保持独立]

**保留理由:** 这是面向数据库的经典通用 CRUD 骨架。Alerts 与 Config 代表完全不同的业务实体和事务边界，强行共用基类会导致过度泛化并降低可读性，保留独立设计有利于高内聚。

**批次:** dup-E-alerts-frontend | **置信度:** HIGH

**涉及函数:**

- `create_alert` @ `domains/alerts/repository.py:21` — 插入提醒
- `list_alerts` @ `domains/alerts/repository.py:42` — 查询列表
- `get_alert` @ `domains/alerts/repository.py:60` — 查询单项
- `update_alert` @ `domains/alerts/repository.py:69` — 更新字段
- `delete_alert` @ `domains/alerts/repository.py:77` — 删除记录
- `add_user` @ `domains/config/repository.py:16` — 插入用户
- `save_user` @ `domains/config/repository.py:25` — 提交并刷新

**实现差异:** 都是 SQLAlchemy 异步会话上的标准 CRUD,只在实体类型上不同

**建议:** **INVESTIGATE** — 保留 `alerts/repository.py`。建议引入通用 GenericRepository[Model] 抽取 add/get/list/update/delete,降低样板但不要破坏现有事务边界

---

### ❌ 前端 Hook 模式:useQuery 单资源查询 - 多个 feature 都用相同模式包装 query [保持独立]

**保留理由:** 各 Feature Hook 的 queryKey、缓存失效机制 (Invalidate) 和 endpoint 参数均不同。泛化 useQuery Hook 会引入极高的 TypeScript 范型复杂度和侵入性，各 Feature 保持独立的 thin Query Wrappers 更加清晰明了。

**批次:** dup-E-alerts-frontend | **置信度:** HIGH

**涉及函数:**

- `useAlerts` @ `features/alerts/hooks/useAlerts.ts:5` — 按商品查提醒
- `useAllAlerts` @ `features/alerts/hooks/useAlerts.ts:15` — 查全部提醒
- `useJobConfigs` @ `features/jobs/hooks/useJobs.ts:61` — 查职位配置列表
- `useJobConfig` @ `features/jobs/hooks/useJobs.ts:67` — 查单个职位配置
- `useJobs` @ `features/jobs/hooks/useJobs.ts:99` — 查职位列表
- `useJob` @ `features/jobs/hooks/useJobs.ts:118` — 查单个职位
- `useResumes` @ `features/jobs/hooks/useJobs.ts:219` — 查简历列表
- `useMatchResults` @ `features/jobs/hooks/useJobs.ts:251` — 查匹配结果
- `useCrawlProfiles` @ `features/jobs/hooks/useJobs.ts:282` — 查 Profile 列表
- `useProducts` @ `features/products/hooks/useProducts.ts:43` — 查商品列表
- `useProductHistory` @ `features/products/hooks/useProducts.ts:111` — 查价格历史
- `useCrawlLogs` @ `features/products/hooks/useProducts.ts:160` — 查爬取日志
- `useProductProfileBindings` @ `features/products/hooks/useProducts.ts:171` — 查绑定列表
- `useResourcePermissions` @ `features/admin/hooks/useAdmin.ts:9` — 查资源权限
- `useRolePermissionMatrix` @ `features/admin/hooks/useAdmin.ts:57` — 查角色权限矩阵
- `useScheduleConfig` @ `features/schedule/hooks/useScheduleConfig.ts:5` — 查全局调度配置

**实现差异:** 都是 useQuery 包装,queryKey 和 endpoint 不同;但 useJobs/useJobConfigs 都在同一文件内属于同一域,可保留;useProducts 同理;跨域散落到多文件才是真问题

**建议:** **INVESTIGATE** — 保留 `useProducts.ts`。可抽取 useResourceQuery<T>(endpoint, params, options) 通用 hook,但当前代码可读性可接受;优先在重复 3 次以上的简单查询上抽取

---

### ❌ 前端 Hook 模式:useMutation 单资源变更 - 多个 feature 共享 useMutation 包装模式 [保持独立]

**保留理由:** 各 feature hooks 的 mutations 有其特定的 query key 回刷机制和不同的入参格式，合并这数十个 hooks 会极大地降低代码的可维护性，保留各自的 thin Mutation Hook 更为解耦。

**批次:** dup-E-alerts-frontend | **置信度:** HIGH

**涉及函数:**

- `useCreateAlert` @ `features/alerts/hooks/useAlerts.ts:21` — 创建提醒
- `useUpdateAlert` @ `features/alerts/hooks/useAlerts.ts:29` — 更新提醒
- `useDeleteAlert` @ `features/alerts/hooks/useAlerts.ts:38` — 删除提醒
- `useCreateJobConfig` @ `features/jobs/hooks/useJobs.ts:74` — 创建职位配置
- `useUpdateJobConfig` @ `features/jobs/hooks/useJobs.ts:82` — 更新职位配置
- `useDeleteJobConfig` @ `features/jobs/hooks/useJobs.ts:91` — 删除职位配置
- `useCreateResume` @ `features/jobs/hooks/useJobs.ts:225` — 创建简历
- `useUpdateResume` @ `features/jobs/hooks/useJobs.ts:234` — 更新简历
- `useDeleteResume` @ `features/jobs/hooks/useJobs.ts:243` — 删除简历
- `useCreateCrawlProfile` @ `features/jobs/hooks/useJobs.ts:295` — 创建 Profile
- `useUpdateCrawlProfile` @ `features/jobs/hooks/useJobs.ts:303` — 更新 Profile
- `useDeleteCrawlProfile` @ `features/jobs/hooks/useJobs.ts:317` — 删除 Profile
- `useRenameCrawlProfile` @ `features/jobs/hooks/useJobs.ts:325` — 重命名 Profile
- `useCopyCrawlProfile` @ `features/jobs/hooks/useJobs.ts:342` — 复制 Profile
- `useTriggerMatch` @ `features/jobs/hooks/useJobs.ts:263` — 触发匹配
- `useTestCrawlProfile` @ `features/jobs/hooks/useJobs.ts:374` — 测试 Profile
- `useExportProfileBackup` @ `features/jobs/hooks/useJobs.ts:388` — 导出备份
- `useImportProfileBackup` @ `features/jobs/hooks/useJobs.ts:399` — 导入备份
- `useCreateProduct` @ `features/products/hooks/useProducts.ts:56` — 创建商品
- `useUpdateProduct` @ `features/products/hooks/useProducts.ts:64` — 更新商品
- `useDeleteProduct` @ `features/products/hooks/useProducts.ts:78` — 删除商品
- `useBatchCreate` @ `features/products/hooks/useProducts.ts:86` — 批量创建
- `useBatchDelete` @ `features/products/hooks/useProducts.ts:94` — 批量删除
- `useBatchUpdate` @ `features/products/hooks/useProducts.ts:102` — 批量更新
- `useCrawlNow` @ `features/products/hooks/useProducts.ts:118` — 触发爬取
- `useUpdateProductProfileBinding` @ `features/products/hooks/useProducts.ts:178` — 更新绑定
- `useDeleteProductProfileBinding` @ `features/products/hooks/useProducts.ts:193` — 删除绑定
- `useGrantResourcePermission` @ `features/admin/hooks/useAdmin.ts:20` — 授予资源权限
- `useRevokeResourcePermission` @ `features/admin/hooks/useAdmin.ts:31` — 撤销资源权限
- `useUpdateResourcePermission` @ `features/admin/hooks/useAdmin.ts:41` — 更新资源权限
- `useUpdateRolePermissions` @ `features/admin/hooks/useAdmin.ts:63` — 更新角色权限
- `useUpdateScheduleConfig` @ `features/schedule/hooks/useScheduleConfig.ts:11` — 更新调度配置

**实现差异:** 几乎所有 mutation 都是 useMutation + invalidateQueries 的标准样板,只有 invalidate 的 queryKey 集合不同

**建议:** **INVESTIGATE** — 保留 `useProducts.ts`。useJobs.ts 单文件超过 28 个 mutation hook 增长到 400+ 行,已具备抽取 useCrudMutations(entity) 工厂的条件

---

### ✅ 前端时间格式化工具分散在多处 - formatTime/formatDateTime 重复实现 [已合并修复]

**修复详情:** 移除了 `RecentAlertsPanel.tsx` 组件内私有的 `formatTime` 冗余实现，直接引入并调用统一的 `shared/utils/date.ts` 的 `formatDateTime`。

**批次:** dup-E-alerts-frontend | **置信度:** HIGH

**涉及函数:**

- `formatTime` @ `features/dashboard/components/RecentAlertsPanel.tsx:11` — 本地化时间格式化 zh-CN,在组件内私有
- `formatDateTime` @ `shared/utils/date.ts:5` — 统一时间格式化 zh-CN,共享工具
- `formatTime` @ `utils/nl-to-cron.ts:101` — 时间数字零填充(非日期,是 HH/mm 数字补零)

**实现差异:** RecentAlertsPanel 的 formatTime 与 date.ts 的 formatDateTime 高度重叠(都是 zh-CN 本地化),nl-to-cron 的 formatTime 是不同的零填充语义

**建议:** **CONSOLIDATE** — 保留 `shared/utils/date.ts:formatDateTime`。RecentAlertsPanel 的 formatTime 应删除改用共享 formatDateTime;nl-to-cron 的 formatTime 名字混淆建议重命名为 padTimeDigits

---

### ✅ 前端今日简报构建器 - buildPriceStatus / buildJobStatus / buildHomeStatus 共享相同状态构建模式 [已合并修复]

**修复详情:** 将 `todayBrief.ts` 内重复取首位实体 title 的 `productName` 和 `jobName` 统一合并为公用的 `firstSourceName(items, fallback)` helper 辅助函数，精简了逻辑。

**批次:** dup-E-alerts-frontend | **置信度:** HIGH

**涉及函数:**

- `buildPriceStatus` @ `features/today/todayBrief.ts:16` — 价格看守模块状态
- `buildJobStatus` @ `features/today/todayBrief.ts:36` — 职位雷达模块状态
- `buildHomeStatus` @ `features/today/todayBrief.ts:56` — 家居设备模块状态
- `productName` @ `features/today/todayBrief.ts:8` — 取首项标题
- `jobName` @ `features/today/todayBrief.ts:12` — 取首项标题
- `quietScore` @ `features/today/todayBrief.ts:134` — 基于事件量算静默分

**实现差异:** productName 与 jobName 都是 'sources[0].title || fallback' 的同一模式;三个 build\*Status 各对应不同模块

**建议:** **CONSOLIDATE** — 保留 `todayBrief.ts:buildPriceStatus`。productName/jobName 应合并为 firstSourceName(sources, fallback);buildXxxStatus 因输入 shape 不同不必合并

---

### ✅ 前端 SSE 实时连接 hook - useDashboardSSE 与 useSmartHomeSSE 共享 EventSource 模式 [已合并修复]

**修复详情:** 提取底层的 EventSource 连接逻辑、重连重试机制及资源清理，新建共享 `shared/hooks/useSSE.ts` Hook。两处 feature sse hook 经 refactor 后现在直接代理至该通用 hook，只负责业务逻辑分发。

**批次:** dup-E-alerts-frontend | **置信度:** HIGH

**涉及函数:**

- `useDashboardSSE` @ `features/dashboard/hooks/useDashboardSSE.ts:12` — 仪表盘 SSE 实时数据
- `useSmartHomeSSE` @ `features/smart-home/hooks/useSmartHomeSSE.ts:5` — 智能家居 SSE 实时连接

**实现差异:** 都是 EventSource 包装,只是 endpoint URL 和消息处理 handler 不同

**建议:** **CONSOLIDATE** — 保留 `shared/hooks/useSSE.ts`。应抽取通用 useSSE<T>(url, options) 处理 onopen/onmessage/onerror + 自动重连 + cleanup,两个 feature hook 只保留消息分发逻辑

---

### ✅ 前端 dashboard KPI 后端缓存模式 - 多个 \_calculate*\_uncached + calculate* 配对模式高度重复 [已合并修复]

**修复详情:** Dashboard 服务的 12 对统计查询和趋势趋势接口现已统一改用通用的 `_cached_or_compute` 缓存模型，彻底移除了重复的手写缓存判定与降级代码。

**批次:** dup-E-alerts-frontend | **置信度:** HIGH

**涉及函数:**

- `calculate_user_kpi` @ `domains/dashboard/dashboard_service.py:51` — 包装 \_calculate_user_kpi_uncached + 缓存
- `_calculate_user_kpi_uncached` @ `domains/dashboard/dashboard_service.py:91` — 未缓存实现
- `calculate_system_kpi` @ `domains/dashboard/dashboard_service.py:219` — 包装
- `_calculate_system_kpi_uncached` @ `domains/dashboard/dashboard_service.py:232` — 未缓存
- `get_price_trends` @ `domains/dashboard/dashboard_service.py:310` — 包装
- `_get_price_trends_uncached` @ `domains/dashboard/dashboard_service.py:317` — 未缓存
- `get_price_change_trends` @ `domains/dashboard/dashboard_service.py:359` — 包装
- `_get_price_change_trends_uncached` @ `domains/dashboard/dashboard_service.py:368` — 未缓存
- `get_job_trends` @ `domains/dashboard/dashboard_service.py:424` — 包装
- `_get_job_trends_uncached` @ `domains/dashboard/dashboard_service.py:431` — 未缓存
- `get_job_match_trends` @ `domains/dashboard/dashboard_service.py:474` — 包装
- `_get_job_match_trends_uncached` @ `domains/dashboard/dashboard_service.py:483` — 未缓存
- `get_platform_distribution` @ `domains/dashboard/dashboard_service.py:532` — 包装
- `_get_platform_distribution_uncached` @ `domains/dashboard/dashboard_service.py:541` — 未缓存
- `get_salary_distribution` @ `domains/dashboard/dashboard_service.py:583` — 包装
- `_get_salary_distribution_uncached` @ `domains/dashboard/dashboard_service.py:590` — 未缓存
- `get_system_health_trends` @ `domains/dashboard/dashboard_service.py:634` — 包装
- `_get_system_health_trends_uncached` @ `domains/dashboard/dashboard_service.py:643` — 未缓存
- `get_crawl_failure_trends` @ `domains/dashboard/dashboard_service.py:684` — 包装
- `_get_crawl_failure_trends_uncached` @ `domains/dashboard/dashboard_service.py:691` — 未缓存
- `get_platform_success_rates` @ `domains/dashboard/dashboard_service.py:756` — 包装
- `_get_platform_success_rates_uncached` @ `domains/dashboard/dashboard_service.py:772` — 未缓存

**实现差异:** 12 对方法完全重复 '\_get_cached_trend / cache_key / try_cache_or_compute' 包装骨架,只有内部 SQL 与返回结构不同

**建议:** **CONSOLIDATE** — 保留 `_get_cached_trend`。已经存在 _get_cached_trend 通用工厂,应将所有 calculate/get_\* 方法重构为统一调用 \_get_cached_trend(key, ttl, fn),消除 12 处重复

---

## MEDIUM 置信度(需进一步调查)

### ❌ HTTP 端点 try/except 异常映射(领域异常 → HTTPException)通用模式 [保持独立]

**保留理由:** smart_home 领域通过独立的 `_http_error` 进行集中的自定义映射捕获；而 dashboard router 逻辑较薄，大部分错误由业务层通过统一异常处理器处理。模式与领域不同，强行合并会产生代码耦合。

**批次:** dup-D-infra-dashboard-smart | **置信度:** MEDIUM

**涉及函数:**

- `_http_error` @ `domains/smart_home/router.py:38` — smart_home 领域的多分支 isinstance(exc) → HTTPException(status_code, detail) 映射器
- `get_trend_data` @ `domains/dashboard/router.py:114` — 内联多个 if current_user.role not in admin → raise HTTPException(403, ...) 分支
- `stream_dashboard_events` @ `domains/dashboard/router.py:50` — 无 try/except,走 CancelledError 处理

**实现差异:** smart_home 是显式 \_http_error helper,在大 try/except 里 raise \_http_error(exc) from exc;dashboard 没抽出 helper,在 if-elif 链里直接 raise HTTPException。模式不同(集中映射 vs 散布 raise),不可机械合并。

**建议:** **KEEP_SEPARATE**。smart_home 走 service 层抛出领域异常的成熟模式,dashboard 在 router 直接做权限检查。模式选择有差异(异常映射 vs 角色守卫),强行统一会污染一个或另一个的设计。保留各自风格

---

### ❌ KPI/trend 数据反序列化为 Pydantic model(从缓存或构造结果) [保持独立]

**保留理由:** 原生 Pydantic `model_validate` 的单行调用。由于针对的是不同的 Schema（`UserKPI`、`SystemKPI`、`TrendResponse` 等），不需要且不应该引入繁琐的范型进行物理去重。

**批次:** dup-D-infra-dashboard-smart | **置信度:** MEDIUM

**涉及函数:**

- `calculate_user_kpi` @ `domains/dashboard/dashboard_service.py:56` — UserKPI.model_validate(cached) — 从缓存反序列化
- `calculate_system_kpi` @ `domains/dashboard/dashboard_service.py:224` — SystemKPI.model_validate(cached) — 同上
- `_get_cached_trend` @ `domains/dashboard/dashboard_service.py:766` — TrendResponse.model_validate(cached) — 同上

**实现差异:** 都是 cache hit 后 model_validate 反序列化,签名都不同,无法直接合并;但模式一致。

**建议:** **KEEP_SEPARATE**。model_validate 是 pydantic 标准 API,3 处都是单行调用,合并无收益,反而增加泛型复杂度。保留

---

### ❌ Profile 池与 browser_manager 各自实现 acqiure/release 流程——lease 生命周期逻辑分散 [保持独立]

**保留理由:** `profile_pool.acquire` 是悲观锁及 DB 字段级的租约事务操作；而 `browser_manager.acquire` 是 Playwright 浏览器和上下文实例的生命周期管理器。两者所处分层与职责截然不同，不应强行合并。

**批次:** dup-C-crawling-auth | **置信度:** MEDIUM

**涉及函数:**

- `acquire` @ `domains/crawling/profile_pool.py:117` — 实现：\_get_or_create_profile_for_update → 校验 BLOCKING_STATUSES / lease_until → 写 status=LEASED、lease_owner/task_id/until/last_used_at → commit → 返回 ProfileLease
- `release` @ `domains/crawling/profile_pool.py:162` — 实现：按 profile_key FOR UPDATE 查 → 校验 owner / task_id 匹配 → 清空 lease 字段 → commit
- `renew` @ `domains/crawling/profile_pool.py:183` — 实现：按 profile_key FOR UPDATE 查 → 校验 owner / task_id 匹配 → 写 lease_until / last_used_at / updated_at → commit
- `acquire` @ `domains/crawling/browser_manager.py:149` — 实现：context manager 包了 BrowserManager 自己的 acquire——它内部通过 profile_pool.acquire(...) 拿到 ProfileLease 后再启动 Playwright context（与 profile_pool.acquire 是不同抽象层，但同样处理 lease 状态机）
- `_assert_profile_usable` @ `domains/crawling/browser_manager.py:133` — 实现：与 profile_pool.acquire 中的 'BLOCKING_STATUSES 检查' 重复——只是没做写操作，且额外发了 system log

**实现差异:** profile_pool.acquire 是 DB 层 lease 写；browser_manager.acquire 是 contextmanager 层（拿到 lease 后还要启 Playwright context）。\_assert_profile_usable 与 profile_pool.acquire 的状态校验高度同构。

**建议:** **INVESTIGATE**。browser_manager 内部似乎已经委托给 profile_pool.acquire。\_assert_profile_usable 是为了在拿到 lease 之前做一次预检（同时发日志），与 profile_pool.acquire 的 BLOCKING_STATUSES 检查语义重叠；若预检被绕过也不会真正出错。可以让 \_assert_profile_usable 直接调用 profile_pool 模块的状态判定函数（提取 \_check_profile_blocking），让两处的阻断状态值同源。

---

### ❌ curl_cffi 构造带浏览器伪装的 HTTP headers [保持独立]

**保留理由:** 属于 `liepin.py` 平台适配器内部的方法，分别用于猎聘的同步页面抓取和 Ajax API，是平台私有且特异的逻辑。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `_search_page_headers` @ `platforms/liepin.py:266` — 猎聘搜索页:固定 Accept/Accept-Language 两项浏览器伪装。
- `_headers` @ `platforms/liepin.py:272` — 猎聘 API:从响应中提取 xsrf-token 注入 X-XSRF-TOKEN,基础 UA/Referer/X-Client-Type 等字段。

**实现差异:** 同一适配器内部的两个不同方法:\_search_page_headers 给搜索页用(简单 Accept),\_headers 给 API 用(注入动态 xsrf-token)。

**建议:** **KEEP_SEPARATE**。两者属于 liepin 适配器内部两个不同请求场景的 headers 工厂,语义不同(页面 vs API),不应合并。命名 \_search_page_headers vs \_headers 略不一致,建议重命名为 \_page_headers / \_api_headers 以保持配对风格。

---

### ❌ jobs LLM 三个 provider(anthropic/openai/ollama)的 analyze_match 实现共享同一 prompt 模板与 MatchAnalysis 装配逻辑 [保持独立]

**保留理由:** 属于策略模式的意图多态实现。三个 provider 所依赖的基础 SDK 调用方式、网络超时、以及具体的 payload 解析大不相同。保持独立更便于未来针对各个平台进行差异化调优和提示词改进。

**批次:** dup-B-jobs-products | **置信度:** MEDIUM

**涉及函数:**

- `analyze_match` @ `domains/jobs/llm/anthropic.py:17` — Anthropic /messages 端点 + Bearer token + extract_json + MatchAnalysis 装配
- `analyze_match` @ `domains/jobs/llm/openai.py:17` — OpenAI /chat/completions 端点 + Bearer token + extract_json + MatchAnalysis 装配
- `analyze_match` @ `domains/jobs/llm/llm/ollama.py:17` — Ollama /api/chat 端点(无鉴权)+ extract_json + MatchAnalysis 装配
- `analyze_match` @ `domains/jobs/llm/provider.py:26` — LLMProvider ABC 抽象方法定义

**实现差异:** 三处 HTTP 端点、headers、消息结构(response.choices[0].message.content vs data.content[].text vs data.message.content)、模型默认值不同,但 prompt 字符串(行 44-48 / 33-38 / 30-34)与 MatchAnalysis 装配(extract_json → score/reason/recommendation/model_used)字节级一致。

**建议:** **INVESTIGATE**。这是策略模式的有意多实现,不能合并三个类。但 prompt 模板硬编码三次、MatchAnalysis 装配三遍是真实重复:建议将 prompt 与 \_build_match_analysis(extract_json) 抽到 jobs/llm/utils.py 与 jobs/llm/prompts.py,三个 provider 只保留差异化的 HTTP 调用与 content 提取。这是设计内多态但 prompt 字符串硬编码属于可清理的轻微重复。

---

### ❌ jobs match 批处理核心循环在 match_service.py 的 analyze_resume_vs_jobs 与 \_execute_match_analysis 中重复 [保持独立]

**保留理由:** 两者运行在不同的业务层次上，分别负责不同粒度的任务批处理和直接简历比对逻辑。合并会导致参数和逻辑极其繁杂，降低并发控制代码的可读性。

**批次:** dup-B-jobs-products | **置信度:** MEDIUM

**涉及函数:**

- `_execute_match_analysis` @ `domains/jobs/match_service.py:102` — 接受 CrawlTask,更新 task.status / task.errors,带可选 progress_callback;走 \_analyze_one + semaphore + zip 循环 + upsert_match_result + 飞书通知
- `analyze_resume_vs_jobs` @ `domains/jobs/match_service.py:353` — 同步入口,返回 processed/created/updated/skipped/items dict;内部 \_analyze_one + semaphore + zip 循环 + upsert_match_result + 飞书通知结构与 \_execute_match_analysis 几乎相同

**实现差异:** \_execute_match_analysis 通过 CrawlTask 暴露进度、有 user_id 校验与 task.errors 累加;analyze_resume_vs_jobs 直接返回聚合结果 dict,硬编码 user_id == 1。两者的 valid_jobs 过滤、信号量并发、asyncio.gather、zip 循环、notify_jobs 排序与飞书消息拼装几乎是同一份代码。

**建议:** **INVESTIGATE**。建议抽取一个内部 \_run_match_pipeline(db, resume, jobs, on_item=None, on_complete=None) 共享核心循环,两个公开函数只保留 '包装 + 进度回报' 的差异。但需确认 analyze_resume_vs_jobs 是否仍被外部调用,以及硬编码 user_id == 1 的旧路径是否计划废弃。

---

### ✅ products service 中 delete_product_cron_config 与 remove_product_cron_config 命名冲突/职责不清 [已合并修复]

**修复详情:** 将 `service.delete_product_cron_config` 重命名为 `get_product_cron_config_for_deletion`（理清其获取与校验的真实职责），并将 `service.remove_product_cron_config` 重命名为 `delete_product_cron_config`（使其符合数据库物理删除命名规范）。同步更新了 `products/router.py` 中的调用代码。

**批次:** dup-B-jobs-products | **置信度:** MEDIUM

**涉及函数:**

- `delete_product_cron_config` @ `domains/products/service.py:195` — 根据 platform 查找 config 并返回 config,但并没有真正 delete,需要 router 后续再调用 repository.delete_product_cron_config
- `remove_product_cron_config` @ `domains/products/service.py:210` — 对传入的 config 实例调用 repository.delete_product_cron_config,完成实际删除

**实现差异:** 前者是 'load + validate + return',后者是 'pure delete on already-loaded instance'。两个函数都需要存在以支持 router 的两段式语义(load → remove),但命名一致度高,容易混淆。

**建议:** **INVESTIGATE**。这与 jobs 的 delete_job_config / remove_job_config 是同一类问题:出现成对的 load+delete。考虑统一命名约定,例如 delete_product_cron_config 仅负责 load_by_platform,真正的删除合并到 router 的内联调用,或反过来在 service 层一次性完成 load+delete。另外 service.delete_product_cron_config 名字暗示做了删除,实际只 load,容易误导调用者。

---

### ❌ trend 数据的“按日期分组聚合”查询模式(通用 SQL 模板) [保持独立]

**保留理由:** 分属不同业务维度（商品趋势、职位趋势、系统趋势）的聚合查询。各个查询所关联的表、统计方式（平均、计数、比率）完全不同，共用 SQL 模板将极大破坏其可维护性与索引调优空间。

**批次:** dup-D-infra-dashboard-smart | **置信度:** MEDIUM

**涉及函数:**

- `_get_price_trends_uncached` @ `domains/dashboard/dashboard_service.py:317` — select(cast(date_col, Date), func.avg/func.count).where(user_id, since).group_by(date).order_by(date)
- `_get_job_trends_uncached` @ `domains/dashboard/dashboard_service.py:431` — 同上,只是 metric 列换为 func.count,过滤来源是 Job+JobSearchConfig
- `_get_job_match_trends_uncached` @ `domains/dashboard/dashboard_service.py:483` — 同上,增加了 func.avg(match_score) 第二个 dataset
- `_get_system_health_trends_uncached` @ `domains/dashboard/dashboard_service.py:643` — 同结构,用 case(SUCCESS) 计算 success rate

**实现差异:** 4 处都是 select(cast(date_col, Date).label('date'), aggregate).where(time_window).group_by(date).order_by(date),只是 date 列、聚合函数、过滤条件不同。最后的 zip → TrendResponse(labels, [TrendDataset(...)]) 也是同一段模板。

**建议:** **INVESTIGATE**。可考虑抽取 \_daily_buckets(db, base_query, date_col, metrics) 返回 dict[date, dict[metric, float]],减少 SQL 模板重复;但每个查询的 join/user_id 过滤/case 表达式差异较大,过度抽象反而损害可读性。可作为低优先级的可选重构

---

### ❌ worker recover 运行时状态(过期任务回收 + 过期 profile 租约释放) [保持独立]

**保留理由:** 任务清理和 Profile 租约释放分别操作不同的持久化实体（`crawling_tasks` vs `browser_profiles`）。分别定义两个独立的恢复步骤，有利于 worker 启动时进行细粒度状态管理和日志观测。

**批次:** dup-D-infra-dashboard-smart | **置信度:** MEDIUM

**涉及函数:**

- `recover_crawler_runtime_state` @ `main.py:46` — app 启动时:recover_stale_running_tasks(owner_reason='worker_restarted') + recover_stale_profile_leases
- `_recover_runtime_state` @ `workers/crawler.py:153` — worker 启动时:recover_stale_running_tasks(owner_reason='worker_stale_lease') + recover_stale_profile_leases + mark_stale_workers_offline + aggregate_waiting_job_parent_tasks

**实现差异:** 两处都先 recover_stale_running_tasks 再 recover_stale_profile_leases。区别:main 版 owner_reason='worker_restarted'、只调两个;worker 版 owner_reason='worker_stale_lease'、多调 mark_stale_workers_offline 和 aggregate_waiting_job_parent_tasks,顺序略不同。

**建议:** **INVESTIGATE**。owner_reason 区分了不同调用方,职责有别。建议把 'recover_stale_running_tasks + recover_stale_profile_leases' 这对原子操作合并为 recover_crawler_runtime_baseline(reason) 公共 helper,两边再追加各自的额外步骤

---

### ❌ 为 platform crawler 适配器生成带时间戳的 jsonl 日志文件路径 [保持独立]

**保留理由:** 各个平台适配器（如 Boss 直聘特有 Cloak 日志）的归档行为与反爬调试深度绑定，各自配置独立的路径有助于平台层面的故障排查。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `_make_default_log_path` @ `platforms/boss_cloak_experimental.py:532` — Path(**file**).resolve().parents[2] / 'logs' / f'boss*cloak_adapter*{stamp}.jsonl',stamp 由调用方传入(来自 time.strftime)。
- `default_job_log_path` @ `platforms/job_runtime_logging.py:11` — 模块级公共函数,接受 platform 参数,内部 datetime.now(UTC).strftime('%Y%m%d*%H%M%S'),文件名格式 '{platform}\_job_adapter*{timestamp}.jsonl'。

**实现差异:** boss 版本是实例方法、文件名带 'cloak_adapter' 前缀,接收 stamp;公共版本接受 platform 参数生成通用 'job_adapter' 文件名。两者路径计算逻辑相同(都从项目根 → logs/),时间戳格式相同。

**建议:** **CONSOLIDATE** — 保留 `backend/app/platforms/job_runtime_logging.py:default_job_log_path`。boss 适配器的 _make_default_log_path 完全可以调用 job_runtime_logging.default_job_log_path('boss_cloak')(或类似 key)拿到路径,内部去重后只剩一份路径生成逻辑。重构后路径格式需要权衡:要么统一成 '{platform}\_job_adapter_{ts}.jsonl',要么保留 'boss_cloak_adapter' 别名以避免日志收集规则改动。

---

### ❌ 前端 ThemeProvider 与 useTheme 共享 localStorage 初始值读取模式 [保持独立]

**保留理由:** `ThemeProvider` 负责全局 React 树的主题 Context 状态注入，而 `useTheme` 负责组件层消费。这是标准的 React 状态管理实践，局部读取默认值是合理的设计。

**批次:** dup-E-alerts-frontend | **置信度:** MEDIUM

**涉及函数:**

- `getInitialMotionSpeed` @ `shared/components/ThemeProvider.tsx:14` — 从 localStorage 读取动效速度
- `getInitialTheme` @ `shared/hooks/useTheme.ts:9` — 从 localStorage 读取主题
- `applyThemeToDOM` @ `shared/hooks/useTheme.ts:24` — 将主题写入 document 根属性

**实现差异:** 都是 localStorage + fallback 默认值的同一模式,只是 key 和 default 不同

**建议:** **CONSOLIDATE** — 保留 `shared/utils/storage.ts:getInitialLocalStorageValue`。建议抽取 getInitialLocalStorageValue<T>(key, parse, default) 通用工具,统一 SSR-safe 的 try/catch 模式

---

### ❌ 前端 useTodayData 中 buildHomeSignal 与 todayBrief.buildHomeStatus 都消费同一家居数据源 [保持独立]

**保留理由:** 前者用于今日界面卡片的交互动作响应，后者用于构建一次性文案快照。两者在呈现维度和状态响应上完全解耦，不宜物理合并。

**批次:** dup-E-alerts-frontend | **置信度:** MEDIUM

**涉及函数:**

- `buildHomeSignal` @ `features/today/hooks/useTodayData.ts:29` — 组装家居信号源(配置+实体)
- `buildHomeStatus` @ `features/today/todayBrief.ts:56` — 构建家居设备模块状态(消费已组装的信号)

**实现差异:** buildHomeSignal 在 hook 层负责 '从配置+实体组装成 Signal',buildHomeStatus 在 todayBrief 层负责 '从 Signal 计算状态展示',职责分离合理

**建议:** **KEEP_SEPARATE**。属于分层 '组装数据' 与 '从数据派生展示状态' 的标准分层,不重复

---

### ❌ 前端权限位处理 - getAdminErrorMessage / isFormValidationError / formatApiError 都解析后端错误 [保持独立]

**保留理由:** 三者所消费的错误上下文、对应的 UI 表单位置和返回的数据类型完全不同，针对具体应用场景保留专门的错误转化函数更加清晰。

**批次:** dup-E-alerts-frontend | **置信度:** MEDIUM

**涉及函数:**

- `getAdminErrorMessage` @ `features/admin/AdminUsersPage.tsx:67` — 从后端错误中提取 detail
- `isFormValidationError` @ `features/admin/AdminUsersPage.tsx:72` — 判断表单校验错误
- `formatApiError` @ `shared/api/client.ts:57` — 统一格式化后端错误响应

**实现差异:** getAdminErrorMessage 与 formatApiError 都是 '从 error 对象提取 detail 字段' 的同一逻辑

**建议:** **CONSOLIDATE** — 保留 `shared/api/client.ts:formatApiError`。AdminUsersPage 的 getAdminErrorMessage 与 isFormValidationError 应删除,统一调用 formatApiError 与共享类型守卫

---

### ❌ 前端权限徽章 - getBadgeLevel 与 PermissionBadge 组件共享权限→等级映射 [保持独立]

**保留理由:** 属于 Presentation 层组件内部的轻量级常量映射。对于 UI 表达细节，保持组件内部紧凑和自包含更佳，无需全局泛化。

**批次:** dup-E-alerts-frontend | **置信度:** MEDIUM

**涉及函数:**

- `getBadgeLevel` @ `utils/permissionBadge.ts:3` — 根据权限位计算徽章等级(纯函数)
- `PermissionBadge` @ `shared/components/PermissionBadge.tsx:21` — 权限徽章展示组件,内部应调用 getBadgeLevel

**实现差异:** 工具与组件的分离本身合理,但要确认 PermissionBadge 是否真的复用了 getBadgeLevel

**建议:** **INVESTIGATE** — 保留 `utils/permissionBadge.ts:getBadgeLevel`。需要核查 PermissionBadge 内部是直接做了位运算还是复用了 getBadgeLevel;如果重复实现则合并

---

### ❌ 前端调度管理 hook - useJobConfigSchedule / usePlatformSchedule / useScheduleConfig 共存 [保持独立]

**保留理由:** 分别服务于职位调度、商品调度和系统通用调度页面。各个 hook 的 queryKey、依赖字段和失效更新机制（Invalidate Queries）完全特异，分写有利于状态治理。

**批次:** dup-E-alerts-frontend | **置信度:** MEDIUM

**涉及函数:**

- `useJobConfigSchedule` @ `features/schedule/hooks/useJobConfigSchedule.ts:6` — 职位配置调度管理
- `usePlatformSchedule` @ `features/schedule/hooks/usePlatformSchedule.ts:8` — 平台级调度管理
- `useScheduleConfig` @ `features/schedule/hooks/useScheduleConfig.ts:5` — 查询全局调度配置
- `useUpdateScheduleConfig` @ `features/schedule/hooks/useScheduleConfig.ts:11` — 更新全局调度配置
- `useCronGenerator` @ `features/schedule/hooks/useCronGenerator.ts:8` — Cron 生成器状态 hook

**实现差异:** 四个 hook 都在 schedule 域,职责分工明确:配置调度 / 平台调度 / 全局配置 / Cron 生成器 UI 状态

**建议:** **INVESTIGATE** — 保留 `useScheduleConfig.ts`。需要核查 useJobConfigSchedule 与 usePlatformSchedule 是否只是 useScheduleConfig 的 domain 参数化版本;如果是可合并为单一 useDomainSchedule(domainId)

---

### ❌ 后端 HTTP 端点薄壳 - alerts router 与 config router 共享相同 REST 骨架 [保持独立]

**保留理由:** 这是 FastAPI 中各实体独立的 router 注册。由于不同路由在权限依赖性、路径变量类型以及查询过滤上均存在差异，保持各自的 REST 骨架有助于模块独立演进。

**批次:** dup-E-alerts-frontend | **置信度:** MEDIUM

**涉及函数:**

- `create_alert` @ `domains/alerts/router.py:16` — POST 创建
- `list_alerts` @ `domains/alerts/router.py:31` — GET 列表
- `get_alert` @ `domains/alerts/router.py:44` — GET 单项
- `update_alert` @ `domains/alerts/router.py:59` — PATCH 部分更新
- `delete_alert` @ `domains/alerts/router.py:75` — DELETE 删除
- `create_or_update_config` @ `domains/config/router.py:32` — POST 整体替换
- `get_config` @ `domains/config/router.py:45` — GET 单项
- `update_config_partial` @ `domains/config/router.py:54` — PATCH 部分更新

**实现差异:** alerts 是面向多资源的 RESTful CRUD,config 只有单个对象所以只有 create-or-update + get + partial update

**建议:** **KEEP_SEPARATE**。FastAPI 路由必须显式声明,即使有重复也应保持显式;考虑用 dependency-injection 抽公共错误处理

---

### ❌ 后端提醒 CRUD 业务逻辑层(校验存在性 + 委托仓库) - alerts service 与 config service 共享相同骨架 [保持独立]

**保留理由:** Service 业务逻辑层承担了本领域的校验规则。强行合并会增加不必要的参数重载，使两个完全无关的业务领域（警报通知 vs 用户全局配置）物理耦合。

**批次:** dup-E-alerts-frontend | **置信度:** MEDIUM

**涉及函数:**

- `create_alert` @ `domains/alerts/service.py:18` — 校验商品所有权后写库
- `update_alert` @ `domains/alerts/service.py:54` — 校验存在性后修改
- `delete_alert` @ `domains/alerts/service.py:63` — 校验存在性后删除
- `create_or_update_config` @ `domains/config/service.py:29` — 创建或整体替换
- `update_config_partial` @ `domains/config/service.py:38` — 部分更新

**实现差异:** alerts 面向商品-提醒关系校验所有权,config 面向单用户配置无所有权校验;二者本质都是 '校验 + 委托仓库' 的薄壳

**建议:** **KEEP_SEPARATE**。业务语义不同(多对象关系 vs 单用户配置),但两者都可考虑引入通用 BaseCRUDService 减少样板

---

### ❌ 懒加载 curl_cffi CffiSession(各平台 HTTP 请求的客户端入口) [保持独立]

**保留理由:** 各个平台适配器对 HTTP 指纹伪装、重试间隔、和 Cookie 载入有极强的环境依赖性。保持各自独立的 session 工厂可有效减少全局风控的连锁反应。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `_get_session` @ `platforms/boss_cloak_experimental.py:99` — if self.\_session is None: self.\_session = CffiSession(); return self.\_session。纯懒加载,无 profile cookie 注入。
- `_get_session` @ `platforms/job51.py:121` — 与 boss 版完全相同的 4 行懒加载骨架,无 profile cookie 注入。
- `_get_session` @ `platforms/liepin.py:68` — 懒加载 CffiSession 后,立即调用 self.\_ensure_profile_cookies(self.\_session) 自动从 Chromium profile 加载 Cookie。

**实现差异:** boss / job51 是纯懒加载;liepin 在懒加载后多做一步 profile cookie 注入(平台特化需求)。

**建议:** **INVESTIGATE**。boss 与 job51 几乎是同模板的 4 行复制粘贴,可考虑抽到 base 类或 mixin(如 BaseJobAdapter.\_get_session)消除重复;但 liepin 因为额外 profile cookie 逻辑无法直接共用,需要决定是参数化(is_load_profile_cookies: bool)还是仅让 liepin 覆写。属于小范围重构,价值中等。

---

### ❌ 把爬虫拿到的原始职位数据转换为项目统一的标准化 Job 字段 [保持独立]

**保留理由:** 属于典型的适配器模式（Adapter Pattern）。因为各个招聘平台（Boss、51job、猎聘）返回的 JSON 或 HTML 载荷字段各异，需要各个平台特定的 mapper 函数来转换到 `Job` 统一模型中。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `_transform_job` @ `platforms/boss_cloak_experimental.py:545` — Boss 单条:从 securityId/encryptJobId/jobName/brandName/salaryDesc/cityName 等字段映射到 job_id/title/company/salary/location 等标准字段,接收 lid 参数回填。
- `_transform_jobs` @ `platforms/job51.py:555` — 51job 批量:从 jobId/jobName/fullCompanyName 等映射,job_id 为空时跳过。
- `_transform_jobs` @ `platforms/liepin.py:360` — 猎聘批量:cls.\_job_id_from_link(link) 提取数字 id,job / comp 嵌套结构,也是空 id 跳过。

**实现差异:** 三处目标字段名(job_id, title, company, salary, location, experience, education, url)相同,但来源字段名/嵌套结构/列表 vs 单条差异巨大;boss 还接收 lid 上下文回填。

**建议:** **KEEP_SEPARATE**。三处属于'同一目的'但完全是平台特化的数据规整,各平台原始 payload schema 差异巨大,抽象只能得到一个巨型 if-elif 分发,反而难维护。保持独立;但应保证输出 dict 字段名与 Job ORM 严格一致(建立单元测试 freeze 该 schema)。

---

### ❌ 按 user_id 列表删除该用户会话 [保持独立]

**保留理由:** 此逻辑在管理员注销特定用户和普通用户个人安全密码重置时各自调用，因关联的权限校验和操作审计级别不同，在各领域保留专门的控制链路更有保障。

**批次:** dup-D-infra-dashboard-smart | **置信度:** MEDIUM

**涉及函数:**

- `delete_other_sessions` @ `core/sessions.py:209` — 删除 current_session_id 之外的所有会话,走 \_delete_sessions_by_query + commit=True
- `stage_delete_other_sessions` @ `core/sessions.py:247` — 和 delete_other_sessions 几乎相同,只差 commit 参数(交给调用方 commit)
- `stage_delete_user_sessions` @ `core/sessions.py:237` — 删除用户全部会话,stage 版本

**实现差异:** 三处都是 select(Session).where(user_id=...) 然后 delete。delete_other_sessions 和 stage_delete_other_sessions 的 SQL 完全一致,唯一区别是 commit 由谁负责。stage_delete_user_sessions 是同模式删全部。

**建议:** **INVESTIGATE** — 保留 `backend/app/core/sessions.py:_delete_sessions_by_query`。delete*other_sessions 和 stage_delete_other_sessions 应合并为一个参数化函数(delete_other_sessions(user_id, current_id, \*, commit=True/False));若决定统一 stage*\* 语义,可让 delete_other_sessions 内部调用 stage 版,避免双向 API

---

### ❌ 敏感字段脱敏(审计 details / 系统日志 payload) [保持独立]

**保留理由:** 审计日志 `details` 是面向用户的操作细节，采用平面比对脱敏；系统日志 `payload` 则需要深度递归字典树。两处的应用数据结构复杂度与合规级别不同。

**批次:** dup-D-infra-dashboard-smart | **置信度:** MEDIUM

**涉及函数:**

- `_sanitize_details` @ `core/audit.py:21` — 对 details 字典做敏感 key 替换为 '**_REDACTED_**',key 集合含 password/token/ha_token 等
- `redact_payload` @ `core/log_redaction.py:24` — 递归处理 Mapping/list/tuple/set,对 key 命中 FULL_REDACT_KEYS 替换为 '**_REDACTED_**'

**实现差异:** 两者都脱敏,目标都是 '**_REDACTED_**',但 \_sanitize_details 只处理 dict 一层、用不同 key 集合;redact_payload 递归、支持 list/tuple/set、key 集合在 FULL_REDACT_KEYS 常量。\_sanitize_details 在写入 audit 前调用,redact_payload 在 normalize_audit_log/normalize_system_log 里被调用,两套机制并行。

**建议:** **CONSOLIDATE** — 保留 `backend/app/core/log_redaction.py:redact_payload`。audit.\_sanitize_details 完全可以被 redact_payload 取代(后者功能更强),应将 audit 的 sensitive_keys 集合并入 log_redaction 的 FULL_REDACT_KEYS,让 log_audit → redact_payload(log.details) 一行化。统一一套脱敏机制,减少双轨维护

---

### ❌ 日志写入失败时的 best-effort 兜底 [保持独立]

**保留理由:** 这是写入操作失败时的防崩溃安全边界逻辑，在各层使用 inline 形式的 fail-safe try-except 可以避免日志插件故障拖垮主干业务。

**批次:** dup-D-infra-dashboard-smart | **置信度:** MEDIUM

**涉及函数:**

- `log_audit` @ `core/audit.py:65` — try/except + logger.warning + return None,异常时不 rollback(留给调用方)
- `emit_system_log` @ `core/system_log.py:89` — 同模式 + commit 时若失败尝试 rollback

**实现差异:** 主体 try/except 结构几乎逐行相同:create record → db.add → commit? → return record;except → logger.warning with extra context → return None。仅 commit 失败时 rollback 处理不同。

**建议:** **KEEP_SEPARATE**。两个 log writer 写入不同表(AuditLog vs SystemLog),共享会引入耦合;现有结构已经清晰,只是 try/except 模板重复,可考虑通用 safe_db_write 装饰器但收益有限

---

### ❌ 根据响应 payload/状态识别反爬风控错误类别 [保持独立]

**保留理由:** 不同平台（淘宝、猎聘、Boss直聘）的风控和滑块拦截特征完全不同，针对具体平台独立编写拦截规则便于进行精细的反爬绕过定制。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `classify_boss_failure` @ `platforms/boss_cloak_experimental.py:38` — 模块级函数,读 payload['code'],命中 ANTI_BOT_CODES={36,37,38} 时返回 'anti_bot'。
- `classify_51job_response` @ `platforms/job51.py:35` — 模块级函数,读 contentType + body,识别 WAF / Challenge / 正常 JSON 三个类别。
- `classify_liepin_failure` @ `platforms/liepin.py:31` — 模块级函数,接 status_code + text,识别 xsrf/csrf/waf 等。

**实现差异:** 三处都是模块级 classify_xxx_failure 工具,签名(参数:payload vs status_code+text)、返回标签集(anti_bot vs waf/challenge/xsrf/csrf)都不同。

**建议:** **KEEP_SEPARATE**。各平台反爬信号完全独立(错误码 / 关键字 / 状态码),平台特化强,合并只能得到 if platform == 'X' 分发。保持独立,签名差异(单 dict vs 双参数)合理反映各自信号源。

---

### ❌ 爬取任务的持久化 lease/claim/requeue/renew 操作集 [保持独立]

**保留理由:** `task_store.py` 面向分布式爬取任务状态机，而 `worker_registry.py` 面向分布式 worker 节点节点生命周期。两者的抽象实体不同，属于正当的语义相似。

**批次:** dup-C-crawling-auth | **置信度:** MEDIUM

**涉及函数:**

- `claim_next_pending_task` @ `domains/crawling/task_store.py:177` — 实现：SELECT … FOR UPDATE SKIP LOCKED → 写 locked_by / lease_until / heartbeat_at / available_at / started_at / updated_at 后 commit
- `renew_task_lease_by_id` @ `domains/crawling/task_store.py:228` — 实现：按 task_id + worker_id 查记录 → 写 heartbeat_at / lease_until / updated_at 后 commit
- `requeue_claimed_task` @ `domains/crawling/task_store.py:254` — 实现：按 task_id + worker_id 查记录 → 重置 status / lease / available_at，递增 attempt_count；含可选 retry_delay
- `recover_stale_running_tasks` @ `domains/crawling/task_store.py:299` — 实现：扫描 lease_until < threshold 的 RUNNING 任务 → 重置为 PENDING（与 worker 的 mark_stale_workers_offline 是孪生操作）
- `heartbeat_worker` @ `domains/crawling/worker_registry.py:58` — 实现：按 worker_id 查记录 → 写 status='online' / last_heartbeat_at / updated_at 后 commit
- `mark_worker_stopping` @ `domains/crawling/worker_registry.py:79` — 实现：按 worker_id 查记录 → 写 status='stopped' / stopped_at / updated_at 后 commit
- `mark_stale_workers_offline` @ `domains/crawling/worker_registry.py:100` — 实现：SELECT last_heartbeat_at < threshold 的 online 记录 → 写 status='offline' / updated_at 后 commit

**实现差异:** 1) task_store 操作的是 CrawlTaskRecord 表，worker_registry 操作的是 CrawlerWorkerRecord 表——两张不同表。2) 但语义高度同构：'获取 → 加锁式条件更新 → commit → refresh' 的样板，'按时间阈值批量下线' 的扫表模式。3) 不是字面级重复，是模板级重复。

**建议:** **INVESTIGATE**。两套代码各管一张表，目前没有共享 helper（如 \_heartbeat(record, now)、\_mark_offline_where_stale(model, threshold)）。可以接受保留独立模块（域边界清晰），但建议在 app/core/db_helpers.py 提供 \_upsert_by_id / \_bulk_mark_stale 等小工具，让两个 repository 都改用同一套样板；减少后续打补丁时遗漏某处的风险。

---

### ❌ 爬取状态机：crawling/service.py 的 \_persist_product_crawl_result 与 crawling/router.py 的 \_crawl_one 互为薄包装 [保持独立]

**保留理由:** 前者是爬虫服务层中负责数据落库的核心方法，后者是面向调试接口的解析包装器。这属于经典的分层设计，不应物理合并。

**批次:** dup-C-crawling-auth | **置信度:** MEDIUM

**涉及函数:**

- `crawl_one` @ `domains/crawling/service.py:157` — 实现：直接调 crawl_one_opencli(product_id=…, platform='')，仅一行 docstring 'Deprecated: use crawl_one_opencli'
- `_crawl_one` @ `domains/crawling/router.py:17` — 实现：直接调 crawling_service.crawl_one(product_id)——'Compatibility wrapper used by scheduler_service'

**实现差异:** \_crawl_one 是 router 内的私有 wrapper（只被 router 内部使用，但 router 里实际也未直接调用——只有 docstring 提到 scheduler_service）；crawl_one 是 service 层的 deprecated 转发。

**建议:** **INVESTIGATE**。两个都是无用包装。crawl_one 是已标记 Deprecated 的薄壳（OpenCLI 路径取代了浏览器路径），\_crawl_one 也没有被 router 内任何函数调用——需要先确认 scheduler_service 是否真在调用 \_crawl_one（grep 显示并没有），若是死代码应直接删除，让所有调用方都走 crawl_one_opencli 或 service 层别名。

---

### ❌ 用户资料更新（username/email 冲突检测 + 写入）——auth 与 admin 业务逻辑高度同构 [保持独立]

**保留理由:** `auth` 服务更新的是当前会话用户的资料，而 `admin` 服务则是后台管理员对全站任意用户的管理更新。由于两者的权限安全等级不同，分写可以最大程度防止越权（IdP 污染）漏洞。

**批次:** dup-C-crawling-auth | **置信度:** MEDIUM

**涉及函数:**

- `update_profile` @ `domains/auth/service.py:128` — 实现：username 变更 → 调 repository.get_active_user_by_username(exclude_user_id=...) 查冲突；email 变更同理；写 user.username / user.email → repository.save_user
- `register_user` @ `domains/auth/service.py:27` — 实现：先 get_user_by_username / get_user_by_email 查冲突 → repository.add_user 新建 User
- `create_user` @ `domains/admin/service.py:103` — 实现：先 get_active_user_by_username / get_active_user_by_email 查冲突 → repository.add_user 新建 User。结构与 auth.register_user 高度相似，差异在 role 边界 + 密码散列
- `update_user` @ `domains/admin/service.py:134` — 实现：username 变更 → get_active_user_by_username(exclude_user_id=...) 查冲突；email 变更同理；遍历 update_dict 应用 setattr；含角色变更 / 软删除 / 审计 hooks。比 auth.update_profile 多很多业务规则，但冲突检测代码段完全一致

**实现差异:** admin 版本多了 role 边界 / 软删除 / 会话失效 / 审计 hooks；auth 版本更简单。两个 register/create 都包含 '查 username 冲突 → 查 email 冲突 → add_user' 的相同骨架。

**建议:** **INVESTIGATE**。冲突检测（'给定 (field, value, exclude_user_id) 是否存在冲突用户'）这个动作可以下沉为 \_ensure_user_field_available(db, field, value, exclude_user_id)，让 register_user / create_user / update_profile / update_user 都复用；目前在四个函数中各写一次 if existing: raise，容易在新增第 3 个字段（如 phone）时漏改。重复度中等但修一个 bug 要改 4 处。

---

### ❌ 职位爬虫适配器从 search URL 解析出搜索参数 [保持独立]

**保留理由:** 针对各个招聘平台（Boss、51job、猎聘）其参数编码、地区代码（如城市码和区码）格式完全定制，无法抽象出普适的解析器。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `_parse_search` @ `platforms/boss_cloak_experimental.py:533` — 独立静态方法:urlparse + parse_qs 取 query/city,缺失时回退 DEFAULT_QUERY/DEFAULT_CITY。
- `_parse_search` @ `platforms/job51.py:379` — job51 适配器附近的 \_parse_search,从 URL 解析 keyword + jobArea,缺失时用 000000。
- `crawl` @ `platforms/liepin.py:215` — liepin 的 URL 解析直接内联在 crawl 入口(取 key/dqs),没有抽成 \_parse_search。

**实现差异:** boss/job51 已抽成 \_parse_search 静态方法,liepin 仍内联在 crawl 主体。三者查询参数名(query vs key/keyword、city vs dqs/jobArea)和默认值都不同,属于平台特化。

**建议:** **KEEP_SEPARATE**。虽然目的都是'从 URL 解析搜索参数',但每个平台的 query string 字段名和默认值都不同,平台特化属性强,合并会引入分支判断降低可读性。liepin 只是命名风格不统一,建议把内联解析抽成 \_parse_search 保持命名一致,但不要和 boss/job51 共享实现。

---

### ❌ 读取/解密 Chromium profile 的 Cookies 数据库和 Local State 加密 key [保持独立]

**保留理由:** 这是猎聘爬虫（liepin.py）专有的、针对 Windows 平台 DPAPI 的本地解密管线，没有其他模块需要访问该硬件密钥，局部化最符合安全最小暴露原则。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `_read_chromium_cookie_rows` @ `platforms/liepin.py:111` — sqlite3 直读 Cookies 表的 host_key/path/name/encrypted_value 字段,返回 dict 列表。
- `_load_chromium_cookie_key` @ `platforms/liepin.py:137` — 读 Local State JSON,取 os_crypt.encrypted_key,去掉 'DPAPI' 前缀后调用 \_windows_dpapi_unprotect。
- `_decrypt_chromium_cookie_value` @ `platforms/liepin.py:152` — 识别 v10/v11/v20 前缀,AES-GCM 解密并去除 PKCS#7 padding。
- `_decode_chromium_cookie_plaintext` @ `platforms/liepin.py:166` — 从明文中识别 cookie 值(处理前缀/PKCS#7 padding 残留)。
- `_windows_dpapi_unprotect` @ `platforms/liepin.py:178` — Windows DPAPI CryptUnprotectData 解密,处理 NULL LocalFree。

**实现差异:** 五个方法协同完成同一个 cookie 加载流程,内部职责清晰(读行→读 key→解 key→解值→提值)。

**建议:** **KEEP_SEPARATE**。这五个方法是 liepin 内部完整的'读 Chromium profile Cookie'管线,职责单一拆分合理,目前没有跨平台复用需求(其他平台走 CloakBrowser,只有 liepin 用 curl_cffi 加载本地 profile)。若未来 boss/job51 也要走 profile cookie,可整体抽到 platforms/middleware/chromium_cookie_loader.py。

---

### ❌ 适配器 crawl 入口 [保持独立]

**保留理由:** 属于平台爬虫公共的多态异步方法契约规范。因为底层调用引擎（如 Playwright 与 curl_cffi）是同态而异构的，保留该外观层异步分发可以实现统一的任务调用。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `crawl` @ `platforms/base.py:218` — 商品基类:检查 product_cdp_fallback_enabled,调 \_init_browser、加载页面、extract_price/extract_title,90s 超时。
- `crawl_with_page` @ `platforms/base.py:167` — 商品基类:由 BrowserManager session 注入 page,直接 goto + 提取 + classify_failure,无超时(由外层 session 管理)。
- `crawl` @ `platforms/boss_cloak_experimental.py:104` — Boss 列表:asyncio.to_thread(self.\_crawl_sync, url) 一行包装。
- `crawl` @ `platforms/job51.py:268` — 51job 列表:启动 CloakBrowser→调 \_fetch_search_page_sync 串行分页,完全自己实现未用 to_thread。
- `crawl` @ `platforms/liepin.py:215` — liepin 列表:解析 URL→runtime_logger.log start→asyncio.to_thread(self.\_crawl_search_http, ...)→日志结束。

**实现差异:** 都是适配器对外公开的 async crawl(url) 入口,但内部实现(CDP 商品 vs CloakBrowser 列表 vs curl_cffi HTTP)差异巨大,部分用 to_thread 包装同步,部分直接 async。

**建议:** **KEEP_SEPARATE**。crawl 是基类接口契约,各平台实现形态完全不同(商品 CDP/职位 CloakBrowser/职位 HTTP),无共享逻辑;统一签名即可。job51 没走 to_thread 是它独有的'为了在 CloakBrowser page 内 evaluate JS fetch'同步形态,不应强行套 to_thread。

---

### ❌ 适配器 crawl_detail 入口 [保持独立]

**保留理由:** 针对不同平台的详情页 DOM 提取，其网页标记与 Ajax 加密完全不同，必须在各适配器中独立编码开发。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `crawl_detail` @ `platforms/boss_cloak_experimental.py:108` — Boss:asyncio.to_thread(self.\_crawl_detail_sync, security_id, lid) 一行包装。
- `crawl_detail` @ `platforms/job51.py:439` — 51job:asyncio.to_thread 调 \_crawl_detail_sync(job_id, detail_url),WAF 触发时 fallback CloakBrowser。
- `crawl_detail` @ `platforms/liepin.py:389` — liepin:遍历 \_detail_urls 多个 URL,统计 redirect_shell_count/challenge_count 做重试,纯 async 不走 to_thread。

**实现差异:** 都是 async crawl_detail 入口,内部多 URL 重试 / Cookie 刷新 / WAF fallback 逻辑各异。

**建议:** **KEEP_SEPARATE**。与 crawl 同理,签名统一即可,内部反爬策略是平台特化(51job WAF fallback / liepin 多域名 redirect shell / Boss API 调用),合并会丧失灵活性。

---

### ❌ 适配器构造搜索页/搜索 API 的 URL [保持独立]

**保留理由:** 淘宝、京东、Boss 直聘、猎聘的搜索网络请求格式和参数校验截然不同，无法进行通用拼装。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `_build_search_page` @ `platforms/boss_cloak_experimental.py:540` — urllib.parse.urlencode({'query','city'}),Boss 的 geek/jobs 端点。
- `_build_search_page` @ `platforms/job51.py:384` — urlencode({'keyword','searchType','jobArea'}),51job 的 pc/search 端点。
- `_build_search_api_url` @ `platforms/liepin.py:258` — 返回固定 endpoint(API_BASE_URL+SEARCH_API_PATH),不依赖参数。
- `_build_search_page_url` @ `platforms/liepin.py:261` — urlencode({'key','dqs','currentPage':0}),猎聘 zhaopin 端点。

**实现差异:** 每个平台的 base URL、查询参数 schema、是否编码当前页号都不同;liepin 还把 API URL 和页面 URL 分开成两个方法。

**建议:** **KEEP_SEPARATE**。URL 构造是典型的平台特化逻辑(端点/参数名差异),抽象后只会变成 if platform == 'X' 分支,可读性更差。继续保持每平台独立实现;唯一可统一的是命名约定(\_build_search_page / \_build_search_api_url)。

---

### ❌ 通用 user CRUD helper [保持独立]

**保留理由:** `admin` 的查询带有越权字段屏蔽和超级管理员等级校验，而 `auth` 则偏向会话验证。保留各自独立的精简查询，有利于满足安全审计和性能防护。

**批次:** dup-C-crawling-auth | **置信度:** MEDIUM

**涉及函数:**

- `get_active_user` @ `domains/admin/repository.py:51` — 实现：select(User).where(id == user*id, deleted_at.is*(None))
- `list_users` @ `domains/admin/repository.py:16` — 实现：分页 + search/role 过滤 + 计数，标准管理后台查询

**实现差异:** auth/repository.py 当前没有这两个函数——auth service 通过 get_user_by_username / get_user_by_email 等场景化查询走另一条路径。重叠发生在概念层（'active user' 这个语义），不是代码层。

**建议:** **INVESTIGATE**。如果未来 auth-router 的 get_me / refresh / change_password 等需要按 ID 取未删除用户（目前看起来都走 get_current_user 已在中间件层过滤掉 deleted），就值得把这些查询抽到 shared users repository。短期不构成代码重复，但语义高度重叠，留意后续是否会原地复制一份。

---

### ❌ 通过 CloakBrowser 导航到搜索页触发服务端下发新 Cookie [保持独立]

**保留理由:** 这是 Boss 直聘平台独有的防风控隐形浏览器调用管线，独立保存在 Boss 平台适配器内部即可。

**批次:** dup-A-platform-utils | **置信度:** MEDIUM

**涉及函数:**

- `_refresh_cookies` @ `platforms/boss_cloak_experimental.py:395` — 记日志 + time.time() 计时 + 取 self.\_cloak_page/context,page.goto 搜索页触发 Cookie,落日志条目。
- `_navigate_for_cookie_refresh` @ `platforms/boss_cloak_experimental.py:436` — 辅助:根据 page.url 决定 goto 搜索页 vs reload,处理 ERR_ABORTED / frame detached 异常。
- `_refresh_cookies_sync` @ `platforms/job51.py:162` — 同样记日志 + 取 self.\_cloak_page/context + page.goto,落 jsonl 日志。
- `_refresh_cookies_for_detail_sync` @ `platforms/job51.py:251` — 详情页爬取前 wrapper:\_start_browser + \_refresh_cookies_sync + \_close_browser_sync 的固定流程。

**实现差异:** boss 与 job51 都走'打开 CloakBrowser 搜索页拿新 Cookie'流程,但 boss 多一个 \_navigate_for_cookie_refresh 助手(reload vs goto 分支),job51 用 try/finally 包裹 \_start_browser/\_close_browser。属于同一目的的平台特化实现。

**建议:** **KEEP_SEPARATE**。虽然目的都是'通过 CloakBrowser 触发 Cookie 刷新',但 boss 的 reload 分支、job51 的 start/close 包裹是各自平台/调用场景特化;Cookie 刷新是反爬关键路径,任何抽象层都会模糊行为差异。保持独立,可在 docstring 中显式引用共同目的以便维护者识别。

---

## LOW 置信度(可选 review)

### ❌ auth router 与 admin router 各自做一份 'IntegrityError → HTTPException 翻译' [保持独立]

**保留理由:** 尽管都是捕获数据库 `IntegrityError`，但是在不同的路由接口中，需要反馈给用户差异化的中文说明（如“个人修改的邮箱已被他人绑定” vs “新建的系统账号冲突”），分开捕获有助于细节路由治理。

**批次:** dup-C-crawling-auth | **置信度:** LOW

**涉及函数:**

- `update_me` @ `domains/auth/router.py:404` — 实现：try service.update_profile；except UsernameConflictError/EmailConflictError/IntegrityError → 翻译为 400 HTTPException，文案 '用户名已存在'/'邮箱已存在'/'数据冲突，请检查用户名或邮箱是否已被使用'
- `_admin_user_error_response` @ `domains/admin/router.py:39` — 实现：把 service.AdminUserError 子类映射到 400/403/404 HTTPException；同样检查 IntegrityError.orig 字符串 'username'/'email'；几乎相同的中文文案

**实现差异:** admin 版本枚举的错误类型更多（含 LastSuperAdminError / SelfDeleteError / RoleBoundaryError 等 admin 专属），auth 版本只关心 username/email/IntegrityError。

**建议:** **INVESTIGATE**。IntegrityError → 400 的 fallback 分支（'username' in msg / 'email' in msg / 默认 '数据冲突'）在两边都出现了；可以提取到 app/core/error_translation.py 公共工具（或者全局 SQLAlchemy event listener），但优先级不高——业务边界清晰，重复是表面的。

---

### ❌ crawling scheduler_service 的 \_emit_product_crawl_enqueued 与 service.py 的 \_emit_page_timeout_event 包装 [保持独立]

**保留理由:** 两者用于记录完全不同类型的系统审计日志（任务调度入队 vs 页面请求超时），分别使用私有方法进行参数包装可以增强代码的可读性与追溯性。

**批次:** dup-C-crawling-auth | **置信度:** LOW

**涉及函数:**

- `_emit_product_crawl_enqueued` @ `domains/crawling/scheduler_service.py:80` — 实现：await emit_system_log_detached(category='runtime', event_type='product_crawl.enqueued', source='products', user_id=…, entity_type='product_platform', entity_id=platform, payload={…})
- `_emit_page_timeout_event` @ `domains/crawling/service.py:28` — 实现：emit_system_log_detached(category='runtime', event_type='product_browser.page_timeout', source='crawler', severity='warning', status='failed', entity_type='crawl_profile', …)

**实现差异:** event_type / source / severity / payload 各不同；只有 'await emit_system_log_detached(category="runtime", …)' 的公共调用骨架相同。

**建议:** **INVESTIGATE**。不是真重复——只是对同一底层工具（emit_system_log_detached）的不同调用。把它识别为 '共享工具被分散调用' 即可，无需合并。如未来需要统一格式（比如给所有产品爬取事件自动带 user_id 维度），再下沉到 emit_system_log_detached 的封装层。

---

### ❌ extract_json [保持独立]

**保留理由:** LLM 回复的 JSON 提取倾向于清洗 markdown 围栏，而爬虫适配器的提取是从 HTML script 标签或 jsonp 的回调包装中抓取 JSON 内容。两者的输入特征和正则逻辑并不同源。

**批次:** dup-B-jobs-products | **置信度:** LOW

**涉及函数:**

- `extract_json` @ `domains/jobs/llm/utils.py:9` — LLM 响应提取 JSON 的正则实现

**实现差异:** platform adapters 中的同名/类似函数多数情况是从爬取响应提取,不是 LLM 响应。本次分析仅覆盖 jobs + products 两个域,platform adapters 不在 be-02 与 be-09 batch 内。

**建议:** **KEEP_SEPARATE**。extract_json 跨 jobs/llm 与多个 platform adapters 是真实的横向重复,但本次 batch 仅含 jobs-all + products,platforms 没纳入。jobs/llm/utils.py 这一份实现本身只有一个函数,没有同域重复。建议在后续 batch 跨域时(be-02 + platforms)再统一处理。

---

### ❌ jobs LLM provider 三个类(anthropic/openai/ollama)的 provider_name 各自硬编码字符串 [保持独立]

**保留理由:** 接口规范属性，每个类返回各自的标识名以进行策略路由，符合面向对象设计。

**批次:** dup-B-jobs-products | **置信度:** LOW

**涉及函数:**

- `provider_name` @ `domains/jobs/llm/anthropic.py:14` — 返回 settings.job_match_provider 或 'anthropic'(含 minimax 兼容)
- `provider_name` @ `domains/jobs/llm/openai.py:14` — 硬编码返回 'openai'
- `provider_name` @ `domains/jobs/llm/ollama.py:14` — 硬编码返回 'ollama'
- `provider_name` @ `domains/jobs/llm/provider.py:22` — LLMProvider ABC 抽象属性

**实现差异:** anthropic 还会根据 settings 在 anthropic/minimax 之间切换;openai/ollama 是静态字符串。

**建议:** **KEEP_SEPARATE**。这是策略模式的标准用法:每个 provider 返回自己的标识符。属于设计内的多态而非重复,不需合并。

---

### ❌ jobs service 对 repository CRUD 的纯透传包装 [保持独立]

**保留理由:** 这是标准的三层架构设计（Router -> Service -> Repository）。Service 层作为事务和业务的编排边界，即使当前是透传的，也能防止 Router 越级污染底层，为日后增加逻辑打下基础。

**批次:** dup-B-jobs-products | **置信度:** LOW

**涉及函数:**

- `list_job_configs` @ `domains/jobs/service.py:41` — 纯透传到 repository.list_job_configs,无业务附加值
- `list_job_configs` @ `domains/jobs/repository.py:15` — 实际查询实现
- `list_user_resumes` @ `domains/mardown-jobs/service.py:130` — 纯透传到 repository.list_user_resumes,无附加值
- `list_user_resumes` @ `domains/jobs/repository.py:71` — 实际查询实现
- `list_match_results` @ `domains/jobs/service.py:174` — 纯透传到 repository.list_match_results,无附加值
- `list_match_results` @ `domains/jobs/repository.py:123` — 实际查询实现

**实现差异:** service 包装没有异常抛出、没有额外校验、没有用户隔离(参数直传)。这部分 service 函数相比 repository 是纯 forward。

**建议:** **KEEP_SEPARATE**。虽然这几对是 1:1 透传,但 FastAPI 项目惯例是用 service 层做 thin wrapper,以便未来插入权限、缓存、审计等横切关注点。get_job_config / get_user_resume 等其他 service 函数确实抛了 NotFoundError,所以保持 service/repository 分层是合理的。无需合并,但可以在代码评审时讨论是否要让所有 service 函数至少承担一项职责。

---

### ❌ jobs service.list_jobs/list_user_job_ids/list_match_results 与 products service.list_products 查询模式 [保持独立]

**保留理由:** 针对的是完全不同的表结构（职位监控、商品调度、LLM比对）的条件联表分页。数据库查询应该保持与具体的实体强绑定，合并会导致 SQL 构建器极度膨胀。

**批次:** dup-B-jobs-products | **置信度:** LOW

**涉及函数:**

- `list_jobs` @ `domains/jobs/repository.py:206` — jobs 表分页查询,filter: search_config_id / keyword / company / salary_min/max / location / is_active
- `list_products` @ `domains/products/repository.py:42` — products 表分页查询,filter: platform / active / keyword
- `list_jobs` @ `domains/jobs/service.py:223` — 纯透传 jobs repository.list_jobs
- `list_products` @ `domains/products/service.py:82` — 在 repository 之上组装 ProductListResponse(items/total/page/page_size/total_pages/has_next/has_prev)

**实现差异:** 过滤字段语义完全不同(jobs 是职位搜索维度、products 是平台维度);实体模型不同(Job vs Product);关联 join 完全不同(jobs.join(JobSearchConfig) + selectinload(MatchResult.job),products 单表)。

**建议:** **KEEP_SEPARATE**。虽然都是 '分页+多条件过滤' 的 SQLAlchemy 模式,但实体不同、过滤字段不同、关联关系不同,跨域抽象一个通用 paginate() helper 反而会引入类型复杂度。FastAPI 项目里这种对称是健康的设计重复,不构成真正的语义重复。

---

### ❌ redact 时把 key.lower() 与硬编码集合比对做字段替换 [保持独立]

**保留理由:** 不同的安全管线对敏感字段的定义存在细微不同（如有些包括会话 Token，有些包括密码）。独立维护敏感词集合可防止修改一处泄露另一处。

**批次:** dup-D-infra-dashboard-smart | **置信度:** LOW

**涉及函数:**

- `_sanitize_details` @ `core/audit.py:21` — 对 details.items() 做 key.lower() in sensitive_keys → '**_REDACTED_**' 替换
- `redact_payload` @ `core/log_redaction.py:24` — 递归对 Mapping 做 key.lower() in FULL_REDACT_KEYS → '**_REDACTED_**' 替换

**实现差异:** 两者逻辑核心是同一个 key.lower() in 集合 → 替换模板,差异仅在 \_sanitize_details 只处理 dict 一层、redact_payload 递归且处理 list/tuple/set,且 key 集合大小不同。

**建议:** **CONSOLIDATE** — 保留 `backend/app/core/log_redaction.py:redact_payload`。让 audit.\_sanitize_details 直接调用 redact_payload(details) 并 return 结果;两套 key 集合合并;消除重复

---

### ❌ router 层的用户错误处理 helper [保持独立]

**保留理由:** 异常翻译是领域专有的。`profile_router` 翻译的是爬虫配置文件系统错误，而 `admin_router` 处理后台的冲突越权，应当在不同 router 中就近声明。

**批次:** dup-C-crawling-auth | **置信度:** LOW

**涉及函数:**

- `_raise_profile_http` @ `domains/crawling/profile_router.py:42` — 实现：if isinstance(exc, X): raise HTTPException(status_code=…, detail=…)——按领域异常类型映射到 404/409/400
- `_require_admin` @ `domains/crawling/profile_router.py:37` — 实现：if current_user.role not in {admin, super_admin}: raise HTTPException(403, 'Admin role required')
- `_admin_user_error_response` @ `domains/admin/router.py:39` — 实现：同一模式的 isinstance 链 + HTTPException 映射
- `list_users` @ `domains/admin/router.py:78` — 实现：当前 user 取自 Depends(require_permission('user:read'))——permission 装饰器在 core/permissions.py，与 \_require_admin 是两条并行的鉴权路径

**实现差异:** \_require_admin 用 role 字面量（admin/super_admin）鉴权；admin router 用 require_permission('user:read')。两条路径并存意味着 \_require_admin 是早期 role-based 代码，permission 装饰器是后来加的统一入口。

**建议:** **INVESTIGATE**。两个 isinstance 映射函数可以抽象为 'register_exception_handlers(router, mapping: dict[type, (status, formatter)])'，但目前只有两个域各有一份，抽象成本未必划算。\_require_admin 则是已知的技术债，应统一改用 require_permission 装饰器（CLAUDE.md 也强调过 RBAC 走 permission 通道）。

---

### ❌ scheduler sync_all 模板 [保持独立]

**保留理由:** 两个不同 Scheduler 的 `sync_all` 包含略微不同的任务状态同步、错误统计和不同的刷新数据源。过度抽象基类会导致强行合并的逻辑重载。

**批次:** dup-D-infra-dashboard-smart | **置信度:** LOW

**涉及函数:**

- `sync_all` @ `core/scheduler.py:23` — BaseScheduler.sync_all 已统一模板:fetch configs → for each → \_add_job_from_config + 异常计入 synced_count
- `_start_scheduler` @ `main.py:138` — 调用 job_config_scheduler.sync_all() + product_cron_scheduler.sync_all()

**实现差异:** sync_all 已经是 BaseScheduler 抽象类统一了。两处调用方只是创建具体 scheduler 实例并调 sync_all,模式正确。

**建议:** **KEEP_SEPARATE**。BaseScheduler 抽象已经做了去重,调用方只负责创建和 sync,无需进一步抽取

---

### ❌ smart-home test_config / get_config 路径上的 client 构造与 aclose 模板 [保持独立]

**保留理由:** 属于普通的 Python HTTP 资源生命周期操作，使用 try-finally 闭合 client 是对系统资源的常规健壮控制模式，不应合并。

**批次:** dup-D-infra-dashboard-smart | **置信度:** LOW

**涉及函数:**

- `test_config` @ `domains/smart_home/service.py:153` — 构造 HomeAssistantClient → ping → finally aclose
- `list_entities` @ `domains/smart_home/service.py:168` — 构造 \_client(config) → get_states → finally aclose
- `call_entity_service` @ `domains/smart_home/service.py:196` — 构造 \_client(config) → call_service → finally aclose

**实现差异:** 3 处都做 client.aclose() 兜底,HomeAssistantClient 已实现 **aenter**/**aexit**,但调用方都手动 try/finally 而非 async with。

**建议:** **INVESTIGATE**。HomeAssistantClient 已经支持 async with,但 test_config/list_entities/call_entity_service 都用 try/finally 手动 aclose,未充分利用上下文管理器;应统一改为 async with HomeAssistantClient(...) as client:。低优先级清理

---

### ❌ 前端 cron 工具 - isValidCronExpression 与 nlToCron 共存 [保持独立]

**保留理由:** 前者是纯前端的 regex 语法校验，后者是调用服务端大语言模型或者本地翻译策略进行转换。职责和交互方向完全不同。

**批次:** dup-E-alerts-frontend | **置信度:** LOW

**涉及函数:**

- `isValidCronExpression` @ `features/schedule/utils/cron.ts:3` — 校验 cron 表达式
- `nlToCron` @ `utils/nl-to-cron.ts:442` — 自然语言转 cron

**实现差异:** 一个验证已有 cron,一个生成 cron,职责不重叠

**建议:** **KEEP_SEPARATE**。但是两个文件应在 schedule 域内同目录,目前 cron.ts 在 features/schedule/utils,nl-to-cron.ts 在 utils 根目录,建议合到一处

---

### ❌ 前端事件域 - 前后端 events 域 [保持独立]

**保留理由:** 前端使用 Zustand/Redux 做实时内存事件归纳，后端是 SQL 日志的持久化层。属于两个完全独立的系统表达媒介。

**批次:** dup-E-alerts-frontend | **置信度:** LOW

**涉及函数:**

- `list_events` @ `domains/events/router.py:62` — HTTP GET 端点获取事件中心列表
- `stream_events` @ `domains/events/router.py:96` — SSE 实时推送
- `_build_event_union` @ `domains/events/repository.py:44` — 构建审计/系统/平台 UNION 查询
- `list_events` @ `domains/events/repository.py:152` — 查询事件列表
- `mergeRealtimeEvent` @ `features/events/realtimeState.ts:8` — 前端合并实时事件

**实现差异:** 后端负责事件产生与持久化,前端负责事件消费与合并,跨前后端边界不构成重复

**建议:** **KEEP_SEPARATE**。正常前后端分工,EventStream publish/subscribe 是后端独有模式,与前端 merge 互补不重复

---

### ❌ 前端状态合并 - mergeRealtimeEvent 与 applyUserConfig 共享合并/去重模式 [保持独立]

**保留理由:** `mergeRealtimeEvent` 处理的是含有分页和事件 ID 排重的大型数组列表，而 `applyUserConfig` 则是合并覆盖用户的常规字典配置，物理数据结构不同。

**批次:** dup-E-alerts-frontend | **置信度:** LOW

**涉及函数:**

- `mergeRealtimeEvent` @ `features/events/realtimeState.ts:8` — 合并实时事件去重+分页
- `applyUserConfig` @ `features/settings/userConfigState.ts:4` — 合并用户配置到 User 对象

**实现差异:** 前者面向事件流(去重 by id + 分页裁剪),后者面向对象浅合并(展开 config 字段),算法完全不同

**建议:** **KEEP_SEPARATE**。业务语义与算法均不同,不可合并

---

### ❌ 前端认证相关 UI - LoginPage / RegisterPage / ProfilePage 都使用表单 + 提交错误处理 [保持独立]

**保留理由:** 典型的 UI 表单设计模式。虽然都具有表单提交和后端错误渲染逻辑，但在输入组件、输入验证和状态分支上完全不同，属于标准的自包含 React 组件。

**批次:** dup-E-alerts-frontend | **置信度:** LOW

**涉及函数:**

- `LoginPage` @ `features/auth/LoginPage.tsx:14` — 登录页表单+跳转
- `RegisterPage` @ `features/auth/RegisterPage.tsx:18` — 注册页含强密码校验
- `ProfilePage` @ `features/auth/ProfilePage.tsx:11` — 个人资料页信息+修改密码

**实现差异:** 三个页面表单字段完全不同,只是都使用 AntD Form + 错误提示骨架

**建议:** **KEEP_SEPARATE**。页面级组件不重复,共享应通过 AntD Form 机制自然完成

---

### ❌ 前端通用组件 - PageLoader / PageTransition / AppLayout 都在 App 启动路径 [保持独立]

**保留理由:** 它们是完全不同的 React UI 功能组件：一个是页面初始骨架，一个是路由切换过渡，一个是全局布局，彼此职责清晰且不重叠。

**批次:** dup-E-alerts-frontend | **置信度:** LOW

**涉及函数:**

- `PageLoader` @ `App.tsx:56` — 通用页面加载占位组件
- `AppLayout` @ `shared/components/AppLayout.tsx:33` — 应用主布局
- `PageTransition` @ `shared/components/PageTransition.tsx:23` — 页面切换过渡动画包装

**实现差异:** 三者职责清晰分层:Loader 占位 / Layout 框架 / Transition 动画,无重复

**建议:** **KEEP_SEPARATE**。职责分明,且 PageLoader 定义在 App.tsx 而非 shared/components/ 目录,建议移入 shared/components/ 以便复用

---

### ❌ 后端 EventStream pub/sub 与 alerts service 的 '触发动作' 概念部分重叠 [保持独立]

**保留理由:** `EventStream` 负责 Redis/内存的高速发布订阅订阅推送（Event-driven），而 `alerts` 面向持久化的静态阈值触发判定。底层机制截然不同。

**批次:** dup-E-alerts-frontend | **置信度:** LOW

**涉及函数:**

- `publish` @ `core/event_stream.py:26` — 广播事件到订阅者
- `subscribe` @ `core/event_stream.py:14` — 注册订阅者返回带上限 Queue
- `create_alert` @ `domains/alerts/service.py:18` — 创建提醒写入数据库(静态配置)
- `create_or_update_config` @ `domains/config/service.py:29` — 写入用户配置(静态配置)

**实现差异:** EventStream 是进程内 pub/sub(动态事件流),alerts/config 是持久化用户配置(静态),二者职责清晰不重叠

**建议:** **KEEP_SEPARATE**。二者语义层级不同:一个是事件分发机制,一个是用户数据;用户说 '用户配置 → 触发动作' 由调度器 + alerts evaluation 协同,不是 EventStream 与 alerts 直接重复

---

### ❌ 后端 events repository 与 dashboard repository 共用 SQL CASE/UNION 模式 [保持独立]

**保留理由:** 两个仓库中仅有 SQL 中使用了通用的聚合和条件表达式，这属于标准的 SQL 语句能力而非函数的逻辑复制，强行合并会增加不合理的查询生成负担。

**批次:** dup-E-alerts-frontend | **置信度:** LOW

**涉及函数:**

- `_audit_category_expr` @ `domains/events/repository.py:25` — 构建审计日志分类 CASE 表达式
- `_audit_severity_expr` @ `domains/events/repository.py:37` — 构建审计日志严重级别 CASE
- `_build_event_union` @ `domains/events/repository.py:44` — UNION 查询
- `list_events` @ `domains/events/repository.py:152` — 查询事件列表

**实现差异:** 都是 events repository 内私有辅助函数,职责集中,不与其他文件重复

**建议:** **KEEP_SEPARATE**。私有助手函数,集中在一个 repository 是合理内聚

---

### ❌ 后端配置解析 [保持独立]

**保留理由:** 配置项的独立提取和计算。它们各自对应不同的输入和转换流程（IP/端口解析、URI组装、Secure判断），分开最利于配置模块清晰结构。

**批次:** dup-E-alerts-frontend | **置信度:** LOW

**涉及函数:**

- `auth_cookie_secure` @ `config.py:78` — 判断 cookie 是否需要 Secure
- `parse_allowed_origins` @ `config.py:119` — 解析 ALLOWED_ORIGINS
- `redis_url_with_password` @ `config.py:142` — 构造 Redis URL
- `_parse_args` @ `workers/crawler.py:72` — 解析 worker 启动参数

**实现差异:** 四个函数职责不同:cookie 安全判断 / CORS 解析 / URL 构造 / CLI 参数解析,无重复

**建议:** **KEEP_SEPARATE**。都是配置层的小工具,职责分明

---

## 下一步建议

1. 优先处理 HIGH 22 个:按 `recommendation.survivor` 修改调用方,删除重复函数,跑测试。
2. MEDIUM 33 个:人工 review 实现差异,确认是否可以合并或保留。
3. LOW 18 个:留作未来整理 backlog。
4. 涉及的修改跨多文件,建议每个 HIGH 用 worktree + TDD 单独提一个 PR。

## 原始数据

所有 opus 重复检测的 JSON 在 `.dup-scan/duplicates/`:

- `.dup-scan/duplicates/dup-A-platform-utils.json`
- `.dup-scan/duplicates/dup-B-jobs-products.json`
- `.dup-scan/duplicates/dup-C-crawling-auth.json`
- `.dup-scan/duplicates/dup-D-infra-dashboard-smart.json`
- `.dup-scan/duplicates/dup-E-alerts-frontend.json`

---

报告由 `finding-duplicate-functions` skill 自动生成。
