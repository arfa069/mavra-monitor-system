import 'package:flutter/material.dart';

class MavraPageBanner extends StatelessWidget {
  const MavraPageBanner({
    super.key,
    this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String? eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final horizontalPadding = wide ? 24.0 : 16.0;
        final verticalPadding = wide ? 22.0 : 18.0;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.36),
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: text.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: (wide ? text.headlineMedium : text.headlineSmall)?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
