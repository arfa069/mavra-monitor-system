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
      headline: '今天很安静，Mavra 会继续帮你看着。',
      subhead: '价格、职位和家里设备都没有需要你立刻处理的变化。',
      quietScore: 92,
      attentionItems: const [],
      moduleStatuses: const [
        TodayModuleStatus(
          label: '价格看守',
          state: TodayStatusState.quiet,
          summary: '价格还没有到你设的目标。',
          route: '/products',
        ),
        TodayModuleStatus(
          label: '职位雷达',
          state: TodayStatusState.quiet,
          summary: '今天没有新的高匹配职位。',
          route: '/jobs',
        ),
        TodayModuleStatus(
          label: '家里设备',
          state: TodayStatusState.quiet,
          summary: '家里设备都在安静运行。',
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
    headline: count == 0 ? '今天很安静，Mavra 会继续帮你看着。' : '今天只提醒 $count 件事。',
    subhead: count == 0
        ? '价格、职位和家里设备都没有需要你立刻处理的变化。'
        : '其他事情都在安静运行，你可以先看最值得注意的变化。',
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
      label: '价格看守',
      state: TodayStatusState.attention,
      summary: '${source.kpi.priceDropsToday} 个商品到了值得看的价位。',
      route: '/products',
    );
  }
  return TodayModuleStatus(
    label: '价格看守',
    state: source.kpi.totalProducts > 0
        ? TodayStatusState.quiet
        : TodayStatusState.inactive,
    summary: source.kpi.totalProducts > 0 ? '价格还没有到你设的目标。' : '还没有添加关注商品。',
    route: '/products',
  );
}

TodayModuleStatus _buildJobStatus(TodaySourceData source) {
  if (source.kpi.matchCount > 0 || source.kpi.newJobsToday > 0) {
    return TodayModuleStatus(
      label: '职位雷达',
      state: TodayStatusState.attention,
      summary:
          '${_maxInt(source.kpi.matchCount, source.kpi.newJobsToday)} 个职位值得看看。',
      route: '/jobs',
    );
  }
  return const TodayModuleStatus(
    label: '职位雷达',
    state: TodayStatusState.quiet,
    summary: '今天没有新的高匹配职位。',
    route: '/jobs',
  );
}

TodayModuleStatus _buildHomeStatus(TodaySourceData source) {
  if (!source.home.configured) {
    return const TodayModuleStatus(
      label: '家里设备',
      state: TodayStatusState.inactive,
      summary: '还没有连接 Home Assistant。',
      route: '/smart-home',
    );
  }
  if (!source.home.connected || source.home.unavailableCount > 0) {
    return TodayModuleStatus(
      label: '家里设备',
      state: TodayStatusState.attention,
      summary: '${source.home.unavailableCount} 个设备需要看一下。',
      route: '/smart-home',
    );
  }
  return const TodayModuleStatus(
    label: '家里设备',
    state: TodayStatusState.quiet,
    summary: '家里设备都在安静运行。',
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
        timeLabel: '今天',
        title: '${_firstProductName(source.products)} 到了心理价位',
        description: '价格低于你设定的提醒条件，适合今天决定要不要买。',
        metric: '-${source.kpi.priceDropsToday}',
        actionLabel: '查看',
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
        timeLabel: '稍后',
        title: '${_firstJobName(source.jobMatches)} 值得晚点打开',
        description: topMatch == null
            ? '薪资、地点或匹配度接近你的设定。'
            : _jobDescription(topMatch),
        metric: topMatch == null
            ? '${source.kpi.matchCount}'
            : '${topMatch.score.round()}',
        actionLabel: '收藏',
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
        timeLabel: '早晨',
        title: '家里连接需要看一下',
        description: 'Home Assistant 状态不是完全正常，建议确认连接和设备状态。',
        metric: '${source.home.unavailableCount}',
        actionLabel: '看家里',
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
  return products.isEmpty ? '一个关注商品' : products.first.title ?? '一个关注商品';
}

String _firstJobName(List<TodayJobSignal> matches) {
  return matches.isEmpty ? '一个职位' : matches.first.title ?? '一个职位';
}

String _jobDescription(TodayJobSignal match) {
  final company = match.company;
  if (company == null || company.isEmpty) {
    return '薪资、地点或匹配度接近你的设定。';
  }
  final location = match.location;
  if (location == null || location.isEmpty) {
    return company;
  }
  return '$company · $location';
}

int _minInt(int a, int b) => a < b ? a : b;

int _maxInt(int a, int b) => a > b ? a : b;
