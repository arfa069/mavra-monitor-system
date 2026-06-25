import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF0A0A0A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryPressed = Color(0xFF222222);
  static const focusBlue = Color(0xFF1D4ED8);
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF7F8FA);
  static const surfaceMuted = Color(0xFFF2F3F5);
  static const hairline = Color(0xFFE5E7EB);
  static const hairlineSoft = Color(0xFFEAECF0);
  static const ink = Color(0xFF0A0A0A);
  static const charcoal = Color(0xFF222222);
  static const steel = Color(0xFF5F5F5F);
  static const muted = Color(0xFFA8AAB2);
  static const brandCoral = Color(0xFFFF5530);
  static const brandMagenta = Color(0xFFEA5EC1);
  static const brandBlue = Color(0xFF1456F0);
  static const brandBlueDeep = Color(0xFF1D4ED8);
  static const brandBlue700 = Color(0xFF17437D);
  static const brandCyan = Color(0xFF3DAEFF);
  static const brandBlue200 = Color(0xFFBFDBFE);
  static const brandPurple = Color(0xFFA855F7);
  static const successBackground = Color(0xFFE8FFEA);
  static const successText = Color(0xFF1BA673);
  static const danger = Color(0xFFB91C1C);
  static const warning = Color(0xFFB45309);
  static const home = Color(0xFF0F766E);
  static const job = Color(0xFF7C3AED);
  static const price = Color(0xFFC05621);
  static const pillRadius = 999.0;

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: ink,
          onPrimaryContainer: onPrimary,
          secondary: steel,
          onSecondary: onPrimary,
          tertiary: brandCoral,
          onTertiary: onPrimary,
          error: danger,
          onError: onPrimary,
          errorContainer: const Color(0xFFFFE4E6),
          onErrorContainer: danger,
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: steel,
          outline: hairline,
          outlineVariant: hairlineSoft,
          shadow: const Color(0xFF000000),
        );

    return _theme(scheme);
  }

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5E7EB),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFFFFFFF),
          onPrimary: primary,
          primaryContainer: const Color(0xFFE5E7EB),
          onPrimaryContainer: primary,
          secondary: const Color(0xFFCBD5E1),
          onSecondary: primary,
          tertiary: const Color(0xFFFF8A66),
          onTertiary: primary,
          error: const Color(0xFFFCA5A5),
          onError: primary,
          errorContainer: const Color(0xFF451A1A),
          onErrorContainer: const Color(0xFFFCA5A5),
          surface: const Color(0xFF111111),
          onSurface: const Color(0xFFF8FAFC),
          onSurfaceVariant: const Color(0xFFCBD5E1),
          outline: const Color(0xFF3F3F46),
          outlineVariant: const Color(0xFF27272A),
          shadow: const Color(0xFF000000),
        );

    return _theme(scheme);
  }

  static ThemeData _theme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = _textTheme(isDark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'DMSans',
      fontFamilyFallback: const ['NotoSansSC'],
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : surfaceSoft,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: focusBlue, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: danger, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.outlineVariant,
          disabledForegroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.onSurface),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(36, 36),
          fixedSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        labelStyle: textTheme.labelSmall,
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        disabledColor: scheme.outlineVariant,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurfaceVariant,
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: scheme.onSurface,
        selectedTileColor: scheme.brightness == Brightness.dark
            ? const Color(0xFF18181B)
            : surfaceMuted,
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 48,
        headingTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
        dataTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
        ),
        dividerThickness: 1,
      ),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final color = isDark ? const Color(0xFFF8FAFC) : ink;
    final mutedColor = isDark ? const Color(0xFFCBD5E1) : steel;
    const fallback = ['NotoSansSC'];

    TextStyle style({
      required double size,
      required FontWeight weight,
      double height = 1.5,
      Color? textColor,
    }) {
      return TextStyle(
        fontFamily: 'DMSans',
        fontFamilyFallback: fallback,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: 0,
        color: textColor ?? color,
      );
    }

    return TextTheme(
      displayLarge: style(size: 80, weight: FontWeight.w600, height: 1.1),
      displayMedium: style(size: 56, weight: FontWeight.w600, height: 1.1),
      displaySmall: style(size: 40, weight: FontWeight.w600, height: 1.2),
      headlineMedium: style(size: 32, weight: FontWeight.w600, height: 1.2),
      headlineSmall: style(size: 24, weight: FontWeight.w600, height: 1.25),
      titleLarge: style(size: 20, weight: FontWeight.w600, height: 1.35),
      titleMedium: style(size: 18, weight: FontWeight.w600, height: 1.4),
      titleSmall: style(size: 15, weight: FontWeight.w600, height: 1.4),
      bodyLarge: style(size: 16, weight: FontWeight.w400, textColor: color),
      bodyMedium: style(size: 16, weight: FontWeight.w400, textColor: color),
      bodySmall: style(
        size: 14,
        weight: FontWeight.w400,
        textColor: mutedColor,
      ),
      labelLarge: style(size: 14, weight: FontWeight.w600, height: 1.4),
      labelMedium: style(size: 13, weight: FontWeight.w600, height: 1.4),
      labelSmall: style(size: 12, weight: FontWeight.w600, height: 1.4),
    );
  }
}
