# Task 17 Full React Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the Flutter frontend to business parity with every old React protected route while keeping Flutter-native responsive layouts for Web, Windows, and Android.

**Architecture:** Keep the existing generated OpenAPI client plus repository interfaces as the API boundary. Add a small set of shared Flutter workbench primitives for dense filters, tables, side sheets, confirmations, and charts, then rebuild each page around those primitives without copying React pixels. Wide screens use dense operational layouts; mobile uses native stacked lists and sheets with the same workflows.

**Tech Stack:** Flutter, Material 3, go_router, generated `mavra_api`, dio, file_selector, flutter_secure_storage, flutter_test, integration_test, GitNexus, FastAPI/OpenAPI when client gaps are found.

---

## Source Of Truth

- Approved spec: `docs/flutter-migration/task-17-full-react-parity-spec.md`
- Existing parity ledger, now superseded: `docs/flutter-migration/react-flutter-feature-parity.md`
- Old React reference app: `C:\Users\arfac\Documents\mavra-monitor-system\frontend\src`
- Flutter target: `C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\frontend`

## File Structure Map

Shared Flutter primitives:

- Create: `frontend/lib/core/widgets/mavra_page.dart` - common page header, toolbar band, status banner, and responsive content constraints.
- Create: `frontend/lib/core/widgets/mavra_responsive_data_view.dart` - wide-screen `DataTable` adapter and narrow-screen list adapter.
- Create: `frontend/lib/core/widgets/mavra_confirm.dart` - confirmation dialog helper with stable test keys.
- Create: `frontend/lib/core/widgets/mavra_side_sheet.dart` - wide-screen right-side details panel and mobile bottom/dialog sheet helper.
- Create: `frontend/lib/core/widgets/mavra_chart.dart` - trend, bar, and pie chart wrappers.
- Create: `frontend/test/core/widgets/mavra_page_test.dart`
- Create: `frontend/test/core/widgets/mavra_responsive_data_view_test.dart`
- Create: `frontend/test/core/widgets/mavra_chart_test.dart`
- Modify: `frontend/pubspec.yaml`
- Modify: `frontend/pubspec.lock`

Route shell and navigation:

- Modify: `frontend/lib/app/app_shell.dart`
- Modify: `frontend/lib/app/router.dart`
- Modify: `frontend/test/app_shell_navigation_test.dart`
- Modify: `frontend/integration_test/app_smoke_test.dart`

Analytics:

- Modify: `frontend/lib/features/analytics/domain/analytics_models.dart`
- Modify: `frontend/lib/features/analytics/data/analytics_api.dart`
- Modify: `frontend/lib/features/analytics/presentation/analytics_page.dart`
- Modify: `frontend/test/features/analytics/analytics_page_test.dart`

Events:

- Modify: `frontend/lib/features/events/domain/event_models.dart`
- Modify: `frontend/lib/features/events/data/events_api.dart`
- Modify: `frontend/lib/features/events/presentation/events_page.dart`
- Modify: `frontend/test/features/events/events_page_test.dart`

Products:

- Modify: `frontend/lib/features/products/domain/product_models.dart`
- Modify: `frontend/lib/features/products/data/products_api.dart`
- Modify: `frontend/lib/features/products/presentation/products_page.dart`
- Modify: `frontend/test/features/products/products_page_test.dart`

Jobs:

- Modify: `frontend/lib/features/jobs/domain/job_models.dart`
- Modify: `frontend/lib/features/jobs/data/jobs_api.dart`
- Modify: `frontend/lib/features/jobs/presentation/jobs_page.dart`
- Modify: `frontend/test/features/jobs/jobs_page_test.dart`

Schedule:

- Modify: `frontend/lib/features/schedule/domain/schedule_models.dart`
- Modify: `frontend/lib/features/schedule/data/schedule_api.dart`
- Modify: `frontend/lib/features/schedule/presentation/schedule_page.dart`
- Modify: `frontend/test/features/schedule/schedule_page_test.dart`

Smart Home:

- Modify: `frontend/lib/features/smart_home/domain/smart_home_models.dart`
- Modify: `frontend/lib/features/smart_home/data/smart_home_api.dart`
- Modify: `frontend/lib/features/smart_home/presentation/smart_home_page.dart`
- Modify: `frontend/test/features/smart_home/smart_home_page_test.dart`

Profile and Settings:

- Modify: `frontend/lib/features/auth/domain/auth_models.dart`
- Modify: `frontend/lib/features/auth/data/auth_api.dart`
- Modify: `frontend/lib/features/auth/presentation/profile_page.dart`
- Modify: `frontend/test/features/auth/auth_flow_test.dart`
- Modify: `frontend/lib/features/settings/domain/settings_models.dart`
- Modify: `frontend/lib/features/settings/data/settings_api.dart`
- Modify: `frontend/lib/features/settings/presentation/settings_page.dart`
- Modify: `frontend/test/features/settings/settings_page_test.dart`

Admin:

- Create: `frontend/lib/features/admin/presentation/admin_users_page.dart`
- Create: `frontend/lib/features/admin/presentation/admin_audit_logs_page.dart`
- Modify: `frontend/lib/features/admin/domain/admin_models.dart`
- Modify: `frontend/lib/features/admin/data/admin_api.dart`
- Modify: `frontend/lib/features/admin/presentation/admin_page.dart`
- Modify: `frontend/test/features/admin/admin_page_test.dart`

Blog:

- Modify: `frontend/lib/features/blog/domain/blog_models.dart`
- Modify: `frontend/lib/features/blog/data/blog_api.dart`
- Modify: `frontend/lib/features/blog/presentation/blog_page.dart`
- Modify: `frontend/test/features/blog/blog_page_test.dart`

