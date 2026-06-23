enum AnalyticsTrendType {
  platformProducts,
  price,
  priceChange,
  platformJobs,
  jobs,
  jobMatches,
  platformSuccess,
  crawlFailures,
}

enum AnalyticsChartKind { line, bar, pie }

class DashboardUserKpi {
  const DashboardUserKpi({
    required this.totalProducts,
    required this.priceDropsToday,
    required this.newJobsToday,
    required this.matchCount,
    required this.crawlCountToday,
  });

  const DashboardUserKpi.empty()
    : totalProducts = 0,
      priceDropsToday = 0,
      newJobsToday = 0,
      matchCount = 0,
      crawlCountToday = 0;

  final int totalProducts;
  final int priceDropsToday;
  final int newJobsToday;
  final int matchCount;
  final int crawlCountToday;
}

class DashboardSystemKpi {
  const DashboardSystemKpi({
    required this.totalUsers,
    required this.totalCrawls,
    required this.successRate,
    required this.activeAlerts,
    required this.diskUsage,
    required this.memoryUsage,
  });

  final int totalUsers;
  final int totalCrawls;
  final num successRate;
  final int activeAlerts;
  final num diskUsage;
  final num memoryUsage;
}

class AnalyticsKpiSnapshot {
  const AnalyticsKpiSnapshot({required this.user, this.system});

  final DashboardUserKpi user;
  final DashboardSystemKpi? system;
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

class AnalyticsTrendSection {
  const AnalyticsTrendSection({
    required this.type,
    required this.title,
    required this.chartKind,
    required this.series,
  });

  final AnalyticsTrendType type;
  final String title;
  final AnalyticsChartKind chartKind;
  final List<TrendSeries> series;
}

class AnalyticsRecentAlert {
  const AnalyticsRecentAlert({
    required this.id,
    required this.message,
    required this.alertType,
    required this.active,
    this.productTitle,
    this.createdAt,
    this.platform,
  });

  final int id;
  final String message;
  final String alertType;
  final bool active;
  final String? productTitle;
  final DateTime? createdAt;
  final String? platform;
}

class AnalyticsOverview {
  const AnalyticsOverview({
    required this.userKpi,
    required this.userTrends,
    this.systemKpi,
    this.systemTrends = const [],
    this.recentAlerts = const [],
  });

  factory AnalyticsOverview.empty() {
    return const AnalyticsOverview(
      userKpi: DashboardUserKpi.empty(),
      userTrends: [],
    );
  }

  AnalyticsOverview copyWithKpi(AnalyticsKpiSnapshot snapshot) {
    return AnalyticsOverview(
      userKpi: snapshot.user,
      systemKpi: snapshot.system ?? systemKpi,
      userTrends: userTrends,
      systemTrends: systemTrends,
      recentAlerts: recentAlerts,
    );
  }

  final DashboardUserKpi userKpi;
  final DashboardSystemKpi? systemKpi;
  final List<AnalyticsTrendSection> userTrends;
  final List<AnalyticsTrendSection> systemTrends;
  final List<AnalyticsRecentAlert> recentAlerts;
}

abstract class AnalyticsRepository {
  Future<AnalyticsOverview> loadOverview({
    int days = 30,
    bool includeAdmin = false,
  });

  Stream<AnalyticsKpiSnapshot> watchKpiUpdates();
}
