import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

    expect(find.text('今天'), findsWidgets);
    expect(find.text('Quiet score 64'), findsOneWidget);
    expect(find.text('今天只提醒 2 件事。'), findsOneWidget);
    expect(find.text('其他事情都在安静运行，你可以先看最值得注意的变化。'), findsOneWidget);
    expect(find.text('值得看'), findsOneWidget);
    expect(find.text('米家电饭煲 到了心理价位'), findsOneWidget);
    expect(find.text('查看'), findsOneWidget);
    expect(find.text('今天的状态'), findsOneWidget);
    expect(find.text('价格看守'), findsOneWidget);
    expect(find.text('需要看看'), findsOneWidget);
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

    expect(find.text('今天很安静，Mavra 会继续帮你看着。'), findsOneWidget);
    expect(find.text('没有需要你立刻处理的事。'), findsOneWidget);
    expect(find.text('安静运行'), findsWidgets);
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
    expect(find.text('正在整理今天的节奏...'), findsOneWidget);

    completer.complete(_quietSnapshot());
  });

  testWidgets('falls back to quiet brief with a warning when loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTodayHarness(repository: const _ThrowingTodayRepository()),
    );

    await tester.pumpAndSettle();

    expect(find.text('今天的简报没有完全同步，稍后会再试。'), findsOneWidget);
    expect(find.text('今天很安静，Mavra 会继续帮你看着。'), findsOneWidget);
  });

  testWidgets('navigates when an attention action is tapped', (tester) async {
    await tester.pumpWidget(
      _buildTodayHarness(
        repository: _FakeTodayRepository(snapshot: _attentionSnapshot()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('查看'));
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

  return MaterialApp.router(routerConfig: router);
}

TodaySnapshot _attentionSnapshot() {
  return const TodaySnapshot(
    headline: '今天只提醒 2 件事。',
    subhead: '其他事情都在安静运行，你可以先看最值得注意的变化。',
    quietScore: 64,
    attentionItems: [
      TodayAttentionItem(
        id: 'price-drop',
        kind: TodayAttentionKind.price,
        timeLabel: '今天',
        title: '米家电饭煲 到了心理价位',
        description: '价格低于你设定的提醒条件，适合今天决定要不要买。',
        metric: '-2',
        actionLabel: '查看',
        route: '/products',
      ),
      TodayAttentionItem(
        id: 'job-match',
        kind: TodayAttentionKind.job,
        timeLabel: '稍后',
        title: 'Flutter 工程师 值得晚点打开',
        description: 'Mavra Labs · 上海',
        metric: '92',
        actionLabel: '收藏',
        route: '/jobs',
      ),
    ],
    moduleStatuses: [
      TodayModuleStatus(
        label: '价格看守',
        state: TodayStatusState.attention,
        summary: '2 个商品到了值得看的价位。',
        route: '/products',
      ),
      TodayModuleStatus(
        label: '职位雷达',
        state: TodayStatusState.quiet,
        summary: '今天没有新的高匹配职位。',
        route: '/jobs',
      ),
      TodayModuleStatus(
        label: '家里设备',
        state: TodayStatusState.quiet,
        summary: '家里设备都在安静运行。',
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
