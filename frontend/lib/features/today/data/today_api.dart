import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../domain/today_models.dart';

class GeneratedTodayRepository implements TodayRepository {
  GeneratedTodayRepository({
    required AppConfig config,
    generated.MavraApi? client,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           );

  final generated.MavraApi _client;

  generated.DashboardApi get _dashboardApi => _client.getDashboardApi();

  @override
  Future<TodaySnapshot> loadToday() async {
    final response = await _dashboardApi.dashboardGetDashboardKpi();
    final kpi = response.data;
    if (kpi == null) {
      return TodaySnapshot.quiet();
    }

    final metrics = [
      TodayMetric(label: 'Price drops', value: '${kpi.user.priceDropsToday}'),
      TodayMetric(label: 'New jobs', value: '${kpi.user.newJobsToday}'),
      TodayMetric(label: 'Crawls', value: '${kpi.user.crawlCountToday}'),
      TodayMetric(label: 'Matches', value: '${kpi.user.matchCount}'),
    ];
    final attention = <AttentionItem>[
      if (kpi.user.priceDropsToday > 0)
        AttentionItem(
          title: '${kpi.user.priceDropsToday} price drops',
          detail: 'Review product alerts before they get stale.',
          severity: AttentionSeverity.info,
          route: '/products',
        ),
      if (kpi.user.newJobsToday > 0)
        AttentionItem(
          title: '${kpi.user.newJobsToday} new jobs',
          detail: 'Open the jobs queue when you have a focused moment.',
          severity: AttentionSeverity.info,
          route: '/jobs',
        ),
    ];
    final system = kpi.system;

    return TodaySnapshot(
      summary: TodaySummary(
        title: 'Today',
        subtitle: attention.isEmpty
            ? 'No attention needed'
            : '${attention.length} things need attention',
        quietState: attention.isEmpty
            ? 'Mavra is watching quietly.'
            : 'Mavra found signals worth checking.',
        metrics: metrics,
      ),
      attentionQueue: attention,
      modules: [
        ModuleStatus(
          name: 'Products',
          status: kpi.user.priceDropsToday > 0 ? 'Price movement' : 'Quiet',
          detail: '${kpi.user.totalProducts} products monitored',
          healthy: true,
        ),
        ModuleStatus(
          name: 'Jobs',
          status: kpi.user.newJobsToday > 0 ? 'New results' : 'Quiet',
          detail: '${kpi.user.matchCount} matches available',
          healthy: true,
        ),
        if (system != null)
          ModuleStatus(
            name: 'System',
            status: '${system.successRate}% success',
            detail: '${system.activeAlerts} active alerts',
            healthy: system.successRate >= 80,
          ),
      ],
    );
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
