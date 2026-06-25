enum TodayAttentionKind { price, job, home }

enum TodayStatusState { quiet, attention, inactive }

class TodayKpiSnapshot {
  const TodayKpiSnapshot({
    required this.totalProducts,
    required this.priceDropsToday,
    required this.newJobsToday,
    required this.matchCount,
    required this.crawlCountToday,
  });

  const TodayKpiSnapshot.empty()
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

class TodayProductSignal {
  const TodayProductSignal({
    required this.id,
    required this.title,
    required this.platform,
  });

  final int id;
  final String? title;
  final String platform;
}

class TodayJobSignal {
  const TodayJobSignal({
    required this.id,
    required this.score,
    required this.title,
    required this.company,
    required this.location,
  });

  final int id;
  final int score;
  final String? title;
  final String? company;
  final String? location;
}

class TodayHomeSignal {
  const TodayHomeSignal({
    required this.configured,
    required this.connected,
    required this.unavailableCount,
    required this.activeCount,
  });

  const TodayHomeSignal.empty()
    : configured = false,
      connected = false,
      unavailableCount = 0,
      activeCount = 0;

  final bool configured;
  final bool connected;
  final int unavailableCount;
  final int activeCount;
}

class TodaySourceData {
  const TodaySourceData({
    required this.kpi,
    required this.products,
    required this.jobMatches,
    required this.home,
  });

  final TodayKpiSnapshot kpi;
  final List<TodayProductSignal> products;
  final List<TodayJobSignal> jobMatches;
  final TodayHomeSignal home;
}

class TodayAttentionItem {
  const TodayAttentionItem({
    required this.id,
    required this.kind,
    required this.timeLabel,
    required this.title,
    required this.description,
    required this.metric,
    required this.actionLabel,
    required this.route,
  });

  final String id;
  final TodayAttentionKind kind;
  final String timeLabel;
  final String title;
  final String description;
  final String metric;
  final String actionLabel;
  final String route;
}

class TodayModuleStatus {
  const TodayModuleStatus({
    required this.label,
    required this.state,
    required this.summary,
    required this.route,
  });

  final String label;
  final TodayStatusState state;
  final String summary;
  final String route;
}

class TodaySnapshot {
  const TodaySnapshot({
    required this.headline,
    required this.subhead,
    required this.quietScore,
    required this.attentionItems,
    required this.moduleStatuses,
    this.warningMessage,
  });

  factory TodaySnapshot.quiet({String? warningMessage}) {
    return TodaySnapshot(
      headline: 'All quiet today. Mavra is keeping watch.',
      subhead: 'Prices, jobs, and home devices have no changes requiring immediate action.',
      quietScore: 92,
      attentionItems: const [],
      moduleStatuses: const [
        TodayModuleStatus(
          label: 'Price Monitor',
          state: TodayStatusState.quiet,
          summary: 'Prices have not reached your target yet.',
          route: '/products',
        ),
        TodayModuleStatus(
          label: 'Job Radar',
          state: TodayStatusState.quiet,
          summary: 'No new high-match jobs today.',
          route: '/jobs',
        ),
        TodayModuleStatus(
          label: 'Smart Home',
          state: TodayStatusState.quiet,
          summary: 'Smart Home devices are running quietly.',
          route: '/smart-home',
        ),
      ],
      warningMessage: warningMessage,
    );
  }

