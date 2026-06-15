# Flutter Screen State Matrix

Status: required UI state contract for route parity.

Every state below defines:

- visible copy;
- primary action;
- secondary or defer action;
- retry or reconnect behavior;
- permission recovery path;
- partial data rule;
- widget test expectation for semantics or focus.

Backend error envelopes are displayed through `code`, `message`, `details`,
`trace_id`, and `help_url` when present. User-facing copy starts with
`message`; diagnostic fields stay secondary and copyable.

## Auth

- Loading: copy `正在确认登录状态...`; primary none; secondary none; retry waits for storage/session restore then retries once; permission path N/A; partial keeps entered username only; widget test expects a labelled progress indicator and no focused password leak.
- Empty: copy `登录后，Mavra 会继续帮你看价格、职位和家里。`; primary `登录`; secondary `注册`; retry N/A; permission path N/A; partial N/A; widget test expects first text field focused on desktop.
- Error: copy from backend envelope or `登录失败，请检查账号或网络。`; primary `重试`; secondary `忘记密码/返回登录`; retry repeats the same request; permission path N/A; partial retains non-secret fields; widget test expects error announced by screen reader.
- Permission denied: copy `这个账号还不能访问该页面。`; primary `回到 Today`; secondary `打开 Profile`; retry re-checks current user; permission path ask an admin to update role; partial N/A; widget test expects focus on primary action.
- Partial data: copy `账号已确认，正在补齐个人资料。`; primary `继续`; secondary `稍后再说`; retry refreshes profile; permission path open Profile; partial blocks only routes needing missing fields; widget test expects route is not trapped.
- Offline/realtime disconnected: copy `网络暂时不可用，登录状态会在恢复后继续确认。`; primary `重试`; secondary `离线查看帮助`; retry reconnects with backoff; permission path N/A; partial keeps local auth state untrusted; widget test expects offline banner semantics.
- Success: copy `欢迎回来。`; primary route to stored destination or Today; secondary none; retry N/A; permission path direct forbidden routes to permission panel; partial N/A; widget test expects `/today` navigation after login.

## Today

- Loading: copy `正在整理今天的节奏...`; primary none; secondary none; retry parallel-loads prices/jobs/home once; permission path N/A; partial may show cached quiet score; widget test expects skeleton labelled as Today loading.
- Empty: copy `没有需要你立刻处理的事。`; primary `查看 Prices`; secondary `查看 Jobs`; retry pull-to-refresh or refresh button; permission path hidden admin data ignored; partial modules show inactive rows; widget test expects quiet state is not announced as an error.
- Error: copy `今天的晨报暂时没有整理好。`; primary `重试`; secondary `打开 Activity`; retry reloads all Today sources; permission path routes missing module permission to Settings/Profile; partial shows available module statuses; widget test expects error banner includes retry.
- Permission denied: copy `登录后才能查看 Today。`; primary `去登录`; secondary none; retry auth guard rechecks session; permission path login; partial N/A; widget test expects unauthenticated redirect.
- Partial data: copy `有些模块还在路上，先显示已拿到的状态。`; primary `刷新`; secondary `查看 Activity`; retry reloads failed modules only; permission path marks forbidden modules as unavailable; partial never hides successful sources; widget test expects successful module links remain tappable.
- Offline/realtime disconnected: copy `实时更新断开了，当前显示最近一次状态。`; primary `重新连接`; secondary `继续查看`; retry reconnects realtime then refreshes summary; permission path N/A; partial cached data marked stale; widget test expects stale banner semantics.
- Success: copy headline from Today brief, such as `今天只提醒 2 件事。`; primary first attention action; secondary defer/continue; retry manual refresh; permission path unavailable modules link to permission panel; partial N/A; widget test expects attention list, quiet score, and module status landmarks.

## Products

- Loading: copy `正在加载关注商品...`; primary none; secondary none; retry query retries with existing filters; permission path N/A; partial can show cached table rows disabled; widget test expects table loading semantics.
- Empty: copy `还没有关注商品。`; primary `添加商品`; secondary `批量导入`; retry refreshes list; permission path hide crawl-only actions; partial N/A; widget test expects Add Product focus order before Import on desktop.
- Error: copy `商品列表加载失败。`; primary `重试`; secondary `查看 Activity`; retry preserves filters/page; permission path show read permission issue if envelope says forbidden; partial keeps current page if cache exists; widget test expects error row inside table frame.
- Permission denied: copy `没有权限管理商品。`; primary `回到 Today`; secondary `打开 Settings`; retry refreshes current user; permission path request product access from admin; partial hides destructive actions; widget test expects disabled row actions expose reason.
- Partial data: copy `部分价格历史暂时不可用。`; primary `刷新价格`; secondary `继续看列表`; retry refetches history/logs only; permission path crawl actions hidden if missing `crawl:execute`; partial product CRUD stays usable; widget test expects warning does not remove rows.
- Offline/realtime disconnected: copy `价格更新暂时离线，列表显示最近一次同步。`; primary `重新连接`; secondary `查看抓取日志`; retry reconnects stream/polling; permission path N/A; partial stale price cells show timestamp; widget test expects stale timestamp visible.
- Success: copy `Products`; primary `添加商品`; secondary `批量导入`; retry refresh button; permission path hide crawl now without `crawl:execute`; partial N/A; widget test expects table row count and selected rows announced.