Visual QA and documentation:

- Modify: `frontend/lib/visual_qa/visual_qa_app.dart`
- Modify: `frontend/test/visual_qa/visual_qa_app_test.dart`
- Modify: `docs/flutter-migration/final-verification-report.md`
- Modify: `docs/flutter-migration/platform-verification-matrix.md`

## Global Execution Rules

- Before editing a Dart class, widget, repository, or API route, run GitNexus impact when the symbol is indexed:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement
npx gitnexus analyze
```

Then use `mcp__gitnexus.impact` for the target symbol with `direction: "upstream"`. If GitNexus cannot resolve Dart because the Dart parser is unavailable, record that limitation in the task notes and compensate with source review, widget tests, `flutter analyze`, and focused build checks.

- Never run real crawls, real Profile login/import/export against a live profile, real match jobs, or real Home Assistant control from automated tests.
- For every dangerous action test, assert only the fake repository method call or confirmation flow.
- Keep commits scoped by task. Do not stage `AGENTS.md` or `CLAUDE.md` unless the user explicitly asks.
- Use `git diff --check` and `mcp__gitnexus.detect_changes(scope: "staged")` before each commit.

---

## Task 0: Baseline, Safety, And Test Inventory

**Files:**

- Read: `docs/flutter-migration/task-17-full-react-parity-spec.md`
- Read: `frontend/pubspec.yaml`
- Read: `frontend/test/features/analytics/analytics_page_test.dart`
- Read: `frontend/test/features/events/events_page_test.dart`
- Read: `frontend/test/features/products/products_page_test.dart`
- Read: `frontend/test/features/jobs/jobs_page_test.dart`
- Read: `frontend/test/features/schedule/schedule_page_test.dart`
- Read: `frontend/test/features/smart_home/smart_home_page_test.dart`
- Read: `frontend/test/features/auth/auth_flow_test.dart`
- Read: `frontend/test/features/settings/settings_page_test.dart`
- Read: `frontend/test/features/admin/admin_page_test.dart`
- Read: `frontend/test/features/blog/blog_page_test.dart`
- Modify: `docs/flutter-migration/final-verification-report.md`

- [ ] **Step 1: Confirm worktree scope**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement
git branch --show-current
git status --short
```

Expected: branch is `codex/flutter-full-replacement`; any unrelated dirty files are listed and left untouched.

- [ ] **Step 2: Refresh code intelligence**

Run:

```powershell
npx gitnexus analyze
```

Expected: repository indexed. If Dart parser warnings appear, record them in `docs/flutter-migration/final-verification-report.md` under Task 17 notes.

- [ ] **Step 3: Run current Flutter baseline**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\frontend
flutter test
flutter analyze
```

Expected: capture current pass/fail state before changing production code. Existing failures become baseline debt and must not be misreported as new parity regressions.

- [ ] **Step 4: Commit only the baseline note if the report changed**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement
git add docs/flutter-migration/final-verification-report.md
git diff --cached --check
git commit -m "docs: record task 17 parity baseline"
```

Expected: commit occurs only if the report was modified.

---

## Task 1: Shared Workbench Primitives And Chart Support

**Files:**

- Create: `frontend/lib/core/widgets/mavra_page.dart`
- Create: `frontend/lib/core/widgets/mavra_responsive_data_view.dart`
- Create: `frontend/lib/core/widgets/mavra_confirm.dart`
- Create: `frontend/lib/core/widgets/mavra_side_sheet.dart`
- Create: `frontend/lib/core/widgets/mavra_chart.dart`
- Create: `frontend/test/core/widgets/mavra_page_test.dart`
- Create: `frontend/test/core/widgets/mavra_responsive_data_view_test.dart`
- Create: `frontend/test/core/widgets/mavra_chart_test.dart`
- Modify: `frontend/pubspec.yaml`
- Modify: `frontend/pubspec.lock`

- [ ] **Step 1: Add chart dependency through Flutter tooling**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\frontend
flutter pub add fl_chart
```

Expected: `frontend/pubspec.yaml` and `frontend/pubspec.lock` update. If `fl_chart` fails to resolve, choose a maintained Flutter chart package with Web, Windows, and Android support and record the chosen package in the commit message body.

- [ ] **Step 2: Write failing responsive data view tests**

Add `frontend/test/core/widgets/mavra_responsive_data_view_test.dart` with these assertions:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';

void main() {
  testWidgets('uses a data table on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: MavraResponsiveDataView<int>(
        rows: const [1],
        columns: const [
          DataColumn(label: Text('Name')),
        ],
        tableCells: (row) => const [
          DataCell(Text('Wide table row')),
        ],
        mobileBuilder: (context, row) => const ListTile(
          title: Text('Mobile list row'),
        ),
      ),
    ));

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Wide table row'), findsOneWidget);
    expect(find.text('Mobile list row'), findsNothing);
  });

  testWidgets('uses mobile rows on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: MavraResponsiveDataView<int>(
        rows: const [1],
        columns: const [
          DataColumn(label: Text('Name')),
        ],
        tableCells: (row) => const [
          DataCell(Text('Wide table row')),
        ],
        mobileBuilder: (context, row) => const ListTile(
          title: Text('Mobile list row'),
        ),
      ),
    ));

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Mobile list row'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Verify the test fails**

Run:

```powershell
flutter test test/core/widgets/mavra_responsive_data_view_test.dart
```

Expected: FAIL because `MavraResponsiveDataView` is not defined.

- [ ] **Step 4: Implement `MavraResponsiveDataView`**

Create `frontend/lib/core/widgets/mavra_responsive_data_view.dart` with this public API:

```dart
import 'package:flutter/material.dart';

