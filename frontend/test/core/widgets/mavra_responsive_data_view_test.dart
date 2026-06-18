import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';

void main() {
  testWidgets('uses a data table on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Wide table row'), findsOneWidget);
    expect(find.text('Mobile list row'), findsNothing);
  });

  testWidgets('uses mobile rows on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Mobile list row'), findsOneWidget);
  });

  testWidgets('renders the configured empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MavraResponsiveDataView<int>(
          rows: const [],
          columns: const [
            DataColumn(label: Text('Name')),
          ],
          tableCells: (row) => const [
            DataCell(Text('Wide table row')),
          ],
          mobileBuilder: (context, row) => const ListTile(
            title: Text('Mobile list row'),
          ),
          empty: const Text('Nothing to review'),
        ),
      ),
    );

    expect(find.text('Nothing to review'), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
  });
}
