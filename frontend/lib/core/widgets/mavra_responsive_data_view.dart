import 'package:flutter/material.dart';

typedef MavraTableCells<T> = List<DataCell> Function(T row);
typedef MavraMobileRowBuilder<T> = Widget Function(BuildContext context, T row);
typedef MavraRowKey<T> = Key Function(T row);

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
    this.rowKey,
  });

  final List<T> rows;
  final List<DataColumn> columns;
  final MavraTableCells<T> tableCells;
  final MavraMobileRowBuilder<T> mobileBuilder;
  final double wideBreakpoint;
  final double? columnSpacing;
  final Widget? empty;
  final MavraRowKey<T>? rowKey;

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

        final rowIndexesByKey = {
          if (rowKey != null)
            for (var index = 0; index < rows.length; index++)
              rowKey!(rows[index]): index * 2,
        };

        return ListView.custom(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childrenDelegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) {
                return const Divider(height: 1);
              }
              final rowIndex = index ~/ 2;
              return Material(
                key: rowKey?.call(rows[rowIndex]),
                type: MaterialType.transparency,
                child: mobileBuilder(context, rows[rowIndex]),
              );
            },
            childCount: rows.length * 2 - 1,
            findChildIndexCallback: rowKey == null
                ? null
                : (key) => rowIndexesByKey[key],
          ),
        );
      },
    );
  }
}
