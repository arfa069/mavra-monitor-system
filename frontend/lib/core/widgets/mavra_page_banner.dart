import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MavraPageBanner extends StatelessWidget {
  const MavraPageBanner({
    super.key,
    this.accentColor = AppTheme.brandCoral,
    this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final Color accentColor;
  final String? eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accentColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final horizontalPadding = wide ? 28.0 : 20.0;
        final verticalPadding = wide ? 28.0 : 24.0;

        return DecoratedBox(
          key: const Key('mavra-page-banner-surface'),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BannerCopy(eyebrow, title, subtitle, foreground),
            ),
          ),
        );
      },
    );
  }
}

class _BannerCopy extends StatelessWidget {
  const _BannerCopy(this.eyebrow, this.title, this.subtitle, this.foreground);

  final String? eyebrow;
  final String title;
  final String subtitle;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: text.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          title,
          style: text.headlineMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            subtitle,
            style: text.bodyMedium?.copyWith(
              color: foreground.withValues(alpha: 0.82),
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

Color _foregroundFor(Color background) {
  return background.computeLuminance() > 0.55
      ? AppTheme.primary
      : AppTheme.onPrimary;
}
