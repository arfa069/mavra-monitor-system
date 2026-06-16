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
  Future<AnalyticsOverview> loadOverview() async {
    final results = await Future.wait([
      _dashboardApi.dashboardGetDashboardKpi(),
      _dashboardApi.dashboardGetTrendData(type: 'price_change'),
      _dashboardApi.dashboardGetRecentAlerts(),
    ]);
    final kpi = results[0].data as generated.DashboardKPIResponse?;
    final trends = results[1].data as generated.TrendResponse?;
    final alerts = results[2].data as Iterable<generated.RecentAlert>?;

    return AnalyticsOverview(
      kpis: kpi == null
          ? const []
          : [
              AnalyticsKpi(
                label: 'Price drops',
                value: '${kpi.user.priceDropsToday}',
              ),
              AnalyticsKpi(
                label: 'New jobs',
                value: '${kpi.user.newJobsToday}',
              ),
              AnalyticsKpi(
                label: 'Crawls',
                value: '${kpi.user.crawlCountToday}',
              ),
              AnalyticsKpi(label: 'Matches', value: '${kpi.user.matchCount}'),
            ],
      trends: [
        for (final series in trends?.datasets ?? <generated.TrendDataset>[])
          TrendSeries(
            label: series.label,
            points: [
              for (final point in series.data)
                TrendPoint(label: point.label, value: point.value),
            ],
          ),
      ],
      recentAlerts: [
        for (final alert in alerts ?? <generated.RecentAlert>[])
          AnalyticsRecentAlert(
            message: alert.message,
            productTitle: alert.productTitle ?? 'Product #${alert.productId}',
            alertType: alert.alertType,
          ),
      ],
    );
  }

  @override
  Stream<AnalyticsOverview> watchOverview() {
    return _realtimeClient.connect('dashboard').map(_overviewFromRealtime);
  }

  AnalyticsOverview _overviewFromRealtime(RealtimeMessage message) {
    final payload = message.payload;
    return AnalyticsOverview(
      kpis: _mapKpis(payload['kpis']),
      trends: _mapTrends(payload['trends']),
      recentAlerts: _mapRecentAlerts(payload['recent_alerts']),
    );
  }

  List<AnalyticsKpi> _mapKpis(Object? value) {
    if (value is! Iterable) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is Map)
          AnalyticsKpi(
            label: item['label']?.toString() ?? 'Metric',
            value: item['value']?.toString() ?? '-',
          ),
    ];
  }

  List<TrendSeries> _mapTrends(Object? value) {
    if (value is! Iterable) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is Map)
          TrendSeries(
            label: item['label']?.toString() ?? 'Trend',
            points: _mapTrendPoints(item['points']),
          ),
    ];
  }

  List<TrendPoint> _mapTrendPoints(Object? value) {
    if (value is! Iterable) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is Map)
          TrendPoint(
            label: item['label']?.toString() ?? '',
            value: num.tryParse(item['value']?.toString() ?? '') ?? 0,
          ),
    ];
  }

  List<AnalyticsRecentAlert> _mapRecentAlerts(Object? value) {
    if (value is! Iterable) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is Map)
          AnalyticsRecentAlert(
            message: item['message']?.toString() ?? 'Alert update',
            productTitle: item['product_title']?.toString() ?? 'Product',
            alertType: item['alert_type']?.toString() ?? 'price_drop',
          ),
    ];
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
