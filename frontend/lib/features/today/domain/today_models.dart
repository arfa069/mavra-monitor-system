enum AttentionSeverity { info, warning, critical }

class TodayMetric {
  const TodayMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class TodaySummary {
  const TodaySummary({
    required this.title,
    required this.subtitle,
    required this.quietState,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final String quietState;
  final List<TodayMetric> metrics;
}

class AttentionItem {
  const AttentionItem({
    required this.title,
    required this.detail,
    required this.severity,
    this.route,
  });

  final String title;
  final String detail;
  final AttentionSeverity severity;
  final String? route;
}

class ModuleStatus {
  const ModuleStatus({
    required this.name,
    required this.status,
    required this.detail,
    required this.healthy,
  });

  final String name;
  final String status;
  final String detail;
  final bool healthy;
}

class TodaySnapshot {
  const TodaySnapshot({
    required this.summary,
    required this.attentionQueue,
    required this.modules,
  });

  factory TodaySnapshot.quiet() {
    return const TodaySnapshot(
      summary: TodaySummary(
        title: 'Today',
        subtitle: 'All clear for now',
        quietState: 'Mavra is watching quietly.',
        metrics: [
          TodayMetric(label: 'Price drops', value: '0'),
          TodayMetric(label: 'New jobs', value: '0'),
          TodayMetric(label: 'Crawls', value: '0'),
        ],
      ),
      attentionQueue: [],
      modules: [
        ModuleStatus(
          name: 'Products',
          status: 'Quiet',
          detail: 'No active price changes',
          healthy: true,
        ),
        ModuleStatus(
          name: 'Jobs',
          status: 'Quiet',
          detail: 'No new matches need review',
          healthy: true,
        ),
      ],
    );
  }

  final TodaySummary summary;
  final List<AttentionItem> attentionQueue;
  final List<ModuleStatus> modules;
}

abstract class TodayRepository {
  Future<TodaySnapshot> loadToday();
}