## Jobs

- Loading: copy `正在加载职位和规则...`; primary none; secondary none; retry retries active tab query; permission path N/A; partial shows cached tabs; widget test expects active tab remains selected.
- Empty: copy `还没有职位搜索规则。`; primary `新建规则`; secondary `导入/管理 Profile`; retry refresh configs; permission path hide crawl/test actions; partial N/A; widget test expects empty state action is labelled.
- Error: copy `职位数据加载失败。`; primary `重试`; secondary `查看 Crawl Logs`; retry preserves active tab; permission path show missing permission state if forbidden; partial successful tabs stay visible; widget test expects error is scoped to tab.
- Permission denied: copy `没有权限执行抓取操作。`; primary `继续查看职位`; secondary `联系管理员`; retry refreshes permissions; permission path require `crawl:execute` for crawl/test; partial read-only lists stay visible; widget test expects disabled crawl buttons expose reason.
- Partial data: copy `职位列表可用，但匹配/Profile 数据暂时不完整。`; primary `刷新当前标签`; secondary `继续查看`; retry refetches failed tab only; permission path profile backup controls hidden when forbidden; partial no tab may block another tab; widget test expects tabs with partial state are reachable.
- Offline/realtime disconnected: copy `抓取状态不会实时更新，当前显示最后一次记录。`; primary `重新连接`; secondary `刷新日志`; retry reconnects task status or polls; permission path N/A; partial crawling chips become stale; widget test expects stale crawl status announced.
- Success: copy `Job Management`; primary `新建搜索规则`; secondary `查看匹配结果`; retry refresh current tab; permission path crawl action depends on `crawl:execute`; partial N/A; widget test expects table, tabs, and drawer semantics.

## Schedule

- Loading: copy `正在加载自动规则...`; primary none; secondary none; retry reloads product/job schedule configs; permission path N/A; partial cached schedules show stale marker; widget test expects progress label.
- Empty: copy `还没有自动运行规则。`; primary `新建规则`; secondary `使用模板`; retry refreshes schedules; permission path edit action requires `schedule:configure`; partial N/A; widget test expects template control reachable.
- Error: copy `规则加载失败。`; primary `重试`; secondary `查看 Activity`; retry preserves edited draft; permission path forbidden opens permission panel; partial loaded platform rules remain visible; widget test expects draft fields are retained.
- Permission denied: copy `没有权限修改自动规则。`; primary `只读查看`; secondary `联系管理员`; retry refreshes role; permission path request `schedule:configure`; partial disables edit/delete only; widget test expects disabled controls explain reason.
- Partial data: copy `部分平台的下一次运行时间暂时不可用。`; primary `刷新状态`; secondary `继续编辑规则`; retry refetches schedules; permission path edit still role-gated; partial cron definitions remain editable; widget test expects warning and rows both visible.
- Offline/realtime disconnected: copy `运行状态暂时不会实时刷新。`; primary `重新连接`; secondary `手动刷新`; retry reconnects or polls; permission path N/A; partial stale run timestamps labelled; widget test expects stale labels.
- Success: copy `Rules`; primary `保存规则`; secondary `预览 cron`; retry manual refresh; permission path read-only when missing configure permission; partial N/A; widget test expects cron generator semantics.

## Smart Home

- Loading: copy `正在连接 Home Assistant...`; primary none; secondary none; retry loads config/entities; permission path N/A; partial cached rooms show disabled controls; widget test expects connection progress semantics.
- Empty: copy `还没有可控制的 Home Assistant 设备。`; primary `配置 Home Assistant`; secondary `刷新`; retry reloads entities; permission path configure button requires `smart_home:configure`; partial N/A; widget test expects empty state action hidden if not permitted.
- Error: copy `智能家居状态加载失败。`; primary `重试`; secondary `打开配置`; retry reloads entities and config; permission path configure/control permissions split; partial show loaded entities with error banner; widget test expects command buttons remain disabled until safe.
- Permission denied: copy `没有权限控制这个设备。`; primary `只看状态`; secondary `联系管理员`; retry refreshes user; permission path require `smart_home:control` or `smart_home:configure`; partial read state remains visible; widget test expects controls disabled with semantic reason.
- Partial data: copy `部分设备暂时没有状态。`; primary `刷新设备`; secondary `继续查看`; retry reloads unavailable group; permission path control remains role-gated; partial group by room and show unavailable chips; widget test expects unavailable count announced.
- Offline/realtime disconnected: copy `Home Assistant 实时更新断开了。`; primary `重新连接`; secondary `手动刷新`; retry reconnects SSE then loads entities; permission path N/A; partial stale device states labelled; widget test expects disconnected banner.
- Success: copy `家里设备都在安静运行。` or connected status; primary device control; secondary configure/refresh; retry manual refresh; permission path control/config buttons role-gated; partial N/A; widget test expects switch/service confirmation semantics.

