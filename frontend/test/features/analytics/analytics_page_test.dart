import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/widgets/mavra_chart.dart';
import 'package:mavra_frontend/features/analytics/domain/analytics_models.dart';
import 'package:mavra_frontend/features/analytics/presentation/analytics_page.dart';

void main() {
  testWidgets('renders React dashboard parity content outside the banner', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeAnalyticsRepository(overview: _overview());

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          repository: repository,
          canViewSystemAnalytics: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('数据分析'), findsOneWidget);
    expect(find.text('监控系统运行状态、价格走势统计与候选人匹配度分析'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(find.text('Events'), findsNothing);
    expect(find.text('Alerts'), findsNothing);

    final banner = find.byKey(const Key('dashboard-banner'));
    expect(banner, findsOneWidget);
    expect(
      find.descendant(of: banner, matching: find.text('30天')),
      findsNothing,
    );
    expect(find.byKey(const Key('dashboard-range-toolbar')), findsOneWidget);
    expect(repository.loadCalls.single, (days: 30, includeAdmin: true));

    for (final label in const [
      '监控商品数',
      '今日降价',
      '新职位数',
      '匹配分析',
      '今日爬取',
      '各平台商品分布',
      '价格趋势',
      '价格变化率趋势',
      '各平台职位分布',
      '新增职位趋势',
      '职位匹配趋势',
      '系统运营',
      '总用户数',
      '成功率',
      '最近告警',
    ]) {
      expect(find.text(label, skipOffstage: false), findsWidgets);
    }

    expect(
      find.text('Taobao rice cooker dropped 12%', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('降价', skipOffstage: false), findsOneWidget);
    expect(find.text('taobao', skipOffstage: false), findsWidgets);
    expect(find.byType(MavraTrendChart), findsWidgets);
    expect(find.byType(MavraBarChart), findsWidgets);
    expect(find.byType(MavraPieChart), findsWidgets);
  });

  testWidgets(
    'keeps admin-only dashboard sections behind user read permission',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnalyticsPage(
            repository: _FakeAnalyticsRepository(overview: _overview()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('系统运营'), findsNothing);
      expect(find.text('最近告警'), findsNothing);
      expect(find.text('各平台商品分布', skipOffstage: false), findsOneWidget);
    },
  );

  testWidgets('changes time range and reloads dashboard data', (tester) async {
    final repository = _FakeAnalyticsRepository(overview: _overview());

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          repository: repository,
          canViewSystemAnalytics: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('7天'));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, [
      (days: 30, includeAdmin: true),
      (days: 7, includeAdmin: true),
    ]);
  });

  testWidgets('realtime KPI updates do not replace trends or alerts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeAnalyticsRepository(overview: _overview());

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          repository: repository,
          canViewSystemAnalytics: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    repository.emit(
      const AnalyticsKpiSnapshot(
        user: DashboardUserKpi(
          totalProducts: 88,
          priceDropsToday: 5,
          newJobsToday: 6,
          matchCount: 7,
          crawlCountToday: 9,
        ),
        system: DashboardSystemKpi(
          totalUsers: 4,
          totalCrawls: 90,
          successRate: 0.91,
          activeAlerts: 3,
          diskUsage: 0.45,
          memoryUsage: 0.62,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('88'), findsOneWidget);
    expect(find.text('91.0%'), findsOneWidget);
    expect(find.text('价格趋势', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Taobao rice cooker dropped 12%', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('renders empty, warning, loading, and hard error states', (
    tester,
  ) async {
    final loading = Completer<AnalyticsOverview>();
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          repository: _FakeAnalyticsRepository(overviewFuture: loading.future),
        ),
      ),
    );

    expect(find.text('正在加载数据分析...'), findsOneWidget);
    loading.complete(_overview(userTrends: const [], recentAlerts: const []));
    await tester.pumpAndSettle();

    expect(find.text('暂无数据'), findsWidgets);
    expect(find.text('暂无告警'), findsNothing);

    final repository = _FakeAnalyticsRepository(overview: _overview());
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          key: const ValueKey('warning-dashboard'),
          repository: repository,
          canViewSystemAnalytics: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    repository.failRealtime();
    await tester.pumpAndSettle();
    expect(find.text('连接断开，正在重连...'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(repository: _FailingAnalyticsRepository()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Analytics unavailable'), findsOneWidget);
  });

  testWidgets('uses desktop and mobile dashboard layout keys', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          repository: _FakeAnalyticsRepository(overview: _overview()),
          canViewSystemAnalytics: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-desktop-layout')), findsOneWidget);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          repository: _FakeAnalyticsRepository(overview: _overview()),
          canViewSystemAnalytics: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-mobile-layout')), findsOneWidget);
  });
}

class _FakeAnalyticsRepository implements AnalyticsRepository {
  _FakeAnalyticsRepository({this.overview, this.overviewFuture});

  final AnalyticsOverview? overview;
  final Future<AnalyticsOverview>? overviewFuture;
  final _controller = StreamController<AnalyticsKpiSnapshot>.broadcast();
  final List<({int days, bool includeAdmin})> loadCalls = [];

  @override
  Future<AnalyticsOverview> loadOverview({
    int days = 30,
    bool includeAdmin = false,
  }) async {
    loadCalls.add((days: days, includeAdmin: includeAdmin));
    return overviewFuture ?? Future.value(overview ?? _overviewFixture());
  }

  @override
  Stream<AnalyticsKpiSnapshot> watchKpiUpdates() => _controller.stream;

  void emit(AnalyticsKpiSnapshot value) => _controller.add(value);

  void failRealtime() => _controller.addError(StateError('offline'));
}

class _FailingAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<AnalyticsOverview> loadOverview({
    int days = 30,
    bool includeAdmin = false,
  }) {
    throw StateError('analytics down');
  }

  @override
  Stream<AnalyticsKpiSnapshot> watchKpiUpdates() => const Stream.empty();
}

