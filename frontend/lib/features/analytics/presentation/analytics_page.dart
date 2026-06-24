import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/mavra_chart.dart';
import '../domain/analytics_models.dart';

const _realtimeWarning = '连接断开，正在重连...';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({
    super.key,
    required this.repository,
    this.canViewSystemAnalytics = false,
  });

  final AnalyticsRepository repository;
  final bool canViewSystemAnalytics;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Future<AnalyticsOverview>? _overviewFuture;
  AnalyticsOverview? _overview;
  Object? _error;
  StreamSubscription<AnalyticsKpiSnapshot>? _subscription;
  int _days = 30;
  bool _showRealtimeWarning = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnalyticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.canViewSystemAnalytics != widget.canViewSystemAnalytics) {
      _subscription?.cancel();
      _subscribe();
      _load();
    }
  }

  void _subscribe() {
    _subscription = widget.repository.watchKpiUpdates().listen(
      (snapshot) {
        if (mounted) {
          setState(() {
            _overview = (_overview ?? AnalyticsOverview.empty()).copyWithKpi(
              snapshot,
            );
            _showRealtimeWarning = false;
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _showRealtimeWarning = true;
          });
        }
      },
    );
  }

  void _load() {
    final future = Future<AnalyticsOverview>.sync(
      () => widget.repository.loadOverview(
        days: _days,
        includeAdmin: widget.canViewSystemAnalytics,
      ),
    );
    setState(() {
      _error = null;
      _overviewFuture = future
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<AnalyticsOverview>(
          future: _overviewFuture,
          builder: (context, snapshot) {
            if (_error != null) {
              return const _AnalyticsError();
            }
            if (snapshot.connectionState != ConnectionState.done &&
                _overview == null) {
              return const _AnalyticsLoading();
            }
            return _AnalyticsContent(
              overview: _overview ?? AnalyticsOverview.empty(),
              selectedDays: _days,
              showSystemAnalytics: widget.canViewSystemAnalytics,
              showRealtimeWarning: _showRealtimeWarning,
              onDaysChanged: (days) {
                if (days == _days) {
                  return;
                }
                _days = days;
                _load();
              },
            );
          },
        ),
      ),
    );
  }
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载数据分析...'),
        ],
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.overview,
    required this.selectedDays,
    required this.showSystemAnalytics,
    required this.showRealtimeWarning,
    required this.onDaysChanged,
  });

  final AnalyticsOverview overview;
  final int selectedDays;
  final bool showSystemAnalytics;
  final bool showRealtimeWarning;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final child = wide
            ? _DesktopDashboard(
                overview: overview,
                selectedDays: selectedDays,
                showSystemAnalytics: showSystemAnalytics,
                showRealtimeWarning: showRealtimeWarning,
                onDaysChanged: onDaysChanged,
              )
            : _MobileDashboard(
                overview: overview,
                selectedDays: selectedDays,
                showSystemAnalytics: showSystemAnalytics,
                showRealtimeWarning: showRealtimeWarning,
                onDaysChanged: onDaysChanged,
              );
        return child;
      },
    );
  }
}

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.overview,
    required this.selectedDays,
    required this.showSystemAnalytics,
    required this.showRealtimeWarning,
    required this.onDaysChanged,
  });

  final AnalyticsOverview overview;
  final int selectedDays;
  final bool showSystemAnalytics;
  final bool showRealtimeWarning;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('dashboard-desktop-layout'),
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _DashboardBanner(),
                const SizedBox(height: 16),
                _RangeToolbar(
                  selectedDays: selectedDays,
                  showRealtimeWarning: showRealtimeWarning,
                  onDaysChanged: onDaysChanged,
                ),
                const SizedBox(height: 16),
                _UserKpis(kpi: overview.userKpi),
                const SizedBox(height: 20),
                _TrendGrid(sections: overview.userTrends, columns: 3),
                if (showSystemAnalytics) ...[
                  const SizedBox(height: 28),
                  _SystemAnalytics(overview: overview, columns: 2),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.overview,
    required this.selectedDays,
    required this.showSystemAnalytics,
    required this.showRealtimeWarning,
    required this.onDaysChanged,
  });

  final AnalyticsOverview overview;
  final int selectedDays;
  final bool showSystemAnalytics;
  final bool showRealtimeWarning;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('dashboard-mobile-layout'),
      padding: const EdgeInsets.all(16),
      children: [
        const _DashboardBanner(),
        const SizedBox(height: 12),
        _RangeToolbar(
          selectedDays: selectedDays,
          showRealtimeWarning: showRealtimeWarning,
          onDaysChanged: onDaysChanged,
        ),
        const SizedBox(height: 16),
        _UserKpis(kpi: overview.userKpi),
        const SizedBox(height: 20),
        _TrendGrid(sections: overview.userTrends, columns: 1),
        if (showSystemAnalytics) ...[
          const SizedBox(height: 24),
          _SystemAnalytics(overview: overview, columns: 1),
        ],
      ],
    );
  }
}

class _DashboardBanner extends StatelessWidget {
  const _DashboardBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      key: const Key('dashboard-banner'),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.56),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: text.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '数据分析',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '监控系统运行状态、价格走势统计与候选人匹配度分析',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeToolbar extends StatelessWidget {
  const _RangeToolbar({
    required this.selectedDays,
    required this.showRealtimeWarning,
    required this.onDaysChanged,
  });

  final int selectedDays;
  final bool showRealtimeWarning;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      key: const Key('dashboard-range-toolbar'),
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7天')),
            ButtonSegment(value: 30, label: Text('30天')),
            ButtonSegment(value: 90, label: Text('90天')),
          ],
          selected: {selectedDays},
          onSelectionChanged: (selection) => onDaysChanged(selection.single),
        ),
        if (showRealtimeWarning)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                _realtimeWarning,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ),
      ],
    );
  }
}

