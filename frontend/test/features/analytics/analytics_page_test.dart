import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/widgets/mavra_chart.dart';
import 'package:mavra_frontend/features/analytics/domain/analytics_models.dart';
import 'package:mavra_frontend/features/analytics/presentation/analytics_page.dart';

void main() {
  testWidgets('renders KPI cards, chart data, and recent alerts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          repository: _FakeAnalyticsRepository(overview: _overview()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Price drops'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Price trend'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    expect(
      find.text('Taobao rice cooker dropped 12%', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('renders React parity analytics charts on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          repository: _FakeAnalyticsRepository(overview: _overview()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('7d'), findsOneWidget);
    expect(find.text('Price trend'), findsOneWidget);
    expect(find.text('Price change rate'), findsOneWidget);
    expect(find.text('Platform success'), findsOneWidget);
    expect(find.text('Crawl failures'), findsOneWidget);
    expect(find.text('Recent alerts'), findsOneWidget);
    expect(find.byType(MavraTrendChart), findsWidgets);
    expect(find.byType(MavraPieChart), findsWidgets);
  });

  testWidgets('keeps analytics parity labels visible on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(
          repository: _FakeAnalyticsRepository(overview: _overview()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('7d'), findsOneWidget);
    expect(find.text('Price trend'), findsOneWidget);
    expect(find.text('Price change rate'), findsOneWidget);
    expect(find.text('Platform success'), findsOneWidget);
    expect(find.text('Crawl failures'), findsOneWidget);
    expect(find.text('Recent alerts'), findsOneWidget);
  });

  testWidgets('renders analytics error state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsPage(repository: _FailingAnalyticsRepository()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Analytics unavailable'), findsOneWidget);
  });

  testWidgets('uses realtime data ahead of initial analytics data', (
    tester,
  ) async {
    final repository = _FakeAnalyticsRepository(overview: _overview());

    await tester.pumpWidget(
      MaterialApp(home: AnalyticsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    repository.emit(
      AnalyticsOverview(
        kpis: const [
          AnalyticsKpi(label: 'Price drops', value: '5'),
          AnalyticsKpi(label: 'New jobs', value: '8'),
        ],
        trends: const [
          TrendSeries(
            label: 'Realtime trend',
            points: [TrendPoint(label: 'Now', value: 21)],
          ),
        ],
        recentAlerts: const [
          AnalyticsRecentAlert(
            message: 'Realtime alert is freshest',
            productTitle: 'JD office chair',
            alertType: 'price_drop',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('Realtime trend'), findsOneWidget);
    expect(find.text('Realtime alert is freshest'), findsOneWidget);
    expect(find.text('Taobao rice cooker dropped 12%'), findsNothing);
  });
}

class _FakeAnalyticsRepository implements AnalyticsRepository {
  _FakeAnalyticsRepository({required this.overview});

  final AnalyticsOverview overview;
  final _controller = StreamController<AnalyticsOverview>.broadcast();

  @override
  Future<AnalyticsOverview> loadOverview() async => overview;

  @override
  Stream<AnalyticsOverview> watchOverview() => _controller.stream;

  void emit(AnalyticsOverview value) => _controller.add(value);
}

class _FailingAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<AnalyticsOverview> loadOverview() {
    throw StateError('analytics down');
  }

  @override
  Stream<AnalyticsOverview> watchOverview() => const Stream.empty();
}

AnalyticsOverview _overview() {
  return const AnalyticsOverview(
    kpis: [
      AnalyticsKpi(label: 'Price drops', value: '2'),
      AnalyticsKpi(label: 'New jobs', value: '4'),
      AnalyticsKpi(label: 'Crawls', value: '7'),
    ],
    trends: [
      TrendSeries(
        label: 'Price trend',
        points: [
          TrendPoint(label: 'Monday', value: 12),
          TrendPoint(label: 'Tuesday', value: 18),
        ],
      ),
      TrendSeries(
        label: 'Price change rate',
        points: [
          TrendPoint(label: 'Taobao', value: 12),
          TrendPoint(label: 'JD', value: 8),
        ],
      ),
      TrendSeries(
        label: 'Platform success',
        points: [
          TrendPoint(label: 'Taobao', value: 92),
          TrendPoint(label: 'JD', value: 88),
        ],
      ),
      TrendSeries(
        label: 'Crawl failures',
        points: [
          TrendPoint(label: 'Taobao', value: 2),
          TrendPoint(label: 'JD', value: 3),
        ],
      ),
    ],
    recentAlerts: [
      AnalyticsRecentAlert(
        message: 'Taobao rice cooker dropped 12%',
        productTitle: 'Taobao rice cooker',
        alertType: 'price_drop',
      ),
    ],
  );
}
