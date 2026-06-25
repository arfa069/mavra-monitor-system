import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MavraButtonStyle {
  static ButtonStyle compactFilled({
    required BuildContext context,
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: isDangerous ? colors.error : colors.primary,
      foregroundColor: isDangerous ? colors.onError : colors.onPrimary,
      minimumSize: const Size(40, 40),
      fixedSize: const Size.fromHeight(40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      textStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  static ButtonStyle compactOutlined({
    required BuildContext context,
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return OutlinedButton.styleFrom(
      foregroundColor: isDangerous ? colors.error : colors.primary,
      side: BorderSide(
        color: isDangerous ? colors.error : colors.outlineVariant,
      ),
      minimumSize: const Size(40, 40),
      fixedSize: const Size.fromHeight(40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      textStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  static ButtonStyle compactText({
    required BuildContext context,
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return TextButton.styleFrom(
      foregroundColor: isDangerous ? colors.error : colors.primary,
      minimumSize: const Size(40, 40),
      fixedSize: const Size.fromHeight(40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      textStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  static ButtonStyle filterFilled({
    required BuildContext context,
    bool isDangerous = false,
  }) {
    return compactFilled(context: context, isDangerous: isDangerous).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 40)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static ButtonStyle filterOutlined({
    required BuildContext context,
    bool isDangerous = false,
  }) {
    return compactOutlined(context: context, isDangerous: isDangerous).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 40)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static ButtonStyle filterSegmented() {
    return SegmentedButton.styleFrom(
      minimumSize: const Size(0, 40),
      maximumSize: const Size(double.infinity, 40),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
    );
  }

  static ButtonStyle rowIconButton({
    required BuildContext context,
    bool isDangerous = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.styleFrom(
      foregroundColor: isDangerous ? colors.error : colors.primary,
      minimumSize: const Size(36, 36),
      fixedSize: const Size(36, 36),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
    );
  }
}

class MavraFilterButton extends StatelessWidget {
  const MavraFilterButton.filled({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDangerous = false,
  }) : outlined = false;

  const MavraFilterButton.outlined({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDangerous = false,
  }) : outlined = true;

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDangerous;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onPressed != null;
    final foreground = isDangerous ? colors.error : colors.primary;
    final filledForeground = isDangerous ? colors.onError : colors.onPrimary;
    final background = isDangerous ? colors.error : colors.primary;
    final borderColor = isDangerous ? colors.error : colors.outlineVariant;
    final disabledColor = colors.onSurface.withValues(alpha: 0.38);

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: outlined
                  ? Colors.transparent
                  : enabled
                  ? background
                  : colors.onSurface.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              border: Border.all(
                color: enabled ? borderColor : colors.outlineVariant,
              ),
            ),
            child: IconTheme(
              data: IconThemeData(
                color: enabled
                    ? outlined
                          ? foreground
                          : filledForeground
                    : disabledColor,
                size: 18,
              ),
              child: DefaultTextStyle(
                style: (theme.textTheme.labelMedium ?? const TextStyle())
                    .copyWith(
                      color: enabled
                          ? outlined
                                ? foreground
                                : filledForeground
                          : disabledColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MavraInputStyle {
  static InputDecoration filterInput({
    required BuildContext context,
    required String label,
    Widget? suffixIcon,
    String? errorText,
    String? helperText,
    bool isMultiline = false,
    bool labelAsHint = false,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: labelAsHint ? null : label,
      hintText: labelAsHint ? label : null,
      alignLabelWithHint: true,
      floatingLabelBehavior: labelAsHint
          ? FloatingLabelBehavior.never
          : FloatingLabelBehavior.auto,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      isDense: true,
      constraints: (errorText == null && helperText == null && !isMultiline)
          ? const BoxConstraints(maxHeight: 40, minHeight: 40)
          : null,
      errorText: errorText,
      helperText: helperText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.focusBlue, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  static InputDecoration tableInput({
    required BuildContext context,
    Widget? suffixIcon,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
      constraints: const BoxConstraints(maxHeight: 36, minHeight: 36),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.focusBlue, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }
}

class MavraTabChipStyle {
  static Color selectedColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static BorderSide side(BuildContext context) {
    return BorderSide(color: Theme.of(context).colorScheme.outlineVariant);
  }

  static Color iconColor(BuildContext context, bool selected) {
    final colors = Theme.of(context).colorScheme;
    return selected ? colors.onPrimary : colors.onSurfaceVariant;
  }

  static TextStyle? labelStyle(BuildContext context, bool selected) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return theme.textTheme.labelMedium?.copyWith(
      color: selected ? colors.onPrimary : colors.onSurface,
      fontWeight: FontWeight.w600,
    );
  }
}

class MavraTableStyle {
  static BoxDecoration panelDecoration(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: colors.outlineVariant),
    );
  }
}
