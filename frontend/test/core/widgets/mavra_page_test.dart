import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/widgets/mavra_confirm.dart';
import 'package:mavra_frontend/core/widgets/mavra_page.dart';
import 'package:mavra_frontend/core/widgets/mavra_side_sheet.dart';

void main() {
  testWidgets('renders page title, subtitle, actions, status, and child', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MavraPageScaffold(
          title: 'Products',
          subtitle: 'Monitor prices and crawl status',
          status: const Text('Synced'),
          actions: const [
            FilledButton(onPressed: null, child: Text('Create')),
          ],
          child: const Text('Product table'),
        ),
      ),
    );

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Monitor prices and crawl status'), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Product table'), findsOneWidget);
  });

  testWidgets('renders loading, error, and empty states before child content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MavraPageScaffold(
          title: 'Activity',
          isLoading: true,
          error: 'Unable to load events',
          empty: Text('No events yet'),
          child: Text('Event table'),
        ),
      ),
    );

    expect(find.byKey(const Key('mavra-page-loading')), findsOneWidget);
    expect(find.text('Unable to load events'), findsOneWidget);
    expect(find.text('No events yet'), findsOneWidget);
    expect(find.text('Event table'), findsNothing);
  });

  testWidgets('mavraConfirm returns true only through the confirm button', (
    tester,
  ) async {
    var confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () async {
                confirmed = await mavraConfirm(
                  context,
                  title: 'Delete product',
                  message: 'This action is recorded only in tests.',
                  confirmKey: const Key('delete-product-confirm-button'),
                );
              },
              child: const Text('Open confirm'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open confirm'));
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);

    await tester.tap(find.byKey(const Key('delete-product-confirm-button')));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('side sheet uses a right panel on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () => MavraSideSheet.show<void>(
                context,
                title: 'Event details',
                child: const Text('Wide detail body'),
              ),
              child: const Text('Open sheet'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mavra-side-sheet-panel')), findsOneWidget);
    expect(find.text('Event details'), findsOneWidget);
    expect(find.text('Wide detail body'), findsOneWidget);
  });

  testWidgets('side sheet uses a mobile sheet on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () => MavraSideSheet.show<void>(
                context,
                title: 'Job details',
                child: const Text('Mobile detail body'),
              ),
              child: const Text('Open sheet'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mavra-side-sheet-mobile')), findsOneWidget);
    expect(find.text('Job details'), findsOneWidget);
    expect(find.text('Mobile detail body'), findsOneWidget);
  });
}
