import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/features/alerts/domain/alert_models.dart';
import 'package:mavra_frontend/features/alerts/presentation/alerts_page.dart';

void main() {
  testWidgets('renders alerts and reloads when filter changes', (tester) async {
    final repository = _FakeAlertRepository(
      alertsByFilter: {
        AlertFilter.all: [
          _alert(id: 1, title: 'Taobao rice cooker', active: true),
        ],
        AlertFilter.inactive: [
          _alert(id: 2, title: 'Amazon desk lamp', active: false),
        ],
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: AlertsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Taobao rice cooker'), findsOneWidget);

    await tester.tap(find.text('Inactive'));
    await tester.pumpAndSettle();

    expect(repository.lastFilter, AlertFilter.inactive);
    expect(find.text('Amazon desk lamp'), findsOneWidget);
    expect(find.text('Taobao rice cooker'), findsNothing);
  });

  testWidgets('renders an empty alert state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AlertsPage(
          repository: _FakeAlertRepository(alertsByFilter: const {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No alerts configured'), findsOneWidget);
  });

  testWidgets('renders an alert error state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AlertsPage(repository: _FailingAlertRepository())),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alerts unavailable'), findsOneWidget);
  });

  testWidgets('applies realtime alert updates', (tester) async {
    final repository = _FakeAlertRepository(
      alertsByFilter: {
        AlertFilter.all: [
          _alert(id: 1, title: 'Taobao rice cooker', active: true),
        ],
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: AlertsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    repository.emit(_alert(id: 3, title: 'JD office chair', active: true));
    await tester.pumpAndSettle();

    expect(find.text('JD office chair'), findsOneWidget);
    expect(find.text('Taobao rice cooker'), findsOneWidget);
  });
}

class _FakeAlertRepository implements AlertRepository {
  _FakeAlertRepository({required this.alertsByFilter});

  final Map<AlertFilter, List<AlertItem>> alertsByFilter;
  final _controller = StreamController<AlertItem>.broadcast();
  AlertFilter lastFilter = AlertFilter.all;

  @override
  Future<List<AlertItem>> listAlerts({
    AlertFilter filter = AlertFilter.all,
  }) async {
    lastFilter = filter;
    return alertsByFilter[filter] ?? const [];
  }

  @override
  Stream<AlertItem> watchAlerts({AlertFilter filter = AlertFilter.all}) {
    return _controller.stream;
  }

  void emit(AlertItem item) => _controller.add(item);
}

class _FailingAlertRepository implements AlertRepository {
  @override
  Future<List<AlertItem>> listAlerts({AlertFilter filter = AlertFilter.all}) {
    throw StateError('alerts down');
  }

  @override
  Stream<AlertItem> watchAlerts({AlertFilter filter = AlertFilter.all}) {
    return const Stream.empty();
  }
}

AlertItem _alert({
  required int id,
  required String title,
  required bool active,
}) {
  return AlertItem(
    id: id,
    productId: 100 + id,
    productTitle: title,
    alertType: 'price_drop',
    thresholdLabel: '10%',
    active: active,
    updatedAt: DateTime.utc(2026, 6, 16, 8),
  );
}
