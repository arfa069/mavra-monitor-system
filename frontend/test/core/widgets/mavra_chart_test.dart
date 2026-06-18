import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/widgets/mavra_chart.dart';

void main() {
  const points = [
    MavraChartPoint(label: 'Taobao', value: 12),
    MavraChartPoint(label: 'JD', value: 8),
    MavraChartPoint(label: 'Amazon', value: 4),
  ];

  testWidgets('trend chart renders a real line chart with labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MavraTrendChart(
            title: 'Price trend',
            points: points,
          ),
        ),
      ),
    );

    expect(find.text('Price trend'), findsOneWidget);
    expect(find.text('Taobao'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('bar chart renders a real bar chart with labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MavraBarChart(
            title: 'Crawl failures',
            points: points,
          ),
        ),
      ),
    );

    expect(find.text('Crawl failures'), findsOneWidget);
    expect(find.text('JD'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('pie chart renders a real pie chart with labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MavraPieChart(
            title: 'Platform success',
            points: points,
          ),
        ),
      ),
    );

    expect(find.text('Platform success'), findsOneWidget);
    expect(find.text('Amazon'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
  });
}
