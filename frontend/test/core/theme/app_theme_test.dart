import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/theme/app_theme.dart';

void main() {
  test('light theme exposes the adapted MiniMax token contract', () {
    final theme = AppTheme.light;

    expect(theme.textTheme.bodyMedium?.fontFamily, 'DMSans');
    expect(
      theme.textTheme.bodyMedium?.fontFamilyFallback,
      contains('NotoSansSC'),
    );
    expect(theme.colorScheme.primary, const Color(0xFF0A0A0A));
    expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F8FA));
    expect(theme.textTheme.bodyMedium?.fontSize, 16);
    expect(theme.textTheme.labelLarge?.fontWeight, FontWeight.w600);
  });

  test('theme exposes the high-impact MiniMax display scale', () {
    final theme = AppTheme.light;

    expect(theme.textTheme.displayLarge?.fontSize, 80);
    expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w600);
    expect(theme.textTheme.displayLarge?.height, 1.1);
    expect(theme.textTheme.displayMedium?.fontSize, 56);
    expect(theme.textTheme.displaySmall?.fontSize, 40);
  });

  test('core Material components use pill actions and flat data chrome', () {
    final theme = AppTheme.light;

    final filledShape =
        theme.filledButtonTheme.style?.shape?.resolve({})
            as RoundedRectangleBorder?;
    final outlinedShape =
        theme.outlinedButtonTheme.style?.shape?.resolve({})
            as RoundedRectangleBorder?;
    final iconShape =
        theme.iconButtonTheme.style?.shape?.resolve({})
            as RoundedRectangleBorder?;

    expect(filledShape?.borderRadius, BorderRadius.circular(999));
    expect(outlinedShape?.borderRadius, BorderRadius.circular(999));
    expect(iconShape?.borderRadius, BorderRadius.circular(999));
    expect(theme.dataTableTheme.headingRowHeight, 40);
    expect(theme.dataTableTheme.dataRowMinHeight, 44);
    expect(theme.cardTheme.elevation, 0);
  });
}
