import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/today_models.dart';

const _loadWarning = "Today's briefing is not fully synced; will retry shortly.";

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
      body: SafeArea(
        child: FutureBuilder<TodaySnapshot>(
          future: _snapshot,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _TodayLoading();
            }
            final brief = snapshot.hasError
                ? TodaySnapshot.quiet(warningMessage: _loadWarning)
                : snapshot.data ?? TodaySnapshot.quiet();
            return _TodayContent(snapshot: brief);
          },
        ),
      ),
    );
  }
}

class _TodayLoading extends StatelessWidget {
  const _TodayLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Gathering today's rhythm..."),
        ],
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
        final wide = constraints.maxWidth >= 900;
        final content = wide
            ? _DesktopToday(snapshot: snapshot)
            : _MobileToday(snapshot: snapshot);
        return content;
      },
    );
  }
}

class _DesktopToday extends StatelessWidget {
  const _DesktopToday({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
      padding: const EdgeInsets.all(32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              key: const Key('today-desktop-rhythm'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (snapshot.warningMessage != null) ...[
                  _WarningBanner(message: snapshot.warningMessage!),
                  const SizedBox(height: 16),
                ],
                _TodayShowcaseHero(snapshot: snapshot),
                const SizedBox(height: 24),
                _TodayProductMatrix(statuses: snapshot.moduleStatuses),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DailySummary(snapshot: snapshot),
                          const SizedBox(height: 16),
                          _AttentionQueue(items: snapshot.attentionItems),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 360,
                      child: _QuietStatusPanel(
                        statuses: snapshot.moduleStatuses,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileToday extends StatelessWidget {
  const _MobileToday({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('today-mobile-rhythm'),
      scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
      padding: const EdgeInsets.all(16),
      children: [
        if (snapshot.warningMessage != null) ...[
          _WarningBanner(message: snapshot.warningMessage!),
          const SizedBox(height: 12),
        ],
        _TodayShowcaseHero(snapshot: snapshot),
        const SizedBox(height: 16),
        _TodayProductMatrix(statuses: snapshot.moduleStatuses),
        const SizedBox(height: 16),
        _DailySummary(snapshot: snapshot),
        const SizedBox(height: 16),
        _AttentionQueue(items: snapshot.attentionItems),
        const SizedBox(height: 16),
        _QuietStatusPanel(statuses: snapshot.moduleStatuses),
      ],
    );
  }
}

class _TodayShowcaseHero extends StatelessWidget {
  const _TodayShowcaseHero({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return DecoratedBox(
      key: const Key('today-showcase-hero'),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.hairlineSoft),
      ),
      child: Padding(
        padding: EdgeInsets.all(wide ? 40 : 24),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _TodayHeroCopy(snapshot: snapshot)),
                  const SizedBox(width: 32),
                  const _TodayHeroIdentityCard(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TodayHeroCopy(snapshot: snapshot),
                  const SizedBox(height: 24),
                  const _TodayHeroIdentityCard(),
                ],
              ),
      ),
    );
  }
}

class _TodayHeroCopy extends StatelessWidget {
  const _TodayHeroCopy({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MISSION CONTROL',
          style: text.labelLarge?.copyWith(
            color: AppTheme.brandCoral,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Mavra Monitor System',
          style: (wide ? text.displayLarge : text.displaySmall)?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w600,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'A sharper morning console for the changes worth opening first.',
            style: text.bodyLarge?.copyWith(
              color: AppTheme.steel,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
              ),
              onPressed: () => context.go('/products'),
              child: const Text('View Prices'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
              onPressed: () => context.go('/jobs'),
              child: const Text('Open Jobs'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayHeroIdentityCard extends StatelessWidget {
  const _TodayHeroIdentityCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.brandCoral,
              AppTheme.brandMagenta,
              AppTheme.brandBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MAVRA',
                style: text.labelLarge?.copyWith(
                  color: AppTheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 72),
              Text(
                'Price · Jobs · Home',
                style: text.titleLarge?.copyWith(
                  color: AppTheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daily signals in one bold surface.',
                style: text.bodySmall?.copyWith(
                  color: AppTheme.onPrimary.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayProductMatrix extends StatelessWidget {
  const _TodayProductMatrix({required this.statuses});

  final List<TodayModuleStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ShowcaseCardData(
        title: 'Price Monitor',
        summary: _summaryFor('Price Monitor', statuses),
        route: '/products',
        color: AppTheme.brandCoral,
        icon: Icons.trending_down_rounded,
      ),
      _ShowcaseCardData(
        title: 'Job Radar',
        summary: _summaryFor('Job Radar', statuses),
        route: '/jobs',
        color: AppTheme.brandPurple,
        icon: Icons.work_rounded,
      ),
      _ShowcaseCardData(
        title: 'Smart Home',
        summary: _summaryFor('Smart Home', statuses),
        route: '/smart-home',
        color: AppTheme.brandBlue,
        icon: Icons.home_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Wrap(
          key: const Key('today-product-matrix'),
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards)
              SizedBox(
                width: wide
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth,
                child: _ProductShowcaseCard(card: card),
              ),
          ],
        );
      },
    );
  }

  static String _summaryFor(String label, List<TodayModuleStatus> statuses) {
    for (final status in statuses) {
      if (status.label == label) {
        return status.summary;
      }
    }
    return 'Ready for the next signal.';
  }
}

class _ShowcaseCardData {
  const _ShowcaseCardData({
    required this.title,
    required this.summary,
    required this.route,
    required this.color,
    required this.icon,
  });

  final String title;
  final String summary;
  final String route;
  final Color color;
  final IconData icon;
}

class _ProductShowcaseCard extends StatelessWidget {
  const _ProductShowcaseCard({required this.card});

  final _ShowcaseCardData card;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: () => context.go(card.route),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: card.color,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(card.icon, color: AppTheme.onPrimary, size: 30),
              const SizedBox(height: 42),
              Text(
                card.title,
                style: text.titleLarge?.copyWith(
                  color: AppTheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                card.summary,
                style: text.bodySmall?.copyWith(
                  color: AppTheme.onPrimary.withValues(alpha: 0.78),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      key: const Key('today-summary-card'),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _QuietScoreChip(score: snapshot.quietScore),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              snapshot.headline,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.08,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              snapshot.subhead,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietScoreChip extends StatelessWidget {
  const _QuietScoreChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerHighest
            : AppTheme.successBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          'Quiet score $score',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isDark ? colors.onSurface : AppTheme.successText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AttentionQueue extends StatelessWidget {
  const _AttentionQueue({required this.items});

  final List<TodayAttentionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _TodayCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Nothing requires your immediate attention.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Worth a Look', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < items.length; index++) ...[
          _AttentionTile(item: items[index]),
          if (index != items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.item});

  final TodayAttentionItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        return _TodayCard(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 76, child: _AttentionTime(item: item)),
                    const SizedBox(width: 16),
                    Expanded(child: _AttentionCopy(item: item)),
                    const SizedBox(width: 16),
                    _AttentionAction(item: item),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AttentionTime(item: item),
                    const SizedBox(height: 8),
                    _AttentionCopy(item: item),
                    const SizedBox(height: 12),
                    _AttentionAction(item: item),
                  ],
                ),
        );
      },
    );
  }
}

class _AttentionTime extends StatelessWidget {
  const _AttentionTime({required this.item});

  final TodayAttentionItem item;

  @override
  Widget build(BuildContext context) {
    return Text(
      item.timeLabel,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _AttentionCopy extends StatelessWidget {
  const _AttentionCopy({required this.item});

  final TodayAttentionItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          item.description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AttentionAction extends StatelessWidget {
  const _AttentionAction({required this.item});

  final TodayAttentionItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.metric,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.tertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          onPressed: () => context.go(item.route),
          child: Text(item.actionLabel),
        ),
      ],
    );
  }
}

class _QuietStatusPanel extends StatelessWidget {
  const _QuietStatusPanel({required this.statuses});

  final List<TodayModuleStatus> statuses;

  @override
  Widget build(BuildContext context) {
    return _TodayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Today', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (var index = 0; index < statuses.length; index++) ...[
            _StatusRow(status: statuses[index]),
            if (index != statuses.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});

  final TodayModuleStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(status.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.summary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _statusText(status.state),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _statusColor(context, status.state),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

String _statusText(TodayStatusState status) {
  return switch (status) {
    TodayStatusState.attention => 'Needs attention',
    TodayStatusState.inactive => 'Inactive',
    TodayStatusState.quiet => 'Running quietly',
  };
}

Color _statusColor(BuildContext context, TodayStatusState status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    TodayStatusState.attention => colors.tertiary,
    TodayStatusState.inactive => colors.onSurfaceVariant,
    TodayStatusState.quiet => colors.primary,
  };
}
