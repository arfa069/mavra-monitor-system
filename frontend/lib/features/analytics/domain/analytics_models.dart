class AnalyticsKpi {
  const AnalyticsKpi({required this.label, required this.value});

  final String label;
  final String value;
}

class TrendPoint {
  const TrendPoint({required this.label, required this.value});

  final String label;
  final num value;
}

class TrendSeries {
  const TrendSeries({required this.label, required this.points});

  final String label;
  final List<TrendPoint> points;
}

class AnalyticsRecentAlert {
  const AnalyticsRecentAlert({
    required this.message,
    required this.productTitle,
    required this.alertType,
  });

  final String message;
  final String productTitle;
  final String alertType;
}

class AnalyticsOverview {
  const AnalyticsOverview({
    required this.kpis,
    required this.trends,
    required this.recentAlerts,
  });

  factory AnalyticsOverview.empty() {
    return const AnalyticsOverview(kpis: [], trends: [], recentAlerts: []);
  }

  final List<AnalyticsKpi> kpis;
  final List<TrendSeries> trends;
  final List<AnalyticsRecentAlert> recentAlerts;
}

abstract class AnalyticsRepository {
  Future<AnalyticsOverview> loadOverview();

  Stream<AnalyticsOverview> watchOverview();
}