typedef MavraTableCells<T> = List<DataCell> Function(T row);
typedef MavraMobileRowBuilder<T> = Widget Function(BuildContext context, T row);

class MavraResponsiveDataView<T> extends StatelessWidget {
  const MavraResponsiveDataView({
    super.key,
    required this.rows,
    required this.columns,
    required this.tableCells,
    required this.mobileBuilder,
    this.wideBreakpoint = 760,
    this.empty,
  });

  final List<T> rows;
  final List<DataColumn> columns;
  final MavraTableCells<T> tableCells;
  final MavraMobileRowBuilder<T> mobileBuilder;
  final double wideBreakpoint;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return empty ?? const Center(child: Text('No records'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= wideBreakpoint) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: [
                for (final row in rows) DataRow(cells: tableCells(row)),
              ],
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => mobileBuilder(context, rows[index]),
        );
      },
    );
  }
}
```

- [ ] **Step 5: Add page, confirm, side-sheet, and chart tests**

Add tests that assert:

- `MavraPageScaffold` renders title, subtitle, actions, loading, error, and empty state.
- `mavraConfirm` returns `true` only after tapping the keyed confirm button.
- `MavraSideSheet.show` renders a wide-screen right panel at `1200px` and a mobile dialog/sheet at `390px`.
- `MavraTrendChart`, `MavraBarChart`, and `MavraPieChart` render non-empty chart widgets with labels.

- [ ] **Step 6: Implement the remaining primitives**

Implement the public class/function names used by the tests:

```dart
class MavraChartPoint {
  const MavraChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class MavraPageScaffold extends StatelessWidget {
  const MavraPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.status,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ...actions,
              ],
            ),
            if (subtitle != null) Text(subtitle!),
            if (status != null) status!,
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

Future<bool> mavraConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required Key confirmKey,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: confirmKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class MavraSideSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    required String title,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class MavraTrendChart extends StatelessWidget {
  const MavraTrendChart({super.key, required this.points});

  final List<MavraChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 220, child: Text('Trend chart ${points.length}'));
  }
}

class MavraBarChart extends StatelessWidget {
  const MavraBarChart({super.key, required this.points});

  final List<MavraChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 220, child: Text('Bar chart ${points.length}'));
  }
}

class MavraPieChart extends StatelessWidget {
  const MavraPieChart({super.key, required this.points});

  final List<MavraChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 220, child: Text('Pie chart ${points.length}'));
  }
}
```

The implementation replaces the text chart bodies above with `fl_chart` widgets before this task is complete; feature pages depend only on these wrapper classes.

- [ ] **Step 7: Verify shared primitives**

Run:

```powershell
flutter test test/core/widgets
flutter analyze
```

Expected: PASS.

- [ ] **Step 8: Commit shared primitives**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement
git add frontend/pubspec.yaml frontend/pubspec.lock frontend/lib/core/widgets frontend/test/core/widgets
git diff --cached --check
git commit -m "feat: add flutter parity workbench primitives"
```

---

## Task 2: Expand Repository Contracts To Match React Workflows

**Files:**

- Modify: `frontend/lib/features/products/domain/product_models.dart`
- Modify: `frontend/lib/features/products/data/products_api.dart`
- Modify: `frontend/lib/features/jobs/domain/job_models.dart`
- Modify: `frontend/lib/features/jobs/data/jobs_api.dart`
- Modify: `frontend/lib/features/schedule/domain/schedule_models.dart`
- Modify: `frontend/lib/features/schedule/data/schedule_api.dart`
- Modify: `frontend/lib/features/admin/domain/admin_models.dart`
- Modify: `frontend/lib/features/admin/data/admin_api.dart`
- Modify: `frontend/lib/features/blog/domain/blog_models.dart`
- Modify: `frontend/lib/features/blog/data/blog_api.dart`
- Modify: `frontend/lib/features/auth/domain/auth_models.dart`
- Modify: `frontend/lib/features/auth/data/auth_api.dart`
- Modify: `frontend/lib/features/settings/domain/settings_models.dart`
- Modify: `frontend/lib/features/settings/data/settings_api.dart`
- Modify: `frontend/test/features/products/products_page_test.dart`
- Modify: `frontend/test/features/jobs/jobs_page_test.dart`
- Modify: `frontend/test/features/schedule/schedule_page_test.dart`
- Modify: `frontend/test/features/admin/admin_page_test.dart`
- Modify: `frontend/test/features/blog/blog_page_test.dart`
- Modify: `frontend/test/features/auth/auth_flow_test.dart`
- Modify: `frontend/test/features/settings/settings_page_test.dart`