class _UserKpis extends StatelessWidget {
  const _UserKpis({required this.kpi});

  final DashboardUserKpi kpi;

  @override
  Widget build(BuildContext context) {
    return _KpiWrap(
      cards: [
        _KpiData(label: '监控商品数', value: '${kpi.totalProducts}'),
        _KpiData(label: '今日降价', value: '${kpi.priceDropsToday}', alert: true),
        _KpiData(label: '新职位数', value: '${kpi.newJobsToday}'),
        _KpiData(label: '匹配分析', value: '${kpi.matchCount}'),
        _KpiData(label: '今日爬取', value: '${kpi.crawlCountToday}'),
      ],
    );
  }
}

class _SystemKpis extends StatelessWidget {
  const _SystemKpis({required this.kpi});

  final DashboardSystemKpi? kpi;

  @override
  Widget build(BuildContext context) {
    if (kpi == null) {
      return const _DashboardPanel(
        child: SizedBox(height: 76, child: Center(child: Text('暂无数据'))),
      );
    }
    return _KpiWrap(
      cards: [
        _KpiData(label: '总用户数', value: '${kpi!.totalUsers}'),
        _KpiData(label: '今日爬取', value: '${kpi!.totalCrawls}'),
        _KpiData(label: '成功率', value: _percent(kpi!.successRate)),
        _KpiData(label: '活跃告警', value: '${kpi!.activeAlerts}', alert: true),
        _KpiData(label: '磁盘使用', value: _percent(kpi!.diskUsage)),
        _KpiData(label: '内存使用', value: _percent(kpi!.memoryUsage)),
      ],
    );
  }
}

class _KpiWrap extends StatelessWidget {
  const _KpiWrap({required this.cards});

  final List<_KpiData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final width = wide ? 176.0 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: width.clamp(148, 220),
                child: _KpiCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: data.alert ? colors.tertiary : colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendGrid extends StatelessWidget {
  const _TrendGrid({required this.sections, required this.columns});

  final List<AnalyticsTrendSection> sections;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const _DashboardPanel(
        child: SizedBox(height: 180, child: Center(child: Text('暂无数据'))),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = columns == 1 ? 12.0 : 16.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final section in sections)
              SizedBox(
                width: width,
                child: _TrendSection(section: section),
              ),
          ],
        );
      },
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.section});

  final AnalyticsTrendSection section;

  @override
  Widget build(BuildContext context) {
    final points = _pointsFor(section);
    return _DashboardPanel(
      child: points.isEmpty
          ? SizedBox(
              height: 272,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Expanded(child: Center(child: Text('暂无数据'))),
                ],
              ),
            )
          : _chartFor(section, points),
    );
  }
}

class _SystemAnalytics extends StatelessWidget {
  const _SystemAnalytics({required this.overview, required this.columns});

  final AnalyticsOverview overview;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('系统运营', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _SystemKpis(kpi: overview.systemKpi),
        const SizedBox(height: 16),
        _TrendGrid(sections: overview.systemTrends, columns: columns),
        const SizedBox(height: 16),
        _RecentAlertsPanel(alerts: overview.recentAlerts),
      ],
    );
  }
}

class _RecentAlertsPanel extends StatelessWidget {
  const _RecentAlertsPanel({required this.alerts});

  final List<AnalyticsRecentAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最近告警', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('暂无告警')),
            )
          else
            for (var index = 0; index < alerts.length; index++) ...[
              _RecentAlertRow(alert: alerts[index]),
              if (index != alerts.length - 1) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _RecentAlertRow extends StatelessWidget {
  const _RecentAlertRow({required this.alert});

  final AnalyticsRecentAlert alert;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alert.active ? Icons.notifications_active : Icons.notifications,
            color: alert.active ? colors.tertiary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusPill(label: _alertTypeLabel(alert.alertType)),
                    if (alert.platform != null)
                      _StatusPill(label: alert.platform!),
                    if (alert.createdAt != null)
                      Text(
                        _formatDateTime(alert.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (alert.productTitle != null) ...[
                  Text(
                    alert.productTitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(alert.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
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

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    this.alert = false,
  });

  final String label;
  final String value;
  final bool alert;
}

Widget _chartFor(AnalyticsTrendSection section, List<MavraChartPoint> points) {
  return switch (section.chartKind) {
    AnalyticsChartKind.pie => MavraPieChart(
      title: section.title,
      points: points,
    ),
    AnalyticsChartKind.bar => MavraBarChart(
      title: section.title,
      points: points,
    ),
    AnalyticsChartKind.line => MavraTrendChart(
      title: section.title,
      points: points,
    ),
  };
}

List<MavraChartPoint> _pointsFor(AnalyticsTrendSection section) {
  return [
    for (final series in section.series)
      for (final point in series.points)
        MavraChartPoint(
          label: section.series.length > 1
              ? '${series.label} ${point.label}'
              : point.label,
          value: point.value.toDouble(),
        ),
  ];
}

String _percent(num ratio) {
  return '${(ratio * 100).toStringAsFixed(1)}%';
}

String _alertTypeLabel(String alertType) {
  return switch (alertType) {
    'price_drop' => '降价',
    _ => alertType,
  };
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
