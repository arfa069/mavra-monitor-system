import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/theme/app_theme.dart';
import 'package:mavra_frontend/core/widgets/mavra_page_banner.dart';

void main() {
  testWidgets(
    'page banner uses the requested accent surface without promo chrome',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: MavraPageBanner(
              accentColor: AppTheme.brandMagenta,
              eyebrow: 'Prices',
              title: 'Price Monitor',
              subtitle: 'Track the products that matter.',
            ),
          ),
        ),
      );

      final surface = tester.widget<DecoratedBox>(
        find.byKey(const Key('mavra-page-banner-surface')),
      );
      final decoration = surface.decoration as BoxDecoration;

      expect(decoration.color, AppTheme.brandMagenta);
      expect(decoration.borderRadius, BorderRadius.circular(32));
      expect(
        find.byKey(const Key('mavra-page-banner-promo-strip')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('mavra-page-banner-accent-panel')),
        findsNothing,
      );
      expect(find.text('Mavra Intelligence Layer'), findsNothing);
    },
  );
}