AnalyticsOverview _overview({
  List<AnalyticsTrendSection>? userTrends,
  List<AnalyticsRecentAlert>? recentAlerts,
}) {
  return AnalyticsOverview(
    userKpi: const DashboardUserKpi(
      totalProducts: 12,
      priceDropsToday: 2,
      newJobsToday: 4,
      matchCount: 5,
      crawlCountToday: 9,
    ),
    systemKpi: const DashboardSystemKpi(
      totalUsers: 3,
      totalCrawls: 45,
      successRate: 0.96,
      activeAlerts: 2,
      diskUsage: 0.41,
      memoryUsage: 0.68,
    ),
    userTrends: userTrends ?? _userTrends(),
    systemTrends: _systemTrends(),
    recentAlerts:
        recentAlerts ??
        [
          AnalyticsRecentAlert(
            id: 1,
            message: 'Taobao rice cooker dropped 12%',
            productTitle: 'Taobao rice cooker',
            alertType: 'price_drop',
            active: true,
            createdAt: DateTime.utc(2026, 6, 17, 8),
            platform: 'taobao',
          ),
        ],
  );
}

AnalyticsOverview _overviewFixture() => _overview();

List<AnalyticsTrendSection> _userTrends() => const [
  AnalyticsTrendSection(
    type: AnalyticsTrendType.platformProducts,
    title: '各平台商品分布',
    chartKind: AnalyticsChartKind.pie,
    series: [
      TrendSeries(
        label: 'products',
        points: [
          TrendPoint(label: 'taobao', value: 5),
          TrendPoint(label: 'jd', value: 4),
        ],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.price,
    title: '价格趋势',
    chartKind: AnalyticsChartKind.line,
    series: [
      TrendSeries(
        label: 'price',
        points: [
          TrendPoint(label: 'Mon', value: 12),
          TrendPoint(label: 'Tue', value: 18),
        ],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.priceChange,
    title: '价格变化率趋势',
    chartKind: AnalyticsChartKind.line,
    series: [
      TrendSeries(
        label: 'price_change',
        points: [TrendPoint(label: 'Mon', value: -6)],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.platformJobs,
    title: '各平台职位分布',
    chartKind: AnalyticsChartKind.pie,
    series: [
      TrendSeries(
        label: 'jobs',
        points: [TrendPoint(label: 'boss', value: 8)],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.jobs,
    title: '新增职位趋势',
    chartKind: AnalyticsChartKind.line,
    series: [
      TrendSeries(
        label: 'jobs',
        points: [TrendPoint(label: 'Mon', value: 3)],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.jobMatches,
    title: '职位匹配趋势',
    chartKind: AnalyticsChartKind.line,
    series: [
      TrendSeries(
        label: 'matches',
        points: [TrendPoint(label: 'Mon', value: 6)],
      ),
    ],
  ),
];

List<AnalyticsTrendSection> _systemTrends() => const [
  AnalyticsTrendSection(
    type: AnalyticsTrendType.platformSuccess,
    title: '平台成功率对比',
    chartKind: AnalyticsChartKind.bar,
    series: [
      TrendSeries(
        label: 'success',
        points: [TrendPoint(label: 'taobao', value: 92)],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.crawlFailures,
    title: '爬取失败趋势',
    chartKind: AnalyticsChartKind.bar,
    series: [
      TrendSeries(
        label: 'failures',
        points: [TrendPoint(label: 'Mon', value: 2)],
      ),
    ],
  ),
];