- [ ] **Step 1: Audit generated client coverage**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\frontend
rg -n "productsBatch|ProductPlatform|CrawlProfile|JobSearchConfig|UserResume|RolePermission|ResourcePermission|BlogPost|SmartHome|eventsListEvents|dashboardGetTrend" lib/core/api/generated/lib/src/api lib/core/api/generated/lib/src/model
```

Expected: every React-used endpoint from the Task 17 spec is visible in generated Dart code. If an endpoint is absent, pause the feature page and update FastAPI/OpenAPI plus generated Dart client in the same task group.

- [ ] **Step 2: Extend domain models with exact parity fields**

Add these model fields without removing existing fields:

```dart
class ProductPageState { final List<ProductItem> items; final int page; final int pageSize; final int total; }
class ProductAlertDraft { final bool enabled; final String alertType; final double thresholdPercent; }
class ProductPlatformProfileBinding { final String platform; final String? profileKey; final String? profileStatus; final String? profileLastError; }
class JobPageState { final List<JobItem> items; final int page; final int pageSize; final int total; }
class JobDetail { final int id; final String title; final String company; final String? description; final String? url; }
class ResourcePermissionItem { final int id; final String resourceType; final String resourceId; final String permission; final DateTime createdAt; }
class AuditLogPageState { final List<AdminAuditLog> items; final int page; final int pageSize; final int total; }
class BlogEditorValue { final String html; final Map<String, Object?> json; }
```

Use the exact names above unless a matching class already exists, in which case extend that class.

- [ ] **Step 3: Add repository methods for missing workflows**

Add repository methods for:

- Products: `listProducts`, `getProductHistory`, `saveAlert`, `listProfileBindings`, `saveProfileBinding`, `deleteProfileBinding`, `listCrawlLogs`, `listProductSchedules`.
- Jobs: `listJobs`, `loadJobDetail`, `listMatchResults`, `createResume`, `updateResume`, `selectResumeForMatch`, `importProfileBackup`, `exportProfileBackup`.
- Schedule: `listProductSchedules`, `listJobSchedules`, `saveProductCron`, `deleteProductCron`, `saveJobCron`, `generateCron`.
- Admin: `listUsers`, `listAuditLogs`, `loadRolePermissionMatrix`, `updateRolePermissions`, `listResourcePermissions`, `grantResourcePermissions`, `updateResourcePermission`, `revokeResourcePermission`.
- Blog: `listPosts`, `loadPostDraft`, `savePost`, `uploadMedia`, `listCategories`, `listTags`.
- Profile: `updateProfile`, `changePassword`.
- Settings: `saveMotionSpeed`.

- [ ] **Step 4: Update fake repositories to compile**

Update all test fake repositories so every new method records intent into fields such as:

```dart
int? savedProductAlertId;
String? exportedProfileKey;
bool smartHomeServiceConfirmed = false;
List<String> grantedResourceIds = const [];
String? changedPasswordValue;
```

- [ ] **Step 5: Verify contract compilation**

Run:

```powershell
flutter test test/features/products/products_page_test.dart test/features/jobs/jobs_page_test.dart test/features/admin/admin_page_test.dart
flutter analyze
```

Expected: tests may fail on UI expectations in later tasks, but there must be no Dart compile errors.

- [ ] **Step 6: Commit contract expansion**

Run:

```powershell
git add frontend/lib/features frontend/test/features
git diff --cached --check
git commit -m "feat: expand flutter parity repository contracts"
```

---

## Task 3: Analytics And Events Parity

**Files:**

- Modify: `frontend/lib/features/analytics/domain/analytics_models.dart`
- Modify: `frontend/lib/features/analytics/data/analytics_api.dart`
- Modify: `frontend/lib/features/analytics/presentation/analytics_page.dart`
- Modify: `frontend/test/features/analytics/analytics_page_test.dart`
- Modify: `frontend/lib/features/events/domain/event_models.dart`
- Modify: `frontend/lib/features/events/data/events_api.dart`
- Modify: `frontend/lib/features/events/presentation/events_page.dart`
- Modify: `frontend/test/features/events/events_page_test.dart`

- [ ] **Step 1: Write failing Analytics parity tests**

Add tests that assert these labels are present at wide width:

```dart
expect(find.text('Analytics'), findsOneWidget);
expect(find.text('7d'), findsOneWidget);
expect(find.text('Price trend'), findsOneWidget);
expect(find.text('Price change rate'), findsOneWidget);
expect(find.text('Platform success'), findsOneWidget);
expect(find.text('Crawl failures'), findsOneWidget);
expect(find.text('Recent alerts'), findsOneWidget);
expect(find.byType(MavraTrendChart), findsWidgets);
expect(find.byType(MavraPieChart), findsWidgets);
```

Also add a narrow-width test that keeps the same labels visible in stacked order.

- [ ] **Step 2: Implement Analytics page**

Replace progress-row chart stand-ins with `MavraTrendChart`, `MavraBarChart`, and `MavraPieChart`. Keep existing realtime `watchOverview()` behavior and add a `SegmentedButton<int>` for `7`, `30`, and `90` day ranges. Admin-only sections render only when admin/system KPI data is available.

- [ ] **Step 3: Run Analytics tests**

Run:

```powershell
flutter test test/features/analytics/analytics_page_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 4: Write failing Events parity tests**

Add tests that set `tester.view.physicalSize = const Size(1280, 900)` and assert:

```dart
expect(find.byType(DataTable), findsOneWidget);
expect(find.text('Kind'), findsOneWidget);
expect(find.text('Event type'), findsOneWidget);
expect(find.text('Category'), findsOneWidget);
expect(find.text('Severity'), findsOneWidget);
expect(find.text('Source'), findsOneWidget);
expect(find.text('Keyword'), findsOneWidget);
expect(find.byKey(const Key('events-reset-filters-button')), findsOneWidget);
expect(find.byKey(const Key('event-detail-event-1-button')), findsOneWidget);
```

Add an SSE merge test where the fake repository emits the same event ID twice and the UI still shows one row for that ID.

- [ ] **Step 5: Implement Events page**

Use `MavraResponsiveDataView<EventFeedItem>` for table/list switching. Use `MavraSideSheet.show` for event details on wide screens and the mobile path. Add reset behavior that clears kind, type, category, severity, source, keyword, start, and end fields before reloading page 1.

- [ ] **Step 6: Run Events tests**

Run:

