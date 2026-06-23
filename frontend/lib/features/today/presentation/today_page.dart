import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/today_models.dart';

const _loadWarning = '今天的简报没有完全同步，稍后会再试。';

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
          Text('正在整理今天的节奏...'),
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
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Row(
              key: const Key('today-desktop-rhythm'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (snapshot.warningMessage != null) ...[
                        _WarningBanner(message: snapshot.warningMessage!),
                        const SizedBox(height: 16),
                      ],
                      _DailySummary(snapshot: snapshot),
                      const SizedBox(height: 16),
                      _AttentionQueue(items: snapshot.attentionItems),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 360,
                  child: _QuietStatusPanel(statuses: snapshot.moduleStatuses),
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
      padding: const EdgeInsets.all(16),
      children: [
        if (snapshot.warningMessage != null) ...[
          _WarningBanner(message: snapshot.warningMessage!),
          const SizedBox(height: 12),
        ],
        _DailySummary(snapshot: snapshot),
        const SizedBox(height: 16),
        _AttentionQueue(items: snapshot.attentionItems),
        const SizedBox(height: 16),
        _QuietStatusPanel(statuses: snapshot.moduleStatuses),
      ],
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
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.54),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
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
                    '今天',
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          'Quiet score $score',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onPrimaryContainer,
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
          child: Text('没有需要你立刻处理的事。'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('值得看', style: Theme.of(context).textTheme.titleLarge),
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
          Text('今天的状态', style: Theme.of(context).textTheme.titleLarge),
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
      borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
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
        color: colors.surface.withValues(alpha: 0.72),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

String _statusText(TodayStatusState status) {
  return switch (status) {
    TodayStatusState.attention => '需要看看',
    TodayStatusState.inactive => '未启用',
    TodayStatusState.quiet => '安静运行',
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
