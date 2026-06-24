# 统一 Flutter 页面视觉规范修复计划

## Summary

已确认采用以下统一规范：

- 按钮：紧凑统一。
- 表格：产品表风格。
- Banner：全宽统一。

本次修复目标是把 `/events`、`/jobs`、`/products`、`/schedule`、`/smart-home`、`/admin/blog`、`/admin/users`、`/admin/audit-logs` 的 banner、按钮、表格统一到同一套组件语言。

## Key Changes

### 共享 UI 规范

#### Banner 规范

- 所有目标页面使用同一个全宽标题 banner 组件；在当前内容区内 `width: double.infinity`，禁止按文案内容收缩。
- Banner 只包含 eyebrow、title、subtitle 三类文案；所有按钮、tabs、filters、状态 chips 必须放在 banner 外。
- Desktop 尺寸：
  - 外层与下一块内容间距：`20px`。
  - 内边距：水平 `24px`，垂直 `22px`。
  - 圆角：`16px`。
  - 边框：`1px`，使用 `colorScheme.outlineVariant`。
  - 背景：`colorScheme.surfaceContainerHighest.withValues(alpha: 0.36)`；不要使用纯色 pop block、渐变或重阴影。
- Mobile 尺寸：
  - 内边距：水平 `16px`，垂直 `18px`。
  - 圆角：`16px`。
  - subtitle 允许换行，title 不得被按钮或 chips 挤压。
- 字体：
  - eyebrow：`labelLarge` 或等效 `12-13px / 500`。
  - title：`headlineMedium`；若空间较紧，最低不得小于 `headlineSmall`。
  - subtitle：`bodyMedium`，颜色使用 `onSurfaceVariant`。
- 若现有 `/schedule` banner 与上述细节不一致，实施时也同步调整 `/schedule`，以本规范为准。

#### 按钮和输入控件规范

- 工具栏、筛选栏、tabs、列表操作区统一使用 compact 尺寸。
- 文本按钮和 icon+text 按钮：
  - 高度：`40px`。
  - 最小宽度：`40px`。
  - 水平 padding：`14px`；只有 icon-only 时为 `0`。
  - 圆角：`8px`。
  - icon 尺寸：`18px`。
  - icon 与文字间距：`8px`。
  - 同一 toolbar 内 FilledButton、OutlinedButton、TextButton 视觉高度必须一致。
- 表格行内 icon-only 操作按钮：
  - 外框尺寸：`36px x 36px`。
  - icon 尺寸：`18px`。
  - 圆角：`8px`。
  - 同一行多个 icon-only 按钮间距：`4px`。
- Tabs / ChoiceChip / Segmented controls：
  - 高度：`40px`。
  - 水平 padding：`12px`。
  - icon 尺寸：`16px`。
  - 同一组内按钮高度一致，不允许有的按钮 32px、有的按钮 44px。
- TextField、Dropdown、filter input：
  - 视觉高度统一为 `48px`。
  - 圆角：`8px`。
  - 水平 content padding：`14px`。
  - label 使用浮动 label 或外显 label，不能只依赖 placeholder。
- 按钮语义：
  - 主动作：FilledButton，例如 `Apply`、`New User`、`Add Product`、`Save`。
  - 次动作：OutlinedButton，例如 `Refresh`、`Configure`、`Crawl Now`。
  - 低强调动作：TextButton，例如 `Reset`、`Cancel`。
  - 删除/危险动作使用 error 语义色，不使用普通主色。

#### 表格和面板规范

- 所有目标页面的数据表统一为产品表风格的工作台表：
  - 表格外层面板圆角：`16px`。
  - 面板边框：`1px outlineVariant`。
  - 面板内边距：`16px`；移动端 `12px`。
  - Panel title 与 toolbar 分隔线间距：`12px`。
  - Toolbar 与表格 header 间距：`12px`。
- DataTable / table 行尺寸：
  - Header 行高：`44px`。
  - Body 行高：`48px`。
  - Header 字体：`labelMedium` 或等效 `12-13px / 600`。
  - Body 字体：`bodyMedium` 或等效 `14px / 400`。
  - 数字、日期、金额使用 tabular number 风格；如现有主题暂不支持，至少保持等宽列宽和右对齐/固定宽度。
  - 行分割线：`1px outlineVariant.withValues(alpha: 0.7)`。
- 表格宽度和滚动：
  - 表格默认填满面板宽度；列总宽超过面板时才横向滚动。
  - 不允许出现表格内容只占左侧、右侧大片空白但 Actions 列仍被裁掉的状态。
  - `Actions` 列在 1280px 桌面视口下必须可见；若列过多，优先压缩长文本列并省略，不压缩操作列到不可点。
- 长文本处理：
  - 普通长文本列默认 `maxLines: 1` + ellipsis，并通过 tooltip 或详情按钮完整查看。
  - Error、Details、URL、Message 这类诊断列默认最多 `2-3` 行；超过时显示 ellipsis，并提供 tooltip、展开行或详情 drawer。
  - Recent Crawl Logs 的 Error 列必须能完整查看失败原因，不能被表格行高硬裁掉。
- 分页和底部边界：
  - 分页放在表格面板底部右侧；总数/页码放底部左侧。
  - 表格内容少时，面板底部应紧贴内容和分页，不保留大块无意义空白。
  - 空状态在表格区域内居中，文案简短，保留主要操作按钮时也使用 compact 规范。

### 页面修复

- `/events`：筛选栏按钮、dropdown、text field、Reset、More filters、Apply 高度一致。
- `/jobs`：banner 改全宽；Jobs List 内筛选、状态切换、Apply、Crawl All 按钮统一尺寸。
- `/products`：banner 改全宽；Products tabs/toolbar 按钮统一尺寸；Products 表格面板底部贴合内容边界；Recent Crawl Logs 的 Error 长文本列支持完整查看，默认省略或多行限制并提供 tooltip/详情展开。
- `/schedule`、`/smart-home`、`/admin/blog`、`/admin/users`、`/admin/audit-logs`：表格统一到产品表风格，按钮统一到 compact 规范，避免每页各自写一套样式。

## Test Plan

- 扩展或更新页面测试：
  - 断言 Jobs/Products banner 全宽，且按钮不在 banner 内。
  - 断言 Events/Jobs/Products toolbar 控件高度一致。
  - 断言 Products crawl logs 的 Error 列可完整访问。
  - 断言 Schedule/Smart Home/Admin 表格仍渲染核心列和操作按钮。
- 运行验证命令：
  - `flutter test` 对相关页面测试。
  - `flutter analyze`。
  - `flutter build web`。
  - `git diff --check`。
- 浏览器复查 3001：
  - `/events`、`/jobs`、`/products`、`/schedule`、`/smart-home`、`/admin/blog`、`/admin/users`、`/admin/audit-logs`。
  - 桌面和移动至少各抽查一轮。

## Assumptions

- 本次只做视觉一致性和可读性修复，不改后端契约，不改 generated client。
- “产品表风格”不表示所有表格列宽完全相同，而是统一面板、行高、表头、分割线、分页、长文本处理和操作按钮语言。
- 3001 应继续作为当前 Flutter 前端验证端口。