```powershell
flutter test test/features/events/events_page_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 7: Commit Analytics and Events**

Run:

```powershell
git add frontend/lib/features/analytics frontend/test/features/analytics frontend/lib/features/events frontend/test/features/events
git diff --cached --check
git commit -m "feat: restore flutter analytics and events parity"
```

---

## Task 4: Products Parity

**Files:**

- Modify: `frontend/lib/features/products/domain/product_models.dart`
- Modify: `frontend/lib/features/products/data/products_api.dart`
- Modify: `frontend/lib/features/products/presentation/products_page.dart`
- Modify: `frontend/test/features/products/products_page_test.dart`

- [ ] **Step 1: Write failing Products parity tests**

Extend `products_page_test.dart` with these assertions:

```dart
expect(find.byKey(const Key('product-platform-filter')), findsOneWidget);
expect(find.byKey(const Key('product-active-filter')), findsOneWidget);
expect(find.byKey(const Key('product-page-size-field')), findsOneWidget);
expect(find.byKey(const Key('product-import-open-button')), findsOneWidget);
expect(find.byKey(const Key('product-batch-delete-confirm-button')), findsOneWidget);
expect(find.byKey(const Key('product-alert-enabled-field')), findsOneWidget);
expect(find.byKey(const Key('product-profile-binding-taobao-button')), findsOneWidget);
expect(find.byKey(const Key('product-cron-taobao-edit-button')), findsOneWidget);
expect(find.byType(MavraTrendChart), findsOneWidget);
```

Add fake repository assertions:

```dart
expect(repository.lastListQuery.platform, 'jd');
expect(repository.lastListQuery.active, false);
expect(repository.savedAlertProductId, 1);
expect(repository.savedProfileBindingPlatform, 'taobao');
expect(repository.deletedCronPlatform, 'jd');
```

- [ ] **Step 2: Implement server-side query state**

Update `ProductRepository` and `GeneratedProductRepository` so list calls accept keyword, platform, active, page, and page size. Store the returned page metadata in `ProductsSnapshot`.

- [ ] **Step 3: Implement dense product table and mobile list**

Use `MavraResponsiveDataView<ProductItem>` with columns for selection, platform, title/link, current price, active state, updated time, and actions. Keep row keys stable:

```dart
Key('product-select-${product.id}')
Key('product-open-${product.id}-button')
Key('product-trend-${product.id}-button')
Key('product-edit-${product.id}-button')
Key('product-delete-${product.id}-button')
```

- [ ] **Step 4: Implement product dialogs and confirmations**

Product add/edit uses a dialog or side sheet with title, URL, platform selector, active switch, alert enable switch, threshold field, and save button. Batch delete and single delete use `mavraConfirm` with explicit confirm keys.

- [ ] **Step 5: Implement trend, crawl log, schedule, and profile sections**

Trend uses `MavraTrendChart` with day-range chips `7d`, `30d`, `90d`, `All`. Crawl logs use a dense table on wide screens. Schedule and profile binding sections show current platform rows and open management actions without triggering crawls.

- [ ] **Step 6: Run Products tests**

Run:

```powershell
flutter test test/features/products/products_page_test.dart
flutter analyze
```

Expected: PASS. Fake repository fields show request intent only.

- [ ] **Step 7: Commit Products**

Run:

```powershell
git add frontend/lib/features/products frontend/test/features/products
git diff --cached --check
git commit -m "feat: restore flutter products parity"
```

---

## Task 5: Jobs Parity

**Files:**

- Modify: `frontend/lib/features/jobs/domain/job_models.dart`
- Modify: `frontend/lib/features/jobs/data/jobs_api.dart`
- Modify: `frontend/lib/features/jobs/presentation/jobs_page.dart`
- Modify: `frontend/test/features/jobs/jobs_page_test.dart`

- [ ] **Step 1: Write failing real tab tests**

Update `jobs_page_test.dart` so tapping each tab hides unrelated sections:

```dart
await tester.tap(find.byKey(const Key('job-tab-profiles')));
await tester.pumpAndSettle();
expect(find.text('Profile management'), findsOneWidget);
expect(find.text('Search configs'), findsNothing);

