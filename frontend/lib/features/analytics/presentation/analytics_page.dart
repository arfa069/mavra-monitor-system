import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_chart.dart';
import '../domain/analytics_models.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, required this.repository});

  final AnalyticsRepository repository;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Future<AnalyticsOverview>? _overviewFuture;
  AnalyticsOverview? _overview;
  Object? _error;
  StreamSubscription<AnalyticsOverview>? _subscription;
  int _days = 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _load() {
    _error = null;
    _overviewFuture = Future.sync(widget.repository.loadOverview)
      ..then((overview) {
        if (mounted) {
          setState(() {
            _overview = overview;
          });
        }
      }).catchError((Object error) {
        if (mounted) {
          setState(() {
            _error = error;
          });
        }
      });
    _subscription?.cancel();
    _subscription = widget.repository.watchOverview().listen((overview) {
      if (mounted) {
        setState(() {
          _overview = overview;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.today, label: 'Today'),
          AdaptiveDestination(icon: Icons.event_note, label: 'Events'),
          AdaptiveDestination(icon: Icons.notifications, label: 'Alerts'),
          AdaptiveDestination(icon: Icons.analytics, label: 'Analytics'),
        ],
        selectedIndex: 3,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 1:
              context.go('/events');
            case 2:
              context.go('/alerts');
          }
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<AnalyticsOverview>(
              future: _overviewFuture,
              builder: (context, snapshot) {
                if (_error != null) {
                  return const _AnalyticsError();
                }
                if (snapshot.connectionState != ConnectionState.done &&
                    _overview == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _AnalyticsContent(
                  overview: _overview ?? AnalyticsOverview.empty(),
                  selectedDays: _days,
                  onDaysChanged: (days) {
                    setState(() {
                      _days = days;
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.overview,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  final AnalyticsOverview overview;
  final int selectedDays;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Analytics', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final kpi in overview.kpis) _KpiCard(kpi: kpi)],
        ),
        const SizedBox(height: 20),
        Text('Recent alerts', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (overview.recentAlerts.isEmpty)
          const Text('No recent alerts')
        else
          for (final alert in overview.recentAlerts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications),
              title: Text(alert.message),
              subtitle: Text('${alert.productTitle} - ${alert.alertType}'),
            ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Trends',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7d')),
                ButtonSegment(value: 30, label: Text('30d')),
                ButtonSegment(value: 90, label: Text('90d')),
              ],
              selected: {selectedDays},
              onSelectionChanged: (selection) =>
                  onDaysChanged(selection.single),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (overview.trends.isEmpty)
          const Text('No chart data yet')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final charts = [
                for (final trend in overview.trends) _chartForTrend(trend),
              ];
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final chart in charts) ...[
                      chart,
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final chart in charts)
                    SizedBox(width: constraints.maxWidth / 2 - 12, child: chart),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _chartForTrend(TrendSeries series) {
    final points = [
      for (final point in series.points)
        MavraChartPoint(label: point.label, value: point.value.toDouble()),
    ];
    final label = series.label.toLowerCase();
    if (label.contains('platform success')) {
      return MavraPieChart(title: series.label, points: points);
    }
    if (label.contains('crawl failures')) {
      return MavraBarChart(title: series.label, points: points);
    }
    return MavraTrendChart(title: series.label, points: points);
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final AnalyticsKpi kpi;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kpi.label),
              const SizedBox(height: 8),
              Text(kpi.value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Analytics unavailable'));
  }
}
