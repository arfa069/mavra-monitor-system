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
      labels: const [],
      child: LineChart(
        LineChartData(
          minY: _minY(points),
          maxY: _maxY(points),
          gridData: const FlGridData(show: true),
          titlesData: _lineTitles(context, points),
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
      labels: const [],
      child: BarChart(
        BarChartData(
          maxY: _maxY(points),
          gridData: const FlGridData(show: true),
          titlesData: _barTitles(context, points),
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
      labelColors: [
        for (var index = 0; index < points.length; index++)
          colors[index % colors.length],
      ],
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
    this.labelColors = const [],
  });

  final String title;
  final List<String> labels;
  final List<Color> labelColors;
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
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ChartLegend(labels: labels, colors: labelColors),
        ],
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.labels, required this.colors});

  final List<String> labels;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (var index = 0; index < labels.length; index++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.isEmpty
                      ? Theme.of(context).colorScheme.primary
                      : colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(labels[index], style: textStyle),
            ],
          ),
      ],
    );
  }
}

FlTitlesData _lineTitles(BuildContext context, List<MavraChartPoint> points) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: _bottomTitles(context, points),
  );
}

FlTitlesData _barTitles(BuildContext context, List<MavraChartPoint> points) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: _bottomTitles(context, points),
  );
}

AxisTitles _bottomTitles(BuildContext context, List<MavraChartPoint> points) {
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: points.isNotEmpty,
      reservedSize: 30,
      interval: _axisInterval(),
      getTitlesWidget: (value, meta) {
        final index = value.round();
        if (index < 0 || index >= points.length) {
          return const SizedBox.shrink();
        }
        if (!_shouldShowAxisLabel(index, points.length)) {
          return const SizedBox.shrink();
        }
        return SideTitleWidget(
          meta: meta,
          child: Text(
            _compactAxisLabel(points[index].label),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    ),
  );
}

double _axisInterval() {
  return 1;
}

bool _shouldShowAxisLabel(int index, int count) {
  if (count <= 4) {
    return true;
  }
  final targets = <int>{0, (count - 1) ~/ 3, ((count - 1) * 2) ~/ 3, count - 1};
  return targets.contains(index);
}

String _compactAxisLabel(String label) {
  final date = DateTime.tryParse(label);
  if (date != null) {
    return '${date.month}/${date.day}';
  }
  if (label.length <= 10) {
    return label;
  }
  return '${label.substring(0, 9)}…';
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