## Events

- Loading: copy `正在加载 Activity...`; primary none; secondary none; retry loads events and stream state; permission path N/A; partial cached events show stale marker; widget test expects list loading label.
- Empty: copy `暂时没有新的活动记录。`; primary `刷新`; secondary `回到 Today`; retry reloads list; permission path N/A; partial N/A; widget test expects empty state is not an error.
- Error: copy `活动记录加载失败。`; primary `重试`; secondary `查看 Today`; retry preserves filters; permission path forbidden opens permission panel; partial cached events remain visible; widget test expects retry button focus.
- Permission denied: copy `没有权限查看这类活动。`; primary `清除筛选`; secondary `联系管理员`; retry refreshes user; permission path request relevant read permission; partial hide forbidden categories; widget test expects forbidden filter state announced.
- Partial data: copy `部分活动来源暂时不可用。`; primary `刷新`; secondary `继续查看`; retry failed source only; permission path forbidden sources omitted with notice; partial never merge audit/system labels incorrectly; widget test expects source labels visible.
- Offline/realtime disconnected: copy `实时活动断开了，列表显示最近记录。`; primary `重新连接`; secondary `手动刷新`; retry reconnects event stream; permission path N/A; partial stale stream marker shown; widget test expects connected/disconnected semantics.
- Success: copy `Activity`; primary `刷新`; secondary filters; retry manual refresh; permission path category visibility follows role; partial N/A; widget test expects filters and event severity chips announced.

## Alerts

- Loading: copy `正在加载提醒规则...`; primary none; secondary none; retry reloads alert list; permission path N/A; partial cached alert chips show stale; widget test expects progress label.
- Empty: copy `还没有价格提醒。`; primary `创建提醒`; secondary `去 Prices`; retry refresh; permission path product read required; partial N/A; widget test expects primary action navigates to Prices form.
- Error: copy `提醒加载失败。`; primary `重试`; secondary `查看 Products`; retry reloads alerts; permission path forbidden opens permission panel; partial product rows still render without alert badge; widget test expects missing alert badge is explained.
- Permission denied: copy `没有权限修改提醒。`; primary `只读查看`; secondary `联系管理员`; retry refresh role; permission path request product/alert permission; partial hide edit actions; widget test expects disabled controls semantic reason.
- Partial data: copy `部分商品的提醒状态暂时不可用。`; primary `刷新提醒`; secondary `继续查看商品`; retry alerts only; permission path role-gated; partial product list remains canonical; widget test expects warning per affected row.
- Offline/realtime disconnected: copy `提醒状态不会实时更新。`; primary `重新连接`; secondary `刷新`; retry stream/polling reconnect; permission path N/A; partial stale alert badges timestamped; widget test expects stale labels.
- Success: copy `提醒已启用` or `提醒未启用`; primary toggle/save; secondary edit threshold; retry manual refresh; permission path edit role-gated; partial N/A; widget test expects toggle labels include product name.

## Admin

- Loading: copy `正在加载管理数据...`; primary none; secondary none; retry current admin query; permission path N/A; partial cached tables disabled; widget test expects admin landmark.
- Empty: copy `没有符合条件的记录。`; primary `清除筛选`; secondary `刷新`; retry reloads table; permission path direct URL checks `user:read`; partial N/A; widget test expects empty table header remains visible.
- Error: copy `管理数据加载失败。`; primary `重试`; secondary `导出当前筛选` only if available; retry preserves filters; permission path forbidden panel; partial cached rows remain read-only; widget test expects trace id area copyable when present.
- Permission denied: copy `没有权限访问管理功能。`; primary `回到 Today`; secondary `打开 Profile`; retry refresh user; permission path request `user:read` or specific manage permission; partial N/A; widget test expects focus on `回到 Today`.
- Partial data: copy `部分权限信息暂时不可用。`; primary `刷新权限`; secondary `继续查看用户`; retry permissions endpoint only; permission path manage/delete buttons hidden if missing; partial never allow destructive action without full permissions; widget test expects hidden action absent from semantics.
- Offline/realtime disconnected: copy `管理数据不是实时状态。`; primary `刷新`; secondary `继续查看`; retry poll refresh; permission path N/A; partial stale timestamp visible; widget test expects stale notice.
- Success: copy `Users` or `Audit Logs`; primary route-specific create/edit; secondary filters; retry refresh; permission path actions gated by `user:manage`, `user:delete`, `rbac:manage`; partial N/A; widget test expects table sort/filter/focus semantics.