await tester.tap(find.byKey(const Key('job-tab-jobs')));
await tester.pumpAndSettle();
expect(find.byKey(const Key('job-keyword-filter')), findsOneWidget);
expect(find.byKey(const Key('job-status-filter')), findsOneWidget);
```

- [ ] **Step 2: Replace decorative chips with `TabController`**

Implement tabs: `Configs`, `Jobs`, `Match Results`, `Resumes`, `Profiles`, `Crawl Logs`. Use `TabBar` plus `TabBarView` on wide screens and segmented chips that update the same selected tab on narrow screens.

- [ ] **Step 3: Restore Configs tab**

Add config CRUD form fields: name, platform, profile, URL, keyword, city code, salary min/max, experience, education, deactivation threshold, active, notify on new, and auto-match. Per-config crawl and crawl-all buttons call fake repository methods only in tests.

- [ ] **Step 4: Restore Jobs tab**

Add keyword/status filters, page size, pagination, dense job table, mobile list, detail side sheet, original-link display, resume selector, and match action. The match action calls `requestMatchAnalysis(job.id, resumeId: selectedResume.id)`.

- [ ] **Step 5: Restore Resume, Profile, Match, and Logs tabs**

Resume tab supports create, edit, delete, upload. Profile tab supports create, rename, copy, mark available, mark login required, disable, delete, release stale, open login session, close login session, test profile, import backup, and export backup. Match Results and Crawl Logs render dense tables with mobile lists.

- [ ] **Step 6: Run Jobs tests**

Run:

```powershell
flutter test test/features/jobs/jobs_page_test.dart
flutter analyze
```

Expected: PASS. No test opens a real browser profile, imports a real profile backup into shared storage, exports a real profile backup, or starts a real crawl.

- [ ] **Step 7: Commit Jobs**

Run:

```powershell
git add frontend/lib/features/jobs frontend/test/features/jobs
git diff --cached --check
git commit -m "feat: restore flutter jobs parity"
```

---

## Task 6: Schedule Parity

**Files:**

- Modify: `frontend/lib/features/schedule/domain/schedule_models.dart`
- Modify: `frontend/lib/features/schedule/data/schedule_api.dart`
- Modify: `frontend/lib/features/schedule/presentation/schedule_page.dart`
- Modify: `frontend/test/features/schedule/schedule_page_test.dart`

- [ ] **Step 1: Write failing schedule table tests**

Assert the wide screen page contains:

```dart
expect(find.text('Product Crawl Schedule Config'), findsOneWidget);
expect(find.text('Job Crawl Schedule Config'), findsOneWidget);
expect(find.byKey(const Key('schedule-product-taobao-cron-field')), findsOneWidget);
expect(find.byKey(const Key('schedule-product-taobao-generator-button')), findsOneWidget);
expect(find.byKey(const Key('schedule-product-taobao-save-button')), findsOneWidget);
expect(find.byKey(const Key('schedule-product-taobao-delete-button')), findsOneWidget);
expect(find.byKey(const Key('schedule-retention-days-field')), findsOneWidget);
expect(find.byKey(const Key('schedule-webhook-url-field')), findsOneWidget);
```

- [ ] **Step 2: Implement two schedule tables**

Replace the abstract `New rule` workflow with product platform and job config tables. Each editable cron cell keeps a controller keyed by platform or config ID.

- [ ] **Step 3: Implement Cron Generator dialog**

The dialog includes presets `Every hour`, `Daily at 9am`, `Weekdays at 6pm`, `Every Monday`, and `Every 30 min`; a natural-language input; generated expression; validity indicator; and apply button. The parser must support the preset phrases without network access.

- [ ] **Step 4: Implement retention and webhook settings**

Keep existing save settings repository path. Disable save buttons when the user lacks config write permission.

- [ ] **Step 5: Run Schedule tests**

Run:

```powershell
flutter test test/features/schedule/schedule_page_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 6: Commit Schedule**

Run:

```powershell
git add frontend/lib/features/schedule frontend/test/features/schedule
git diff --cached --check
git commit -m "feat: restore flutter schedule parity"
```

---

## Task 7: Smart Home Parity

**Files:**

- Modify: `frontend/lib/features/smart_home/domain/smart_home_models.dart`
- Modify: `frontend/lib/features/smart_home/data/smart_home_api.dart`
- Modify: `frontend/lib/features/smart_home/presentation/smart_home_page.dart`
- Modify: `frontend/test/features/smart_home/smart_home_page_test.dart`

- [ ] **Step 1: Write failing entity-control tests**

Add tests for grouped device cards and domain controls:

```dart
expect(find.text('Living Room'), findsOneWidget);
expect(find.byKey(const Key('smart-home-domain-light-filter')), findsOneWidget);
expect(find.byKey(const Key('smart-home-entity-light.living_room-toggle')), findsOneWidget);
expect(find.byKey(const Key('smart-home-cover-cover.blinds-open-button')), findsOneWidget);
expect(find.byKey(const Key('smart-home-climate-climate.ac-mode-field')), findsOneWidget);
expect(find.byKey(const Key('smart-home-run-scene.movie-button')), findsOneWidget);
```

For scene/script and generic service calls, assert confirmation before fake repository `callService` is recorded.

- [ ] **Step 2: Implement grouped grid/list**

Group entities by area or device name. Wide screens render a grid; mobile renders cards in a list. Preserve status header, refresh, connected/offline tag, last error, and realtime entity updates.

- [ ] **Step 3: Implement entity-specific controls**

Use native controls:

- switch/light/fan: toggle switch.
- cover: open, stop, close buttons.
- climate: HVAC mode menu and temperature input.
- scene/script: run button with confirmation.
- unknown domain: disabled service button with entity details.

- [ ] **Step 4: Implement config dialog**

Config dialog includes base URL, token field with keep-existing wording, enabled switch, test connection button, save button, and loading/error feedback.

- [ ] **Step 5: Run Smart Home tests**

Run:

```powershell
flutter test test/features/smart_home/smart_home_page_test.dart
flutter analyze
```

Expected: PASS. Fake repository records service intent only after confirmation.

- [ ] **Step 6: Commit Smart Home**

Run:

```powershell
git add frontend/lib/features/smart_home frontend/test/features/smart_home
git diff --cached --check
git commit -m "feat: restore flutter smart home parity"
```

---

## Task 8: Profile And Settings Parity

**Files:**

- Modify: `frontend/lib/features/auth/domain/auth_models.dart`
- Modify: `frontend/lib/features/auth/data/auth_api.dart`
- Modify: `frontend/lib/features/auth/presentation/profile_page.dart`
- Modify: `frontend/test/features/auth/auth_flow_test.dart`
- Modify: `frontend/lib/features/settings/domain/settings_models.dart`
- Modify: `frontend/lib/features/settings/data/settings_api.dart`
- Modify: `frontend/lib/features/settings/presentation/settings_page.dart`
- Modify: `frontend/test/features/settings/settings_page_test.dart`

- [ ] **Step 1: Write failing Profile form tests**

Assert:

```dart
expect(find.byKey(const Key('profile-username-field')), findsOneWidget);
expect(find.byKey(const Key('profile-email-field')), findsOneWidget);
expect(find.byKey(const Key('profile-save-button')), findsOneWidget);
expect(find.byKey(const Key('profile-current-password-field')), findsOneWidget);
expect(find.byKey(const Key('profile-new-password-field')), findsOneWidget);
expect(find.byKey(const Key('profile-change-password-button')), findsOneWidget);
```