  final String headline;
  final String subhead;
  final int quietScore;
  final List<TodayAttentionItem> attentionItems;
  final List<TodayModuleStatus> moduleStatuses;
  final String? warningMessage;
}

abstract class TodayRepository {
  Future<TodaySnapshot> loadToday();
}

TodaySnapshot buildTodaySnapshot(
  TodaySourceData source, {
  String? warningMessage,
}) {
  final attentionItems = _buildAttentionItems(source);
  final count = attentionItems.length;

  return TodaySnapshot(
    headline: count == 0 ? 'All quiet today. Mavra is keeping watch.' : 'Only $count things today.',
    subhead: count == 0
        ? 'Prices, jobs, and home devices have no changes requiring immediate action.'
        : 'Everything else is running quietly. Focus on the most notable changes.',
    quietScore: _quietScore(source),
    attentionItems: attentionItems,
    moduleStatuses: [
      _buildPriceStatus(source),
      _buildJobStatus(source),
      _buildHomeStatus(source),
    ],
    warningMessage: warningMessage,
  );
}

TodayModuleStatus _buildPriceStatus(TodaySourceData source) {
  if (source.kpi.priceDropsToday > 0) {
    return TodayModuleStatus(
      label: 'Price Monitor',
      state: TodayStatusState.attention,
      summary: '${source.kpi.priceDropsToday} items dropped to target prices.',
      route: '/products',
    );
  }
  return TodayModuleStatus(
    label: 'Price Monitor',
    state: source.kpi.totalProducts > 0
        ? TodayStatusState.quiet
        : TodayStatusState.inactive,
    summary: source.kpi.totalProducts > 0 ? 'Prices have not reached your target yet.' : 'No monitored products added yet.',
    route: '/products',
  );
}

TodayModuleStatus _buildJobStatus(TodaySourceData source) {
  if (source.kpi.matchCount > 0 || source.kpi.newJobsToday > 0) {
    return TodayModuleStatus(
      label: 'Job Radar',
      state: TodayStatusState.attention,
      summary:
          '${_maxInt(source.kpi.matchCount, source.kpi.newJobsToday)} jobs worth looking at.',
      route: '/jobs',
    );
  }
  return const TodayModuleStatus(
    label: 'Job Radar',
    state: TodayStatusState.quiet,
    summary: 'No new high-match jobs today.',
    route: '/jobs',
  );
}

TodayModuleStatus _buildHomeStatus(TodaySourceData source) {
  if (!source.home.configured) {
    return const TodayModuleStatus(
      label: 'Smart Home',
      state: TodayStatusState.inactive,
      summary: 'Home Assistant is not connected yet.',
      route: '/smart-home',
    );
  }
  if (!source.home.connected || source.home.unavailableCount > 0) {
    return TodayModuleStatus(
      label: 'Smart Home',
      state: TodayStatusState.attention,
      summary: '${source.home.unavailableCount} devices require attention.',
      route: '/smart-home',
    );
  }
  return const TodayModuleStatus(
    label: 'Smart Home',
    state: TodayStatusState.quiet,
    summary: 'Smart Home devices are running quietly.',
    route: '/smart-home',
  );
}

List<TodayAttentionItem> _buildAttentionItems(TodaySourceData source) {
  final items = <TodayAttentionItem>[];

  if (source.kpi.priceDropsToday > 0) {
    items.add(
      TodayAttentionItem(
        id: 'price-drop',
        kind: TodayAttentionKind.price,
        timeLabel: 'Today',
        title: '${_firstProductName(source.products)} reached target price',
        description: 'Price is below your alert threshold. A good time to decide on buying.',
        metric: '-${source.kpi.priceDropsToday}',
        actionLabel: 'View',
        route: '/products',
      ),
    );
  }

  if (source.kpi.matchCount > 0 || source.jobMatches.isNotEmpty) {
    final topMatch = source.jobMatches.isEmpty ? null : source.jobMatches.first;
    items.add(
      TodayAttentionItem(
        id: 'job-match',
        kind: TodayAttentionKind.job,
        timeLabel: 'Later',
        title: '${_firstJobName(source.jobMatches)} worth opening later',
        description: topMatch == null
            ? 'Salary, location, or match score are close to your target.'
            : _jobDescription(topMatch),
        metric: topMatch == null
            ? '${source.kpi.matchCount}'
            : '${topMatch.score.round()}',
        actionLabel: 'Save',
        route: '/jobs',
      ),
    );
  }

  if (source.home.configured &&
      (!source.home.connected || source.home.unavailableCount > 0)) {
    items.add(
      TodayAttentionItem(
        id: 'home-attention',
        kind: TodayAttentionKind.home,
        timeLabel: 'Morning',
        title: 'Home connection needs attention',
        description: 'Home Assistant is not fully online. Please check connection and device statuses.',
        metric: '${source.home.unavailableCount}',
        actionLabel: 'View Home',
        route: '/smart-home',
      ),
    );
  }

  return items.take(5).toList();
}

int _quietScore(TodaySourceData source) {
  var score = 92;
  score -= _minInt(source.kpi.priceDropsToday * 8, 24);
  score -= _minInt(source.kpi.matchCount * 6, 18);
  score -= source.home.connected ? 0 : 18;
  score -= _minInt(source.home.unavailableCount * 5, 20);
  return score.clamp(0, 100).toInt();
}

String _firstProductName(List<TodayProductSignal> products) {
  return products.isEmpty ? 'A monitored product' : products.first.title ?? 'A monitored product';
}

String _firstJobName(List<TodayJobSignal> matches) {
  return matches.isEmpty ? 'A job' : matches.first.title ?? 'A job';
}

String _jobDescription(TodayJobSignal match) {
  final company = match.company;
  if (company == null || company.isEmpty) {
    return 'Salary, location, or match score are close to your target.';
  }
  final location = match.location;
  if (location == null || location.isEmpty) {
    return company;
  }
  return '$company · $location';
}

int _minInt(int a, int b) => a < b ? a : b;

int _maxInt(int a, int b) => a > b ? a : b;