## Blog

- Loading: copy `正在加载 Blog Studio...`; primary none; secondary none; retry posts/taxonomy query; permission path N/A; partial cached drafts visible read-only; widget test expects editor not focused before load.
- Empty: copy `还没有文章草稿。`; primary `New post`; secondary `刷新`; retry reloads posts; permission path requires `blog:read_admin`; partial taxonomy may still load; widget test expects New post focusable.
- Error: copy `Blog Studio 加载失败。`; primary `重试`; secondary `回到 Activity`; retry preserves filters and draft content; permission path forbidden panel; partial posts list remains visible if editor taxonomy failed; widget test expects draft body not lost.
- Permission denied: copy `没有权限访问 Blog Studio。`; primary `回到 Today`; secondary `联系管理员`; retry refresh user; permission path request `blog:read_admin`; partial N/A; widget test expects direct URL shows panel.
- Partial data: copy `文章列表可用，但分类或标签暂时不可用。`; primary `刷新分类`; secondary `继续编辑`; retry taxonomy only; permission path publish actions still role-gated; partial editor disables publish if required taxonomy missing; widget test expects body field retains content.
- Offline/realtime disconnected: copy `媒体上传或保存暂时离线。`; primary `重试保存`; secondary `保存为本地草稿` when implemented; retry repeats upload/save; permission path N/A; partial local draft marked unsynced; widget test expects unsaved state announced.
- Success: copy `Blog Studio`; primary `New post` or `Save`; secondary status filters; retry refresh; permission path admin-only route; partial N/A; widget test expects rich-text editor has `Blog post body` semantics.

## Settings

- Loading: copy `正在加载设置...`; primary none; secondary none; retry load settings; permission path N/A; partial cached preferences visible; widget test expects progress label.
- Empty: copy `还没有可配置的偏好。`; primary `回到 Today`; secondary `刷新`; retry reloads settings; permission path authenticated only; partial N/A; widget test expects no empty form trap.
- Error: copy `设置加载失败。`; primary `重试`; secondary `回到 Today`; retry preserves unsaved local edits; permission path forbidden panel if needed; partial cached settings remain editable only after conflict check; widget test expects field errors attached.
- Permission denied: copy `没有权限修改这些设置。`; primary `只读查看`; secondary `联系管理员`; retry refresh user; permission path request relevant config permission; partial disable forbidden groups; widget test expects disabled group explains reason.
- Partial data: copy `部分设置暂时不可用。`; primary `刷新不可用项`; secondary `保存可用项`; retry failed groups only; permission path group-level gating; partial never sends unavailable fields; widget test expects partial save confirmation.
- Offline/realtime disconnected: copy `设置会在网络恢复后同步。`; primary `重试同步`; secondary `保留本地更改`; retry background sync; permission path N/A; partial unsynced changes marked; widget test expects offline banner.
- Success: copy `Settings`; primary `保存`; secondary `重置`; retry manual refresh; permission path group-level gating; partial N/A; widget test expects keyboard traversal through all controls.

## Analytics

- Loading: copy `正在加载 Analytics...`; primary none; secondary none; retry loads KPI/charts/recent alerts; permission path N/A; partial cached charts skeleton; widget test expects chart loading labels.
- Empty: copy `还没有足够数据生成分析。`; primary `去 Prices`; secondary `去 Jobs`; retry refresh; permission path hide forbidden modules; partial N/A; widget test expects text summary visible.
- Error: copy `分析数据加载失败。`; primary `重试`; secondary `查看 Activity`; retry preserves selected range; permission path forbidden panel for protected data; partial successful charts remain visible; widget test expects failed chart has own retry.
- Permission denied: copy `没有权限查看这些分析。`; primary `回到 Today`; secondary `联系管理员`; retry refresh user; permission path request relevant read permission; partial omit forbidden series; widget test expects omitted series notice.
- Partial data: copy `部分图表暂时不可用。`; primary `刷新图表`; secondary `继续查看`; retry failed chart only; permission path forbidden series omitted; partial never render misleading zero as missing data; widget test expects chart summary names missing source.
- Offline/realtime disconnected: copy `实时指标断开了，图表显示最近一次数据。`; primary `重新连接`; secondary `手动刷新`; retry reconnect stream/poll; permission path N/A; partial stale timestamp visible; widget test expects stale chart label.
- Success: copy `Analytics`; primary range selector; secondary drill into source module; retry manual refresh; permission path series visibility follows role; partial N/A; widget test expects chart semantics and data-table fallback.

