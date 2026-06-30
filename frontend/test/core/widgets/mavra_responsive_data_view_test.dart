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

  testWidgets('wide data table fills the available panel width', (tester) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 800,
            child: MavraResponsiveDataView<int>(
              rows: const [1],
              columns: const [
                DataColumn(label: Text('Name')),
              ],
              tableCells: (row) => const [
                DataCell(Text('Short')),
              ],
              mobileBuilder: (context, row) => const ListTile(
                title: Text('Mobile list row'),
              ),
            ),
          ),
        ),
      ),
    );

    final tableWidth = tester.getSize(find.byType(DataTable)).width;
    expect(tableWidth, greaterThanOrEqualTo(800));
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

  testWidgets('keeps mobile row state with configured row keys', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget buildRows(List<int> rows) {
      return MaterialApp(
        home: MavraResponsiveDataView<int>(
          rows: rows,
          rowKey: (row) => ValueKey('row-$row'),
          columns: const [
            DataColumn(label: Text('Name')),
          ],
          tableCells: (row) => [
            DataCell(Text('Wide row $row')),
          ],
          mobileBuilder: (context, row) => _StatefulMobileRow(label: '$row'),
        ),
      );
    }

    await tester.pumpWidget(buildRows(const [1, 2]));

    await tester.tap(find.text('row 2: 0'));
    await tester.pump();
    expect(find.text('row 2: 1'), findsOneWidget);

    await tester.pumpWidget(buildRows(const [2, 1]));
    await tester.pump();

    expect(find.text('row 1: 1'), findsNothing);
    expect(find.text('row 2: 1'), findsOneWidget);
    expect(find.text('row 1: 0'), findsOneWidget);
  });
}

class _StatefulMobileRow extends StatefulWidget {
  const _StatefulMobileRow({required this.label});

  final String label;

  @override
  State<_StatefulMobileRow> createState() => _StatefulMobileRowState();
}

class _StatefulMobileRowState extends State<_StatefulMobileRow> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('row ${widget.label}: $_count'),
      onTap: () => setState(() => _count += 1),
    );
  }
}