Submit values and assert fake auth repository recorded username, email, old password, and new password.

- [ ] **Step 2: Implement Profile forms**

Keep account overview, sessions, and login history. Add account edit form and password-change form with strong-password guidance text matching existing auth policy wording.

- [ ] **Step 3: Write failing Settings tests**

Assert:

```dart
expect(find.byKey(const Key('settings-feishu-field')), findsOneWidget);
expect(find.byKey(const Key('settings-retention-field')), findsOneWidget);
expect(find.byKey(const Key('settings-motion-speed-fast')), findsOneWidget);
expect(find.byKey(const Key('settings-theme-system')), findsOneWidget);
expect(find.textContaining('Secure storage'), findsOneWidget);
```

- [ ] **Step 4: Implement Settings parity**

Keep Feishu webhook, data retention days, theme selector, and platform capability chips. Add page transition speed segmented control with `fast`, `normal`, and `slow` values persisted through settings repository or local preference model.

- [ ] **Step 5: Run Profile and Settings tests**

Run:

```powershell
flutter test test/features/auth/auth_flow_test.dart test/features/settings/settings_page_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 6: Commit Profile and Settings**

Run:

```powershell
git add frontend/lib/features/auth frontend/test/features/auth frontend/lib/features/settings frontend/test/features/settings
git diff --cached --check
git commit -m "feat: restore flutter profile and settings parity"
```

---

## Task 9: Admin Users And Audit Logs Split

**Files:**

- Create: `frontend/lib/features/admin/presentation/admin_users_page.dart`
- Create: `frontend/lib/features/admin/presentation/admin_audit_logs_page.dart`
- Modify: `frontend/lib/features/admin/presentation/admin_page.dart`
- Modify: `frontend/lib/app/router.dart`
- Modify: `frontend/lib/features/admin/domain/admin_models.dart`
- Modify: `frontend/lib/features/admin/data/admin_api.dart`
- Modify: `frontend/test/features/admin/admin_page_test.dart`
- Modify: `frontend/test/app_shell_navigation_test.dart`

- [ ] **Step 1: Write failing route split tests**

Assert `/admin/users` renders `User Management` and not `Audit Logs` as the primary page title. Assert `/admin/audit-logs` renders `Audit Logs` and not `User Management` as the primary page title.

- [ ] **Step 2: Implement separate page widgets**

`AdminUsersPage` owns user table, user CRUD, role permissions, and resource permissions. `AdminAuditLogsPage` owns audit log table, action labels/colors, details JSON display, IP address, timestamp, filters, and pagination. Keep `AdminPage` only as a compatibility wrapper or remove route usage if no longer needed.

- [ ] **Step 3: Restore Users workflows**

Implement search, role filter, paginated table, create/edit modal, enable/disable confirmation, delete confirmation, resource permission list, grant modal, inline edit/revoke, and role permission matrix checkboxes gated by `rbac:manage`.

- [ ] **Step 4: Restore Audit Logs workflows**

Implement action/actor filters, dense table, details JSON, and pagination with page size. No user CRUD controls appear on `/admin/audit-logs`.

- [ ] **Step 5: Run Admin tests**

Run:

```powershell
flutter test test/features/admin/admin_page_test.dart test/app_shell_navigation_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 6: Commit Admin split**

Run:

```powershell
git add frontend/lib/features/admin frontend/lib/app/router.dart frontend/test/features/admin frontend/test/app_shell_navigation_test.dart
git diff --cached --check
git commit -m "feat: split flutter admin users and audit logs parity"
```

---

## Task 10: Blog Studio Parity

**Files:**

- Modify: `frontend/lib/features/blog/domain/blog_models.dart`
- Modify: `frontend/lib/features/blog/data/blog_api.dart`
- Modify: `frontend/lib/features/blog/presentation/blog_page.dart`
- Modify: `frontend/test/features/blog/blog_page_test.dart`

- [ ] **Step 1: Write failing Blog parity tests**

Assert:

```dart
expect(find.byKey(const Key('blog-search-field')), findsOneWidget);
expect(find.byKey(const Key('blog-status-filter')), findsOneWidget);
expect(find.byType(DataTable), findsOneWidget);
expect(find.byKey(const Key('blog-new-post-button')), findsOneWidget);
expect(find.byKey(const Key('blog-published-at-field')), findsOneWidget);
expect(find.byKey(const Key('blog-category-field')), findsOneWidget);
expect(find.byKey(const Key('blog-tags-field')), findsOneWidget);
expect(find.byKey(const Key('blog-cover-upload-button')), findsOneWidget);
expect(find.byKey(const Key('blog-editor-bold-button')), findsOneWidget);
expect(find.byKey(const Key('blog-editor-link-button')), findsOneWidget);
expect(find.byKey(const Key('blog-canonical-url-field')), findsOneWidget);
expect(find.byKey(const Key('blog-og-image-field')), findsOneWidget);
```

- [ ] **Step 2: Implement post table and filters**

Use `MavraResponsiveDataView<BlogPostItem>`. Search and status filters call repository list with exact keyword/status values. New/edit opens a dialog or side sheet.

- [ ] **Step 3: Implement editor form**

Fields: title, status, slug, publish time, excerpt, category picker, tag picker, cover URL plus upload button, body editor, SEO title, SEO description, canonical URL, Open Graph image. Body editor must provide toolbar buttons for bold, italic, bullet list, numbered list, link, and image URL. Store body as `BlogEditorValue` or equivalent structured value that maps to the generated API payload.

- [ ] **Step 4: Implement media upload and save**

Upload uses `FileService.pickFile()` and repository `uploadMedia`. Save creates or updates through `BlogRepository.savePost`. Tests assert fake repository receives media file name and full post draft values.

