import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MavraChartPoint {
  const MavraChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class MavraTrendChart extends StatelessWidget {
  const MavraTrendChart({super.key, required this.title, required this.points});

  final String title;
  final List<MavraChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final chartPoints = _normalizedPoints(points);
    final color = Theme.of(context).colorScheme.primary;

    return _MavraChartFrame(
      title: title,
      labels: [for (final point in points) point.label],
      child: LineChart(
        LineChartData(
          minY: _minY(points),
          maxY: _maxY(points),
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: chartPoints,
              isCurved: true,
              color: color,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MavraBarChart extends StatelessWidget {
  const MavraBarChart({super.key, required this.title, required this.points});

  final String title;
  final List<MavraChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;

    return _MavraChartFrame(
      title: title,
      labels: [for (final point in points) point.label],
      child: BarChart(
        BarChartData(
          maxY: _maxY(points),
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var index = 0; index < points.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: points[index].value,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                    color: color,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class MavraPieChart extends StatelessWidget {
  const MavraPieChart({super.key, required this.title, required this.points});

  final String title;
  final List<MavraChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
    ];

    return _MavraChartFrame(
      title: title,
      labels: [for (final point in points) point.label],
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 34,
          sectionsSpace: 2,
          sections: [
            for (var index = 0; index < points.length; index++)
              PieChartSectionData(
                value: points[index].value,
                title: '',
                radius: 58,
                color: colors[index % colors.length],
              ),
          ],
        ),
      ),
    );
  }
}

class _MavraChartFrame extends StatelessWidget {
  const _MavraChartFrame({
    required this.title,
    required this.labels,
    required this.child,
  });

  final String title;
  final List<String> labels;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: child),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final label in labels)
              Chip(visualDensity: VisualDensity.compact, label: Text(label)),
          ],
        ),
      ],
    );
  }
}

List<FlSpot> _normalizedPoints(List<MavraChartPoint> points) {
  if (points.isEmpty) {
    return const [FlSpot(0, 0)];
  }

  return [
    for (var index = 0; index < points.length; index++)
      FlSpot(index.toDouble(), points[index].value),
  ];
}

double _maxY(List<MavraChartPoint> points) {
  if (points.isEmpty) {
    return 1;
  }

  final maxValue = points.map((point) => point.value).reduce(math.max);
  return math.max(1, maxValue * 1.2);
}

double _minY(List<MavraChartPoint> points) {
  if (points.isEmpty) {
    return 0;
  }

  final minValue = points.map((point) => point.value).reduce(math.min);
  return minValue < 0 ? minValue * 1.2 : 0;
}
