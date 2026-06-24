import 'package:flutter/material.dart';

typedef MavraTableCells<T> = List<DataCell> Function(T row);
typedef MavraMobileRowBuilder<T> = Widget Function(BuildContext context, T row);

class MavraResponsiveDataView<T> extends StatelessWidget {
  const MavraResponsiveDataView({
    super.key,
    required this.rows,
    required this.columns,
    required this.tableCells,
    required this.mobileBuilder,
    this.wideBreakpoint = 760,
    this.columnSpacing,
    this.empty,
  });

  final List<T> rows;
  final List<DataColumn> columns;
  final MavraTableCells<T> tableCells;
  final MavraMobileRowBuilder<T> mobileBuilder;
  final double wideBreakpoint;
  final double? columnSpacing;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return empty ?? const Center(child: Text('No records'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= wideBreakpoint) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: columnSpacing,
                columns: columns,
                rows: [for (final row in rows) DataRow(cells: tableCells(row))],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => Material(
            type: MaterialType.transparency,
            child: mobileBuilder(context, rows[index]),
          ),
        );
      },
    );
  }
}
