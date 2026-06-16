import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_scaffold.dart';
import '../domain/today_models.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key, required this.repository});

  final TodayRepository repository;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late Future<TodaySnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.repository.loadToday();
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
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              context.go('/events');
            case 2:
              context.go('/alerts');
            case 3:
              context.go('/analytics');
          }
        },
        body: FutureBuilder<TodaySnapshot>(
          future: _snapshot,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _TodayError(
                onRetry: () {
                  setState(() {
                    _snapshot = widget.repository.loadToday();
                  });
                },
              );
            }
            return _TodayContent(
              snapshot: snapshot.data ?? TodaySnapshot.quiet(),
            );
          },
        ),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = constraints.maxWidth >= 900
            ? _DesktopToday(snapshot: snapshot)
            : _MobileToday(snapshot: snapshot);
        return SafeArea(child: content);
      },
    );
  }
}

class _MobileToday extends StatelessWidget {
  const _MobileToday({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('today-mobile-feed'),
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryPanel(summary: snapshot.summary),
        const SizedBox(height: 12),
        _AttentionPanel(items: snapshot.attentionQueue),
        const SizedBox(height: 12),
        _ModulePanel(modules: snapshot.modules),
      ],
    );
  }
}

class _DesktopToday extends StatelessWidget {
  const _DesktopToday({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        key: const Key('today-desktop-grid'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _SummaryPanel(summary: snapshot.summary),
                const SizedBox(height: 16),
                _ModulePanel(modules: snapshot.modules),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: _AttentionPanel(items: snapshot.attentionQueue),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(summary.subtitle),
          const SizedBox(height: 10),
          Text(summary.quietState),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metric in summary.metrics)
                _MetricChip(label: metric.label, value: metric.value),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({required this.items});

  final List<AttentionItem> items;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attention queue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('No attention needed')
          else
            for (final item in items) _AttentionTile(item: item),
        ],
      ),
    );
  }
}

class _ModulePanel extends StatelessWidget {
  const _ModulePanel({required this.modules});

  final List<ModuleStatus> modules;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Module status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final module in modules) _ModuleTile(module: module),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      avatar: const Icon(Icons.insights, size: 18),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.item});

  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.severity) {
      AttentionSeverity.info => Theme.of(context).colorScheme.primary,
      AttentionSeverity.warning => Colors.amber.shade800,
      AttentionSeverity.critical => Theme.of(context).colorScheme.error,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.flag, color: color),
      title: Text(item.title),
      subtitle: Text(item.detail),
      trailing: item.route == null ? null : const Icon(Icons.chevron_right),
      onTap: item.route == null ? null : () => context.go(item.route!),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module});

  final ModuleStatus module;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        module.healthy ? Icons.check_circle_outline : Icons.error_outline,
        color: module.healthy
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
      title: Text(module.name),
      subtitle: Text('${module.status} - ${module.detail}'),
    );
  }
}

class _TodayError extends StatelessWidget {
  const _TodayError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40),
          const SizedBox(height: 12),
          const Text('Today could not load'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
