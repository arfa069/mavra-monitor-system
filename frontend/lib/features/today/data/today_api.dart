import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../domain/today_models.dart';

const _partialWarning = "Today's briefing is not fully synced; will retry shortly.";

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

  generated.ProductsApi get _productsApi => _client.getProductsApi();

  generated.JobsApi get _jobsApi => _client.getJobsApi();

  generated.SmartHomeApi get _smartHomeApi => _client.getSmartHomeApi();

  @override
  Future<TodaySnapshot> loadToday() async {
    final kpiFlight = _capture(_dashboardApi.dashboardGetDashboardKpi());
    final productsFlight = _capture(
      _productsApi.productsListProducts(active: true, page: 1, size: 5),
    );
    final matchesFlight = _capture(
      _jobsApi.jobsListMatchResults(page: 1, pageSize: 5),
    );
    final homeFlight = _capture(_smartHomeApi.smartHomeGetSummary());

    final kpiResult = await kpiFlight;
    final productsResult = await productsFlight;
    final matchesResult = await matchesFlight;
    final homeResult = await homeFlight;

    final source = TodaySourceData(
      kpi: _mapKpi(kpiResult.value?.data?.user),
      products: [
        for (final product
            in productsResult.value?.data?.items.toList() ?? const [])
          TodayProductSignal(
            id: product.id,
            title: product.title,
            platform: product.platform,
          ),
      ],
      jobMatches: [
        for (final match
            in matchesResult.value?.data?.items.toList() ?? const [])
          TodayJobSignal(
            id: match.id,
            score: match.matchScore,
            title: match.jobTitle,
            company: match.jobCompany,
            location: match.jobLocation,
          ),
      ],
      home: _mapHome(homeResult.value?.data),
    );

    final hasPartialFailure =
        !kpiResult.ok ||
        !productsResult.ok ||
        !matchesResult.ok ||
        !homeResult.ok;

    return buildTodaySnapshot(
      source,
      warningMessage: hasPartialFailure ? _partialWarning : null,
    );
  }

  static TodayKpiSnapshot _mapKpi(generated.UserKPI? kpi) {
    if (kpi == null) {
      return const TodayKpiSnapshot.empty();
    }
    return TodayKpiSnapshot(
      totalProducts: kpi.totalProducts,
      priceDropsToday: kpi.priceDropsToday,
      newJobsToday: kpi.newJobsToday,
      matchCount: kpi.matchCount,
      crawlCountToday: kpi.crawlCountToday,
    );
  }

  static TodayHomeSignal _mapHome(generated.SmartHomeSummaryResponse? summary) {
    if (summary == null) {
      return const TodayHomeSignal.empty();
    }
    return TodayHomeSignal(
      configured: summary.configured,
      connected: summary.connected,
      unavailableCount: summary.unavailableCount,
      activeCount: summary.activeCount,
    );
  }

  static Future<_LoadResult<T>> _capture<T>(Future<T> future) async {
    try {
      return _LoadResult.value(await future);
    } catch (_) {
      return const _LoadResult.failure();
    }
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    final normalized = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    if (normalized.endsWith(apiPrefix)) {
      return normalized.substring(0, normalized.length - apiPrefix.length);
    }
    return normalized;
  }
}

class _LoadResult<T> {
  const _LoadResult.value(this.value) : ok = true;

  const _LoadResult.failure() : value = null, ok = false;

  final T? value;
  final bool ok;
}