- [ ] **Step 5: Run Blog tests**

Run:

```powershell
flutter test test/features/blog/blog_page_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 6: Commit Blog**

Run:

```powershell
git add frontend/lib/features/blog frontend/test/features/blog
git diff --cached --check
git commit -m "feat: restore flutter blog studio parity"
```

---

## Task 11: Navigation, Permissions, Visual QA Data, And Integration Smoke

**Files:**

- Modify: `frontend/lib/app/app_shell.dart`
- Modify: `frontend/lib/app/router.dart`
- Modify: `frontend/lib/visual_qa/visual_qa_app.dart`
- Modify: `frontend/test/app_shell_navigation_test.dart`
- Modify: `frontend/test/visual_qa/visual_qa_app_test.dart`
- Modify: `frontend/integration_test/app_smoke_test.dart`

- [ ] **Step 1: Write failing navigation and permission tests**

Assert the shell shows Today, Analytics, Activity, Jobs, Prices, Schedules, Home, Blog, Users, and Audit Logs when permissions allow. Assert Blog is hidden without `blog:read_admin`; Users and Audit Logs are hidden without `user:read`; Settings route is blocked without `config:read`.

- [ ] **Step 2: Remove local page navigation duplication**

Feature pages should rely on `MavraShell`. Remove page-local `AdaptiveScaffold` destinations where they duplicate the global shell.

- [ ] **Step 3: Expand visual QA fixtures**

Update `frontend/lib/visual_qa/visual_qa_app.dart` so fixtures include non-empty data for Today, Dashboard, Events, Products, Jobs, Schedule, Smart Home, Profile, Settings, Users, Audit Logs, and Blog. Include long text values that exercise overflow and wrapping.

- [ ] **Step 4: Expand integration smoke route coverage**

Update `frontend/integration_test/app_smoke_test.dart` to log in, open every protected route, verify one route-specific key, use browser/system back navigation, and return to Today. Android-specific smoke must include rotation, text input, and safe-area coverage.

- [ ] **Step 5: Run app shell and smoke tests locally where supported**

Run:

```powershell
flutter test test/app_shell_navigation_test.dart test/visual_qa/visual_qa_app_test.dart
flutter test integration_test/app_smoke_test.dart -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Expected: widget tests PASS. Windows integration smoke PASS when backend is running; if backend is not running, record that device smoke is pending backend startup rather than marking it passed.

- [ ] **Step 6: Commit navigation and smoke updates**

Run:

```powershell
git add frontend/lib/app frontend/lib/visual_qa frontend/test/app_shell_navigation_test.dart frontend/test/visual_qa frontend/integration_test/app_smoke_test.dart
git diff --cached --check
git commit -m "test: expand flutter parity navigation and smoke coverage"
```

---

## Task 12: Final Verification And Evidence

**Files:**

- Modify: `docs/flutter-migration/final-verification-report.md`
- Modify: `docs/flutter-migration/platform-verification-matrix.md`
- Add screenshots under the existing screenshot/evidence directory used by the project, or create `docs/flutter-migration/evidence/task-17/` if no current directory exists.

- [ ] **Step 1: Run full Flutter verification**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\frontend
flutter test
flutter analyze
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Expected: PASS or a documented environment blocker with command output summary.

- [ ] **Step 2: Run backend contract verification if OpenAPI changed**

Run only if backend routes/schemas or generated API changed:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\backend
uv run --extra dev python -m pytest
uv run --extra dev python ../scripts/check_api_contract.py
```

Expected: PASS or documented backend environment failure.

- [ ] **Step 3: Run device smoke checks**

Web:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement\frontend
flutter run -d chrome --web-port 3001 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Windows:

```powershell
.\build\windows\x64\runner\Release\mavra_frontend.exe
```

Android emulator:

```powershell
flutter test integration_test/app_smoke_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Expected: each device opens every old React protected route and records evidence. iOS remains deferred.

- [ ] **Step 4: Capture visual QA screenshots**

Capture Web and Windows screenshots for:

```text
Today
Dashboard
Events
Products
Jobs
Schedule
Smart Home
Profile
Settings
Users
Audit Logs
Blog
```

Expected: screenshots show no white screens, no clipped controls, no overlapping text, no hidden primary actions, no mobile-only layout on desktop width, and no desktop-only table overflow on Android.

- [ ] **Step 5: Update verification docs**

Update `final-verification-report.md` with command, date, result, and screenshot paths. Update `platform-verification-matrix.md` with Web, Windows, Android emulator, and iOS deferred status.

- [ ] **Step 6: Run final GitNexus and diff checks**

Run:

```powershell
cd C:\Users\arfac\Documents\mavra-monitor-system\.worktrees\flutter-full-replacement
git diff --check
```

Then run `mcp__gitnexus.detect_changes` with `scope: "all"` and review any medium or higher risk areas before final commit.

- [ ] **Step 7: Commit final verification docs**

Run:

```powershell
git add docs/flutter-migration/final-verification-report.md docs/flutter-migration/platform-verification-matrix.md docs/flutter-migration/evidence
git diff --cached --check
git commit -m "docs: record flutter full parity verification"
```

## Completion Definition

Task 17 is complete only when:

- Every old React protected route in the spec has a Flutter page with equivalent business workflows.
- Web, Windows, and Android emulator device gates are executed or blocked by a documented environment issue.
- `flutter test`, `flutter analyze`, and build commands are executed and reported honestly.
- Dangerous actions are covered by fake repository or intent tests only.
- `final-verification-report.md` and `platform-verification-matrix.md` contain current evidence.
- Independent code review is run after implementation and before merge.
