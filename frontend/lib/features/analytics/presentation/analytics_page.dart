import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_scaffold.dart';
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
  const _AnalyticsContent({required this.overview});

  final AnalyticsOverview overview;

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
        Text('Trends', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (overview.trends.isEmpty)
          const Text('No chart data yet')
        else
          for (final trend in overview.trends) _TrendPanel(series: trend),
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
      ],
    );
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

class _TrendPanel extends StatelessWidget {
  const _TrendPanel({required this.series});

  final TrendSeries series;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(series.label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final point in series.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(width: 96, child: Text(point.label)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: point.value <= 0
                            ? 0
                            : (point.value / 100).clamp(0, 1).toDouble(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${point.value}'),
                  ],
                ),
              ),
          ],
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
