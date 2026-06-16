import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/features/today/domain/today_models.dart';
import 'package:mavra_frontend/features/today/presentation/today_page.dart';

void main() {
  testWidgets('renders summary, attention queue, quiet state, and modules', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          repository: _FakeTodayRepository(
            snapshot: TodaySnapshot(
              summary: const TodaySummary(
                title: 'Good morning',
                subtitle: '3 things need attention',
                quietState: 'Price monitors are quiet',
                metrics: [
                  TodayMetric(label: 'Price drops', value: '2'),
                  TodayMetric(label: 'New jobs', value: '4'),
                ],
              ),
              attentionQueue: [
                AttentionItem(
                  title: 'Boss profile needs login',
                  detail: 'Session expired 12 minutes ago',
                  severity: AttentionSeverity.warning,
                  route: '/jobs',
                ),
              ],
              modules: [
                ModuleStatus(
                  name: 'Products',
                  status: 'Monitoring',
                  detail: '18 active items',
                  healthy: true,
                ),
                ModuleStatus(
                  name: 'Jobs',
                  status: 'Needs login',
                  detail: '1 profile blocked',
                  healthy: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('3 things need attention'), findsOneWidget);
    expect(find.text('Price monitors are quiet'), findsOneWidget);
    expect(find.text('Boss profile needs login'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
  });

  testWidgets('renders a quiet empty attention state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          repository: _FakeTodayRepository(snapshot: TodaySnapshot.quiet()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No attention needed'), findsOneWidget);
    expect(find.text('Mavra is watching quietly.'), findsOneWidget);
  });

  testWidgets('uses a mobile single feed below the desktop breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          repository: _FakeTodayRepository(snapshot: TodaySnapshot.quiet()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today-mobile-feed')), findsOneWidget);
    expect(find.byKey(const Key('today-desktop-grid')), findsNothing);
  });

  testWidgets('uses multi-column layout on desktop width', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          repository: _FakeTodayRepository(snapshot: TodaySnapshot.quiet()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today-desktop-grid')), findsOneWidget);
    expect(find.byKey(const Key('today-mobile-feed')), findsNothing);
  });
}

class _FakeTodayRepository implements TodayRepository {
  const _FakeTodayRepository({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Future<TodaySnapshot> loadToday() async => snapshot;
}
