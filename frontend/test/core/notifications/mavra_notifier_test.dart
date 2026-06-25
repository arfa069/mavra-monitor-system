import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/notifications/mavra_notifier.dart';

void main() {
  testWidgets('shows success messages through the global scaffold messenger', (
    tester,
  ) async {
    await _pumpNotifierHost(tester);

    MavraNotifier.success('Saved');
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('keeps only the latest message visible', (tester) async {
    await _pumpNotifierHost(tester);

    MavraNotifier.info('First message');
    await tester.pump();
    MavraNotifier.warning('Second message');
    await tester.pump();

    expect(find.text('First message'), findsNothing);
    expect(find.text('Second message'), findsOneWidget);
    expect(find.byIcon(Icons.warning), findsOneWidget);
  });

  testWidgets('shows error messages with the error icon', (tester) async {
    await _pumpNotifierHost(tester);

    MavraNotifier.error('Failed');
    await tester.pump();

    expect(find.text('Failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('clear removes the current message', (tester) async {
    await _pumpNotifierHost(tester);

    MavraNotifier.info('Dismiss me');
    await tester.pump();
    MavraNotifier.clear();
    await tester.pumpAndSettle();

    expect(find.text('Dismiss me'), findsNothing);
  });
}

Future<void> _pumpNotifierHost(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      scaffoldMessengerKey: MavraNotifier.scaffoldMessengerKey,
      home: const Scaffold(body: Text('Home')),
    ),
  );
}
