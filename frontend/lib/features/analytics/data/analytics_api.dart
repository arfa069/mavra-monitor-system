import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../../../core/realtime/realtime_client.dart';
import '../domain/analytics_models.dart';

class GeneratedAnalyticsRepository implements AnalyticsRepository {
  GeneratedAnalyticsRepository({
    required AppConfig config,
    generated.MavraApi? client,
    RealtimeClient? realtimeClient,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           ),
       _realtimeClient =
           realtimeClient ?? PollingRealtimeClient(poll: () async => const []);

  final generated.MavraApi _client;
  final RealtimeClient _realtimeClient;

  generated.DashboardApi get _dashboardApi => _client.getDashboardApi();

  @override
  Future<AnalyticsOverview> loadOverview({
    int days = 30,
    bool includeAdmin = false,
  }) async {
    final kpi = (await _dashboardApi.dashboardGetDashboardKpi()).data;
    if (kpi == null) {
      throw StateError('Dashboard KPI response was empty');
    }

    final userTrends = await Future.wait([
      for (final spec in _userTrendSpecs) _loadTrend(spec, days),
    ]);
    final systemTrends = includeAdmin
        ? await Future.wait([
            for (final spec in _systemTrendSpecs) _loadTrend(spec, days),
          ])
        : <AnalyticsTrendSection>[];
    final recentAlerts = includeAdmin
        ? await _loadRecentAlerts()
        : const <AnalyticsRecentAlert>[];

    return AnalyticsOverview(
      userKpi: _userKpiFromGenerated(kpi.user),
      systemKpi: includeAdmin ? _systemKpiFromGenerated(kpi.system) : null,
      userTrends: userTrends,
      systemTrends: systemTrends,
      recentAlerts: recentAlerts,
    );
  }

  @override
  Stream<AnalyticsKpiSnapshot> watchKpiUpdates() {
    return _realtimeClient
        .connect('dashboard')
        .map(_kpiFromRealtime)
        .where((snapshot) => snapshot != null)
        .cast<AnalyticsKpiSnapshot>();
  }

  Future<AnalyticsTrendSection> _loadTrend(_TrendSpec spec, int days) async {
    try {
      final response = await _dashboardApi.dashboardGetTrendData(
        type: spec.apiType,
        days: days,
      );
      return spec.toSection(_seriesFromTrend(response.data));
    } catch (_) {
      return spec.toSection(const []);
    }
  }

  Future<List<AnalyticsRecentAlert>> _loadRecentAlerts() async {
    try {
      final response = await _dashboardApi.dashboardGetRecentAlerts(limit: 10);
      return [
        for (final alert in response.data ?? <generated.RecentAlert>[])
          AnalyticsRecentAlert(
            id: alert.id,
            message: alert.message,
            productTitle: alert.productTitle,
            alertType: alert.alertType,
            active: alert.active,
            createdAt: _parseDate(alert.createdAt),
            platform: alert.platform,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  List<TrendSeries> _seriesFromTrend(generated.TrendResponse? trend) {
    if (trend == null) {
      return const [];
    }
    return [
      for (final dataset in trend.datasets)
        TrendSeries(
          label: dataset.label,
          points: [
            for (final point in dataset.data)
              TrendPoint(label: point.label, value: point.value),
          ],
        ),
    ];
  }

  AnalyticsKpiSnapshot? _kpiFromRealtime(RealtimeMessage message) {
    final payload = message.payload;
    final event = payload['event']?.toString() ?? message.type;
    if (event != 'kpi_update') {
      return null;
    }

    final userPayload = _asMap(payload['data']) ?? _asMap(payload['user']);
    if (userPayload == null) {
      return null;
    }

    return AnalyticsKpiSnapshot(
      user: _userKpiFromMap(userPayload),
      system: _systemKpiFromMap(_asMap(payload['system'])),
    );
  }

  DashboardUserKpi _userKpiFromGenerated(generated.UserKPI kpi) {
    return DashboardUserKpi(
      totalProducts: kpi.totalProducts,
      priceDropsToday: kpi.priceDropsToday,
      newJobsToday: kpi.newJobsToday,
      matchCount: kpi.matchCount,
      crawlCountToday: kpi.crawlCountToday,
    );
  }

  DashboardSystemKpi? _systemKpiFromGenerated(generated.SystemKPI? kpi) {
    if (kpi == null) {
      return null;
    }
    return DashboardSystemKpi(
      totalUsers: kpi.totalUsers,
      totalCrawls: kpi.totalCrawls,
      successRate: kpi.successRate,
      activeAlerts: kpi.activeAlerts,
      diskUsage: kpi.diskUsage,
      memoryUsage: kpi.memoryUsage,
    );
  }

  DashboardUserKpi _userKpiFromMap(Map<Object?, Object?> map) {
    return DashboardUserKpi(
      totalProducts: _intValue(map, 'total_products'),
      priceDropsToday: _intValue(map, 'price_drops_today'),
      newJobsToday: _intValue(map, 'new_jobs_today'),
      matchCount: _intValue(map, 'match_count'),
      crawlCountToday: _intValue(map, 'crawl_count_today'),
    );
  }

  DashboardSystemKpi? _systemKpiFromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return null;
    }
    return DashboardSystemKpi(
      totalUsers: _intValue(map, 'total_users'),
      totalCrawls: _intValue(map, 'total_crawls'),
      successRate: _numValue(map, 'success_rate'),
      activeAlerts: _intValue(map, 'active_alerts'),
      diskUsage: _numValue(map, 'disk_usage'),
      memoryUsage: _numValue(map, 'memory_usage'),
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

const _userTrendSpecs = [
  _TrendSpec(
    type: AnalyticsTrendType.platformProducts,
    apiType: 'platform_products',
    title: 'Product Distribution by Platform',
    chartKind: AnalyticsChartKind.pie,
  ),
  _TrendSpec(
    type: AnalyticsTrendType.price,
    apiType: 'price',
    title: 'Price Trends',
    chartKind: AnalyticsChartKind.line,
  ),
  _TrendSpec(
    type: AnalyticsTrendType.priceChange,
    apiType: 'price_change',
    title: 'Price Change Rate Trends',
    chartKind: AnalyticsChartKind.line,
  ),
  _TrendSpec(
    type: AnalyticsTrendType.platformJobs,
    apiType: 'platform_jobs',
    title: 'Job Distribution by Platform',
    chartKind: AnalyticsChartKind.pie,
  ),
  _TrendSpec(
    type: AnalyticsTrendType.jobs,
    apiType: 'jobs',
    title: 'New Job Trends',
    chartKind: AnalyticsChartKind.line,
  ),
  _TrendSpec(
    type: AnalyticsTrendType.jobMatches,
    apiType: 'job_matches',
    title: 'Job Match Trends',
    chartKind: AnalyticsChartKind.line,
  ),
];

const _systemTrendSpecs = [
  _TrendSpec(
    type: AnalyticsTrendType.platformSuccess,
    apiType: 'platform_success',
    title: 'Platform Success Rate Comparison',
    chartKind: AnalyticsChartKind.bar,
  ),
  _TrendSpec(
    type: AnalyticsTrendType.crawlFailures,
    apiType: 'crawl_failures',
    title: 'Crawl Failure Trends',
    chartKind: AnalyticsChartKind.bar,
  ),
];

class _TrendSpec {
  const _TrendSpec({
    required this.type,
    required this.apiType,
    required this.title,
    required this.chartKind,
  });

  final AnalyticsTrendType type;
  final String apiType;
  final String title;
  final AnalyticsChartKind chartKind;

  AnalyticsTrendSection toSection(List<TrendSeries> series) {
    return AnalyticsTrendSection(
      type: type,
      title: title,
      chartKind: chartKind,
      series: series,
    );
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

Map<Object?, Object?>? _asMap(Object? value) {
  if (value is Map) {
    return value;
  }
  return null;
}

int _intValue(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _numValue(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is num) {
    return value;
  }
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
