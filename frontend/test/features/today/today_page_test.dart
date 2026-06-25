import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mavra_frontend/core/theme/app_theme.dart';
import 'package:mavra_frontend/features/today/domain/today_models.dart';
import 'package:mavra_frontend/features/today/presentation/today_page.dart';

void main() {
  testWidgets('renders the React parity morning brief sections', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _attentionSnapshot()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Quiet score 64'), findsOneWidget);
    expect(find.text('Only 2 things today.'), findsOneWidget);
    expect(find.text('Everything else is running quietly. Focus on the most notable changes.'), findsOneWidget);
    expect(find.text('Worth a Look'), findsOneWidget);
    expect(find.text('米家电饭煲 reached target price'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Status Today'), findsOneWidget);
    expect(find.text('Price Monitor'), findsNWidgets(2));
    expect(find.text('Needs attention'), findsOneWidget);
  });

  testWidgets('does not render the old nested Today navigation scaffold', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _quietSnapshot()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Events'), findsNothing);
    expect(find.text('Alerts'), findsNothing);
    expect(find.text('Analytics'), findsNothing);
  });

  testWidgets('uses mobile and desktop rhythm layouts at the breakpoint', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _quietSnapshot()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today-mobile-rhythm')), findsOneWidget);
    expect(find.byKey(const Key('today-desktop-rhythm')), findsNothing);

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _quietSnapshot()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today-desktop-rhythm')), findsOneWidget);
    expect(find.byKey(const Key('today-mobile-rhythm')), findsNothing);
  });

  testWidgets('renders quiet empty attention state', (tester) async {
    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _quietSnapshot()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('All quiet today. Mavra is keeping watch.'), 400);
    await tester.scrollUntilVisible(find.text('Nothing requires your immediate attention.'), 400);

    expect(find.text('All quiet today. Mavra is keeping watch.'), findsOneWidget);
    expect(find.text('Nothing requires your immediate attention.'), findsOneWidget);
    await tester.drag(find.byType(Scrollable), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Running quietly'), findsWidgets);
  });

  testWidgets('summary uses adapted flat card chrome', (tester) async {
    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _quietSnapshot()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('today-summary-card')),
      400,
    );

    final summary = tester.widget<DecoratedBox>(
      find.byKey(const Key('today-summary-card')),
    );
    final decoration = summary.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(16));
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('renders the MiniMax-style showcase hero and product matrix', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _attentionSnapshot()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today-showcase-hero')), findsOneWidget);
    expect(find.byKey(const Key('today-product-matrix')), findsOneWidget);
    expect(find.text('Mavra Monitor System'), findsOneWidget);
    expect(find.text('Price Monitor'), findsNWidgets(2));
    expect(find.text('Job Radar'), findsNWidgets(2));
    expect(find.text('Smart Home'), findsNWidgets(2));
  });

  testWidgets('uses a light hero surface on the default light theme', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _attentionSnapshot()),
      ),
    );

    await tester.pumpAndSettle();

    final hero = tester.widget<DecoratedBox>(
      find.byKey(const Key('today-showcase-hero')),
    );
    final decoration = hero.decoration as BoxDecoration;

    expect(decoration.color, AppTheme.surface);
    expect(decoration.border, isNotNull);
  });

  testWidgets('shows loading copy while the brief is being prepared', (
    tester,
  ) async {
    final completer = Completer<TodaySnapshot>();

    await tester.pumpWidget(
      _buildTodayHarness(repository: _PendingTodayRepository(completer.future)),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Gathering today's rhythm..."), findsOneWidget);

    completer.complete(_quietSnapshot());
  });

  testWidgets('falls back to quiet brief with a warning when loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTodayHarness(repository: const _ThrowingTodayRepository()),
    );

    await tester.pumpAndSettle();
    expect(find.text("Today's briefing is not fully synced; will retry shortly."), findsOneWidget);

    await tester.scrollUntilVisible(find.text('All quiet today. Mavra is keeping watch.'), 400);

    expect(find.text('All quiet today. Mavra is keeping watch.'), findsOneWidget);
  });

  testWidgets('navigates when an attention action is tapped', (tester) async {
    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _attentionSnapshot()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('View'), 400);
    await tester.ensureVisible(find.text('View'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(find.text('Products page'), findsOneWidget);
  });
}

Widget _buildTodayHarness({required TodayRepository repository}) {
  final router = GoRouter(
    initialLocation: '/today',
    routes: [
      GoRoute(
        path: '/today',
        builder: (context, state) => TodayPage(repository: repository),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) =>
            const Scaffold(body: Text('Products page')),
      ),
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const Scaffold(body: Text('Jobs page')),
      ),
      GoRoute(
        path: '/smart-home',
        builder: (context, state) => const Scaffold(body: Text('Home page')),
      ),
    ],
  );

  return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
}

TodaySnapshot _attentionSnapshot() {
  return const TodaySnapshot(
    headline: 'Only 2 things today.',
    subhead: 'Everything else is running quietly. Focus on the most notable changes.',
    quietScore: 64,
    attentionItems: [
      TodayAttentionItem(
        id: 'price-drop',
        kind: TodayAttentionKind.price,
        timeLabel: 'Today',
        title: '米家电饭煲 reached target price',
        description: 'Price is below your alert threshold. A good time to decide on buying.',
        metric: '-2',
        actionLabel: 'View',
        route: '/products',
      ),
      TodayAttentionItem(
        id: 'job-match',
        kind: TodayAttentionKind.job,
        timeLabel: 'Later',
        title: 'Flutter 工程师 worth opening later',
        description: 'Mavra Labs · 上海',
        metric: '92',
        actionLabel: 'Save',
        route: '/jobs',
      ),
    ],
    moduleStatuses: [
      TodayModuleStatus(
        label: 'Price Monitor',
        state: TodayStatusState.attention,
        summary: '2 items dropped to target prices.',
        route: '/products',
      ),
      TodayModuleStatus(
        label: 'Job Radar',
        state: TodayStatusState.quiet,
        summary: 'No new high-match jobs today.',
        route: '/jobs',
      ),
      TodayModuleStatus(
        label: 'Smart Home',
        state: TodayStatusState.quiet,
        summary: 'Smart Home devices are running quietly.',
        route: '/smart-home',
      ),
    ],
  );
}

TodaySnapshot _quietSnapshot() {
  return TodaySnapshot.quiet();
}

class _FakeTodayRepository implements TodayRepository {
  const _FakeTodayRepository({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Future<TodaySnapshot> loadToday() async => snapshot;
}

class _PendingTodayRepository implements TodayRepository {
  const _PendingTodayRepository(this.future);

  final Future<TodaySnapshot> future;

  @override
  Future<TodaySnapshot> loadToday() => future;
}

class _ThrowingTodayRepository implements TodayRepository {
  const _ThrowingTodayRepository();

  @override
  Future<TodaySnapshot> loadToday() async {
    throw StateError('offline');
  }
}
